import { MAX_PDF_BYTES } from "./pdf-bytes";

export { MAX_PDF_BYTES };
export const MAX_CAPTURE_PIXELS = 32_000_000;
export const MAX_CAPTURE_SIDE = 16_384;
export const MAX_CAPTURE_NODES = 5_000;
export const MAX_CAPTURE_IMAGES = 100;
export const MAX_CAPTURE_RESOURCES = 100;
export const MAX_CAPTURE_STYLE_BYTES = 2 * 1024 * 1024;
export const MAX_PDF_PAGES = 20;
export const PDF_ASSET_WAIT_TIMEOUT_MS = 10_000;
export const PDF_RENDER_TIMEOUT_MS = 30_000;

const DEFAULT_MARGIN_POINTS = 36;
const DEFAULT_SCALE = 2;
const CAPTURE_BLEED_PX = 8;
const CAPTURE_MARKER = "data-aether-pdf-capture";
const EXCLUDE_SELECTOR = "[data-pdf-exclude]";
const EXPAND_SELECTOR = "[data-pdf-expand]";
const VIRTUALIZED_SELECTOR = "[data-pdf-virtualized]";
const UNSAFE_EMBEDDED_CONTENT_SELECTOR =
  'audio, embed, iframe, input[type="image"], link, object, script, video';
const INTRINSIC_CONTENT_SELECTOR =
  "canvas, hr, img, input, meter, picture, progress, select, svg, textarea";
const URL_COMPUTED_STYLE_PROPERTIES = [
  "background-image",
  "border-image-source",
  "clip-path",
  "content",
  "cursor",
  "filter",
  "list-style-image",
  "mask-image",
  "offset-path",
  "shape-outside",
] as const;
const captureQueues = new WeakMap<HTMLElement, Promise<void>>();

export type PdfPaperSize = "a4" | "letter";
export type PdfOrientation = "portrait" | "landscape";

export type PdfCaptureOptions = {
  expandContainers?: boolean;
  paperSize?: PdfPaperSize;
  orientation?: PdfOrientation;
  marginPoints?: number;
  scale?: number;
};

export type PdfExportResult = {
  blob: Blob;
  fileName: string;
  byteLength: number;
  mimeType: "application/pdf";
};

const pdfExportErrorMessages = new WeakMap<Error, string>();

class PdfExportError extends Error {
  override readonly name = "PdfExportError";

  constructor(message: string) {
    super(message);
    pdfExportErrorMessages.set(this, message);
  }
}

export function toSafePdfExportError(error: unknown): Error | null {
  if (!(error instanceof PdfExportError)) return null;
  const message = pdfExportErrorMessages.get(error);
  return message ? new Error(message) : null;
}

type ResolvedCaptureOptions = Required<PdfCaptureOptions>;

export function normalizePdfFileName(fileName: string): string {
  const sanitizedName = Array.from(fileName.trim())
    .map((character) =>
      character.charCodeAt(0) < 32 || '<>:"/\\|?*'.includes(character)
        ? "-"
        : character,
    )
    .join("")
    .replace(/[.\s]+$/g, "");
  const safeName = Array.from(sanitizedName)
    .slice(0, 116)
    .join("")
    .replace(/[.\s]+$/g, "");
  const stem =
    safeName.replace(/\.pdf$/i, "").replace(/^[-.]+$/, "") || "document";
  return `${stem}.pdf`;
}

export async function validatePdfBlob(blob: Blob): Promise<void> {
  const [bytes, trailer] = await Promise.all([
    blob.slice(0, 5).arrayBuffer().then((buffer) => new Uint8Array(buffer)),
    blob.slice(Math.max(0, blob.size - 1_024)).text(),
  ]);
  const signature = String.fromCharCode(...bytes);

  if (
    blob.size === 0 ||
    blob.type !== "application/pdf" ||
    signature !== "%PDF-" ||
    !/%%EOF\s*$/.test(trailer)
  ) {
    throw new PdfExportError("PDF generation returned invalid output.");
  }
  if (blob.size > MAX_PDF_BYTES) {
    throw new PdfExportError(
      `PDF output exceeds the ${MAX_PDF_BYTES}-byte maximum.`,
    );
  }
}

function defaultPaperSize(
  locale = globalThis.navigator?.language,
): PdfPaperSize {
  if (!locale) return "letter";

  try {
    const region = new Intl.Locale(locale).region;
    return region === "US" || region === "CA" || region === "MX"
      ? "letter"
      : "a4";
  } catch {
    return "letter";
  }
}

function resolveOptions(
  options: PdfCaptureOptions,
  locale?: string,
): ResolvedCaptureOptions {
  const marginPoints = options.marginPoints ?? DEFAULT_MARGIN_POINTS;
  const scale = options.scale ?? DEFAULT_SCALE;

  if (
    !Number.isFinite(marginPoints) ||
    marginPoints < 0 ||
    marginPoints > 72
  ) {
    throw new PdfExportError("PDF margin must be between 0 and 72 points.");
  }
  if (!Number.isFinite(scale) || scale < 1 || scale > 2) {
    throw new PdfExportError("PDF capture scale must be between 1 and 2.");
  }

  return {
    expandContainers: options.expandContainers ?? false,
    paperSize: options.paperSize ?? defaultPaperSize(locale),
    orientation: options.orientation ?? "portrait",
    marginPoints,
    scale,
  };
}

