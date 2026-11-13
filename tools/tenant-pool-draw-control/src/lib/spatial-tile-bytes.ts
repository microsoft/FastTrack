export const MAX_SPATIAL_TILE_BYTES = 1024 * 1024;

export type SpatialTileMime = "image/jpeg" | "image/png" | "image/webp";
export type SpatialTileFailure =
  | "invalid_signature"
  | "oversized"
  | "unsupported_shape";

export type SpatialTileDecodeResult =
  | {
      ok: true;
      bytes: Uint8Array<ArrayBuffer>;
      dataUrl: string;
      mime: SpatialTileMime;
    }
  | {
      ok: false;
      reason: SpatialTileFailure;
    };

const ARRAY_BUFFER_TAG = "[object ArrayBuffer]";
const BASE64_TEXT = /^[A-Za-z0-9+/]*={0,2}$/;
const DATA_URL_PREFIX = /^data:image\/(?:png|jpeg|webp);base64,/i;
const MAX_BASE64_CHARS = Math.ceil(MAX_SPATIAL_TILE_BYTES / 3) * 4;

function isArrayBuffer(value: unknown): value is ArrayBuffer {
  return Object.prototype.toString.call(value) === ARRAY_BUFFER_TAG;
}

function decodeBase64(value: string): SpatialTileDecodeResult {
  const trimmed = value.trim();
  const payload = DATA_URL_PREFIX.test(trimmed)
    ? trimmed.replace(DATA_URL_PREFIX, "")
    : trimmed;
  if (
    payload.length === 0 ||
    payload.length > MAX_BASE64_CHARS ||
    !BASE64_TEXT.test(payload) ||
    payload.length % 4 === 1
  ) {
    return {
      ok: false,
      reason:
        payload.length > MAX_BASE64_CHARS ? "oversized" : "unsupported_shape",
    };
  }

  const padded = payload.padEnd(
    payload.length + ((4 - (payload.length % 4)) % 4),
    "=",
  );
  try {
    const decoded = atob(padded);
    if (decoded.length === 0) {
      return { ok: false, reason: "unsupported_shape" };
    }
    if (decoded.length > MAX_SPATIAL_TILE_BYTES) {
      return { ok: false, reason: "oversized" };
    }
    const bytes = new Uint8Array(decoded.length);
    for (let index = 0; index < decoded.length; index += 1) {
      bytes[index] = decoded.charCodeAt(index);
    }
    return encodeBytes(bytes);
  } catch {
    return { ok: false, reason: "unsupported_shape" };
  }
}

function detectMime(bytes: Uint8Array): SpatialTileMime | null {
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return "image/png";
  }
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff
  ) {
    return "image/jpeg";
  }
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 &&
    bytes[1] === 0x49 &&
    bytes[2] === 0x46 &&
    bytes[3] === 0x46 &&
    bytes[8] === 0x57 &&
    bytes[9] === 0x45 &&
    bytes[10] === 0x42 &&
    bytes[11] === 0x50
  ) {
    return "image/webp";
  }
  return null;
}

function toDataUrl(bytes: Uint8Array, mime: SpatialTileMime): string {
  let binary = "";
  const chunkSize = 0x8000;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(
      ...bytes.subarray(offset, offset + chunkSize),
    );
  }
  return `data:${mime};base64,${btoa(binary)}`;
}

function encodeBytes(input: Uint8Array): SpatialTileDecodeResult {
  if (input.byteLength === 0) {
    return { ok: false, reason: "unsupported_shape" };
  }
  if (input.byteLength > MAX_SPATIAL_TILE_BYTES) {
    return { ok: false, reason: "oversized" };
  }
  const bytes = Uint8Array.from(input);
  const mime = detectMime(bytes);
  if (!mime) {
    return { ok: false, reason: "invalid_signature" };
  }
  return { ok: true, bytes, dataUrl: toDataUrl(bytes, mime), mime };
}

export function decodeSpatialTile(value: unknown): SpatialTileDecodeResult {
  if (typeof value === "string") {
    return decodeBase64(value);
  }
  if (ArrayBuffer.isView(value)) {
    return encodeBytes(
      new Uint8Array(value.buffer, value.byteOffset, value.byteLength),
    );
  }
  if (isArrayBuffer(value)) {
    return encodeBytes(new Uint8Array(value));
  }
  return { ok: false, reason: "unsupported_shape" };
}
