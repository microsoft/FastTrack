import { QueryClient } from "@tanstack/react-query";

// Throttling (429) and a slow query the connector gateway gave up waiting on
// (202 Accepted with no result, 502/503/504). The query usually finishes and is
// cached server-side, so a retry often returns it.
const TRANSIENT_STATUS = new Set([202, 429, 502, 503, 504]);
// For errors with no numeric status: the same codes, or a throttling, bad-gateway
// or timeout message.
const TRANSIENT_TEXT =
  /\b(202|429|502|503|504)\b|throttl|too many requests|bad gateway|gateway time-?out|timed? ?out/i;

// Generated apps throw the connector SDK's `result.error` as-is: a plain object
// with a numeric `status` and a `message`, sometimes wrapped as a `cause`. When
// it has a status, the status decides.
export function isTransient(error: unknown, depth = 0): boolean {
  if (typeof error === "string") return TRANSIENT_TEXT.test(error);
  if (!error || typeof error !== "object" || depth > 3) return false;
  const { status, statusCode, message, cause } = error as Record<string, unknown>;
  const code = typeof status === "number" ? status : statusCode;
  if (typeof code === "number") return TRANSIENT_STATUS.has(code);
  if (typeof message === "string" && TRANSIENT_TEXT.test(message)) return true;
  return cause !== undefined && isTransient(cause, depth + 1);
}

// Transient failures get four retries, other failures one.
export function shouldRetry(failureCount: number, error: unknown): boolean {
  return failureCount < (isTransient(error) ? 4 : 1);
}

// Transient failures back off exponentially from 2s (capped at 30s) with jitter,
// so queries throttled together do not retry together. Other failures keep
// TanStack's default delay.
export function retryDelay(attempt: number, error: unknown): number {
  if (!isTransient(error)) return Math.min(1000 * 2 ** attempt, 30000);
  const ceiling = Math.min(2000 * 2 ** attempt, 30000);
  return ceiling / 2 + Math.random() * (ceiling / 2);
}

// Single shared TanStack Query client.
// `staleTime` is finite so live connector/API data refetches (e.g. on window
// focus). For purely in-memory state — sample data that never changes on its
// own — override per-query with `staleTime: Infinity` to avoid pointless refetch.
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: shouldRetry,
      retryDelay,
    },
  },
});
