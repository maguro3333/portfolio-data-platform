const WINDOW_MS = 60_000;
const MAX_REQUESTS = 5;

type RateEntry = {
  count: number;
  resetAt: number;
};

const globalRateState = globalThis as typeof globalThis & {
  __analystRateLimit?: Map<string, RateEntry>;
};

const rateLimit =
  globalRateState.__analystRateLimit ?? new Map<string, RateEntry>();
globalRateState.__analystRateLimit = rateLimit;

export function getClientIp(request: Request) {
  const forwarded = request.headers.get("x-forwarded-for");
  return (
    forwarded?.split(",")[0]?.trim() ||
    request.headers.get("x-real-ip") ||
    "unknown"
  );
}

export function checkRateLimit(ip: string) {
  const now = Date.now();
  if (rateLimit.size > 1_000) {
    for (const [key, entry] of rateLimit) {
      if (entry.resetAt <= now) {
        rateLimit.delete(key);
      }
    }
  }
  const current = rateLimit.get(ip);

  if (!current || current.resetAt <= now) {
    rateLimit.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return { allowed: true, retryAfterSeconds: 0 };
  }

  if (current.count >= MAX_REQUESTS) {
    return {
      allowed: false,
      retryAfterSeconds: Math.max(
        1,
        Math.ceil((current.resetAt - now) / 1000),
      ),
    };
  }

  current.count += 1;
  return { allowed: true, retryAfterSeconds: 0 };
}
