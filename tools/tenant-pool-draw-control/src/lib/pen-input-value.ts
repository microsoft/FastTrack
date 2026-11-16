export const PEN_INPUT_MIME_TYPE = "image/png" as const;
export const DEFAULT_PEN_INPUT_MAX_BYTES = 512 * 1024;
export const MAX_PEN_INPUT_DIMENSION = 8192;
export const MAX_PEN_INPUT_PIXELS = 16 * 1024 * 1024;
export const MAX_PEN_INPUT_DECODED_BYTES = 4 * 1024 * 1024;
const PNG_DATA_URL_PREFIX = `data:${PEN_INPUT_MIME_TYPE};base64,`;

export interface PenInputValue {
  dataUrl: string;
  mimeType: typeof PEN_INPUT_MIME_TYPE;
  width: number;
  height: number;
  byteLength: number;
}

export class PenInputValueError extends Error {
  constructor(
    readonly code:
      | "invalid_data_url"
      | "invalid_limit"
      | "too_large"
      | "export_failed",
    message: string,
  ) {
    super(message);
    this.name = "PenInputValueError";
  }
}

function base64Payload(dataUrl: string): string {
  if (!dataUrl.startsWith(PNG_DATA_URL_PREFIX)) {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing is not a PNG image.",
    );
  }

  const payload = dataUrl.slice(PNG_DATA_URL_PREFIX.length);
  if (
    !payload ||
    !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(
      payload,
    )
  ) {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing contains invalid image data.",
    );
  }
  return payload;
}

export function penInputDataUrlByteLength(dataUrl: string): number {
  const payload = base64Payload(dataUrl);
  const padding = payload.endsWith("==") ? 2 : payload.endsWith("=") ? 1 : 0;
  return Math.floor((payload.length * 3) / 4) - padding;
}

function decodedDrawingBytes(dataUrl: string): Uint8Array {
  const payload = base64Payload(dataUrl);
  let binary: string;
  try {
    binary = atob(payload);
  } catch {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing contains invalid image data.",
    );
  }

  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

function assertValidMaxBytes(maxBytes: number): void {
  if (
    !Number.isFinite(maxBytes) ||
    maxBytes <= 0 ||
    maxBytes > DEFAULT_PEN_INPUT_MAX_BYTES
  ) {
    throw new PenInputValueError(
      "invalid_limit",
      `The drawing size limit must be a positive number no greater than ${DEFAULT_PEN_INPUT_MAX_BYTES.toLocaleString()} bytes.`,
    );
  }
}

function assertValidDimensions(width: number, height: number): void {
  if (
    !Number.isInteger(width) ||
    width <= 0 ||
    !Number.isInteger(height) ||
    height <= 0 ||
    width > MAX_PEN_INPUT_DIMENSION ||
    height > MAX_PEN_INPUT_DIMENSION ||
    width * height > MAX_PEN_INPUT_PIXELS
  ) {
    throw new PenInputValueError(
      "too_large",
      `The drawing canvas exceeds the supported ${MAX_PEN_INPUT_DIMENSION.toLocaleString()}-pixel edge or ${MAX_PEN_INPUT_PIXELS.toLocaleString()}-pixel area.`,
    );
  }
}

interface ScanlinePass {
  rows: number;
  rowBytes: number;
}

function scanlinePasses(
  width: number,
  height: number,
  bitsPerPixel: number,
  interlace: number,
): ScanlinePass[] {
  const passGeometry =
    interlace === 0
      ? [[0, 0, 1, 1]]
      : [
          [0, 0, 8, 8],
          [4, 0, 8, 8],
          [0, 4, 4, 8],
          [2, 0, 4, 4],
          [0, 2, 2, 4],
          [1, 0, 2, 2],
          [0, 1, 1, 2],
        ];
  return passGeometry.flatMap(([startX, startY, stepX, stepY]) => {
    const passWidth =
      width <= startX ? 0 : Math.ceil((width - startX) / stepX);
    const rows =
      height <= startY ? 0 : Math.ceil((height - startY) / stepY);
    return passWidth === 0 || rows === 0
      ? []
      : [{ rows, rowBytes: Math.ceil((passWidth * bitsPerPixel) / 8) }];
  });
}

function assertDecodedWorkLimit(
  width: number,
  height: number,
  bitDepth: number,
  colorType: number,
  interlace: number,
): void {
  const channels = colorType === 2 ? 3 : colorType === 4 ? 2 : colorType === 6 ? 4 : 1;
  const passes = scanlinePasses(
    width,
    height,
    channels * bitDepth,
    interlace,
  );
  const expectedLength = passes.reduce(
    (total, pass) => total + pass.rows * (pass.rowBytes + 1),
    0,
  );
  if (expectedLength > MAX_PEN_INPUT_DECODED_BYTES) {
    throw new PenInputValueError(
      "too_large",
      "The drawing canvas exceeds the supported 4 MiB decoded scanline limit.",
    );
  }
}

