/**
 * Fixed parent-frame message contract for the app preview.
 *
 * The template sends exactly three message families to its embedding Cowork
 * host, all fixed/typed here — no ad hoc envelope may be declared inline at
 * a call site:
 *   - A fixed, detail-free runtime-error signal: no error name, message,
 *     stack, component stack, route, URL, token, app id, or customer
 *     content ever crosses through it. The companion Cowork receiver owns
 *     any user-facing handling once support for this code lands.
 *   - A fixed, detail-free app-mounted signal: only a `timestamp` (a clock
 *     reading, not customer content) crosses through it, so the host can
 *     measure real first-paint latency.
 *   - A bounded app-view snapshot: the matched route PATTERN and an
 *     accessible-name tree of what is on screen, so the agent can ground on
 *     what the user is looking at. This family carries app content by
 *     design; its bound is the serialiser (`src/lib/app-view-serializer.ts`)
 *     and the caps below, and it is the ONLY family allowed to.
 *
 * This extends Cowork's existing `preview-error` envelope family with a new
 * fixed `code`. See:
 *   - src/lib/cowork-parent-transport.ts  (the runtime-error sender)
 *   - src/lib/app-mounted-transport.ts    (the app-mounted sender)
 *   - src/lib/app-view-transport.ts       (the app-view sender)
 *   - src/components/error-boundary.tsx   (caught render crashes)
 *   - src/main.tsx                        (uncaught root crashes; mount signal)
 *   - src/App.tsx                         (app-view signal, inside the router)
 *   - AGENTS.md                           ("Parent-frame message contract")
 */

/** Fixed message `type` — Cowork's preview-error envelope family. */
export const PREVIEW_ERROR_TYPE = "preview-error" as const;

/** Fixed message `code` for a render-phase runtime crash. */
export const APP_RUNTIME_ERROR_CODE = "APP_RUNTIME_ERROR" as const;

/**
 * The complete, immutable runtime-error message. Two string literals only.
 * Deliberately has NO `payload`, `message`, `source`, `name`, `stack`,
 * `appId`, `url`, or any other field.
 */
export interface AppRuntimeErrorMessage {
  readonly type: typeof PREVIEW_ERROR_TYPE;
  readonly code: typeof APP_RUNTIME_ERROR_CODE;
}

/** The single runtime-error value this template may post to its parent frame. */
export const APP_RUNTIME_ERROR_MESSAGE: AppRuntimeErrorMessage = Object.freeze({
  type: PREVIEW_ERROR_TYPE,
  code: APP_RUNTIME_ERROR_CODE,
});

/** Fixed message `type` for the app-mounted (first-paint) signal. */
export const APP_MOUNTED_TYPE = "app-mounted" as const;

/**
 * The app-mounted message shape. `timestamp` is the only dynamic field —
 * a `Date.now()` clock reading, not customer content — filled in by the
 * sender at call time, which is why this is a type rather than a single
 * frozen constant like `APP_RUNTIME_ERROR_MESSAGE`.
 */
export interface AppMountedMessage {
  readonly type: typeof APP_MOUNTED_TYPE;
  readonly timestamp: number;
}

/** Fixed message `type` for the app-view snapshot. */
export const APP_VIEW_TYPE = "app-view" as const;

/** Wire version of the app-view envelope; bump on any field change. */
export const APP_VIEW_PROTOCOL_VERSION = 1 as const;

/**
 * Hard cap on the serialised accessible-name tree, in characters. Mirrors
 * the Cowork receiver's `APP_VIEW_MAX_DOM_CHARS`; the runtime re-cuts at the
 * same bound, so a change here is a three-repo change.
 */
export const APP_VIEW_MAX_TREE_CHARS = 24_000;

/** Hard cap on the matched route pattern, in characters. */
export const APP_VIEW_MAX_ROUTE_CHARS = 512;

/**
 * What the serialiser hands the sender. `route` is a route PATTERN from the
 * routes manifest (never the pathname, never params); `tree` is the
 * accessible-name tree cut at whole lines; `truncated` says whether any cap
 * cut it.
 */
export interface AppViewSnapshot {
  readonly route: string;
  readonly tree: string;
  readonly truncated: boolean;
}

/**
 * The app-view message shape. `timestamp` is informational: the host
 * measures snapshot age from its own receipt time, never from this clock.
 * The receiver stamps the app id from the bound iframe, so the envelope
 * carries none.
 */
export interface AppViewMessage {
  readonly type: typeof APP_VIEW_TYPE;
  readonly v: typeof APP_VIEW_PROTOCOL_VERSION;
  readonly timestamp: number;
  readonly route: string;
  readonly tree: string;
  readonly truncated: boolean;
}

/** Narrow alias: the only AppMessages this template emits to its parent. */
export type AppMessage = AppRuntimeErrorMessage | AppMountedMessage | AppViewMessage;
