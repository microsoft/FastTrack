/*!
 * Copyright (C) Microsoft Corporation. All rights reserved.
 */

// The ONLY module allowed to import `three/*` subpaths such as the loaders
// (eslint enforces it). Generated apps show model files with <ModelViewer>
// from @/components/model-viewer instead of wiring loaders themselves.
//
// three is loaded with a dynamic import. The build inlines dynamic imports
// into one bundle and tree-shakes three's ES modules, so an app that imports
// the viewer carries the renderer, one camera, two lights, a generated
// room environment for reflections, the orbit controls and the glTF/OBJ/STL
// loaders; an app that does not carries none of it.
//
// A model is drawn with its own materials, as the platform's 3D control does.
// Only geometry that carries no color at all (an OBJ without vertex colors,
// since its .mtl is a separate file the viewer refuses; an STL without
// per-face colors) gets the blue default material, whose color the
// `color` option sets.
//
// Compressed glTF (Draco, meshopt, KTX2/Basis) is refused up front: each one
// needs a WebAssembly decoder, and a published app's CSP is
// `script-src 'self'`, which forbids compiling WebAssembly.

export const MODEL_FORMATS = ["glb", "gltf", "obj", "stl"] as const;
export type ModelFormat = (typeof MODEL_FORMATS)[number];

/** The largest model the viewer loads: 10 MiB. */
export const MAX_MODEL_BYTES = 10 * 1024 * 1024;

/** How long a download may go without receiving a byte before it fails. */
export const MODEL_READ_IDLE_MS = 15_000;

/** How long a whole download (headers and body) may take before it fails. */
export const MODEL_DOWNLOAD_TIMEOUT_MS = 60_000;

/** Where a model comes from: a picked file, raw bytes, or an https URL. */
export type ModelSource = File | Blob | ArrayBuffer | Uint8Array | string;

export type ModelErrorCode =
  | "unsupported-format"
  | "too-large"
  | "compressed"
  | "external-resources"
  | "unsafe-url"
  | "fetch-failed"
  | "read-failed"
  | "parse-failed"
  | "webgl-unavailable"
  | "viewer-load-failed";

export class ModelLoadError extends Error {
  readonly code: ModelErrorCode;
  constructor(code: ModelErrorCode, message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "ModelLoadError";
    this.code = code;
  }
}

/** The friendly sentence the viewer shows for each failure. */
export function modelErrorMessage(code: ModelErrorCode): string {
  switch (code) {
    case "unsupported-format":
      return "That file isn't a supported 3D model — use .glb, .gltf, .obj or .stl.";
    case "too-large":
      return "That model is too large — choose one under 10MB.";
    case "compressed":
      return "That model uses compression this viewer can't open — export it without Draco, meshopt or KTX2.";
    case "external-resources":
      return "That model points to separate files the viewer can't load — export it as a single .glb.";
    case "unsafe-url":
      return "That model link isn't a web address the viewer can open.";
    case "fetch-failed":
      return "Couldn't download that model. Check the link and try again.";
    case "read-failed":
      return "Couldn't open that file.";
    case "parse-failed":
      return "Couldn't read that model. The file may be damaged.";
    case "webgl-unavailable":
      return "This device can't display 3D content.";
    case "viewer-load-failed":
      return "The 3D viewer couldn't load. Reload the page and try again.";
  }
}

const COMPRESSED_EXTENSIONS = [
  "KHR_draco_mesh_compression",
  "EXT_meshopt_compression",
  "KHR_texture_basisu",
] as const;

const GLB_MAGIC = 0x46546c67; // "glTF" little-endian
const GLB_JSON_CHUNK = 0x4e4f534a; // "JSON"

function isGlb(bytes: Uint8Array): boolean {
  if (bytes.byteLength < 12) return false;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return view.getUint32(0, true) === GLB_MAGIC;
}

function isBinaryStl(bytes: Uint8Array): boolean {
  if (bytes.byteLength < 84) return false;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const triangles = view.getUint32(80, true);
  return bytes.byteLength === 84 + triangles * 50;
}

function leadingText(bytes: Uint8Array, length = 256): string {
  return new TextDecoder("utf-8", { fatal: false })
    .decode(bytes.subarray(0, Math.min(length, bytes.byteLength)))
    .replace(/^\uFEFF/, "")
    .trimStart();
}