function captureDimensions(
  target: HTMLElement,
  options: ResolvedCaptureOptions,
): { width: number; height: number } {
  const bounds = target.getBoundingClientRect();
  const expandedRows = new Map<number, number>();
  if (options.expandContainers) {
    for (const element of Array.from(target.children)) {
      if (
        !(element instanceof HTMLElement) ||
        !element.matches(EXPAND_SELECTOR) ||
        element.matches(EXCLUDE_SELECTOR)
      ) {
        continue;
      }
      const delta = Math.max(0, element.scrollHeight - element.clientHeight);
      const row = Math.round(element.getBoundingClientRect().top);
      expandedRows.set(row, Math.max(expandedRows.get(row) ?? 0, delta));
    }
  }
  const expandedHeight = Array.from(expandedRows.values()).reduce(
    (total, delta) => total + delta,
    0,
  );
  const targetWidth = Math.ceil(bounds.width);
  const targetHeight = Math.ceil(bounds.height + expandedHeight);

  if (targetWidth <= 0 || targetHeight <= 0) {
    throw new PdfExportError("PDF capture target has no visible size.");
  }
  const width = targetWidth + CAPTURE_BLEED_PX * 2;
  const height = targetHeight + CAPTURE_BLEED_PX * 2;
  if (!options.expandContainers) {
    validateCaptureDimensions(width, height, options.scale);
  }
  return { width, height };
}

function validateCaptureDimensions(
  width: number,
  height: number,
  scale: number,
): void {
  if (
    width * scale > MAX_CAPTURE_SIDE ||
    height * scale > MAX_CAPTURE_SIDE ||
    width * scale * height * scale > MAX_CAPTURE_PIXELS
  ) {
    throw new PdfExportError("PDF capture target exceeds the supported size.");
  }
}

function validateCaptureTarget(
  target: HTMLElement,
  options: ResolvedCaptureOptions,
): void {
  if (!target.isConnected) {
    throw new PdfExportError(
      "PDF capture target is not attached to the document.",
    );
  }
  const view = target.ownerDocument.defaultView;
  if (view) {
    const fileInputs = [
      ...(target.matches('input[type="file"]')
        ? [target as HTMLInputElement]
        : []),
      ...includedDescendants<HTMLInputElement>(target, 'input[type="file"]'),
    ];
    for (const input of fileInputs) {
      const style = view.getComputedStyle(input);
      const bounds = input.getBoundingClientRect();
      const isVisible =
        !input.hidden &&
        style.display !== "none" &&
        style.visibility !== "hidden" &&
        style.opacity !== "0" &&
        (input.getClientRects().length > 0 ||
          bounds.width > 0 ||
          bounds.height > 0);
      if (isVisible && input.files && input.files.length > 0) {
        throw new PdfExportError(
          "PDF capture cannot include a visible file input with a selected file.",
        );
      }
    }
    for (
      let element: HTMLElement | null = target;
      element;
      element = element.parentElement
    ) {
      const style = view.getComputedStyle(element);
      if (
        ["transform", "translate", "rotate", "scale"].some((property) => {
          const value = style.getPropertyValue(property).trim();
          return value !== "" && value !== "none";
        })
      ) {
        throw new PdfExportError(
          "PDF capture does not support transforms on the target or its ancestors.",
        );
      }
    }
  }
  if (target.matches(EXCLUDE_SELECTOR)) {
    throw new PdfExportError("PDF capture target must not be excluded.");
  }
  validateCloneContext(target);
  if (
    target.matches(VIRTUALIZED_SELECTOR) ||
    includedDescendants(target, VIRTUALIZED_SELECTOR).length > 0
  ) {
    throw new PdfExportError(
      "PDF capture does not support virtualized content.",
    );
  }
  if (
    target.closest(UNSAFE_EMBEDDED_CONTENT_SELECTOR) ||
    includedDescendants(target, UNSAFE_EMBEDDED_CONTENT_SELECTOR).length > 0
  ) {
    throw new PdfExportError(
      "PDF capture target must not contain executable or embedded content.",
    );
  }
  if (includedDescendants(target, "*").length + 1 > MAX_CAPTURE_NODES) {
    throw new PdfExportError(
      `PDF capture target exceeds the ${MAX_CAPTURE_NODES}-node maximum.`,
    );
  }
  const expandable = includedDescendants<HTMLElement>(
    target,
    EXPAND_SELECTOR,
  );
  if (!options.expandContainers && expandable.length > 0) {
    throw new PdfExportError(
      "PDF expandable containers require the expandContainers option.",
    );
  }
  if (!options.expandContainers) return;
  if (expandable.some((element) => element.parentElement !== target)) {
    throw new PdfExportError(
      "PDF capture does not support nested expandable containers.",
    );
  }
}

function includedDescendants<T extends Element>(
  target: HTMLElement,
  selector: string,
): T[] {
  return Array.from(target.querySelectorAll<T>(selector)).filter((element) => {
    const excludedRoot = element.closest(EXCLUDE_SELECTOR);
    return (
      !excludedRoot ||
      excludedRoot === target ||
      !target.contains(excludedRoot)
    );
  });
}

async function waitForAsset<T>(
  asset: PromiseLike<T>,
  timeoutMessage: string,
  timeoutMs = PDF_ASSET_WAIT_TIMEOUT_MS,
  onTimeout?: () => void,
): Promise<T> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      asset,
      new Promise<never>((_, reject) => {
        timeout = setTimeout(
          () => {
            onTimeout?.();
            reject(new Error(timeoutMessage));
          },
          timeoutMs,
        );
      }),
    ]);
  } finally {
    if (timeout) clearTimeout(timeout);
  }
}

