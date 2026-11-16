import path from "path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig, loadEnv, searchForWorkspaceRoot } from "vite";
import type { Plugin } from "vite";
import aetherSdkSqlFix from "./aether-sdk-sqlfix";
import { aetherBuildId } from "./vite-build-id";
import devReloadSSE from "./vite-dev-reload";

// Dev-only: mute Vite's HMR-failure WebSocket noise. Injected ONLY in serve
// mode (this plugin is apply:'serve'), so it is fully inert during vite build
// and NEVER reaches the published bundle -- the published app is served under
// the production CSP script-src 'self', which rejects an inline <script>, so
// this dev concern must not ship (issue #1063). It is a CLASSIC (non-module)
// script: it runs synchronously at parse time, BEFORE the deferred
// /@vite/client module that opens the vite-hmr WebSocket (native HMR is off --
// see server.hmr:false below). Script body is unchanged from the previous
// inline index.html version.
const DEV_WS_MUTE_SCRIPT = `
      // Mute Vite's HMR-failure noise. Native HMR is off (vite.config.ts:
      // server.hmr=false) because the runtime preview proxy is HTTP-only;
      // reload comes from the SSE dev-reload plugin instead. @vite/client
      // still attempts a WS connection regardless of hmr:false, so two layers:
      //  1. Stub WebSocket for subprotocol 'vite-hmr' — the synthetic close
      //     skips the network entirely, so the browser never logs its native
      //     "WebSocket connection ... failed:" line (that line bypasses
      //     console.* and can't be filtered any other way). Vite's transport
      //     rejects with "closed without opened", matching its expected path.
      //  2. Filter "failed to connect to websocket" from console.warn/error,
      //     covering Vite's own diagnostic at client.mjs:861/868.
      // Must run before @vite/client loads.
      (function () {
        const RealWS = window.WebSocket;
        function StubWS(url, protocols) {
          const isHmr =
            protocols === 'vite-hmr' ||
            (Array.isArray(protocols) && protocols.includes('vite-hmr'));
          if (!isHmr) return new RealWS(url, protocols);
          const listeners = { close: [], error: [], open: [], message: [] };
          const fake = {
            readyState: 0,
            url: url,
            protocol: '',
            send: function () {},
            close: function () {},
            addEventListener: function (type, fn) {
              (listeners[type] || (listeners[type] = [])).push(fn);
            },
            removeEventListener: function (type, fn) {
              const arr = listeners[type]; if (!arr) return;
              const i = arr.indexOf(fn); if (i >= 0) arr.splice(i, 1);
            },
            dispatchEvent: function () { return true; },
            onopen: null, onclose: null, onerror: null, onmessage: null,
          };
          queueMicrotask(function () {
            fake.readyState = 3;
            const ev = new CloseEvent('close', { code: 1006, reason: '', wasClean: false });
            listeners.close.forEach(function (fn) { try { fn.call(fake, ev); } catch (e) {} });
            if (typeof fake.onclose === 'function') { try { fake.onclose(ev); } catch (e) {} }
          });
          return fake;
        }
        StubWS.CONNECTING = 0;
        StubWS.OPEN = 1;
        StubWS.CLOSING = 2;
        StubWS.CLOSED = 3;
        StubWS.prototype = RealWS.prototype;
        window.WebSocket = StubWS;

        ['warn', 'error'].forEach(function (level) {
          const orig = console[level];
          console[level] = function () {
            const first = arguments[0];
            if (typeof first === 'string' && first.includes('failed to connect to websocket')) return;
            return orig.apply(console, arguments);
          };
        });
      })();
    `;

function devWsMute(): Plugin {
  return {
    name: "aether-dev-ws-mute",
    apply: "serve",
    transformIndexHtml(html: string) {
      return {
        html,
        tags: [
          { tag: "script", injectTo: "head-prepend", children: DEV_WS_MUTE_SCRIPT },
        ],
      };
    },
  };
}