function extensionOf(name: string | undefined): string {
  if (!name) return "";
  const path = name.split(/[?#]/, 1)[0] ?? "";
  const slash = path.lastIndexOf("/");
  const dot = path.lastIndexOf(".");
  return dot <= slash ? "" : path.slice(dot + 1).toLowerCase();
}

/**
 * Works out which loader reads `bytes`. Content wins over the name: a GLB
 * header or an exact binary-STL length decides on its own; otherwise the
 * file extension decides. A name with any other extension is refused; only
 * a name with no extension falls back to sniffing text content.
 */
export function detectModelFormat(
  name: string | undefined,
  bytes: Uint8Array,
): ModelFormat | null {
  if (isGlb(bytes)) return "glb";
  if (isBinaryStl(bytes)) return "stl";
  const ext = extensionOf(name);
  if ((MODEL_FORMATS as readonly string[]).includes(ext)) return ext as ModelFormat;
  if (ext !== "") return null;
  const head = leadingText(bytes);
  if (head.startsWith("{")) return "gltf";
  if (/^solid\s/.test(head)) return "stl";
  if (/^(v\s|vn\s|vt\s|o\s|g\s|f\s|mtllib\s)/m.test(head)) return "obj";
  return null;
}

export type ModelBytesFailure =
  | "empty"
  | "oversized"
  | "text_decoded"
  | "unsupported_format"
  | "unsupported_shape";

export type ModelBytesDecodeResult =
  | { ok: true; bytes: Uint8Array<ArrayBuffer>; format: ModelFormat }
  | { ok: false; reason: ModelBytesFailure };

const MAX_MODEL_BASE64_CHARS = Math.ceil(MAX_MODEL_BYTES / 3) * 4;
// Line wrapping and a data-URL prefix can pad base64; this coarse bound
// refuses obviously oversized text before any normalisation copies it.
const MAX_MODEL_TEXT_CHARS = MAX_MODEL_BASE64_CHARS * 2;
const MODEL_DATA_URL = /^data:(?:[a-z0-9.+-]+\/[a-z0-9.+-]+)?(?:;[^,;]*)*;base64,/i;
// Base64 as connectors return it (applied to trimmed text): no spaces or
// tabs, optional line breaks. Text model formats (OBJ, glTF JSON) always
// contain a space or a brace, so they never match; ASCII STL is checked
// for its `solid` header first.
const MODEL_BASE64_TEXT = /^[A-Za-z0-9+/\r\n]*={0,2}$/;

function checkModelBytes(
  input: Uint8Array,
  name: string | undefined,
): ModelBytesDecodeResult {
  if (input.byteLength === 0) return { ok: false, reason: "empty" };
  if (input.byteLength > MAX_MODEL_BYTES) return { ok: false, reason: "oversized" };
  const bytes = Uint8Array.from(input);
  // No model format starts with `<`: an HTML sign-in or error page is not a
  // model whatever the file name says.
  if (!isGlb(bytes) && !isBinaryStl(bytes) && leadingText(bytes, 64).startsWith("<")) {
    return { ok: false, reason: "unsupported_format" };
  }
  const format = detectModelFormat(name, bytes);
  if (!format) return { ok: false, reason: "unsupported_format" };
  return { ok: true, bytes, format };
}

function decodeModelBase64(
  payload: string,
  name: string | undefined,
): ModelBytesDecodeResult {
  const compact = payload.replace(/\s+/g, "");
  if (compact.length === 0) return { ok: false, reason: "empty" };
  if (compact.length > MAX_MODEL_BASE64_CHARS) return { ok: false, reason: "oversized" };
  if (compact.length % 4 === 1) return { ok: false, reason: "unsupported_shape" };
  let decoded: string;
  try {
    decoded = atob(compact.padEnd(compact.length + ((4 - (compact.length % 4)) % 4), "="));
  } catch {
    return { ok: false, reason: "unsupported_shape" };
  }
  const bytes = new Uint8Array(decoded.length);
  for (let index = 0; index < decoded.length; index += 1) {
    bytes[index] = decoded.charCodeAt(index);
  }
  return checkModelBytes(bytes, name);
}

function decodeModelString(
  value: string,
  name: string | undefined,
): ModelBytesDecodeResult {
  if (value.length > MAX_MODEL_TEXT_CHARS) return { ok: false, reason: "oversized" };
  const trimmed = value.trim();
  if (trimmed.length === 0) return { ok: false, reason: "empty" };
  const dataUrl = MODEL_DATA_URL.exec(trimmed);
  if (dataUrl) return decodeModelBase64(trimmed.slice(dataUrl[0].length), name);
  if (/^data:/i.test(trimmed) || /^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed)) {
    return { ok: false, reason: "unsupported_shape" };
  }
  const asciiStl = /^solid\s/.test(trimmed);
  if (!asciiStl && MODEL_BASE64_TEXT.test(trimmed)) return decodeModelBase64(trimmed, name);
  // A binary body text-decoded on the way here: its bytes are already lost.
  if (trimmed.startsWith("glTF") || trimmed.includes("\uFFFD")) {
    return { ok: false, reason: "text_decoded" };
  }
  // A text model (OBJ, ASCII STL, glTF JSON) handed back as the file's text.
  if (value.length > MAX_MODEL_BYTES) return { ok: false, reason: "oversized" };
  const result = checkModelBytes(new TextEncoder().encode(value), name);
  // An STL that arrives as text must be ASCII STL; anything else was binary.
  if (result.ok && result.format === "stl" && !asciiStl) {
    return { ok: false, reason: "text_decoded" };
  }
  return result;
}

/**
 * Normalises a connector's file-content response (OneDrive, SharePoint,
 * Dataverse file column) into bytes `<ModelViewer>` can load, and names the
 * loader. Accepts raw bytes, an `ArrayBuffer` or view, base64 text, a
 * `data:…;base64,` URL, the Power Platform `{ "$content": "<base64>" }` or
 * Graph `{ "contentBytes": "<base64>" }` file envelope, or the file's own text for OBJ, ASCII STL and glTF JSON. Pass the
 * file's name (or just its extension, e.g. `"model.obj"`) when you know it.
 * Never throws; a failure names why. Accepted bytes are a private copy of at
 * most `MAX_MODEL_BYTES`.
 */
export function decodeModelBytes(
  value: unknown,
  name?: string,
): ModelBytesDecodeResult {
  if (typeof value === "string") return decodeModelString(value, name);
  if (ArrayBuffer.isView(value)) {
    return checkModelBytes(
      new Uint8Array(value.buffer, value.byteOffset, value.byteLength),
      name,
    );
  }
  if (Object.prototype.toString.call(value) === "[object ArrayBuffer]") {
    return checkModelBytes(new Uint8Array(value as ArrayBuffer), name);
  }
  if (value !== null && typeof value === "object") {
    const envelope = value as { $content?: unknown; contentBytes?: unknown };
    if (typeof envelope.$content === "string") return decodeModelString(envelope.$content, name);
    if (typeof envelope.contentBytes === "string") {
      return decodeModelString(envelope.contentBytes, name);
    }
  }
  return { ok: false, reason: "unsupported_shape" };
}

function glbJson(bytes: Uint8Array): string | null {
  if (bytes.byteLength < 20) return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const chunkLength = view.getUint32(12, true);
  const chunkType = view.getUint32(16, true);
  if (chunkType !== GLB_JSON_CHUNK || 20 + chunkLength > bytes.byteLength) {
    return null;
  }
  return new TextDecoder().decode(bytes.subarray(20, 20 + chunkLength));
}

/**
 * True when a buffer or image (the only glTF 2.0 objects the loader fetches
 * by `uri`) points at anything but an embedded `data:` URI. A `uri` under
 * `extras` or an extension is app data the loader never fetches.
 */
function hasExternalUri(json: { buffers?: unknown; images?: unknown }): boolean {
  const external = (list: unknown) =>
    Array.isArray(list) &&
    list.some((entry: unknown) => {
      const uri = (entry as { uri?: unknown } | null)?.uri;
      return typeof uri === "string" && !/^data:/i.test(uri);
    });
  return external(json.buffers) || external(json.images);
}

/**
 * Throws `compressed` when a glTF/GLB declares an extension whose decoder
 * needs WebAssembly, and `external-resources` when any `uri` in it points at
 * a separate file (the loader would fetch it relative to the app). Embedded
 * `data:` URIs and GLB's own binary chunk pass. OBJ and STL carry no
 * extensions and always pass.
 */
export function assertNoCompressedExtensions(
  bytes: Uint8Array,
  format: ModelFormat,
): void {
  if (format !== "glb" && format !== "gltf") return;
  const text = format === "glb" ? glbJson(bytes) : new TextDecoder().decode(bytes);
  if (text === null) throw new ModelLoadError("parse-failed", "GLB has no JSON chunk");
  let json: {
    extensionsUsed?: unknown;
    extensionsRequired?: unknown;
    buffers?: unknown;
    images?: unknown;
  };
  try {
    json = JSON.parse(text) as typeof json;
  } catch {
    throw new ModelLoadError("parse-failed", "glTF JSON is not valid");
  }
  if (json === null || typeof json !== "object" || Array.isArray(json)) {
    throw new ModelLoadError("parse-failed", "glTF JSON root is not an object");
  }
  const declared = new Set<unknown>([
    ...(Array.isArray(json.extensionsUsed) ? json.extensionsUsed : []),
    ...(Array.isArray(json.extensionsRequired) ? json.extensionsRequired : []),
  ]);
  const hit = COMPRESSED_EXTENSIONS.find((ext) => declared.has(ext));
  if (hit) throw new ModelLoadError("compressed", `glTF declares ${hit}`);
  if (hasExternalUri(json)) {
    throw new ModelLoadError("external-resources", "glTF references an external file");
  }
}

/**
 * Returns the source as a URL only when it is an absolute https URL.
 * `http:`, `blob:`, `data:`, `javascript:` and relative paths are refused:
 * pass a File or bytes for local content instead.
 */
export function toSafeModelUrl(value: string): URL | null {
  let url: URL;
  try {
    url = new URL(value.trim());
  } catch {
    return null;
  }
  return url.protocol === "https:" ? url : null;
}

export interface ModelBytes {
  bytes: Uint8Array;
  name: string | undefined;
}

function checkSize(length: number): void {
  if (length > MAX_MODEL_BYTES) {
    throw new ModelLoadError("too-large", `model is ${length} bytes`);
  }
}

const IDLE = Symbol("idle");

/**
 * Reads a response body, stopping as soon as it passes the size cap, goes
 * `MODEL_READ_IDLE_MS` without delivering a chunk, or `deadline` rejects.
 */
async function readCappedBody(response: Response, deadline: Promise<never>): Promise<Uint8Array> {
  if (!response.body) {
    const buffer = await Promise.race([response.arrayBuffer(), deadline]);
    checkSize(buffer.byteLength);
    return new Uint8Array(buffer);
  }
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const idle = new Promise<typeof IDLE>((resolve) => {
      timer = setTimeout(() => resolve(IDLE), MODEL_READ_IDLE_MS);
    });
    let result: ReadableStreamReadResult<Uint8Array> | typeof IDLE;
    try {
      result = await Promise.race([reader.read(), idle, deadline]);
    } catch (error) {
      await reader.cancel().catch(() => undefined);
      throw error;
    } finally {
      clearTimeout(timer);
    }
    if (result === IDLE) {
      await reader.cancel().catch(() => undefined);
      throw new ModelLoadError("fetch-failed", "model download stalled");
    }
    if (result.done) break;
    total += result.value.byteLength;
    if (total > MAX_MODEL_BYTES) {
      await reader.cancel().catch(() => undefined);
      checkSize(total);
    }
    chunks.push(result.value);
  }
  if (chunks.length === 1) return chunks[0]!;
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

/**
 * Downloads an https model, failing with `fetch-failed` when the whole
 * download (headers and body) outlasts `MODEL_DOWNLOAD_TIMEOUT_MS`. An abort
 * of `signal` is rethrown as is.
 */
async function downloadModel(url: URL, signal: AbortSignal | undefined): Promise<Uint8Array> {
  const controller = new AbortController();
  const forward = () => controller.abort(signal?.reason);
  if (signal?.aborted) forward();
  else signal?.addEventListener("abort", forward, { once: true });
  let timer: ReturnType<typeof setTimeout> | undefined;
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      reject(new ModelLoadError("fetch-failed", "model download timed out"));
      controller.abort();
    }, MODEL_DOWNLOAD_TIMEOUT_MS);
  });
  deadline.catch(() => undefined);
  try {
    let response: Response;
    try {
      response = await Promise.race([
        fetch(url, { signal: controller.signal, credentials: "omit" }),
        deadline,
      ]);
    } catch (error) {
      if (error instanceof ModelLoadError || signal?.aborted) throw error;
      throw new ModelLoadError("fetch-failed", "model download failed");
    }
    if (!response.ok) {
      await response.body?.cancel().catch(() => undefined);
      throw new ModelLoadError("fetch-failed", `model download returned ${response.status}`);
    }
    if (response.url) {
      const finalUrl = toSafeModelUrl(response.url);
      if (!finalUrl) {
        await response.body?.cancel().catch(() => undefined);
        throw new ModelLoadError("unsafe-url", "model download redirected outside https");
      }
    }
    const declared = Number(response.headers.get("content-length"));
    if (Number.isFinite(declared) && declared > MAX_MODEL_BYTES) {
      await response.body?.cancel().catch(() => undefined);
      checkSize(declared);
    }
    try {
      return await readCappedBody(response, deadline);
    } catch (error) {
      if (error instanceof ModelLoadError || signal?.aborted) throw error;
      throw new ModelLoadError("fetch-failed", "model download was interrupted");
    }
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", forward);
  }
}

