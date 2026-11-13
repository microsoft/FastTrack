/**
 * Design-time preview camera bridge (app side). Infra — LOCKED, don't edit.
 *
 * Cowork's preview iframe is not delegated the browser camera, so a plain
 * `getUserMedia` there always fails. Instead the host owns the camera: it shows
 * its own per-app consent, opens a video-only camera at top level, and streams
 * frames to the app over a dedicated `MessagePort`. This module replaces
 * `navigator.mediaDevices.getUserMedia` in the dev preview only (installed from
 * `main.tsx` when `import.meta.env.DEV` and embedded), so react-webcam, and
 * with it `CameraCapture` and `BarcodeScanner`, keeps working unchanged.
 *
 * Wire protocol (version 1):
 * - app -> parent: `{ type: "cowork-camera/request", version: 1, requestId }`,
 *   posted to every `COWORK_PARENT_ORIGINS` entry, never `"*"`.
 * - parent -> app: `cowork-camera/pending` at once, then
 *   `cowork-camera/granted` with a transferred `MessagePort` (and optional
 *   `width` / `height`) or `cowork-camera/denied` with a `reason`. Replies are
 *   accepted only from `window.parent` at a `COWORK_PARENT_ORIGINS` origin.
 * - port: the host sends `{ type: "frame", bitmap }` and waits for this side's
 *   `{ type: "ack" }`; `{ type: "ended" }` closes the session. This side sends
 *   `{ type: "stop" }` to release the camera.
 *
 * Nothing about the app crosses to the host: the request carries a random id
 * only. When no host answers within `HOST_ANSWER_TIMEOUT_MS` (an older host, or
 * a non-Cowork embedder) every later call goes straight to the browser's own
 * `getUserMedia`. Audio requests always use the browser's own path.
 *
 * One host session serves every concurrent caller (React StrictMode mounts the
 * webcam twice in dev): frames are painted onto one canvas, each caller gets
 * its own `captureStream` track, and the host camera is released when the last
 * track stops.
 */

import { COWORK_PARENT_ORIGINS } from "./cowork-parent-transport";

const VERSION = 1;
const REQUEST_TYPE = "cowork-camera/request";
const PENDING_TYPE = "cowork-camera/pending";
const GRANTED_TYPE = "cowork-camera/granted";
const DENIED_TYPE = "cowork-camera/denied";

/** How long to wait for the host's `pending` before using the browser's own camera. */
export const HOST_ANSWER_TIMEOUT_MS = 1000;
const DEFAULT_WIDTH = 640;
const DEFAULT_HEIGHT = 480;
const CAPTURE_FPS = 30;

type GetUserMedia = (constraints?: MediaStreamConstraints) => Promise<MediaStream>;

type BridgeCanvas = {
  width: number;
  height: number;
  getContext(kind: "2d"): Pick<CanvasRenderingContext2D, "drawImage" | "fillRect" | "fillStyle"> | null;
  captureStream(frameRate?: number): MediaStream;
};

export type PreviewCameraBridgeDeps = {
  /** The window that receives the host's replies. */
  readonly window: Pick<Window, "addEventListener" | "removeEventListener">;
  /** The embedding host. */
  readonly parent: { postMessage(message: unknown, targetOrigin: string): void };
  readonly nativeGetUserMedia: GetUserMedia;
  readonly createCanvas: () => BridgeCanvas;
  readonly randomId?: () => string;
  readonly answerTimeoutMs?: number;
};

const hostDeniedErrors = new WeakSet<object>();

/** True for the error a host Deny rejects with, as opposed to a missing or blocked browser camera. */
export function isPreviewCameraDenied(error: unknown): boolean {
  return typeof error === "object" && error !== null && hostDeniedErrors.has(error);
}

type ConsentListener = () => void;
const consentListeners = new Set<ConsentListener>();
let consentPending = false;

function setConsentPending(next: boolean): void {
  if (consentPending === next) return;
  consentPending = next;
  for (const listener of consentListeners) listener();
}

/** True while the host is showing its camera consent; callers should not time out meanwhile. */
export function isPreviewCameraConsentPending(): boolean {
  return consentPending;
}

export function subscribePreviewCameraConsent(listener: ConsentListener): () => void {
  consentListeners.add(listener);
  return () => {
    consentListeners.delete(listener);
  };
}

function wantsBridge(constraints: MediaStreamConstraints | undefined): boolean {
  return !!constraints?.video && !constraints.audio;
}

function deniedError(reason: unknown): DOMException {
  if (reason === "denied") {
    const error = new DOMException("Camera access was blocked in the preview", "NotAllowedError");
    hostDeniedErrors.add(error);
    return error;
  }
  return new DOMException("Camera unavailable in the preview", "NotReadableError");
}

type Session = {
  readonly canvas: BridgeCanvas;
  readonly port: MessagePort;
  readonly tracks: Set<MediaStreamTrack>;
  ended: boolean;
};

/**
 * Build the replacement `getUserMedia` and its `pagehide` cleanup. Exported for
 * tests; the app installs it with `installPreviewCameraBridge`.
 */
