/*!
 * Copyright (C) Microsoft Corporation. All rights reserved.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Webcam from "react-webcam";
import { Flashlight, ScanLine, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { LoadingState } from "@/components/states";
import { isPreviewMount } from "@/lib/app-view-serializer";
import { isPreviewCameraDenied } from "@/lib/preview-camera-bridge";
import {
  clampScanRate,
  createDetector,
  createScanDeduper,
  decodeImage,
  grabVideoFrame,
  normalizeBarcodeTypes,
  type BarcodeType,
  type Detector,
} from "@/lib/barcode-scan";
import { cn } from "@/lib/utils";

// Live barcode / QR scanner with the same fallback contract as CameraCapture:
// it scans live in the design-time preview once the user allows the Cowork
// host's own camera prompt (`preview-camera-bridge.ts`), and otherwise lands
// on the photo-upload
// fallback (see AGENTS.md). The fallback decodes the chosen photo, so a
// scanner flow stays testable without a camera. Unlike CameraCapture there is
// no 8s auto-fallback timer while the camera is pending: the user leaves that
// state with "Scan from a photo instead".
//
// Scanned values are untrusted user data: never log them (console-capture.ts
// forwards console output to the agent) and never put one in href/location
// without toSafeHttpUrl() from @/lib/barcode-scan.

const MAX_PHOTO_BYTES = 10 * 1024 * 1024; // 10MB
const MAX_DETECT_FAILURES = 5;

type ScanState = "pending" | "live" | "fallback";

type TorchCapabilities = MediaTrackCapabilities & { torch?: boolean };

export type { BarcodeType };

export function BarcodeScanner({
  onScan,
  barcodeTypes,
  scanRate,
  preferFrontCamera = false,
  flashlightEnabled = false,
  className,
  videoClassName,
  fallbackMessage,
}: {
  /**
   * Fires once per newly seen code; holding it in view does not repeat it. A throw or rejection is
   * not retried while the code stays in view (the user moves it away and back), so onScan should be
   * idempotent or handle its own retry. The scan is announced once onScan returns; it may return a promise,
   * which scanning does not wait for, and a rejection shows a toast after that announcement.
   */
  onScan: (value: string, type: string) => unknown;
  /** Formats to look for, e.g. `["qr_code"]` or `["ean_13", "upc_a"]`. Omit for every supported format. */
  barcodeTypes?: readonly BarcodeType[];
  /** Scans per second, 1–100 (default 20). */
  scanRate?: number;
  /** Use the front (selfie) camera instead of the rear one. */
  preferFrontCamera?: boolean;
  /** Show a flashlight toggle when the device camera supports a torch. */
  flashlightEnabled?: boolean;
  className?: string;
  /** Overrides the default `w-full max-w-sm` sizing on the viewfinder itself (twMerge — later classes win). */
  videoClassName?: string;
  /** Overrides the default fallback badge text. */
  fallbackMessage?: string;
}) {
  const [state, setState] = useState<ScanState>("pending");
  // Why the scanner is in fallback: the user chose a photo, or the camera/decoder failed.
  const [fallbackReason, setFallbackReason] = useState<"user" | "error" | "blocked" | "decoder">("error");
  const [announcement, setAnnouncement] = useState("");
  const [torchAvailable, setTorchAvailable] = useState(false);
  const [torchOn, setTorchOn] = useState(false);
  const [decoding, setDecoding] = useState(false);
  const webcamRef = useRef<Webcam>(null);
  const onScanRef = useRef(onScan);
  onScanRef.current = onScan;
  const mountedRef = useRef(true);
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);
  const isDesignTimePreview = isPreviewMount(import.meta.env.BASE_URL ?? "./");

  // Keyed on the joined list so an inline array literal doesn't restart the
  // scanner every render.
  const typesKey = (barcodeTypes ?? []).join(",");
  const types = useMemo(() => normalizeBarcodeTypes(typesKey ? typesKey.split(",") : undefined), [typesKey]);
  const intervalMs = 1000 / clampScanRate(scanRate);
  const videoConstraints = useMemo<MediaTrackConstraints>(
    () => ({
      facingMode: preferFrontCamera ? "user" : "environment",
      // Low-resolution frames defeat 1D decoders; continuous focus keeps close-up codes sharp.
      width: { ideal: 1920 },
      height: { ideal: 1080 },
      advanced: [{ focusMode: "continuous" } as MediaTrackConstraintSet],
    }),
    [preferFrontCamera],
  );

  // Every mode change starts a new session. Camera callbacks, photo decodes and
  // onScan successes from an older session are ignored; an older session's
  // onScan failure is only logged.
  const sessionRef = useRef(0);
  const [session, setSession] = useState(0);
  const stateRef = useRef(state);
  stateRef.current = state;
  const enter = useCallback((next: ScanState, reason?: "user" | "error" | "blocked" | "decoder") => {
    sessionRef.current += 1;
    setSession(sessionRef.current);
    // A photo decode belongs to the session that started it; a new session never inherits its busy state.
    setDecoding(false);
    // The torch belongs to the old camera track; a new session starts with it off.
    setTorchOn(false);
    if (reason) setFallbackReason(reason);
    setState(next);
  }, []);
  const isCurrent = useCallback((s: number) => mountedRef.current && sessionRef.current === s, []);

  const scanCount = useRef(0);
  // Not awaited by the callers: a slow async onScan must not pause live scanning
  // (which would also let the deduper expire a held code and repeat it).
  const report = useCallback(
    (value: string, type: string, s: number) => {
      if (!isCurrent(s)) return;
      const announce = () => {
        if (!isCurrent(s)) return;
        scanCount.current += 1;
        // The count makes each announcement distinct so a repeat scan is re-announced.
        setAnnouncement(`Scanned ${type.replace(/_/g, " ")} code (${scanCount.current})`);
      };
      // A throwing or rejecting consumer callback is the app's bug, not a decoder failure:
      // it must not count toward the fallback limit or show the photo-error toast. A synchronous throw
      // is not announced; a returned promise is announced on delivery, whenever it settles.
      const fail = () => {
        // No error object: it may carry the scanned value, which must not reach the console.
        console.warn("BarcodeScanner: onScan threw");
        // A failure that settles after a mode change or unmount belongs to a session the
        // user has left: log it, but don't toast it over the current one.
        if (!isCurrent(s)) return;
        // A fixed id collapses repeats (a multi-code photo) into one toast.
        toast.error("Couldn't process that scan.", { id: "barcode-onscan-error" });
      };
      let result: unknown;
      try {
        result = onScanRef.current(value, type);
      } catch {
        fail();
        return;
      }
      announce();
      Promise.resolve(result).catch(fail);
    },
    [isCurrent],
  );

  // console.warn, not console.error — an expected fallback is not a runtime
  // failure for the agent (same reasoning as CameraCapture).
  function handleUserMediaError(err: string | DOMException, s: number) {
    console.warn("BarcodeScanner: getUserMedia failed, falling back", err);
    // react-webcam reports a rejection even after the user already left this camera attempt.
    if (!isCurrent(s)) return;
    enter("fallback", isPreviewCameraDenied(err) ? "blocked" : "error");
  }

  // Scan loop: one detect() at a time, throttled to scanRate, paused while
  // the tab is hidden.
  useEffect(() => {
    if (state !== "live") return;
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let detector: Detector | undefined;
    const isNew = createScanDeduper();
    let failures = 0;

    const tick = async () => {
      if (cancelled) return;
      const video = webcamRef.current?.video;
      if (detector && video && video.readyState >= 2 && !document.hidden) {
        try {
          // iOS Safari has no native BarcodeDetector; the zxing-js decoder reads ImageData reliably, a <video> element not.
          for (const result of await detector.detect(grabVideoFrame(video) ?? video)) {
            if (!cancelled && isNew(result)) report(result.value, result.type, session);
          }
          failures = 0;
        } catch (err) {
          console.warn("BarcodeScanner: detect failed", err);
          if (++failures >= MAX_DETECT_FAILURES) {
            if (!cancelled) {
              toast.error("The scanner stopped working — try choosing a photo instead.");
              enter("fallback", "decoder");
            }
            return;
          }
        }
      }
      if (!cancelled) timer = setTimeout(tick, intervalMs);
    };

    createDetector(types)
      .then((d) => {
        detector = d;
        void tick();
      })
      .catch((err) => {
        console.warn("BarcodeScanner: decoder failed to load", err);
        if (!cancelled) toast.error("The scanner couldn't start — try choosing a photo instead.");
        if (!cancelled) enter("fallback", "decoder");
      });

    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, [state, session, types, intervalMs, report, enter]);

  // Torch support is per device; only offer the toggle when the track has it.
  useEffect(() => {
    if (state !== "live" || !flashlightEnabled) {
      setTorchAvailable(false);
      return;
    }
    const track = webcamRef.current?.stream?.getVideoTracks()[0];
    const caps = track?.getCapabilities?.() as TorchCapabilities | undefined;
    setTorchAvailable(Boolean(caps?.torch));
  }, [state, flashlightEnabled]);

  // Stop the camera when unmounting so the device light turns off.
  useEffect(() => {
    const webcam = webcamRef;
    return () => webcam.current?.stream?.getTracks().forEach((t) => t.stop());
  }, []);

  async function toggleTorch() {
    const track = webcamRef.current?.stream?.getVideoTracks()[0];
    if (!track) return;
    const next = !torchOn;
    const s = sessionRef.current;
    try {
      await track.applyConstraints({ advanced: [{ torch: next } as MediaTrackConstraintSet] });
      if (isCurrent(s)) setTorchOn(next);
    } catch (err) {
      console.warn("BarcodeScanner: torch toggle failed", err);
      if (isCurrent(s)) toast.error("Couldn't switch the flashlight.");
    }
  }

  async function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const input = e.target;
    const file = input.files?.[0];
    input.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      toast.error("That file isn't a photo — choose an image instead.");
      return;
    }
    if (file.size > MAX_PHOTO_BYTES) {
      toast.error("That photo is too large — choose one under 10MB.");
      return;
    }
    const s = sessionRef.current;
    setDecoding(true);
    try {
      const results = await decodeImage(file, types);
      // The scanner may have closed, or gone back to the camera, while the photo decoded: drop the result.
      if (!isCurrent(s)) return;
      if (results.length === 0) {
        toast.error("No barcode or QR code found in that photo.");
        return;
      }
      for (const r of results) report(r.value, r.type, s);
    } catch (err) {
      if (!isCurrent(s)) return;
      console.warn("BarcodeScanner: photo decode failed", err);
      toast.error("Couldn't read that photo — try a different one.");
    } finally {
      if (isCurrent(s)) setDecoding(false);
    }
  }

  const liveRegion = (
    <p className="sr-only" aria-live="polite" role="status">
      {announcement}
    </p>
  );

  if (state === "fallback") {
    return (
      <div data-slot="barcode-scanner" className={cn("flex flex-col items-center gap-3 py-10 text-center", className)}>
        <div className="relative flex size-24 items-center justify-center rounded-2xl bg-muted/40">
          <span className="absolute left-0 top-0 size-4 rounded-tl-md border-l-2 border-t-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute right-0 top-0 size-4 rounded-tr-md border-r-2 border-t-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute bottom-0 left-0 size-4 rounded-bl-md border-b-2 border-l-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute bottom-0 right-0 size-4 rounded-br-md border-b-2 border-r-2 border-muted-foreground/40" aria-hidden="true" />
          <ScanLine className="size-9 text-muted-foreground" aria-hidden="true" />
        </div>
        <span
          className={cn(
            "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
            isDesignTimePreview && (fallbackReason === "error" || fallbackReason === "blocked") ? "bg-amber-100 text-amber-800" : "bg-muted text-muted-foreground",
          )}
        >
          {fallbackMessage ??
            (fallbackReason === "user"
              ? "Scanning from a photo"
              : fallbackReason === "decoder"
                ? "Live scanning unavailable"
                : fallbackReason === "blocked"
                  ? "Camera access was blocked"
                  : isDesignTimePreview
                    ? "Camera unavailable in preview"
                    : "Camera not available on this device")}
        </span>
        <div className="flex items-center gap-2">
          <Button asChild variant="outline" disabled={decoding}>
            <label className="cursor-pointer has-[:focus-visible]:outline-solid has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-ring">
              <Upload aria-hidden="true" />
              {decoding ? "Reading photo…" : "Scan from a photo"}
              <input type="file" accept="image/*" className="sr-only" onChange={handleFile} disabled={decoding} />
            </label>
          </Button>
          <Button type="button" variant="ghost" onClick={() => enter("pending")}>
            Try camera again
          </Button>
        </div>
        {liveRegion}
      </div>
    );
  }

  return (
    <div data-slot="barcode-scanner" className={cn("flex flex-col items-center gap-3", className)}>
      {state === "pending" && (
        <>
          <LoadingState rows={1} className="w-full max-w-sm" />
          {/* No timer fallback (unlike CameraCapture): a slow permission prompt
              must not be yanked away, so the user chooses when to give up. */}
          <Button
            type="button"
            variant="ghost"
            onClick={() => enter("fallback", "user")}
          >
            Scan from a photo instead
          </Button>
        </>
      )}
      <Webcam
        ref={webcamRef}
        audio={false}
        videoConstraints={videoConstraints}
        onUserMedia={() => {
          // A repeated callback must not restart the live loop (and its deduper).
          if (sessionRef.current === session && stateRef.current !== "live") enter("live");
        }}
        onUserMediaError={(err) => handleUserMediaError(err, session)}
        aria-label="Barcode scanner viewfinder"
        className={cn("w-full max-w-sm rounded-lg", videoClassName, state !== "live" && "hidden")}
      />
      {state === "live" && torchAvailable && (
        <Button type="button" variant="outline" onClick={toggleTorch} aria-pressed={torchOn}>
          <Flashlight aria-hidden="true" />
          {torchOn ? "Flashlight off" : "Flashlight on"}
        </Button>
      )}
      {liveRegion}
    </div>
  );
}
