import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { keepPreviousData, useQuery, useQueryClient } from "@tanstack/react-query";
import { differenceInCalendarDays, format, formatDistanceToNowStrict } from "date-fns";
import { AlertTriangle, CheckCircle2, Database, Download, History, ListChecks, Lock, MousePointerClick, RefreshCw, Search, ShieldCheck, Sparkles, X } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Progress } from "@/components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Sheet, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { ConnectorErrorState, EmptyState, LoadingState } from "@/components/states";
import { cn } from "@/lib/utils";
import {
  allocationPutBody,
  NO_RECORD,
  drawsFromPool,
  fetchAllPoolSettings,
  fetchEnvironmentPage,
  fetchGroupNames,
  setTenantPool,
  type EnvRow,
  type PoolSetting,
} from "@/lib/pool-api";
import { EMPTY_STATE, KNOWN_TYPES, loadState, saveState, type ChangeEntry, type SaveResult, type StoredState } from "@/data/environments";
import { changeLogCsv, csvFileName, downloadCsv } from "@/lib/change-log-csv";
import { diagnosticHttpStatus } from "@/lib/connector-safety";

type View = "all" | "new" | "drawing" | "capped";
type StorageStatus = "ok" | "unavailable" | "invalid" | "failed";
interface RunState {
  action: "disable" | "enable";
  total: number;
  done: number;
  /** Environment currently being changed; null once the run has finished. */
  current: { id: string; name: string } | null;
  queued: Set<string>;
  updated: number;
  locked: number;
  failed: number;
  finished: boolean;
  /** Name of the environment that ended the run early after an unexpected change, if any. */
  stoppedOn?: string;
  /** The saved change-log entry for this run, once it has finished. */
  entry?: ChangeEntry;
}

function outcomeDetail(outcome: Awaited<ReturnType<typeof setTenantPool>>): string | undefined {
  switch (outcome.kind) {
    case "failed": {
      const status = diagnosticHttpStatus((outcome.error as { status?: unknown } | undefined)?.status);
      return status ? `Request failed (HTTP ${status})` : "Request failed";
    }
    case "unconfirmed":
      return "Change sent, but the read-back failed";
    case "mismatch":
      return "Read-back still shows the previous setting";
    case "incomplete":
      return "Current allocation couldn't be read reliably, so nothing was sent";
    case "unsupported":
      return "Skipped: this environment also has allocations of other credit types. Nothing was sent. Change it in the Power Platform admin center";
    case "sideEffect":
      return "Pool draw changed, but other allocation settings changed too. Check this environment";
    default:
      return undefined;
  }
}
interface PendingChange {
  action: "disable" | "enable";
  source: ChangeEntry["source"];
  targets: EnvRow[];
}

const CONNECTOR = "Power Platform for Admins V2";
const nf = new Intl.NumberFormat("en-US");

const TONE = {
  drawing: "border-amber-300 bg-amber-50 text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100",
  capped: "border-emerald-300 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-100",
  locked: "border-slate-300 bg-slate-100 text-slate-800 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200",
  failed: "border-red-300 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-950 dark:text-red-100",
  info: "border-sky-300 bg-sky-50 text-sky-900 dark:border-sky-800 dark:bg-sky-950 dark:text-sky-100",
} as const;

function initialState(): { state: StoredState; status: StorageStatus } {
  const r = loadState();
  if (r.kind === "ok") return { state: r.state, status: "ok" };
  if (r.kind === "empty") return { state: EMPTY_STATE, status: saveState(EMPTY_STATE) ? "ok" : "failed" };
  return { state: EMPTY_STATE, status: r.kind };
}

const isNew = (e: EnvRow, days: number) =>
  e.createdTime !== null && differenceInCalendarDays(new Date(), new Date(e.createdTime)) <= days;

function PoolPipe({ drawing, locked, last }: { drawing: boolean; locked: boolean; last: boolean }) {
  return (
    <svg width="64" height="72" viewBox="0 0 64 72" aria-hidden="true" className="shrink-0 self-stretch">
      <line x1="14" y1="0" x2="14" y2={last ? 36 : 72} className="stroke-primary" strokeWidth="4" strokeLinecap="round" />
      {drawing ? (
        <>
          <line x1="14" y1="36" x2="56" y2="36" className="stroke-amber-600 dark:stroke-amber-400" strokeWidth="4" strokeLinecap="round" />
          <path d="M48 30 L56 36 L48 42" fill="none" className="stroke-amber-600 dark:stroke-amber-400" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
        </>
      ) : (
        <>
          <line x1="14" y1="36" x2="28" y2="36" className="stroke-emerald-700 dark:stroke-emerald-400" strokeWidth="4" strokeLinecap="round" />
          <line x1="33" y1="26" x2="33" y2="46" className="stroke-emerald-700 dark:stroke-emerald-400" strokeWidth="3" strokeLinecap="round" />
          <line x1="39" y1="26" x2="39" y2="46" className="stroke-emerald-700 dark:stroke-emerald-400" strokeWidth="3" strokeLinecap="round" />
          <line x1="46" y1="36" x2="56" y2="36" className="stroke-muted-foreground" strokeWidth="3" strokeDasharray="2 4" strokeLinecap="round" />
        </>
      )}
      {locked && <circle cx="14" cy="36" r="6" className="fill-background stroke-slate-500" strokeWidth="2" />}
    </svg>
  );
}

