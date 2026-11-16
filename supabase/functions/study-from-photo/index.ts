import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type StudyRequest = {
  prompt?: string;
  imageBase64?: string;
  mimeType?: string;
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

function ensureValidRequest(payload: unknown): StudyRequest {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw Object.assign(new Error('Missing request body.'), {
      statusCode: 400,
      code: 'invalid_request',
    });
  }

  const request = payload as Record<string, unknown>;
  const prompt = safeText(request.prompt, '');
  if (!prompt) {
    throw Object.assign(new Error('Prompt is required.'), {
      statusCode: 400,
      code: 'invalid_request',
    });
  }

  const imageBase64 = safeText(request.imageBase64, '');
  const mimeType = safeText(request.mimeType, 'image/jpeg');

  return {
    prompt,
    imageBase64: imageBase64 || undefined,
    mimeType: mimeType || 'image/jpeg',
  };
}

function resolveGeminiModel(): string {
  const configured = safeText(Deno.env.get('GEMINI_MODEL'), '');
  return configured || 'gemini-3.8-flash';
}

function buildGeminiParts(request: StudyRequest) {
  const parts: unknown[] = [
    {
      text: `You are an expert educational tutor. Analyze the image or text carefully and respond with a clear, accurate explanation.

Instructions:
- Explain the concept(s) shown in the material.
- If the image is unclear, say so.
- Do not guess beyond what is visible.
- Keep the answer educational, structured, and practical.
- Return only the final answer text, not JSON wrappers or markdown fences.

Student request:
${request.prompt}`,
    },
  ];

  if (request.imageBase64 && request.imageBase64.trim()) {
    const mimeType = safeText(request.mimeType, 'image/jpeg');
    parts.push({
      inline_data: {
        mime_type: mimeType,
        data: request.imageBase64,
      },
    });
  }

  return parts;
}

function extractTextFromGemini(data: unknown): string {
  const candidates = Array.isArray((data as any)?.candidates)
    ? (data as any).candidates
    : [];

  const combined = candidates
    .map((candidate: any) => {
      const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
      return parts
        .map((part: any) => {
          if (typeof part?.text === 'string') return part.text;
          return '';
        })
        .join('');
    })
    .join('')
    .trim();

  return combined;
}

async function callGemini(request: StudyRequest) {
  const apiKey = Deno.env.get('STUDY_PHOTO_GEMINI_KEY');
  console.log('[study-from-photo] checking Gemini secret', {
    hasSecret: !!apiKey,
    secretLength: apiKey ? apiKey.length : 0,
  });

  if (!apiKey) {
    throw Object.assign(new Error('STUDY_PHOTO_GEMINI_KEY is missing'), {
      statusCode: 500,
      code: 'missing_secret',
    });
  }

  const model = resolveGeminiModel();
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const payload = {
    contents: [{ role: 'user', parts: buildGeminiParts(request) }],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 2000,
    },
  };

  console.log('[study-from-photo] sending Gemini request', {
    model,
    hasImage: !!request.imageBase64,
    promptLength: request.prompt.length,
  });

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(90_000),
    });

    const responseText = await response.text();
    console.log('[study-from-photo] Gemini HTTP status received', {
      model,
      status: response.status,
      bodyPreview: truncateForLog(responseText),
    });

    if (!response.ok) {
      const errorText = truncateForLog(responseText);
      console.error('[study-from-photo] Gemini HTTP failure', {
        model,
        status: response.status,
        errorText,
      });

      if (response.status === 400 || response.status === 404) {
        throw Object.assign(new Error(`Gemini request rejected (${model}): ${errorText}`), {
          statusCode: 400,
          code: 'invalid_request',
        });
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
        statusCode: 503,
        code: 'upstream_failure',
      });
    }

    let data: unknown;
    try {
      data = JSON.parse(responseText);
    } catch {
      throw Object.assign(new Error('Gemini response was not valid JSON.'), {
        statusCode: 502,
        code: 'invalid_json_response',
      });
    }

    const firstText = extractTextFromGemini(data);
    console.log('[study-from-photo] Gemini response parsed', {
      model,
      textLength: firstText.length,
    });

    if (!firstText) {
      throw Object.assign(new Error('Gemini returned no generated explanation text.'), {
        statusCode: 502,
        code: 'empty_response',
      });
    }

    return {
      status: 200,
      result: {
        candidates: [
          {
            content: {
              parts: [{ text: firstText }],
            },
          },
        ],
      },
    };
  } catch (error) {
    if (
      error instanceof Error &&
      (error.name === 'TimeoutError' || error.message.toLowerCase().includes('timeout'))
    ) {
      console.error('[study-from-photo] Gemini request timed out', { model });
      throw Object.assign(new Error('Gemini request timed out.'), {
        statusCode: 504,
        code: 'timeout',
      });
    }

    if ((error as { statusCode?: number })?.statusCode) {
      throw error;
    }

    console.error('[study-from-photo] unexpected failure', {
      model,
      error: error instanceof Error ? error.message : String(error),
    });

    throw Object.assign(new Error(`Gemini request failed: ${String(error)}`), {
      statusCode: 503,
      code: 'upstream_failure',
    });
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    console.log('[study-from-photo] OPTIONS preflight received');
    return jsonResponse(200, { ok: true });
  }

  if (req.method !== 'POST') {
    console.warn('[study-from-photo] unsupported method', { method: req.method });
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  console.log('[study-from-photo] incoming request received');

  try {
    const rawBody = await req.text();
    console.log('[study-from-photo] request body received', {
      length: rawBody.length,
      preview: truncateForLog(rawBody, 300),
    });

    const parsed = rawBody ? JSON.parse(rawBody) : {};
    const request = ensureValidRequest(parsed);

    const response = await callGemini(request);
    return jsonResponse(200, response);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'AI request failed';
    const statusCode = (error as { statusCode?: number })?.statusCode ?? 500;
    const code = (error as { code?: string })?.code ?? 'internal_error';

    console.error('[study-from-photo] request failed', {
      statusCode,
      code,
      message: truncateForLog(message),
      error: truncateForLog(error),
    });

    return jsonResponse(200, {
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
