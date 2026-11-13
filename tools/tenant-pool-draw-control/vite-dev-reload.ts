/* Dev reload plugin (SSE + HMR mirror, build errors only).
 *
 * INLINED scaffold infra (do NOT edit - see AGENTS.md). Co-located next to
 * vite.config.ts and imported relatively so the file travels with the app
 * source tree as-is. `apply: 'serve'`, so it is inert during `vite build` and
 * the published bundle contains none of it.
 */
import * as fs from "node:fs";
import * as path from "node:path";

import { normalizePath } from "vite";
import type { ModuleNode, Plugin, ViteDevServer } from "vite";

const DEBOUNCE_MS = 80;
const HEARTBEAT_MS = 30000;
const SSE_PATH = "/__dev/reload";
const CLIENT_SSE_PATH = "__dev/reload";
const CSS_EXTENSIONS = [".css", ".scss", ".sass", ".less", ".styl", ".pcss"];

const CONSOLE_PATH = "/__dev/console";
const BROWSER_ERRORS_LOG = ".browser-errors.log";
// The deploy gate's persisted high-water cursor (written by the app-builder
// agent's pre-deploy sequence filter, in the same app dir this server runs
// in). Read here only to seed the sequence past it on restart — never written.
const BROWSER_ERRORS_SEQ = ".browser-errors.seq";
const BROWSER_ERRORS_LOG_CAP_BYTES = 64 * 1024;

const RELOAD_FULL_PATH = "/__dev/reload-full";
const LOOPBACK_PEERS = new Set(["127.0.0.1", "::1", "::ffff:127.0.0.1"]);

