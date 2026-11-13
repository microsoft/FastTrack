// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import { useEffect, useRef, useState, type KeyboardEvent } from "react";
import { toast } from "sonner";

import { LoadingState } from "@/components/states";
import {
  assertNoCompressedExtensions,
  createModelStage,
  detectModelFormat,
  ModelLoadError,
  modelErrorMessage,
  readModelSource,
  sameModelSource,
  snapshotModelSource,
  viewCommandForKey,
  type ModelErrorCode,
  type ModelFormat,
  type ModelSource,
  type ModelStage,
  type ModelStats,
} from "@/lib/model-load";
import { cn } from "@/lib/utils";

export type { ModelFormat, ModelSource, ModelStats } from "@/lib/model-load";
export { MAX_MODEL_BYTES, MODEL_FORMATS, ModelLoadError } from "@/lib/model-load";

export interface ModelViewerProps {
  /**
   * A File, bytes, or an https URL to a .glb, .gltf, .obj or .stl model. A
   * new byte object with the same accepted-size content does not reload the
   * model; File and Blob objects reload unless their identity is unchanged.
   */
  source: ModelSource | null | undefined;
  /** Forces this loader for every source, skipping detection; set it only for nameless bytes. */
  format?: ModelFormat;
  className?: string;
  canvasClassName?: string;
  /** Draws every material as a wireframe. */
  wireframe?: boolean;
  /**
   * Hex, `rgb()`, `hsl()` or named CSS colour for OBJ and STL meshes that
   * carry no vertex colours (`oklch()` and `var()` are not parsed). GLB and
   * glTF keep their own materials; prefer GLB when the model has colours or
   * textures.
   */
  color?: string;
  /** Slowly spins the camera around the model until the user interacts with it. */
  autoRotate?: boolean;
  /**
   * With no `source`, shows a coloured sample model (a toy car) labelled
   * "Sample model" instead of an empty canvas. Defaults to true; pass false
   * for an empty canvas.
   */
  sample?: boolean;
  /** Called after a model is on screen, with its mesh and triangle counts and its bounding-box size. */
  onLoad?: (result: ModelStats) => void;
  /** Called when a model cannot be shown. The viewer never throws. */
  onError?: (error: ModelLoadError) => void;
}

type Status = "idle" | "loading" | "ready" | "error";

function toModelError(error: unknown): ModelLoadError {
  if (error instanceof ModelLoadError) return error;
  return new ModelLoadError("viewer-load-failed", "viewer could not render the model", {
    cause: error,
  });
}

interface StageHolder {
  canvas: HTMLCanvasElement;
  promise: Promise<ModelStage> | null;
  /** Brings a newly created stage up to the current props and canvas size. */
  configure: (stage: ModelStage) => void;
}

type StableSource = {
  source: ModelViewerProps["source"];
  /** What the shown version was loaded from, copied when it is bytes. */
  loaded: ModelViewerProps["source"];
  version: number;
  equalErrorRetryConsumed: boolean;
};

/**
 * Returns the holder's stage, creating it when there is none yet or when
 * the last attempt failed, so a transient failure (a lost WebGL context, a
 * chunk that did not download) is retried by the next model. Every stage it
 * creates, a retried one included, is configured before anyone uses it.
 */
function acquireStage(holder: StageHolder): Promise<ModelStage> {
  if (holder.promise) return holder.promise;
  const promise = createModelStage(holder.canvas).then((stage) => {
    holder.configure(stage);
    return stage;
  });
  holder.promise = promise;
  promise.catch(() => {
    if (holder.promise === promise) holder.promise = null;
  });
  return promise;
}

/** Runs an app callback; a throw or a rejected promise from it is logged, never propagated. */
function safely(callback: () => unknown): void {
  const report = (error: unknown) => console.error("ModelViewer: callback threw", error);
  try {
    const returned = callback();
    if (returned instanceof Promise) returned.catch(report);
  } catch (error) {
    report(error);
  }
}

/**
 * Shows a 3D model with orbit (drag or arrow keys), zoom (wheel, pinch or
 * `+`/`-`) and pan (right-drag / two-finger drag). The model is framed
 * automatically; OBJ
 * and STL meshes keep their vertex colours or get a blue default material
 * (`color` overrides it); GLB and glTF keep their own materials. With no
 * `source` it shows a coloured sample model until one is given.
 */
