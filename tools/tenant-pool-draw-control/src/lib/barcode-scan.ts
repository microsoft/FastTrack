/*!
 * Copyright (C) Microsoft Corporation. All rights reserved.
 */

// The ONLY module allowed to import @zxing/library (eslint enforces it).
// Generated apps use <BarcodeScanner> from @/components/barcode-scanner
// instead of wiring a decoder themselves.
//
// The native BarcodeDetector (Chrome on Android/ChromeOS/macOS) is tried first
// when it supports EVERY requested format; a frame it reads nothing from (it
// misses 1D codes on low-resolution camera frames), or a detector that throws
// (macOS Chrome reports formats but "Barcode detection service unavailable"),
// is retried with @zxing/library. That decoder is pure JavaScript on purpose:
// a published app's CSP is `script-src 'self'`, which forbids compiling
// WebAssembly, so a wasm decoder never runs there. The build inlines dynamic
// imports into one bundle, so the decoder ships with any app that imports
// the scanner.
export const BARCODE_TYPES = [
  "qr_code",
  "ean_13",
  "ean_8",
  "upc_a",
  "upc_e",
  "code_128",
  "code_39",
  "itf",
  "data_matrix",
  "pdf417",
  "aztec",
  "codabar",
] as const;

export type BarcodeType = (typeof BARCODE_TYPES)[number];

export interface ScanResult {
  value: string;
  type: string;
}

export interface Detector {
  detect(source: ImageBitmapSource): Promise<ScanResult[]>;
}

interface NativeDetected {
  rawValue: string;
  format: string;
}
interface NativeDetectorCtor {
  new (options?: { formats?: string[] }): { detect(source: ImageBitmapSource): Promise<NativeDetected[]> };
  getSupportedFormats(): Promise<string[]>;
}

export const DEFAULT_SCAN_RATE = 20;

/** Scans per second, clamped to 1–100 (Power Apps' ScanRate range). */
export function clampScanRate(rate: number | undefined): number {
  if (rate === undefined || !Number.isFinite(rate)) return DEFAULT_SCAN_RATE;
  return Math.min(100, Math.max(1, Math.round(rate)));
}

/** Drops unknown names and duplicates; an empty or missing list means every supported type. */
export function normalizeBarcodeTypes(types: readonly string[] | undefined): BarcodeType[] {
  const wanted = new Set(types ?? []);
  const picked = BARCODE_TYPES.filter((t) => wanted.has(t));
  return picked.length > 0 ? picked : [...BARCODE_TYPES];
}

function mapResults(found: NativeDetected[], types: readonly BarcodeType[]): ScanResult[] {
  return found
    .filter((b) => typeof b.rawValue === "string" && b.rawValue.length > 0)
    .map((b) => normalizeUpc({ value: b.rawValue, type: b.format }, types));
}

/**
 * A UPC-A read as EAN-13 (zxing does this) carries a leading 0; when UPC-A was
 * requested, report it as the 12-digit UPC-A printed on the label.
 */
export function normalizeUpc(result: ScanResult, types: readonly BarcodeType[]): ScanResult {
  return types.includes("upc_a") && result.type === "ean_13" && /^0\d{12}$/.test(result.value)
    ? { value: result.value.slice(1), type: "upc_a" }
    : result;
}

function nativeCtor(): NativeDetectorCtor | undefined {
  const ctor = (globalThis as { BarcodeDetector?: NativeDetectorCtor }).BarcodeDetector;
  return typeof ctor === "function" ? ctor : undefined;
}

type ZXing = typeof import("@zxing/library");
let zxingModule: Promise<ZXing> | undefined;

function loadZXing(): Promise<ZXing> {
  zxingModule ??= import("@zxing/library");
  // A failed module import must not poison every later attempt.
  zxingModule.catch(() => {
    zxingModule = undefined;
  });
  return zxingModule;
}

const ZXING_FORMAT: Record<BarcodeType, string> = {
  qr_code: "QR_CODE",
  ean_13: "EAN_13",
  ean_8: "EAN_8",
  upc_a: "UPC_A",
  upc_e: "UPC_E",
  code_128: "CODE_128",
  code_39: "CODE_39",
  itf: "ITF",
  data_matrix: "DATA_MATRIX",
  pdf417: "PDF_417",
  aztec: "AZTEC",
  codabar: "CODABAR",
};

/** `source` as ImageData: used as-is when it already is, else drawn onto a canvas. */
async function toImageData(source: ImageBitmapSource): Promise<ImageData | null> {
  if (typeof ImageData !== "undefined" && source instanceof ImageData) return source;
  if (typeof createImageBitmap !== "function") return null;
  const bitmap = await createImageBitmap(source);
  try {
    const c = makeCanvas(bitmap.width, bitmap.height);
    if (!c) return null;
    c.ctx.drawImage(bitmap, 0, 0);
    return c.ctx.getImageData(0, 0, bitmap.width, bitmap.height);
  } finally {
    bitmap.close();
  }
}

