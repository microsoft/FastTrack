import { BrowserRouter, Route, Routes } from "react-router-dom";
import { QueryClientProvider } from "@tanstack/react-query";
import { MotionConfig } from "motion/react";
import { ErrorBoundary } from "@/components/error-boundary";
import { ConfirmDialogProvider } from "@/components/confirm-dialog";
import { queryClient } from "@/lib/query-client";
import { AppShell } from "@/components/app-shell";
import { NotFoundPage } from "@/pages/not-found";
import { routes } from "@/routes";
import { AppViewSignal } from "@/lib/app-view-signal";
import { isPreviewMount } from "@/lib/app-view-serializer";
import { AppShortcutProvider } from "@/components/shortcut-provider";

// Derive the router basename. The app is served under two kinds of mount:
//
//   DEV (runtime preview proxy):
//     URL  = /v1/preview/{token}/dev/...  or  /v1/dev/{sid}/{aid}/...
//     ``VITE_BASE`` is written into ``.env.development.local`` by the
//     orchestrator at session-start, so ``import.meta.env.BASE_URL`` has
//     the FULL session-scoped prefix baked in at build time.
//
//   DEPLOYED (published app, post ``main.tsx`` normalize):
//     ``import.meta.env.BASE_URL`` may not be a usable prefix for the served
//     URL, so derive the basename from the runtime pathname instead — take the
//     first path segment (matches Microsoft's canonical M365 Copilot template).
//     NOTE: the MAAF ``appPlayUri`` served-path shape is UNVERIFIED — the
//     first-path-segment fallback assumes a single-segment mount.
//
// Rule: trust ``BASE_URL`` ONLY when the runtime pathname actually starts
// with it. Anything else (an unusable build base, empty, malformed) falls
// through to runtime derivation. This avoids ad-hoc substring blacklists ever
// drifting out of date against Vite normalization changes.
function getRouterBasename(): string {
  const buildBase = import.meta.env.BASE_URL.replace(/\/$/, "");
  if (
    buildBase &&
    buildBase.startsWith("/") &&
    (window.location.pathname === buildBase ||
      window.location.pathname.startsWith(buildBase + "/"))
  ) {
    return buildBase;
  }
  const parts = window.location.pathname.split("/").filter(Boolean);
  return parts.length ? `/${parts[0]}/` : "/";
}
const ROUTER_BASENAME = getRouterBasename();

// Route PATTERNS for the app-view signal (never pathnames). Computed once so
// the signal effect does not re-run on every App render.
const APP_VIEW_ROUTE_PATTERNS: readonly string[] = routes.map((route) => route.path);

// App vision runs on the PREVIEW mount only. The orchestrator bakes the
// session-scoped ``/v1/...`` prefix into ``VITE_BASE`` for the dev preview
// (see getRouterBasename above); a deployed build carries no such base, and a
// deployed app inside the player host has no Cowork receiver to report to, so
// it must not observe or post at all.
const APP_VIEW_PREVIEW_MOUNT: boolean = isPreviewMount(import.meta.env.BASE_URL);

export function App() {
  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <MotionConfig reducedMotion="user">
          <AppShortcutProvider>
            <ConfirmDialogProvider>
              <BrowserRouter basename={ROUTER_BASENAME}>
                <Routes>
                  <Route path="/" element={<AppShell />}>
                    {routes.map((r) =>
                      r.path === "/" ? (
                        <Route key={r.path} index element={r.element} />
                      ) : (
                        <Route key={r.path} path={r.path} element={r.element} />
                      ),
                    )}
                    <Route path="*" element={<NotFoundPage />} />
                  </Route>
                </Routes>
                {APP_VIEW_PREVIEW_MOUNT && <AppViewSignal patterns={APP_VIEW_ROUTE_PATTERNS} />}
              </BrowserRouter>
            </ConfirmDialogProvider>
          </AppShortcutProvider>
        </MotionConfig>
      </QueryClientProvider>
    </ErrorBoundary>
  );
}