// The iframe's document URL carries the stateless 24 h KIND_APP_DEV bearer
// token (/v1/preview/{token}/dev/...), and browser error reports embed it via
// location.href, error.filename and stack-frame URLs. .browser-errors.log is
// agent-facing (the deploy gate prints entries into the app-builder
// transcript), so the token segment is scrubbed BEFORE an entry is persisted
// or broadcast. console-capture.ts applies the same scrub client-side before
// POSTing; this is the producer-side belt over that suspender. Best-effort by
// nature: it removes the accidental leak — a page that wants to exfiltrate
// its own token can encode it past any regex — so a scrubbed log is not
// proof of a token-free channel.
const PREVIEW_TOKEN_RE = /\/v1\/preview\/[^/\s"'\\]+/g;
const scrubPreviewToken = (s: string): string =>
  s.replace(PREVIEW_TOKEN_RE, "/v1/preview/<token>");

// Boot-stage tracker parent channel. A copy of `COWORK_PARENT_ORIGINS` in
// src/lib/cowork-parent-transport.ts, because this file is refreshed into
// existing apps on its own and cannot import app source; a container test pins
// the two lists equal, so adding a host fails until both are updated.
export const BOOT_STAGE_PARENT_ORIGINS: readonly string[] = [
  "https://agentbuilder.local.microsoft.com:44300",
  "http://localhost:44300",
  "https://local.loop.microsoft.com:8080",
  "https://m365.cloud.microsoft",
  "https://copilot.cloud.microsoft",
  "https://m365copilotapp.svc.cloud.microsoft",
  "https://cr.m365copilotapp.svc.cloud.microsoft",
  "https://www.microsoft365.com",
  "https://outlook.office.com",
];
export const BOOT_STAGE_MESSAGE_TYPE = "aether-boot-stage";
// A missing named export is a SyntaxError in every engine, worded per engine:
// V8 "does not provide an export named", SpiderMonkey "import not found",
// JavaScriptCore "Importing binding name ... is not found".
export const MISSING_EXPORT_PATTERN =
  /does not provide an export named|import not found|Importing binding name/;

// A classic inline script, prepended to <head> of the dev index.html, so it
// runs before any module script: a module-graph LINK failure (missing export,
// browser-side syntax error) and a failed module fetch (Vite answers a
// transform or resolve failure with a 500 on the importer) happen before
// console-capture.ts has evaluated, so nothing else in the page can see them
// and the preview stays blank. The tracker records the boot stages on
// window.__aetherBoot, posts each stage to the Cowork host as a fixed-vocabulary
// envelope (stage, category, status, counts; never a message, path or URL),
// and POSTs a boot failure, with its details, to the app root's __dev/console so it lands in
// .browser-errors.log. Only failures before #root first renders are reported,
// at most one per page load; a runtime throw is left to console-capture.ts,
// which is installed by then and already logs it, and a module status that does
// not point at app source (502, 503, 504) is staged but not logged.
//
// String.raw keeps the regex backslashes literal; the body may use no backtick
// and no dollar-brace beyond the three constant interpolations.
export const BOOT_STAGE_TRACKER_SCRIPT = String.raw`
(function () {
  if (window.__aetherBoot) return;
  var ORIGINS = ${JSON.stringify(BOOT_STAGE_PARENT_ORIGINS)};
  var TYPE = ${JSON.stringify(BOOT_STAGE_MESSAGE_TYPE)};
  var TOKEN_RE = /\/v1\/preview\/[^\/\s"'\\]+/g;
  var MESSAGE_CAP = 2000;
  var MODULES_CAP = 5;
  var boot = { stages: [], error: null };
  window.__aetherBoot = boot;
  // Large apps fetch more than the default 250 resources before a late failure.
  try { if (performance.setResourceTimingBufferSize) performance.setResourceTimingBufferSize(4096); } catch (e) {}
  var own = Object.prototype.hasOwnProperty;
  var embedded = window.parent !== window;
  var rendered = false;
  var failed = false;
  function scrub(s) { return String(s).replace(TOKEN_RE, '/v1/preview/<token>'); }
  function cap(s) { return s == null ? null : String(s).slice(0, MESSAGE_CAP); }
  function pathOf(url) {
    try { var u = new URL(url, location.href); return scrub(u.pathname + u.search); }
    catch (e) { return scrub(url); }
  }
  function stage(name, fields) {
    for (var i = 0; i < boot.stages.length; i++) if (boot.stages[i].stage === name) return;
    var rec = { stage: name, t: Math.round(performance.now()) };
    var msg = { type: TYPE, v: 1, stage: name, t: rec.t };
    for (var k in fields) if (own.call(fields, k)) { rec[k] = fields[k]; msg[k] = fields[k]; }
    boot.stages.push(rec);
    if (!embedded) return;
    for (var j = 0; j < ORIGINS.length; j++) {
      try { window.parent.postMessage(msg, ORIGINS[j]); } catch (e) {}
    }
  }
  function moduleEntries() {
    var out = [];
    var list = performance.getEntriesByType ? performance.getEntriesByType('resource') : [];
    for (var i = 0; i < list.length; i++) {
      var e = list[i];
      if (e.initiatorType !== 'script' && e.initiatorType !== 'other') continue;
      var u;
      try { u = new URL(e.name); } catch (err) { continue; }
      if (u.origin !== location.origin || u.pathname.indexOf('/__dev/') >= 0) continue;
      out.push(e);
    }
    return out;
  }
  function failedStatus(e) { return typeof e.responseStatus === 'number' && e.responseStatus >= 400; }
  // The proxy accepts the console POST only at the app root, and a nested
  // client route makes './__dev/console' resolve below it; Vite's injected
  // client script sits at the app root, so its URL locates the endpoint.
  function consoleUrl() {
    var vc = document.querySelector('script[type="module"][src*="/@vite/client"]');
    if (vc && vc.src) return vc.src.slice(0, vc.src.indexOf('@vite/client')) + '__dev/console';
    return './__dev/console';
  }
  function post(entry) {
    try {
      fetch(consoleUrl(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: scrub(JSON.stringify(entry)),
        keepalive: true
      }).catch(function () {});
    } catch (e) {}
  }
  // Reads #root itself rather than trusting the observer, which has not run yet
  // when a module renders and throws in the same task.
  function hasRendered() {
    if (rendered) return true;
    var root = document.getElementById('root');
    if (root && root.children.length) { onRendered(); return true; }
    return false;
  }
  // A parse or link failure is raised before any code runs, so its error has
  // no call frames; a SyntaxError thrown by running code (JSON.parse, RegExp)
  // carries V8's "    at" or SpiderMonkey/JSC's "@url:line:col" frames.
  function thrownByCode(err) {
    var s = err && err.stack ? String(err.stack) : '';
    return /\n\s+at |@\S*:\d+:\d+/.test(s);
  }
  function fail(category, detail, logIt) {
    if (failed || hasRendered()) return null;
    failed = true;
    boot.error = { category: category, detail: detail };
    stage('error', { category: category });
    if (!logIt) return null;
    return function () {
      var entry = { kind: 'boot.error', category: category };
      for (var k in detail) if (own.call(detail, k)) entry[k] = detail[k];
      entry.time = Date.now();
      entry.url = location.href;
      post(entry);
    };
  }
  // The runtime's JSON error layer wraps an untyped 5xx body as
  // {"error":{"details":{"original_error": <Vite's HTML>}}}.
  function viteErrorMessage(text) {
    try {
      var env = JSON.parse(text);
      var orig = env && env.error && env.error.details && env.error.details.original_error;
      if (typeof orig === 'string') text = orig;
    } catch (e) {}
    var m = /const error = (\{.*\})\s*\n/.exec(text);
    if (!m) return null;
    try { var o = JSON.parse(m[1]); return typeof o.message === 'string' ? o.message : null; }
    catch (e) { return null; }
  }
  function onModuleFetchFailed(src) {
    var bad = [];
    var all = moduleEntries();
    var dropped = false;
    for (var i = 0; i < all.length; i++) {
      if (failedStatus(all[i])) bad.push(all[i]);
      else if (all[i].responseStatus === 0) dropped = true;
    }
    var first = bad[0];
    var detail = { message: null, modules: [] };
    for (var j = 0; j < bad.length && j < MODULES_CAP; j++) {
      detail.modules.push({ path: pathOf(bad[j].name), status: bad[j].responseStatus });
    }
    // No failed fetch: the dev server's SPA fallback answered the script with
    // index.html (200), which the browser refused as a module.
    if (!bad.length && src) {
      var es = performance.getEntriesByName ? performance.getEntriesByName(src) : [];
      var last = es[es.length - 1];
      detail.modules.push({ path: pathOf(src), status: last && typeof last.responseStatus === 'number' ? last.responseStatus : null });
    }
    var compile = !!first && first.responseStatus === 500;
    // Only a 404, a 500 or the SPA fallback points at app source. Any other
    // status (the proxy's 504 read timeout and 503 transport fault, a 502 or
    // 504 during dependency pre-bundling) and a connection the network dropped
    // (Chromium records it with status 0) are staged to the parent but not
    // logged, so they cannot fail the deploy gate of an app with no fault.
    var logIt = first ? first.responseStatus === 404 || compile : !dropped;
    var send = fail(compile ? 'compile_error' : 'module_fetch_failed', detail, logIt);
    if (!send) return;
    if (!compile) { send(); return; }
    fetch(first.name, { cache: 'no-store' })
      .then(function (r) { return r.text(); })
      .then(function (t) { detail.message = cap(viteErrorMessage(t)); }, function () {})
      .then(send);
  }
  window.addEventListener('error', function (ev) {
    if (failed || hasRendered()) return;
    var t = ev.target;
    if (t && t !== window && t.tagName === 'SCRIPT') {
      var sameOrigin = false;
      try { sameOrigin = new URL(t.src, location.href).origin === location.origin; } catch (e) {}
      if (t.type === 'module' && sameOrigin) setTimeout(function () { onModuleFetchFailed(t.src); }, 0);
      return;
    }
    if (typeof ErrorEvent === 'undefined' || !(ev instanceof ErrorEvent)) return;
    var msg = String(ev.message || '');
    var where = {
      message: cap(msg),
      file: ev.filename ? pathOf(ev.filename) : null,
      line: ev.lineno || null,
      col: ev.colno || null
    };
    var send;
    if (${MISSING_EXPORT_PATTERN.toString()}.test(msg)) send = fail('missing_export', where, true);
    else if (/SyntaxError/.test(msg) && !thrownByCode(ev.error)) send = fail('syntax_error', where, true);
    else send = fail('runtime_throw', where, false);
    if (send) send();
  }, true);
  stage('html');
  function onRendered() {
    if (rendered) return;
    rendered = true;
    stage('root_rendered');
  }
  document.addEventListener('DOMContentLoaded', function () {
    var scripts = document.querySelectorAll('script[type="module"][src]');
    for (var i = 0; i < scripts.length; i++) {
      var src = scripts[i].src;
      if (src.indexOf('/@vite/') >= 0) continue;
      var es = performance.getEntriesByName ? performance.getEntriesByName(src) : [];
      var e = es[es.length - 1];
      if (e) stage('entry_fetched', { status: typeof e.responseStatus === 'number' ? e.responseStatus : null });
      break;
    }
    var root = document.getElementById('root');
    if (!root) return;
    if (root.children.length) { onRendered(); return; }
    var mo = new MutationObserver(function () {
      if (root.children.length) { mo.disconnect(); onRendered(); }
    });
    mo.observe(root, { childList: true });
  });
  window.addEventListener('load', function () {
    var all = moduleEntries();
    var bad = 0;
    for (var i = 0; i < all.length; i++) if (failedStatus(all[i])) bad++;
    stage('modules_fetched', { count: all.length, failed: bad });
  });
})();`;

interface PendingChange {
  file: string;
  isCSS: boolean;
  modules: ModuleNode[];
}

export interface DevReloadScheduler {
  setTimeout: typeof setTimeout;
  clearTimeout: typeof clearTimeout;
  setInterval: typeof setInterval;
  clearInterval: typeof clearInterval;
}

export function normalizeWatcherModulePath(
  file: string,
  platform: NodeJS.Platform = process.platform,
): string {
  return normalizePath(platform === "win32" ? file.replaceAll("\\", "/") : file);
}

const DEFAULT_SCHEDULER: DevReloadScheduler = {
  setTimeout,
  clearTimeout,
  setInterval,
  clearInterval,
};

export default function devReload(
  scheduler: DevReloadScheduler = DEFAULT_SCHEDULER,
): Plugin {
  let server: ViteDevServer | null = null;
  let version = 1;
  let debounceTimer: ReturnType<typeof setTimeout> | null = null;
  let lastBuildStart = 0;
  let lastBuildDuration = 0;

  const pending = new Map<string, PendingChange>();
  const clients = new Set<any>();
  let heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  let errorHooksInstalled = false;
  let configuredWatcher: ViteDevServer["watcher"] | null = null;
  let configuredHttpServer: ViteDevServer["httpServer"] = null;
  let queueChangeHandler: ((file: string) => void) | null = null;
  let configuredWs: any = null;
  let originalWsSend: ((...args: any[]) => any) | null = null;
  let patchedWsSend: ((...args: any[]) => any) | null = null;
  const cwd = process.cwd();
  // Vite reports module ids with forward slashes even on Windows, while
  // process.cwd() uses the platform separator, so a bare replaceAll(cwd, ...)
  // silently fails to redact an `id` on Windows. Redact both spellings.
  //
  // This is scrubbing, NOT a guarantee. It keys on process.cwd() alone, and in
  // the container the dev server's cwd is the app directory while this plugin,
  // the Vite CLI and the dep cache all live elsewhere in the image -- so a
  // stack frame pointing into the template dir or the cache passes through
  // unredacted. What survives is image-infrastructure paths and an app-id
  // GUID, not customer content, but do not read a redacted frame as proof that
  // every path in it was rewritten.
  const cwdPosix = cwd.split(String.fromCharCode(92)).join("/");
  const redact = (s: string) =>
    s.replaceAll(cwd, "<cwd>").replaceAll(cwdPosix, "<cwd>");
  // `String(err)` on a reason-less `Promise.reject()` yields the literal
  // "undefined", which is truthy and would render full-screen as the word
  // "undefined" — worse than the blank frame this overlay exists to replace.
  // Collapse the spellings that carry no diagnostic to "" so emitters can
  // decline to broadcast rather than paint a placeholder over the app.
  const USELESS_MESSAGES = ["", "undefined", "null", "[object Object]"];
  // ONE rule for "are these the same file", used on both sides of the wire.
  //
  // The same question is asked twice: the client asks whether a changed CSS
  // file is the one the overlay describes, and the server asks whether a
  // changed file invalidates the failure it is holding for replay. The two
  // must not be able to disagree, so the client's copy inside the injected
  // script is a transliteration of this, and the shared case table in the
  // tests pins them to the same answers.
  //
  // A tail match is tolerated ONLY when the two sides are in different frames
  // of reference -- one <cwd>-relative, one absolute because `redact` could
  // not match it (the dev server's cwd is the app dir while this plugin loads
  // from the image's template dir, so ids outside cwd survive unredacted).
  // When BOTH are already <cwd>-relative they share a frame, so a tail match
  // means a nested directory with the same ending, not the same file:
  // /node_modules/foo/src/index.css is not /src/index.css. Treating those as
  // equal made the client tear down a live overlay and the server drop the
  // retained failure at the same time, leaving the reloaded page silent about
  // a build that was still broken.
  const comparablePath = (s: string) => {
    let n = String(s || "").split(String.fromCharCode(92)).join("/");
    const q = n.indexOf("?");
    if (q !== -1) n = n.slice(0, q);
    const hash = n.indexOf("#");
    if (hash !== -1) n = n.slice(0, hash);
    const rooted = n.indexOf("<cwd>/") === 0;
    if (rooted) n = n.slice(5);
    return { path: n, rooted };
  };
  const samePathSpelling = (a: string, b: string) => {
    const x = comparablePath(a);
    const y = comparablePath(b);
    if (!x.path || !y.path) return false;
    if (x.path === y.path) return true;
    if (x.rooted && y.rooted) return false;
    const longer = x.path.length >= y.path.length ? x.path : y.path;
    const shorter = x.path.length >= y.path.length ? y.path : x.path;
    // The shorter side keeps its leading '/', so requiring it to start with
    // one is what anchors the match to a segment boundary.
    return shorter.charAt(0) === "/" && longer.endsWith(shorter);
  };
  // The last transform failure that is still believed live, retained so it can
  // be replayed to a client that connects AFTER it happened.
  //
  // Without this a failure is only ever observable at the instant it is
  // emitted. `broadcast` reaches already-registered clients only, and the SSE
  // handler greets a new client with `connected` and nothing else, so the
  // reload on the non-cssOnly arm produces a page that may never learn its own
  // build is broken: measured against a live dev server, a client connecting
  // after the failure receives `connected` + `heartbeat` and zero `hmr-error`.
  // That is the blank frame this overlay exists to remove, coming back.
  //
  // Retained until the failing file CHANGES -- the same evidence rule the
  // client applies to a cssOnly flush. A file being edited is the only signal
  // that its failure may be resolved; if it still does not compile, the
  // re-transform emits a fresh error anyway.
  let liveHmrError: ReturnType<typeof normalizeBuildError> | null = null;
  let lastHmrErrorSig: string | null = null;
  let lastHmrErrorTime = 0;
  const HMR_ERROR_DEDUPE_WINDOW_MS = 400;

  let browserErrorSeq = 0;

  // The FUSE workspace mount silently drops inotify (vite.config.ts:
  // server.watch comment), forcing chokidar into polling mode. Polling can
  // still throw (a transient FUSE stat()/EIO glitch, fd exhaustion, etc.),
  // and the watch channel does not recover on its own — only a full
  // dev-server restart re-creates chokidar.
  // `lastFsEventAt` is the "last change/add/unlink we actually observed"
  // clock: broadcast on every heartbeat SSE frame. There is no
  // `.dev-server.log` file in this repo — nothing writes one — so this is
  // NOT a "diff the frame against a log file" mechanism; the only persisted
  // trace of a watcher failure is `recordWatcherError`'s `console.error`
  // below, which goes to stderr and is captured by the orchestrator's
  // stderr ring buffer (surfaced back to the app-builder agent via its log
  // read tool), not stdout and not a file on disk. The heartbeat fields
  // themselves are currently observable only to a developer with devtools
  // open on the live preview at the moment a frame lands (app-studio#2158,
  // app-studio#2830 tracks giving them an actual reader).
  let lastFsEventAt = Date.now();
  let watcherErrorCount = 0;
  let lastWatcherErrorTime = 0;
  let lastEmittedWatcherErrorCount = 0;
  const WATCHER_ERROR_DEDUPE_WINDOW_MS = 5000;

  const isCSS = (file: string) =>
    CSS_EXTENSIONS.some((ext) => file.toLowerCase().endsWith(ext));
  function broadcast(obj: any) {
    const data = `data: ${JSON.stringify(obj)}\n\n`;
    clients.forEach((res) => {
      try {
        res.write(data);
      } catch {
        clients.delete(res);
      }
    });
  }

  function flushChanges() {
    debounceTimer = null;
    if (!pending.size) return;
    const changes = Array.from(pending.values());
    const cssOnly = changes.every((c) => c.isCSS);
    const files = changes.map((c) => c.file);
    const cssFiles = changes.filter((c) => c.isCSS).map((c) => c.file);
    const otherFiles = changes.filter((c) => !c.isCSS).map((c) => c.file);
    // Legacy apps disable native HMR, while overlay apps keep Vite's internal
    // pipeline active but neutralize its browser WebSocket. In either mode,
    // build-end must mean that the next HTTP request sees a fresh transform.
    for (const change of changes) {
      for (const module of change.modules) {
        server?.moduleGraph?.invalidateModule(module);
      }
    }
    const end = Date.now();
    lastBuildDuration = end - lastBuildStart;
    version++;
    // The failing file was edited, so the retained failure is no longer known
    // to be current. Drop it rather than replay a diagnostic that may already
    // be fixed; if it still does not compile, a fresh error follows.
    if (liveHmrError?.id && files.some((f) => samePathSpelling(redact(f), liveHmrError!.id!))) {
      liveHmrError = null;
    }
    broadcast({
      type: "build-end",
      time: end,
      version,
      cssOnly,
      files: files.map(redact),
      changed: { css: cssFiles.map(redact), other: otherFiles.map(redact) },
      durationMs: lastBuildDuration,
    });
    pending.clear();
  }

  // `String(...)` on both arms, not just the fallback: a plugin that throws an
  // object whose `message` is an array or object leaves a non-string here, and
  // `redact` would call `.replaceAll` on it. That TypeError fires INSIDE the
  // uncaughtException handler, which kills the dev server and destroys the
  // original trace -- a strictly worse outcome than whatever was thrown.
  const messageOf = (err: any) => {
    const raw = err?.message;
    if (raw !== undefined && raw !== null && raw !== "") return String(raw);
    return err === undefined || err === null ? "" : String(err);
  };

  function normalizeBuildError(err: any) {
    const raw = messageOf(err);
    return {
      message: USELESS_MESSAGES.includes(raw) ? "" : redact(raw),
      stack: (err?.stack || "")
        .split("\n")
        .map((line: string) => redact(line))
        .join("\n"),
      plugin: err?.plugin,
      id: err?.id ? redact(err.id) : undefined,
    };
  }

  // An uncaught exception may mean the dev server is genuinely going down, so
  // it stays loud: a `build-error` frame, which the client paints full-screen.
  // Node calls this with (err, origin); the second argument is unused.
  function recordUncaughtException(err: any) {
    const norm = normalizeBuildError(err);
    // Unconditionally, before any early return. Registering an
    // `uncaughtException` listener SUPPRESSES Node's own stderr print, so this
    // is the only thing that puts the crash in the dev-server log at all. It
    // cannot be left to the browser sink either: on a cold-load failure
    // main.tsx never evaluates, so console-capture is never installed and
    // .browser-errors.log gets nothing.
    console.error("[dev-reload] uncaught exception", norm);
    if (!norm.message) {
      // Nothing worth showing. A full-screen panel reading "undefined" over a
      // working app is worse than the blank frame this overlay replaces, so
      // the frame is dropped while the trace above survives.
      return;
    }
    broadcast({ type: "build-error", time: Date.now(), error: norm });
  }

  // An unhandled rejection is NOT a build failure. It can come from anywhere in
  // the dev-server process — including watcher-adjacent async work, per the
  // note on `server.watcher.on("error", ...)` below — while the app underneath
  // keeps compiling and rendering. Painting the full-screen "Build failed"
  // panel over a working preview would hide an app the user can still use, so
  // this gets its own frame and a non-blocking notice at the client.
  //
  // This must be a separate function rather than a branch inside a shared one:
  // Node passes (reason, promise) here and (err, origin) to uncaughtException,
  // and a single handler bound to both hooks receives only the first argument,
  // so there is nothing in-band to branch on.
  function recordUnhandledRejection(reason: any) {
    const norm = normalizeBuildError(reason);
    console.error(
      "[dev-reload] unhandled rejection in the dev server:",
      norm,
    );
    broadcast({ type: "dev-server-error", time: Date.now(), error: norm });
  }

  function recordWatcherError(err: any) {
    watcherErrorCount++;
    const norm = normalizeBuildError(err);
    // A polling watcher can re-throw a different-looking error every poll
    // tick during the same underlying outage (e.g. a FUSE fault surfaces a
    // different path/fd per tick). A signature-keyed dedupe (matching the
    // sig !== lastWatcherErrorSig HMR pattern above) would be defeated by
    // that per-tick variance and emit uncapped anyway — the diagnostic only
    // needs to say "the watcher is unhealthy right now", not distinguish
    // between differently-worded errors within the same outage, so this
    // throttles on TIME ALONE (no signature check): at most one emission per
    // WATCHER_ERROR_DEDUPE_WINDOW_MS regardless of message/id content.
    // watcherErrorCount still increments on every occurrence even when the
    // console/SSE emission is suppressed, so the total stays accurate, and
    // suppressedSinceLast on the emitted line reports how many were
    // collapsed into it.
    const now = Date.now();
    const shouldEmit = now - lastWatcherErrorTime > WATCHER_ERROR_DEDUPE_WINDOW_MS;
    if (!shouldEmit) return;
    const suppressedSinceLast = watcherErrorCount - lastEmittedWatcherErrorCount - 1;
    lastWatcherErrorTime = now;
    lastEmittedWatcherErrorCount = watcherErrorCount;
    // console.error goes to stderr; the dev-server process's stderr is
    // captured into a bounded ring buffer the app-builder agent reads back
    // (not written to a `.dev-server.log` file — nothing in this repo
    // creates one). This is still the first trace this failure class has
    // ever left anywhere.
    console.error(
      `[dev-reload] file watcher error (#${watcherErrorCount}${
        suppressedSinceLast > 0 ? `, ${suppressedSinceLast} suppressed since last report` : ""
      }, last real fs event ${Math.round((Date.now() - lastFsEventAt) / 1000)}s ago):`,
      norm.message,
    );
    broadcast({
      type: "watcher-error",
      time: Date.now(),
      watcherErrorCount,
      suppressedSinceLast,
      lastFsEventAgoMs: Date.now() - lastFsEventAt,
      error: norm,
    });
  }

  function cleanup() {
    if (debounceTimer) {
      scheduler.clearTimeout(debounceTimer);
      debounceTimer = null;
    }
    pending.clear();
    liveHmrError = null;
    if (heartbeatTimer) {
      scheduler.clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
    if (errorHooksInstalled) {
      process.off("uncaughtException", recordUncaughtException);
      process.off("unhandledRejection", recordUnhandledRejection);
      errorHooksInstalled = false;
    }
    if (configuredWatcher) {
      configuredWatcher.off("error", recordWatcherError);
      if (queueChangeHandler) {
        configuredWatcher.off("change", queueChangeHandler);
        configuredWatcher.off("add", queueChangeHandler);
        configuredWatcher.off("unlink", queueChangeHandler);
      }
    }
    configuredWatcher = null;
    queueChangeHandler = null;
    if (configuredHttpServer) {
      configuredHttpServer.off("close", cleanup);
      configuredHttpServer = null;
    }
    if (
      configuredWs &&
      originalWsSend &&
      patchedWsSend &&
      configuredWs.send === patchedWsSend
    ) {
      configuredWs.send = originalWsSend;
      delete configuredWs.__devReloadPatched;
    }
    configuredWs = null;
    originalWsSend = null;
    patchedWsSend = null;
    clients.forEach((res) => {
      try {
        res.end();
      } catch {}
    });
    clients.clear();
    server = null;
  }

  function interceptHMR() {
    const ws: any = server?.ws;
    if (!ws || ws.__devReloadPatched) return;
    ws.__devReloadPatched = true;
    configuredWs = ws;
    originalWsSend = ws.send;
    patchedWsSend = (payload: any, clientsArg?: any) => {
      try {
        Reflect.apply(originalWsSend!, ws, [payload, clientsArg]);
      } catch {}
      try {
        if (!payload || !payload.type) return;
        switch (payload.type) {
          case "update":
            // A hot update that recompiled a MODULE means the graph is healthy
            // again, so a retained failure is no longer current. Invalidating
            // only on "the failing file changed" is not enough: an unresolved
            // import is attributed to the IMPORTER, and the repair usually
            // creates a DIFFERENT file, so the retained failure survived its
            // own fix and the reload that edit triggers replayed it
            // full-screen over an app that now compiles.
            //
            // But a css-update is patched in place and compiles no module, so
            // it is no evidence a failing JS module was repaired -- the same
            // rule the client applies to a cssOnly flush, and the invariant
            // this file states about the two sides never disagreeing. Reading
            // the per-entry kind is what keeps them in step: clearing on every
            // payload discharged a live JS failure the moment any stylesheet
            // was touched.
            if ((payload.updates || []).some((u: any) => u?.type !== "css-update")) {
              liveHmrError = null;
            }
            broadcast({
              type: "hmr-update",
              time: Date.now(),
              updates: (payload.updates || []).map((u: any) => ({
                type: u.type,
                path: u.path ? u.path.replaceAll(cwd, "<cwd>") : undefined,
                accepted: u.acceptedPath ?? u.acceptedPaths ?? undefined,
                timestamp: u.timestamp,
              })),
            });
            break;
          case "full-reload":
            // Same reasoning as `update`: Vite only asks for a full reload
            // after it has successfully produced a graph to reload into.
            liveHmrError = null;
            broadcast({
              type: "hmr-full-reload",
              time: Date.now(),
              path: payload.path ? payload.path.replaceAll(cwd, "<cwd>") : undefined,
            });
            break;
          case "error": {
            const now = Date.now();
            const norm = normalizeBuildError(payload.err || payload.error || payload);
            const sig = `${norm.plugin || ""}|${norm.id || ""}|${norm.message}`;
            // Retained even when the broadcast below is deduped: a client that
            // connects later still needs to learn the build is broken, and the
            // dedupe only suppresses the duplicate emission, not the failure.
            //
            // Decline to retain an error with no `id`; do NOT evict the one
            // already held. Invalidation is keyed on the failing file, so an
            // id-less error could never be dropped and would replay for the
            // life of the server. But an unconditional assignment made its
            // false arm destructive: a config- or plugin-level throw carrying
            // no id would wipe a live, id-bearing transform failure, and the
            // page that reloaded would be told nothing.
            //
            // A message is required too, for the reason the uncaught-exception
            // path already states: an id-bearing throw whose message collapses
            // to empty would otherwise be retained and replayed, painting the
            // placeholder string full-screen on every later connection.
            if (norm.id && norm.message) liveHmrError = norm;
            if (sig !== lastHmrErrorSig || now - lastHmrErrorTime > HMR_ERROR_DEDUPE_WINDOW_MS) {
              lastHmrErrorSig = sig;
              lastHmrErrorTime = now;
              broadcast({
                type: "hmr-error",
                time: now,
                error: norm,
              });
            }
            break;
          }
          default:
            broadcast({ type: "hmr-message", time: Date.now(), message: payload.type });
        }
      } catch (e: any) {
        broadcast({ type: "ws-error", time: Date.now(), error: { message: e?.message || String(e) } });
      }
    };
    ws.send = patchedWsSend;
  }

  return {
    name: "dev-reload-sse-build",
    apply: "serve",

    configureServer(_server: ViteDevServer) {
      server = _server;
      if (!errorHooksInstalled) {
        errorHooksInstalled = true;
        try {
          process.on("uncaughtException", recordUncaughtException);
          process.on("unhandledRejection", recordUnhandledRejection);
        } catch {}
      }
      const base = (server.config.base || "/").replace(/\/$/, "");
      const prefixedSsePath = `${base}${SSE_PATH}`;
      const sseHandler = (_req: any, res: any) => {
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
          "Access-Control-Allow-Origin": "*",
        });
        clients.add(res);
        // Both greeting and replay go through one guarded write. A client can
        // die between the add above and the close handler below, and an
        // unguarded write throws EPIPE straight out of the middleware and
        // leaks the response into `clients` because the close handler is not
        // registered yet. That window opens at the FIRST write, so the
        // greeting is guarded exactly like the replay.
        const greet = (frame: Record<string, unknown>) => {
          try {
            res.write(`data: ${JSON.stringify(frame)}\n\n`);
            return true;
          } catch {
            clients.delete(res);
            return false;
          }
        };
        const greeted = greet({
          type: "connected",
          time: Date.now(),
          version,
          heartbeatMs: HEARTBEAT_MS,
          hmr: true,
        });
        // Hand a newly-connected client any failure that is still live. The
        // page produced by the reload on the non-cssOnly arm is a NEW client,
        // and every other frame reaches already-registered clients only, so
        // without this it can load into a broken build and be told nothing.
        // `replayed` marks it as history rather than a fresh event, so a
        // reader cannot mistake a reconnect for a new failure.
        //
        // Only `hmr-error` is retained. The process survives an uncaught
        // exception (the listener suppresses Node's default crash and the
        // server keeps serving), so survival cannot be the discriminator:
        // a transform failure has a clear resolution signal (the graph
        // recompiles, or the file changes) while a process-level fault has
        // none, so a retained `build-error` could never be invalidated and
        // would paint a full-screen panel on every future page load for the
        // life of the server.
        if (greeted && liveHmrError) {
          greet({
            type: "hmr-error",
            time: Date.now(),
            replayed: true,
            error: liveHmrError,
          });
        }
        _req.on("close", () => {
          clients.delete(res);
        });
        if (!heartbeatTimer) {
          heartbeatTimer = scheduler.setInterval(
            () =>
              broadcast({
                type: "heartbeat",
                time: Date.now(),
                // Last time chokidar actually reported a change/add/unlink —
                // NOT proof edits are/aren't happening, just the watcher's own
                // "still alive and reporting" clock. This frame currently has
                // no automated reader (see the note by `lastFsEventAt`'s
                // declaration above) — it's for a human with devtools open,
                // or a future monitor, to tell a genuinely idle session apart
                // from one where the watcher stopped reporting despite known
                // writes.
                lastFsEventAgoMs: Date.now() - lastFsEventAt,
                watcherErrorCount,
              }),
            HEARTBEAT_MS,
          );
        }
      };
      server.middlewares.use(SSE_PATH, sseHandler);
      if (prefixedSsePath !== SSE_PATH) {
        server.middlewares.use(prefixedSsePath, sseHandler);
      }

      // Node's EventEmitter throws an unhandled 'error' event rather than
      // swallowing it, so without this listener a thrown chokidar error
      // (FUSE stat()/EIO glitch, fd exhaustion — see `lastFsEventAt` above)
      // escapes as an `uncaughtException` and broadcasts as a `build-error`
      // SSE frame, indistinguishable from an actual build failure
      // (app-studio#2158);
      // routing it to `recordWatcherError` yields a correctly-labeled
      // `watcher-error` frame. This does not attempt to restart the
      // watcher — chokidar's polling watcher has no supported public
      // "re-arm" API — it only corrects the categorization and makes the
      // failure observable.
      //
      // NOTE: this only re-routes the SYNCHRONOUS 'error' emit. An async
      // rejection from watcher/fs-adjacent work still falls through to
      // `process.on("unhandledRejection", recordUnhandledRejection)` above,
      // so a `dev-server-error` frame does NOT rule out a watcher-originated
      // fault. Attributing an arbitrary rejection back to the watcher isn't
      // reliably possible from the rejection alone, so it stays a known gap
      // rather than a guess — but that arm is non-blocking and separately
      // labeled, so a watcher-originated rejection cannot cover a working
      // preview with a full-screen "Build failed" panel.
      server.watcher.on("error", recordWatcherError);

      const browserErrorsLogPath = path.resolve(cwd, BROWSER_ERRORS_LOG);
      // Seed the sequence PAST everything already persisted — the max seq in
      // the retained log AND the deploy gate's .browser-errors.seq cursor —
      // so `seq` is monotonic across dev-server restarts. The counter resets
      // with the process while both files persist, and the gate's new-entry
      // filter is `seq > cursor`: an unseeded restart re-issues low seqs,
      // making new errors invisible to the gate (and, before the filter was
      // monotonic, replaying acknowledged ones forever). The seq file covers
      // the log-deleted/trimmed case; the log max covers a cursor that has
      // not caught up yet. Best-effort: on any read fault the worst case is
      // the old restart-at-zero behavior.
      try {
        if (fs.existsSync(browserErrorsLogPath)) {
          for (const line of fs
            .readFileSync(browserErrorsLogPath, "utf-8")
            .split("\n")) {
            if (!line) continue;
            try {
              const s = Number(JSON.parse(line)?.seq);
              if (Number.isFinite(s) && s > browserErrorSeq) {
                browserErrorSeq = s;
              }
            } catch {
              // half-written line from the cap trim — skip it
            }
          }
        }
        const seqCursorPath = path.resolve(cwd, BROWSER_ERRORS_SEQ);
        if (fs.existsSync(seqCursorPath)) {
          const s = Number(fs.readFileSync(seqCursorPath, "utf-8").trim());
          if (Number.isFinite(s) && s > browserErrorSeq) browserErrorSeq = s;
        }
      } catch {
        // seeding is best-effort; see comment above
      }
      const prefixedConsolePath = `${base}${CONSOLE_PATH}`;
      const POST_BODY_CAP_BYTES = 256 * 1024;
      const consoleHandler = (req: any, res: any) => {
        let body = "";
        let aborted = false;
        req.on("data", (chunk: Buffer) => {
          if (aborted) return;
          body += chunk.toString("utf-8");
          if (body.length > POST_BODY_CAP_BYTES) {
            aborted = true;
            res.writeHead(413, { "Access-Control-Allow-Origin": "*" });
            res.end();
            req.destroy();
          }
        });
        req.on("end", () => {
          if (aborted) return;
          try {
            // Scrub at the raw-body chokepoint so every string field (url,
            // filename, stack, message, componentStack) is covered at once.
            const entry = JSON.parse(scrubPreviewToken(body));
            browserErrorSeq += 1;
            const stamped = { ...entry, seq: browserErrorSeq, server_time: Date.now() };
            const line = JSON.stringify(stamped) + "\n";
            try {
              const size = fs.statSync(browserErrorsLogPath).size;
              if (size > BROWSER_ERRORS_LOG_CAP_BYTES) {
                const existing = fs.readFileSync(browserErrorsLogPath, "utf-8");
                const tail = existing.slice(-Math.floor(BROWSER_ERRORS_LOG_CAP_BYTES / 2));
                const nl = tail.indexOf("\n");
                fs.writeFileSync(browserErrorsLogPath, nl >= 0 ? tail.slice(nl + 1) : "");
              }
            } catch {
            }
            fs.appendFileSync(browserErrorsLogPath, line);
            broadcast({ type: "browser-error", time: Date.now(), error: stamped });
          } catch {
          }
          res.writeHead(204, { "Access-Control-Allow-Origin": "*" });
          res.end();
        });
      };
      server.middlewares.use(CONSOLE_PATH, consoleHandler);
      if (prefixedConsolePath !== CONSOLE_PATH) {
        server.middlewares.use(prefixedConsolePath, consoleHandler);
      }

      // The orchestrator's Rayfin supervisor POSTs here after rayfin-local
      // applies a schema change, so the preview refetches against the new
      // backend. Nothing under the app's source changed, so the watcher never
      // flushes on its own. Only a loopback peer may ask: the supervisor runs
      // in this container, and nothing else needs to reload every preview.
      const prefixedReloadFullPath = `${base}${RELOAD_FULL_PATH}`;
      const reloadFullHandler = (req: any, res: any) => {
        if (req.method !== "POST") {
          res.writeHead(405, { Allow: "POST" });
          res.end();
          return;
        }
        if (!LOOPBACK_PEERS.has(String(req.socket?.remoteAddress ?? ""))) {
          res.writeHead(403);
          res.end();
          return;
        }
        // Vite's own full-reload goes to its browser socket (and, through the
        // patched send, out as an `hmr-full-reload` frame). The preview runs
        // with that socket off, and the SSE client reloads only on a
        // non-cssOnly `build-end`, so emit one of those as well.
        try {
          server?.ws.send({ type: "full-reload", path: "*" });
        } catch {}
        version++;
        broadcast({
          type: "build-end",
          time: Date.now(),
          version,
          cssOnly: false,
          files: [],
          changed: { css: [], other: [] },
          durationMs: 0,
        });
        res.writeHead(204);
        res.end();
      };
      server.middlewares.use(RELOAD_FULL_PATH, reloadFullHandler);
      if (prefixedReloadFullPath !== RELOAD_FULL_PATH) {
        server.middlewares.use(prefixedReloadFullPath, reloadFullHandler);
      }

      const queueChange = (file: string): void => {
        lastFsEventAt = Date.now();
        if (!pending.size) {
          lastBuildStart = Date.now();
          broadcast({ type: "build-start", time: lastBuildStart, version });
        }
        // Vite keys the file map with platform-normalized paths. Windows
        // separators become slashes; POSIX literal backslashes stay literal.
        const pendingKey = normalizeWatcherModulePath(file);
        const modules = new Set(pending.get(pendingKey)?.modules);
        for (
          const module of
            server?.moduleGraph?.getModulesByFile(pendingKey) ?? []
        ) {
          modules.add(module);
        }
        pending.set(pendingKey, {
          file,
          isCSS: isCSS(file),
          modules: [...modules],
        });
        if (debounceTimer) scheduler.clearTimeout(debounceTimer);
        debounceTimer = scheduler.setTimeout(flushChanges, DEBOUNCE_MS);
      };
      configuredWatcher = server.watcher;
      queueChangeHandler = queueChange;
      server.watcher.on("change", queueChange);
      server.watcher.on("add", queueChange);
      server.watcher.on("unlink", queueChange);
      configuredHttpServer = server.httpServer;
      configuredHttpServer?.once("close", cleanup);

      interceptHMR();
    },

    closeBundle() {
      cleanup();
    },

    transformIndexHtml(html: string) {
      const script = `
(() => {
  const SSE_PATH = '${CLIENT_SSE_PATH}';
  let currentVersion = ${version};
  const CSS_BASE = (() => {
    const s = document.querySelector('script[src*="/@vite/client"]');
    if (s) {
      try { return new URL('.', s.src).href; }
      catch (e) { console.warn('[dev-reload]', 'CSS_BASE derivation failed, using document.baseURI', e); }
    } else {
      console.warn('[dev-reload]', 'CSS_BASE: no @vite/client tag, using document.baseURI');
    }
    return document.baseURI;
  })();
  // Transliteration of comparablePath/samePathSpelling in the plugin above -- the same "are these the same file" rule, asked here about a
  // changed CSS file and there about a retained failure. Kept in step by the
  // shared case table in the test named "client and server agree on what
  // counts as the same file"; if you change one, that test fails until you
  // change the other.
  //
  // A watcher path inside changed.css is <cwd>-redacted and keeps the platform
  // separator (on Windows, a <cwd> prefix followed by backslashes); a Vite
  // module id on an error frame is absolute and always forward-slashed, and
  // may carry a transform query such as ?direct or ?t=.
  const norm = (s) => s.split(String.fromCharCode(92)).join('/');
  function normPath(s) {
    let n = norm(String(s || ''));
    const q = n.indexOf('?');
    if (q !== -1) n = n.slice(0, q);
    const h = n.indexOf('#');
    if (h !== -1) n = n.slice(0, h);
    const rooted = n.indexOf('<cwd>/') === 0;
    if (rooted) n = n.slice(5);
    return { path: n, rooted: rooted };
  }
  // A tail match is tolerated only across different frames of reference (one
  // <cwd>-relative, one absolute because redaction could not match it). When
  // both are already <cwd>-relative a tail match means a nested directory with
  // the same ending -- /node_modules/foo/src/index.css is not /src/index.css --
  // and treating those as equal tore down a live overlay.
  function samePath(a, b) {
    const x = normPath(a);
    const y = normPath(b);
    if (!x.path || !y.path) return false;
    if (x.path === y.path) return true;
    if (x.rooted && y.rooted) return false;
    const longer = x.path.length >= y.path.length ? x.path : y.path;
    const shorter = x.path.length >= y.path.length ? y.path : x.path;
    return shorter.charAt(0) === '/' && longer.endsWith(shorter);
  }
  function listHasPath(list, target) {
    if (!list || !target) return false;
    for (const f of list) { if (samePath(f, target)) return true; }
    return false;
  }
  async function applyAllCSS(v, changedCss) {
    let linkRefreshed = 0;
    document.querySelectorAll('link[rel="stylesheet"]').forEach(link => {
      const url = new URL(link.href, location.origin);
      url.searchParams.set('v', v);
      const clone = link.cloneNode();
      clone.href = url.toString();
      clone.addEventListener('load', () => link.remove(), { once: true });
      link.after(clone);
      linkRefreshed++;
    });
    const rels = (changedCss || []).map((f) => {
      const n = norm(f);
      const rel = n.indexOf('<cwd>/') === 0 ? n.slice(6) : n;
      return rel.charAt(0) === '/' ? rel : '/' + rel;
    });
    const styles = Array.prototype.slice.call(document.querySelectorAll('style[data-vite-dev-id]'));
    let missed = false;
    for (const rel of rels) {
      const el = styles.find(s => {
        const devId = norm(s.getAttribute('data-vite-dev-id') || '');
        return devId === rel || devId.endsWith(rel);
      });
      if (!el) { missed = true; continue; }
      try {
        const fetchRel = rel.charAt(0) === '/' ? rel.slice(1) : rel;
        const res = await fetch(new URL(fetchRel + '?direct&v=' + v, CSS_BASE).href, { cache: 'no-store' });
        if (!res.ok) {
          console.warn('[dev-reload]', 'CSS fetch failed', rel, res.status);
          missed = true;
          continue;
        }
        if (v !== currentVersion) return;
        const ct = (res.headers.get('content-type') || '').toLowerCase();
        if (ct.indexOf('text/css') === -1) {
          console.warn('[dev-reload]', 'CSS fetch returned non-CSS content-type, forcing reload', rel, ct);
          missed = true;
          continue;
        }
        const text = await res.text();
        if (v !== currentVersion) return; // a newer build superseded this one — drop stale CSS
        el.textContent = text;
      } catch (e) {
        console.warn('[dev-reload]', 'CSS fetch error', rel, e);
        missed = true;
      }
    }
    if (v !== currentVersion) return; // superseded before the reload decision
    if (missed || (linkRefreshed === 0 && rels.length === 0)) location.reload();
  }
  // Build/transform failures already arrive over SSE, but were only written to
  // the console — so a failed build rendered as a blank (or stale) frame with
  // no on-screen cause (app-studio#3001, #2938).
  //
  // The beneficiary is the HUMAN watching the iframe, not the app-builder
  // agent. That agent has no browser or screenshot tool, and its own
  // instructions tell it to investigate the preview only REACTIVELY — from the
  // dev-server log, from .browser-errors.log, or from an error it was told
  // about (workspace_template .claude/gated-agents/app-builder/agent.md). A
  // silent transform failure produces none of those three, so it sits outside
  // the agent's perception entirely rather than merely being unlogged.
  // Painting it on screen gives the one observer who can actually see it
  // something to see.
  // Paint them into the preview instead. The console.error alongside also
  // lands in .browser-errors.log when console-capture is installed (its
  // console.error wrap POSTs ./__dev/console, and the runtime preview proxy
  // forwards that POST — #24067) — but a transform failure can fire before
  // capture installs on a broken cold load, so the overlay stays the
  // guaranteed channel for the human watching the iframe.
  let buildErrorEl = null;
  // Which file the overlay is currently describing. A CSS-only flush can only
  // be evidence that the CSS files it names were repaired, so this is what
  // decides whether such a flush may tear the overlay down.
  let buildErrorId = null;
  function clearBuildErrorOverlay() {
    if (buildErrorEl && buildErrorEl.parentNode) buildErrorEl.parentNode.removeChild(buildErrorEl);
    buildErrorEl = null;
    buildErrorId = null;
  }
  function showBuildErrorOverlay(kind, err, replayed) {
    if (!document.body) return;
    clearBuildErrorOverlay();
    const e = err || {};
    const host = document.createElement('div');
    host.setAttribute('data-aether-build-error', kind);
    host.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;z-index:2147483647;' +
      'background:rgba(15,15,17,.92);padding:24px;overflow:auto;' +
      'font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;';
    const card = document.createElement('div');
    card.style.cssText = 'max-width:1100px;margin:0 auto;background:#1b1b1f;border:1px solid #f2545b;' +
      'border-radius:8px;padding:20px 22px;color:#f5f5f7;box-shadow:0 8px 32px rgba(0,0,0,.5);';
    const head = document.createElement('div');
    head.style.cssText = 'display:flex;align-items:center;justify-content:space-between;gap:16px;margin-bottom:12px;';
    const title = document.createElement('strong');
    title.style.cssText = 'color:#ff6b71;font-size:14px;';
    title.textContent = kind === 'build-error' ? 'Build failed' : 'Transform failed';
    if (replayed) {
      // The screen is where this is actually read. Labelling only the console
      // line left the painted half of the frame indistinguishable from a fresh
      // break, which is the whole reason the flag exists.
      const since = document.createElement('span');
      since.style.cssText = 'margin-left:10px;color:#c9a227;font-size:11px;font-weight:400;';
      since.textContent = '(from before this page loaded)';
      title.appendChild(since);
    }
    const close = document.createElement('button');
    close.textContent = 'Dismiss';
    close.style.cssText = 'background:transparent;color:#a9a9b3;border:1px solid #3a3a42;' +
      'border-radius:5px;padding:3px 10px;font:inherit;font-size:12px;cursor:pointer;';
    close.addEventListener('click', clearBuildErrorOverlay);
    head.appendChild(title);
    head.appendChild(close);
    card.appendChild(head);
    if (e.id) {
      const file = document.createElement('div');
      file.style.cssText = 'color:#9aa0a6;font-size:12px;margin-bottom:10px;word-break:break-all;';
      file.textContent = e.id;
      card.appendChild(file);
    }
    // textContent, never innerHTML — the message embeds the offending source.
    const pre = document.createElement('pre');
    pre.style.cssText = 'margin:0;white-space:pre-wrap;word-break:break-word;font-size:12.5px;line-height:1.5;';
    pre.textContent = e.message || 'The dev server reported an error with no message.';
    card.appendChild(pre);
    if (e.plugin) {
      const plug = document.createElement('div');
      plug.style.cssText = 'margin-top:10px;color:#6f7480;font-size:11px;';
      plug.textContent = 'plugin: ' + e.plugin;
      card.appendChild(plug);
    }
    host.appendChild(card);
    document.body.appendChild(host);
    buildErrorEl = host;
    buildErrorId = e.id || null;
  }
  // Non-blocking counterpart to the overlay above, for failures that do NOT
  // stop the app rendering. The overlay is right when nothing renders anyway;
  // covering a working preview would take away function the user still has, so
  // this is a fixed strip with pointer-events:none and no bottom edge.
  //
  // Single-slot and keyed by kind. Only one kind exists here
  // ('dev-server-error'), so the keying is not currently exercised across
  // kinds; it is written this way because the slot is shared with a second
  // caller landing separately, and a guard keyed only on "is a notice up"
  // would let whichever mounted first block the other. Same-kind re-entry
  // returns early so a repeated frame does not tear down and rebuild the
  // strip; a different kind replaces rather than stacks, because both sit at
  // top:0 and would overlap.
  let noticeEl = null;
  let noticeKind = null;
  function clearNotice(kind) {
    // A caller clearing its own kind must not silently discard someone else's.
    if (kind && noticeKind !== kind) return;
    if (noticeEl && noticeEl.parentNode) noticeEl.parentNode.removeChild(noticeEl);
    noticeEl = null;
    noticeKind = null;
  }
  function showNotice(kind, text, actionLabel, onAction) {
    if (!document.body) return;
    if (noticeKind === kind) return; // already up: re-arm cycles must not restack
    clearNotice();
    const host = document.createElement('div');
    host.setAttribute('data-aether-notice', kind);
    // Same z-index as the overlay so whichever mounted last paints on top
    // instead of one permanently masking the other. pointer-events:none and no
    // bottom edge are what keep the app underneath usable.
    host.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:2147483647;' +
      'display:flex;align-items:center;gap:12px;padding:8px 14px;pointer-events:none;' +
      'background:#3a2f00;border-bottom:1px solid #8a6d00;color:#ffe9a8;' +
      'font:500 12.5px/1.4 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;';
    const label = document.createElement('span');
    label.style.cssText = 'flex:1;min-width:0;';
    label.textContent = text;
    host.appendChild(label);
    if (actionLabel) {
      const action = document.createElement('button');
      action.textContent = actionLabel;
      // The strip itself is click-through; only the control takes pointers.
      action.style.cssText = 'pointer-events:auto;background:#ffe9a8;color:#3a2f00;border:0;' +
        'border-radius:5px;padding:3px 12px;font:inherit;font-weight:600;cursor:pointer;';
      action.addEventListener('click', onAction);
      host.appendChild(action);
    }
    document.body.appendChild(host);
    noticeEl = host;
    noticeKind = kind;
  }
  const RECONNECT_BASE_MS = 1000;
  const RECONNECT_CAP_MS = 30000;
  const RECONNECT_MAX_ATTEMPTS = 12;
  const REARM_CAP_MS = 300000;
  const REFOCUS_REARM_MS = 250;
  const JITTER = 0.2;
  function jittered(ms) {
    return Math.round(ms * (1 + (Math.random() * 2 - 1) * JITTER));
  }
  const PROGRESS_FRAMES = ['heartbeat', 'build-end', 'build-error', 'hmr-error', 'watcher-error', 'dev-server-error'];
  let reconnectAttempt = 0;
  let stopped = false;
  let pendingTimer = null;
  function clearPending() {
    if (pendingTimer !== null) { clearTimeout(pendingTimer); pendingTimer = null; }
  }
  function connect() {
    if (stopped) return;
    clearPending();
    let es;
    try {
      es = new EventSource(SSE_PATH);
    } catch (e) {
      // A throwing constructor inside a scheduled retry or a re-arm would
      // leave the stop flag clear with no timer pending: the channel dies
      // for good. Park it and probe later instead.
      console.warn('[dev-reload]', 'EventSource constructor threw, probing later', e);
      stopped = true;
      scheduleRearm(REARM_CAP_MS);
      return;
    }
    es.onmessage = (ev) => {
      let msg;
      try {
        msg = JSON.parse(ev.data);
      } catch { return; }
      if (!msg || typeof msg !== 'object') return;
      if (PROGRESS_FRAMES.indexOf(msg.type) !== -1) reconnectAttempt = 0;
      switch (msg.type) {
        case 'build-end':
          currentVersion = msg.version;
          if (msg.cssOnly) {
            // A cssOnly flush is a debounced WATCHER flush, not a compile: it
            // patches stylesheets in place, re-requests no modules and never
            // reloads. It is therefore no evidence that a failing module was
            // fixed, and clearing unconditionally here tore the diagnostic
            // down the moment the developer touched any .css file, leaving the
            // JS still broken and the cause invisible again. Only the CSS
            // files this flush actually names can have been repaired.
            if (listHasPath(msg.changed && msg.changed.css, buildErrorId)) clearBuildErrorOverlay();
            applyAllCSS(msg.version, msg.changed && msg.changed.css);
          } else {
            // A full flush reloads, which tears the DOM down anyway; clearing
            // first just avoids painting a stale overlay over the new document
            // if the reload is slow. The reloaded page is a NEW SSE client and
            // no frame is replayed to it automatically, so a failure that
            // survives the reload is repainted by the server handing the live
            // error to that new connection -- measured, not assumed: without
            // it, a client connecting after the failure gets only the
            // connected and heartbeat frames.
            clearBuildErrorOverlay();
            location.reload();
          }
          break;
        case 'build-error':
        case 'hmr-error':
          // A replayed frame is the failure this page loaded INTO, handed over
          // by the server on connect; it is not a new event. Say so, or the
          // console reads as though the build just broke again on every
          // reload and reconnect.
          console.error(
            '[dev-reload][' + msg.type + ']' + (msg.replayed ? ' (still failing from before this page loaded)' : ''),
            msg.error,
          );
          showBuildErrorOverlay(msg.type, msg.error, msg.replayed);
          break;
        case 'dev-server-error':
          // An unhandled rejection somewhere in the dev-server process. The app
          // is still compiling and rendering, so this must not cover it: see
          // the note on showNotice above.
          console.error('[dev-reload][dev-server-error]', msg.error);
          showNotice(
            'dev-server-error',
            'The dev server hit a background error. Your app is still running, but ' +
              'something it started in the background failed. Check the console for details.',
            'Dismiss',
            () => clearNotice('dev-server-error'),
          );
          break;
        case 'hmr-update':
        case 'hmr-full-reload':
          // Recovery. The overlay has two teardowns driven by success signals;
          // the notice had none, so one background rejection left the strip
          // standing over a healthy preview until the user dismissed it or made
          // a non-CSS edit -- indefinitely during a styling session, which is a
          // common loop. A recompile is the same evidence the server clears its
          // retention on.
          clearNotice('dev-server-error');
          break;
        case 'watcher-error':
          // The file watcher (not the SSE channel) failed server-side — edits
          // may silently stop reloading even though this connection stays up.
          // console.error rather than console.warn reaches the parent-frame
          // console (app-studio#2158) AND — through console-capture's
          // console.error wrap, whose ./__dev/console POST the runtime
          // preview proxy forwards (#24067) — .browser-errors.log, so the
          // app-builder agent can see a dead watcher too.
          console.error(
            '[dev-reload] file watcher error #' + msg.watcherErrorCount + ', last real change ' +
              Math.round(msg.lastFsEventAgoMs / 1000) + 's ago — edits may not reload; restart the preview if this persists',
            msg.error,
          );
          break;
      }
    };
    es.onerror = () => {
      es.close();
      if (stopped) return;
      if (reconnectAttempt >= RECONNECT_MAX_ATTEMPTS) {
        stopped = true;
        scheduleRearm(REARM_CAP_MS);
        console.warn('[dev-reload]', 'EventSource failed ' + reconnectAttempt + ' times, pausing');
        return;
      }
      const delay = jittered(
        Math.min(RECONNECT_BASE_MS * Math.pow(2, reconnectAttempt), RECONNECT_CAP_MS),
      );
      reconnectAttempt += 1;
      console.warn('[dev-reload]', 'EventSource failed, retrying in ' + delay + 'ms');
      clearPending();
      pendingTimer = setTimeout(connect, delay);
    };
  }
  function scheduleRearm(delay) {
    clearPending();
    pendingTimer = setTimeout(rearm, jittered(delay));
  }
  function rearm() {
    if (!stopped) return;
    clearPending();
    stopped = false;
    reconnectAttempt = 0;
    connect();
  }
  function rearmSoon() {
    if (!stopped) return;
    clearPending();
    pendingTimer = setTimeout(rearm, jittered(REFOCUS_REARM_MS));
  }
  document.addEventListener('visibilitychange', () => { if (!document.hidden) rearmSoon(); });
  window.addEventListener('focus', rearmSoon);
  if (window.EventSource) connect();
  (window).__devReload = {
    version: () => currentVersion,
    forceReload: () => location.reload()
  };
})();`;
      return {
        html,
        tags: [
          {
            tag: "script",
            injectTo: "head",
            attrs: { type: "module" },
            children: script,
          },
          {
            tag: "script",
            injectTo: "head-prepend",
            children: BOOT_STAGE_TRACKER_SCRIPT,
          },
        ],
      };
    },
  };
}
