/**
 * App-mounted (first-paint) transport to the embedding Cowork host
 * (app-studio#2979 P1).
 *
 * This is the ONLY module that posts the app-mounted signal to the parent
 * frame. It sends a fixed-shape, detail-free message — a `timestamp` clock
 * reading and nothing else — so the Cowork host can measure real
 * spinner-to-content latency instead of inferring it from the outside
 * (iframe `load` fires on document parse, long before the app's module
 * graph has fetched/executed/rendered).
 *
 * Security posture mirrors `cowork-parent-transport.ts` (do not weaken):
 *   - No wildcard (`"*"`) target origin. The fixed message is posted to
 *     every known Cowork host origin from the SAME audited allow-list
 *     `cowork-parent-transport.ts` uses; only the origin that matches the
 *     actual embedding parent delivers.
 *   - No inferred-origin logic (no `ancestorOrigins`, `document.referrer`,
 *     or `location.origin` fallback). If the embedding host origin is not
 *     in the allow-list, the signal simply never arrives — the host falls
 *     back to its own less-precise timing.
 *   - No general-purpose "post to parent" API — this module sends exactly
 *     one fixed-shape message and nothing else.
 */

import { COWORK_PARENT_ORIGINS } from "./cowork-parent-transport";
import { APP_MOUNTED_TYPE, type AppMountedMessage } from "@/types/app-message";

// Guards against firing more than once even if callers double-invoke (e.g.
// StrictMode double-render in dev only calls this once since it's scheduled
// off a `requestAnimationFrame` after the real commit, but a caller retry
// on remount should still be a no-op — the host only cares about the first
// paint).
let appMountedSignalSent = false;

/**
 * Notify the embedding Cowork host that this app's React root has mounted
 * and completed its first paint.
 *
 * Fixed, detail-free signal — carries only a timestamp, no route/URL/appId/
 * customer content. No-op when running top-level (not embedded in a parent
 * frame) or if already sent once.
 */
export function postAppMountedToCoworkParent(): void {
  if (window.parent === window || appMountedSignalSent) {
    return;
  }
  appMountedSignalSent = true;
  const message: AppMountedMessage = {
    type: APP_MOUNTED_TYPE,
    timestamp: Date.now(),
  };
  for (const targetOrigin of COWORK_PARENT_ORIGINS) {
    window.parent.postMessage(message, targetOrigin);
  }
}
