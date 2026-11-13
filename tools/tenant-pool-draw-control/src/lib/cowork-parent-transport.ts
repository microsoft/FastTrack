/**
 * Runtime-error transport to the embedding Cowork host.
 *
 * This is the ONLY module that posts a runtime-error signal to the parent
 * frame. It sends a fixed, zero-argument, detail-free message so no dynamic
 * error data (name / message / stack / component stack / route / URL / token /
 * app id / customer content) ever crosses the parent-frame boundary. The
 * Cowork host owns the localized, user-facing crash UI.
 *
 * Security posture (do not weaken):
 *   - No wildcard (`"*"`) target origin. Each fixed message is posted to every
 *     known Cowork host origin; only the origin that matches the actual
 *     embedding parent delivers, and Cowork additionally pins `event.source`
 *     to this iframe before acting on it.
 *   - No inferred-origin logic (no `ancestorOrigins`, `document.referrer`,
 *     or `location.origin` fallback). If the embedding host origin is not in
 *     the allow-list below, the preview degrades gracefully to its in-frame
 *     fallback and simply does not raise the host-level generic crash UI.
 *   - No general-purpose "post to parent" API. Every other purpose-built
 *     signal lives in its own dedicated sibling file and imports
 *     `COWORK_PARENT_ORIGINS` from here rather than duplicating it: the
 *     app-mounted first-paint signal (`app-mounted-transport.ts`) and the
 *     bounded app-view snapshot (`app-view-transport.ts`). The general
 *     console-forwarding channel remains console-capture.ts's own legacy,
 *     runtime-derived-origin path — do not route new purpose-built signals
 *     through it.
 */

import {
  APP_RUNTIME_ERROR_MESSAGE,
  type AppRuntimeErrorMessage,
} from "@/types/app-message";

/**
 * Explicit allow-list of Cowork host origins the preview may signal.
 *
 * Keep this in sync with Cowork's supported host origins. Adding a new host
 * origin is the ONLY expected change to this file. Never add `"*"`, a suffix
 * match, or a runtime-derived origin.
 *
 * Exported so every purpose-built parent-frame transport — `app-mounted-transport.ts`
 * (the third channel, app-studio#2979 P1) and `app-view-transport.ts` (the
 * fourth, app vision) — broadcasts to the identical audited list instead of
 * maintaining a second, driftable copy. AGENTS.md's LOCKED section lists them.
 */
export const COWORK_PARENT_ORIGINS: readonly string[] = [
  // Local AAD Coworker host (agentbuilder dev certificate).
  "https://agentbuilder.local.microsoft.com:44300",
  // Local / CI no-certificate fallback.
  "http://localhost:44300",
  // Local MSA Coworker host.
  "https://local.loop.microsoft.com:8080",
  // Deployed BizChat / Cowork (m365.cloud.microsoft).
  "https://m365.cloud.microsoft",
  // Deployed Cowork on the Copilot app hosts.
  "https://copilot.cloud.microsoft",
  "https://m365copilotapp.svc.cloud.microsoft",
  "https://cr.m365copilotapp.svc.cloud.microsoft",
  // Deployed Cowork inside the Microsoft 365 and Outlook web shells.
  "https://www.microsoft365.com",
  "https://outlook.office.com",
];

/** The single, immutable message posted to the parent frame. */
const CRASH_MESSAGE: AppRuntimeErrorMessage = APP_RUNTIME_ERROR_MESSAGE;

/**
 * Notify the embedding Cowork host that the app preview crashed.
 *
 * Takes NO arguments and sends NO dynamic data — only the two fixed string
 * literals in `APP_RUNTIME_ERROR_MESSAGE`. No-op when running top-level (not
 * embedded in a parent frame).
 */
export function postAppRuntimeErrorToCoworkParent(): void {
  if (window.parent === window) {
    return;
  }
  for (const targetOrigin of COWORK_PARENT_ORIGINS) {
    window.parent.postMessage(CRASH_MESSAGE, targetOrigin);
  }
}
