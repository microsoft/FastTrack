/* Query cache — template infra, LOCKED: do not edit.
 *
 * Saves the results of queries marked `meta: { persist: true }` in the
 * viewer's browser (IndexedDB) and puts them back when a page that enables the
 * cache is opened again, so the page paints at once while TanStack Query
 * refetches in the background. Off unless the app calls
 * `setQueryCacheEnabled(true, client)`; today only `<DashboardPage savedData>`
 * does, and the author opts in when the app is built. Loading follows imports,
 * not calls: an app that imports nothing that imports this module never loads it.
 *
 * Saved data is discarded when:
 * - the tenant, the user, the app or the build differs from when it was saved;
 * - the viewer has not opened a page that enables the cache for 7 days;
 * - any query, or any `useMutation` write that rejects, fails with 401, 403 or
 *   442, or the connector policy monitor sees
 *   a block, which also stops saving until the page is reloaded. This holds
 *   after the cache has turned itself off for any other reason too;
 * - a later version switches saving off (`discardQueryCache`, run by
 *   `setQueryCacheEnabled(false, client)`).
 *
 * Any storage failure (strict sandbox, private browsing, quota, no host
 * identity) leaves the app on its in-memory cache and logs one line.
 */
import { useSyncExternalStore } from "react";
import type { Query, QueryCacheNotifyEvent, QueryClient } from "@tanstack/react-query";
import { isConnectorPolicyBlock } from "./connector-error";
import { isConnectorPolicyBlocked, subscribeConnectorPolicyBlock } from "./connector-policy-monitor";

const SCHEMA_VERSION = "1";
const DB_PREFIX = "aether-query-cache:";
const DB_VERSION = 1;
const META_STORE = "meta";
const META_KEY = "meta";
const ENTRY_STORE = "entries";

export const MAX_IDLE_MS = 7 * 24 * 60 * 60 * 1000;
/** Wipes tried on one page before a cache whose storage cannot be deleted gives up. */
export const MAX_WIPE_ATTEMPTS = 3;
export const ENTRY_LIMIT_BYTES = 1024 * 1024;
export const TOTAL_LIMIT_BYTES = 5 * 1024 * 1024;
const IDENTITY_TIMEOUT_MS = 3000;
// The build id waits on a delete that waits on the host for the app id; until
// start-up ends, every persisted result is held in memory to be saved.
const BUILD_ID_TIMEOUT_MS = 10_000;
const ACCESS_LOSS_STATUS = new Set([401, 403, 442]);
const ACCESS_LOSS_TEXT = /\b(401|403|442)\b/;

export interface SavedEntry {
  key: string;
  /** The meta stamp current when this entry was written. */
  stamp: string;
  data: unknown;
  updatedAt: number;
  savedAt: number;
  bytes: number;
}

export interface CacheMeta {
  buster: string;
  /**
   * New each time the saved data is wiped (a different user, app or build,
   * 7 days idle). Another tab still running with the old
   * identity writes entries under the old stamp, and those are never restored.
   */
  stamp: string;
  openedAt: number;
}

export interface CacheStore {
  /**
   * Keeps the saved data when the meta record matches `buster` and was opened
   * within MAX_IDLE_MS, otherwise clears it; then records this visit. All in
   * one transaction, so another tab's wipe cannot land between the check and
   * the write and be undone by it.
   */
  claim(buster: string, now: number, newStamp: string): Promise<{ stamp: string; valid: boolean }>;
  readAll(): Promise<SavedEntry[]>;
  put(entry: SavedEntry): Promise<void>;
  remove(key: string): Promise<void>;
  clear(): Promise<void>;
}

export interface CacheIdentity {
  tenantId: string;
  objectId: string;
  appId: string;
}

export interface QueryCacheDeps {
  getIdentity(): Promise<CacheIdentity | undefined>;
  openStore(name: string): Promise<CacheStore>;
  now(): number;
  sha256(text: string): Promise<string>;
  newStamp(): string;
  isPolicyBlocked(): boolean;
  /** Calls `listener` when the connector policy monitor sees a block. */
  onPolicyBlocked(listener: () => void): () => void;
  /** Deletes every query-cache database in this origin: the wipe of last resort. */
  deleteAllStores(): Promise<void>;
  log(message: string): void;
  identityTimeoutMs: number;
  buildIdTimeoutMs: number;
}

