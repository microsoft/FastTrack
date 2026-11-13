/**
 * Console + runtime-error capture.
 *
 *  (1) Forwards console.log/warn/error to the Cowork parent frame via
 *      postMessage so the UX can display console output alongside the
 *      preview.
 *  (2) During authoring, POSTs errors (console.error, window.onerror, unhandledrejection)
 *      to the Vite dev server at `./__dev/console` — under the preview
 *      iframe that resolves onto the runtime preview proxy, whose POST arm
 *      forwards exactly this path (#24067). The dev-reload SSE plugin
 *      appends them to `.browser-errors.log` in the app root so the
 *      app-builder agent can inspect runtime failures that never surface
 *      to `bun run check` — notably React's "Maximum update depth
 *      exceeded" and other re-render loops caught by ErrorBoundary.
 */

const originalConsole = {
  log: console.log.bind(console),
  warn: console.warn.bind(console),
  error: console.error.bind(console),
};

const DEV_CONSOLE_PATH = "./__dev/console";

// The iframe's own document URL carries the preview bearer token
// (/v1/preview/{token}/dev/...) — a live 24 h credential. location.href,
// error.filename and stack-frame URLs would otherwise persist it into
// .browser-errors.log, which the app-builder agent reads. Scrub the token
// segment from the serialized body: ONE chokepoint covers url, stack,
// filename, message and componentStack alike (the dev-reload plugin repeats
// the scrub server-side before writing). JSON.stringify never escapes "/",
// so the segment survives serialization intact for the regex to find.
const PREVIEW_TOKEN_RE = /\/v1\/preview\/[^/\s"'\\]+/g;
const scrubPreviewToken = (s: string): string =>
  s.replace(PREVIEW_TOKEN_RE, "/v1/preview/<token>");

// Target origin for ``window.parent.postMessage``. S360 (SM03080) flags
// wildcard ``"*"`` because any cross-origin parent can read those events.
// Resolution order:
//   (1) ``VITE_COWORK_PARENT_ORIGIN`` — explicit override the orchestrator
//       can inject into ``.env.development.local`` alongside ``VITE_BASE``.
//   (2) ``window.location.ancestorOrigins[0]`` — Chromium/WebKit only, but
//       it's the actual embedding origin and can't be spoofed by the child.
//   (3) ``window.location.origin`` — last-resort same-origin guess. The
//       Cowork preview proxy serves us same-origin to the host shell, so
//       this still beats wildcard for the common case.
// Computed once at module load; the ancestor never changes for the life of
// the iframe.
const PARENT_ORIGIN: string = (() => {
  const fromEnv = import.meta.env.VITE_COWORK_PARENT_ORIGIN;
  if (typeof fromEnv === "string" && fromEnv.length > 0) {
    return fromEnv;
  }
  const ancestors = window.location.ancestorOrigins;
  if (ancestors && ancestors.length > 0 && ancestors[0]) {
    return ancestors[0];
  }
  return window.location.origin;
})();

// Dedup identical errors fired in bursts — an infinite-loop component
// can emit the same stack 1000 times per second. Keyed on (kind + first
// stack line). 500ms quiet window is short enough to still catch a
// legitimate retry and long enough to suppress render-loop spam.
const DEDUP_WINDOW_MS = 500;
let lastSignature: string | null = null;
let lastSignatureTime = 0;

function postToParent(level: string, args: unknown[]) {
  try {
    const message = args
      .map((a) => (typeof a === "object" ? JSON.stringify(a, null, 2) : String(a)))
      .join(" ");
    window.parent.postMessage(
      { type: "console", level, message, timestamp: Date.now() },
      PARENT_ORIGIN
    );
  } catch {
    /* ignore serialization errors */
  }
}

function postToDevServer(kind: string, payload: Record<string, unknown>) {
  // Vite supplies this context during serve (even with hmr:false), never build.
  if (!import.meta.hot) return;

  const sig = `${kind}|${(payload.stack as string | undefined)?.split("\n", 2)[0] ?? payload.message ?? ""}`;
  const now = Date.now();
  if (sig === lastSignature && now - lastSignatureTime < DEDUP_WINDOW_MS) {
    return;
  }
  lastSignature = sig;
  lastSignatureTime = now;

  try {
    void fetch(DEV_CONSOLE_PATH, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: scrubPreviewToken(
        JSON.stringify({
          kind,
          time: now,
          url: location.href,
          ...payload,
        }),
      ),
      keepalive: true,
    }).catch(() => {
      /* dev server may be restarting — drop silently */
    });
  } catch {
    /* ignore */
  }
}

function serializeArgs(args: unknown[]): { message: string; stack: string | null } {
  let stack: string | null = null;
  const parts: string[] = [];
  for (const a of args) {
    if (a instanceof Error) {
      parts.push(a.message);
      stack = stack ?? a.stack ?? null;
    } else if (typeof a === "object" && a !== null) {
      try {
        parts.push(JSON.stringify(a));
      } catch {
        parts.push(String(a));
      }
    } else {
      parts.push(String(a));
    }
  }
  return { message: parts.join(" "), stack };
}

/**
 * Private-only runtime-error reporter for the ErrorBoundary.
 *
 * Routes the *real* error and React component stack to the console
 * implementation captured before this module installs its parent-forwarding
 * wrappers, plus an authoring-only best-effort POST to `./__dev/console`.
 * It deliberately does NOT call `postToParent`, so render-crash details never
 * reach the parent frame through the retained console-forwarding channel
 * above. The parent frame receives only the fixed, detail-free crash signal
 * emitted separately by `cowork-parent-transport.ts`.
 */
export function reportPrivateRuntimeError(
  label: string,
  error: unknown,
  detail?: string | null,
): void {
  // Bypass this module's parent-forwarding wrapper. An earlier bootstrap script
  // may already have wrapped console.error for local websocket noise filtering.
  originalConsole.error(label, error, detail ?? "");
  const { message, stack } = serializeArgs([error]);
  postToDevServer("app.error", {
    label,
    message,
    stack,
    componentStack: detail ?? null,
  });
}
console.log = (...args: unknown[]) => {
  originalConsole.log(...args);
  postToParent("log", args);
};
console.warn = (...args: unknown[]) => {
  originalConsole.warn(...args);
  postToParent("warn", args);
};
console.error = (...args: unknown[]) => {
  originalConsole.error(...args);
  postToParent("error", args);
  const { message, stack } = serializeArgs(args);
  postToDevServer("console.error", { message, stack });
};

window.addEventListener("error", (ev) => {
  postToDevServer("window.error", {
    message: ev.message,
    filename: ev.filename,
    lineno: ev.lineno,
    colno: ev.colno,
    stack: ev.error?.stack ?? null,
  });
});

window.addEventListener("unhandledrejection", (ev) => {
  const reason = ev.reason;
  const hasMessage = typeof reason === "object" && reason !== null && "message" in reason;
  postToDevServer("unhandledrejection", {
    message: hasMessage ? String((reason as { message: unknown }).message) : String(reason),
    stack: (reason as { stack?: string } | null)?.stack ?? null,
  });
});