export default defineConfig(({ mode }) => {
  // Use process.cwd() not __dirname — ESM configs bundled by Vite can't rely on
  // __dirname, but `cd app && bun run dev` makes cwd === app/ reliably.
  const envDir = process.cwd();
  const env = loadEnv(mode, envDir, "");
  // VITE_BASE is written to .env.development.local by the orchestrator
  // (_provision_app_template in tool_hooks.py) with the session-scoped
  // tokenless dev-proxy path `/v1/dev/{session_id}/`. Every absolute asset
  // URL Vite emits (`/@vite/client`, `/src/...`, `/@fs/...`) is prefixed
  // with this base, so the runtime proxy route matches. Fall back to "./"
  // for non-session contexts (e.g., `bun run build` on a dev machine).
  const base = env.VITE_BASE || "./";
  // Intentional: visible at dev-server startup so we can confirm which base Vite
  // is actually using when debugging proxy issues. Safe to leave in — only runs
  // once per `vite` invocation.
  console.log(`[vite.config] mode=${mode} envDir=${envDir} base=${base} reload=sse`);

  return {
    plugins: [aetherSdkSqlFix(), aetherBuildId(), react(), tailwindcss(), devReloadSSE(), devWsMute()],
    base,
    // 3D model files are binary assets Vite does not know by default; without
    // this, `import url from "@/assets/model.glb"` fails in import-analysis.
    assetsInclude: ["**/*.glb", "**/*.gltf", "**/*.obj", "**/*.stl"],
    // Vite's default cacheDir is `node_modules/.vite`, but in the aether
    // orchestrator container node_modules is a root-owned bind mount while
    // vite runs as uid 1500 (cowork). Writing there fails with EACCES during
    // optimizeDeps (`deps_temp_*` mkdir) and when Vite bundles the config
    // file itself (`config.ts.timestamp-*.mjs`).
    //
    // The orchestrator points `AETHER_VITE_CACHE_DIR` at a per-app dir OFF
    // the FUSE workspace mount. rclone/FUSE does NOT support atomic directory
    // rename — Vite's optimizeDeps commits its bundle by renaming
    // `<cacheDir>/deps_temp_* -> <cacheDir>/deps`, which fails with `EIO` on a
    // FUSE cacheDir; the optimize then crashes and, under
    // `optimizeDeps.holdUntilCrawlEnd:true` below, every `/deps/*.js` request
    // blocks behind the failed optimize, surfacing to the browser as a
    // dep-prebundle 504 storm. The orchestrator's dir is tmpfs-backed (atomic
    // rename works) and is seeded from the image-baked deps, so warm
    // first-paint is preserved AND a runtime re-optimize can complete.
    //
    // Fallback when the env var is unset (non-orchestrator contexts, e.g.
    // `bun run build` on a dev machine): the historical per-app
    // `apps/{app_id}/.vite-cache/` — byte-identical to before. Vite's default
    // `node_modules/.vite` is unusable in-container (root-owned bind mount,
    // vite runs as uid 1500 -> EACCES on the `deps_temp_*` mkdir). The cache
    // is regenerable; it is reclaimed on `app_manager purge`
    // (`dev_server_manager.reclaim_vite_cache_dir`, both the off-FUSE and the
    // legacy in-workspace location) and on container restart — losing it is
    // intentional.
    cacheDir: process.env.AETHER_VITE_CACHE_DIR || path.resolve(envDir, ".vite-cache"),
    resolve: {
      alias: {
        "@": path.resolve(envDir, "src"),
        // Azure Artifacts can mirror TanStack packages without their build/
        // outputs. Vite dev can consume the shipped sources directly.
        "@tanstack/react-query": path.resolve(envDir, "node_modules/@tanstack/react-query/src/index.ts"),
        "@tanstack/query-core": path.resolve(envDir, "node_modules/@tanstack/query-core/src/index.ts"),
        "@tanstack/react-table": path.resolve(envDir, "node_modules/@tanstack/react-table/src/index.tsx"),
        "@tanstack/table-core": path.resolve(envDir, "node_modules/@tanstack/table-core/src/index.ts"),
      },
    },
    build: {
      outDir: "dist",
      emptyOutDir: true,
      write: process.env.VITE_CHECK_MODE !== "true",
      // A dashboard's data snapshot (src/data/*.ndjson.gz, written by embed-csv-data.sh) is
      // fetched at runtime and gzips small enough to fall under the default 4 KB limit; keep it
      // a file so it is never inlined as a `data:` URL for fetch to read. Other assets keep the
      // default.
      assetsInlineLimit: (file: string) => (file.endsWith(".ndjson.gz") ? false : undefined),
      rollupOptions: {
        output: {
          // Produce one JS chunk (no code-splitting on dynamic
          // imports). A single chunk benefits small SPAs (one network
          // round-trip for first paint, no async chunk waterfall). Flip
          // this to ``false`` once any app in the template actually uses
          // ``React.lazy(() => import(...))`` and the bundle is large
          // enough that code-splitting wins outweigh the extra
          // round-trip.
          inlineDynamicImports: true,
        },
      },
    },
    server: {
      port: 5173,
      strictPort: true,
      // When the orchestrator relocates the dep cache OFF the project root
      // (`AETHER_VITE_CACHE_DIR`, the FUSE atomic-rename fix), Vite serves the
      // prebundled deps via `/@fs/<abs>` URLs. `server.fs.strict` defaults to
      // true, so without an explicit allow-entry the off-root deps would 403
      // and the app would fail to load entirely. Add the cache dir to the
      // allow-list (keeping the default workspace root). Only set `fs` when the
      // override is present so non-orchestrator runs (`bun run build`/dev
      // machine) keep Vite's exact default behaviour.
      ...(process.env.AETHER_VITE_CACHE_DIR
        ? {
            fs: {
              allow: [
                searchForWorkspaceRoot(process.cwd()),
                process.env.AETHER_VITE_CACHE_DIR,
              ],
            },
          }
        : {}),
      // Loopback bind. The runtime reaches Vite via the orchestrator nginx
      // `/v1/dev/{sid}/{aid}/` reverse-proxy on port 9001 — same-container
      // nginx → loopback Vite. Binding all interfaces is unnecessary and
      // would expose the dev server to in-VNet pods that have no business
      // talking to it. The runtime preview proxy is the auth boundary;
      // nginx is the cross-container ingress.
      host: "127.0.0.1",
      // Native WebSocket HMR is disabled in favor of the SSE dev-reload plugin
      // (`./vite-dev-reload.ts`, inlined scaffold). SSE flows through the runtime
      // preview proxy as plain HTTP with no WebSocket upgrade required,
      // avoiding corporate / runtime proxy WS compatibility issues.
      hmr: false,
      // The orchestrator workspace is a fuse.rclone mount, which does not
      // propagate inotify events. Chokidar's default native watcher opens
      // inotify fds but never receives writes, so `handleHotUpdate` never
      // fires and the SSE reload plugin never broadcasts `build-end`.
      // Polling sidesteps the FUSE blind spot by stat()ing files periodically.
      watch: {
        usePolling: true,
        interval: 500,
        ignored: [
          "**/node_modules/**",
          "**/.git/**",
          "**/.vite-cache/**",
          "**/dist/**",
          "**/.dev-server.log",
          "**/.browser-errors.log",
          // Sibling of .browser-errors.log — written by the agent's verify
          // step (see AGENTS.md "Verification loop" — `seq.write_text(str(top))`).
          // Without this, every advance of the high-water mark fires a chokidar
          // change event → full page reload → fresh render → potentially fresh
          // errors → re-verify loop. Mirror the .log entry above.
          "**/.browser-errors.seq",
          // Vite's own bundled-config temp file. When ``bun run build`` runs
          // (or anything that re-evaluates vite.config.ts), Vite writes
          // ``vite.config.ts.timestamp-<random>.mjs`` to the project root
          // and unlinks it on exit. Without this, every build fires two
          // chokidar events (add + unlink) → two ``build-end`` SSE events →
          // two full iframe reloads. The ``.cjs`` extension is hedged
          // against future Vite versions that may write CommonJS instead.
          "**/*.timestamp-*.mjs",
          "**/*.timestamp-*.cjs",
          // ms.config.json — the MAAF V0 app config. Written only by the
          // Aether runtime: provisioning at create and after each successful
          // save+publish (appId, environmentId, repositoryId, canonical
          // display name), and the typed data-source tools (the
          // connectionReferences bindings). Not imported by any source file —
          // purely a sidecar metadata file for the runtime and the publish
          // pipeline. Without this entry, every config mutation
          // fires one full iframe reload on top of any build-driven
          // reload, which the user sees as the "preview flash on save"
          // symptom.
          "**/ms.config.json",
        ],
      },
    },
    optimizeDeps: {
      // Pin React + every React-importing dep here. Omitting `radix-ui`
      // lets Vite optimize its deep imports on-demand via the CJS-interop
      // path, which can yield `React.useContext === null` at runtime.
      //
      // Exception: a dep whose `resolve.alias` target is NON-optimizable is
      // deliberately absent. Vite's `isOptimizable` allowlist is
      // `.js/.cjs/.mjs/.ts/.cts/.mts` — `.tsx`/`.jsx` are rejected — so esbuild
      // cannot prebundle it and listing it only emits `Cannot optimize
      // dependency: <pkg>, present in client 'optimizeDeps.include'` on every
      // dev-server start (app-studio#1728). `@tanstack/react-table` is aliased
      // to `src/index.tsx` and is therefore NOT pinned; its alias stays, and it
      // is served on demand via the JSX transform. Do not re-add it here.
      //
      // `holdUntilCrawlEnd: true` reverts Vite 5.1+'s default partial-prebundle
      // behavior. Without it, Vite ships an initial prebundle while still
      // discovering deps, then re-prebundles when new deps surface — producing
      // multiple `?v=<hash>` versions of `react.js` served to the same load.
      // Two React module identities = `useRef`/`useCallback`/`useContext` is
      // null = ErrorBoundary card. Reproduces deterministically on the 3rd
      // app spawn in a multi-app conversation (#7706 multi-app variant).
      holdUntilCrawlEnd: true,
      include: [
        "react",
        "react/jsx-runtime",
        "react/jsx-dev-runtime",
        "react-dom",
        "react-dom/client",
        // Radix UI unified package — every shadcn (new-york) ui primitive
        // imports from `radix-ui` (e.g. `import { Dialog } from "radix-ui"`).
        // Pinning it prevents on-demand re-discovery when the agent writes
        // code that newly imports a primitive, which would trigger a
        // re-prebundle and ship a second React hash.
        "radix-ui",
        "@dnd-kit/core",
        "@dnd-kit/sortable",
        "@dnd-kit/utilities",
        // Managed Apps iframe SDK — only subpath exports exist, no bare
        // `.` entry in the package's `exports` field (verified against
        // node_modules/@microsoft/managed-apps/package.json — keys are
        // `./app`, `./auth`, `./data`, and `./telemetry`).
        // Listing the bare specifier here would cause `vite optimize`
        // to fail with "'.' is not exported under [...]".  Pinning the
        // `/data` subpath instead — what the managed-apps connector
        // codegen emits imports from (`@microsoft/managed-apps/data`) —
        // forces the prebundle at dev-server startup so the iframe's
        // first `/data` import is served from `.vite-cache/deps/` rather
        // than triggering a cold on-demand prebundle behind the upstream
        // proxy's read deadline (same rationale as the TanStack pins
        // below).
        "@microsoft/managed-apps/data",
        // `/app` (getContext) is imported by the dashboard CopyLinkButton and,
        // with `/auth`, on demand by the query cache (src/lib/query-cache.ts).
        "@microsoft/managed-apps/app",
        "@microsoft/managed-apps/auth",
        "@zxing/library",
        "leaflet",
        "html2canvas-pro",
        "jspdf",
        "three",
        "three/examples/jsm/controls/OrbitControls.js",
        "three/examples/jsm/loaders/GLTFLoader.js",
        "three/examples/jsm/loaders/OBJLoader.js",
        "three/examples/jsm/loaders/STLLoader.js",
        "three/examples/jsm/environments/RoomEnvironment.js",
        "react-markdown",
        "remark-gfm",
        // TanStack peers are aliased above to the package's TypeScript
        // source (Azure Artifacts mirror lacks dist/). Without an explicit
        // include entry, Vite discovers each on-demand at iframe load and
        // cold-prebundles esbuild → can exceed the upstream proxy's read
        // deadline (Plex Island Gateway in prod). Pinning here forces the
        // prebundle at dev-server startup so the iframe's first request
        // for ``.vite-cache/deps/@tanstack_react-query.js`` is served from
        // disk, not generated on demand. See #8088.
        "@tanstack/react-query",
        "class-variance-authority",
        "clsx",
        "cmdk",
        "date-fns",
        "zustand",
        "lucide-react",
        "motion",
        "prismjs",
        "prismjs/components/prism-sql",
        "prismjs/components/prism-kusto",
        "react-day-picker",
        "react-router-dom",
        "react-webcam",
        "recharts",
        "signature_pad",
        "sonner",
        "sql.js",
        "tailwind-merge",
        "unpdf",
        "xlsx",
      ],
    },
  };
});
