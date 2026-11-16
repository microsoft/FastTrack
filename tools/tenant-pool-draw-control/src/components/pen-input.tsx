import {
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
} from "react";
import DrawingPad from "signature_pad";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import {
  DEFAULT_PEN_INPUT_MAX_BYTES,
  MAX_PEN_INPUT_DECODED_BYTES,
  MAX_PEN_INPUT_DIMENSION,
  MAX_PEN_INPUT_PIXELS,
  penInputValueFromCanvas,
  validatePenInputValue,
  type PenInputValue,
} from "@/lib/pen-input-value";

export interface PenInputCanvasAttributes {
  id?: string;
  title?: string;
  dir?: "ltr" | "rtl" | "auto";
  lang?: string;
  [dataAttribute: `data-${string}`]:
    | string
    | number
    | boolean
    | undefined;
}

export interface PenInputProps {
  value?: PenInputValue | null;
  onChange: (value: PenInputValue | null) => void;
  onValidityChange?: (isValid: boolean) => void;
  label?: string;
  description?: string;
  required?: boolean;
  disabled?: boolean;
  maxBytes?: number;
  width?: CSSProperties["width"];
  height?: CSSProperties["height"];
  penColor?: string;
  backgroundColor?: string;
  minStrokeWidth?: number;
  maxStrokeWidth?: number;
  borderRadius?: CSSProperties["borderRadius"];
  className?: string;
  canvasClassName?: string;
  canvasStyle?: CSSProperties;
  canvasProps?: PenInputCanvasAttributes;
}

const CANVAS_SIZE_ERROR = `The drawing canvas cannot fit the supported ${MAX_PEN_INPUT_DIMENSION.toLocaleString()}-pixel edge, ${MAX_PEN_INPUT_PIXELS.toLocaleString()}-pixel area, and ${(MAX_PEN_INPUT_DECODED_BYTES / (1024 * 1024)).toLocaleString()} MiB decoded scanline limits. Reduce the drawing area's CSS width or height.`;

const canvasTransforms = new WeakMap<
  HTMLCanvasElement,
  { cssWidth: number; cssHeight: number; scaleX: number; scaleY: number }
>();

function applyCanvasTransform(canvas: HTMLCanvasElement) {
  const transform = canvasTransforms.get(canvas);
  if (!transform) return;
  canvas
    .getContext("2d")
    ?.setTransform(transform.scaleX, 0, 0, transform.scaleY, 0, 0);
}

function clearDrawingPad(
  drawingPad: DrawingPad,
  canvas: HTMLCanvasElement | null,
) {
  const context = canvas?.getContext("2d");
  if (!context) {
    drawingPad.clear();
    return;
  }
  context.save();
  context.setTransform(1, 0, 0, 1, 0, 0);
  drawingPad.clear();
  context.restore();
}

function normalizeCanvasProps(
  canvasProps: PenInputCanvasAttributes | undefined,
): PenInputCanvasAttributes {
  const normalized: PenInputCanvasAttributes = {};
  if (!canvasProps || typeof canvasProps !== "object") return normalized;

  const candidateProps = canvasProps as Record<string, unknown>;
  for (const name of Object.keys(candidateProps)) {
    if (
      (name === "id" ||
        name === "title" ||
        name === "lang") &&
      typeof candidateProps[name] === "string"
    ) {
      normalized[name] = candidateProps[name];
    } else if (
      name === "dir" &&
      (candidateProps[name] === "ltr" ||
        candidateProps[name] === "rtl" ||
        candidateProps[name] === "auto")
    ) {
      normalized.dir = candidateProps[name];
    } else if (
      name.startsWith("data-") &&
      (typeof candidateProps[name] === "string" ||
        typeof candidateProps[name] === "number" ||
        typeof candidateProps[name] === "boolean")
    ) {
      normalized[name as `data-${string}`] = candidateProps[name];
    }
  }

  return normalized;
}

