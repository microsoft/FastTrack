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
}

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

export function toPoolSetting(model: AllocationByEnvironmentModel | undefined): PoolSetting {
  const credits = model?.currencyAllocations?.find(isCopilotCredits);
  if (!credits) return { hasRecord: false, allocated: 0, tenantPoolEnabled: null };
  const rule = credits.enforcementRules?.find((r) => r.ruleType === TENANT_POOL);
  return {
    hasRecord: true,
    allocated: typeof credits.allocated === "number" ? credits.allocated : 0,
    tenantPoolEnabled: typeof rule?.enabled === "boolean" ? rule.enabled : null,
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
    if (status === 404) return { hasRecord: false, allocated: 0, tenantPoolEnabled: null };
    logConnectorFailure("PowerPlatformforAdminsV2Service.GetAllocationsByEnvironment", "action", result.error);
    throw result.error;
  }
  return toPoolSetting(result.data);
}

/** Request body sent per environment: PUT /licensing/allocationsV2 (keeps the current allocation). */
export function allocationPutBody(environmentId: string, allocated: number, enabled: boolean) {
  return {
    scope: { environmentId },
    allocatedEntitlements: [
      {
        entitlementId: COPILOT_CREDITS,
        allocation: { quantity: allocated },
        enforcementRules: [{ ruleType: TENANT_POOL, enabled }],
      },
    ],
  };
}

export type WriteOutcome =
  | { kind: "updated"; setting: PoolSetting }
  | { kind: "locked" }
  | { kind: "unconfirmed" }
  | { kind: "mismatch" }
  | { kind: "failed"; error: unknown };

const mentionsLock = (error: unknown) => {
  const msg = typeof error === "object" && error !== null ? (error as { message?: unknown }).message : undefined;
  return typeof msg === "string" && msg.includes("TenantPoolLockedByPolicy");
};

/** Set the TenantPool rule, keeping the environment's current Copilot Credits allocation, then read it back. */
export async function setTenantPool(environmentId: string, enabled: boolean): Promise<WriteOutcome> {
  let current: PoolSetting;
  try {
    current = await readPoolSetting(environmentId);
  } catch (error) {
    return { kind: "failed", error };
  }
  const result = await PowerPlatformforAdminsV2Service.PutAllocationsV2(
    LICENSING_API_VERSION,
    allocationPutBody(environmentId, current.allocated, enabled),
  );
  if (!result.success) {
    if (mentionsLock(result.error)) return { kind: "locked" };
    logConnectorFailure("PowerPlatformforAdminsV2Service.PutAllocationsV2", "action", result.error);
    return { kind: "failed", error: result.error };
  }
  try {
    const after = await readPoolSetting(environmentId);
    if (drawsFromPool(after) !== enabled) return { kind: "mismatch" };
    return { kind: "updated", setting: after };
  } catch {
    return { kind: "unconfirmed" };
  }
}
