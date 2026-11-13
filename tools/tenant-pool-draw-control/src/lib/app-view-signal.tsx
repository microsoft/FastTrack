/**
 * App-view signal: when to report what the user is looking at.
 *
 * Mounted once inside `<BrowserRouter>` by `App.tsx`, on the preview mount
 * only, so it can read the router's pathname. A route change or a DOM
 * mutation anywhere in the document schedules ONE emission once mutations
 * have been quiet for a window — every mutation re-arms it, bounded by a
 * maximum wait so a page that never settles still reports — with a floor
 * between emissions, so the host receives the latest view rather than a feed.
 * The host keeps only the newest snapshot and
 * attaches it to the user's next chat send.
 *
 * The whole `document.body` is observed and serialised, not `#root`: the
 * shadcn overlays (dialog, sheet, select, menus, popovers) render through a
 * Radix portal into `body`, and the overlay is exactly what the user is
 * looking at when it is open.
 *
 * This file never touches the parent frame: it hands a bounded snapshot from
 * `app-view-serializer.ts` to `app-view-transport.ts`, which owns the
 * `postMessage`. When the document is not embedded, nothing is observed.
 */

import { useEffect } from "react";
import { useLocation } from "react-router-dom";

import { matchedRoutePattern, serializeAppView } from "./app-view-serializer";
import {
  isEmbeddedInCoworkParent,
  postAppViewToCoworkParent,
} from "./app-view-transport";
import { reportPrivateRuntimeError } from "./console-capture";

/** Mutations settle for this long before one snapshot is taken. */
export const APP_VIEW_QUIET_WINDOW_MS = 500;

/** A mutation stream that never settles still yields a snapshot this long after its first mutation. */
export const APP_VIEW_MAX_WAIT_MS = 2_000;

/** Floor between two emissions, whatever the mutation rate. */
export const APP_VIEW_MIN_INTERVAL_MS = 1_000;

/** Attribute changes that can alter the accessible tree; others are ignored. */
const OBSERVED_ATTRIBUTES = [
  "hidden",
  "inert",
  "role",
  "aria-hidden",
  "aria-label",
  "aria-labelledby",
  "aria-checked",
  "aria-expanded",
  "aria-selected",
  "aria-disabled",
  "alt",
  "title",
  "disabled",
  "open",
  "data-state",
];

// Module-level so the floor survives the effect re-running on a route change.
let lastEmittedAt = 0;

export function AppViewSignal({ patterns }: { patterns: readonly string[] }) {
  const { pathname } = useLocation();

  useEffect(() => {
    if (!isEmbeddedInCoworkParent()) {
      return;
    }
    const root = document.body;

    let timer: ReturnType<typeof setTimeout> | undefined;
    let firstScheduledAt: number | undefined;
    let disposed = false;

    const emit = () => {
      timer = undefined;
      firstScheduledAt = undefined;
      if (disposed) {
        return;
      }
      const wait = lastEmittedAt + APP_VIEW_MIN_INTERVAL_MS - Date.now();
      if (wait > 0) {
        timer = setTimeout(emit, wait);
        return;
      }
      lastEmittedAt = Date.now();
      let snapshot;
      try {
        const { tree, truncated } = serializeAppView(root);
        snapshot = { route: matchedRoutePattern(pathname, patterns), tree, truncated };
      } catch (cause) {
        // A serialiser fault is infra, not an app defect: report it on the
        // private diagnostics path (never the forwarded console, never a
        // thrown error the app-builder agent would read as its own crash)
        // and stop reporting for this route rather than retrying on every
        // mutation.
        observer.disconnect();
        reportPrivateRuntimeError("[app-view serialiser]", cause);
        return;
      }
      postAppViewToCoworkParent(snapshot);
    };

    const schedule = () => {
      const now = Date.now();
      if (timer === undefined) {
        firstScheduledAt = now;
      } else {
        // Trailing debounce: a mutation inside the window re-arms it, so the
        // snapshot is taken once the DOM has been quiet for the whole window.
        clearTimeout(timer);
      }
      const deadline = (firstScheduledAt ?? now) + APP_VIEW_MAX_WAIT_MS;
      timer = setTimeout(emit, Math.max(0, Math.min(APP_VIEW_QUIET_WINDOW_MS, deadline - now)));
    };

    const observer = new MutationObserver(schedule);
    observer.observe(root, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: OBSERVED_ATTRIBUTES,
    });
    schedule();

    return () => {
      disposed = true;
      observer.disconnect();
      if (timer !== undefined) {
        clearTimeout(timer);
      }
    };
  }, [pathname, patterns]);

  return null;
}
