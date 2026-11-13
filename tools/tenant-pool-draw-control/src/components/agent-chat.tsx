import { memo, useCallback, useEffect, useId, useMemo, useRef, useState, type ChangeEvent, type FormEvent, type KeyboardEvent } from "react";
import { createPortal } from "react-dom";
import { ArrowUp, Check, Copy, Download, FileText, Paperclip, RotateCcw, X } from "lucide-react";
import { MarkdownText } from "@/components/markdown-text";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

// A chat surface for an agent that answers one message at a time (AgentNode's
// inline agent, or any `send` that resolves to Markdown). LOCKED — app code
// renders `<AgentChat send={...} />` and never rebuilds the transcript, the
// composer or the file previews.
//
// Layout: the root fills its container (`h-full`), the transcript scrolls on
// its own and the composer stays pinned below it, so give the parent a height.
// Enter sends, Shift+Enter inserts a newline, and the composer is locked while
// an answer is pending. Answers render through `<MarkdownText>`; files the agent
// generated render as inline images (PNG, JPEG, GIF, WebP only), capped text
// previews, or download chips.

/** The answer shape `send` resolves to; `InlineAgentAnswer` satisfies it. */
export type AgentChatAnswer = {
  message?: string;
  files?: unknown[];
  /** Shown as JSON, after any activity text, when the answer carries no message; `null` is shown too. */
  structuredOutput?: unknown;
  /** The text of these is shown when the answer carries no message. */
  activities?: unknown[];
};

/** A file the user attached, base64-encoded; `InlineAgentFile` has the same shape. */
export type AgentChatUpload = { name: string; content: string; contentType: string };

export const MAX_UPLOAD_FILES = 10;
export const MAX_UPLOAD_FILE_BYTES = 10 * 1024 * 1024;
export const MAX_UPLOAD_TOTAL_BYTES = 15 * 1024 * 1024;
const FILES_ONLY_MESSAGE = "Please look at the attached files.";

export type AgentChatProps = {
  /**
   * Sends one message and resolves to the agent's answer. Rejections show inline with Retry.
   * `files` is passed only when `acceptFiles` is set and the user attached any.
   */
  send: (message: string, files?: AgentChatUpload[]) => Promise<AgentChatAnswer>;
  /** Shows an attach button; attached files go to `send` with the message. */
  acceptFiles?: boolean;
  /** Prompts offered as buttons while the transcript is empty. */
  starters?: string[];
  placeholder?: string;
  /** Shown above the starters while the transcript is empty. */
  emptyTitle?: string;
  className?: string;
};

type ChatEntry =
  | { id: number; role: "user"; text: string; uploads: AgentChatUpload[] }
  | { id: number; role: "agent"; text: string; files: AgentChatFile[]; dropped: number; retry: Turn }
  | { id: number; role: "error"; text: string; retry: Turn };

type Turn = { text: string; uploads: AgentChatUpload[] };
type PendingUpload = AgentChatUpload & { size: number };

function uploadContentType(file: File): string {
  if (file.type) return file.type;
  const extension = file.name.split(".").pop()?.toLowerCase() ?? "";
  return Object.hasOwn(EXTENSION_TYPES, extension) ? EXTENSION_TYPES[extension] : "application/octet-stream";
}

async function readBase64(file: File): Promise<string> {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}

/** Why `adding` cannot join `current`, or null when it fits the upload limits. */
export function uploadLimitError(current: { size: number }[], adding: { name: string; size: number }[]): string | null {
  if (current.length + adding.length > MAX_UPLOAD_FILES) return `Attach up to ${MAX_UPLOAD_FILES} files per message.`;
  const large = adding.find((file) => file.size > MAX_UPLOAD_FILE_BYTES);
  if (large) return `${large.name} is larger than ${formatBytes(MAX_UPLOAD_FILE_BYTES)}.`;
  const total = [...current, ...adding].reduce((sum, file) => sum + file.size, 0);
  if (total > MAX_UPLOAD_TOTAL_BYTES) return `Attachments can total at most ${formatBytes(MAX_UPLOAD_TOTAL_BYTES)}.`;
  return null;
}

const IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/gif", "image/webp"]);
const TEXT_TYPES = new Set(["application/json", "application/xml", "application/x-yaml", "application/yaml"]);
const EXTENSION_TYPES: Record<string, string> = {
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  gif: "image/gif",
  webp: "image/webp",
  txt: "text/plain",
  log: "text/plain",
  md: "text/markdown",
  markdown: "text/markdown",
  csv: "text/csv",
  tsv: "text/tab-separated-values",
  json: "application/json",
  xml: "application/xml",
  yaml: "application/yaml",
  yml: "application/yaml",
  htm: "text/html",
  html: "text/html",
  svg: "application/octet-stream",
};
const TYPE_ALIASES: Record<string, string> = {
  "image/jpg": "image/jpeg",
  "image/pjpeg": "image/jpeg",
  "text/x-markdown": "text/markdown",
};
const BASE64 = /^[A-Za-z0-9+/]*={0,2}$/;
/** A `data:<type>;base64,` prefix some connectors put on `contentBytes`; group 1 is the type with its parameters. */
const DATA_URL = /^\s*data:([^,]*?);base64,/i;
/** Declared types that say nothing about the content, so the extension decides. */
const GENERIC_TYPES = new Set([
  "application/octet-stream",
  "binary/octet-stream",
  "application/binary",
  "application/unknown",
  "application/x-download",
  "application/download",
  "application/force-download",
]);
/** Decoded bytes above this are offered as a download only. */
export const MAX_INLINE_FILE_BYTES = 5 * 1024 * 1024;
/** Characters of a text file shown before "Show all". */
export const TEXT_PREVIEW_CHARS = 1_200;
/** Characters of a text file ever rendered inline. */
export const TEXT_MAX_CHARS = 100_000;
const GENERIC_ERROR = "The agent could not answer. Try again.";
/** Bidi overrides and isolates, which could make a file name display as a different extension. */
const BIDI_CONTROLS = /[\u202A-\u202E\u2066-\u2069]/g;
/** How long a download's object URL outlives its click, so the browser can start reading it. */
const DOWNLOAD_URL_TTL_MS = 60_000;

// Typing in the composer re-renders the chat; this keeps settled answers from re-parsing their Markdown.
const AnswerMarkdown = memo(MarkdownText);

export type AgentChatFileKind = "image" | "markdown" | "text" | "binary";

export type AgentChatFile = {
  name: string;
  contentType: string;
  kind: AgentChatFileKind;
  base64: string;
  size: number;
  /** The `charset=` parameter of the declared content type, else of the data-URL prefix; decodes text previews. */
  charset?: string;
};

/** True when a key press should send rather than insert a newline. */
export function isSendKey(event: { key: string; shiftKey: boolean; isComposing?: boolean; keyCode?: number }): boolean {
  // keyCode 229 is the IME commit Enter that Safari reports with isComposing false.
  return event.key === "Enter" && !event.shiftKey && !event.isComposing && event.keyCode !== 229;
}

/** The content type to treat a file as: its declared type, else one guessed from the extension. */
export function resolveContentType(name: string, declared: unknown): string {
  const type = typeof declared === "string" ? declared.split(";")[0].trim().toLowerCase() : "";
  if (type && !GENERIC_TYPES.has(type)) return Object.hasOwn(TYPE_ALIASES, type) ? TYPE_ALIASES[type] : type;
  const dot = name.lastIndexOf(".");
  const ext = dot >= 0 ? name.slice(dot + 1).toLowerCase() : "";
  return Object.hasOwn(EXTENSION_TYPES, ext) ? EXTENSION_TYPES[ext] : "application/octet-stream";
}

/** The `charset=` parameter of a declared content type, lowercased, if any. */
export function resolveCharset(declared: unknown): string | undefined {
  if (typeof declared !== "string") return undefined;
  const match = /;\s*charset\s*=\s*"?([^";\s]+)"?/i.exec(declared);
  return match ? match[1].toLowerCase() : undefined;
}

export function classifyContentType(contentType: string): AgentChatFileKind {
  if (IMAGE_TYPES.has(contentType)) return "image";
  if (contentType === "text/markdown") return "markdown";
  if (contentType === "text/html" || contentType === "image/svg+xml") return "binary";
  if (contentType.startsWith("text/") || TEXT_TYPES.has(contentType)) return "text";
  return "binary";
}

/**
 * Reads the connector's untyped `files` into renderable files. Entries without a
 * name or with content that is not base64 are dropped and counted.
 */