/** A pure-JS @zxing/library detector with the native detector's shape. */
async function createZXingDetector(types: readonly BarcodeType[]): Promise<RawDetector> {
  const zx = await loadZXing();
  const formats = types.map((t) => zx.BarcodeFormat[ZXING_FORMAT[t] as keyof typeof zx.BarcodeFormat]);
  const hints = new Map<number, unknown>([
    [zx.DecodeHintType.POSSIBLE_FORMATS, formats],
    [zx.DecodeHintType.TRY_HARDER, true],
  ]);
  const reader = new zx.MultiFormatReader();
  reader.setHints(hints);
  const back = new Map<number, string>(types.map((t) => [zx.BarcodeFormat[ZXING_FORMAT[t] as keyof typeof zx.BarcodeFormat], t]));
  return {
    detect: async (source) => {
      const img = await toImageData(source);
      if (!img) return [];
      const { width, height, data } = img;
      const lum = new Uint8ClampedArray(width * height);
      for (let i = 0, p = 0; i < lum.length; i++, p += 4) {
        lum[i] = (306 * data[p] + 601 * data[p + 1] + 117 * data[p + 2] + 0x200) >> 10;
      }
      const luminance = new zx.RGBLuminanceSource(lum, width, height);
      // Hybrid suits 2D codes; the global histogram reads 1D codes Hybrid's local thresholds break.
      for (const Binarizer of [zx.HybridBinarizer, zx.GlobalHistogramBinarizer]) {
        try {
          const result = reader.decodeWithState(new zx.BinaryBitmap(new Binarizer(luminance)));
          return [{ rawValue: result.getText(), format: back.get(result.getBarcodeFormat()) ?? "unknown" }];
        } catch (err) {
          if (!(err instanceof zx.NotFoundException || err instanceof zx.ChecksumException || err instanceof zx.FormatException)) throw err;
        } finally {
          reader.reset();
        }
      }
      return [];
    },
  };
}

/** Builds a detector for `types`: native first when it covers all of them, @zxing/library for anything native misses. */
export async function createDetector(types: readonly BarcodeType[]): Promise<Detector> {
  const formats = [...types];
  const native = nativeCtor();
  let Ctor: NativeDetectorCtor | undefined;
  if (native) {
    try {
      const supported = new Set(await native.getSupportedFormats());
      if (formats.every((f) => supported.has(f))) Ctor = native;
    } catch {
      // fall through to zxing
    }
  }
  const zxing = withQuietZoneRetry(() => createZXingDetector(formats), formats);
  if (!Ctor) return zxing;
  const NativeCtor = Ctor;
  const nativeDetector = withQuietZoneRetry(async () => new NativeCtor({ formats }), formats);
  // Android's native detector misses 1D codes on low-res frames that zxing reads;
  // macOS Chrome's throws "Barcode detection service unavailable".
  return {
    detect: async (source) => {
      try {
        const found = await nativeDetector.detect(source);
        if (found.length > 0) return found;
      } catch {
        // fall through to zxing
      }
      return zxing.detect(source);
    },
  };
}
type RawDetector = { detect(source: ImageBitmapSource): Promise<NativeDetected[]> };

function withQuietZoneRetry(make: () => Promise<RawDetector>, types: readonly BarcodeType[]): Detector {
  let detector: Promise<RawDetector> | undefined;
  return {
    detect: async (source) => {
      detector ??= make();
      detector.catch(() => {
        detector = undefined;
      });
      const d = await detector;
      const found = mapResults(await d.detect(source), types);
      if (found.length > 0) return found;
      // 1D codes cropped tight to the bars (no quiet zone) never decode; retry on a white margin.
      const padded = await padWithQuietZone(source);
      if (!padded) return found;
      return mapResults(await d.detect(padded), types);
    },
  };
}

/** Margin added on each side: 10% of the longer edge, at least 40px. */
export function quietZoneMargin(width: number, height: number): number {
  return Math.max(40, Math.round(Math.max(width, height) * 0.1));
}

type Canvas2D = { canvas: OffscreenCanvas | HTMLCanvasElement; ctx: OffscreenCanvasRenderingContext2D | CanvasRenderingContext2D };

/** A 2d canvas: OffscreenCanvas where it works (iOS < 16.4 has none), else a detached <canvas>. */
function makeCanvas(width: number, height: number): Canvas2D | null {
  if (typeof OffscreenCanvas === "function") {
    const canvas = new OffscreenCanvas(width, height);
    const ctx = canvas.getContext("2d");
    if (ctx) return { canvas, ctx };
  }
  if (typeof document !== "undefined") {
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    if (ctx) return { canvas, ctx };
  }
  return null;
}

type Decoded = { source: CanvasImageSource; width: number; height: number; release(): void };