/** Reads any ModelSource into bytes, enforcing the size cap before parsing. */
export async function readModelSource(
  source: ModelSource,
  signal?: AbortSignal,
): Promise<ModelBytes> {
  if (typeof source === "string") {
    const url = toSafeModelUrl(source);
    if (!url) throw new ModelLoadError("unsafe-url", "model source is not https");
    return { bytes: await downloadModel(url, signal), name: url.pathname };
  }
  if (source instanceof Uint8Array) {
    checkSize(source.byteLength);
    return { bytes: source, name: undefined };
  }
  if (source instanceof ArrayBuffer) {
    checkSize(source.byteLength);
    return { bytes: new Uint8Array(source), name: undefined };
  }
  checkSize(source.size);
  const name = "name" in source && typeof source.name === "string" ? source.name : undefined;
  let buffer: ArrayBuffer;
  try {
    buffer = await source.arrayBuffer();
  } catch {
    throw new ModelLoadError("read-failed", "the file could not be read");
  }
  return { bytes: new Uint8Array(buffer), name };
}

async function importThree() {
  const [
    three,
    { OrbitControls },
    { GLTFLoader },
    { OBJLoader },
    { STLLoader },
    { RoomEnvironment },
  ] = await Promise.all([
    import("three"),
    import("three/examples/jsm/controls/OrbitControls.js"),
    import("three/examples/jsm/loaders/GLTFLoader.js"),
    import("three/examples/jsm/loaders/OBJLoader.js"),
    import("three/examples/jsm/loaders/STLLoader.js"),
    import("three/examples/jsm/environments/RoomEnvironment.js"),
  ]);
  return { three, OrbitControls, GLTFLoader, OBJLoader, STLLoader, RoomEnvironment };
}

