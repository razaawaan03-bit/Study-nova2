declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

// @ts-ignore - Supabase Edge Functions run with Deno runtime, not a standard TS project.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Attachment = {
  name?: string;
  mimeType?: string;
  data?: string;
};

type CourseRequest = {
  title?: string;
  courseType?: string;
  classLevel?: string;
  subject?: string;
  examTarget?: string;
  length?: string;
  difficulty?: string;
  language?: string;
  learningGoal?: string;
  description?: string;
  materialText?: string;
  attachments?: Attachment[];
};

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
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

function ensureCourseRequest(payload: CourseRequest | null | undefined) {
  if (!payload || Object.keys(payload).length === 0) {
    throw Object.assign(new Error('Missing course request body.'), { statusCode: 400 });
  }

  const title = safeText(payload.title, '');
  const subject = safeText(payload.subject, '');
  const topic = payload.description && safeText(payload.description, '');

  if (!title && !subject && !topic) {
    throw Object.assign(
      new Error('Missing course title or topic. Please enter a title or subject before generating.'),
      { statusCode: 400 },
    );
  }

  return payload;
}

function resolveGeminiModel(): string {
  const configured = safeText(Deno.env.get('GEMINI_MODEL'), '');
  return configured || 'gemini-3.8-flash';
}

function buildGeminiParts(request: CourseRequest) {
  const materialText = safeText(request.materialText, '');
  const prompt = `
You are an expert teacher and curriculum designer.

Build a complete, structured study course in ${safeText(request.language, 'en')} for this course request.

COURSE REQUEST
- Title: ${safeText(request.title, 'Untitled Course')}
- Course type: ${safeText(request.courseType, 'general_learning')}
- Class level: ${safeText(request.classLevel, 'N/A')}
- Subject: ${safeText(request.subject, 'General Studies')}
- Exam target: ${safeText(request.examTarget, 'N/A')}
- Course length: ${safeText(request.length, 'medium')}
- Difficulty: ${safeText(request.difficulty, 'beginner')}
- Learning goal: ${safeText(request.learningGoal, 'Not specified')}
- Description: ${safeText(request.description, 'No description provided')}

STUDENT MATERIAL
${materialText.trim().length > 0 ? materialText : 'No uploaded files or notes were supplied. Build a complete course directly from the course request using general educational knowledge.'}

RULES
- If the user provides material, use it as a reference and prioritize it where appropriate.
- If no material is supplied, create a complete course from the title/topic and the general educational knowledge available to you.
- Do not invent facts that contradict the course request; when needed, present reasonable educational content that matches the topic.
- Keep the language student-friendly and clear.
- Return valid JSON only, without markdown fences.
- Include chapters, topics, quizzes, a mind map, and revision notes.
- Each chapter should have a practical explanation and structured topics.
- Keep quiz questions multiple-choice with exact correct answers.

RETURN THIS EXACT JSON SHAPE:
{
  "course": {
    "title": "course title",
    "description": "one or two sentence description"
  },
  "chapters": [
    {
      "title": "chapter title",
      "description": "what this chapter covers",
      "topics": [
        {
          "title": "topic title",
          "explanation": "detailed explanation",
          "simple_explanation": "very simple explanation",
          "important_points": ["point"],
          "examples": ["example"],
          "key_terms": [{ "term": "term", "definition": "definition" }],
          "questions": ["practice question"],
          "revision_notes": ["short revision note"]
        }
      ]
    }
  ],
  "quizzes": [
    {
      "title": "Chapter 1 Quiz",
      "questions": [
        {
          "question": "question text",
          "options": ["option A", "option B", "option C", "option D"],
          "correct_answer": "exact text of the correct option",
          "explanation": "why that answer is correct"
        }
      ]
    }
  ],
  "mind_map": {
    "root": "main topic",
    "branches": [{ "name": "concept", "children": ["sub-concept", "key point"] }]
  },
  "revision_notes": ["course level revision note"]
}
`;

  const parts: unknown[] = [{ text: prompt }];

  for (const attachment of request.attachments ?? []) {
    const base64 = safeText(attachment.data, '');
    if (!base64) continue;

    const mimeType = safeText(attachment.mimeType, 'application/octet-stream');
    const name = safeText(attachment.name, 'attachment');

    parts.push({
      inline_data: {
        mime_type: mimeType,
        data: base64,
      },
      file_name: name,
    });
  }

  return parts;
}

