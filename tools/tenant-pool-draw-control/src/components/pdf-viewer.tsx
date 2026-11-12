import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { getDocumentProxy } from "unpdf";

import { decodePdfBytes, type PdfBytesFailure } from "@/lib/pdf-bytes";

export interface PdfLoadResult {
  success: boolean;
  data: unknown;
  error?: unknown;
}

export type PdfLoader = () => Promise<PdfLoadResult>;

export type PdfViewerOutcome =
  | "loaded"
  | "load_failed"
  | "open_failed"
  | "render_error"
  | PdfBytesFailure;

export interface PdfViewerProps {
  /** Fetches the PDF through the user's connection; called once per load or retry. */
  loadPdf: PdfLoader;
  /** Accessible name for the document region, e.g. the file name. */
  title: string;
  initialPage?: number;
  onPageChange?: (page: number, pageCount: number) => void;
  onOutcome?: (outcome: PdfViewerOutcome, detail?: unknown) => void;
  onUnavailable?: (outcome: Exclude<PdfViewerOutcome, "loaded">) => void;
}

const MIN_ZOOM = 0.5;
const MAX_ZOOM = 3;
const ZOOM_STEP = 0.25;
const MAX_CANVAS_PIXELS = 16_777_216;

type PdfDocument = Awaited<ReturnType<typeof getDocumentProxy>>;

type ViewerState =
  | { status: "loading" }
  | { status: "ready"; pageCount: number }
  | { status: "unavailable"; outcome: Exclude<PdfViewerOutcome, "loaded"> };

const UNAVAILABLE_COPY: Record<Exclude<PdfViewerOutcome, "loaded">, string> = {
  load_failed: "The PDF could not be loaded.",
  open_failed: "This file could not be opened as a PDF.",
  render_error: "This page could not be displayed.",
  empty: "The PDF file is empty.",
  invalid_signature: "This file is not a PDF.",
  oversized: "This PDF is too large to display here.",
  text_decoded: "The PDF arrived as text and could not be read.",
  unsupported_shape: "The PDF could not be read from the connection's response.",
};

function notify(callback: () => void): void {
  try {
    callback();
  } catch (error) {
    console.error("PdfViewer callback failed", error);
  }
}

function clampPage(page: number | undefined, pageCount: number): number {
  if (page === undefined || !Number.isFinite(page)) return 1;
  return Math.min(Math.max(1, Math.trunc(page)), Math.max(1, pageCount));
}

