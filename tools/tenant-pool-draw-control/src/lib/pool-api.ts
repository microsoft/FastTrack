// Live reads and writes against the Power Platform API through the
// "Power Platform for Admins V2" connector binding.
import { PowerPlatformforAdminsV2Service } from "../../generated/services/PowerPlatformforAdminsV2Service";
import type {
  AllocationByEnvironmentModel,
  CurrencyAllocationModel,
  EnvironmentResponse,
} from "../../generated/models/PowerPlatformforAdminsV2Model";
import { logConnectorFailure } from "@/lib/connector-safety";

export const ENV_API_VERSION = "2022-03-01-preview";
export const LICENSING_API_VERSION = "2024-10-01";
/** Copilot Credits entitlement. */
export const COPILOT_CREDITS = "MCSMessages";
export const TENANT_POOL = "TenantPool";

export type Continuation = { kind: "none" } | { kind: "available"; cursor: number } | { kind: "invalid" };

export interface EnvRow {
  environmentId: string;
  displayName: string;
  type: string;
  geo: string;
  createdTime: string | null;
  environmentGroupId: string | null;
  state: string | null;
}

export interface EnvPage {
  rows: EnvRow[];
  continuation: Continuation;
}

/** Copilot Credits allocation + TenantPool rule for one environment, as read from the API. */
export interface PoolSetting {
  /** No allocation record exists for the environment: the platform default (draws from the pool) applies. */
  hasRecord: boolean;
  allocated: number;
  /** null = no explicit TenantPool rule; the default lets the environment draw. */
  tenantPoolEnabled: boolean | null;
  /** False when a record exists but its allocated quantity isn't a usable number: never write from it. */
  complete: boolean;
  /** Every Copilot Credits enforcement rule exactly as read (e.g. TenantPool, Alert with its ruleData). */
  rules: EnforcementRule[];
  /** Canonical form of all allocations except the TenantPool flag, to prove a write changed nothing else. */
  fingerprint: string;
  /**
   * The record also holds a non-empty allocation of another credit type. The write only sends Copilot
   * Credits and it isn't verified that the API keeps the rest, so such environments are never written.
   */
  otherAllocations: boolean;
}

/** A rule as returned by the API; extra fields such as ruleData are kept so they are sent back unchanged. */
export type EnforcementRule = { ruleType?: string; enabled?: boolean } & Record<string, unknown>;

export const NO_RECORD: PoolSetting = {
  hasRecord: false,
  allocated: 0,
  tenantPoolEnabled: null,
  complete: true,
  rules: [],
  fingerprint: "[]",
  otherAllocations: false,
};

export const drawsFromPool = (s: PoolSetting | undefined) => s?.tenantPoolEnabled !== false;

const str = (v: unknown) => (typeof v === "string" && v.length > 0 ? v : null);

function toRow(e: EnvironmentResponse): EnvRow | null {
  const id = str(e.id);
  if (!id) return null;
  return {
    environmentId: id,
    displayName: str(e.displayName) ?? id,
    type: str(e.type) ?? "Unknown",
    geo: str(e.geo) ?? str(e.azureRegion) ?? "",
    createdTime: str(e.createdDateTime),
    environmentGroupId: str(e.environmentGroupId),
    state: str(e.state),
  };
}

/** One page of environments. The cursor is the `$skip` offset; `@odata.nextlink` marks more pages. */
export async function fetchEnvironmentPage(skip: number | undefined): Promise<EnvPage> {
  const result = await PowerPlatformforAdminsV2Service.ListEnvironmentsForUser(
    ENV_API_VERSION,
    undefined,
    undefined,
    undefined,
    skip,
  );
  if (!result.success) {
    logConnectorFailure("PowerPlatformforAdminsV2Service.ListEnvironmentsForUser", "action", result.error);
    throw result.error;
  }
  const data = result.data;
  if (!data || (data.value !== undefined && !Array.isArray(data.value))) {
    throw new Error("Unexpected environment list shape");
  }
  const rows = (data.value ?? []).map(toRow).filter((r): r is EnvRow => r !== null);
  const next = data["@odata.nextlink"];
  const continuation: Continuation =
    next === undefined || next === null
      ? { kind: "none" }
      : typeof next === "string" && next.length > 0 && rows.length > 0
        ? { kind: "available", cursor: (skip ?? 0) + rows.length }
        : { kind: "invalid" };
  return { rows, continuation };
}

const isCopilotCredits = (c: CurrencyAllocationModel) =>
  typeof c.currencyType === "string" && c.currencyType.toLowerCase() === COPILOT_CREDITS.toLowerCase();