export function normalizeFiles(files: unknown[] | undefined): { files: AgentChatFile[]; dropped: number } {
  if (!Array.isArray(files)) return { files: [], dropped: 0 };
  const out: AgentChatFile[] = [];
  let dropped = 0;
  for (const file of files) {
    if (!file || typeof file !== "object") {
      dropped += 1;
      continue;
    }
    const { name, contentBytes, contentType } = file as Record<string, unknown>;
    if (typeof name !== "string" || !name.trim() || typeof contentBytes !== "string") {
      dropped += 1;
      continue;
    }
    const dataUrl = DATA_URL.exec(contentBytes);
    const declaredType = typeof contentType === "string" ? contentType.split(";")[0].trim().toLowerCase() : "";
    const declared = dataUrl && (!declaredType || GENERIC_TYPES.has(declaredType)) ? dataUrl[1] : contentType;
    const base64 = (dataUrl ? contentBytes.slice(dataUrl[0].length) : contentBytes)
      .replace(/\s+/g, "").replace(/-/g, "+").replace(/_/g, "/");
    if (!BASE64.test(base64) || base64.length % 4 === 1 || (base64.includes("=") && base64.length % 4 !== 0)) {
      dropped += 1;
      continue;
    }
    const padding = base64.endsWith("==") ? 2 : base64.endsWith("=") ? 1 : 0;
    const trimmed = name.replace(BIDI_CONTROLS, "").trim();
    if (!trimmed) {
      dropped += 1;
      continue;
    }
    const type = resolveContentType(trimmed, declared);
    out.push({
      name: trimmed,
      contentType: type,
      kind: classifyContentType(type),
      base64,
      size: Math.max(0, Math.floor((base64.length * 3) / 4) - padding),
      charset: resolveCharset(contentType) ?? resolveCharset(dataUrl?.[1]),
    });
  }
  return { files: out, dropped };
}

/**
 * The Markdown to show for an answer: its message, else the text of its
 * activities followed by its structured output (`null` included) as a JSON block.
 */