export type QueryCacheState = "off" | "starting" | "on";

interface Runtime {
  client: QueryClient;
  deps: QueryCacheDeps;
  store?: CacheStore;
  buster?: string;
  stamp?: string;
  entries: Map<string, SavedEntry>;
  /** Queries showing a saved result that no fetch has replaced yet. */
  restored: Set<string>;
  loaded: boolean;
  stopped: boolean;
  wiped: boolean;
  wipeFailures: number;
  chain: Promise<unknown>;
  unsubscribe(): void;
}

let runtime: Runtime | null = null;
let state: QueryCacheState = "off";
const listeners = new Set<() => void>();

function setState(next: QueryCacheState): void {
  if (state === next) return;
  state = next;
  for (const listener of listeners) listener();
}

function subscribeState(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getQueryCacheState(): QueryCacheState {
  return state;
}

export function useQueryCacheState(): QueryCacheState {
  return useSyncExternalStore(subscribeState, getQueryCacheState, getQueryCacheState);
}

function isPersisted(query: Query): boolean {
  return (query.meta as { persist?: unknown } | undefined)?.persist === true;
}

// Connector errors are plain objects with a numeric `status`, sometimes
// wrapped as a `cause` (the shape query-client.ts's isTransient reads). A
// policy block is whatever connector-error.ts's isConnectorPolicyBlock says it is.
export function isAccessLoss(error: unknown, depth = 0): boolean {
  if (typeof error === "string") return ACCESS_LOSS_TEXT.test(error);
  if (!error || typeof error !== "object" || depth > 3) return false;
  if (depth === 0 && isConnectorPolicyBlock(error)) return true;
  const { status, statusCode, message, cause } = error as Record<string, unknown>;
  let coded = false;
  for (const value of [status, statusCode]) {
    const code = typeof value === "string" && /^\d+$/.test(value) ? Number(value) : value;
    if (typeof code !== "number") continue;
    coded = true;
    if (ACCESS_LOSS_STATUS.has(code)) return true;
  }
  // A numeric status decides; the message is read only when there is none.
  if (!coded && typeof message === "string" && ACCESS_LOSS_TEXT.test(message)) return true;
  return cause !== undefined && isAccessLoss(cause, depth + 1);
}

function enqueue<T>(rt: Runtime, task: () => Promise<T>): Promise<T | undefined> {
  const run = rt.chain.then(task, task);
  rt.chain = run.catch(() => undefined);
  return run.catch((error: unknown) => {
    turnOff(rt, `storage error (${errorName(error)})`);
    return undefined;
  });
}

function errorName(error: unknown): string {
  return error instanceof Error ? error.name : typeof error;
}

function turnOff(rt: Runtime, reason: string, wipe = false): void {
  if (!rt.stopped) {
    rt.stopped = true;
    setState("off");
    rt.deps.log(`[query-cache] off: ${reason}`);
  } else if (wipe && !rt.wiped) {
    rt.deps.log(`[query-cache] deleting saved data: ${reason}`);
  }
  // A stop that keeps the saved data keeps listening, so a later 401, 403 or
  // 442 still deletes it.
  if (!wipe || rt.wiped) return;
  rt.wiped = true;
  rt.entries.clear();
  // Saved results already on screen go too: the tiles fetch again, and a
  // viewer who lost access sees the error rather than the saved copy.
  const shown = new Set(rt.restored);
  rt.restored.clear();
  if (shown.size > 0) {
    queueMicrotask(() => {
      void rt.client.resetQueries({ predicate: (query) => shown.has(query.queryHash) });
    });
  }
  // Runs after start-up has opened the store, so a wipe asked for while the
  // identity was still loading still clears the saved data. With no store
  // open, or a clear that fails, the databases themselves are deleted. If both
  // fail, a 401, 403 or 442 arriving after the failure tries again, up to
  // MAX_WIPE_ATTEMPTS in all; then the listening stops, as it does once a wipe
  // goes through.
  rt.chain = rt.chain
    .then(() => (rt.store ? rt.store.clear() : rt.deps.deleteAllStores()))
    .catch((error: unknown) => {
      rt.deps.log(`[query-cache] could not clear saved data (${errorName(error)}); deleting it`);
      return rt.deps.deleteAllStores();
    })
    .then(
      () => rt.unsubscribe(),
      (error: unknown) => {
        rt.deps.log(`[query-cache] could not delete saved data (${errorName(error)})`);
        rt.wipeFailures += 1;
        if (rt.wipeFailures < MAX_WIPE_ATTEMPTS) rt.wiped = false;
        else rt.unsubscribe();
      },
    );
}

function restore(rt: Runtime, query: Query): void {
  if (rt.stopped || !rt.loaded || !isPersisted(query)) return;
  if (query.state.data !== undefined) return;
  if (rt.client.getQueryCache().get(query.queryHash) !== query) return;
  const entry = rt.entries.get(query.queryHash);
  if (!entry || rt.deps.now() - entry.updatedAt > MAX_IDLE_MS) return;
  // Keeps the saved time, so a result older than staleTime refetches at once
  // and FreshnessBadge shows its real age.
  // Registered first: setQueryData notifies synchronously, and a wipe in that
  // notification must find this tile to take it off the screen.
  rt.restored.add(query.queryHash);
  rt.client.setQueryData(query.queryKey, entry.data, { updatedAt: entry.updatedAt });
}

function sizeOf(data: unknown): number | undefined {
  try {
    const json = JSON.stringify(data);
    return json === undefined ? undefined : json.length * 2;
  } catch {
    return undefined;
  }
}

function save(rt: Runtime, query: Query): void {
  const key = query.queryHash;
  const data = query.state.data;
  const updatedAt = query.state.dataUpdatedAt;
  const bytes = sizeOf(data);
  void enqueue(rt, async () => {
    const store = rt.store;
    const stamp = rt.stamp;
    if (rt.stopped || !store || !stamp) return;
    // Not measurable or too big: not saved, and an older copy must not outlive it.
    // Another tab may have saved it, so remove it even when this tab never saw it.
    if (bytes === undefined || bytes > ENTRY_LIMIT_BYTES) {
      rt.entries.delete(key);
      await store.remove(key);
      return;
    }
    const older = [...rt.entries.values()]
      .filter((entry) => entry.key !== key)
      .sort((a, b) => a.savedAt - b.savedAt);
    let total = bytes + older.reduce((sum, entry) => sum + entry.bytes, 0);
    while (total > TOTAL_LIMIT_BYTES && older.length > 0) {
      const oldest = older.shift()!;
      total -= oldest.bytes;
      rt.entries.delete(oldest.key);
      await store.remove(oldest.key);
    }
    const entry: SavedEntry = { key, stamp, data, updatedAt, savedAt: rt.deps.now(), bytes };
    try {
      await store.put(entry);
    } catch {
      // Not cloneable or over quota: this result is not saved, and an older
      // copy must not outlive it.
      rt.entries.delete(key);
      await store.remove(key);
      return;
    }
    rt.entries.set(key, entry);
  });
}

function onEvent(rt: Runtime, event: QueryCacheNotifyEvent): void {
  if (rt.deps.isPolicyBlocked()) {
    turnOff(rt, "connector blocked", true);
    return;
  }
  if (event.type === "added") {
    const { query } = event;
    if (isPersisted(query)) queueMicrotask(() => restore(rt, query));
    return;
  }
  if (event.type !== "updated") return;
  const { action, query } = event;
  if ((action.type === "failed" || action.type === "error") && isAccessLoss(action.error)) {
    turnOff(rt, "access lost", true);
    return;
  }
  // `manual` marks setQueryData, which is how a restore lands: never re-saved.
  if (action.type !== "success" || action.manual) return;
  // A tile showing fresh data is no longer showing the saved copy, even after
  // a stop, so a later wipe leaves it on screen.
  rt.restored.delete(query.queryHash);
  if (!rt.stopped && isPersisted(query)) save(rt, query);
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | undefined> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => resolve(undefined), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error: unknown) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
}