type Three = Awaited<ReturnType<typeof importThree>>;

/**
 * Runs `load` once and shares its result; a rejection becomes
 * `viewer-load-failed` and is not cached, so the next call tries again.
 */
export function retryingImport<T>(load: () => Promise<T>): () => Promise<T> {
  let cached: Promise<T> | undefined;
  return () => {
    if (!cached) {
      const attempt = load().catch((error): never => {
        if (cached === attempt) cached = undefined;
        throw new ModelLoadError("viewer-load-failed", "three.js could not be loaded", {
          cause: error,
        });
      });
      cached = attempt;
    }
    return cached;
  };
}

/** Loads three and its loaders once; a failed import is retried on the next call. */
export const loadThree = retryingImport(importThree);

/** What `show` reports about the model it displayed. */
export interface ModelStats {
  /** Number of meshes in the model. */
  meshes: number;
  /** Number of triangles across all meshes. */
  triangles: number;
  /** Axis-aligned bounding-box size, in the model's own units. */
  size: { x: number; y: number; z: number };
}

/** A live viewer: one renderer, one scene, at most one loaded model. */
export interface ModelStage {
  /**
   * Replaces the current model; resolves with its stats. When
   * `isCurrent` reports false before or after parsing, the parsed model is
   * discarded, the scene is left untouched and the call resolves `null`.
   */
  show(
    bytes: Uint8Array,
    format: ModelFormat,
    isCurrent?: () => boolean,
  ): Promise<ModelStats | null>;
  /**
   * Replaces the current model with a built-in, multi-coloured sample (a
   * toy car) drawn without any download; resolves like `show`.
   */
  showSample(isCurrent?: () => boolean): Promise<ModelStats | null>;
  /** Draws every mesh, current and later, as wireframe when `on`. */
  setWireframe(on: boolean): void;
  /**
   * Sets the color of the default material, which only geometry with no
   * color of its own uses; `undefined` restores `DEFAULT_MODEL_COLOR`. A CSS
   * color string; one three.js cannot parse leaves the color unchanged.
   */
  setColor(color: string | undefined): void;
  /** Turns the camera slowly around the model when `on`. */
  setAutoRotate(on: boolean): void;
  /** Applies one keyboard step to the camera; counts as user interaction. */
  nudge(command: ViewCommand): void;
  /** Clears the current model. */
  clear(): void;
  /**
   * Re-fits the drawing buffer after the canvas changes size. The model is
   * re-framed only until the user first moves the camera, so their zoom and
   * pan survive a resize.
   */
  resize(): void;
  dispose(): void;
}

/** The color of geometry that has none of its own: a saturated blue, never a flat gray. */
export const DEFAULT_MODEL_COLOR = "#2f7de1";