export function answerText(answer: AgentChatAnswer): string {
  if (typeof answer.message === "string" && answer.message.trim()) return answer.message;
  const activityText = (Array.isArray(answer.activities) ? answer.activities : [])
    .map((activity) => {
      if (typeof activity === "string") return activity;
      if (activity && typeof activity === "object") {
        const text = (activity as Record<string, unknown>).text;
        if (typeof text === "string") return text;
      }
      return "";
    })
    .filter((text) => text.trim())
    .join("\n\n");
  if (answer.structuredOutput === undefined) return activityText;
  let json: string | undefined;
  try {
    json = JSON.stringify(answer.structuredOutput, null, 2);
  } catch {
    json = undefined;
  }
  const body = json ?? String(answer.structuredOutput);
  let fenceLength = 3;
  for (const run of body.matchAll(/`+/g)) fenceLength = Math.max(fenceLength, run[0].length + 1);
  const fence = "`".repeat(fenceLength);
  const block = `${fence}json\n${body}\n${fence}`;
  return activityText ? `${activityText}\n\n${block}` : block;
}

export function decodeBase64(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Decodes text in its declared charset, falling back to UTF-8 for a label the browser does not know. */
export function decodeText(base64: string, charset = "utf-8"): string {
  let decoder: TextDecoder;
  try {
    decoder = new TextDecoder(charset);
  } catch {
    decoder = new TextDecoder("utf-8");
  }
  return decoder.decode(decodeBase64(base64));
}

export function formatBytes(size: number): string {
  if (size < 1024) return `${size} B`;
  if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
  return `${(size / (1024 * 1024)).toFixed(1)} MB`;
}

/** The message to show for a failed send: the connector's sanitized text, else a generic one. */
export function errorMessage(error: unknown): string {
  if (error instanceof Error && error.name === "AgentNodeError" && error.message) return error.message;
  return GENERIC_ERROR;
}

/**
 * Saves a file under its own name. Decodes only now, so a large answer never decodes on render, and
 * types the blob as octet-stream so the browser saves it rather than opening it. False when it failed.
 */
export function downloadFile(file: AgentChatFile): boolean {
  let url: string | undefined;
  try {
    url = URL.createObjectURL(new Blob([decodeBase64(file.base64)], { type: "application/octet-stream" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = file.name;
    link.click();
    return true;
  } catch {
    return false;
  } finally {
    const revoke = url;
    if (revoke) setTimeout(() => URL.revokeObjectURL(revoke), DOWNLOAD_URL_TTL_MS);
  }
}

function DownloadChip({ file }: { file: AgentChatFile }) {
  const [failed, setFailed] = useState(false);
  const onDownload = () => setFailed(!downloadFile(file));
  if (failed) {
    return (
      <span role="status" className="inline-flex max-w-full items-center gap-2 rounded-md border border-destructive/40 px-3 py-2 text-xs text-destructive">
        <span className="truncate font-medium">{file.name}</span>
        <span className="shrink-0">Couldn't prepare file</span>
      </span>
    );
  }
  return (
    <button
      type="button"
      onClick={onDownload}
      data-download={file.name}
      className="inline-flex max-w-full items-center gap-2 rounded-md border border-border bg-background px-3 py-2 text-xs hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    >
      <Download className="size-4 shrink-0" aria-hidden />
      <span className="truncate font-medium">{file.name}</span>
    </button>
  );
}

function TextPreview({ file }: { file: AgentChatFile }) {
  const [expanded, setExpanded] = useState(false);
  const text = useMemo(() => {
    try {
      return decodeText(file.base64, file.charset).slice(0, TEXT_MAX_CHARS);
    } catch {
      return null;
    }
  }, [file.base64, file.charset]);
  if (text === null) return <DownloadChip file={file} />;
  const long = text.length > TEXT_PREVIEW_CHARS;
  const shown = expanded || !long ? text : `${text.slice(0, TEXT_PREVIEW_CHARS)}…`;
  return (
    <figure className="w-full min-w-0 overflow-hidden rounded-md border border-border">
      <figcaption className="flex items-center gap-2 border-b border-border bg-muted/50 px-3 py-1.5 text-xs">
        <FileText className="size-3.5 shrink-0" aria-hidden />
        <span className="truncate font-medium">{file.name}</span>
      </figcaption>
      <div className="max-h-80 overflow-auto p-3">
        {file.kind === "markdown" ? (
          <AnswerMarkdown>{shown}</AnswerMarkdown>
        ) : (
          <pre className="whitespace-pre-wrap break-words font-mono text-xs">{shown}</pre>
        )}
      </div>
      <div className="flex gap-2 border-t border-border px-2 py-1">
        {long && (
          <Button type="button" variant="ghost" size="xs" onClick={() => setExpanded((value) => !value)}>
            {expanded ? "Show less" : "Show all"}
          </Button>
        )}
        <DownloadChip file={file} />
      </div>
    </figure>
  );
}

function ImageLightbox({ file, src, onClose }: { file: AgentChatFile; src: string; onClose: () => void }) {
  const closeRef = useRef<HTMLButtonElement>(null);
  const dialogRef = useRef<HTMLDivElement>(null);
  const [downloadFailed, setDownloadFailed] = useState(false);
  useEffect(() => {
    const opener = document.activeElement as HTMLElement | null;
    closeRef.current?.focus();
    const onKey = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape") {
        // Capture phase, so a surrounding dialog's own Escape handler never sees this key.
        event.stopImmediatePropagation();
        onClose();
        return;
      }
      if (event.key !== "Tab") return;
      // The dialog is modal: Tab cycles through its own buttons instead of the page behind it.
      const buttons = Array.from(dialogRef.current?.querySelectorAll("button") ?? []);
      if (buttons.length === 0) return;
      const at = buttons.indexOf(document.activeElement as HTMLButtonElement);
      const next = event.shiftKey ? (at <= 0 ? buttons.length - 1 : at - 1) : (at + 1) % buttons.length;
      event.preventDefault();
      buttons[next].focus();
    };
    document.addEventListener("keydown", onKey, true);
    return () => {
      document.removeEventListener("keydown", onKey, true);
      opener?.focus?.();
    };
  }, [onClose]);
  // Portalled to the body so a transformed or clipped ancestor cannot trap the fixed overlay.
  return createPortal(
    <div
      ref={dialogRef}
      role="dialog"
      aria-modal="true"
      aria-label={file.name}
      data-lightbox={file.name}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
      className="fixed inset-0 z-50 flex flex-col items-center justify-center gap-3 bg-black/80 p-6"
    >
      <img src={src} alt={file.name} className="max-h-[85vh] max-w-full rounded-md object-contain" />
      <div className="flex items-center gap-2 text-sm text-white">
        <span className="min-w-0 truncate">{file.name}</span>
        <Button type="button" variant="secondary" size="sm" onClick={() => setDownloadFailed(!downloadFile(file))}>
          <Download aria-hidden /> Download
        </Button>
        {downloadFailed && <span role="status">Couldn't prepare file</span>}
        <Button ref={closeRef} type="button" variant="secondary" size="sm" aria-label="Close" onClick={onClose}>
          <X aria-hidden />
        </Button>
      </div>
    </div>,
    document.body,
  );
}

function AgentImage({ file }: { file: AgentChatFile }) {
  const [failed, setFailed] = useState(false);
  const [zoomed, setZoomed] = useState(false);
  const [downloadFailed, setDownloadFailed] = useState(false);
  const close = useCallback(() => setZoomed(false), []);
  if (failed) return <DownloadChip file={file} />;
  const src = `data:${file.contentType};base64,${file.base64}`;
  return (
    <figure className="w-full min-w-0">
      <button
        type="button"
        aria-label={`Open ${file.name}`}
        data-zoom={file.name}
        onClick={() => setZoomed(true)}
        className="block max-w-full cursor-zoom-in rounded-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        <img
          src={src}
          alt={file.name}
          onError={() => setFailed(true)}
          className="max-h-96 max-w-full rounded-md border border-border object-contain"
        />
      </button>
      <figcaption className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
        <span className="truncate">{file.name}</span>
        <Button
          type="button"
          variant="ghost"
          size="icon-xs"
          aria-label={`Download ${file.name}`}
          data-download={file.name}
          onClick={() => setDownloadFailed(!downloadFile(file))}
        >
          <Download aria-hidden />
        </Button>
        {downloadFailed && (
          <span role="status" className="text-destructive">
            Couldn't prepare file
          </span>
        )}
      </figcaption>
      {zoomed && <ImageLightbox file={file} src={src} onClose={close} />}
    </figure>
  );
}

function AgentFile({ file }: { file: AgentChatFile }) {
  if (file.size > MAX_INLINE_FILE_BYTES || file.kind === "binary") return <DownloadChip file={file} />;
  if (file.kind === "image") return <AgentImage file={file} />;
  return <TextPreview file={file} />;
}

function CopyButton({ text }: { text: string }) {
  const [state, setState] = useState<"idle" | "copied" | "failed">("idle");
  useEffect(() => {
    if (state === "idle") return;
    const timer = setTimeout(() => setState("idle"), 1_500);
    return () => clearTimeout(timer);
  }, [state]);
  const onCopy = () => {
    if (!navigator.clipboard?.writeText) {
      setState("failed");
      return;
    }
    navigator.clipboard.writeText(text).then(
      () => setState("copied"),
      () => setState("failed"),
    );
  };
  return (
    <span className="inline-flex items-center gap-1">
      <Button
        type="button"
        variant="ghost"
        size="icon-xs"
        aria-label={state === "copied" ? "Copied" : state === "failed" ? "Copy failed" : "Copy answer"}
        onClick={onCopy}
      >
        {state === "copied" ? <Check aria-hidden /> : <Copy aria-hidden />}
      </Button>
      {state === "failed" && (
        <span role="status" className="text-xs text-destructive">
          Copy failed
        </span>
      )}
    </span>
  );
}

export function AgentChat({
  send,
  acceptFiles = false,
  starters = [],
  placeholder = "Message the agent…",
  emptyTitle = "Ask the agent anything",
  className,
}: AgentChatProps) {
  const [entries, setEntries] = useState<ChatEntry[]>([]);
  const [draft, setDraft] = useState("");
  const [uploads, setUploadsState] = useState<PendingUpload[]>([]);
  // Written with the state, so a send right after a read finishes sees the file before it renders.
  const uploadsRef = useRef<PendingUpload[]>([]);
  const setUploads = useCallback((next: (current: PendingUpload[]) => PendingUpload[]) => {
    uploadsRef.current = next(uploadsRef.current);
    setUploadsState(uploadsRef.current);
  }, []);
  // Bumped when attachments switch off: a read started before that never attaches.
  const uploadGeneration = useRef(0);
  const [uploadError, setUploadError] = useState<string | null>(null);
  // A pick is read before it joins the chips; sending or picking again waits for it.
  const [reading, setReading] = useState(false);
  const readingRef = useRef(false);
  const [pending, setPending] = useState(false);
  const nextId = useRef(0);
  const inFlight = useRef(false);
  // The newest `send`, read at call time: a new `send` identity alone keeps the pending answer.
  // Switching agent or connection remounts the chat through `key`, which drops it.
  const sendRef = useRef(send);
  sendRef.current = send;
  // Read at call time too: once `acceptFiles` is off, nothing attached earlier is sent.
  const acceptFilesRef = useRef(acceptFiles);
  acceptFilesRef.current = acceptFiles;
  const scroller = useRef<HTMLDivElement>(null);
  const composer = useRef<HTMLTextAreaElement>(null);
  const filePicker = useRef<HTMLInputElement>(null);
  const inputId = useId();

  useEffect(() => {
    const node = scroller.current;
    if (node) node.scrollTop = node.scrollHeight;
  }, [entries, pending]);

  const wasPending = useRef(false);
  useEffect(() => {
    if (wasPending.current && !pending) {
      const active = document.activeElement;
      const node = composer.current;
      if (!active || active === document.body || node?.closest("section")?.contains(active)) node?.focus();
    }
    wasPending.current = pending;
  }, [pending]);

  const submit = useCallback(
    async (
      raw: string,
      options: { echo: boolean; clearDraft: boolean; clearUploads?: boolean; uploads?: AgentChatUpload[] } = {
        echo: true,
        clearDraft: true,
      },
    ) => {
      const attached = acceptFilesRef.current ? (options.uploads ?? []) : [];
      // Only trailing whitespace is dropped: leading indentation in pasted code is content.
      const typed = raw.trimEnd();
      if ((!typed.trim() && attached.length === 0) || inFlight.current) return;
      const text = typed.trim() ? typed : FILES_ONLY_MESSAGE;
      const turn: Turn = { text, uploads: attached };
      inFlight.current = true;
      setPending(true);
      if (options.echo) {
        setEntries((current) => [...current, { id: nextId.current++, role: "user", text, uploads: attached }]);
      }
      if (options.clearDraft) setDraft("");
      if (options.clearDraft || options.clearUploads) {
        setUploads(() => []);
        setUploadError(null);
      }
      try {
        const answer = await (attached.length ? sendRef.current(text, attached) : sendRef.current(text));
        const { files, dropped } = normalizeFiles(answer.files);
        const message = answerText(answer);
        setEntries((current) => [
          ...current,
          { id: nextId.current++, role: "agent", text: message, files, dropped, retry: turn },
        ]);
      } catch (error) {
        setEntries((current) => [
          ...current,
          { id: nextId.current++, role: "error", text: errorMessage(error), retry: turn },
        ]);
      } finally {
        inFlight.current = false;
        setPending(false);
      }
    },
    [setUploads],
  );

  // A turn sent with files is never re-sent without them once `acceptFiles` is off.
  const canRetry = (turn: Turn) => acceptFiles || turn.uploads.length === 0;

  const retry = (entry: Extract<ChatEntry, { role: "error" | "agent" }>) => {
    if (inFlight.current || !canRetry(entry.retry)) return;
    // Retrying an earlier turn re-asks the question at the end so its answer sits under it.
    const isLatest = entries[entries.length - 1]?.id === entry.id;
    setEntries((current) => {
      const index = current.findIndex((item) => item.id === entry.id);
      // An earlier turn's question is re-asked at the end, so its original bubble goes too.
      const question = !isLatest && current[index - 1]?.role === "user" ? current[index - 1].id : undefined;
      return current.filter((item) => item.id !== entry.id && item.id !== question);
    });
    void submit(entry.retry.text, { echo: !isLatest, clearDraft: false, uploads: entry.retry.uploads });
  };

  const pendingUploads = () => uploadsRef.current.map(({ name, content, contentType }) => ({ name, content, contentType }));

  const sendDraft = () => {
    if (readingRef.current) return;
    void submit(draft, { echo: true, clearDraft: true, uploads: pendingUploads() });
  };

  // A starter is sent with the files already attached, which leave the composer with it.
  const sendStarter = (starter: string) => {
    if (readingRef.current) return;
    void submit(starter, { echo: true, clearDraft: false, clearUploads: true, uploads: pendingUploads() });
  };

  useEffect(() => {
    if (acceptFiles) return;
    uploadGeneration.current += 1;
    setUploads(() => []);
    setUploadError(null);
  }, [acceptFiles, setUploads]);

  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    sendDraft();
  };

  const onComposerKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    const { key, shiftKey, nativeEvent } = event;
    if (!isSendKey({ key, shiftKey, isComposing: nativeEvent.isComposing, keyCode: nativeEvent.keyCode })) return;
    event.preventDefault();
    sendDraft();
  };

  const onFilesPicked = async (event: ChangeEvent<HTMLInputElement>) => {
    const picked = Array.from(event.target.files ?? []);
    event.target.value = "";
    if (picked.length === 0 || readingRef.current) return;
    const limit = uploadLimitError(uploadsRef.current, picked);
    if (limit) {
      setUploadError(limit);
      return;
    }
    const generation = uploadGeneration.current;
    readingRef.current = true;
    setReading(true);
    try {
      const read = await Promise.all(
        picked.map(async (file) => ({
          name: file.name,
          content: await readBase64(file),
          contentType: uploadContentType(file),
          size: file.size,
        })),
      );
      // A read that finishes after attachments were switched off, even if back on since, is dropped.
      if (acceptFilesRef.current && generation === uploadGeneration.current) setUploads((current) => [...current, ...read]);
      setUploadError(null);
    } catch {
      setUploadError("Couldn't read that file. Try again.");
    } finally {
      readingRef.current = false;
      setReading(false);
    }
    composer.current?.focus();
  };

  const removeUpload = (index: number) => {
    setUploads((current) => current.filter((_, at) => at !== index));
    setUploadError(null);
  };

  return (
    <section className={cn("flex h-full min-h-0 w-full flex-col overflow-hidden", className)} aria-label="Agent chat">
      <div
        ref={scroller}
        className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-4 py-4"
        role="log"
        aria-live="polite"
        aria-busy={pending}
        aria-relevant="additions"
      >
        {entries.length === 0 && !pending ? (
          <div className="flex h-full flex-col items-center justify-center gap-4 text-center">
            <p className="text-base font-semibold">{emptyTitle}</p>
            {starters.length > 0 && (
              <div className="flex max-w-xl flex-wrap justify-center gap-2">
                {starters.map((starter) => (
                  <Button key={starter} type="button" variant="outline" size="sm" disabled={reading} onClick={() => sendStarter(starter)}>
                    {starter}
                  </Button>
                ))}
              </div>
            )}
          </div>
        ) : (
          <ol className="mx-auto flex w-full max-w-3xl flex-col gap-4">
            {entries.map((entry) => (
              <li key={entry.id} data-role={entry.role} className="flex min-w-0 flex-col">
                {entry.role === "user" && (
                  <div className="ml-auto flex max-w-[85%] flex-col items-end gap-1">
                    {entry.uploads.length > 0 && (
                      <ul className="flex flex-wrap justify-end gap-1" aria-label="Attached files">
                        {entry.uploads.map((upload, index) => (
                          <li
                            key={`${upload.name}-${index}`}
                            data-sent-upload={upload.name}
                            className="flex max-w-56 items-center gap-1 rounded-md border border-border bg-muted px-2 py-1 text-xs"
                          >
                            <FileText className="size-3.5 shrink-0" aria-hidden />
                            <span className="truncate">{upload.name}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                    <div className="whitespace-pre-wrap break-words rounded-2xl bg-primary px-4 py-2 text-sm text-primary-foreground">
                      {entry.text}
                    </div>
                  </div>
                )}
                {entry.role === "agent" && (
                  <div className="group flex min-w-0 flex-col gap-3">
                    {entry.text ? (
                      <AnswerMarkdown>{entry.text}</AnswerMarkdown>
                    ) : entry.files.length === 0 ? (
                      <div className="flex flex-wrap items-center gap-2">
                        <p className="text-sm italic text-muted-foreground">
                          {entry.dropped === 0
                            ? "The agent returned an empty answer."
                            : entry.dropped === 1
                              ? "1 file could not be displayed."
                              : `${entry.dropped} files could not be displayed.`}
                        </p>
                        <Button
                          type="button"
                          variant="outline"
                          size="xs"
                          disabled={pending || !canRetry(entry.retry)}
                          onClick={() => retry(entry)}
                        >
                          <RotateCcw aria-hidden />
                          Retry
                        </Button>
                      </div>
                    ) : null}
                    {entry.dropped > 0 && (entry.text || entry.files.length > 0) && (
                      <p className="text-sm italic text-muted-foreground">
                        {entry.dropped === 1 ? "1 file could not be displayed." : `${entry.dropped} files could not be displayed.`}
                      </p>
                    )}
                    {entry.files.length > 0 && (
                      <div className="flex flex-col items-start gap-2">
                        {entry.files.map((file, index) => (
                          <AgentFile key={`${file.name}-${index}`} file={file} />
                        ))}
                      </div>
                    )}
                    {entry.text && (
                      <div className="opacity-60 transition-opacity group-hover:opacity-100 focus-within:opacity-100">
                        <CopyButton text={entry.text} />
                      </div>
                    )}
                  </div>
                )}
                {entry.role === "error" && (
                  <div
                    role="alert"
                    className="flex flex-wrap items-center gap-2 rounded-md border border-destructive/40 bg-destructive/5 px-3 py-2 text-sm text-destructive"
                  >
                    <span className="min-w-0 flex-1 break-words">{entry.text}</span>
                    <Button
                      type="button"
                      variant="outline"
                      size="xs"
                      disabled={pending || !canRetry(entry.retry)}
                      onClick={() => retry(entry)}
                    >
                      <RotateCcw aria-hidden />
                      Retry
                    </Button>
                  </div>
                )}
              </li>
            ))}
            {pending && (
              <li data-role="pending" className="flex items-center gap-2 text-sm text-muted-foreground">
                <span className="flex gap-1" aria-hidden>
                  <span className="size-1.5 animate-bounce rounded-full bg-current [animation-delay:-0.3s]" />
                  <span className="size-1.5 animate-bounce rounded-full bg-current [animation-delay:-0.15s]" />
                  <span className="size-1.5 animate-bounce rounded-full bg-current" />
                </span>
                Thinking…
              </li>
            )}
          </ol>
        )}
      </div>
      <form onSubmit={onSubmit} className="shrink-0 border-t border-border bg-background px-4 py-3">
        {uploads.length > 0 && (
          <ul className="mx-auto mb-2 flex w-full max-w-3xl flex-wrap gap-1" aria-label="Files to send">
            {uploads.map((upload, index) => (
              <li
                key={`${upload.name}-${index}`}
                data-upload={upload.name}
                className="flex max-w-60 items-center gap-1 rounded-md border border-border bg-muted py-0.5 pl-2 pr-0.5 text-xs"
              >
                <FileText className="size-3.5 shrink-0" aria-hidden />
                <span className="truncate">{upload.name}</span>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-xs"
                  aria-label={`Remove ${upload.name}`}
                  disabled={pending || reading}
                  onClick={() => removeUpload(index)}
                >
                  <X aria-hidden />
                </Button>
              </li>
            ))}
          </ul>
        )}
        {uploadError && (
          <p role="alert" data-upload-error className="mx-auto mb-2 w-full max-w-3xl text-xs text-destructive">
            {uploadError}
          </p>
        )}
        <div className="mx-auto flex w-full max-w-3xl items-end gap-2 rounded-xl border border-input bg-background p-2 focus-within:ring-2 focus-within:ring-ring">
          {acceptFiles && (
            <>
              <input
                ref={filePicker}
                type="file"
                multiple
                hidden
                data-file-input
                onChange={(event) => void onFilesPicked(event)}
              />
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                aria-label="Attach files"
                disabled={pending || reading}
                onClick={() => filePicker.current?.click()}
              >
                <Paperclip aria-hidden />
              </Button>
            </>
          )}
          <label htmlFor={inputId} className="sr-only">
            Message
          </label>
          <textarea
            id={inputId}
            ref={composer}
            value={draft}
            rows={1}
            placeholder={placeholder}
            disabled={pending}
            onChange={(event) => setDraft(event.target.value)}
            onKeyDown={onComposerKeyDown}
            className="field-sizing-content max-h-40 min-h-8 flex-1 resize-none bg-transparent px-2 py-1.5 text-sm leading-5 outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-60"
          />
          <Button type="submit" size="icon-sm" aria-label="Send" disabled={pending || reading || (!draft.trim() && uploads.length === 0)}>
            <ArrowUp aria-hidden />
          </Button>
        </div>
      </form>
    </section>
  );
}