export function HomePage() {
  const queryClient = useQueryClient();
  const init = useRef(initialState());
  const [data, setData] = useState<StoredState>(init.current.state);
  const [storage, setStorage] = useState<StorageStatus>(init.current.status);
  const [query, setQuery] = useState("");
  const [view, setView] = useState<View>("all");
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [pending, setPending] = useState<PendingChange | null>(null);
  const [run, setRun] = useState<RunState | null>(null);
  // Results of this session's writes (session memory only).
  const [overrides, setOverrides] = useState<Map<string, PoolSetting>>(new Map());
  const [locked, setLocked] = useState<Set<string>>(new Set());
  const [failed, setFailed] = useState<Set<string>>(new Set());
  const [cursor, setCursor] = useState<number | undefined>(undefined);
  const [history, setHistory] = useState<(number | undefined)[]>([]);

  const envQuery = useQuery({
    queryKey: ["ppadmin", "environments", { cursor }] as const,
    queryFn: () => fetchEnvironmentPage(cursor),
    placeholderData: keepPreviousData,
    retry: 1,
    staleTime: 30_000,
  });
  const poolQuery = useQuery({ queryKey: ["ppadmin", "allocations"], queryFn: fetchAllPoolSettings, retry: 1, staleTime: 30_000 });
  const groupQuery = useQuery({ queryKey: ["ppadmin", "groups"], queryFn: fetchGroupNames, retry: 1, staleTime: 300_000 });

  useEffect(() => {
    const onStorage = () => {
      if (storage !== "ok") return;
      const r = loadState();
      if (r.kind === "ok") setData(r.state);
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, [storage]);

  const commit = useCallback(
    (mutate: (s: StoredState) => StoredState) => {
      let base = data;
      if (storage === "ok") {
        const r = loadState();
        if (r.kind === "ok") base = r.state;
      }
      const next = mutate(base);
      setData(next);
      if (storage === "ok" || storage === "failed") {
        const result: SaveResult = saveState(next);
        setStorage(result === "failed" ? "failed" : "ok");
        return result;
      }
      return "failed" as SaveResult;
    },
    [data, storage],
  );

  const { policy, log } = data;
  const rows = useMemo(() => envQuery.data?.rows ?? [], [envQuery.data]);
  const settingFor = useCallback(
    (id: string) => overrides.get(id.toLowerCase()) ?? poolQuery.data?.get(id.toLowerCase()) ?? NO_RECORD,
    [overrides, poolQuery.data],
  );
  const groupName = (id: string | null) => (id ? (groupQuery.data?.get(id.toLowerCase()) ?? "an environment group") : null);
  const nameOf = (id: string) => rows.find((r) => r.environmentId === id)?.displayName ?? id;
  const entryName = (e: ChangeEntry) => (id: string) => e.names[id] ?? nameOf(id);
  const downloadEntries = (entries: ChangeEntry[], prefix: string) => {
    if (!downloadCsv(csvFileName(prefix), changeLogCsv(entries, nameOf))) toast.error("Your browser didn't allow the download.");
  };

  const types = useMemo(() => [...new Set([...KNOWN_TYPES, ...rows.map((r) => r.type)])], [rows]);
  const counts = useMemo(() => {
    const drawing = rows.filter((r) => drawsFromPool(settingFor(r.environmentId))).length;
    return { drawing, capped: rows.length - drawing };
  }, [rows, settingFor]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return rows
      .filter((e) => (typeFilter === "all" ? true : e.type === typeFilter))
      .filter((e) => {
        const d = drawsFromPool(settingFor(e.environmentId));
        return view === "new" ? isNew(e, policy.newWindowDays) : view === "drawing" ? d : view === "capped" ? !d : true;
      })
      .filter((e) => !q || e.displayName.toLowerCase().includes(q) || e.environmentId.toLowerCase().includes(q))
      .sort((a, b) => (b.createdTime ?? "").localeCompare(a.createdTime ?? ""));
  }, [rows, query, typeFilter, view, policy.newWindowDays, settingFor]);

  const sweepTargets = rows.filter((e) => policy.types.includes(e.type) && drawsFromPool(settingFor(e.environmentId)) && !locked.has(e.environmentId));
  const newDrawing = rows.filter((e) => isNew(e, policy.newWindowDays) && drawsFromPool(settingFor(e.environmentId))).length;
  const allSelected = visible.length > 0 && visible.every((e) => selected.has(e.environmentId));
  const busy = run !== null && !run.finished;

  const toggleRow = (id: string, on: boolean) =>
    setSelected((prev) => {
      const next = new Set(prev);
      if (on) next.add(id);
      else next.delete(id);
      return next;
    });

  const openPreview = (action: PendingChange["action"], source: PendingChange["source"], envs: EnvRow[]) => {
    const targets = envs.filter((e) => drawsFromPool(settingFor(e.environmentId)) === (action === "disable"));
    setPending({ action, source, targets });
  };

  const apply = async () => {
    if (!pending || pending.targets.length === 0 || busy) return;
    const { action, source, targets } = pending;
    setPending(null);
    const updated: string[] = [];
    const lockedIds: string[] = [];
    const failedIds: string[] = [];
    const names: Record<string, string> = {};
    const details: Record<string, string> = {};
    setRun({
      action, total: targets.length, done: 0, current: null,
      queued: new Set(targets.map((t) => t.environmentId)), updated: 0, locked: 0, failed: 0, finished: false,
    });
    let stoppedOn: string | undefined;
    for (const env of targets) {
      const id = env.environmentId;
      names[id] = env.displayName;
      if (stoppedOn) {
        failedIds.push(id);
        details[id] = `Not attempted: the run stopped after an unexpected change in ${stoppedOn}`;
        setRun((r) => {
          if (!r) return r;
          const queued = new Set(r.queued);
          queued.delete(id);
          return { ...r, done: r.done + 1, queued, failed: r.failed + 1 };
        });
        continue;
      }
      setRun((r) => r && { ...r, current: { id, name: env.displayName } });
      const outcome = await setTenantPool(id, action === "enable");
      const detail = outcomeDetail(outcome);
      if (detail) details[id] = detail;
      if (outcome.kind === "updated") {
        updated.push(id);
        setOverrides((m) => new Map(m).set(id.toLowerCase(), outcome.setting));
      } else if (outcome.kind === "locked") {
        lockedIds.push(id);
      } else {
        failedIds.push(id);
        // Another allocation changed too, so continuing could repeat that on every remaining environment.
        if (outcome.kind === "sideEffect") stoppedOn = env.displayName;
      }
      setRun((r) => {
        if (!r) return r;
        const queued = new Set(r.queued);
        queued.delete(id);
        return {
          ...r, done: r.done + 1, queued,
          updated: r.updated + (outcome.kind === "updated" ? 1 : 0),
          locked: r.locked + (outcome.kind === "locked" ? 1 : 0),
          failed: r.failed + (outcome.kind !== "updated" && outcome.kind !== "locked" ? 1 : 0),
        };
      });
    }
    setLocked((s) => new Set([...s, ...lockedIds]));
    setFailed((s) => {
      const next = new Set(s);
      updated.forEach((id) => next.delete(id));
      failedIds.forEach((id) => next.add(id));
      return next;
    });
    const entry: ChangeEntry = {
      id: crypto.randomUUID(), at: new Date().toISOString(), action, source,
      updatedIds: updated, lockedIds, failedIds, names, details,
    };
    setRun((r) => r && { ...r, current: null, finished: true, entry, stoppedOn });
    setSelected(new Set());
    void queryClient.invalidateQueries({ queryKey: ["ppadmin", "allocations"] });
    const saved = commit((s) => ({ ...s, log: [entry, ...s.log].slice(0, 50) }));
    const verb = action === "disable" ? "Tenant pool draw disabled" : "Tenant pool draw enabled";
    const parts = [`${verb} for ${updated.length} of ${targets.length}`];
    if (lockedIds.length) parts.push(`${lockedIds.length} locked by a group rule`);
    if (failedIds.length) parts.push(`${failedIds.length} not confirmed`);
    if (stoppedOn) toast.error(`Stopped after an unexpected change in ${stoppedOn}. ${parts.join(" · ")}`);
    else if (failedIds.length || lockedIds.length) toast.warning(parts.join(" · "));
    else toast.success(parts[0]);
    if (saved === "failed") toast.warning("The change log entry couldn't be saved in this browser. Download the results from the progress panel to keep them.");
    else if (saved === "trimmed") toast.info("Browser storage was full, so older change log entries were removed. Download the log to keep a full record.");
  };

  const updatePolicy = (patch: Partial<StoredState["policy"]>) => commit((s) => ({ ...s, policy: { ...s.policy, ...patch } }));

  const page = envQuery.data;
  const navBlocked = envQuery.fetchStatus !== "idle" || envQuery.isPlaceholderData || busy;
  const nextCursor = page?.continuation.kind === "available" ? page.continuation.cursor : undefined;
  const goNext = () => {
    if (nextCursor === undefined || navBlocked) return;
    setHistory((h) => [...h, cursor]);
    setCursor(nextCursor);
    setSelected(new Set());
  };
  const goPrev = () => {
    if (history.length === 0 || navBlocked) return;
    setCursor(history[history.length - 1]);
    setHistory((h) => h.slice(0, -1));
    setSelected(new Set());
  };
  const refresh = () => {
    setOverrides(new Map());
    void queryClient.invalidateQueries({ queryKey: ["ppadmin"] });
  };
  const multiPage = history.length > 0 || page?.continuation.kind !== "none";

  const selectedEnvs = rows.filter((e) => selected.has(e.environmentId));
  const zeroAllocation = pending?.action === "disable" ? pending.targets.filter((e) => settingFor(e.environmentId).allocated === 0) : [];
  const groupedTargets = pending?.targets.filter((e) => e.environmentGroupId) ?? [];
  const skippedTargets = pending?.targets.filter((e) => settingFor(e.environmentId).otherAllocations) ?? [];

  const loadError = envQuery.error ?? poolQuery.error;
  const firstLoad = (envQuery.isPending || poolQuery.isPending) && !loadError;

  return (
    <div className="mx-auto grid h-full w-full max-w-[1400px] gap-6 px-4 py-5 sm:px-6 lg:grid-cols-[minmax(0,1fr)_320px]">
      <section id="work" tabIndex={-1} aria-labelledby="fleet-heading" className="min-w-0 outline-none">
        {storage !== "ok" && (
          <div role="alert" className="mb-4 flex items-start gap-2 rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100">
            <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            <span>
              {storage === "invalid"
                ? "Saved rule settings and change log couldn't be loaded, so they were left untouched. Changes here are kept only while this page is open."
                : "Your latest rule settings and change log changes couldn't be saved in this browser. Keep this page open to avoid losing them."}
            </span>
          </div>
        )}

        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 id="fleet-heading" className="text-xl font-semibold tracking-tight">Environments</h1>
            <p className="mt-1 flex items-center gap-1.5 text-sm text-muted-foreground">
              <MousePointerClick className="size-4 shrink-0" aria-hidden="true" />
              Pick environments yourself: flip a switch, or tick several and use the selection bar.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative">
              <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
              <Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search name or ID" aria-label="Search environments" className="w-56 pl-8" />
            </div>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-40" aria-label="Environment type"><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All types</SelectItem>
                {types.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}
              </SelectContent>
            </Select>
            <Button variant="outline" onClick={refresh} disabled={envQuery.isFetching || poolQuery.isFetching || busy}>
              <RefreshCw className={cn("size-4", (envQuery.isFetching || poolQuery.isFetching) && "animate-spin")} aria-hidden="true" />Refresh
            </Button>
          </div>
        </div>

        <ToggleGroup type="single" variant="outline" value={view} onValueChange={(v) => v && setView(v as View)} className="mt-3" aria-label="Show">
          <ToggleGroupItem value="all">All {rows.length}</ToggleGroupItem>
          <ToggleGroupItem value="new">New · last {policy.newWindowDays} days</ToggleGroupItem>
          <ToggleGroupItem value="drawing">Drawing {counts.drawing}</ToggleGroupItem>
          <ToggleGroupItem value="capped">Capped {counts.capped}</ToggleGroupItem>
        </ToggleGroup>

        <div className="mt-4 overflow-hidden rounded-lg border bg-card">
          <div className="flex flex-wrap items-center gap-x-6 gap-y-2 border-b bg-muted/40 px-3 py-3">
            <div className="flex items-center gap-3">
              <div className="grid size-9 place-items-center rounded-md bg-primary text-primary-foreground">
                <Database className="size-5" aria-hidden="true" />
              </div>
              <div className="text-sm font-semibold">Tenant pool · Copilot Credits</div>
            </div>
            <dl className="flex gap-5 text-sm">
              <div><dt className="text-muted-foreground">Drawing</dt><dd className="font-semibold tabular-nums">{counts.drawing}</dd></div>
              <div><dt className="text-muted-foreground">Capped</dt><dd className="font-semibold tabular-nums">{counts.capped}</dd></div>
              {multiPage && <div><dt className="text-muted-foreground">Page</dt><dd className="font-semibold tabular-nums">{history.length + 1}</dd></div>}
            </dl>
            <div className="ml-auto flex items-center gap-2">
              <Checkbox id="select-all" checked={allSelected} disabled={visible.length === 0 || busy}
                onCheckedChange={(c) => setSelected(c ? new Set(visible.map((e) => e.environmentId)) : new Set())} />
              <Label htmlFor="select-all" className="text-sm">Select shown</Label>
            </div>
          </div>


          {firstLoad ? (
            <LoadingState rows={6} className="p-4" />
          ) : loadError && !page ? (
            <ConnectorErrorState error={loadError} connector={CONNECTOR}
              action={<Button variant="outline" onClick={refresh}>Retry</Button>} />
          ) : (
            <>
              {loadError && (
                <ConnectorErrorState error={loadError} connector={CONNECTOR} className="py-6"
                  action={<Button variant="outline" onClick={refresh}>Retry</Button>} />
              )}
              {page?.continuation.kind === "invalid" && (
                <div role="alert" className="flex items-center gap-3 border-b px-3 py-2 text-sm">
                  Unable to prepare the next page.
                  <Button size="sm" variant="outline" onClick={() => void envQuery.refetch()}>Retry</Button>
                </div>
              )}
              {visible.length === 0 ? (
                <EmptyState icon={Search} title={rows.length === 0 ? "No environments found" : "No environments match"} />
              ) : (
                <ul aria-label="Environments and their tenant pool draw">
                  {visible.map((env, i) => {
                    const s = settingFor(env.environmentId);
                    const drawing = drawsFromPool(s);
                    const isLocked = locked.has(env.environmentId);
                    const group = groupName(env.environmentGroupId);
                    const working = run?.current?.id === env.environmentId;
                    const queued = !working && !!run && !run.finished && run.queued.has(env.environmentId);
                    return (
                      <li key={env.environmentId} aria-busy={working || undefined}
                        className={cn("flex items-stretch gap-2 border-b pr-3 last:border-b-0", selected.has(env.environmentId) && "bg-muted", working && "bg-primary/10")}>
                        <div className="flex items-center pl-3">
                          <Checkbox aria-label={`Select ${env.displayName}`} checked={selected.has(env.environmentId)} disabled={busy}
                            onCheckedChange={(c) => toggleRow(env.environmentId, c === true)} />
                        </div>
                        <PoolPipe drawing={drawing} locked={isLocked} last={i === visible.length - 1} />
                        <div className="flex min-w-0 flex-1 flex-col justify-center py-2">
                          <div className="flex min-w-0 flex-wrap items-center gap-2">
                            <span className="truncate font-medium">{env.displayName}</span>
                            <Badge variant="secondary">{env.type}</Badge>
                            {isNew(env, policy.newWindowDays) && (
                              <Badge variant="outline" className={TONE.info}><Sparkles className="size-3" aria-hidden="true" />New</Badge>
                            )}
                            {isLocked && <Badge variant="outline" className={TONE.locked}><Lock className="size-3" aria-hidden="true" />Locked by group rule</Badge>}
                            {failed.has(env.environmentId) && <Badge variant="outline" className={TONE.failed}>Last change not confirmed</Badge>}
                          </div>
                          <div className="mt-0.5 truncate text-xs text-muted-foreground">
                            {[env.geo, env.createdTime ? `created ${formatDistanceToNowStrict(new Date(env.createdTime), { addSuffix: true })}` : null, group ? `group: ${group}` : null]
                              .filter(Boolean).join(" · ")}
                          </div>
                        </div>
                        <div className="hidden w-36 flex-col justify-center text-xs sm:flex">
                          <span className="tabular-nums">{s.allocated > 0 ? `${nf.format(s.allocated)} allocated` : "No allocation"}</span>
                        </div>
                        <div className="hidden w-48 items-center md:flex">
                          <Badge variant="outline" className={drawing ? TONE.drawing : TONE.capped}>
                            {drawing ? `Draws from pool${s.tenantPoolEnabled === null ? " (default)" : ""}` : "Capped at allocation"}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-2">
                          {working && <span className="flex items-center gap-1 text-xs font-medium text-primary"><Spinner aria-hidden="true" />Working…</span>}
                          {queued && <span className="text-xs text-muted-foreground">Queued</span>}
                          <Switch checked={drawing} disabled={busy} aria-label={`Draw from tenant pool for ${env.displayName}`}
                            onCheckedChange={(on) => openPreview(on ? "enable" : "disable", "row", [env])} />
                        </div>
                      </li>
                    );
                  })}
                </ul>
              )}
              {multiPage && (
                <nav aria-label="Pagination" className="flex items-center justify-end gap-2 border-t px-3 py-2">
                  <Button size="sm" variant="outline" onClick={goPrev} disabled={history.length === 0 || navBlocked}>Previous page</Button>
                  <Button size="sm" variant="outline" onClick={goNext} disabled={nextCursor === undefined || navBlocked}>
                    {envQuery.isFetching ? "Loading…" : "Next page"}
                  </Button>
                </nav>
              )}
            </>
          )}
        </div>

        {selected.size > 0 && !run && (
          <div className="sticky bottom-4 mt-4 flex flex-wrap items-center gap-3 rounded-lg border bg-card px-4 py-3 shadow-md">
            <span className="flex items-center gap-2 text-sm font-medium">
              <ListChecks className="size-4" aria-hidden="true" />{selected.size} you selected
            </span>
            <Button disabled={busy} onClick={() => openPreview("disable", "bulk", selectedEnvs)}>Disable for selected…</Button>
            <Button variant="outline" disabled={busy} onClick={() => openPreview("enable", "bulk", selectedEnvs)}>Enable for selected…</Button>
            <Button variant="ghost" onClick={() => setSelected(new Set())}>Clear</Button>
          </div>
        )}
      </section>

      <aside className="flex flex-col gap-6" aria-label="Disable by rule and change log">
        <section aria-labelledby="policy-heading" className="rounded-lg border-2 border-primary/40 bg-primary/5 p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 id="policy-heading" className="flex items-center gap-2 font-semibold">
              <ShieldCheck className="size-4" aria-hidden="true" />Disable by rule
            </h2>
            <Badge variant="outline" className="border-primary/40 text-primary">Automatic match</Badge>
          </div>
          <p className="mt-2 text-sm text-muted-foreground">
            Turns pool draw off for <strong className="font-medium text-foreground">every environment of the types below</strong> that still draws from the pool.
            It ignores the environments you ticked in the list.
          </p>
          <fieldset className="mt-3">
            <legend className="text-sm font-medium">Environment types to include</legend>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {types.map((t) => (
                <div key={t} className="flex items-center gap-2">
                  <Checkbox id={`type-${t}`} checked={policy.types.includes(t)}
                    onCheckedChange={(c) => updatePolicy({ types: c ? [...policy.types, t] : policy.types.filter((x) => x !== t) })} />
                  <Label htmlFor={`type-${t}`} className="text-sm font-normal">{t}</Label>
                </div>
              ))}
            </div>
          </fieldset>
          <div className="mt-4 flex items-center justify-between gap-2">
            <Label htmlFor="new-window" className="text-sm">Badge as "New" if created in</Label>
            <Select value={String(policy.newWindowDays)} onValueChange={(v) => updatePolicy({ newWindowDays: Number(v) })}>
              <SelectTrigger id="new-window" className="w-36"><SelectValue /></SelectTrigger>
              <SelectContent>
                {[7, 14, 30].map((d) => <SelectItem key={d} value={String(d)}>Last {d} days</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
          <dl className="mt-4 grid grid-cols-2 gap-3 border-t pt-3 text-sm">
            <div><dt className="text-muted-foreground">In scope, still drawing</dt><dd className="text-lg font-semibold tabular-nums">{sweepTargets.length}</dd></div>
            <div><dt className="text-muted-foreground">New, still drawing</dt><dd className="text-lg font-semibold tabular-nums">{newDrawing}</dd></div>
          </dl>
          <p className="mt-2 text-xs text-muted-foreground">The "New" badge only highlights recent environments. It doesn't change which ones the rule disables.</p>
          <Button className="mt-3 w-full" disabled={sweepTargets.length === 0 || busy} onClick={() => openPreview("disable", "sweep", sweepTargets)}>
            {multiPage ? `Disable now: ${sweepTargets.length} matching on this page…` : `Disable now: ${sweepTargets.length} matching…`}
          </Button>
        </section>

        <section aria-labelledby="log-heading" className="rounded-lg border bg-card p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 id="log-heading" className="flex items-center gap-2 font-semibold">
              <History className="size-4" aria-hidden="true" />Change log
            </h2>
            <Button variant="outline" size="sm" disabled={log.length === 0} onClick={() => downloadEntries(log, "pool-draw-change-log")}>
              <Download className="size-4" aria-hidden="true" />Download CSV
            </Button>
          </div>
          {log.length > 0 && (
            <p className="mt-1 text-xs text-muted-foreground">
              One row per environment for the last {log.length} change{log.length === 1 ? "" : "s"} ({nf.format(log.reduce((n, l) => n + l.updatedIds.length + l.lockedIds.length + l.failedIds.length, 0))} environment results).
            </p>
          )}
          {log.length === 0 ? (
            <p className="mt-2 text-sm text-muted-foreground">No changes yet</p>
          ) : (
            <ol className="mt-2 space-y-3">
              {log.slice(0, 8).map((l) => (
                <li key={l.id} className="text-sm">
                  <div className="flex items-center gap-2">
                    <Badge variant="outline" className={l.action === "disable" ? TONE.capped : TONE.drawing}>{l.action === "disable" ? "Disabled" : "Enabled"}</Badge>
                    <span className="tabular-nums">{l.updatedIds.length} env{l.updatedIds.length === 1 ? "" : "s"}</span>
                    <span className="text-xs text-muted-foreground">{l.source === "sweep" ? "by rule" : l.source === "bulk" ? "selected" : "switch"}</span>
                    <span className="ml-auto text-xs text-muted-foreground">{format(new Date(l.at), "MMM d, HH:mm")}</span>
                    <Button variant="ghost" size="icon" className="size-7" aria-label={`Download this change (${format(new Date(l.at), "MMM d, HH:mm")}) as CSV`}
                      onClick={() => downloadEntries([l], "pool-draw-change")}>
                      <Download className="size-3.5" aria-hidden="true" />
                    </Button>
                  </div>
                  {l.updatedIds.length > 0 && <div className="mt-1 text-xs">{shortList(l.updatedIds.map(entryName(l)))}</div>}
                  {l.lockedIds.length > 0 && <div className="mt-0.5 text-xs text-muted-foreground">Locked by group rule: {shortList(l.lockedIds.map(entryName(l)))}</div>}
                  {l.failedIds.length > 0 && <div className="mt-0.5 text-xs text-red-800 dark:text-red-300">Not confirmed: {shortList(l.failedIds.map(entryName(l)))}</div>}
                </li>
              ))}
            </ol>
          )}
          <Popover>
            <PopoverTrigger asChild>
              <Button variant="link" className="mt-3 h-auto p-0 text-xs">Stored in this browser</Button>
            </PopoverTrigger>
            <PopoverContent className="text-sm">
              The rule settings and change log are kept in this browser only: not shared with other people, not synced to other browsers or devices,
              visible to anyone using this browser profile, and removed if browser data is cleared. Environment settings themselves are read from and written to Power Platform.
            </PopoverContent>
          </Popover>
        </section>
      </aside>

      {run && (
        <RunPanel run={run} onDismiss={() => setRun(null)}
          onDownload={run.entry ? () => downloadEntries([run.entry!], "pool-draw-change") : undefined} />
      )}

      <Sheet open={pending !== null} onOpenChange={(o) => !o && setPending(null)}>
        <SheetContent className="sm:max-w-lg">
          {pending && (
            <>
              <SheetHeader>
                <SheetTitle>
                  {pending.action === "disable" ? "Disable" : "Enable"} tenant pool draw · {pending.targets.length} environment{pending.targets.length === 1 ? "" : "s"}
                </SheetTitle>
                <p className="flex items-center gap-1.5 text-sm font-medium">
                  {pending.source === "sweep"
                    ? <><ShieldCheck className="size-4" aria-hidden="true" />From the rule: every {policy.types.join(", ")} environment still drawing</>
                    : pending.source === "bulk"
                      ? <><ListChecks className="size-4" aria-hidden="true" />From your selection in the list</>
                      : <><MousePointerClick className="size-4" aria-hidden="true" />From the switch on one environment</>}
                </p>
                <SheetDescription>
                  {pending.action === "disable"
                    ? "Each environment is capped at its own Copilot Credits allocation."
                    : "Each environment can draw from unallocated tenant capacity after its allocation is used."}
                </SheetDescription>
              </SheetHeader>
              <div className="flex flex-col gap-4 px-4">
                {zeroAllocation.length > 0 && (
                  <div role="note" className="flex gap-2 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100">
                    <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
                    <span>{zeroAllocation.length} of these have no allocation, so agents there stop consuming Copilot Credits once capped.</span>
                  </div>
                )}
                {skippedTargets.length > 0 && (
                  <div role="note" className="flex gap-2 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100">
                    <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
                    <span>{skippedTargets.length} of these also have allocations of other credit types, so they will be skipped and reported as not confirmed. Change those in the Power Platform admin center.</span>
                  </div>
                )}
                {groupedTargets.length > 0 && (
                  <p className="text-sm">
                    {groupedTargets.length} {groupedTargets.length === 1 ? "is" : "are"} in an environment group. If that group publishes a draw-from-tenant-pool rule, Power Platform rejects the change and it is reported as locked.
                  </p>
                )}
                {pending.targets.length === 0 && <p className="text-sm">Nothing to change.</p>}
                <ul className="divide-y rounded-md border">
                  {pending.targets.map((e) => (
                    <li key={e.environmentId} className="flex items-center gap-2 px-3 py-2 text-sm">
                      <span className="min-w-0 flex-1 truncate">{e.displayName}</span>
                      <span className="text-xs tabular-nums text-muted-foreground">{nf.format(settingFor(e.environmentId).allocated)} allocated</span>
                    </li>
                  ))}
                </ul>
                {pending.targets[0] && (
                  <Collapsible>
                    <CollapsibleTrigger asChild><Button variant="outline" size="sm">Show API request</Button></CollapsibleTrigger>
                    <CollapsibleContent>
                      <pre className="mt-2 overflow-x-auto rounded-md bg-muted p-3 font-mono text-xs">
{`PUT /licensing/allocationsV2?api-version=2024-10-01
${JSON.stringify(allocationPutBody(pending.targets[0].environmentId, settingFor(pending.targets[0].environmentId), pending.action === "enable"), null, 2)}`}
                      </pre>
                    </CollapsibleContent>
                  </Collapsible>
                )}
              </div>
              <SheetFooter>
                <Button onClick={() => void apply()} disabled={pending.targets.length === 0 || busy}>
                  {pending.action === "disable" ? "Disable" : "Enable"} for {pending.targets.length}
                </Button>
                <Button variant="outline" onClick={() => setPending(null)}>Cancel</Button>
              </SheetFooter>
            </>
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}

/** First few names, then "+N more" so runs over hundreds of environments stay readable. */
function shortList(names: string[], max = 5): string {
  return names.length <= max ? names.join(", ") : `${names.slice(0, max).join(", ")} +${names.length - max} more`;
}

function RunPanel({ run, onDismiss, onDownload }: { run: RunState; onDismiss: () => void; onDownload?: () => void }) {
  const verb = run.action === "disable" ? "Disabling" : "Enabling";
  const working = run.finished ? run.done : Math.min(run.done + 1, run.total);
  const pct = run.total === 0 ? 100 : Math.round((run.done / run.total) * 100);
  const problems = run.locked + run.failed;
  return (
    <div className="fixed inset-x-4 bottom-4 z-50 mx-auto max-w-xl rounded-lg border bg-card p-4 shadow-lg" role="status" aria-live="polite">
      <div className="flex items-start gap-3">
        {run.finished ? (
          problems ? <AlertTriangle className="mt-0.5 size-5 shrink-0 text-amber-600" aria-hidden="true" />
            : <CheckCircle2 className="mt-0.5 size-5 shrink-0 text-primary" aria-hidden="true" />
        ) : (
          <Spinner className="mt-0.5 size-5 shrink-0 text-primary" aria-hidden="true" />
        )}
        <div className="min-w-0 flex-1">
          <p className="font-semibold tabular-nums">
            {run.finished
              ? `${run.stoppedOn ? "Stopped" : "Finished"}: ${run.updated} of ${run.total} ${run.action === "disable" ? "disabled" : "enabled"}`
              : `${verb} tenant pool draw: working on ${working} of ${run.total}`}
          </p>
          <p className={run.stoppedOn ? "text-sm text-muted-foreground" : "truncate text-sm text-muted-foreground"}>
            {run.finished
              ? run.stoppedOn
                ? `Stopped after an unexpected change in ${run.stoppedOn}. Check it in the Power Platform admin center before continuing.`
                : problems ? [run.locked && `${run.locked} locked by a group rule`, run.failed && `${run.failed} not confirmed`].filter(Boolean).join(" · ") : "Every change was confirmed by reading it back."
              : run.current ? `${run.current.name} · changing and confirming` : "Starting…"}
          </p>
        </div>
        {run.finished && (
          <Button variant="ghost" size="icon" aria-label="Dismiss" onClick={onDismiss}><X className="size-4" aria-hidden="true" /></Button>
        )}
      </div>
      <Progress value={pct} className="mt-3" aria-label="Progress" />
      <div className="mt-2 flex flex-wrap items-center gap-4 text-xs tabular-nums text-muted-foreground">
        <span>{run.done} of {run.total} done</span>
        <span>{run.updated} confirmed</span>
        {run.locked > 0 && <span>{run.locked} locked</span>}
        {run.failed > 0 && <span>{run.failed} not confirmed</span>}
        {run.finished && onDownload && (
          <Button variant="outline" size="sm" className="ml-auto" onClick={onDownload}>
            <Download className="size-4" aria-hidden="true" />Download results
          </Button>
        )}
      </div>
    </div>
  );
}