/** Sort object keys (and rule/allocation lists) so two reads of the same data compare equal. */
function canonical(value: unknown): unknown {
  if (Array.isArray(value)) {
    const items = value.map(canonical);
    return items.sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)));
  }
  if (value && typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const key of Object.keys(value as Record<string, unknown>).sort()) {
      out[key] = canonical((value as Record<string, unknown>)[key]);
    }
    return out;
  }
  return value;
}

/** Everything in the record except the TenantPool flag on Copilot Credits. */
function fingerprintOf(model: AllocationByEnvironmentModel | undefined): string {
  const list = Array.isArray(model?.currencyAllocations) ? model.currencyAllocations : [];
  const stripped = list.map((c) => {
    if (!isCopilotCredits(c)) return c;
    const rules = (c.enforcementRules ?? []).filter((r) => r?.ruleType !== TENANT_POOL);
    return { ...c, enforcementRules: rules };
  });
  return JSON.stringify(canonical(stripped));
}

const isRule = (r: unknown): r is EnforcementRule => !!r && typeof r === "object" && !Array.isArray(r);

/** An allocation of another credit type that holds credits or rules. Anything unrecognised counts as non-empty. */
function hasOtherAllocations(model: AllocationByEnvironmentModel | undefined): boolean {
  const list = Array.isArray(model?.currencyAllocations) ? model.currencyAllocations : [];
  return list.some((c) => {
    if (isCopilotCredits(c)) return false;
    const rules: unknown = c.enforcementRules;
    const noRules = rules == null || (Array.isArray(rules) && rules.length === 0);
    return !(noRules && (c.allocated ?? 0) === 0 && (c.autoAllocated ?? 0) === 0);
  });
}

export function toPoolSetting(model: AllocationByEnvironmentModel | undefined): PoolSetting {
  const otherAllocations = hasOtherAllocations(model);
  const credits = model?.currencyAllocations?.find(isCopilotCredits);
  if (!credits) return { ...NO_RECORD, otherAllocations };
  const rawRules: unknown = credits.enforcementRules;
  const rulesOk = rawRules === undefined || (Array.isArray(rawRules) && rawRules.every(isRule));
  const rules = rulesOk ? ((rawRules as EnforcementRule[] | undefined) ?? []).map((r) => ({ ...r })) : [];
  const rule = rules.find((r) => r.ruleType === TENANT_POOL);
  const allocatedOk = typeof credits.allocated === "number" && Number.isFinite(credits.allocated) && credits.allocated >= 0;
  return {
    hasRecord: true,
    allocated: allocatedOk ? (credits.allocated as number) : 0,
    tenantPoolEnabled: typeof rule?.enabled === "boolean" ? rule.enabled : null,
    complete: allocatedOk && rulesOk,
    rules,
    fingerprint: fingerprintOf(model),
    otherAllocations,
  };
}

/** Allocations and enforcement rules for every environment, keyed by environment id. */
export async function fetchAllPoolSettings(): Promise<Map<string, PoolSetting>> {
  const result = await PowerPlatformforAdminsV2Service.ListAllocationsByEnvironment(LICENSING_API_VERSION);
  if (!result.success) {
    logConnectorFailure("PowerPlatformforAdminsV2Service.ListAllocationsByEnvironment", "action", result.error);
    throw result.error;
  }
  const raw: unknown = result.data;
  const list: unknown = Array.isArray(raw) ? raw : (raw as { value?: unknown } | undefined)?.value;
  if (!Array.isArray(list)) throw new Error("Unexpected allocation list shape");
  const map = new Map<string, PoolSetting>();
  for (const item of list as AllocationByEnvironmentModel[]) {
    if (typeof item?.environmentId === "string") map.set(item.environmentId.toLowerCase(), toPoolSetting(item));
  }
  return map;
}

export async function fetchGroupNames(): Promise<Map<string, string>> {
  const result = await PowerPlatformforAdminsV2Service.ListEnvironmentGroups(LICENSING_API_VERSION);
  if (!result.success) {
    logConnectorFailure("PowerPlatformforAdminsV2Service.ListEnvironmentGroups", "action", result.error);
    throw result.error;
  }
  const map = new Map<string, string>();
  for (const g of result.data?.value ?? []) {
    if (typeof g.id === "string" && typeof g.displayName === "string") map.set(g.id.toLowerCase(), g.displayName);
  }
  return map;
}

