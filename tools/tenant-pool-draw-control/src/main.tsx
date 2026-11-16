import { StrictMode, useEffect } from "react";
import { createRoot } from "react-dom/client";
// console-capture MUST be imported before ./App (#24067 criterion 2): ESM
// evaluates modules in declaration order, so this ordering is what installs
// the window.onerror / unhandledrejection listeners BEFORE the app's module
// graph evaluates — a module-eval throw anywhere under ./App is captured and
// POSTed to ./__dev/console during authoring instead of dying unobserved.
import { reportPrivateRuntimeError } from "./lib/console-capture";
import { App } from "./App";
import { postAppRuntimeErrorToCoworkParent } from "./lib/cowork-parent-transport";
import { postAppMountedToCoworkParent } from "./lib/app-mounted-transport";
import { startConnectorPolicyMonitor } from "./lib/connector-policy-monitor";
import { ConnectorPolicyBanner } from "./components/connector-policy-banner";
import { installPreviewCameraBridge } from "./lib/preview-camera-bridge";
import "./index.css";

// Before render, so a block on the first page's queries is not missed.
startConnectorPolicyMonitor();

// Design-time preview only: the host iframe has no camera of its own, so route
// getUserMedia through the Cowork host's consented camera bridge. A published
// build is not DEV and keeps the browser's own camera.
if (import.meta.env.DEV) {
  installPreviewCameraBridge();
}

// Normalize ``/index.html`` → ``/`` before react-router-dom mounts.
//
// Some deep-link / share-link entrypoints land the player on
// ``.../index.html`` instead of ``.../``. React Router's
// ``BrowserRouter`` matches against the FULL pathname, and the app's
// routes are configured against ``/`` (post-basename strip), so
// ``index.html`` left in the URL falls through to the catch-all
// (NotFoundPage in apps that have one, or simply renders nothing in
// apps that don't). Rewriting via ``history.replaceState`` preserves
// whatever query string and hash the user navigated with (the MAAF
// island gateway authenticates via cookies/headers and doesn't put
// anything in the URL itself, but user-supplied deep-link params
// ride through unmodified) and avoids a network round-trip.
if (window.location.pathname.endsWith("/index.html")) {
  const newPath = window.location.pathname.replace(/\/index\.html$/, "/");
  window.history.replaceState(
    null,
    "",
    newPath + window.location.search + window.location.hash,
  );
}

// Mount signal (app-studio#2979 P1): timestamp roughly when React has
// committed the first paint so the Cowork host can measure real
// spinner-to-content latency instead of inferring it from the outside
// (iframe `load` fires on document parse, long before the app's module
// graph has fetched/executed/rendered).
//
// This MUST run from a `useEffect`, not a bare `requestAnimationFrame`
// scheduled right after `.render()`: React 18's root render is
// concurrent, so `.render()` returning does not mean React has committed
// yet — a module-level rAF can fire before the real first paint and end
// up measuring module-evaluation time instead. `useEffect` on a component
// mounted alongside `<App />` gives the commit guarantee (React schedules
// passive effects as a browser task, which lets the browser paint the
// committed frame first in the common case). The nested rAF is NOT a
// "wait until painted" guarantee — per spec, an animation-frame callback
// runs BEFORE its frame's paint, not after — it is only a defensive delay
// to the next frame boundary in case the effect itself runs before the
// browser has had a chance to paint. `performance.mark` is local-only
// (DevTools/Perf API); the parent signal is the fixed, detail-free
// postMessage below.
function MountSignal() {
  useEffect(() => {
    requestAnimationFrame(() => {
      performance.mark("aether:app-mounted");
      postAppMountedToCoworkParent();
    });
  }, []);
  return null;
}

createRoot(document.getElementById("root")!, {
  onCaughtError(error, errorInfo) {
    reportPrivateRuntimeError(
      "[React caught error]",
      error,
      errorInfo.componentStack,
    );
  },
  onUncaughtError(error, errorInfo) {
    reportPrivateRuntimeError(
      "[React uncaught error]",
      error,
      errorInfo.componentStack,
    );
    postAppRuntimeErrorToCoworkParent();
  },
  onRecoverableError(error, errorInfo) {
    reportPrivateRuntimeError(
      "[React recoverable error]",
      error,
      errorInfo.componentStack,
    );
  },
}).render(
  <StrictMode>
    <App />
    <ConnectorPolicyBanner />
    <MountSignal />
  </StrictMode>
);