function pngDimensions(bytes: Uint8Array): {
  width: number;
  height: number;
} {
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (
    bytes.length < 33 ||
    !pngSignature.every((byte, index) => bytes[index] === byte)
  ) {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing is not a valid PNG image.",
    );
  }

  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let offset = 8;
  let dimensions: { width: number; height: number } | null = null;
  let colorType: number | null = null;
  let bitDepth: number | null = null;
  let interlace: number | null = null;
  let sawPalette = false;
  let sawImageData = false;
  let sawEnd = false;
  let imageDataEnded = false;
  while (offset + 12 <= bytes.length && !sawEnd) {
    const length = view.getUint32(offset);
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    const chunkEnd = dataEnd + 4;
    if (dataEnd < dataStart || chunkEnd > bytes.length) break;

    const type = String.fromCharCode(...bytes.slice(offset + 4, dataStart));
    if (!/^[A-Za-z]{4}$/.test(type)) break;
    let crc = 0xffffffff;
    for (let index = offset + 4; index < dataEnd; index += 1) {
      crc ^= bytes[index];
      for (let bit = 0; bit < 8; bit += 1) {
        crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
      }
    }
    if ((crc ^ 0xffffffff) >>> 0 !== view.getUint32(dataEnd)) break;

    if (offset === 8) {
      if (type !== "IHDR" || length !== 13) break;
      bitDepth = bytes[dataStart + 8];
      colorType = bytes[dataStart + 9];
      const validBitDepths: Record<number, readonly number[]> = {
        0: [1, 2, 4, 8, 16],
        2: [8, 16],
        3: [1, 2, 4, 8],
        4: [8, 16],
        6: [8, 16],
      };
      if (
        !validBitDepths[colorType]?.includes(bitDepth) ||
        bytes[dataStart + 10] !== 0 ||
        bytes[dataStart + 11] !== 0 ||
        ![0, 1].includes(bytes[dataStart + 12])
      ) {
        break;
      }
      dimensions = {
        width: view.getUint32(dataStart),
        height: view.getUint32(dataStart + 4),
      };
      interlace = bytes[dataStart + 12];
    } else if (type === "IHDR") {
      break;
    } else if (type === "PLTE") {
      if (
        sawPalette ||
        sawImageData ||
        length === 0 ||
        length % 3 !== 0 ||
        length > 768 ||
        (colorType === 3 && length / 3 > 2 ** bitDepth!) ||
        colorType === 0 ||
        colorType === 4
      ) {
        break;
      }
      sawPalette = true;
    } else if (type === "IDAT") {
      if (imageDataEnded || (colorType === 3 && !sawPalette)) break;
      sawImageData = true;
    } else if (type === "IEND") {
      if (length !== 0 || !sawImageData) break;
      sawEnd = true;
    } else {
      if ((bytes[offset + 4] & 0x20) === 0) break;
      if (sawImageData) imageDataEnded = true;
    }
    offset = chunkEnd;
  }

  if (!dimensions || !sawImageData || !sawEnd || offset !== bytes.length) {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing is not a valid PNG image.",
    );
  }
  try {
    assertValidDimensions(dimensions.width, dimensions.height);
    assertDecodedWorkLimit(
      dimensions.width,
      dimensions.height,
      bitDepth!,
      colorType!,
      interlace!,
    );
  } catch (error) {
    if (error instanceof PenInputValueError) throw error;
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing is not a valid PNG image.",
    );
  }
  return dimensions;
}

export function validatePenInputValue(
  value: PenInputValue,
  maxBytes = DEFAULT_PEN_INPUT_MAX_BYTES,
): void {
  assertValidMaxBytes(maxBytes);
  const maximumDataUrlLength =
    PNG_DATA_URL_PREFIX.length + 4 * Math.ceil(maxBytes / 3);
  if (value.dataUrl.length > maximumDataUrlLength) {
    throw new PenInputValueError(
      "too_large",
      `The drawing is too large. Clear it and use fewer strokes (maximum ${maxBytes.toLocaleString()} bytes).`,
    );
  }
  const encodedByteLength = penInputDataUrlByteLength(value.dataUrl);
  if (encodedByteLength > maxBytes) {
    throw new PenInputValueError(
      "too_large",
      `The drawing is too large. Clear it and use fewer strokes (maximum ${maxBytes.toLocaleString()} bytes).`,
    );
  }

  const bytes = decodedDrawingBytes(value.dataUrl);
  const dimensions = pngDimensions(bytes);
  assertValidDimensions(value.width, value.height);
  if (
    value.mimeType !== PEN_INPUT_MIME_TYPE ||
    value.byteLength !== bytes.byteLength ||
    value.width !== dimensions.width ||
    value.height !== dimensions.height
  ) {
    throw new PenInputValueError(
      "invalid_data_url",
      "The captured drawing metadata does not match its image data.",
    );
  }
}

export function penInputValueFromCanvas(
  canvas: HTMLCanvasElement,
  maxBytes = DEFAULT_PEN_INPUT_MAX_BYTES,
): PenInputValue {
  assertValidMaxBytes(maxBytes);
  assertValidDimensions(canvas.width, canvas.height);

  let dataUrl: string;
  try {
    dataUrl = canvas.toDataURL(PEN_INPUT_MIME_TYPE);
  } catch {
    throw new PenInputValueError(
      "export_failed",
      "The drawing could not be prepared. Clear it and try again.",
    );
  }

  const byteLength = penInputDataUrlByteLength(dataUrl);
  if (byteLength > maxBytes) {
    throw new PenInputValueError(
      "too_large",
      `The drawing is too large. Clear it and use fewer strokes (maximum ${maxBytes.toLocaleString()} bytes).`,
    );
  }

  const value: PenInputValue = {
    dataUrl,
    mimeType: PEN_INPUT_MIME_TYPE,
    width: canvas.width,
    height: canvas.height,
    byteLength,
  };
  validatePenInputValue(value, maxBytes);
  return value;
}

export function penInputValueToBlob(value: PenInputValue): Blob {
  validatePenInputValue(value, DEFAULT_PEN_INPUT_MAX_BYTES);
  const bytes = decodedDrawingBytes(value.dataUrl);
  return new Blob([bytes], { type: PEN_INPUT_MIME_TYPE });
}
