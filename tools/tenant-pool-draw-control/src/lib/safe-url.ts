// Allowlist URL schemes before rendering links built from untrusted/connector
// data (email senders, file links, SharePoint items, etc.). Returns the URL when
// its scheme is safe to navigate to, otherwise `undefined` — so a `javascript:`,
// `data:`, or `vbscript:` URL never becomes a click-to-execute vector.
//
//   <a href={safeUrl(item.link) ?? "#"}>…</a>
//
// Relative URLs (path / query / hash) are allowed; protocol-relative (`//host`)
// and absolute URLs are scheme-validated against the allowlist.
const SAFE_SCHEMES = new Set(["http:", "https:", "mailto:", "tel:"]);

export function safeUrl(url: string | null | undefined): string | undefined {
  if (!url) return undefined;
  const trimmed = url.trim();
  if (!trimmed) return undefined;
  // Browsers normalize backslashes to forward slashes in the authority
  // position, so `/\\host` and `/\/host` resolve cross-origin exactly like
  // `//host`. Normalize leading `\` → `/` before the path-only check below so a
  // backslash form can't slip an open-redirect past it.
  const normalized = trimmed.replace(/^[\\/]+/, (m) => m.replace(/\\/g, "/"));
  // Same-document relative navigation (query / hash) or a relative/absolute
  // path — never cross-origin, never a script-execution vector, so no scheme to
  // validate. A protocol-relative `//host` is deliberately EXCLUDED here (it
  // navigates cross-origin, inheriting the page scheme) and falls through to the
  // scheme-validating parse below, so a non-http(s) resolved scheme is rejected.
  if (/^[.#?]/.test(normalized)) return trimmed;
  if (normalized.startsWith("/") && !normalized.startsWith("//")) return trimmed;
  try {
    const parsed = new URL(trimmed, window.location.origin);
    return SAFE_SCHEMES.has(parsed.protocol) ? trimmed : undefined;
  } catch {
    return undefined;
  }
}
