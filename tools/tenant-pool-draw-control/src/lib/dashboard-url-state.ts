import { format, isValid, parse } from "date-fns";

import { type DateRange, wholeDayRange } from "@/lib/dashboard-data";

// Dashboard filter state kept in the query string, so a copied link opens the
// same view. The Managed Apps player forwards its own query params, minus
// `ms_*`, onto the app frame's URL once at load; `ms_*` names are the host's.
// No React here, so tests and the hook share it.

export type UrlFilterValue = string | DateRange;
export type UrlFilterDefaults = Record<string, UrlFilterValue>;
// Allowed values per string filter (a SelectFilter's option values); a URL
// value outside the list falls back to the default. List "" for a filter whose
// SelectFilter has an `allLabel`: "" is the value of its "All" option (lint:
// `aether-app/dashboard-select-all-option`). A filter whose values are
// open-ended (a TimeRangeFilter's custom range) takes a predicate instead,
// such as `isTimeRangeValue`.
export type UrlFilterOptions<T extends UrlFilterDefaults> = Partial<
  Record<keyof T & string, readonly string[] | ((value: string) => boolean)>
>;

// The public-cloud Managed Apps player. The SDK's context carries the app id
// but not the app's URL yet, and the Managed Apps host team's guidance is to
// build `<player>/apps/<appId>` from `getContext()`. Sovereign clouds serve
// the player from other origins and are not covered.
export const MANAGED_APPS_PLAYER_ORIGIN = "https://play.managedapps.cloud.microsoft";

const DAY_FORMAT = "yyyy-MM-dd";
const DAY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const RANGE_SEPARATOR = "..";

export function isReservedParam(name: string): boolean {
  return name.toLowerCase().startsWith("ms_");
}

function isDateRange(value: UrlFilterValue): value is DateRange {
  return typeof value !== "string";
}

function assertFilterKeys(defaults: UrlFilterDefaults): void {
  for (const key of Object.keys(defaults)) {
    if (isReservedParam(key)) {
      throw new Error(
        `Filter key "${key}" starts with ms_, which the Managed Apps host reserves; rename it.`,
      );
    }
  }
}

function parseDay(text: string): Date | null {
  if (!DAY_PATTERN.test(text)) return null;
  const day = parse(text, DAY_FORMAT, new Date());
  return isValid(day) ? day : null;
}

// "2026-03-01..2026-03-31", in local calendar days.
export function formatRangeParam(range: DateRange): string {
  return `${format(range.from, DAY_FORMAT)}${RANGE_SEPARATOR}${format(range.to, DAY_FORMAT)}`;
}

// A whole-day range, or null when the text is not two valid days.
export function parseRangeParam(text: string): DateRange | null {
  const parts = text.split(RANGE_SEPARATOR);
  if (parts.length !== 2) return null;
  const from = parseDay(parts[0]);
  const to = parseDay(parts[1]);
  return from && to ? wholeDayRange(from, to) : null;
}

export function encodeFilterValue(value: UrlFilterValue): string {
  return isDateRange(value) ? formatRangeParam(value) : value;
}

// The filters a query string names, each falling back to its default when
// absent or invalid.
export function readUrlFilters<T extends UrlFilterDefaults>(
  params: URLSearchParams,
  defaults: T,
  options?: UrlFilterOptions<T>,
): T {
  assertFilterKeys(defaults);
  const values: UrlFilterDefaults = { ...defaults };
  for (const [key, fallback] of Object.entries(defaults)) {
    const raw = params.get(key);
    if (raw === null) continue;
    if (isDateRange(fallback)) {
      const range = parseRangeParam(raw);
      if (range) values[key] = range;
      continue;
    }
    const allowed = options?.[key as keyof T & string];
    const ok = !allowed || (typeof allowed === "function" ? allowed(raw) : allowed.includes(raw));
    if (ok) values[key] = raw;
  }
  return values as T;
}

// A copy of `params` with each filter set, or removed when it equals its
// default. Params that are not filters (the host's `ms_*` among them) stay.
export function writeUrlFilters<T extends UrlFilterDefaults>(
  params: URLSearchParams,
  values: T,
  defaults: T,
): URLSearchParams {
  assertFilterKeys(defaults);
  const next = new URLSearchParams(params);
  for (const [key, fallback] of Object.entries(defaults)) {
    const text = encodeFilterValue(values[key] ?? fallback);
    if (text === encodeFilterValue(fallback)) next.delete(key);
    else next.set(key, text);
  }
  return next;
}

// The player link that opens this app with the given query, `ms_*` removed.
export function buildShareLink(appId: string, params: URLSearchParams): string {
  const query = new URLSearchParams();
  for (const [name, value] of params) {
    if (!isReservedParam(name)) query.append(name, value);
  }
  const search = query.toString();
  return `${MANAGED_APPS_PLAYER_ORIGIN}/apps/${encodeURIComponent(appId)}${search ? `?${search}` : ""}`;
}