function resizeCanvasBackingStore(
  canvas: HTMLCanvasElement,
): "unchanged" | "resized" | "too_large" {
  const deviceRatio = Number.isFinite(window.devicePixelRatio)
    ? Math.max(window.devicePixelRatio, 1)
    : 1;
  const width = canvas.offsetWidth || canvas.getBoundingClientRect().width;
  const height = canvas.offsetHeight || canvas.getBoundingClientRect().height;
  const dimensionsAt = (ratio: number) => ({
    width: Math.max(1, Math.round(width * ratio)),
    height: Math.max(1, Math.round(height * ratio)),
  });
  const dimensionsAreSupported = ({
    width: candidateWidth,
    height: candidateHeight,
  }: ReturnType<typeof dimensionsAt>) =>
    Number.isFinite(candidateWidth) &&
    Number.isFinite(candidateHeight) &&
    candidateWidth <= MAX_PEN_INPUT_DIMENSION &&
    candidateHeight <= MAX_PEN_INPUT_DIMENSION &&
    candidateWidth * candidateHeight <= MAX_PEN_INPUT_PIXELS &&
    candidateHeight * (candidateWidth * 4 + 1) <=
      MAX_PEN_INPUT_DECODED_BYTES;

  if (!dimensionsAreSupported(dimensionsAt(0))) {
    return "too_large";
  }
  let ratio = deviceRatio;
  if (!dimensionsAreSupported(dimensionsAt(ratio))) {
    let lower = 0;
    const largestCssDimension = Math.max(width, height);
    let upper = Math.min(
      ratio,
      largestCssDimension > 0
        ? MAX_PEN_INPUT_DIMENSION / largestCssDimension + 1
        : 1,
    );
    for (let iteration = 0; iteration < 32; iteration += 1) {
      const candidate = (lower + upper) / 2;
      if (dimensionsAreSupported(dimensionsAt(candidate))) {
        lower = candidate;
      } else {
        upper = candidate;
      }
    }
    ratio = lower;
  }
  const { width: nextWidth, height: nextHeight } = dimensionsAt(ratio);
  const nextTransform = {
    cssWidth: width,
    cssHeight: height,
    scaleX: width > 0 ? nextWidth / width : ratio,
    scaleY: height > 0 ? nextHeight / height : ratio,
  };
  const previousTransform = canvasTransforms.get(canvas);
  const allocationChanged =
    canvas.width !== nextWidth || canvas.height !== nextHeight;

  if (allocationChanged) {
    canvas.width = nextWidth;
    canvas.height = nextHeight;
  }
  canvasTransforms.set(canvas, nextTransform);
  applyCanvasTransform(canvas);
  return allocationChanged ||
    previousTransform?.cssWidth !== width ||
    previousTransform?.cssHeight !== height ||
    previousTransform?.scaleX !== nextTransform.scaleX ||
    previousTransform?.scaleY !== nextTransform.scaleY
    ? "resized"
    : "unchanged";
}