function exactBuffer(bytes: Uint8Array): ArrayBuffer {
  if (bytes.byteOffset === 0 && bytes.byteLength === bytes.buffer.byteLength) {
    return bytes.buffer as ArrayBuffer;
  }
  return bytes.slice().buffer;
}

/**
 * A GLTFLoader plugin that decodes a GLB's embedded images straight from their
 * bytes. GLTFLoader's own path wraps each image in a `blob:` URL and fetches it,
 * which a host page's Content-Security-Policy can refuse, leaving every texture
 * blank and the model white.
 */
interface EmbeddedImageDef {
  bufferView?: number;
  mimeType?: string;
  extras?: unknown;
}

interface ImageSourceParser {
  json: { images?: EmbeddedImageDef[] };
  sourceCache: Record<number, Promise<{ clone(): unknown }>>;
  getDependency(type: string, index: number): Promise<unknown>;
  loadImageSource(sourceIndex: number, loader: unknown): Promise<unknown>;
}

function embeddedImagePlugin(T: Three["three"]) {
  return (gltfParser: unknown) => {
    const parser = gltfParser as ImageSourceParser;
    const original = parser.loadImageSource.bind(parser);
    parser.loadImageSource = (sourceIndex: number, loader: unknown) => {
      const sourceDef = parser.json.images?.[sourceIndex];
      if (
        sourceDef?.bufferView === undefined ||
        typeof createImageBitmap === "undefined"
      ) {
        return original(sourceIndex, loader);
      }
      const cached = parser.sourceCache[sourceIndex];
      if (cached !== undefined) {
        return cached.then((t) => t.clone());
      }
      const promise = parser
        .getDependency("bufferView", sourceDef.bufferView)
        .then((view) =>
          createImageBitmap(new Blob([view as ArrayBuffer], { type: sourceDef.mimeType }), {
            premultiplyAlpha: "none",
            colorSpaceConversion: "none",
          }),
        )
        .then((bitmap) => {
          const texture = new T.Texture(bitmap);
          texture.needsUpdate = true;
          if (sourceDef.extras && typeof sourceDef.extras === "object") {
            Object.assign(texture.userData, sourceDef.extras);
          }
          texture.userData.mimeType = sourceDef.mimeType;
          return texture;
        });
      parser.sourceCache[sourceIndex] = promise;
      return promise;
    };
    return { name: "AETHER_embedded_images" };
  };
}

interface StylableColor<C> {
  setStyle(style: string): C;
  equals(other: C): boolean;
}

/**
 * Parses a CSS color with three.js's `Color`, or returns null when it cannot.
 * `setStyle` leaves the color unchanged on input it cannot parse, so the
 * string is applied to a black and a white probe: only a parsed color makes
 * them equal. Every color, black and white included, parses the same way.
 */
export function parseModelColor<C extends StylableColor<C>>(
  makeColor: (r: number, g: number, b: number) => C,
  color: string,
): C | null {
  const fromBlack = makeColor(0, 0, 0).setStyle(color);
  const fromWhite = makeColor(1, 1, 1).setStyle(color);
  return fromBlack.equals(fromWhite) ? fromBlack : null;
}

/**
 * Browsers cap live WebGL contexts per page, so a disposed stage on a detached
 * canvas releases its context now. A canvas still in the document is being
 * reused (React StrictMode's effect replay builds a second stage on it), and
 * its context belongs to that newer stage.
 */
export function releaseWebGLContext(
  renderer: { forceContextLoss(): void },
  canvas: { isConnected: boolean },
): void {
  if (!canvas.isConnected) renderer.forceContextLoss();
}

/** The loader may only resolve resources embedded in the model itself. */
export function isEmbeddedResourceUrl(url: string): boolean {
  return /^(?:data|blob):/i.test(url);
}

/** Skinned meshes can share one skeleton, whose bone texture is freed once. */
export function disposeSkeletons(root: { traverse(visit: (node: object) => void): void }): void {
  const skeletons = new Set<{ dispose(): void }>();
  root.traverse((node) => {
    const { skeleton } = node as { skeleton?: { dispose(): void } };
    if (skeleton) skeletons.add(skeleton);
  });
  skeletons.forEach((skeleton) => skeleton.dispose());
}

/** Anything a model's content makes the viewer throw is reported as a damaged model. */
export function asParseFailure(error: unknown, message: string): ModelLoadError {
  if (error instanceof ModelLoadError) return error;
  return new ModelLoadError("parse-failed", message, { cause: error });
}

interface AutoRotateState {
  requested: boolean;
  stoppedByUser: boolean;
}

export function autoRotateAfterProp(state: AutoRotateState, requested: boolean): boolean {
  if (state.requested !== requested) {
    state.requested = requested;
    state.stoppedByUser = false;
  }
  return state.requested && !state.stoppedByUser;
}

export function autoRotateAfterUserInteraction(state: AutoRotateState): boolean {
  if (state.requested) state.stoppedByUser = true;
  return state.requested && !state.stoppedByUser;
}

/** One keyboard step for the camera: orbit by radians, or dolly by a distance factor. */
export type ViewCommand =
  | { kind: "orbit"; left: number; up: number }
  | { kind: "zoom"; factor: number };

/** Radians one arrow-key press orbits the camera. */
export const KEY_ORBIT_STEP = Math.PI / 24;
/** Distance factor one `+` press applies; `-` applies its inverse. */
export const KEY_ZOOM_STEP = 0.85;
/** Pixels a pressed pointer must travel before the press counts as a drag. */
const DRAG_PX = 3;

