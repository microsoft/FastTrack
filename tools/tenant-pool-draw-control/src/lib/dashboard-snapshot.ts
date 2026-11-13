// Loads a dashboard's NDJSON data snapshot: a header object with `rowCount` on the
// first line, then one JSON row per line.
//
// The body is decoded from gzip at most once, and only when its own first bytes are
// the gzip signature. Neither the file name nor a `Content-Encoding` header says what
// `fetch` hands back: a `.gz` file served with `Content-Encoding: gzip` (the dev
// preview) reaches the page already decoded, while the same file served as opaque
// bytes still needs one decode. Piping that already-decoded body through
// `DecompressionStream("gzip")` fails with "incorrect header check".

export type DashboardSnapshotFailure =
  | "http"
  | "empty"
  | "malformed"
  | "incomplete";

export class DashboardSnapshotError extends Error {
  readonly reason: DashboardSnapshotFailure;

  constructor(reason: DashboardSnapshotFailure, message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = "DashboardSnapshotError";
    this.reason = reason;
  }
}

export type DashboardSnapshotHeader = { rowCount: number } & Record<string, unknown>;

export interface DashboardSnapshot<Row, Header extends object> {
  header: Header & DashboardSnapshotHeader;
  rows: Row[];
}

export interface LoadNdjsonSnapshotOptions {
  signal?: AbortSignal;
}

const GZIP_SIGNATURE = [0x1f, 0x8b] as const;
const ROWS_PER_YIELD = 10_000;

const yieldToBrowser = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

function isAbort(error: unknown): boolean {
  return error instanceof DOMException && error.name === "AbortError";
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Reads just enough of the body to see its first two bytes, then replays them ahead
// of the rest, so the bytes are inspected without buffering the whole snapshot.
async function decodeOnce(
  body: ReadableStream<Uint8Array>,
): Promise<ReadableStream<Uint8Array> | null> {
  const reader = body.getReader();
  const head: Uint8Array[] = [];
  let size = 0;
  while (size < GZIP_SIGNATURE.length) {
    const { value, done } = await reader.read();
    if (done) break;
    if (value.byteLength > 0) {
      head.push(value);
      size += value.byteLength;
    }
  }
  if (size === 0) return null;

  const first = head[0];
  const second = first.byteLength > 1 ? first[1] : head[1]?.[0];
  const gzipped = first[0] === GZIP_SIGNATURE[0] && second === GZIP_SIGNATURE[1];

  const replay = new ReadableStream<Uint8Array>({
    start(controller) {
      for (const chunk of head) controller.enqueue(chunk);
    },
    async pull(controller) {
      const { value, done } = await reader.read();
      if (done) controller.close();
      else controller.enqueue(value);
    },
    cancel(reason) {
      return reader.cancel(reason);
    },
  });
  return gzipped ? replay.pipeThrough(new DecompressionStream("gzip")) : replay;
}

/**
 * Fetches and parses an NDJSON snapshot. Rejects with a `DashboardSnapshotError` when
 * the request fails, the body is empty or not valid NDJSON, or the number of rows
 * differs from the header's `rowCount`; it never resolves with partial or empty data
 * in place of a failure. An aborted `signal` rejects with its `AbortError`.
 */
export async function loadNdjsonSnapshot<
  Row = unknown,
  Header extends object = Record<string, unknown>,
>(
  source: string | URL,
  options: LoadNdjsonSnapshotOptions = {},
): Promise<DashboardSnapshot<Row, Header>> {
  const { signal } = options;
  let response: Response;
  try {
    response = await fetch(source, { signal });
  } catch (error) {
    if (isAbort(error)) throw error;
    throw new DashboardSnapshotError("http", "The data snapshot could not be downloaded.", {
      cause: error,
    });
  }
  if (!response.ok) {
    throw new DashboardSnapshotError(
      "http",
      `The data snapshot could not be downloaded (HTTP ${response.status}).`,
    );
  }
  if (!response.body) {
    throw new DashboardSnapshotError("empty", "The data snapshot is empty.");
  }

  let header: (Header & DashboardSnapshotHeader) | null = null;
  const rows: Row[] = [];
  let lineNumber = 0;

  const acceptLine = (line: string) => {
    lineNumber += 1;
    if (line.trim() === "") return;
    let value: unknown;
    try {
      value = JSON.parse(line);
    } catch (error) {
      throw new DashboardSnapshotError(
        "malformed",
        `The data snapshot is not valid NDJSON (line ${lineNumber}).`,
        { cause: error },
      );
    }
    if (header === null) {
      const rowCount = isPlainObject(value) ? value.rowCount : undefined;
      if (
        typeof rowCount !== "number" ||
        !Number.isSafeInteger(rowCount) ||
        rowCount < 0
      ) {
        throw new DashboardSnapshotError(
          "malformed",
          "The data snapshot's first line must be a header object with a whole-number rowCount.",
        );
      }
      header = value as Header & DashboardSnapshotHeader;
      return;
    }
    if (rows.length >= header.rowCount) {
      throw new DashboardSnapshotError(
        "malformed",
        `The data snapshot has more rows than its header's rowCount of ${header.rowCount}.`,
      );
    }
    rows.push(value as Row);
  };

  try {
    const bytes = await decodeOnce(response.body);
    if (bytes === null) {
      throw new DashboardSnapshotError("empty", "The data snapshot is empty.");
    }
    const reader = bytes
      .pipeThrough(new TextDecoderStream("utf-8", { fatal: true }))
      .getReader();
    let pending = "";
    let nextYield = ROWS_PER_YIELD;
    for (;;) {
      if (signal?.aborted) {
        await reader.cancel(signal.reason).catch(() => undefined);
        throw signal.reason;
      }
      const { value, done } = await reader.read();
      if (done) break;
      pending += value;
      let start = 0;
      let newline = pending.indexOf("\n", start);
      while (newline >= 0) {
        const end = newline > start && pending[newline - 1] === "\r" ? newline - 1 : newline;
        acceptLine(pending.slice(start, end));
        start = newline + 1;
        newline = pending.indexOf("\n", start);
      }
      pending = pending.slice(start);
      if (rows.length >= nextYield) {
        nextYield = rows.length + ROWS_PER_YIELD;
        await yieldToBrowser();
      }
    }
    if (pending !== "") acceptLine(pending);
  } catch (error) {
    if (error instanceof DashboardSnapshotError || isAbort(error) || error === signal?.reason) {
      throw error;
    }
    throw new DashboardSnapshotError(
      "malformed",
      "The data snapshot could not be decoded; it may be corrupt or cut short.",
      { cause: error },
    );
  }

  const parsed = header as (Header & DashboardSnapshotHeader) | null;
  if (parsed === null) {
    throw new DashboardSnapshotError("empty", "The data snapshot is empty.");
  }
  if (rows.length !== parsed.rowCount) {
    throw new DashboardSnapshotError(
      "incomplete",
      `The data snapshot is incomplete: ${rows.length} of ${parsed.rowCount} rows arrived.`,
    );
  }
  return { header: parsed, rows };
}
