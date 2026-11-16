import {
  useEffect,
  useRef,
  useState,
  type ReactNode,
  type RefObject,
} from "react";

import { Button } from "@/components/ui/button";
import {
  createPdfBlob,
  toSafePdfExportError,
  type PdfCaptureOptions,
  type PdfExportResult,
} from "@/lib/pdf-export";

export type PdfExportButtonProps = {
  targetRef: RefObject<HTMLElement | null>;
  fileName: string;
  options?: PdfCaptureOptions;
  onGenerated?: (result: PdfExportResult) => void | Promise<void>;
  callbackTimeoutMs?: number;
  children?: ReactNode;
};

export const DEFAULT_PDF_CALLBACK_TIMEOUT_MS = 30_000;
export const MAX_PDF_CALLBACK_TIMEOUT_MS = 60_000;
export const PDF_OBJECT_URL_REVOKE_DELAY_MS = 1_000;
export const MAX_PENDING_PDF_CALLBACKS = 2;

const FOLLOW_UP_FAILED = "PDF ready, but the follow-up action failed.";
const FOLLOW_UP_PENDING = "PDF ready; the follow-up action is still running.";
const PREVIOUS_FOLLOW_UP_PENDING =
  "PDF generated; its follow-up action is queued behind the previous export.";
const FOLLOW_UP_QUEUE_FULL =
  "PDF ready, but its follow-up action was not queued because earlier actions are still running.";

type ExportPhase = "idle" | "generating" | "follow-up";

function preserveFollowUpFailure(
  current: string | null,
  next: string | null,
): string | null {
  return current === FOLLOW_UP_FAILED || current === FOLLOW_UP_QUEUE_FULL
    ? current
    : next;
}

function isErrorNotice(notice: string): boolean {
  return (
    notice === "PDF export failed." ||
    notice === FOLLOW_UP_FAILED ||
    notice === FOLLOW_UP_QUEUE_FULL
  );
}

function normalizeCallbackTimeout(timeoutMs: number): number {
  if (
    !Number.isSafeInteger(timeoutMs) ||
    timeoutMs <= 0 ||
    timeoutMs > MAX_PDF_CALLBACK_TIMEOUT_MS
  ) {
    return DEFAULT_PDF_CALLBACK_TIMEOUT_MS;
  }
  return timeoutMs;
}

function normalizeReportedError(error: unknown, fallback: string): Error {
  return toSafePdfExportError(error) ?? new Error(fallback);
}

async function waitForCallback(
  callback: Promise<"completed" | "failed">,
  timeoutMs: number,
): Promise<"completed" | "failed" | "pending"> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      callback,
      new Promise<"pending">((resolve) => {
        timeout = setTimeout(() => resolve("pending"), timeoutMs);
      }),
    ]);
  } finally {
    if (timeout) clearTimeout(timeout);
  }
}