/** Maps a `KeyboardEvent.key` to a camera step; any other key is `null`. */
export function viewCommandForKey(key: string): ViewCommand | null {
  switch (key) {
    case "ArrowLeft":
      return { kind: "orbit", left: KEY_ORBIT_STEP, up: 0 };
    case "ArrowRight":
      return { kind: "orbit", left: -KEY_ORBIT_STEP, up: 0 };
    case "ArrowUp":
      return { kind: "orbit", left: 0, up: KEY_ORBIT_STEP };
    case "ArrowDown":
      return { kind: "orbit", left: 0, up: -KEY_ORBIT_STEP };
    case "+":
    case "=":
      return { kind: "zoom", factor: KEY_ZOOM_STEP };
    case "-":
    case "_":
      return { kind: "zoom", factor: 1 / KEY_ZOOM_STEP };
    default:
      return null;
  }
}

function sourceBytes(source: ModelSource): Uint8Array | null {
  try {
    if (source instanceof Uint8Array) return source;
    if (source instanceof ArrayBuffer) return new Uint8Array(source);
  } catch {
    return null;
  }
  return null;
}

/**
 * A private copy of accepted-size bytes for `sameModelSource` to compare
 * later sources against, and for the viewer to load, so a caller that
 * rewrites the buffer it passed in can neither hide a new model nor change
 * the one being parsed. Other sources, and bytes it cannot copy, come back
 * as they are.
 */
export function snapshotModelSource<S extends ModelSource | null | undefined>(source: S): S {
  if (source == null || typeof source === "string") return source;
  const bytes = sourceBytes(source);
  if (!bytes || bytes.byteLength > MAX_MODEL_BYTES) return source;
  try {
    return bytes.slice() as S;
  } catch {
    return source;
  }
}

/**
 * Whether two `source` values name the same model, so a parent that builds
 * a new `Uint8Array` object on every render does not reload it. Strings
 * compare by value, accepted-size bytes by content, and `File` or bare `Blob`
 * objects only equal themselves.
 */
export function sameModelSource(
  a: ModelSource | null | undefined,
  b: ModelSource | null | undefined,
): boolean {
  if (a === b) return true;
  if (a == null || b == null || typeof a === "string" || typeof b === "string") return false;
  if (
    typeof File !== "undefined" &&
    (a instanceof File || b instanceof File)
  ) {
    return false;
  }
  const x = sourceBytes(a);
  const y = sourceBytes(b);
  if (!x || !y || x.byteLength !== y.byteLength) return false;
  // Both would be refused as too-large, so a reload could only repeat the
  // failure; skip the scan and keep the viewer on its error.
  if (x.byteLength > MAX_MODEL_BYTES) return true;
  for (let i = 0; i < x.byteLength; i += 1) {
    if (x[i] !== y[i]) return false;
  }
  return true;
}

/**
 * Frees what a half-built stage holds: every resource (each attempted even
 * when another throws), the renderer, and its context when the canvas has
 * left the page. A canvas still on the page keeps its context for the retry.
 */
export function abandonStage(
  resources: readonly { dispose(): void }[],
  renderer: { dispose(): void; forceContextLoss(): void },
  canvas: { isConnected: boolean },
): void {
  for (const resource of resources) {
    try {
      resource.dispose();
    } catch {
      // Keep releasing the rest; the setup error is what the caller reports.
    }
  }
  try {
    renderer.dispose();
  } catch {
    // Preserve the setup error; cleanup is best-effort.
  }
  try {
    releaseWebGLContext(renderer, canvas);
  } catch {
    // Preserve the setup error; cleanup is best-effort.
  }
}

/**
 * Creates the renderer, camera, lights and controls on `canvas` and starts
 * rendering. If setup fails after the renderer exists, everything built so
 * far is released before the error propagates. `engine` is a test seam.
 */
export async function createModelStage(
  canvas: HTMLCanvasElement,
  engine: () => Promise<Three> = loadThree,
): Promise<ModelStage> {
  const modules = await engine();
  const T = modules.three;
  let renderer: InstanceType<typeof T.WebGLRenderer>;
  try {
    renderer = new T.WebGLRenderer({ canvas, alpha: true, antialias: true });
  } catch {
    throw new ModelLoadError("webgl-unavailable", "WebGL context could not be created");
  }
  const built: { dispose(): void }[] = [];
  try {
    return buildStage(canvas, modules, renderer, built);
  } catch (error) {
    abandonStage(built, renderer, canvas);
    throw error instanceof ModelLoadError
      ? error
      : new ModelLoadError("viewer-load-failed", "the 3D viewer could not be set up", {
          cause: error,
        });
  }
}

