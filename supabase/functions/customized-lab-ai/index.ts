// @ts-nocheck

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

// @ts-ignore - Supabase Edge Functions run with Deno runtime, not a standard TS project.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import {
  DEFAULT_FALLBACK_MODEL,
  DEFAULT_PRIMARY_MODEL,
  resolveGeminiModels,
  shouldUseFallbackForGeminiError,
} from './gemini_model_config.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type LabGenerationRequest = {
  title?: string;
  topic?: string;
  subject?: string;
  classLevel?: string;
  difficulty?: string;
  numberOfLessons?: number;
  duration?: string;
  learningObjectives?: string;
  preferredLanguage?: string;
  learningContent?: string[];
  instructions?: string;
};

type LabLessonOutput = {
  id: string;
  title: string;
  content: string;
  key_points: string[];
  order_index: number;
  duration_minutes: number;
};

type QuizQuestionOutput = {
  id: string;
  question: string;
  options: string[];
  correct_answer: string;
  explanation: string;
  type: string;
};

const MAX_GEMINI_ATTEMPTS = 3;
const PER_GEMINI_REQUEST_TIMEOUT_MS = 15_000;
const OVERALL_GEMINI_DEADLINE_MS = 52_000;
const TRANSIENT_GEMINI_STATUS_CODES = new Set([429, 500, 502, 503, 504]);

function getRemainingMs(deadlineMs: number): number {
  return Math.max(0, deadlineMs - Date.now());
}

function getRequestTimeoutMs(deadlineMs: number): number {
  return Math.min(PER_GEMINI_REQUEST_TIMEOUT_MS, getRemainingMs(deadlineMs));
}

function createGeminiError(
  message: string,
  statusCode: number,
  code: string,
): Error & { statusCode: number; code: string } {
  return Object.assign(new Error(message), { statusCode, code });
}

function logAttempt(model: string, attemptNumber: number, detail: Record<string, unknown>) {
  console.log('[customized-lab-ai]', JSON.stringify({
    model,
    attempt: attemptNumber,
    ...detail,
  }));
}

function isTimeoutError(error: unknown): boolean {
  const name = (error as { name?: string })?.name;
  return name === 'AbortError' || name === 'TimeoutError';
}

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseRetryAfterMs(headers: Headers): number | undefined {
  const retryAfter = headers.get('Retry-After');
  if (!retryAfter) return undefined;

  const seconds = Number(retryAfter);
  if (Number.isFinite(seconds)) {
    return Math.max(1000, seconds * 1000);
  }

  const retryAt = Date.parse(retryAfter);
  if (!Number.isNaN(retryAt)) {
    return Math.max(1000, retryAt - Date.now());
  }

  return undefined;
}

function resolveConfiguredModels() {
  const models = resolveGeminiModels({
    CUSTOM_LAB_GEMINI_MODEL: Deno.env.get('CUSTOM_LAB_GEMINI_MODEL'),
    GEMINI_MODEL: Deno.env.get('GEMINI_MODEL'),
    CUSTOM_LAB_GEMINI_FALLBACK_MODEL: Deno.env.get(
      'CUSTOM_LAB_GEMINI_FALLBACK_MODEL',
    ),
    GEMINI_FALLBACK_MODEL: Deno.env.get('GEMINI_FALLBACK_MODEL'),
  });

  return models;
}

function shouldRetryOnGeminiError(
  statusCode?: number,
  code?: string,
  attemptsUsed = 0,
  hasFallbackModel = false,
): boolean {
  if (statusCode === 400 || statusCode === 401 || statusCode === 403 || statusCode === 404) {
    return false;
  }

  if (code === 'invalid_request' || code === 'invalid_api_key' || code === 'missing_secret') {
    return false;
  }

  if (attemptsUsed >= MAX_GEMINI_ATTEMPTS) {
    return false;
  }

  if (shouldUseFallbackForGeminiError(statusCode, code)) {
    return hasFallbackModel || attemptsUsed < MAX_GEMINI_ATTEMPTS;
  }

  return false;
}

function getModelAttemptLimit(index: number, attemptsUsed: number): number {
  const remainingAttempts = MAX_GEMINI_ATTEMPTS - attemptsUsed;
  if (remainingAttempts <= 0) return 0;
  if (index === 0) {
    return 1;
  }
  return Math.min(2, remainingAttempts);
}

function safeText(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value.trim() : fallback;
}