export function createPreviewCameraBridge(deps: PreviewCameraBridgeDeps): {
  getUserMedia: GetUserMedia;
  dispose: () => void;
} {
  const randomId = deps.randomId ?? (() => crypto.randomUUID().replace(/-/g, ""));
  let hostAbsent = false;
  let session: Session | null = null;
  let inflight: Promise<Session | null> | null = null;

  const endSession = (ended: Session, notifyHost: boolean): void => {
    if (ended.ended) return;
    ended.ended = true;
    if (session === ended) session = null;
    if (notifyHost) ended.port.postMessage({ type: "stop" });
    ended.port.onmessage = null;
    ended.port.close();
    const tracks = [...ended.tracks];
    ended.tracks.clear();
    for (const track of tracks) {
      track.stop();
      track.dispatchEvent(new Event("ended"));
    }
  };

  const startSession = (port: MessagePort, width: unknown, height: unknown): Session => {
    const canvas = deps.createCanvas();
    canvas.width = typeof width === "number" && width > 0 ? width : DEFAULT_WIDTH;
    canvas.height = typeof height === "number" && height > 0 ? height : DEFAULT_HEIGHT;
    const context = canvas.getContext("2d");
    if (context) {
      context.fillStyle = "#000";
      context.fillRect(0, 0, canvas.width, canvas.height);
    }
    const started: Session = { canvas, port, tracks: new Set(), ended: false };
    port.onmessage = (event: MessageEvent) => {
      const data = event.data as { type?: unknown; bitmap?: Partial<ImageBitmap> } | null;
      if (data?.type === "ended") {
        endSession(started, false);
        return;
      }
      const bitmap = data?.bitmap;
      if (data?.type !== "frame" || typeof bitmap?.close !== "function") return;
      if (typeof bitmap.width !== "number" || typeof bitmap.height !== "number") return;
      if (canvas.width !== bitmap.width || canvas.height !== bitmap.height) {
        canvas.width = bitmap.width;
        canvas.height = bitmap.height;
      }
      context?.drawImage(bitmap as ImageBitmap, 0, 0);
      bitmap.close();
      port.postMessage({ type: "ack" });
    };
    port.start();
    return started;
  };

  const attachTrack = (owner: Session): MediaStream => {
    const stream = owner.canvas.captureStream(CAPTURE_FPS);
    for (const track of stream.getVideoTracks()) {
      const stopTrack = track.stop.bind(track);
      owner.tracks.add(track);
      track.stop = () => {
        stopTrack();
        if (!owner.tracks.delete(track)) return;
        if (owner.tracks.size === 0) endSession(owner, true);
      };
    }
    return stream;
  };

  // Resolves with a live session, rejects with the host's denial, or resolves
  // `null` when no host answered in time.
  const requestHost = (): Promise<Session | null> =>
    new Promise((resolve, reject) => {
      const requestId = randomId();
      let answered = false;
      let settled = false;
      const finish = (): void => {
        settled = true;
        clearTimeout(timer);
        deps.window.removeEventListener("message", onMessage);
        setConsentPending(false);
      };
      const onMessage = (event: MessageEvent): void => {
        if (event.source !== (deps.parent as unknown)) return;
        if (!COWORK_PARENT_ORIGINS.includes(event.origin)) return;
        const data = event.data as Record<string, unknown> | null;
        if (data?.version !== VERSION || data.requestId !== requestId) return;
        if (data.type === PENDING_TYPE) {
          answered = true;
          clearTimeout(timer);
          setConsentPending(true);
          return;
        }
        if (data.type === DENIED_TYPE) {
          finish();
          reject(deniedError(data.reason));
          return;
        }
        if (data.type === GRANTED_TYPE) {
          const port = event.ports[0];
          finish();
          if (!port) {
            reject(deniedError("unavailable"));
            return;
          }
          resolve(startSession(port, data.width, data.height));
        }
      };
      const timer = setTimeout(() => {
        if (answered || settled) return;
        finish();
        resolve(null);
      }, deps.answerTimeoutMs ?? HOST_ANSWER_TIMEOUT_MS);
      deps.window.addEventListener("message", onMessage);
      for (const targetOrigin of COWORK_PARENT_ORIGINS) {
        deps.parent.postMessage({ type: REQUEST_TYPE, version: VERSION, requestId }, targetOrigin);
      }
    });

  const getUserMedia: GetUserMedia = async (constraints) => {
    if (hostAbsent || !wantsBridge(constraints)) return deps.nativeGetUserMedia(constraints);
    if (session && !session.ended) return attachTrack(session);
    if (!inflight) {
      inflight = requestHost()
        .then((started) => {
          if (started) session = started;
          else hostAbsent = true;
          return started;
        })
        .finally(() => {
          inflight = null;
        });
    }
    const owner = await inflight;
    if (!owner) return deps.nativeGetUserMedia(constraints);
    if (owner.ended) throw deniedError("unavailable");
    return attachTrack(owner);
  };

  return {
    getUserMedia,
    dispose: () => {
      if (session) endSession(session, true);
    },
  };
}

/** Route the dev preview's camera through the embedding Cowork host. No-op top-level or without `mediaDevices`. */
export function installPreviewCameraBridge(): void {
  if (window.parent === window) return;
  const mediaDevices = navigator.mediaDevices;
  if (!mediaDevices?.getUserMedia) return;
  const bridge = createPreviewCameraBridge({
    window,
    parent: window.parent,
    nativeGetUserMedia: mediaDevices.getUserMedia.bind(mediaDevices),
    createCanvas: () => document.createElement("canvas"),
  });
  mediaDevices.getUserMedia = bridge.getUserMedia;
  window.addEventListener("pagehide", bridge.dispose);
}
