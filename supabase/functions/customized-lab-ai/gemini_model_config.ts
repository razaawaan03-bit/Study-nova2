export const DEFAULT_PRIMARY_MODEL = 'gemini-3.8-flash';
export const DEFAULT_FALLBACK_MODEL = 'gemini-3.5-flash-lite';

export const SUPPORTED_GENERATE_CONTENT_MODELS = new Set([
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
]);

export function normalizeGeminiModelName(
  value: string | undefined,
  fallback: string,
): string {
  const candidate = (value ?? '').trim().toLowerCase();
  if (!candidate) {
    return fallback;
  }

  if (!candidate.startsWith('gemini-')) {
    return fallback;
  }

  return SUPPORTED_GENERATE_CONTENT_MODELS.has(candidate)
    ? candidate
    : fallback;
}

export function resolveGeminiModels(
  envOverrides: Record<string, string | undefined> = {},
): { primary: string; fallback: string; ordered: string[] } {
  const primaryConfigured = envOverrides.CUSTOM_LAB_GEMINI_MODEL ??
    envOverrides.GEMINI_MODEL;
  const fallbackConfigured = envOverrides.CUSTOM_LAB_GEMINI_FALLBACK_MODEL ??
    envOverrides.GEMINI_FALLBACK_MODEL;

  const primary = normalizeGeminiModelName(primaryConfigured, DEFAULT_PRIMARY_MODEL);
  const fallback = normalizeGeminiModelName(
    fallbackConfigured,
    DEFAULT_FALLBACK_MODEL,
  );

  const ordered = [primary];
  if (fallback !== primary) {
    ordered.push(fallback);
  }

  return { primary, fallback, ordered };
}

export function shouldUseFallbackForGeminiError(
  statusCode?: number,
  code?: string,
): boolean {
  if (code === 'upstream_unavailable') {
    return true;
  }

  if (typeof statusCode !== 'number') {
    return false;
  }

  return [429, 500, 502, 503, 504].includes(statusCode);
}

export async function runGeminiRequestWithFallback<T>(
  request: T,
  runModel: (model: string, maxAttempts: number) => Promise<T>,
  envOverrides: Record<string, string | undefined> = {},
  maxAttempts = 3,
): Promise<T> {
  const { ordered } = resolveGeminiModels(envOverrides);
  let attemptsUsed = 0;
  let lastError: unknown;

  for (let index = 0; index < ordered.length; index++) {
    const model = ordered[index];
    const remaining = maxAttempts - attemptsUsed;
    if (remaining <= 0) break;

    const maxAttemptsForModel = Math.min(remaining, index === 0 ? 2 : 1);

    try {
      return await runModel(model, maxAttemptsForModel);
    } catch (error) {
      lastError = error;
      const statusCode = (error as { statusCode?: number })?.statusCode;
      const code = (error as { code?: string })?.code;

      attemptsUsed += maxAttemptsForModel;

      if (!shouldUseFallbackForGeminiError(statusCode, code)) {
        throw error;
      }

      if (index === ordered.length - 1 || attemptsUsed >= maxAttempts) {
        throw error;
      }
    }
  }

  if (lastError) {
    throw lastError;
  }

  throw new Error('No Gemini models were available for this request.');
}