function truncateForLog(value: unknown, maxLength = 800): string {
  const raw = typeof value === 'string' ? value : JSON.stringify(value);
  const text = String(raw ?? '').replace(/\s+/g, ' ').trim();
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 3)}...`;
}

function requireAuthenticated(req: Request): void {
  const authHeader = req.headers.get('Authorization');
  const apikey = req.headers.get('apikey');
  const clientInfo = req.headers.get('x-client-info');

  if (!authHeader && !apikey && !clientInfo) {
    throw Object.assign(new Error('Authentication required.'), {
      statusCode: 401,
      code: 'unauthorized',
    });
  }
}

function validateRequest(payload: unknown): LabGenerationRequest {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw Object.assign(new Error('Missing request body.'), {
      statusCode: 400,
      code: 'invalid_request',
    });
  }

  const request = payload as Record<string, unknown>;
  const title = safeText(request.title, '');
  const topic = safeText(request.topic, '');
  const subject = safeText(request.subject, '');
  const classLevel = safeText(request.classLevel, 'Class 10');
  const difficulty = safeText(request.difficulty, 'beginner');
  const language = safeText(request.preferredLanguage, 'en');
  const duration = safeText(request.duration, '7 days');
  const learningObjectives = safeText(request.learningObjectives, 'Understand the topic.');

  if (!title && !topic && !subject) {
    throw Object.assign(new Error('Lab title, topic or subject is required.'), {
      statusCode: 400,
      code: 'invalid_request',
    });
  }

  const numberOfLessons = Number(request.numberOfLessons ?? 4);
  if (!Number.isFinite(numberOfLessons) || numberOfLessons < 2 || numberOfLessons > 8) {
    throw Object.assign(new Error('Number of lessons must be between 2 and 8.'), {
      statusCode: 400,
      code: 'invalid_request',
    });
  }

  return {
    title: title || topic || subject,
    topic: topic || title || subject,
    subject: subject || 'General Science',
    classLevel: classLevel || 'Class 10',
    difficulty: difficulty || 'beginner',
    numberOfLessons: Math.round(numberOfLessons),
    duration: duration || '7 days',
    learningObjectives: learningObjectives || 'Understand the topic.',
    preferredLanguage: language || 'en',
    learningContent: Array.isArray(request.learningContent)
      ? request.learningContent.filter((item): item is string => typeof item === 'string')
      : [],
    instructions: safeText(request.instructions, ''),
  };
}

function buildGeminiPrompt(request: LabGenerationRequest): string {
  const contentList = request.learningContent && request.learningContent.length > 0
    ? request.learningContent.join(', ')
    : 'Core concepts, examples, practice questions, and revision notes';

  const prompt = `
You are an expert curriculum designer and educator for a study lab platform.

Create a complete structured study lab in ${request.preferredLanguage || 'en'}.

Requirements:
- Student subject: ${request.subject}
- Class / education level: ${request.classLevel}
- Difficulty: ${request.difficulty}
- Duration: ${request.duration}
- Desired number of lessons: ${request.numberOfLessons}
- Learning objectives: ${request.learningObjectives}
- Preferred content focus: ${contentList}
- Extra instructions: ${request.instructions || 'None'}

Create valid JSON only with no markdown fences.

The JSON must match this exact structure and types:
{
  "lab": {
    "id": "custom-ai-generated-id",
    "title": "Lab title",
    "category": "other",
    "description": "Introductory description",
    "difficulty": "beginner",
    "is_custom_lab": true,
    "created_at": "2026-11-13T00:00:00.000Z",
    "user_id": null,
    "last_studied_at": "2026-11-13T00:00:00.000Z",
    "lessons": [
      {
        "id": "lesson-1",
        "title": "Lesson title",
        "content": "Detailed explanation of the lesson.",
        "key_points": ["Important point 1", "Important point 2"],
        "order_index": 0,
        "duration_minutes": 30,
        "is_completed": false
      }
    ],
    "quiz_questions": [
      {
        "id": "quiz-1",
        "question": "Question text",
        "options": ["A", "B", "C", "D"],
        "correct_answer": "A",
        "explanation": "Why this is correct",
        "type": "multiple_choice"
      }
    ],
    "custom_lab_config": {
      "lab_name": "Lab title",
      "subject": "Subject",
      "category": "other",
      "topic": "Topic",
      "topics": ["Topic"],
      "class_level": "Class 10",
      "duration_days": 7,
      "daily_study_minutes": 30,
      "difficulty": "beginner",
      "learning_goal": "Understand concepts",
      "learning_content": ["Short explanations", "Practice questions"],
      "instructions": "Extra guidance",
      "preferred_language": "en",
      "number_of_lessons": 4
    }
  }
}