function buildStage(
  canvas: HTMLCanvasElement,
  { three: T, OrbitControls, GLTFLoader, OBJLoader, STLLoader, RoomEnvironment }: Three,
  renderer: InstanceType<Three["three"]["WebGLRenderer"]>,
  built: { dispose(): void }[],
): ModelStage {
  renderer.setClearColor(0x000000, 0);
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;

  const scene = new T.Scene();
  // A generated room lights metallic and glossy materials, which direct
  // lights alone leave near black.
  const pmrem = new T.PMREMGenerator(renderer);
  built.push(pmrem);
  const environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
  built.push(environment);
  scene.environment = environment;
  const camera = new T.PerspectiveCamera(45, 1, 0.01, 1000);
  camera.position.set(2, 1.5, 2);
  const key = new T.DirectionalLight(0xffffff, 1);
  key.position.set(1, 1, 1);
  camera.add(key);
  scene.add(camera);
  scene.add(new T.HemisphereLight(0xffffff, new T.Color(0.35, 0.35, 0.4), 0.6));
  const controls = new OrbitControls(camera, canvas);
  built.push(controls);
  controls.enableDamping = true;
  const autoRotateState = { requested: false, stoppedByUser: false };
  // Set once the user moves the camera; a resize then keeps their view. It is
  // judged from the input, not the camera: damping and auto-rotate keep the
  // camera coasting under a click to focus, which is not a move.
  let userMoved = false;
  const pressedAt = new Map<number, { x: number; y: number }>();
  const input = new AbortController();
  built.push({ dispose: () => input.abort() });
  const listen = { signal: input.signal };
  const releasePointer = (event: PointerEvent) => pressedAt.delete(event.pointerId);
  canvas.addEventListener(
    "pointerdown",
    (event) => {
      pressedAt.set(event.pointerId, { x: event.clientX, y: event.clientY });
      if (pressedAt.size > 1) userMoved = true;
    },
    listen,
  );
  canvas.ownerDocument.addEventListener(
    "pointermove",
    (event) => {
      const origin = pressedAt.get(event.pointerId);
      if (origin && Math.hypot(event.clientX - origin.x, event.clientY - origin.y) > DRAG_PX) {
        userMoved = true;
      }
    },
    listen,
  );
  canvas.ownerDocument.addEventListener("pointerup", releasePointer, listen);
  canvas.addEventListener("pointercancel", releasePointer, listen);
  canvas.addEventListener("wheel", () => (userMoved = true), listen);
  controls.addEventListener("start", () => {
    controls.autoRotate = autoRotateAfterUserInteraction(autoRotateState);
  });
  const defaultColor = new T.Color(DEFAULT_MODEL_COLOR);
  const fallback = new T.MeshStandardMaterial({
    color: defaultColor.clone(),
    side: T.DoubleSide,
  });
  built.push(fallback);
  const vertexColored = () =>
    new T.MeshStandardMaterial({ vertexColors: true, side: T.DoubleSide });

  type Object3D = InstanceType<typeof T.Object3D>;
  type Material = InstanceType<typeof T.Material>;
  let current: Object3D | undefined;
  let radius = 0;
  let wireframe = false;

  const forEachMaterial = (root: Object3D, apply: (material: Material) => void) => {
    root.traverse((node) => {
      const material = (node as Partial<InstanceType<typeof T.Mesh>>).material;
      if (Array.isArray(material)) material.forEach(apply);
      else if (material) apply(material);
    });
  };
  const applyWireframe = (root: Object3D) => {
    forEachMaterial(root, (material) => {
      if ("wireframe" in material) {
        (material as Material & { wireframe: boolean }).wireframe = wireframe;
        material.needsUpdate = true;
      }
    });
  };
  const center = new T.Vector3();

  const disposeMaterial = (material: Material) => {
    if (material === fallback) return;
    for (const value of Object.values(material)) {
      if (!(value instanceof T.Texture)) continue;
      // Texture.dispose frees the GPU copy; a decoded ImageBitmap holds its own memory.
      const image: unknown = value.image;
      if (typeof ImageBitmap !== "undefined" && image instanceof ImageBitmap) image.close();
      value.dispose();
    }
    material.dispose();
  };
  const disposeObject = (root: Object3D) => {
    root.traverse((node) => {
      const mesh = node as Partial<InstanceType<typeof T.Mesh>>;
      mesh.geometry?.dispose();
      const material = mesh.material;
      if (Array.isArray(material)) material.forEach(disposeMaterial);
      else if (material) disposeMaterial(material);
    });
    disposeSkeletons(root);
  };

  const frame = (keepDirection: boolean) => {
    if (radius <= 0) return;
    const vFov = T.MathUtils.degToRad(camera.fov) / 2;
    const hFov = Math.atan(Math.tan(vFov) * camera.aspect);
    const distance = (radius / Math.sin(Math.min(vFov, hFov))) * 1.15;
    const direction = keepDirection
      ? camera.position.clone().sub(controls.target)
      : new T.Vector3(1, 0.75, 1);
    if (direction.lengthSq() === 0) direction.set(1, 0.75, 1);
    direction.normalize().multiplyScalar(distance);
    controls.target.copy(center);
    camera.position.copy(center).add(direction);
    camera.near = radius / 100;
    camera.far = radius * 100;
    camera.updateProjectionMatrix();
    controls.minDistance = radius * 0.2;
    controls.maxDistance = radius * 20;
    controls.update();
  };

  const manager = new T.LoadingManager();
  manager.setURLModifier((url) => {
    if (isEmbeddedResourceUrl(url)) return url;
    throw new ModelLoadError("external-resources", "the model asked for a separate file");
  });

  const parse = async (bytes: Uint8Array, format: ModelFormat): Promise<Object3D> => {
    switch (format) {
      case "glb":
      case "gltf":
        return (
          await new GLTFLoader(manager)
            .register(embeddedImagePlugin(T))
            .parseAsync(exactBuffer(bytes), "")
        ).scene;
      case "obj": {
        const group = new OBJLoader(manager).parse(new TextDecoder().decode(bytes));
        group.traverse((node) => {
          const mesh = node as Partial<InstanceType<typeof T.Mesh>>;
          if (!mesh.isMesh) return;
          const original = mesh.material;
          const originals = Array.isArray(original) ? original : original ? [original] : [];
          // Without its .mtl an OBJ's only color is per vertex; keep it.
          const colored = originals.some((m) => (m as Material).vertexColors);
          originals.forEach(disposeMaterial);
          mesh.material = colored ? vertexColored() : fallback;
        });
        return group;
      }
      case "stl": {
        const geometry = new STLLoader(manager).parse(exactBuffer(bytes));
        return new T.Mesh(geometry, geometry.getAttribute("color") ? vertexColored() : fallback);
      }
    }
  };

  let queue: Promise<unknown> = Promise.resolve();
  let disposed = false;

  renderer.setAnimationLoop(() => {
    controls.update();
    renderer.render(scene, camera);
  });

  const place = (model: Object3D): ModelStats => {
    stage.clear();
    current = model;
    applyWireframe(model);
    scene.add(model);
    const box = new T.Box3().setFromObject(model);
    const extent = box.isEmpty() ? new T.Vector3() : box.getSize(new T.Vector3());
    const sphere = box.getBoundingSphere(new T.Sphere());
    center.copy(sphere.center);
    radius = Number.isFinite(sphere.radius) && sphere.radius > 0 ? sphere.radius : 1;
    userMoved = false;
    frame(false);
    let meshes = 0;
    let triangles = 0;
    model.traverse((node) => {
      const mesh = node as Partial<InstanceType<typeof T.Mesh>>;
      if (!mesh.isMesh) return;
      meshes += 1;
      const geometry = mesh.geometry;
      const count = geometry?.index?.count ?? geometry?.getAttribute("position")?.count ?? 0;
      triangles += Math.floor(count / 3);
    });
    return { meshes, triangles, size: { x: extent.x, y: extent.y, z: extent.z } };
  };

  const enqueue = (run: () => Promise<ModelStats | null>): Promise<ModelStats | null> => {
    const result = queue.then(run, run);
    queue = result.catch(() => undefined);
    return result;
  };

  const buildSample = (): Object3D => {
    const paint = (color: string, metalness = 0.1, roughness = 0.45) =>
      new T.MeshStandardMaterial({ color, metalness, roughness });
    const add = (
      group: Object3D,
      geometry: InstanceType<typeof T.BoxGeometry> | InstanceType<typeof T.CylinderGeometry>,
      material: Material,
      x: number,
      y: number,
      z: number,
    ) => {
      const mesh = new T.Mesh(geometry, material);
      mesh.position.set(x, y, z);
      group.add(mesh);
      return mesh;
    };
    const car = new T.Group();
    car.name = "sample-toy-car";
    add(car, new T.BoxGeometry(2, 0.5, 1), paint("#e53935"), 0, 0.45, 0);
    add(car, new T.BoxGeometry(1.1, 0.45, 0.9), paint("#1e88e5", 0.2, 0.2), -0.15, 0.92, 0);
    add(car, new T.BoxGeometry(0.05, 0.12, 0.9), paint("#fdd835"), 1.0, 0.5, 0);
    const tire = paint("#212121", 0, 0.8);
    const hub = paint("#cfd8dc", 0.8, 0.3);
    for (const x of [-0.65, 0.65]) {
      for (const z of [-0.5, 0.5]) {
        const wheel = add(car, new T.CylinderGeometry(0.25, 0.25, 0.18, 24), tire, x, 0.25, z);
        wheel.rotation.x = Math.PI / 2;
        const cap = add(car, new T.CylinderGeometry(0.11, 0.11, 0.2, 16), hub, x, 0.25, z);
        cap.rotation.x = Math.PI / 2;
      }
    }
    add(car, new T.CylinderGeometry(1.6, 1.6, 0.06, 48), paint("#43a047", 0, 0.9), 0, -0.03, 0);
    return car;
  };

  const stage: ModelStage = {
    show(bytes, format, isCurrent) {
      return enqueue(async () => {
        if (disposed || (isCurrent && !isCurrent())) return null;
        let model: Object3D;
        try {
          model = await parse(bytes, format);
        } catch (error) {
          throw asParseFailure(error, `the ${format} loader rejected the model`);
        }
        if (disposed || (isCurrent && !isCurrent())) {
          disposeObject(model);
          return null;
        }
        try {
          return place(model);
        } catch (error) {
          disposeObject(model);
          throw asParseFailure(error, `the ${format} model could not be placed`);
        }
      });
    },
    showSample(isCurrent) {
      return enqueue(async () => {
        if (disposed || (isCurrent && !isCurrent())) return null;
        return place(buildSample());
      });
    },
    setWireframe(on) {
      wireframe = on;
      if (current) applyWireframe(current);
    },
    setColor(color) {
      if (color === undefined) {
        fallback.color.copy(defaultColor);
        return;
      }
      const parsed = parseModelColor((r, g, b) => new T.Color(r, g, b), color);
      if (parsed) fallback.color.copy(parsed);
    },
    setAutoRotate(on) {
      controls.autoRotate = autoRotateAfterProp(autoRotateState, on);
    },
    nudge(command) {
      if (disposed) return;
      userMoved = true;
      controls.autoRotate = autoRotateAfterUserInteraction(autoRotateState);
      if (command.kind === "orbit") {
        controls.rotateLeft(command.left);
        controls.rotateUp(command.up);
      } else {
        controls.dollyIn(command.factor);
      }
    },
    clear() {
      if (!current) return;
      scene.remove(current);
      disposeObject(current);
      current = undefined;
      radius = 0;
    },
    resize() {
      const width = canvas.clientWidth;
      const height = canvas.clientHeight;
      if (width === 0 || height === 0) return;
      renderer.setPixelRatio(Math.min(globalThis.devicePixelRatio || 1, 2));
      renderer.setSize(width, height, false);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      if (!userMoved) frame(true);
    },
    dispose() {
      if (disposed) return;
      disposed = true;
      renderer.setAnimationLoop(null);
      input.abort();
      controls.dispose();
      stage.clear();
      fallback.dispose();
      scene.environment = null;
      environment.dispose();
      pmrem.dispose();
      renderer.dispose();
      releaseWebGLContext(renderer, canvas);
    },
  };
  return stage;
}
