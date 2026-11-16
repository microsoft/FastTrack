export const MAX_PDF_BYTES = 25 * 1024 * 1024;

export type PdfBytesFailure =
  | "empty"
  | "invalid_signature"
  | "oversized"
  | "text_decoded"
  | "unsupported_shape";

export type PdfBytesDecodeResult =
  | { ok: true; bytes: Uint8Array<ArrayBuffer> }
  | { ok: false; reason: PdfBytesFailure };

const ARRAY_BUFFER_TAG = "[object ArrayBuffer]";
const BASE64_TEXT = /^[A-Za-z0-9+/]*={0,2}$/;
const DATA_URL_PREFIX = /^data:application\/(?:pdf|octet-stream);base64,/i;
const MAX_BASE64_CHARS = Math.ceil(MAX_PDF_BYTES / 3) * 4;
// The PDF spec lets a file carry leading bytes before its header; readers
// (pdf.js included) look for it within the first kilobyte.
const SIGNATURE_WINDOW = 1024;
const SIGNATURE = [0x25, 0x50, 0x44, 0x46, 0x2d]; // "%PDF-"

function isArrayBuffer(value: unknown): value is ArrayBuffer {
  return Object.prototype.toString.call(value) === ARRAY_BUFFER_TAG;
}

function hasPdfSignature(bytes: Uint8Array): boolean {
  const limit = Math.min(bytes.length, SIGNATURE_WINDOW) - SIGNATURE.length;
  for (let start = 0; start <= limit; start += 1) {
    let matched = true;
    for (let index = 0; index < SIGNATURE.length; index += 1) {
      if (bytes[start + index] !== SIGNATURE[index]) {
        matched = false;
        break;
      }
    }
    if (matched) return true;
  }
  return false;
}

function checkBytes(input: Uint8Array): PdfBytesDecodeResult {
  if (input.byteLength === 0) return { ok: false, reason: "empty" };
  if (input.byteLength > MAX_PDF_BYTES) return { ok: false, reason: "oversized" };
  const bytes = Uint8Array.from(input);
  if (!hasPdfSignature(bytes)) return { ok: false, reason: "invalid_signature" };
  return { ok: true, bytes };
}

// Whitespace and a data-URL prefix can pad the text; this coarse bound
// rejects obviously oversized text before any normalisation copies it.
const MAX_BASE64_TEXT_CHARS = MAX_BASE64_CHARS * 2;

// A raw PDF body handed back as a string. One char per byte (latin-1 /
// binary string) is lossless only while it stays ASCII. Non-ASCII strings are
// ambiguous with UTF-8-decoded bytes, whose original bytes are already lost.
function decodeBinaryString(value: string): PdfBytesDecodeResult {
  if (value.length > MAX_PDF_BYTES) return { ok: false, reason: "oversized" };
  const bytes = new Uint8Array(value.length);
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code > 0x7f) return { ok: false, reason: "text_decoded" };
    bytes[index] = code;
  }
  return checkBytes(bytes);
}

function decodeBase64(value: string): PdfBytesDecodeResult {
  if (value.length > MAX_BASE64_TEXT_CHARS) return { ok: false, reason: "oversized" };
  const trimmed = value.trim();
  const payload = trimmed.replace(DATA_URL_PREFIX, "").replace(/\s+/g, "");
  if (payload.length === 0) return { ok: false, reason: "empty" };
  if (payload.length > MAX_BASE64_CHARS) return { ok: false, reason: "oversized" };
  if (!BASE64_TEXT.test(payload) || payload.length % 4 === 1) {
    if (!value.slice(0, SIGNATURE_WINDOW).includes("%PDF-")) {
      return { ok: false, reason: "unsupported_shape" };
    }
    return decodeBinaryString(value);
  }
  const padded = payload.padEnd(
    payload.length + ((4 - (payload.length % 4)) % 4),
    "=",
  );
  let decoded: string;
  try {
    decoded = atob(padded);
  } catch {
    return { ok: false, reason: "unsupported_shape" };
  }
  const bytes = new Uint8Array(decoded.length);
  for (let index = 0; index < decoded.length; index += 1) {
    bytes[index] = decoded.charCodeAt(index);
  }
  return checkBytes(bytes);
}

/**
 * Normalises a connector's file-content response into PDF bytes.
 *
 * Accepts what the generated connector methods return for a binary
 * response (declared `string`, bytes at run time): raw bytes, an `ArrayBuffer` or view,
 * base64 text, a `data:application/pdf;base64,` URL, the Power Platform
 * `{ "$content": "<base64>" }` file envelope, or an ASCII-only binary string.
 * A string text-decoded from the bytes (any non-ASCII character, including
 * U+FFFD) is refused as `text_decoded`. Every accepted value must
 * carry a `%PDF-` header within its first 1024 bytes and decode to at most
 * `MAX_PDF_BYTES`. The header check is a cheap shape gate, not validation:
 * pdf.js still decides whether the file opens.
 */
export function decodePdfBytes(value: unknown): PdfBytesDecodeResult {
  if (typeof value === "string") return decodeBase64(value);
  if (ArrayBuffer.isView(value)) {
    return checkBytes(
      new Uint8Array(value.buffer, value.byteOffset, value.byteLength),
    );
  }
  if (isArrayBuffer(value)) return checkBytes(new Uint8Array(value));
  if (
    value !== null &&
    typeof value === "object" &&
    typeof (value as { $content?: unknown }).$content === "string"
  ) {
    return decodeBase64((value as { $content: string }).$content);
  }
  return { ok: false, reason: "unsupported_shape" };
}