export function PdfViewer(props: PdfViewerProps) {
  const committedProps = useRef(props);
  useLayoutEffect(() => {
    committedProps.current = props;
  });

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const documentRef = useRef<PdfDocument | null>(null);
  const attemptRef = useRef({ outcomeReported: false, failureReported: false, reportedPage: 0 });
  const [reloadToken, setReloadToken] = useState(0);
  const [state, setState] = useState<ViewerState>({ status: "loading" });
  const [page, setPage] = useState(1);
  const [zoom, setZoom] = useState(1);
  const [containerWidth, setContainerWidth] = useState(0);

  const releaseDocument = useCallback(() => {
    const pdf = documentRef.current;
    documentRef.current = null;
    if (pdf) void pdf.destroy();
  }, []);

  // Per load attempt: `loaded` at most once, after the first page renders,
  // and the first failure at most once, even when it follows `loaded` (a
  // later page that fails to render still ends the attempt).
  const markUnavailable = useCallback(
    (outcome: Exclude<PdfViewerOutcome, "loaded">, detail?: unknown) => {
    releaseDocument();
    setState({ status: "unavailable", outcome });
    if (attemptRef.current.failureReported) return;
    attemptRef.current.failureReported = true;
    attemptRef.current.outcomeReported = true;
    notify(() => committedProps.current.onOutcome?.(outcome, detail));
    notify(() => committedProps.current.onUnavailable?.(outcome));
    },
    [releaseDocument],
  );

  useEffect(() => {
    let cancelled = false;
    attemptRef.current = { outcomeReported: false, failureReported: false, reportedPage: 0 };
    setState({ status: "loading" });

    const open = async () => {
      let result: PdfLoadResult;
      try {
        result = await committedProps.current.loadPdf();
      } catch (error) {
        if (!cancelled) markUnavailable("load_failed", error);
        return;
      }
      if (cancelled) return;
      if (result === null || typeof result !== "object" || !result.success) {
        markUnavailable("load_failed", result?.error);
        return;
      }
      const decoded = decodePdfBytes(result.data);
      if (!decoded.ok) {
        markUnavailable(decoded.reason);
        return;
      }
      let pdf: PdfDocument;
      try {
        pdf = await getDocumentProxy(decoded.bytes, { isEvalSupported: false });
      } catch (error) {
        if (!cancelled) markUnavailable("open_failed", error);
        return;
      }
      if (cancelled) {
        void pdf.destroy();
        return;
      }
      documentRef.current = pdf;
      setPage(clampPage(committedProps.current.initialPage, pdf.numPages));
      setState({ status: "ready", pageCount: pdf.numPages });
    };

    open().catch((error: unknown) => {
      if (!cancelled) markUnavailable("open_failed", error);
    });
    return () => {
      cancelled = true;
      releaseDocument();
    };
  }, [reloadToken, markUnavailable, releaseDocument]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    setContainerWidth(container.clientWidth);
    if (typeof window.ResizeObserver === "undefined") return;
    const observer = new window.ResizeObserver((entries) => {
      const width = entries[0]?.contentRect.width ?? 0;
      setContainerWidth(Math.floor(width));
    });
    observer.observe(container);
    return () => observer.disconnect();
  }, []);

  const pageCount = state.status === "ready" ? state.pageCount : 0;

  useEffect(() => {
    if (state.status !== "ready") return;
    const pdf = documentRef.current;
    const canvas = canvasRef.current;
    if (!pdf || !canvas) return;

    let cancelled = false;
    let task: { cancel: () => void; promise: Promise<unknown> } | null = null;

    const render = async () => {
      try {
        const pdfPage = await pdf.getPage(page);
        if (cancelled) return;
        const natural = pdfPage.getViewport({ scale: 1 });
        const fitScale =
          containerWidth > 0 ? Math.max(0.1, (containerWidth - 32) / natural.width) : 1;
        // The displayed size follows the zoom; only the backing-store
        // resolution is capped, so a capped page renders softer, not smaller.
        const cssScale = fitScale * zoom;
        let renderScale = cssScale * Math.min(window.devicePixelRatio || 1, 2);
        const area = natural.width * natural.height * renderScale * renderScale;
        if (area > MAX_CANVAS_PIXELS) {
          renderScale *= Math.sqrt(MAX_CANVAS_PIXELS / area);
        }
        const viewport = pdfPage.getViewport({ scale: renderScale });
        canvas.width = Math.floor(viewport.width);
        canvas.height = Math.floor(viewport.height);
        canvas.style.width = `${Math.floor(natural.width * cssScale)}px`;
        canvas.style.height = `${Math.floor(natural.height * cssScale)}px`;
        task = pdfPage.render({ canvas, viewport });
        await task.promise;
        if (cancelled) return;
        const attempt = attemptRef.current;
        if (!attempt.outcomeReported) {
          attempt.outcomeReported = true;
          notify(() => committedProps.current.onOutcome?.("loaded"));
        }
        if (attempt.reportedPage !== page) {
          attempt.reportedPage = page;
          notify(() => committedProps.current.onPageChange?.(page, pdf.numPages));
        }
      } catch (error) {
        if (cancelled) return;
        if (error instanceof Error && error.name === "RenderingCancelledException") return;
        markUnavailable("render_error", error);
      }
    };

    void render();
    return () => {
      cancelled = true;
      task?.cancel();
    };
  }, [state.status, page, zoom, containerWidth, markUnavailable]);

  const unavailable = state.status === "unavailable";
  const loading = state.status === "loading";

  return (
    <div className="flex w-full flex-col gap-2">
      <div
        className="flex flex-wrap items-center justify-between gap-2"
        role="toolbar"
        aria-label={`${props.title} controls`}
      >
        <div className="flex items-center gap-2">
          <button
            type="button"
            className="rounded-md border px-3 py-1 text-sm disabled:opacity-50"
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            disabled={state.status !== "ready" || page <= 1}
          >
            Previous
          </button>
          <span className="text-sm tabular-nums" aria-live="polite">
            {state.status === "ready" ? `Page ${page} of ${pageCount}` : "Page –"}
          </span>
          <button
            type="button"
            className="rounded-md border px-3 py-1 text-sm disabled:opacity-50"
            onClick={() => setPage((current) => Math.min(pageCount, current + 1))}
            disabled={state.status !== "ready" || page >= pageCount}
          >
            Next
          </button>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            className="rounded-md border px-3 py-1 text-sm disabled:opacity-50"
            aria-label="Zoom out"
            onClick={() => setZoom((current) => Math.max(MIN_ZOOM, current - ZOOM_STEP))}
            disabled={state.status !== "ready" || zoom <= MIN_ZOOM}
          >
            −
          </button>
          <span className="w-12 text-center text-sm tabular-nums">
            {Math.round(zoom * 100)}%
          </span>
          <button
            type="button"
            className="rounded-md border px-3 py-1 text-sm disabled:opacity-50"
            aria-label="Zoom in"
            onClick={() => setZoom((current) => Math.min(MAX_ZOOM, current + ZOOM_STEP))}
            disabled={state.status !== "ready" || zoom >= MAX_ZOOM}
          >
            +
          </button>
        </div>
      </div>
      <div
        ref={containerRef}
        className="relative isolate h-[70dvh] min-h-[28rem] w-full overflow-auto rounded-md bg-muted"
      >
        <div
          role="region"
          aria-label={props.title}
          aria-hidden={unavailable || loading ? true : undefined}
          inert={unavailable || loading ? true : undefined}
          className="flex min-h-full w-max min-w-full justify-center p-4"
        >
          <canvas
            ref={canvasRef}
            role="img"
            aria-label={
              state.status === "ready"
                ? `${props.title}, page ${page} of ${pageCount}`
                : props.title
            }
            className="bg-white shadow-sm"
          />
        </div>
        {(loading || unavailable) && (
          <div
            role="status"
            className="absolute inset-0 z-10 flex items-center justify-center bg-background/90 p-6 text-center text-sm text-muted-foreground"
          >
            {loading ? (
              "Loading PDF…"
            ) : (
              <span>
                {UNAVAILABLE_COPY[state.outcome]}
                <button
                  type="button"
                  className="ml-2 underline underline-offset-2"
                  onClick={() => setReloadToken((token) => token + 1)}
                >
                  Try again
                </button>
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