async function boot(rt: Runtime, buildIdSource: string | Promise<string>): Promise<void> {
  const { deps } = rt;
  const buildId = await withTimeout(Promise.resolve(buildIdSource), deps.buildIdTimeoutMs);
  if (!buildId) return turnOff(rt, "no build id");
  if (deps.isPolicyBlocked()) turnOff(rt, "connector blocked", true);
  const identity = await withTimeout(deps.getIdentity(), deps.identityTimeoutMs);
  if (!identity?.tenantId || !identity.objectId || !identity.appId) {
    return turnOff(rt, "no identity");
  }
  const userHash = await deps.sha256(identity.objectId);
  rt.store = await deps.openStore(`${DB_PREFIX}${identity.appId}`);
  // Stopped while starting: a pending wipe runs on the chain after this.
  if (rt.stopped) return;
  const buster = [SCHEMA_VERSION, identity.tenantId, userHash, identity.appId, buildId].join("|");
  const now = deps.now();
  const { stamp, valid } = await rt.store.claim(buster, now, deps.newStamp());
  rt.buster = buster;
  rt.stamp = stamp;
  const saved = valid ? await rt.store.readAll() : [];
  if (rt.stopped) return;
  for (const entry of saved) {
    if (entry.stamp !== stamp || now - entry.updatedAt > MAX_IDLE_MS) {
      await rt.store.remove(entry.key);
    } else {
      rt.entries.set(entry.key, entry);
    }
  }
  if (rt.stopped) return;
  rt.loaded = true;
  setState("on");
  let restored = 0;
  for (const query of rt.client.getQueryCache().getAll()) {
    const before = query.state.data;
    restore(rt, query);
    if (before === undefined && query.state.data !== undefined) restored += 1;
  }
  deps.log(`[query-cache] on, ${rt.entries.size} saved, ${restored} restored at start`);
}