export function PdfExportButton({
  targetRef,
  fileName,
  options,
  onGenerated,
  callbackTimeoutMs = DEFAULT_PDF_CALLBACK_TIMEOUT_MS,
  children = "Download PDF",
}: PdfExportButtonProps) {
  const inFlight = useRef(false);
  const mounted = useRef(false);
  const pendingCallback = useRef<Promise<void> | null>(null);
  const pendingCallbackCount = useRef(0);
  const [phase, setPhase] = useState<ExportPhase>("idle");
  const [generationNotice, setGenerationNotice] = useState<string | null>(null);
  const [followUpNotice, setFollowUpNotice] = useState<string | null>(null);
  const isBusy = phase !== "idle";
  const notices = [generationNotice, followUpNotice].filter(
    (notice): notice is string => Boolean(notice),
  );
  const errorNotices = notices.filter(isErrorNotice);
  const infoNotices = notices.filter((notice) => !isErrorNotice(notice));

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  async function generateAndDownload() {
    if (inFlight.current) return;
    inFlight.current = true;
    setPhase("generating");
    setGenerationNotice(null);
    if (pendingCallbackCount.current === 0) {
      setFollowUpNotice(null);
    }

    let objectUrl: string | undefined;
    try {
      const target = targetRef.current;
      if (!target) {
        throw new Error("PDF capture target is unavailable.");
      }
      const result = await createPdfBlob(target, fileName, options);
      if (!mounted.current) return;

      objectUrl = URL.createObjectURL(result.blob);
      const link = window.document.createElement("a");
      link.href = objectUrl;
      link.download = result.fileName;
      link.style.display = "none";
      window.document.body.append(link);
      try {
        link.click();
        const urlToRevoke = objectUrl;
        window.setTimeout(
          () => URL.revokeObjectURL(urlToRevoke),
          PDF_OBJECT_URL_REVOKE_DELAY_MS,
        );
        objectUrl = undefined;
      } finally {
        link.remove();
      }
      if (onGenerated && pendingCallbackCount.current >= MAX_PENDING_PDF_CALLBACKS) {
        setFollowUpNotice(FOLLOW_UP_QUEUE_FULL);
      } else if (onGenerated) {
        setPhase("follow-up");
        const previousCallback = pendingCallback.current;
        if (previousCallback) {
          setGenerationNotice(PREVIOUS_FOLLOW_UP_PENDING);
        }

        pendingCallbackCount.current += 1;
        const callback = (previousCallback ?? Promise.resolve())
          .catch(() => undefined)
          .then(() => {
            if (previousCallback && mounted.current) {
              setGenerationNotice((current) =>
                current === PREVIOUS_FOLLOW_UP_PENDING ? null : current,
              );
            }
            if (!mounted.current) return;
            return onGenerated(result);
          })
          .catch(async (error) => {
            const { reportPrivateRuntimeError } = await import(
              "@/lib/console-capture"
            );
            reportPrivateRuntimeError(
              "PDF follow-up action failed",
              normalizeReportedError(error, "PDF follow-up action failed"),
            );
            throw error;
          });
        pendingCallback.current = callback;
        const completion = callback.then(
          () => "completed" as const,
          () => "failed" as const,
        );
        void completion.then((outcome) => {
          pendingCallbackCount.current -= 1;
          if (pendingCallback.current === callback) {
            pendingCallback.current = null;
          }
          if (!mounted.current) return;
          setFollowUpNotice((current) =>
            outcome === "failed"
              ? FOLLOW_UP_FAILED
              : preserveFollowUpFailure(current, null),
          );
        });

        const outcome = await waitForCallback(
          completion,
          normalizeCallbackTimeout(callbackTimeoutMs),
        );
        if (!mounted.current) return;
        if (outcome === "failed") {
          setFollowUpNotice(FOLLOW_UP_FAILED);
        } else if (outcome === "pending") {
          setFollowUpNotice((current) =>
            preserveFollowUpFailure(current, FOLLOW_UP_PENDING),
          );
        }
      }
    } catch (error) {
      const { reportPrivateRuntimeError } = await import("@/lib/console-capture");
      reportPrivateRuntimeError(
        "PDF export failed",
        normalizeReportedError(error, "PDF export failed"),
      );
      if (mounted.current) {
        setGenerationNotice("PDF export failed.");
      }
    } finally {
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      inFlight.current = false;
      if (mounted.current) {
        setPhase("idle");
      }
    }
  }

  return (
    <div className="flex flex-col items-start gap-2" data-pdf-exclude>
      <Button
        type="button"
        disabled={isBusy}
        aria-busy={isBusy}
        onClick={() => void generateAndDownload()}
      >
        {phase === "generating"
          ? "Creating PDF…"
          : phase === "follow-up"
            ? "Completing follow-up…"
            : children}
      </Button>
      {phase === "generating" ? (
        <p role="status" className="text-sm text-muted-foreground">
          Creating your PDF…
        </p>
      ) : phase === "follow-up" ? (
        <p role="status" className="text-sm text-muted-foreground">
          PDF ready; completing the follow-up action…
        </p>
      ) : null}
      {infoNotices.length > 0 ? (
        <p role="status" className="text-sm text-muted-foreground">
          {infoNotices.join(" ")}
        </p>
      ) : null}
      {errorNotices.length > 0 ? (
        <p role="alert" className="text-sm text-destructive">
          {errorNotices.join(" ")}
        </p>
      ) : null}
    </div>
  );
}
