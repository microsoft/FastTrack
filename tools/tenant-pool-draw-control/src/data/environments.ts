// Rule settings and change log, persisted in this browser. Environment data
// itself is always read live from the Power Platform API and never stored here.

export const KNOWN_TYPES = ["Developer", "Sandbox", "Trial", "Production", "Default"] as const;

export interface ChangeEntry {
  id: string;
  at: string;
  action: "disable" | "enable";
  source: "bulk" | "row" | "sweep";
  updatedIds: string[];
  lockedIds: string[];
  failedIds: string[];
  /** Display name of each environment at the time of the change (id -> name). */
  names: Record<string, string>;
  /** Why an environment wasn't confirmed (id -> short reason). */
  details: Record<string, string>;
}

export interface GuardPolicy {
  types: string[];
  newWindowDays: number;
}

export interface StoredState {
  version: 2;
  log: ChangeEntry[];
  policy: GuardPolicy;
}

export const DEFAULT_POLICY: GuardPolicy = { types: ["Developer", "Trial", "Sandbox"], newWindowDays: 14 };
export const EMPTY_STATE: StoredState = { version: 2, log: [], policy: DEFAULT_POLICY };

const STORAGE_KEY = "aether:6176fb40-aac0-4c40-8f1c-57e81a27ea1a:records";

export type LoadResult =
  | { kind: "ok"; state: StoredState }
  | { kind: "empty" }
  | { kind: "invalid" }
  | { kind: "unavailable" };

const strMap = (v: unknown): Record<string, string> => {
  if (!v || typeof v !== "object" || Array.isArray(v)) return {};
  return Object.fromEntries(Object.entries(v as Record<string, unknown>).filter((kv): kv is [string, string] => typeof kv[1] === "string"));
};

const strArr = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : []);

function readPolicy(v: unknown): GuardPolicy {
  const p = v as Partial<GuardPolicy> | undefined;
  return p && Array.isArray(p.types) && typeof p.newWindowDays === "number"
    ? { types: strArr(p.types), newWindowDays: p.newWindowDays }
    : DEFAULT_POLICY;
}

function readLog(v: unknown, version: number): ChangeEntry[] {
  if (!Array.isArray(v)) return [];
  return v.flatMap((raw): ChangeEntry[] => {
    const e = raw as Record<string, unknown>;
    if (typeof e?.id !== "string" || typeof e.at !== "string") return [];
    const action = e.action === "enable" ? "enable" : "disable";
    const source = e.source === "row" || e.source === "sweep" ? e.source : "bulk";
    // Version 1 entries recorded names and environment ids; keep only the ids.
    const updatedIds = version === 1 ? strArr(e.environmentIds) : strArr(e.updatedIds);
    return [{
      id: e.id, at: e.at, action, source, updatedIds, lockedIds: strArr(e.lockedIds), failedIds: strArr(e.failedIds),
      names: strMap(e.names), details: strMap(e.details),
    }];
  });
}

export function loadState(): LoadResult {
  let raw: string | null;
  try {
    raw = window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return { kind: "unavailable" };
  }
  if (raw === null) return { kind: "empty" };
  try {
    const parsed = JSON.parse(raw) as { version?: unknown; log?: unknown; policy?: unknown };
    const version = parsed.version === undefined ? 1 : parsed.version;
    if (version !== 1 && version !== 2) return { kind: "invalid" };
    return { kind: "ok", state: { version: 2, log: readLog(parsed.log, version), policy: readPolicy(parsed.policy) } };
  } catch {
    return { kind: "invalid" };
  }
}

export type SaveResult = "saved" | "trimmed" | "failed";

/**
 * Save to this browser. If storage is full (very large runs), the oldest log
 * entries are dropped from the saved copy until it fits; the newest entry is kept.
 */
export function saveState(state: StoredState): SaveResult {
  let log = state.log;
  for (;;) {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...state, log }));
      return log.length === state.log.length ? "saved" : "trimmed";
    } catch {
      if (log.length <= 1) return "failed";
      log = log.slice(0, Math.ceil(log.length / 2));
    }
  }
}