export async function readPoolSetting(environmentId: string): Promise<PoolSetting> {
  const result = await PowerPlatformforAdminsV2Service.GetAllocationsByEnvironment(environmentId, LICENSING_API_VERSION);
  if (!result.success) {
    // 404 = the environment has never had an allocation: zero credits, default pool draw.
    const status = (result.error as { status?: unknown } | undefined)?.status;
    if (status === 404) return NO_RECORD;
    logConnectorFailure("PowerPlatformforAdminsV2Service.GetAllocationsByEnvironment", "action", result.error);
    throw result.error;
  }
  return toPoolSetting(result.data);
}

/**
 * Request body sent per environment: PUT /licensing/allocationsV2.
 * Sends back the current allocation and every existing rule (e.g. Alert with its ruleData) unchanged,
 * and only sets the TenantPool flag. Verified against the live API:
 * - A rule-only PUT is accepted with 200 OK but not applied, so the quantity must be included.
 * - The PATCH UpdateAllocationsByEnvironment is NOT a partial update: a rule-only PATCH reset the
 *   allocation to 0 and removed the other rules. Don't use it.
 * - PatchCurrencyAllocationByEnvironment (v1) only accepts quantities, not enforcement rules.
 */
export function allocationPutBody(environmentId: string, current: PoolSetting, enabled: boolean) {
  const rules: EnforcementRule[] = current.rules.map((r) => (r.ruleType === TENANT_POOL ? { ...r, enabled } : { ...r }));
  if (!rules.some((r) => r.ruleType === TENANT_POOL)) rules.unshift({ ruleType: TENANT_POOL, enabled });
  return {
    scope: { environmentId },
    allocatedEntitlements: [
      {
        entitlementId: COPILOT_CREDITS,
        allocation: { quantity: current.allocated },
        enforcementRules: rules,
      },
    ],
  };
}

export type WriteOutcome =
  | { kind: "updated"; setting: PoolSetting }
  | { kind: "locked" }
  | { kind: "unconfirmed" }
  | { kind: "mismatch" }
  /** The current record couldn't be read reliably, so nothing was sent. */
  | { kind: "incomplete" }
  /** The environment also has allocations of other credit types, so nothing was sent. */
  | { kind: "unsupported" }
  /** Pool draw changed, but something else in the allocation changed too. */
  | { kind: "sideEffect" }
  | { kind: "failed"; error: unknown };

const mentionsLock = (error: unknown) => {
  const msg = typeof error === "object" && error !== null ? (error as { message?: unknown }).message : undefined;
  return typeof msg === "string" && msg.includes("TenantPoolLockedByPolicy");
};

/**
 * Set the TenantPool rule, keeping the environment's current allocation and other rules, then read it
 * back and check that only the TenantPool flag changed.
 */
export async function setTenantPool(environmentId: string, enabled: boolean): Promise<WriteOutcome> {
  let current: PoolSetting;
  try {
    current = await readPoolSetting(environmentId);
  } catch (error) {
    return { kind: "failed", error };
  }
  if (!current.complete) return { kind: "incomplete" };
  if (current.otherAllocations) return { kind: "unsupported" };
  let result: Awaited<ReturnType<typeof PowerPlatformforAdminsV2Service.PutAllocationsV2>>;
  try {
    result = await PowerPlatformforAdminsV2Service.PutAllocationsV2(
      LICENSING_API_VERSION,
      // The generated request type omits extra rule fields such as ruleData; they are sent through unchanged.
      allocationPutBody(environmentId, current, enabled) as Parameters<typeof PowerPlatformforAdminsV2Service.PutAllocationsV2>[1],
    );
  } catch (error) {
    // A thrown call must not abort a bulk run; the list is refreshed afterwards to show the real state.
    logConnectorFailure("PowerPlatformforAdminsV2Service.PutAllocationsV2", "action", error);
    return { kind: "failed", error };
  }
  if (!result.success) {
    if (mentionsLock(result.error)) return { kind: "locked" };
    logConnectorFailure("PowerPlatformforAdminsV2Service.PutAllocationsV2", "action", result.error);
    return { kind: "failed", error: result.error };
  }
  try {
    const after = await readPoolSetting(environmentId);
    if (drawsFromPool(after) !== enabled) return { kind: "mismatch" };
    // A brand-new record (404 before) has nothing to compare against except a zero allocation.
    const keptOther = current.hasRecord
      ? after.fingerprint === current.fingerprint
      : after.allocated === current.allocated;
    if (!keptOther) return { kind: "sideEffect" };
    return { kind: "updated", setting: after };
  } catch {
    return { kind: "unconfirmed" };
  }
}
