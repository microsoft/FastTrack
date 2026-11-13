/*!
 * Copyright (C) Microsoft Corporation. All rights reserved.
 */

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import Webcam from "react-webcam";
import { Camera, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { LoadingState } from "@/components/states";
import { isPreviewMount } from "@/lib/app-view-serializer";
import {
  isPreviewCameraConsentPending,
  isPreviewCameraDenied,
  subscribePreviewCameraConsent,
} from "@/lib/preview-camera-bridge";
import { cn } from "@/lib/utils";

// Camera capture with an automatic fallback. In the design-time preview the
// Cowork host owns the camera: `preview-camera-bridge.ts` routes getUserMedia
// through the host's own consent, so live capture works there once the user
// allows it, and otherwise errors exactly as on a device with no or a blocked
// camera (see AGENTS.md). Render <Webcam> directly and let onUserMediaError
// flip us to the fallback; don't pre-probe getUserMedia yourself, or the
// browser prompts twice and the camera light flickers on/off before the real
// viewfinder mounts.
//
// The badge only says where the camera was unavailable, never that publishing
// fixes it. Reuse the shared preview-mount predicate so both
// `/v1/dev/{session_id}/…` and tokenized `/v1/preview/{token}/dev/…` preview
// bases get the same design-time wording. Outside Vite (for example the Bun
// component tests) BASE_URL is absent, so fall back to the published-build
// `"./"` base there too.

// `accept="image/*"` on the fallback <input> is only a picker-UI hint —
// the browser doesn't enforce it, so a renamed non-image or an oversized
// file can still reach handleFile. Reject both before the (memory-heavy)
// Data URL conversion rather than trusting the accept attribute alone.
const MAX_PHOTO_BYTES = 10 * 1024 * 1024; // 10MB

type CaptureState = "pending" | "live" | "fallback";

export function CameraCapture({
  onCapture,
  className,
  videoClassName,
  videoConstraints,
  fallbackMessage,
}: {
  onCapture: (dataUrl: string) => void;
  className?: string;
  /** Overrides the default `w-full max-w-sm` sizing on the viewfinder itself (twMerge — later classes win). */
  videoClassName?: string;
  /** Passed straight to react-webcam's `videoConstraints` — e.g. `{ facingMode: "environment" }` or a target resolution. */
  videoConstraints?: MediaTrackConstraints;
  /** Overrides the default fallback badge text (camera unavailable in preview vs on this device). */
  fallbackMessage?: string;
}) {
  const [state, setState] = useState<CaptureState>("pending");
  const [blocked, setBlocked] = useState(false);
  const consentPending = useSyncExternalStore(subscribePreviewCameraConsent, isPreviewCameraConsentPending);
  const webcamRef = useRef<Webcam>(null);
  const isDesignTimePreview = isPreviewMount(import.meta.env.BASE_URL ?? "./");

  // NotAllowedError (denied), NotFoundError (no hardware) and NotReadableError
  // (camera in use elsewhere) are all valid, expected reasons to fall back —
  // the badge text is deliberately generic (see file header) except after the
  // user denies the preview host's own camera prompt — but swallowing
  // which one occurred makes the fallback impossible to debug. console.warn,
  // not console.error: console-capture.ts POSTs only console.error to
  // .browser-errors.log for the app-builder agent to inspect as a genuine
  // runtime failure, and an expected/handled fallback isn't one — it still
  // reaches the parent-frame console panel either way.
  function handleUserMediaError(err: string | DOMException) {
    console.warn("CameraCapture: getUserMedia failed, falling back", err);
    setBlocked(isPreviewCameraDenied(err));
    setState("fallback");
  }

  // Some browsers leave the permission prompt open indefinitely instead of
  // rejecting getUserMedia's promise (e.g. Chrome's address-bar prompt bar
  // with no auto-dismiss). Without an escape hatch a user who never answers
  // it is stuck on the loading skeleton with no way to use the file picker.
  // The preview host's own consent dialog is modal and always answered, so
  // the timer waits while it is open.
  useEffect(() => {
    if (state !== "pending" || consentPending) return;
    const timer = setTimeout(() => setState((prev) => (prev === "pending" ? "fallback" : prev)), 8000);
    return () => clearTimeout(timer);
  }, [state, consentPending]);

  function capture() {
    const shot = webcamRef.current?.getScreenshot();
    if (shot) {
      onCapture(shot);
    } else {
      toast.error("Couldn't capture a photo — try again in a moment.");
    }
  }

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      toast.error("That file isn't a photo — choose an image instead.");
      e.target.value = "";
      return;
    }
    if (file.size > MAX_PHOTO_BYTES) {
      toast.error("That photo is too large — choose one under 10MB.");
      e.target.value = "";
      return;
    }
    const reader = new FileReader();
    reader.onload = () => onCapture(reader.result as string);
    reader.onerror = () => toast.error("Couldn't read that photo — try a different file.");
    reader.readAsDataURL(file);
    e.target.value = "";
  }

  if (state === "fallback") {
    return (
      <div data-slot="camera-capture" className={cn("flex flex-col items-center gap-3 py-10 text-center", className)}>
        <div className="relative flex size-24 items-center justify-center rounded-2xl bg-muted/40">
          <span className="absolute left-0 top-0 size-4 rounded-tl-md border-l-2 border-t-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute right-0 top-0 size-4 rounded-tr-md border-r-2 border-t-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute bottom-0 left-0 size-4 rounded-bl-md border-b-2 border-l-2 border-muted-foreground/40" aria-hidden="true" />
          <span className="absolute bottom-0 right-0 size-4 rounded-br-md border-b-2 border-r-2 border-muted-foreground/40" aria-hidden="true" />
          <Camera className="size-9 text-muted-foreground" aria-hidden="true" />
        </div>
        <span
          className={cn(
            "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
            isDesignTimePreview ? "bg-amber-100 text-amber-800" : "bg-muted text-muted-foreground",
          )}
        >
          {fallbackMessage ??
            (blocked
              ? "Camera access was blocked"
              : isDesignTimePreview
                ? "Camera unavailable in preview"
                : "Camera not available on this device")}
        </span>
        <div className="flex items-center gap-2">
          <Button asChild variant="outline">
            {/* The visible control is this label; the actual focusable element is the
                sr-only input below, so :focus-visible on the input alone leaves no
                visible ring. has-[:focus-visible]: forwards that ring onto the label. */}
            <label className="cursor-pointer has-[:focus-visible]:outline-solid has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-ring">
              <Upload aria-hidden="true" />
              Choose a photo
              <input
                type="file"
                accept="image/*"
                className="sr-only"
                onChange={handleFile}
              />
            </label>
          </Button>
          <Button type="button" variant="ghost" onClick={() => setState("pending")}>
            Try camera again
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div data-slot="camera-capture" className={cn("flex flex-col items-center gap-3", className)}>
      {state === "pending" && <LoadingState rows={1} className="w-full max-w-sm" />}
      <Webcam
        ref={webcamRef}
        audio={false}
        screenshotFormat="image/jpeg"
        videoConstraints={videoConstraints}
        onUserMedia={() => setState("live")}
        onUserMediaError={handleUserMediaError}
        className={cn("w-full max-w-sm rounded-lg", videoClassName, state !== "live" && "hidden")}
      />
      {state === "live" && (
        <Button type="button" onClick={capture}>
          <Camera aria-hidden="true" />
          Capture
        </Button>
      )}
    </div>
  );
}