async function waitForImage(image: HTMLImageElement): Promise<void> {
  if (image.complete) return;

  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => {
      cleanup();
      reject(new Error("PDF capture timed out waiting for an image."));
    }, PDF_ASSET_WAIT_TIMEOUT_MS);
    const cleanup = () => {
      clearTimeout(timeout);
      image.removeEventListener("load", onLoad);
      image.removeEventListener("error", onError);
    };
    const onLoad = () => {
      cleanup();
      resolve();
    };
    const onError = () => {
      cleanup();
      reject(new Error("PDF capture image failed to load."));
    };
    image.addEventListener("load", onLoad, { once: true });
    image.addEventListener("error", onError, { once: true });
    if (image.complete) onLoad();
  });
}

function resolveLocalAssetUrl(
  source: string,
  target: HTMLElement,
  baseUrl = target.ownerDocument.baseURI,
): URL {
  const url = new URL(source, baseUrl);
  const isNetworkUrl = url.protocol === "http:" || url.protocol === "https:";
  if (
    (isNetworkUrl && url.origin !== target.ownerDocument.location?.origin) ||
    (!isNetworkUrl && url.protocol !== "data:" && url.protocol !== "blob:")
  ) {
    throw new PdfExportError("PDF capture supports only app-local resources.");
  }
  return url;
}

function computedStyleUrls(target: HTMLElement): string[] {
  const view = target.ownerDocument.defaultView;
  if (!view) return [];

  const urls: string[] = [];
  const elements = [target, ...includedDescendants<HTMLElement>(target, "*")];
  for (const element of elements) {
    for (const pseudo of [null, "::before", "::after"] as const) {
      const style = view.getComputedStyle(element, pseudo);
      for (const property of URL_COMPUTED_STYLE_PROPERTIES) {
        urls.push(...cssUrls(style.getPropertyValue(property)));
      }
    }
  }
  return urls;
}

function isDocumentLocalReference(
  source: string,
  target: HTMLElement,
): boolean {
  if (source.trimStart().startsWith("#")) return true;
  try {
    const resource = new URL(source, target.ownerDocument.baseURI);
    const documentUrl = new URL(target.ownerDocument.location.href);
    return (
      Boolean(resource.hash) &&
      resource.origin === documentUrl.origin &&
      resource.pathname === documentUrl.pathname &&
      resource.search === documentUrl.search
    );
  } catch {
    return false;
  }
}

async function loadImageSource(source: string, target: HTMLElement): Promise<void> {
  const view = target.ownerDocument.defaultView;
  if (!view) {
    throw new PdfExportError("PDF capture document has no browser window.");
  }

  const image = new view.Image();
  image.src = source;
  await waitForImage(image);
  if (image.naturalWidth === 0) {
    throw new PdfExportError("PDF capture image is unavailable.");
  }
}

async function waitForTargetAssets(target: HTMLElement): Promise<number> {
  const fonts = target.ownerDocument.fonts;
  if (fonts?.status === "loading") {
    await waitForAsset(
      fonts.ready,
      "PDF capture timed out waiting for document fonts.",
    );
  }

  const view = target.ownerDocument.defaultView;
  const imageConstructor = view?.HTMLImageElement;
  const images = [
    ...(imageConstructor && target instanceof imageConstructor ? [target] : []),
    ...includedDescendants<HTMLImageElement>(target, "img"),
  ];
  const svgSources = includedDescendants<SVGElement>(
    target,
    "svg image, svg use, svg feImage",
  )
    .map((element) => element.getAttribute("href") ?? element.getAttribute("xlink:href"))
    .filter((source): source is string => Boolean(source));
  const renderedSources = [
    ...new Set([...svgSources, ...computedStyleUrls(target)]),
  ].filter((source) => !isDocumentLocalReference(source, target));
  const sourceCount = images.length + renderedSources.length;
  if (sourceCount > MAX_CAPTURE_IMAGES) {
    throw new PdfExportError(
      `PDF capture target exceeds the ${MAX_CAPTURE_IMAGES}-image maximum.`,
    );
  }

  await Promise.all(
    images.map(async (image) => {
      await waitForImage(image);
      if (image.naturalWidth === 0) {
        throw new PdfExportError("PDF capture image is unavailable.");
      }

      const source = image.currentSrc || image.src;
      if (!source) return;
      resolveLocalAssetUrl(source, target);
    }),
  );
  await Promise.all(
    renderedSources.map(async (source) => {
      const url = resolveLocalAssetUrl(source, target);
      await loadImageSource(url.href, target);
    }),
  );
  return sourceCount;
}

function captureBackgroundColor(target: HTMLElement): string {
  const view = target.ownerDocument.defaultView;
  if (!view) return "#ffffff";
  const canvas = target.ownerDocument.createElement("canvas");
  canvas.width = 1;
  canvas.height = 1;
  const context = canvas.getContext("2d");
  if (!context) return "#ffffff";
  context.fillStyle = "#ffffff";
  context.fillRect(0, 0, 1, 1);

  const layers: string[] = [];
  let element: Element | null = target.parentElement ?? target;
  for (; element; element = element.parentElement) {
    const color = view.getComputedStyle(element).backgroundColor;
    if (!color || color === "transparent") continue;
    layers.push(color);
  }
  for (const layer of layers.reverse()) {
    context.fillStyle = layer;
    context.fillRect(0, 0, 1, 1);
  }
  const [red, green, blue] = context.getImageData(0, 0, 1, 1).data;
  return `rgb(${red}, ${green}, ${blue})`;
}