async function callGemini(payload: CourseRequest): Promise<string> {
  const apiKey = Deno.env.get('COURSE_MAKER_GEMINI_KEY');
  console.log('[course-maker-ai] checking Gemini secret', {
    hasSecret: !!apiKey,
    secretLength: apiKey ? apiKey.length : 0,
  });

  if (!apiKey) {
    throw Object.assign(new Error('COURSE_MAKER_GEMINI_KEY is missing'), {
      statusCode: 500,
      code: 'missing_secret',
    });
  }

  const model = resolveGeminiModel();
  console.log('[course-maker-ai] using Gemini model', { model });

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const body = JSON.stringify({
    contents: [{
      role: 'user',
      parts: buildGeminiParts(payload),
    }],
    generationConfig: {
      temperature: 0.4,
    },
  });

  console.log('[course-maker-ai] sending Gemini request', {
    model,
    promptLength: body.length,
    attachments: payload.attachments?.length ?? 0,
  });

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body,
      signal: AbortSignal.timeout(90_000),
    });

    const responseText = await response.text();
    console.log('[course-maker-ai] Gemini HTTP status received', {
      model,
      status: response.status,
      bodyPreview: truncateForLog(responseText),
    });

    if (!response.ok) {
      const errorText = truncateForLog(responseText);
      console.error('[course-maker-ai] Gemini HTTP failure', {
        model,
        status: response.status,
        errorText,
      });

      if (response.status === 400 || response.status === 404) {
        throw Object.assign(
          new Error(`Gemini model rejected the request (${model}): ${errorText}`),
          { statusCode: 404, code: 'invalid_model_or_payload' },
        );
      }

      if (response.status === 401 || response.status === 403) {
        throw Object.assign(new Error('Gemini API key is invalid or unauthorized.'), {
          statusCode: 401,
          code: 'invalid_api_key',
        });
      }

      if (response.status === 429) {
        throw Object.assign(new Error('Gemini quota exceeded. Please try again later.'), {
          statusCode: 429,
          code: 'quota_exceeded',
        });
      }

      throw Object.assign(new Error(`Gemini API error ${response.status}: ${errorText}`), {
        statusCode: 502,
        code: 'upstream_failure',
      });
    }

    const data = JSON.parse(responseText);
    const candidates = data?.candidates ?? [];
    const first = candidates[0];
    const parts = first?.content?.parts ?? [];

    const combined = parts
      .map((part: any) => typeof part?.text === 'string' ? part.text : '')
      .join('')
      .trim();

    console.log('[course-maker-ai] Gemini response parsed', {
      model,
      candidateCount: candidates.length,
      replyLength: combined.length,
    });

    if (!combined) {
      throw Object.assign(new Error('Gemini returned no generated course content.'), {
        statusCode: 502,
        code: 'empty_response',
      });
    }

    return combined;
  } catch (error) {
    if (
      error instanceof Error &&
      (error.name === 'TimeoutError' || error.message.toLowerCase().includes('timeout'))
    ) {
      console.error('[course-maker-ai] Gemini request timed out', { model });
      throw Object.assign(new Error('Gemini request timed out.'), {
        statusCode: 504,
        code: 'timeout',
      });
    }

    if ((error as { statusCode?: number })?.statusCode) {
      throw error;
    }

    console.error('[course-maker-ai] unexpected Gemini call failure', {
      model,
      error: error instanceof Error ? error.message : String(error),
    });
    throw Object.assign(new Error(`Gemini request failed: ${String(error)}`), {
      statusCode: 502,
      code: 'upstream_failure',
    });
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    console.log('[course-maker-ai] OPTIONS preflight received');
    return jsonResponse(200, { ok: true });
  }

  if (req.method !== 'POST') {
    console.warn('[course-maker-ai] unsupported method', { method: req.method });
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  console.log('[course-maker-ai] incoming request received');

  try {
    const rawBody = await req.text();
    console.log('[course-maker-ai] request body received', {
      length: rawBody.length,
      preview: truncateForLog(rawBody, 300),
    });

    const body = rawBody ? JSON.parse(rawBody) : {};
    console.log('[course-maker-ai] request JSON parsed');

    const payload = ensureCourseRequest((body?.course ?? body) as CourseRequest);
    console.log('[course-maker-ai] required topic/title validated', {
      title: safeText(payload.title, 'missing'),
      subject: safeText(payload.subject, 'missing'),
      attachmentCount: payload.attachments?.length ?? 0,
    });

    const raw = await callGemini(payload);
    console.log('[course-maker-ai] Gemini response received and validated');

    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      const start = raw.indexOf('{');
      const end = raw.lastIndexOf('}');
      if (start === -1 || end === -1 || end <= start) {
        throw Object.assign(new Error('Gemini response was not valid JSON.'), {
          statusCode: 502,
          code: 'invalid_json_response',
        });
      }
      parsed = JSON.parse(raw.substring(start, end + 1));
    }

    console.log('[course-maker-ai] generated course JSON validated');

    return jsonResponse(200, {
      status: 200,
      result: {
        course: parsed,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Course generation failed';
    const statusCode = (error as { statusCode?: number })?.statusCode ?? 500;
    const code = (error as { code?: string })?.code ?? 'internal_error';

    console.error('[course-maker-ai] request failed', {
      statusCode,
      code,
      message: truncateForLog(message),
      error: truncateForLog(error),
    });

    return jsonResponse(statusCode, {
      status: statusCode,
      result: {
        error: {
          status: statusCode,
          message,
          code,
        },
      },
    });
  }
});