export function PenInput({
  value,
  onChange,
  onValidityChange,
  label = "Pen input",
  description = "Draw using a mouse, touch, or stylus.",
  required = false,
  disabled = false,
  maxBytes = DEFAULT_PEN_INPUT_MAX_BYTES,
  width = "100%",
  height = "14rem",
  penColor = "black",
  backgroundColor = "white",
  minStrokeWidth = 0.5,
  maxStrokeWidth = 2.5,
  borderRadius,
  className,
  canvasClassName,
  canvasStyle,
  canvasProps,
}: PenInputProps) {
  const strokeWidthsAreValid =
    Number.isFinite(minStrokeWidth) &&
    minStrokeWidth > 0 &&
    Number.isFinite(maxStrokeWidth) &&
    maxStrokeWidth >= minStrokeWidth;
  const strokeWidthError = strokeWidthsAreValid
    ? null
    : "Drawing stroke widths must be positive, with the minimum no greater than the maximum.";
  const maxBytesIsValid =
    Number.isFinite(maxBytes) &&
    maxBytes > 0 &&
    maxBytes <= DEFAULT_PEN_INPUT_MAX_BYTES;
  const maxBytesError = maxBytesIsValid
    ? null
    : `The drawing size limit must be a positive number no greater than ${DEFAULT_PEN_INPUT_MAX_BYTES.toLocaleString()} bytes.`;
  const [canvasSizeRejected, setCanvasSizeRejected] = useState(false);
  const [initializationFailed, setInitializationFailed] = useState(false);
  const normalizedCanvasProps = normalizeCanvasProps(canvasProps);
  const drawingDisabled =
    disabled ||
    Boolean(strokeWidthError) ||
    Boolean(maxBytesError) ||
    canvasSizeRejected ||
    initializationFailed;
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const drawingPadRef = useRef<DrawingPad | null>(null);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;
  const onValidityChangeRef = useRef(onValidityChange);
  onValidityChangeRef.current = onValidityChange;
  const lastValidityRef = useRef<boolean | null>(null);
  const controlledValueRef = useRef(value);
  controlledValueRef.current = value;
  const wasControlledRef = useRef(value !== undefined);
  const validatedControlledValueRef = useRef<PenInputValue | null>(null);
  const maxBytesRef = useRef(maxBytes);
  maxBytesRef.current = maxBytes;
  const lastEmittedDataUrlRef = useRef<string | null>(null);
  const lastEmittedValueRef = useRef<PenInputValue | null>(null);
  const controlledLoadRef = useRef(0);
  const restorationLoadRef = useRef<number | null>(null);
  const resizeImageRef = useRef<HTMLImageElement | null>(null);
  const canvasSizeRejectedRef = useRef(false);
  const reconciliationFrameRef = useRef<number | null>(null);
  const hasDrawingRef = useRef(false);
  const drawingDisabledRef = useRef(drawingDisabled);
  drawingDisabledRef.current = drawingDisabled;
  const previousDrawingDisabledRef = useRef(drawingDisabled);
  const strokeInProgressRef = useRef(false);
  const drawingOptionsRef = useRef({
    penColor,
    backgroundColor,
    minWidth: strokeWidthsAreValid ? minStrokeWidth : 0.5,
    maxWidth: strokeWidthsAreValid ? maxStrokeWidth : 2.5,
  });
  drawingOptionsRef.current = {
    penColor,
    backgroundColor,
    minWidth: strokeWidthsAreValid ? minStrokeWidth : 0.5,
    maxWidth: strokeWidthsAreValid ? maxStrokeWidth : 2.5,
  };
  const beginStrokeRef = useRef<(event: Event) => void>(() => {});
  const endStrokeRef = useRef<(event: Event) => void>(() => {});
  const descriptionId = useId();
  const errorId = useId();
  const [hasDrawing, setHasDrawing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const updateHasDrawing = useCallback((nextValue: boolean) => {
    hasDrawingRef.current = nextValue;
    setHasDrawing(nextValue);
  }, []);

  const updateValueValidity = useCallback((isValid: boolean) => {
    if (lastValidityRef.current === isValid) return;
    lastValidityRef.current = isValid;
    onValidityChangeRef.current?.(isValid);
  }, []);

  const loadDrawingImage = useCallback(
    (dataUrl: string, loadVersion: number) => {
      restorationLoadRef.current = loadVersion;
      const image = new Image();
      image.onload = () => {
        if (controlledLoadRef.current !== loadVersion) return;
        restorationLoadRef.current = null;

        const drawingPad = drawingPadRef.current;
        const canvas = canvasRef.current;
        const context = canvas?.getContext("2d");
        if (!drawingPad || !canvas || !context) {
          if (drawingPad) clearDrawingPad(drawingPad, canvas);
          lastEmittedDataUrlRef.current = null;
          lastEmittedValueRef.current = null;
          updateHasDrawing(false);
          updateValueValidity(false);
          setError("The saved drawing could not be displayed.");
          return;
        }

        clearDrawingPad(drawingPad, canvas);
        const ratio = Math.max(window.devicePixelRatio || 1, 1);
        const targetWidth = canvas.offsetWidth || canvas.width / ratio;
        const targetHeight = canvas.offsetHeight || canvas.height / ratio;
        const scale = Math.min(
          targetWidth / image.naturalWidth,
          targetHeight / image.naturalHeight,
        );
        const renderWidth = image.naturalWidth * scale;
        const renderHeight = image.naturalHeight * scale;
        context.drawImage(
          image,
          (targetWidth - renderWidth) / 2,
          (targetHeight - renderHeight) / 2,
          renderWidth,
          renderHeight,
        );
        lastEmittedDataUrlRef.current = dataUrl;
        updateHasDrawing(true);
        updateValueValidity(true);
        if (
          !drawingDisabledRef.current &&
          !canvasSizeRejectedRef.current
        ) {
          drawingPad.on();
        }
      };
      image.onerror = () => {
        if (controlledLoadRef.current !== loadVersion) return;
        restorationLoadRef.current = null;
        const drawingPad = drawingPadRef.current;
        if (drawingPad) clearDrawingPad(drawingPad, canvasRef.current);
        lastEmittedDataUrlRef.current = null;
        lastEmittedValueRef.current = null;
        updateHasDrawing(false);
        updateValueValidity(false);
        setError("The saved drawing could not be displayed.");
        if (
          !drawingDisabledRef.current &&
          !canvasSizeRejectedRef.current
        ) {
          drawingPadRef.current?.on();
        }
      };
      image.src = dataUrl;
      return image;
    },
    [updateHasDrawing, updateValueValidity],
  );

  const reconcileRejectedControlledChange = useCallback(
    (proposedDataUrl: string | null) => {
      if (controlledValueRef.current === undefined) return;
      if (reconciliationFrameRef.current !== null) {
        window.cancelAnimationFrame(reconciliationFrameRef.current);
      }
      reconciliationFrameRef.current = window.requestAnimationFrame(() => {
        reconciliationFrameRef.current = null;
        const retainedValue = controlledValueRef.current;
        if ((retainedValue?.dataUrl ?? null) === proposedDataUrl) return;

        const drawingPad = drawingPadRef.current;
        if (!drawingPad) return;
        drawingPad.off();
        controlledLoadRef.current += 1;
        restorationLoadRef.current = null;
        clearDrawingPad(drawingPad, canvasRef.current);
        lastEmittedDataUrlRef.current = null;
        updateHasDrawing(false);
        setError(null);
        if (!retainedValue) {
          if (
            !drawingDisabledRef.current &&
            !canvasSizeRejectedRef.current
          ) {
            drawingPad.on();
          }
          return;
        }

        try {
          validatePenInputValue(retainedValue, maxBytesRef.current);
          loadDrawingImage(
            retainedValue.dataUrl,
            controlledLoadRef.current,
          );
        } catch (caught) {
          setError(
            caught instanceof Error
              ? caught.message
              : "The saved drawing could not be displayed.",
          );
          if (
            !drawingDisabledRef.current &&
            !canvasSizeRejectedRef.current
          ) {
            drawingPad.on();
          }
        }
      });
    },
    [loadDrawingImage, updateHasDrawing],
  );

  const cancelStroke = useCallback(() => {
    const drawingPad = drawingPadRef.current;
    if (!drawingPad) return;

    strokeInProgressRef.current = false;
    drawingPad.off();
    clearDrawingPad(drawingPad, canvasRef.current);
    updateHasDrawing(false);
    setError(null);
    const controlledValue = controlledValueRef.current;
    const retainedDataUrl =
      controlledValue === undefined
        ? lastEmittedDataUrlRef.current
        : (validatedControlledValueRef.current?.dataUrl ?? null);
    if (!retainedDataUrl) {
      if (
        !drawingDisabledRef.current &&
        !canvasSizeRejectedRef.current
      ) {
        drawingPad.on();
      }
      return;
    }

    const loadVersion = controlledLoadRef.current + 1;
    controlledLoadRef.current = loadVersion;
    loadDrawingImage(retainedDataUrl, loadVersion);
  }, [loadDrawingImage, updateHasDrawing]);

  const synchronizeCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const drawingPad = drawingPadRef.current;
    if (!canvas || !drawingPad) return;
    const resizeResult = resizeCanvasBackingStore(canvas);
    if (resizeResult === "unchanged" && !canvasSizeRejectedRef.current) return;

    const controlledValue = controlledValueRef.current;
    const dataUrl =
      controlledValue === undefined
        ? lastEmittedDataUrlRef.current
        : (validatedControlledValueRef.current?.dataUrl ?? null);
    drawingPad.off();
    clearDrawingPad(drawingPad, canvas);
    strokeInProgressRef.current = false;
    if (resizeResult === "too_large") {
      controlledLoadRef.current += 1;
      restorationLoadRef.current = null;
      updateHasDrawing(Boolean(dataUrl));
      setError(CANVAS_SIZE_ERROR);
      canvasSizeRejectedRef.current = true;
      setCanvasSizeRejected(true);
      return;
    }
    canvasSizeRejectedRef.current = false;
    setCanvasSizeRejected(false);
    setError((current) => (current === CANVAS_SIZE_ERROR ? null : current));
    if (!dataUrl) {
      if (!drawingDisabledRef.current) drawingPad.on();
      updateHasDrawing(false);
      return;
    }
    if (resizeImageRef.current) {
      resizeImageRef.current.onload = null;
      resizeImageRef.current.onerror = null;
    }
    const loadVersion = controlledLoadRef.current + 1;
    controlledLoadRef.current = loadVersion;
    resizeImageRef.current = loadDrawingImage(dataUrl, loadVersion);
  }, [loadDrawingImage, updateHasDrawing]);

  useEffect(
    () => () => {
      if (reconciliationFrameRef.current !== null) {
        window.cancelAnimationFrame(reconciliationFrameRef.current);
      }
    },
    [],
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const resizeResult = resizeCanvasBackingStore(canvas);
    if (!canvas.getContext("2d")) {
      validatedControlledValueRef.current = null;
      lastEmittedDataUrlRef.current = null;
      lastEmittedValueRef.current = null;
      updateHasDrawing(false);
      updateValueValidity(false);
      setInitializationFailed(true);
      setError("The drawing canvas could not be initialized.");
      return;
    }
    let drawingPad: DrawingPad;
    try {
      canvas.getContext("2d")?.setTransform(1, 0, 0, 1, 0, 0);
      drawingPad = new DrawingPad(canvas, drawingOptionsRef.current);
    } catch {
      validatedControlledValueRef.current = null;
      lastEmittedDataUrlRef.current = null;
      lastEmittedValueRef.current = null;
      updateHasDrawing(false);
      updateValueValidity(false);
      setInitializationFailed(true);
      setError("The drawing canvas could not be initialized.");
      return;
    }
    setInitializationFailed(false);
    drawingPadRef.current = drawingPad;
    applyCanvasTransform(canvas);
    const handleBeginStroke = (event: Event) => beginStrokeRef.current(event);
    const handleEndStroke = (event: Event) => endStrokeRef.current(event);
    drawingPad.addEventListener("beginStroke", handleBeginStroke);
    drawingPad.addEventListener("endStroke", handleEndStroke);
    if (resizeResult === "too_large") {
      canvasSizeRejectedRef.current = true;
      setCanvasSizeRejected(true);
      setError(CANVAS_SIZE_ERROR);
    }
    if (drawingDisabledRef.current || resizeResult === "too_large") {
      drawingPad.off();
    }

    return () => {
      drawingPad.removeEventListener("beginStroke", handleBeginStroke);
      drawingPad.removeEventListener("endStroke", handleEndStroke);
      drawingPad.off();
      if (drawingPadRef.current === drawingPad) {
        drawingPadRef.current = null;
      }
    };
  }, [updateHasDrawing, updateValueValidity]);

  useEffect(() => {
    if (previousDrawingDisabledRef.current === drawingDisabled) return;
    previousDrawingDisabledRef.current = drawingDisabled;
    const drawingPad = drawingPadRef.current;
    if (!drawingPad) return;

    if (drawingDisabled) {
      if (strokeInProgressRef.current) cancelStroke();
      drawingPad.off();
    } else if (!canvasSizeRejectedRef.current) {
      drawingPad.on();
    }
  }, [cancelStroke, drawingDisabled]);

  useEffect(() => {
    const drawingPad = drawingPadRef.current;
    if (!drawingPad) return;
    const backgroundChanged = drawingPad.backgroundColor !== backgroundColor;
    drawingPad.penColor = penColor;
    drawingPad.backgroundColor = backgroundColor;
    drawingPad.minWidth = strokeWidthsAreValid ? minStrokeWidth : 0.5;
    drawingPad.maxWidth = strokeWidthsAreValid ? maxStrokeWidth : 2.5;
    if (
      backgroundChanged &&
      drawingPad.isEmpty() &&
      !hasDrawingRef.current
    ) {
      clearDrawingPad(drawingPad, canvasRef.current);
    }
  }, [
    backgroundColor,
    maxStrokeWidth,
    minStrokeWidth,
    penColor,
    strokeWidthsAreValid,
  ]);

  useEffect(() => {
    const drawingPad = drawingPadRef.current;
    const nextDataUrl = value?.dataUrl ?? null;
    if (!drawingPad) {
      return;
    }
    const wasControlled = wasControlledRef.current;
    wasControlledRef.current = value !== undefined;
    if (value === undefined) {
      updateValueValidity(true);
      if (wasControlled) {
        controlledLoadRef.current += 1;
        restorationLoadRef.current = null;
        if (resizeImageRef.current) {
          resizeImageRef.current.onload = null;
          resizeImageRef.current.onerror = null;
          resizeImageRef.current = null;
        }
        if (
          !drawingDisabledRef.current &&
          !canvasSizeRejectedRef.current
        ) {
          drawingPad.on();
        }
      }
      return;
    }
    if (!maxBytesIsValid) {
      updateValueValidity(!value);
      drawingPad.off();
      if (!value) {
        controlledLoadRef.current += 1;
        restorationLoadRef.current = null;
        validatedControlledValueRef.current = null;
        lastEmittedDataUrlRef.current = null;
        lastEmittedValueRef.current = null;
        clearDrawingPad(drawingPad, canvasRef.current);
        updateHasDrawing(false);
      }
      return;
    }
    const interruptedStroke = strokeInProgressRef.current;
    if (interruptedStroke) {
      strokeInProgressRef.current = false;
      drawingPad.off();
    }
    lastEmittedValueRef.current = null;

    if (value) {
      try {
        validatePenInputValue(value, maxBytes);
        validatedControlledValueRef.current = value;
      } catch (caught) {
        controlledLoadRef.current += 1;
        restorationLoadRef.current = null;
        if (resizeImageRef.current) {
          resizeImageRef.current.onload = null;
          resizeImageRef.current.onerror = null;
          resizeImageRef.current = null;
        }
        drawingPad.off();
        clearDrawingPad(drawingPad, canvasRef.current);
        validatedControlledValueRef.current = null;
        lastEmittedDataUrlRef.current = null;
        updateHasDrawing(false);
        updateValueValidity(false);
        setError(
          caught instanceof Error
            ? caught.message
            : "The saved drawing could not be displayed.",
        );
        return;
      }
    } else {
      validatedControlledValueRef.current = null;
      updateValueValidity(true);
    }

    if (canvasSizeRejectedRef.current) {
      drawingPad.off();
      updateHasDrawing(Boolean(value));
      updateValueValidity(!value);
      setError(CANVAS_SIZE_ERROR);
      return;
    }

    if (
      value &&
      nextDataUrl === lastEmittedDataUrlRef.current &&
      !interruptedStroke
    ) {
      updateHasDrawing(true);
      updateValueValidity(true);
      if (
        !drawingDisabledRef.current &&
        !canvasSizeRejectedRef.current
      ) {
        drawingPad.on();
      }
      setError(null);
      return;
    }

    if (value) updateValueValidity(false);
    const supersededRestorationLoad = restorationLoadRef.current;
    const loadVersion = controlledLoadRef.current + 1;
    controlledLoadRef.current = loadVersion;
    drawingPad.off();
    if (resizeImageRef.current) {
      resizeImageRef.current.onload = null;
      resizeImageRef.current.onerror = null;
      resizeImageRef.current = null;
    }
    lastEmittedDataUrlRef.current = null;
    clearDrawingPad(drawingPad, canvasRef.current);
    updateHasDrawing(false);
    setError(null);

    if (!value) {
      if (
        supersededRestorationLoad !== null &&
        restorationLoadRef.current === supersededRestorationLoad
      ) {
        restorationLoadRef.current = null;
      }
      if (!drawingDisabledRef.current) drawingPad.on();
      return;
    }

    const image = loadDrawingImage(value.dataUrl, loadVersion);

    return () => {
      image.onload = null;
      image.onerror = null;
      if (controlledLoadRef.current === loadVersion) {
        controlledLoadRef.current += 1;
        restorationLoadRef.current = null;
      }
    };
  }, [
    loadDrawingImage,
    maxBytes,
    maxBytesIsValid,
    updateHasDrawing,
    updateValueValidity,
    value,
  ]);

  useEffect(() => {
    if (value !== undefined || !lastEmittedValueRef.current) return;
    if (!maxBytesIsValid) return;
    try {
      validatePenInputValue(lastEmittedValueRef.current, maxBytes);
    } catch (caught) {
      controlledLoadRef.current += 1;
      restorationLoadRef.current = null;
      const drawingPad = drawingPadRef.current;
      if (drawingPad) clearDrawingPad(drawingPad, canvasRef.current);
      lastEmittedDataUrlRef.current = null;
      lastEmittedValueRef.current = null;
      updateHasDrawing(false);
      setError(
        caught instanceof Error
          ? caught.message
          : "The drawing could not be prepared. Clear it and try again.",
      );
      onChangeRef.current(null);
    }
  }, [maxBytes, maxBytesIsValid, updateHasDrawing, value]);

  useEffect(() => {
    window.addEventListener("resize", synchronizeCanvas);
    const observer =
      typeof window.ResizeObserver === "undefined"
        ? null
        : new window.ResizeObserver(synchronizeCanvas);
    if (canvasRef.current) observer?.observe(canvasRef.current);
    return () => {
      window.removeEventListener("resize", synchronizeCanvas);
      observer?.disconnect();
      controlledLoadRef.current += 1;
      restorationLoadRef.current = null;
      if (resizeImageRef.current) {
        resizeImageRef.current.onload = null;
        resizeImageRef.current.onerror = null;
        resizeImageRef.current = null;
      }
    };
  }, [synchronizeCanvas]);

  useEffect(() => {
    synchronizeCanvas();
  }, [height, synchronizeCanvas, width]);

  useEffect(() => {
    if (!drawingDisabled) {
      synchronizeCanvas();
    }
  }, [drawingDisabled, synchronizeCanvas]);

  const emitDrawing = () => {
    const drawingPad = drawingPadRef.current;
    const canvas = canvasRef.current;
    if (
      !drawingPad ||
      !canvas ||
      drawingPad.isEmpty()
    ) {
      updateHasDrawing(Boolean(lastEmittedDataUrlRef.current));
      return;
    }

    let nextValue: PenInputValue;
    try {
      nextValue = penInputValueFromCanvas(canvas, maxBytes);
      lastEmittedDataUrlRef.current = nextValue.dataUrl;
      lastEmittedValueRef.current = nextValue;
      updateHasDrawing(true);
      setError(null);
    } catch (caught) {
      const message =
        caught instanceof Error
          ? caught.message
          : "The drawing could not be prepared. Clear it and try again.";
      cancelStroke();
      setError(message);
      return;
    }
    try {
      onChange(nextValue);
    } finally {
      reconcileRejectedControlledChange(nextValue.dataUrl);
    }
  };

  const clear = () => {
    controlledLoadRef.current += 1;
    restorationLoadRef.current = null;
    const drawingPad = drawingPadRef.current;
    if (drawingPad) clearDrawingPad(drawingPad, canvasRef.current);
    lastEmittedDataUrlRef.current = null;
    lastEmittedValueRef.current = null;
    updateHasDrawing(false);
    setError(null);
    if (
      !drawingDisabledRef.current &&
      !canvasSizeRejectedRef.current
    ) {
      drawingPadRef.current?.on();
    }
    try {
      onChange(null);
    } finally {
      reconcileRejectedControlledChange(null);
    }
  };

  const displayedError = strokeWidthError ?? maxBytesError ?? error;
  const describedBy = displayedError
    ? `${descriptionId} ${errorId}`
    : descriptionId;
  beginStrokeRef.current = (event) => {
    if (restorationLoadRef.current !== null) {
      event.preventDefault();
      return;
    }
    if (drawingDisabledRef.current) {
      event.preventDefault();
      return;
    }
    strokeInProgressRef.current = true;
    controlledLoadRef.current += 1;
    updateHasDrawing(true);
    setError(null);
  };
  endStrokeRef.current = (event) => {
    if (drawingDisabledRef.current) {
      cancelStroke();
      return;
    }
    strokeInProgressRef.current = false;
    const detail: unknown =
      event instanceof CustomEvent ? event.detail : undefined;
    const sourceType =
      detail !== null &&
      typeof detail === "object" &&
      "event" in detail &&
      detail.event !== null &&
      typeof detail.event === "object" &&
      "type" in detail.event &&
      typeof detail.event.type === "string"
        ? detail.event.type
        : null;
    if (sourceType === "pointercancel" || sourceType === "touchcancel") {
      cancelStroke();
      return;
    }
    emitDrawing();
  };

  return (
    <fieldset
      className={cn("space-y-3", className)}
      disabled={drawingDisabled}
      aria-invalid={displayedError ? "true" : undefined}
      style={{ width }}
    >
      <legend className="text-sm font-medium">
        {label}
        {required && (
          <span className="ml-1 text-destructive" aria-hidden="true">
            *
          </span>
        )}
      </legend>
      <p id={descriptionId} className="text-sm text-muted-foreground">
        {description}
        {required && <span className="sr-only"> Required.</span>}
      </p>

      <div
        role="group"
        aria-label={label}
        aria-disabled={drawingDisabled || undefined}
        className={cn(
          "overflow-hidden rounded-lg border bg-background shadow-xs",
          "focus-within:outline-solid focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-ring",
          drawingDisabled && "opacity-50",
          displayedError && "border-destructive",
        )}
        style={{ borderRadius }}
      >
        <canvas
          {...normalizedCanvasProps}
          ref={canvasRef}
          role="img"
          aria-label={label}
          aria-describedby={describedBy}
          aria-disabled={drawingDisabled || undefined}
          className={cn(
            "block w-full touch-none bg-background",
            canvasClassName,
          )}
          style={{
            ...canvasStyle,
            height,
            backgroundColor,
            borderRadius,
          }}
        />
      </div>

      <div className="flex min-h-9 items-center justify-between gap-3">
        <p className="text-sm text-muted-foreground" aria-live="polite">
          {hasDrawing ? "Drawing captured." : "No drawing captured."}
        </p>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={clear}
          disabled={drawingDisabled || (!hasDrawing && !value)}
        >
          Clear drawing
        </Button>
      </div>

      {displayedError && (
        <p id={errorId} role="alert" className="text-sm text-destructive">
          {displayedError}
        </p>
      )}
    </fieldset>
  );
}