async function defaultIdentity(): Promise<CacheIdentity> {
  const [{ getUser }, { getContext }] = await Promise.all([
    import("@microsoft/managed-apps/auth"),
    import("@microsoft/managed-apps/app"),
  ]);
  const [user, context] = await Promise.all([getUser(), getContext()]);
  return { tenantId: user.tenantId, objectId: user.objectId, appId: context.app.appId };
}

async function defaultSha256(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

const DEFAULT_DEPS: QueryCacheDeps = {
  getIdentity: defaultIdentity,
  openStore: (name) => openIndexedDbStore(name),
  now: () => Date.now(),
  sha256: defaultSha256,
  newStamp: () => crypto.randomUUID(),
  isPolicyBlocked: isConnectorPolicyBlocked,
  onPolicyBlocked: (listener) =>
    subscribeConnectorPolicyBlock(() => {
      if (isConnectorPolicyBlocked()) listener();
    }),
  deleteAllStores,
  // console.info stays in the browser: console-capture forwards log, warn and
  // error to the parent frame, but not info.
  log: (message) => console.info(message),
  identityTimeoutMs: IDENTITY_TIMEOUT_MS,
  buildIdTimeoutMs: BUILD_ID_TIMEOUT_MS,
};

/**
 * Starts the cache once per page. Resolves when saved data is loaded or the
 * cache is off. It listens at once; a `buildId` still loading is awaited,
 * for at most `buildIdTimeoutMs`, before the identity is read.
 */
export function startQueryCache(
  client: QueryClient,
  options: { buildId: string | Promise<string> } & Partial<QueryCacheDeps>,
): Promise<void> {
  if (runtime) return runtime.chain.then(() => undefined);
  const { buildId, ...overrides } = options;
  const rt: Runtime = {
    client,
    deps: { ...DEFAULT_DEPS, ...overrides },
    entries: new Map(),
    restored: new Set(),
    loaded: false,
    stopped: false,
    wiped: false,
    wipeFailures: 0,
    chain: Promise.resolve(),
    unsubscribe: () => undefined,
  };
  runtime = rt;
  setState("starting");
  // Storage work queued before start-up ends (saves, a wipe) waits for it.
  let release: () => void = () => undefined;
  rt.chain = new Promise<void>((resolve) => (release = resolve));
  // Subscribe before start-up finishes, so results that arrive while the
  // identity loads are still saved and a 401 meanwhile still wipes.
  const offQueries = client.getQueryCache().subscribe((event) => {
    try {
      onEvent(rt, event);
    } catch (error) {
      // An event this module could not judge may have been a lost access.
      turnOff(rt, `error (${errorName(error)})`, true);
    }
  });
  const offPolicy = rt.deps.onPolicyBlocked(() => turnOff(rt, "connector blocked", true));
  // A write the viewer is no longer allowed to make means they lost access too.
  const offMutations = client.getMutationCache().subscribe((event) => {
    try {
      if (event.type !== "updated") return;
      const { action } = event;
      if ((action.type === "failed" || action.type === "error") && isAccessLoss(action.error)) {
        turnOff(rt, "access lost", true);
      }
    } catch (error) {
      turnOff(rt, `error (${errorName(error)})`, true);
    }
  });
  rt.unsubscribe = () => {
    offQueries();
    offPolicy();
    offMutations();
  };
  return boot(rt, buildId)
    .catch((error: unknown) => turnOff(rt, `storage unavailable (${errorName(error)})`))
    .finally(release)
    .then(() => rt.chain)
    .then(() => undefined);
}

let discarding: Promise<void> | undefined;

// Loaded on first use: Vite's build-id module exists only in a Vite build or
// dev server, and only an app that saves data needs it.
async function loadBuildId(): Promise<string> {
  return (await import("virtual:aether-build-id")).default;
}

/**
 * The app's switch. The saved data is the app's, not one page's: the first
 * call with `enabled` starts the cache on `client`, whichever pages rendered
 * before it. A call without it deletes what an earlier version of this app
 * saved, once per page load and only while nothing has started the cache; a
 * later start waits for that delete.
 */
export function setQueryCacheEnabled(
  enabled: boolean,
  client: QueryClient,
  options: { loadBuildId?: () => Promise<string>; discard?: () => Promise<void> } = {},
): void {
  if (runtime) return;
  if (enabled) {
    const load = options.loadBuildId ?? loadBuildId;
    void startQueryCache(client, { buildId: discarding ? discarding.then(load) : load() });
  } else if (!discarding) {
    discarding = (options.discard ?? discardQueryCache)();
  }
}

export function resetQueryCacheForTests(): void {
  runtime?.unsubscribe();
  runtime = null;
  discarding = undefined;
  setState("off");
}

/** Every database name in this origin, or undefined where the browser cannot list them. */
async function listStoreNames(): Promise<string[] | undefined> {
  const idb = globalThis.indexedDB;
  if (!idb) throw new Error("no IndexedDB");
  if (typeof idb.databases !== "function") return undefined;
  return (await idb.databases()).flatMap((db) => (db.name ? [db.name] : []));
}

/** "blocked" while another tab holds the database open; the delete then finishes once it lets go. */
function deleteStoreByName(name: string): Promise<"deleted" | "blocked"> {
  return new Promise((resolve, reject) => {
    const request = globalThis.indexedDB.deleteDatabase(name);
    request.onsuccess = () => resolve("deleted");
    request.onblocked = () => resolve("blocked");
    request.onerror = () => reject(request.error);
  });
}

// In the Power Apps player each app has its own origin, so these are this
// app's; anywhere else, deleting another app's copy only costs it a refetch.
async function deleteAllStores(): Promise<void> {
  const names = await listStoreNames();
  if (!names) throw new Error("cannot list databases");
  await Promise.all(names.filter((name) => name.startsWith(DB_PREFIX)).map(deleteStoreByName));
}

export interface DiscardDeps {
  listStores(): Promise<string[] | undefined>;
  getAppId(): Promise<string | undefined>;
  deleteStore(name: string): Promise<"deleted" | "blocked">;
  log(message: string): void;
}

const DEFAULT_DISCARD_DEPS: DiscardDeps = {
  listStores: listStoreNames,
  getAppId: async () => {
    const { getContext } = await import("@microsoft/managed-apps/app");
    return (await getContext()).app.appId;
  },
  deleteStore: deleteStoreByName,
  log: (message) => console.info(message),
};

/**
 * Runs when saved data is switched off: deletes this app's saved data that an
 * earlier version left in the browser. Loads nothing when the browser lists
 * no query-cache data at all; never throws, and logs every case it cannot settle.
 */
export async function discardQueryCache(overrides: Partial<DiscardDeps> = {}): Promise<void> {
  const deps = { ...DEFAULT_DISCARD_DEPS, ...overrides };
  let names: string[] | undefined;
  try {
    names = await deps.listStores();
  } catch (error) {
    deps.log(`[query-cache] saved data not checked: storage unavailable (${errorName(error)})`);
    return;
  }
  try {
    if (names && !names.some((name) => name.startsWith(DB_PREFIX))) return;
    // No deadline here: a slow host delays the delete, and the cache start waiting on it gives up after BUILD_ID_TIMEOUT_MS.
    const appId = await deps.getAppId();
    if (!appId) {
      deps.log("[query-cache] saved data not deleted: no app id");
      return;
    }
    const name = `${DB_PREFIX}${appId}`;
    if (names && !names.includes(name)) return;
    const outcome = await deps.deleteStore(name);
    deps.log(
      outcome === "blocked"
        ? "[query-cache] saved data will be deleted when the app's other tabs close: saving is off"
        : "[query-cache] saved data deleted: saving is off",
    );
  } catch (error) {
    deps.log(`[query-cache] could not delete saved data (${errorName(error)})`);
  }
}

/** The meta record a visit writes, and whether the saved data it finds may be kept. */
export function claimMeta(
  meta: CacheMeta | undefined,
  buster: string,
  now: number,
  newStamp: string,
): { meta: CacheMeta; valid: boolean } {
  const valid =
    meta?.buster === buster && !!meta.stamp && now - meta.openedAt <= MAX_IDLE_MS;
  const stamp = valid && meta ? meta.stamp : newStamp;
  return { meta: { buster, stamp, openedAt: now }, valid };
}

function transact<T>(
  db: IDBDatabase,
  names: string[],
  mode: IDBTransactionMode,
  body: (tx: IDBTransaction) => IDBRequest<T> | void,
): Promise<T> {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(names, mode);
    let result: T;
    const request = body(tx);
    if (request) request.onsuccess = () => (result = request.result);
    tx.oncomplete = () => resolve(result);
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error ?? new Error("transaction aborted"));
  });
}