Rules:
- The title should be: ${request.title || request.topic || request.subject}
- The lab description should match the student's level, subject and duration.
- Create ${request.numberOfLessons} lessons, each with a clear title, explanation, key points, order, and duration.
- Include realistic practical activities and examples in the lesson content.
- Include final assessment and revision notes in the lesson content or description.
- Include a quiz for each lesson or a final quiz with multiple-choice questions and exact correct answers.
- The returned JSON must be parseable and usable by the existing Study Nova lab screens.
- Keep content clear, accurate, and appropriate for the requested class level and language.
`;

  return prompt;
}

function buildGeminiParts(prompt: string) {
  return [{ text: prompt }];
}

function extractJsonFromGemini(data: unknown): object {
  const candidates = Array.isArray((data as any)?.candidates)
    ? (data as any).candidates
    : [];

  const combined = candidates
    .map((candidate: any) => {
      const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
      return parts
        .map((part: any) => typeof part?.text === 'string' ? part.text : '')
        .join('');
    })
    .join('')
    .trim();

  if (!combined) {
    throw createGeminiError('Gemini returned no lab content.', 502, 'empty_response');
  }

  try {
    return JSON.parse(combined);
  } catch {
    const start = combined.indexOf('{');
    const end = combined.lastIndexOf('}');
    if (start === -1 || end === -1 || end <= start) {
      throw createGeminiError('Gemini responded with invalid JSON.', 502, 'invalid_json_response');
    }
    return JSON.parse(combined.substring(start, end + 1));
  }
}

async function callGeminiModel(
  request: LabGenerationRequest,
  model: string,
  apiKey: string,
  attemptNumber: number,
  overallDeadlineMs: number,
): Promise<object> {
  const prompt = buildGeminiPrompt(request);
  const body = JSON.stringify({
    contents: [{ role: 'user', parts: buildGeminiParts(prompt) }],
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 4000,
    },
  });

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const timeoutMs = getRequestTimeoutMs(overallDeadlineMs);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  logAttempt(model, attemptNumber, {
    timeoutMs,
    status: 'starting',
    overallDeadlineMs,
    remainingMs: getRemainingMs(overallDeadlineMs),
  });

  try {
    if (timeoutMs <= 0) {
      throw createGeminiError(
        'AI service is temporarily busy. Please try again in a minute.',
        503,
        'upstream_unavailable',
      );
    }

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
      signal: controller.signal,
    });

    const responseText = await response.text();
    if (!response.ok) {
      const errorText = truncateForLog(responseText);
      const retryAfterMs = parseRetryAfterMs(response.headers);

      if (response.status === 400 || response.status === 404) {
        throw createGeminiError(`Gemini request rejected (${model}): ${errorText}`, 400, 'invalid_request');
      }

      if (response.status === 401 || response.status === 403) {
        throw createGeminiError('Gemini API key is invalid or unauthorized.', 401, 'invalid_api_key');
      }

      if (shouldUseFallbackForGeminiError(response.status)) {
        logAttempt(model, attemptNumber, {
          timeoutMs,
          status: response.status,
          fallback: 'starting',
          outcome: 'transient_http_error',
        });
        throw createGeminiError('AI service is temporarily busy. Please try again in a minute.', 503, 'upstream_unavailable');
      }

      throw createGeminiError(`Gemini API error ${response.status}: ${errorText}`, 502, 'upstream_failure');
    }

    const parsed = JSON.parse(responseText);
    const generated = extractJsonFromGemini(parsed);
    logAttempt(model, attemptNumber, {
      timeoutMs,
      status: 'success',
      fallback: 'none',
      outcome: 'completed',
    });
    return generated;
  } catch (error) {
    const statusCode = (error as { statusCode?: number })?.statusCode;
    const code = (error as { code?: string })?.code;
    const timedOut = isTimeoutError(error);

    logAttempt(model, attemptNumber, {
      timeoutMs,
      status: statusCode ?? (timedOut ? 'timeout' : 'error'),
      fallback: 'none',
      outcome: timedOut ? 'timeout' : (code ?? 'error'),
    });

    if (timedOut || shouldUseFallbackForGeminiError(statusCode, code)) {
      throw createGeminiError('AI service is temporarily busy. Please try again in a minute.', 503, 'upstream_unavailable');
    }

    throw error;
  } finally {
    clearTimeout(timer);
    controller.abort();
  }
}

async function callGemini(request: LabGenerationRequest): Promise<object> {
  const apiKey = Deno.env.get('CUSTOM_LAB_GEMINI_KEY');
  if (!apiKey) {
    throw Object.assign(new Error('CUSTOM_LAB_GEMINI_KEY is missing'), {
      statusCode: 500,
      code: 'missing_secret',
    });
  }

  const { ordered } = resolveConfiguredModels();
  const overallDeadlineMs = Date.now() + OVERALL_GEMINI_DEADLINE_MS;
  let attemptsUsed = 0;
  let lastError: unknown;

  for (let modelIndex = 0; modelIndex < ordered.length; modelIndex++) {
    const model = ordered[modelIndex];
    const remainingAttempts = MAX_GEMINI_ATTEMPTS - attemptsUsed;
    if (remainingAttempts <= 0 || getRemainingMs(overallDeadlineMs) <= 0) break;

    const maxAttemptsForModel = getModelAttemptLimit(modelIndex, attemptsUsed);
    if (maxAttemptsForModel <= 0) break;

    for (let attemptIndex = 1; attemptIndex <= maxAttemptsForModel; attemptIndex++) {
      if (getRemainingMs(overallDeadlineMs) <= 0) {
        break;
      }

      attemptsUsed += 1;
      try {
        return await callGeminiModel(request, model, apiKey, attemptsUsed, overallDeadlineMs);
      } catch (error) {
        lastError = error;
        const statusCode = (error as { statusCode?: number })?.statusCode;
        const code = (error as { code?: string })?.code;
        const timedOut = isTimeoutError(error);
        const transientFailure = timedOut || shouldUseFallbackForGeminiError(statusCode, code);

        if (!transientFailure) {
          throw error;
        }

        const hasFallbackModel = modelIndex < ordered.length - 1;
        const canContinue = attemptsUsed < MAX_GEMINI_ATTEMPTS && getRemainingMs(overallDeadlineMs) > 0;

        if (hasFallbackModel && canContinue) {
          console.warn('[customized-lab-ai]', JSON.stringify({
            model,
            attempt: attemptsUsed,
            status: statusCode ?? 'timeout',
            fallback: 'starting',
            nextModel: ordered[modelIndex + 1],
            remainingAttempts: MAX_GEMINI_ATTEMPTS - attemptsUsed,
            overallDeadlineMs,
          }));
          break;
        }

        if (modelIndex === ordered.length - 1 || !hasFallbackModel) {
          throw error;
        }
      }
    }

    if (modelIndex < ordered.length - 1 && getRemainingMs(overallDeadlineMs) > 0) {
      continue;
    }
  }

  if (lastError) {
    throw lastError;
  }

  throw createGeminiError('AI service is temporarily busy. Please try again in a minute.', 503, 'upstream_unavailable');
}

function resolveGeminiModel(): string {
  const { primary } = resolveConfiguredModels();
  return primary;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return jsonResponse(200, { ok: true });
  }

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  try {
    requireAuthenticated(req);

    const rawBody = await req.text();
    const body = rawBody ? JSON.parse(rawBody) : {};
    const request = validateRequest(body);

    const generated = await callGemini(request);

    return jsonResponse(200, {
      status: 200,
      result: {
        lab: generated,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lab generation failed';
    const statusCode = (error as { statusCode?: number })?.statusCode ?? 500;
    const code = (error as { code?: string })?.code ?? 'internal_error';

    console.error('[customized-lab-ai] request failed', {
      statusCode,
      code,
      message: truncateForLog(message),
      error: truncateForLog(error),
    });

    const finalStatus = statusCode === 503 ? 503 : statusCode;
    const finalCode = code === 'upstream_unavailable' ? 'upstream_unavailable' : code;
    const finalMessage = finalStatus === 503 && finalCode === 'upstream_unavailable'
      ? 'AI service is temporarily busy. Please try again in a minute.'
      : message;

    return jsonResponse(finalStatus, {
      status: finalStatus,
      result: {
        error: {
          status: finalStatus,
          message: finalMessage,
          code: finalCode,
        },
      },
    });
  }
});