function normalizeCssEscapes(value: string): string {
  return value.replace(
    /\\([0-9a-f]{1,6})(?:\r\n|[ \t\r\n\f])?|\\([^\r\n\f])/gi,
    (
      _match,
      hexEscape: string | undefined,
      characterEscape: string | undefined,
    ) => {
      if (!hexEscape) return characterEscape ?? "";
      const codePoint = Number.parseInt(hexEscape, 16);
      return codePoint === 0 || codePoint > 0x10ffff
        ? "\uFFFD"
        : String.fromCodePoint(codePoint);
    },
  );
}

function cssUrls(value: string): string[] {
  return Array.from(
    normalizeCssEscapes(value).matchAll(
      /url\(\s*(?:"([^"]*)"|'([^']*)'|([^)]*?))\s*\)/gi,
    ),
    (match) => match[1] ?? match[2] ?? match[3]?.trim(),
  ).filter((source): source is string => Boolean(source));
}

function containsCssUrl(value: string): boolean {
  return /url\s*\(/i.test(normalizeCssEscapes(value));
}

type StylesheetSnapshot = { cssText: string; media: string };
type StylesheetSnapshotState = {
  resourceUrls: Set<string>;
  styleBytes: number;
  visited: Set<CSSStyleSheet>;
};

function rewriteCssUrls(
  cssText: string,
  target: HTMLElement,
  baseUrl: string,
): string {
  return cssText.replace(
    /url\(\s*(?:"([^"]*)"|'([^']*)'|([^)]*?))\s*\)/g,
    (match, doubleQuoted, singleQuoted, unquoted) => {
      const source = String(
        doubleQuoted ?? singleQuoted ?? unquoted ?? "",
      ).trim();
      if (!source || source.startsWith("#")) return match;
      return `url("${resolveLocalAssetUrl(source, target, baseUrl).href}")`;
    },
  );
}

async function snapshotStylesheetResources(
  target: HTMLElement,
  targetResourceCount: number,
): Promise<StylesheetSnapshot[]> {
  const view = target.ownerDocument.defaultView;
  const state: StylesheetSnapshotState = {
    resourceUrls: new Set(),
    styleBytes: 0,
    visited: new Set(),
  };
  const snapshots: StylesheetSnapshot[] = [];

  const snapshotRules = (
    styleSheet: CSSStyleSheet,
    baseUrl: string,
  ): string[] => {
    if (state.visited.has(styleSheet)) return [];
    state.visited.add(styleSheet);

    let styleRules: CSSRuleList;
    try {
      styleRules = styleSheet.cssRules;
    } catch {
      throw new PdfExportError(
        "PDF capture could not read the app stylesheet.",
      );
    }

    const rules: string[] = [];
    for (const rule of Array.from(styleRules)) {
      if (rule.type === 3 && "styleSheet" in rule && "href" in rule) {
        const importRule = rule as CSSImportRule;
        const importUrl = resolveLocalAssetUrl(importRule.href, target, baseUrl);
        state.resourceUrls.add(importUrl.href);
        if (!importRule.styleSheet) {
          throw new PdfExportError(
            "PDF capture could not read the app stylesheet.",
          );
        }
        const importedRules = snapshotRules(importRule.styleSheet, importUrl.href);
        const media = importRule.media?.mediaText ?? "";
        if (media) {
          rules.push(`@media ${media} {\n${importedRules.join("\n")}\n}`);
        } else {
          rules.push(...importedRules);
        }
        continue;
      }

      state.styleBytes += new TextEncoder().encode(rule.cssText).byteLength;
      rules.push(rewriteCssUrls(rule.cssText, target, baseUrl));
      for (const source of cssUrls(rule.cssText)) {
        if (source.trimStart().startsWith("#")) continue;
        const resource = resolveLocalAssetUrl(source, target, baseUrl);
        state.resourceUrls.add(resource.href);
      }
    }
    return rules;
  };

  for (const styleSheet of Array.from(target.ownerDocument.styleSheets)) {
    if (
      styleSheet.disabled ||
      (styleSheet.media?.mediaText &&
        view &&
        !view.matchMedia(styleSheet.media.mediaText).matches)
    ) {
      continue;
    }
    const rules = snapshotRules(
      styleSheet,
      styleSheet.href ?? target.ownerDocument.baseURI,
    );
    snapshots.push({
      cssText: rules.join("\n"),
      media: styleSheet.media?.mediaText ?? "",
    });
  }
  if (state.styleBytes > MAX_CAPTURE_STYLE_BYTES) {
    throw new PdfExportError(
      `PDF capture styles exceed the ${MAX_CAPTURE_STYLE_BYTES}-byte maximum.`,
    );
  }
  if (targetResourceCount + state.resourceUrls.size > MAX_CAPTURE_RESOURCES) {
    throw new PdfExportError(
      `PDF capture target exceeds the ${MAX_CAPTURE_RESOURCES}-resource maximum.`,
    );
  }
  return snapshots;
}

function applyStylesheetSnapshot(
  document: Document,
  snapshots: StylesheetSnapshot[],
): void {
  document.head
    .querySelectorAll('link[rel~="stylesheet"], style')
    .forEach((element) => element.remove());
  for (const snapshot of snapshots) {
    const style = document.createElement("style");
    if (snapshot.media) style.media = snapshot.media;
    style.textContent = snapshot.cssText;
    document.head.append(style);
  }
}

function cloneIncludedSubtree(source: HTMLElement): HTMLElement {
  const view = source.ownerDocument.defaultView;
  let clone: HTMLElement;
  if (
    view &&
    (source instanceof view.HTMLImageElement ||
      source instanceof view.HTMLSourceElement)
  ) {
    clone = source.ownerDocument.createElement(source.localName);
    for (const attribute of Array.from(source.attributes)) {
      if (["sizes", "src", "srcset"].includes(attribute.name.toLowerCase())) {
        continue;
      }
      clone.setAttributeNS(
        attribute.namespaceURI,
        attribute.name,
        attribute.value,
      );
    }
    if (source instanceof view.HTMLImageElement) {
      const selectedSource = source.currentSrc || source.src;
      if (selectedSource) clone.setAttribute("src", selectedSource);
    }
  } else {
    clone = source.cloneNode(false) as HTMLElement;
  }
  for (const child of Array.from(source.childNodes)) {
    if (child instanceof source.ownerDocument.defaultView!.Element) {
      if (child.matches(EXCLUDE_SELECTOR)) continue;
      clone.append(cloneIncludedSubtree(child as HTMLElement));
    } else {
      clone.append(child.cloneNode(true));
    }
  }
  return clone;
}

function cloneContextElements(target: HTMLElement): HTMLElement[] {
  const elements = [target, ...includedDescendants<HTMLElement>(target, "*")];
  for (
    let ancestor = target.parentElement;
    ancestor;
    ancestor = ancestor.parentElement
  ) {
    elements.push(ancestor);
    if (ancestor === target.ownerDocument.body) break;
  }
  return elements;
}

function isCustomElement(element: Element): boolean {
  return element.localName.includes("-") || element.hasAttribute("is");
}

function validateCloneContext(target: HTMLElement): void {
  const elements = cloneContextElements(target);
  if (elements.some(isCustomElement)) {
    throw new PdfExportError("PDF capture does not support custom elements.");
  }
  let sourceChild: Element = target;
  for (
    let ancestor = target.parentElement;
    ancestor;
    ancestor = ancestor.parentElement
  ) {
    if (
      Array.from(ancestor.children).some(
        (child) => child !== sourceChild && isCustomElement(child),
      )
    ) {
      throw new PdfExportError("PDF capture does not support custom elements.");
    }
    sourceChild = ancestor;
    if (ancestor === target.ownerDocument.body) break;
  }
  if (elements.some((element) => element.shadowRoot)) {
    throw new PdfExportError("PDF capture does not support shadow DOM.");
  }
  if (
    elements.some((element) =>
      Array.from(element.attributes).some((attribute) =>
        attribute.name.toLowerCase().startsWith("on"),
      ),
    )
  ) {
    throw new PdfExportError(
      "PDF capture does not support inline event-handler attributes.",
    );
  }
}

function hasVisiblePaint(style: CSSStyleDeclaration): boolean {
  const backgroundColor = style.backgroundColor.replaceAll(" ", "");
  return (
    (backgroundColor !== "" &&
      backgroundColor !== "transparent" &&
      backgroundColor !== "rgba(0,0,0,0)") ||
    (style.backgroundImage !== "" && style.backgroundImage !== "none") ||
    (style.boxShadow !== "" && style.boxShadow !== "none") ||
    (style.outlineStyle !== "" && style.outlineStyle !== "none") ||
    (style.borderTopStyle !== "" &&
      style.borderTopStyle !== "none" &&
      Number.parseFloat(style.borderTopWidth) > 0) ||
    (style.borderRightStyle !== "" &&
      style.borderRightStyle !== "none" &&
      Number.parseFloat(style.borderRightWidth) > 0) ||
    (style.borderBottomStyle !== "" &&
      style.borderBottomStyle !== "none" &&
      Number.parseFloat(style.borderBottomWidth) > 0) ||
    (style.borderLeftStyle !== "" &&
      style.borderLeftStyle !== "none" &&
      Number.parseFloat(style.borderLeftWidth) > 0)
  );
}

function isIncludedElementVisible(
  element: HTMLElement,
  target: HTMLElement,
  view: Window,
): boolean {
  for (
    let current: HTMLElement | null = element;
    current;
    current = current.parentElement
  ) {
    const style = view.getComputedStyle(current);
    if (
      current.hidden ||
      style.display === "none" ||
      style.visibility === "hidden" ||
      style.visibility === "collapse" ||
      Number.parseFloat(style.opacity) === 0
    ) {
      return false;
    }
    if (current === target) return true;
  }
  return false;
}

function hasIncludedCaptureContent(target: HTMLElement): boolean {
  const view = target.ownerDocument.defaultView;
  if (!view) return false;
  return [target, ...Array.from(target.querySelectorAll<HTMLElement>("*"))].some(
    (element) => {
      if (!isIncludedElementVisible(element, target, view)) return false;
      const style = view.getComputedStyle(element);
      const hasGeneratedContent = ["::before", "::after"].some((pseudo) => {
        const pseudoStyle = view.getComputedStyle(element, pseudo);
        const content = pseudoStyle.content;
        return (
          content !== "" &&
          content !== "none" &&
          content !== "normal" &&
          (content !== '""' &&
            content !== "''" ||
            hasVisiblePaint(pseudoStyle))
        );
      });
      return (
        Array.from(element.childNodes).some(
          (node) => node.nodeType === 3 && Boolean(node.textContent?.trim()),
        ) ||
        (element.matches(INTRINSIC_CONTENT_SELECTOR) &&
          !(
            element instanceof view.HTMLInputElement &&
            element.type === "hidden"
          )) ||
        hasGeneratedContent ||
        hasVisiblePaint(style)
      );
    },
  );
}

function copyLiveElementState(
  source: HTMLElement,
  clone: HTMLElement,
): Array<{ element: HTMLElement; left: number; top: number }> {
  const view = source.ownerDocument.defaultView;
  if (!view) return [];
  const scrollStates: Array<{ element: HTMLElement; left: number; top: number }> = [];
  const sourceElements = [
    source,
    ...includedDescendants<HTMLElement>(source, "*"),
  ];
  const cloneElements = [clone, ...Array.from(clone.querySelectorAll<HTMLElement>("*"))];
  for (let index = 0; index < sourceElements.length; index += 1) {
    const sourceElement = sourceElements[index];
    const cloneElement = cloneElements[index];
    if (!sourceElement || !cloneElement) continue;

    scrollStates.push({
      element: cloneElement,
      left: sourceElement.scrollLeft,
      top: sourceElement.scrollTop,
    });
    if (
      sourceElement instanceof view.HTMLInputElement &&
      cloneElement instanceof view.HTMLInputElement
    ) {
      cloneElement.checked = sourceElement.checked;
      if (sourceElement.type !== "file") {
        cloneElement.value = sourceElement.value;
      }
      if (sourceElement.type === "radio") cloneElement.removeAttribute("name");
    } else if (
      sourceElement instanceof view.HTMLImageElement &&
      cloneElement instanceof view.HTMLImageElement
    ) {
      const selectedSource = sourceElement.currentSrc || sourceElement.src;
      if (selectedSource) cloneElement.src = selectedSource;
      cloneElement.removeAttribute("srcset");
      cloneElement.removeAttribute("sizes");
    } else if (
      sourceElement instanceof view.HTMLSourceElement &&
      cloneElement instanceof view.HTMLSourceElement
    ) {
      cloneElement.removeAttribute("srcset");
      cloneElement.removeAttribute("sizes");
    } else if (
      sourceElement instanceof view.HTMLTextAreaElement &&
      cloneElement instanceof view.HTMLTextAreaElement
    ) {
      cloneElement.value = sourceElement.value;
      cloneElement.textContent = sourceElement.value;
    } else if (
      sourceElement instanceof view.HTMLSelectElement &&
      cloneElement instanceof view.HTMLSelectElement
    ) {
      Array.from(sourceElement.options).forEach((option, optionIndex) => {
        const clonedOption = cloneElement.options.item(optionIndex);
        if (!clonedOption) return;
        // Mirror the choice onto the attribute so a native re-clone or
        // serialisation of the capture keeps it, not just the live property.
        clonedOption.toggleAttribute("selected", option.selected);
        clonedOption.selected = option.selected;
      });
    } else if (
      sourceElement instanceof view.HTMLCanvasElement &&
      cloneElement instanceof view.HTMLCanvasElement
    ) {
      cloneElement.width = sourceElement.width;
      cloneElement.height = sourceElement.height;
      const context = cloneElement.getContext("2d");
      if (!context) {
        throw new PdfExportError(
          "PDF capture could not copy canvas content.",
        );
      }
      context.drawImage(sourceElement, 0, 0);
    }
  }
  return scrollStates;
}

function prepareIsolatedTarget(
  target: HTMLElement,
  options: ResolvedCaptureOptions,
  dimensions: { width: number; height: number },
  backgroundColor: string,
): { capture: HTMLElement; dimensions: { width: number; height: number } } {
  const clonedTarget = cloneIncludedSubtree(target);
  const scrollStates = copyLiveElementState(target, clonedTarget);
  const sourceContentWidth = dimensions.width - CAPTURE_BLEED_PX * 2;
  const sourceContentHeight = dimensions.height - CAPTURE_BLEED_PX * 2;
  clonedTarget.style.setProperty(
    "width",
    `${sourceContentWidth}px`,
    "important",
  );
  clonedTarget.style.setProperty("box-sizing", "border-box", "important");
  clonedTarget.style.setProperty("margin", "0", "important");
  clonedTarget.style.setProperty("position", "relative", "important");
  clonedTarget.style.setProperty("inset", "auto", "important");
  if (options.expandContainers) {
    const expand = (element: HTMLElement) => {
      element.style.setProperty("height", "auto", "important");
      element.style.setProperty("max-height", "none", "important");
      element.style.setProperty("overflow", "visible", "important");
    };
    expand(clonedTarget);
    Array.from(clonedTarget.children).forEach((element) => {
      if (element instanceof HTMLElement && element.matches(EXPAND_SELECTOR)) {
        expand(element);
      }
    });
  } else {
    clonedTarget.style.setProperty(
      "height",
      `${sourceContentHeight}px`,
      "important",
    );
  }

  const container = target.ownerDocument.createElement("div");
  container.setAttribute(CAPTURE_MARKER, "");
  container.style.cssText = [
    "box-sizing: content-box",
    `width: ${sourceContentWidth}px`,
    `padding: ${CAPTURE_BLEED_PX}px`,
    `background: ${backgroundColor}`,
    "overflow: visible",
    "position: fixed",
    "left: -100000px",
    "top: 0",
    "pointer-events: none",
  ].join(";");
  let contextualTarget: HTMLElement = clonedTarget;
  let sourceChild: Element = target;
  const view = target.ownerDocument.defaultView;
  for (
    let ancestor = target.parentElement;
    ancestor;
    ancestor = ancestor.parentElement
  ) {
    const shell = ancestor.cloneNode(false) as HTMLElement;
    for (const property of Array.from(shell.style)) {
      if (containsCssUrl(shell.style.getPropertyValue(property))) {
        shell.style.removeProperty(property);
      }
    }
    if (view) {
      const style = view.getComputedStyle(ancestor);
      const bounds = ancestor.getBoundingClientRect();
      shell.style.setProperty("display", style.display, "important");
      shell.style.setProperty("box-sizing", "border-box", "important");
      shell.style.setProperty("margin", "0", "important");
      shell.style.setProperty("position", "relative", "important");
      shell.style.setProperty("inset", "auto", "important");
      shell.style.setProperty("overflow", "visible", "important");
      if (bounds.width > 0 && style.display !== "contents") {
        shell.style.setProperty("width", `${bounds.width}px`, "important");
        shell.style.setProperty("min-width", `${bounds.width}px`, "important");
        shell.style.setProperty("max-width", `${bounds.width}px`, "important");
      }
      for (const property of ["container-name", "container-type"] as const) {
        const value = style.getPropertyValue(property);
        if (value) shell.style.setProperty(property, value, "important");
      }
    }
    for (const child of Array.from(ancestor.children)) {
      if (child === sourceChild) {
        shell.append(contextualTarget);
        continue;
      }
      const placeholder = child.cloneNode(false) as HTMLElement;
      for (const attribute of Array.from(placeholder.attributes)) {
        if (
          attribute.name === "style" ||
          attribute.name.startsWith("on") ||
          [
            "action",
            "background",
            "data",
            "formaction",
            "href",
            "poster",
            "src",
            "srcdoc",
            "srcset",
            "xlink:href",
          ].includes(attribute.name)
        ) {
          placeholder.removeAttribute(attribute.name);
        }
      }
      placeholder.setAttribute("aria-hidden", "true");
      placeholder.style.setProperty("display", "none", "important");
      shell.append(placeholder);
    }
    contextualTarget = shell;
    sourceChild = ancestor;
    if (ancestor === target.ownerDocument.body) break;
  }
  container.append(contextualTarget);
  target.ownerDocument.body.append(container);
  try {
    if (!hasIncludedCaptureContent(clonedTarget)) {
      throw new PdfExportError("PDF capture target has no included content.");
    }
    for (const state of scrollStates) {
      if (!state.element.isConnected) continue;
      state.element.scrollLeft = state.left;
      state.element.scrollTop = state.top;
    }
    const cloneBounds = clonedTarget.getBoundingClientRect();
    const cloneBoundsWidth = cloneBounds.width;
    const measuredWidth = Math.ceil(
      options.expandContainers
        ? Math.max(clonedTarget.scrollWidth, cloneBoundsWidth)
        : cloneBoundsWidth,
    );
    const contentWidth =
      measuredWidth > 0 ? measuredWidth : sourceContentWidth;
    clonedTarget.style.setProperty(
      "width",
      `${contentWidth}px`,
      "important",
    );
    container.style.setProperty("width", `${contentWidth}px`);
    const widthAdjustedCloneBounds = clonedTarget.getBoundingClientRect();
    const cloneBoundsHeight = widthAdjustedCloneBounds.height;
    const measuredHeight = Math.ceil(
      options.expandContainers
        ? Math.max(clonedTarget.scrollHeight, cloneBoundsHeight)
        : cloneBoundsHeight,
    );
    const contentHeight =
      measuredHeight > 0 ? measuredHeight : sourceContentHeight;
    const measuredDimensions = {
      width: contentWidth + CAPTURE_BLEED_PX * 2,
      height: contentHeight + CAPTURE_BLEED_PX * 2,
    };
    validateCaptureDimensions(
      measuredDimensions.width,
      measuredDimensions.height,
      options.scale,
    );
    clonedTarget.style.setProperty("height", `${contentHeight}px`, "important");
    container.style.setProperty("height", `${contentHeight}px`);
    const finalCloneBounds = clonedTarget.getBoundingClientRect();
    const containerBounds = container.getBoundingClientRect();
    contextualTarget.style.setProperty(
      "left",
      `${
        CAPTURE_BLEED_PX - (finalCloneBounds.left - containerBounds.left)
      }px`,
      "important",
    );
    contextualTarget.style.setProperty(
      "top",
      `${
        CAPTURE_BLEED_PX - (finalCloneBounds.top - containerBounds.top)
      }px`,
      "important",
    );
    container.style.setProperty("overflow", "hidden");
    return { capture: container, dimensions: measuredDimensions };
  } catch (error) {
    container.remove();
    throw error;
  }
}

function mutationChangesCapture(
  mutation: MutationRecord,
  target: HTMLElement,
): boolean {
  const view = target.ownerDocument.defaultView;
  const element =
    view && mutation.target instanceof view.Element
      ? mutation.target
      : mutation.target.parentElement;
  if (
    mutation.type === "attributes" &&
    mutation.attributeName === EXCLUDE_SELECTOR.slice(1, -1) &&
    element &&
    target.contains(element)
  ) {
    return true;
  }
  const excludedRoot = element?.closest(EXCLUDE_SELECTOR);
  return !excludedRoot || !target.contains(excludedRoot);
}

async function createPdfBlobUnlocked(
  target: HTMLElement,
  fileName: string,
  captureOptions: PdfCaptureOptions = {},
): Promise<PdfExportResult> {
  const options = resolveOptions(
    captureOptions,
    target.ownerDocument.defaultView?.navigator.language,
  );
  validateCaptureTarget(target, options);
  const view = target.ownerDocument.defaultView;
  if (!view) {
    throw new PdfExportError("PDF capture document has no browser window.");
  }
  let targetMutated = false;
  const observer = new view.MutationObserver((mutations) => {
    targetMutated ||= mutations.some((mutation) =>
      mutationChangesCapture(mutation, target),
    );
  });
  observer.observe(target, {
    attributes: true,
    characterData: true,
    childList: true,
    subtree: true,
  });
  let isolatedCapture: HTMLElement | undefined;
  let rendererIframeContainer: HTMLElement | undefined;

  try {
    const targetResourceCount = await waitForTargetAssets(target);
    const stylesheetSnapshot = await snapshotStylesheetResources(
      target,
      targetResourceCount,
    );
    const [{ default: html2canvas }, { jsPDF }] = await Promise.all([
      import("html2canvas-pro"),
      import("jspdf"),
    ]);
    if (targetMutated) {
      throw new PdfExportError(
        "PDF capture target changed while preparing the export.",
      );
    }
    validateCaptureTarget(target, options);
    let dimensions = captureDimensions(target, options);
    const backgroundColor = captureBackgroundColor(target);
    const isolated = prepareIsolatedTarget(
      target,
      options,
      dimensions,
      backgroundColor,
    );
    isolatedCapture = isolated.capture;
    const pendingMutations = observer.takeRecords();
    observer.disconnect();
    if (
      targetMutated ||
      pendingMutations.some((mutation) =>
        mutationChangesCapture(mutation, target),
      )
    ) {
      throw new PdfExportError(
        "PDF capture target changed while preparing the export.",
      );
    }
    dimensions = isolated.dimensions;
    rendererIframeContainer = target.ownerDocument.createElement("div");
    target.ownerDocument.body.append(rendererIframeContainer);
    const renderAbort = new AbortController();
    const canvas = await waitForAsset(
      html2canvas(isolatedCapture, {
        allowTaint: false,
        backgroundColor,
        height: dimensions.height,
        imageTimeout: 10_000,
        iframeContainer: rendererIframeContainer,
        ignoreElements: (element) => {
          const parent = element.parentElement;
          if (parent === target.ownerDocument.body) {
            return (
              element !== isolatedCapture &&
              element !== rendererIframeContainer
            );
          }
          return (
            parent === target.ownerDocument.head &&
            element.matches(
              'link[rel~="stylesheet"], link[rel~="icon"], link[rel~="preload"], style',
            )
          );
        },
        logging: false,
        onclone: (clonedDocument) => {
          applyStylesheetSnapshot(clonedDocument, stylesheetSnapshot);
        },
        scale: options.scale,
        signal: renderAbort.signal,
        useCORS: true,
        width: dimensions.width,
        windowHeight: view.innerHeight,
        windowWidth: view.innerWidth,
        x: 0,
        y: 0,
      }),
      "PDF capture timed out while rendering.",
      PDF_RENDER_TIMEOUT_MS,
      () => renderAbort.abort(),
    );
    const document = new jsPDF({
      format: options.paperSize,
      orientation: options.orientation,
      unit: "pt",
    });
    const pageWidth = document.internal.pageSize.getWidth();
    const pageHeight = document.internal.pageSize.getHeight();
    const contentWidth = pageWidth - options.marginPoints * 2;
    const contentHeight = pageHeight - options.marginPoints * 2;
    if (contentWidth <= 0 || contentHeight <= 0) {
      throw new PdfExportError("PDF margins leave no printable area.");
    }

    const sourcePageHeight = Math.max(
      1,
      Math.floor((contentHeight * canvas.width) / contentWidth),
    );
    const pageCount = Math.ceil(canvas.height / sourcePageHeight);
    if (pageCount > MAX_PDF_PAGES) {
      throw new PdfExportError(
        `PDF output exceeds the ${MAX_PDF_PAGES}-page maximum.`,
      );
    }

    for (
      let page = 0, sourceY = 0;
      sourceY < canvas.height;
      page += 1, sourceY += sourcePageHeight
    ) {
      if (page > 0) document.addPage();
      const sourceHeight = Math.min(
        sourcePageHeight,
        canvas.height - sourceY,
      );
      const pageCanvas = target.ownerDocument.createElement("canvas");
      pageCanvas.width = canvas.width;
      pageCanvas.height = sourceHeight;
      const context = pageCanvas.getContext("2d");
      if (!context) {
        throw new PdfExportError("PDF generation could not prepare a page.");
      }
      context.drawImage(
        canvas,
        0,
        sourceY,
        canvas.width,
        sourceHeight,
        0,
        0,
        canvas.width,
        sourceHeight,
      );
      const pageImage = pageCanvas.toDataURL("image/png");
      const pageRenderedHeight =
        (sourceHeight * contentWidth) / canvas.width;
      document.addImage(
        pageImage,
        "PNG",
        options.marginPoints,
        options.marginPoints,
        contentWidth,
        pageRenderedHeight,
        undefined,
        "FAST",
      );
    }

    const rendered = new Blob([document.output("arraybuffer")], {
      type: "application/pdf",
    });
    await validatePdfBlob(rendered);
    return {
      blob: rendered,
      fileName: normalizePdfFileName(fileName),
      byteLength: rendered.size,
      mimeType: "application/pdf",
    };
  } finally {
    observer.disconnect();
    rendererIframeContainer?.remove();
    isolatedCapture?.remove();
  }
}

export async function createPdfBlob(
  target: HTMLElement,
  fileName: string,
  captureOptions: PdfCaptureOptions = {},
): Promise<PdfExportResult> {
  const previous = captureQueues.get(target);
  let release!: () => void;
  const turn = new Promise<void>((resolve) => {
    release = resolve;
  });
  const queued = (previous ?? Promise.resolve())
    .catch(() => undefined)
    .then(() => turn);
  captureQueues.set(target, queued);
  if (previous) await previous.catch(() => undefined);
  try {
    return await createPdfBlobUnlocked(target, fileName, captureOptions);
  } finally {
    release();
    if (captureQueues.get(target) === queued) captureQueues.delete(target);
  }
}
