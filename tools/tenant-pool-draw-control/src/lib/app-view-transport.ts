/**
 * App-view transport to the embedding Cowork host.
 *
 * This is the ONLY module that posts the app-view snapshot to the parent
 * frame. It receives an already-bounded snapshot from
 * `app-view-serializer.ts` and forwards it verbatim: this module never reads
 * the DOM, the location, storage, or anything else about the app. What may
 * cross the boundary is decided by the serialiser's allow-list and caps, and
 * pinned by the Aether source-contract guard; this file only carries it.
 *
 * Security posture mirrors `cowork-parent-transport.ts` (do not weaken):
 *   - No wildcard (`"*"`) target origin. The message is posted to every
 *     known Cowork host origin from the SAME audited allow-list
 *     `cowork-parent-transport.ts` uses; only the origin that matches the
 *     actual embedding parent delivers, and Cowork pins `event.source` to
 *     this iframe before acting on it.
 *   - No inferred-origin logic (no `ancestorOrigins`, `document.referrer`,
 *     or `location.origin` fallback).
 *   - No inbound listener. The host never talks back on this channel.
 *   - No general-purpose "post to parent" API — one fixed-shape message.
 */

import { COWORK_PARENT_ORIGINS } from "./cowork-parent-transport";
import {
  APP_VIEW_PROTOCOL_VERSION,
  APP_VIEW_TYPE,
  type AppViewMessage,
  type AppViewSnapshot,
} from "../types/app-message";

/**
 * True when this document is embedded in ANY parent frame — the name records
 * the caller's intent, not a verified Cowork parent. The signal uses it only
 * to avoid observing the DOM at all when running top-level; what bounds where
 * a snapshot can GO is the explicit `targetOrigin` allow-list in
 * `postAppViewToCoworkParent`, never this predicate. The parent-frame
 * reference stays inside this file so the guard can confine it.
 */
export function isEmbeddedInCoworkParent(): boolean {
  return window.parent !== window;
}

/**
 * Post one bounded app-view snapshot to the embedding Cowork host.
 *
 * No-op when running top-level (not embedded in a parent frame).
 */
export function postAppViewToCoworkParent(snapshot: AppViewSnapshot): void {
  if (window.parent === window) {
    return;
  }
  const message: AppViewMessage = {
    type: APP_VIEW_TYPE,
    v: APP_VIEW_PROTOCOL_VERSION,
    timestamp: Date.now(),
    route: snapshot.route,
    tree: snapshot.tree,
    truncated: snapshot.truncated,
  };
  for (const targetOrigin of COWORK_PARENT_ORIGINS) {
    window.parent.postMessage(message, targetOrigin);
  }
}