export function openIndexedDbStore(
  name: string,
  idb: IDBFactory = globalThis.indexedDB,
): Promise<CacheStore> {
  return new Promise((resolve, reject) => {
    const request = idb.open(name, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(META_STORE)) db.createObjectStore(META_STORE);
      if (!db.objectStoreNames.contains(ENTRY_STORE)) {
        db.createObjectStore(ENTRY_STORE, { keyPath: "key" });
      }
    };
    let blocked = false;
    request.onblocked = () => {
      blocked = true;
      reject(new Error("blocked"));
    };
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const db = request.result;
      // The caller has already given up on a blocked open; a late success
      // would otherwise leave a handle nobody can close.
      if (blocked) {
        db.close();
        return;
      }
      db.onversionchange = () => db.close();
      resolve({
        claim: (buster, now, newStamp) =>
          new Promise((done, fail) => {
            const tx = db.transaction([META_STORE, ENTRY_STORE], "readwrite");
            let result: { stamp: string; valid: boolean } | undefined;
            const read = tx.objectStore(META_STORE).get(META_KEY);
            read.onsuccess = () => {
              const claimed = claimMeta(read.result as CacheMeta | undefined, buster, now, newStamp);
              if (!claimed.valid) tx.objectStore(ENTRY_STORE).clear();
              tx.objectStore(META_STORE).put(claimed.meta, META_KEY);
              result = { stamp: claimed.meta.stamp, valid: claimed.valid };
            };
            tx.oncomplete = () => (result ? done(result) : fail(new Error("claim did not run")));
            tx.onerror = () => fail(tx.error);
            tx.onabort = () => fail(tx.error ?? new Error("transaction aborted"));
          }),
        readAll: () =>
          transact<SavedEntry[]>(db, [ENTRY_STORE], "readonly", (tx) =>
            tx.objectStore(ENTRY_STORE).getAll(),
          ),
        put: (entry) =>
          transact<void>(db, [ENTRY_STORE], "readwrite", (tx) => {
            tx.objectStore(ENTRY_STORE).put(entry);
          }),
        remove: (key) =>
          transact<void>(db, [ENTRY_STORE], "readwrite", (tx) => {
            tx.objectStore(ENTRY_STORE).delete(key);
          }),
        clear: () =>
          transact<void>(db, [META_STORE, ENTRY_STORE], "readwrite", (tx) => {
            tx.objectStore(META_STORE).clear();
            tx.objectStore(ENTRY_STORE).clear();
          }),
      });
    };
  });
}