/** Decodes a photo ourselves, EXIF orientation applied: createImageBitmap first, an <img> where that refuses the file. */
async function decodePhoto(image: Blob): Promise<Decoded | null> {
  if (typeof createImageBitmap === "function") {
    try {
      const bitmap = await createImageBitmap(image, { imageOrientation: "from-image" });
      return { source: bitmap, width: bitmap.width, height: bitmap.height, release: () => bitmap.close() };
    } catch {
      // fall back to <img>
    }
  }
  if (typeof Image !== "function" || typeof URL?.createObjectURL !== "function") return null;
  const url = URL.createObjectURL(image);
  try {
    const img = new Image();
    img.decoding = "async";
    await new Promise<void>((resolve, reject) => {
      img.onload = () => resolve();
      img.onerror = () => reject(new Error("img load failed"));
      img.src = url;
    });
    return { source: img, width: img.naturalWidth, height: img.naturalHeight, release: () => URL.revokeObjectURL(url) };
  } catch {
    URL.revokeObjectURL(url);
    return null;
  }
}

/** Long-side sizes a photo is decoded at: phone photos are 3-4k px, which the decoder handles worse than a downscale. */
export const PHOTO_SCALES = [2000, 1200, 800] as const;

/** Rasterises `photo` with its long side at most `maxSide`, as ImageData (the decoder's native input). */
function rasterize(photo: Decoded, maxSide: number): ImageData | null {
  const scale = Math.min(1, maxSide / Math.max(photo.width, photo.height));
  const w = Math.max(1, Math.round(photo.width * scale));
  const h = Math.max(1, Math.round(photo.height * scale));
  const c = makeCanvas(w, h);
  if (!c) return null;
  c.ctx.fillStyle = "#fff";
  c.ctx.fillRect(0, 0, w, h);
  c.ctx.drawImage(photo.source, 0, 0, w, h);
  return c.ctx.getImageData(0, 0, w, h);
}

/** The current camera frame as ImageData, long side at most `maxSide`; null before the first frame or without a canvas. */
export function grabVideoFrame(video: HTMLVideoElement, maxSide = 1280): ImageData | null {
  const { videoWidth: width, videoHeight: height } = video;
  if (!width || !height) return null;
  return rasterize({ source: video, width, height, release: () => {} }, maxSide);
}

/** Draws `source` centred on a white canvas with a quiet zone; null where canvases are unavailable. */
export async function padWithQuietZone(source: ImageBitmapSource): Promise<ImageBitmapSource | null> {
  if (typeof createImageBitmap !== "function") return null;
  let bitmap: ImageBitmap;
  try {
    bitmap = await createImageBitmap(source);
  } catch {
    return null;
  }
  try {
    const { width, height } = bitmap;
    if (width === 0 || height === 0) return null;
    const m = quietZoneMargin(width, height);
    const c = makeCanvas(width + 2 * m, height + 2 * m);
    if (!c) return null;
    c.ctx.fillStyle = "#fff";
    c.ctx.fillRect(0, 0, c.canvas.width, c.canvas.height);
    c.ctx.drawImage(bitmap, m, m);
    return c.ctx.getImageData(0, 0, c.canvas.width, c.canvas.height);
  } finally {
    bitmap.close();
  }
}

/**
 * Decodes the codes in a still image (e.g. an uploaded photo). The photo is
 * decoded and rasterised here, EXIF-rotated and downscaled, and handed to the
 * detector as ImageData at each of PHOTO_SCALES; the raw file is the last resort.
 */
export async function decodeImage(image: Blob, types: readonly BarcodeType[]): Promise<ScanResult[]> {
  const detector = await createDetector(types);
  const photo = await decodePhoto(image);
  if (photo) {
    try {
      for (const side of PHOTO_SCALES) {
        const frame = rasterize(photo, side);
        if (!frame) break;
        const found = await detector.detect(frame);
        if (found.length > 0) return found;
      }
    } finally {
      photo.release();
    }
  }
  return detector.detect(image);
}

/**
 * Reports each code once while it stays in view, so a code held in front of
 * the camera fires OnScan once, not 20 times a second, even with several
 * codes in the frame. A code unseen for `cooldownMs` fires again.
 *
 * A failed delivery is not redelivered while the code stays in view: onScan
 * may have committed a write before failing, and a retry would repeat it.
 * The user moves the code out of view and back to try again.
 */
export function createScanDeduper(cooldownMs = 2000, now: () => number = Date.now) {
  const lastSeen = new Map<string, number>();
  return (result: ScanResult): boolean => {
    const key = `${result.type}\u0000${result.value}`;
    const t = now();
    for (const [k, s] of lastSeen) if (t - s > cooldownMs) lastSeen.delete(k);
    const fresh = !lastSeen.has(key);
    lastSeen.set(key, t);
    return fresh;
  };
}

/**
 * Returns the scanned value as a URL only when it is an absolute http(s)
 * URL. QR codes are untrusted input: never assign a scanned value to
 * `href`/`location` without this check (it rejects javascript:, data:, etc.).
 */
export function toSafeHttpUrl(value: string): URL | null {
  let url: URL;
  try {
    url = new URL(value.trim());
  } catch {
    return null;
  }
  return url.protocol === "https:" || url.protocol === "http:" ? url : null;
}
