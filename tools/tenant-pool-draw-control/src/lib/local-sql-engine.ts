import type { SqlJsStatic } from "sql.js";

// The SQLite engine: sql.js's pure-JavaScript (asm.js) build, emitted by the
// build as an asset next to the bundle and run as a same-origin classic script
// on the first query. Not the WebAssembly build: a published app's CSP is
// `script-src 'self'` with no 'wasm-unsafe-eval', which forbids compiling
// WebAssembly; a same-origin script is allowed. Not an import: the package's
// `exports` hide this file, and it is CommonJS. A `new URL(…, import.meta.url)`
// reference, not a `?url` import: the preview proxy forwards a bare `?url` as
// `url=`, which Vite does not read.
const engineUrl = new URL(
  "../../node_modules/sql.js/dist/sql-asm-memory-growth.js",
  import.meta.url,
).href;

type InitSqlJs = () => Promise<SqlJsStatic>;

// How long the engine (about 1.5 MB of script) has to download and start
// before the query fails and the next one tries again.
export const ENGINE_TIMEOUT_MS = 30_000;

export default function loadSqlJs(timeoutMs = ENGINE_TIMEOUT_MS): Promise<SqlJsStatic> {
  const script = document.createElement("script");
  let timer: ReturnType<typeof setTimeout> | undefined;
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`The SQL engine did not start within ${timeoutMs / 1000}s (${engineUrl}).`)),
      timeoutMs,
    );
  });
  const started = new Promise<InitSqlJs>((resolve, reject) => {
    script.src = engineUrl;
    script.onload = () => {
      // The script declares `initSqlJs` as a global.
      const init = (globalThis as { initSqlJs?: InitSqlJs }).initSqlJs;
      if (init) resolve(init);
      else reject(new Error(`The SQL engine did not load (no initSqlJs in ${engineUrl}).`));
    };
    script.onerror = () => reject(new Error(`The SQL engine did not load (${engineUrl}).`));
    document.head.append(script);
  }).then((init) => init());
  return Promise.race([started, deadline]).then(
    (sql) => {
      clearTimeout(timer);
      return sql;
    },
    (error: unknown) => {
      clearTimeout(timer);
      // The next query appends a fresh script; a failed one never lingers.
      script.onload = script.onerror = null;
      script.remove();
      throw error;
    },
  );
}