export function ModelViewer({
  source: sourceProp,
  format,
  className,
  canvasClassName,
  wireframe = false,
  autoRotate = false,
  color,
  sample = true,
  onLoad,
  onError,
}: ModelViewerProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const holderRef = useRef<StageHolder | null>(null);
  const generationRef = useRef(0);
  const mountedRef = useRef(true);
  const onLoadRef = useRef(onLoad);
  const onErrorRef = useRef(onError);
  onLoadRef.current = onLoad;
  onErrorRef.current = onError;
  const displayRef = useRef({ wireframe, autoRotate, color });
  displayRef.current = { wireframe, autoRotate, color };

  const [status, setStatus] = useState<Status>("idle");
  const [errorCode, setErrorCode] = useState<ModelErrorCode | null>(null);
  const [showingSample, setShowingSample] = useState(false);
  // The load effect keys on the version, not on the prop's identity, so an
  // inline `new Uint8Array(...)` re-created on every render loads once.
  const [stableSource, setStableSource] = useState<StableSource>(() => ({
    source: sourceProp,
    loaded: snapshotModelSource(sourceProp),
    version: 0,
    equalErrorRetryConsumed: false,
  }));
  if (stableSource.source !== sourceProp) {
    const equalToLoaded = sameModelSource(stableSource.loaded, sourceProp);
    const consumeEqualErrorRetry = equalToLoaded && status === "error" && !stableSource.equalErrorRetryConsumed;
    setStableSource(
      equalToLoaded && !consumeEqualErrorRetry
        ? { ...stableSource, source: sourceProp }
        : {
            source: sourceProp,
            loaded: snapshotModelSource(sourceProp),
            version: stableSource.version + 1,
            equalErrorRetryConsumed: consumeEqualErrorRetry,
          },
    );
  }
  const source = stableSource.source;
  const sourceVersion = stableSource.version;
  // The load reads the snapshot the comparison uses, so a caller rewriting
  // its buffer mid-load cannot change the accepted-size bytes being parsed.
  const loadedRef = useRef(stableSource.loaded);
  loadedRef.current = stableSource.loaded;

  // One renderer per mounted canvas.
  useEffect(() => {
    mountedRef.current = true;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const holder: StageHolder = {
      canvas,
      promise: null,
      configure: (stage) => {
        stage.setColor(displayRef.current.color);
        stage.setWireframe(displayRef.current.wireframe);
        stage.setAutoRotate(displayRef.current.autoRotate);
        stage.resize();
      },
    };
    holderRef.current = holder;
    // Start creating the stage now; failures surface through the load effect.
    acquireStage(holder).catch(() => undefined);

    const observer =
      typeof ResizeObserver === "undefined"
        ? null
        : new ResizeObserver(() => {
            void holder.promise?.then((stage) => stage.resize()).catch(() => undefined);
          });
    observer?.observe(canvas);

    return () => {
      mountedRef.current = false;
      generationRef.current += 1;
      observer?.disconnect();
      holderRef.current = null;
      const pending = holder.promise;
      holder.promise = null;
      void pending?.then((stage) => stage.dispose()).catch(() => undefined);
    };
  }, []);

  useEffect(() => {
    void holderRef.current?.promise
      ?.then((stage) => {
        stage.setWireframe(wireframe);
        stage.setAutoRotate(autoRotate);
      })
      .catch(() => undefined);
  }, [wireframe, autoRotate]);

  useEffect(() => {
    void holderRef.current?.promise?.then((stage) => stage.setColor(color)).catch(() => undefined);
  }, [color]);

  // `sample` only matters with no source, so toggling it never reloads a real model.
  const hasSource =
    source !== null && source !== undefined && (typeof source !== "string" || source.trim() !== "");
  const sampleWanted = !hasSource && sample;

  useEffect(() => {
    const generation = ++generationRef.current;
    const sourceForLoad = loadedRef.current;
    const isCurrent = () => mountedRef.current && generationRef.current === generation;
    const controller = new AbortController();
    const holder = holderRef.current;
    const clearStage = () => {
      void holder?.promise?.then((stage) => stage.clear()).catch(() => undefined);
    };
    const fail = (error: unknown) => {
      if (!isCurrent() || controller.signal.aborted) return;
      const modelError = toModelError(error);
      clearStage();
      // An expected failure (a bad file or link, no WebGL) is not an app bug;
      // a viewer that could not load or render is, so it goes to console.error.
      if (modelError.code === "viewer-load-failed") {
        console.error(`ModelViewer: ${modelError.code}`, error);
      } else {
        console.warn(`ModelViewer: ${modelError.code}`, error);
      }
      setShowingSample(false);
      setStatus("error");
      setErrorCode(modelError.code);
      toast.error(modelErrorMessage(modelError.code), { id: "model-viewer-error" });
      safely(() => onErrorRef.current?.(modelError));
    };

    clearStage();
    setShowingSample(false);
    if (!hasSource) {
      setStatus("idle");
      setErrorCode(null);
      if (sampleWanted && holder) {
        void (async () => {
          try {
            const shown = await (await acquireStage(holder)).showSample(isCurrent);
            if (shown !== null && isCurrent()) setShowingSample(true);
          } catch (error) {
            fail(error);
          }
        })();
      }
      return () => controller.abort();
    }

    setStatus("loading");
    setErrorCode(null);

    void (async () => {
      let result: ModelStats | null;
      try {
        if (!holder) {
          throw new ModelLoadError("webgl-unavailable", "no canvas to draw on");
        }
        if (
          sourceForLoad === null ||
          sourceForLoad === undefined ||
          (typeof sourceForLoad === "string" && sourceForLoad.trim() === "")
        ) {
          return;
        }
        const { bytes, name } = await readModelSource(sourceForLoad, controller.signal);
        if (!isCurrent()) return;
        const resolved = format ?? detectModelFormat(name, bytes);
        if (!resolved) {
          throw new ModelLoadError("unsupported-format", "model format not recognised");
        }
        assertNoCompressedExtensions(bytes, resolved);
        const stage = await acquireStage(holder);
        if (!isCurrent()) return;
        result = await stage.show(bytes, resolved, isCurrent);
        if (result === null || !isCurrent()) return;
      } catch (error) {
        fail(error);
        return;
      }
      setStatus("ready");
      const loaded = result;
      safely(() => onLoadRef.current?.(loaded));
    })();

    return () => controller.abort();
  }, [sourceVersion, format, hasSource, sampleWanted]);

  const instructions = "Drag or use the arrow keys to rotate; scroll or press + and - to zoom.";
  const message =
    status === "loading"
      ? "Loading 3D model…"
      : status === "ready"
        ? `3D model loaded. ${instructions}`
        : status === "error" && errorCode
          ? modelErrorMessage(errorCode)
          : showingSample
            ? `Sample 3D model shown. ${instructions}`
            : "";

  const onCanvasKeyDown = (event: KeyboardEvent<HTMLCanvasElement>) => {
    if (event.altKey || event.ctrlKey || event.metaKey) return;
    const command = viewCommandForKey(event.key);
    if (!command) return;
    event.preventDefault();
    void holderRef.current?.promise?.then((stage) => stage.nudge(command)).catch(() => undefined);
  };

  return (
    <div
      className={cn(
        "relative aspect-square w-full overflow-hidden rounded-lg border bg-muted/30",
        className,
      )}
      data-slot="model-viewer"
      data-status={status}
      data-sample={showingSample ? "" : undefined}
    >
      <canvas
        ref={canvasRef}
        className={cn(
          "block size-full touch-none outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset",
          canvasClassName,
        )}
        aria-label="3D model viewer"
        aria-keyshortcuts="ArrowLeft ArrowRight ArrowUp ArrowDown + -"
        role="application"
        tabIndex={0}
        onKeyDown={onCanvasKeyDown}
      />
      {showingSample ? (
        <span className="pointer-events-none absolute left-2 top-2 rounded bg-background/80 px-2 py-0.5 text-xs text-muted-foreground">
          Sample model
        </span>
      ) : null}
      {status === "loading" ? (
        <div className="absolute inset-0 flex items-center justify-center bg-background/60">
          <LoadingState rows={1} className="w-1/2" />
        </div>
      ) : null}
      {status === "error" && errorCode ? (
        <div className="absolute inset-0 flex items-center justify-center p-4 text-center text-sm text-muted-foreground">
          {modelErrorMessage(errorCode)}
        </div>
      ) : null}
      <span className="sr-only" aria-live="polite">
        {message}
      </span>
    </div>
  );
}
