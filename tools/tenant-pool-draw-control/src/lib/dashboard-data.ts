import {
  addDays,
  addMonths,
  addQuarters,
  addWeeks,
  endOfDay,
  format as formatDate,
  isValid,
  parseISO,
  startOfDay,
  startOfMonth,
  startOfQuarter,
  startOfWeek,
  startOfYear,
  subDays,
  subMonths,
} from "date-fns";
import { TZDate } from "react-day-picker";

// Pure data helpers for dashboards: formatting, aggregation, time bucketing and
// date ranges. No React here, so pages, hooks and tests can all share them.

export type MetricFormat =
  "number" | "compact" | "currency" | "percent" | "duration";

export type DateRange = { from: Date; to: Date };

export type DateRangePreset = { label: string; range: () => DateRange };

export type TimeGrain = "day" | "week" | "month" | "quarter";

export type LabelValue = { label: string; value: number };

const EMPTY_METRIC = "—";
const DEFAULT_CURRENCY = "USD";

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function numberFormat(options: Intl.NumberFormatOptions): Intl.NumberFormat {
  try {
    return new Intl.NumberFormat(undefined, options);
  } catch {
    // An invalid currency code throws RangeError; fall back to a plain number.
    return new Intl.NumberFormat(undefined, { maximumFractionDigits: 2 });
  }
}

const DURATION_UNITS: { unit: string; ms: number; next: number }[] = [
  { unit: "ms", ms: 1, next: 1000 },
  { unit: "s", ms: 1000, next: 60 },
  { unit: "min", ms: 60_000, next: 60 },
  { unit: "h", ms: 3_600_000, next: Number.POSITIVE_INFINITY },
];

// The value as it will be displayed: whole numbers from 100 up, else one decimal.
function roundForDisplay(v: number): number {
  return Math.abs(v) >= 100 ? Math.round(v) : Math.round(v * 10) / 10;
}

// Milliseconds as the largest readable unit: 655 -> "655 ms", 10900 -> "10.9 s",
// 150000 -> "2.5 min", 7200000 -> "2 h". The unit is chosen after rounding, so
// 999.6 ms reads "1 s", never "1,000 ms".
function formatDuration(ms: number): string {
  for (const { unit, ms: size, next } of DURATION_UNITS) {
    const shown = roundForDisplay(ms / size);
    if (Math.abs(shown) < next) {
      return `${numberFormat({ maximumFractionDigits: 1 }).format(shown)} ${unit}`;
    }
  }
  return EMPTY_METRIC;
}

// Intl accepts 0-20 fraction digits; anything else falls back to the default.
function fractionDigits(digits: number | undefined, fallback: number): number {
  return digits !== undefined && Number.isInteger(digits) && digits >= 0 && digits <= 20
    ? digits
    : fallback;
}

// Formats a metric for display. `percent` takes a ratio (0.12 -> "12%",
// 0.0195 -> "1.95%": under 10% keeps two decimals, so a small rate is not
// rounded to a whole point; a nonzero share too small to show reads "<0.01%",
// never "0%"); `duration` takes milliseconds (10900 -> "10.9 s").
// `digits` caps the fraction digits of `number` and `percent`, for a value the
// query already rounded (`round(x, 2)` -> digits 2).
// null, undefined, NaN and Infinity render as an em dash.
export function formatMetric(
  value: number | null | undefined,
  format: MetricFormat = "number",
  currency: string = DEFAULT_CURRENCY,
  digits?: number,
): string {
  if (!isFiniteNumber(value)) return EMPTY_METRIC;
  const abs = Math.abs(value);
  switch (format) {
    case "compact":
      return numberFormat({
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value);
    case "currency": {
      const digits = abs >= 1000 ? 0 : 2;
      return numberFormat({
        style: "currency",
        currency,
        minimumFractionDigits: digits,
        maximumFractionDigits: digits,
      }).format(value);
    }
    case "percent": {
      const places = fractionDigits(digits, abs < 0.1 ? 2 : 1);
      const percent = (v: number) =>
        numberFormat({ style: "percent", maximumFractionDigits: places }).format(v);
      // The smallest share these digits can show; a nonzero value below half
      // of it would round to "0%", which reads as none at all.
      const smallest = 10 ** -(places + 2);
      if (value !== 0 && abs < smallest / 2) {
        return value > 0 ? `<${percent(smallest)}` : `>${percent(-smallest)}`;
      }
      return percent(value);
    }
    case "duration":
      return formatDuration(value);
    default:
      return numberFormat({
        maximumFractionDigits: fractionDigits(digits, abs >= 1000 ? 0 : 2),
      }).format(value);
  }
}

// A currency amount to its minor unit ($1,021,132.70, KWD 1.235), for a data
// table where the exact amount is the point; `formatMetric` drops the cents
// from $1,000 up to keep a chart readable. A currency with fewer than two
// minor digits still keeps up to two, so an average of ¥123.45 is not shown
// as ¥123, while a whole ¥1,021,133 stays whole.
export function formatExactCurrency(
  value: number | null | undefined,
  currency: string = DEFAULT_CURRENCY,
): string {
  if (!isFiniteNumber(value)) return EMPTY_METRIC;
  const minor = numberFormat({ style: "currency", currency });
  const digits = minor.resolvedOptions().maximumFractionDigits ?? 2;
  if (digits >= 2) return minor.format(value);
  return numberFormat({
    style: "currency",
    currency,
    minimumFractionDigits: digits,
    maximumFractionDigits: 2,
  }).format(value);
}

// The label a multi-value filter shows: `allLabel` when nothing or every
// option is chosen, the option's own label for one, else "2 of 4" — never a
// subset that reads as the whole list.
export function multiSelectSummary(
  selected: readonly string[],
  options: readonly { value: string; label: string }[],
  allLabel = "All",
): string {
  const chosen = options.filter((option) => selected.includes(option.value));
  if (chosen.length === 0 || chosen.length === options.length) return allLabel;
  if (chosen.length === 1) return chosen[0].label;
  return `${chosen.length} of ${options.length}`;
}

// Short form for chart axis ticks: large numbers and currency go compact.
export function formatAxisValue(
  value: number | null | undefined,
  format: MetricFormat = "number",
  currency: string = DEFAULT_CURRENCY,
): string {
  if (!isFiniteNumber(value)) return EMPTY_METRIC;
  // A zero tick has no unit worth showing; "0 ms" beside "139 h" reads as a mismatch.
  if (format === "duration" && value === 0) return "0";
  if (format === "percent" || format === "duration")
    return formatMetric(value, format);
  if (format === "currency") {
    return numberFormat({
      style: "currency",
      currency,
      notation: "compact",
      maximumFractionDigits: 1,
    }).format(value);
  }
  return Math.abs(value) >= 10000
    ? formatMetric(value, "compact")
    : formatMetric(value, "number");
}

// Signed percent for a change ratio: 0.123 -> "+12.3%", -0.04 -> "-4%".
export function formatPercentChange(change: number | null | undefined): string {
  if (!isFiniteNumber(change)) return EMPTY_METRIC;
  return numberFormat({
    style: "percent",
    maximumFractionDigits: 1,
    signDisplay: "exceptZero",
  }).format(change);
}

// Change from `previous` to `current` as a ratio (0.12 = +12%). null when
// either side is missing or `previous` is 0 (the change is undefined).
export function percentChange(
  current: number | null | undefined,
  previous: number | null | undefined,
): number | null {
  if (!isFiniteNumber(current) || !isFiniteNumber(previous) || previous === 0) {
    return null;
  }
  const change = (current - previous) / Math.abs(previous);
  return Number.isFinite(change) ? change : null;
}

// `current` as a share of `target` (0.82 = 82% of the target). null when
// either side is missing or `target` is 0 or negative, where a share of it
// means nothing.
export function targetAttainment(
  current: number | null | undefined,
  target: number | null | undefined,
): number | null {
  if (!isFiniteNumber(current) || !isFiniteNumber(target) || target <= 0) {
    return null;
  }
  const share = current / target;
  return Number.isFinite(share) ? share : null;
}

// Whether `current` meets `target`: at or above it when up is good, at or
// below it when down is good. "none" when either side is missing.
export function targetStatus(
  current: number | null | undefined,
  target: number | null | undefined,
  goodDirection: "up" | "down" = "up",
): "on" | "off" | "none" {
  if (!isFiniteNumber(current) || !isFiniteNumber(target)) return "none";
  const met = goodDirection === "down" ? current <= target : current >= target;
  return met ? "on" : "off";
}

function byValueDesc(a: LabelValue, b: LabelValue): number {
  return b.value - a.value || a.label.localeCompare(b.label);
}

// Sums `value` per `key`, largest first. Non-finite values are skipped.
export function groupSum<T>(
  rows: T[],
  key: (r: T) => string,
  value: (r: T) => number,
): LabelValue[] {
  const totals = new Map<string, number>();
  for (const row of rows) {
    const v = value(row);
    if (!isFiniteNumber(v)) continue;
    const k = key(row);
    totals.set(k, (totals.get(k) ?? 0) + v);
  }
  return Array.from(totals, ([label, total]) => ({ label, value: total })).sort(
    byValueDesc,
  );
}

// Date | ISO string | Excel serial | epoch milliseconds -> a valid Date, or
// null when missing or unparseable.
// - Date-only strings ("2026-03-01") are read as LOCAL midnight, not UTC.
// - Excel returns date cells as serial day numbers, often as strings
//   ("45678.5"); a number up to the last Excel day (9999-12-31) is a serial and
//   is never parsed as a year. A five-digit string is a serial (10000 is
//   1927-05-18), so "2026" stays the year 2026; a six- or seven-digit string is
//   a serial only when it is not an ISO basic date ("202603" is March 2026,
//   "2026060" is day 60 of 2026).
// - A larger number is epoch milliseconds (TanStack Query's `dataUpdatedAt`).
const EXCEL_SERIAL_RX = /^\d{5}(\.\d+)?$/;
const LONG_EXCEL_SERIAL_RX = /^\d{6,7}(\.\d+)?$/;
const EXCEL_EPOCH_MS = Date.UTC(1899, 11, 30);
export const EXCEL_MAX_SERIAL = 2_958_465;
const ISO_SHAPED_RX =
  /^[+-]?\d{4,6}-\d{2}(?:-\d{2})?(?:[T ]\d{2}(?::\d{2}(?::\d{2}(?:[.,]\d+)?)?)?)?(?:Z|[+-]\d{2}(?::?\d{2})?)?$/i;
const ISO_DATE_PREFIX_RX = /^([+-]?\d{4,6}-\d{2}-\d{2})(?![\d-])/;

function fromExcelSerial(serial: number, serialWallClock = false): Date | null {
  if (serial <= 0 || serial > EXCEL_MAX_SERIAL + 1) return null;
  // Excel counts 1900-02-29, a day that never existed, so serials before it
  // (1 = 1900-01-01) sit one day later than the 1899-12-30 epoch reads them.
  const days = serial < 61 ? serial + 1 : serial;
  // Round to the millisecond first, so float noise just under midnight
  // (46000.99999999999) still reads as the next day; then to the second, but
  // never past the serial's own day: 23:59:59.9 stays on that day.
  const ms = Math.round(days * 86_400_000);
  const nextMidnight = (Math.floor(days) + 1) * 86_400;
  const seconds =
    ms >= nextMidnight * 1000
      ? nextMidnight
      : Math.min(Math.round(ms / 1000), nextMidnight - 1);
  const utc = new Date(EXCEL_EPOCH_MS + seconds * 1000);
  // A field-preserving carrier for explicitly typed date/wall-clock consumers.
  // Constructing a local Date first would normalize serials in a DST gap.
  if (serialWallClock) return isValid(utc) ? new TZDate(utc.getTime(), "UTC") : null;
  // Serials carry wall-clock time with no zone: read them as local time.
  const local = new Date(
    utc.getUTCFullYear(),
    utc.getUTCMonth(),
    utc.getUTCDate(),
    utc.getUTCHours(),
    utc.getUTCMinutes(),
    utc.getUTCSeconds(),
  );
  return isValid(local) ? local : null;
}

export function toDateValue(
  value: Date | string | number | null | undefined,
  { serialWallClock = false }: { serialWallClock?: boolean } = {},
): Date | null {
  if (value == null) return null;
  if (value instanceof Date) return isValid(value) ? value : null;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return null;
    if (value <= EXCEL_MAX_SERIAL + 1) return fromExcelSerial(value, serialWallClock);
    const epoch = new Date(value);
    return isValid(epoch) ? epoch : null;
  }
  const text = value.trim();
  if (!text) return null;
  if (EXCEL_SERIAL_RX.test(text)) return fromExcelSerial(Number(text), serialWallClock);
  const parsed = parseISO(text);
  if (isValid(parsed)) return parsed;
  if (LONG_EXCEL_SERIAL_RX.test(text)) return fromExcelSerial(Number(text), serialWallClock);
  // A wholly ISO-shaped string parseISO refused ("2026-02-30"), or one whose
  // leading ISO date is impossible ("2026-02-30 10:00 UTC"), is invalid; the
  // engine's lenient parser would roll it into another day. Other shapes
  // ("2026-03-01 12:30:00 UTC") still reach that parser.
  if (ISO_SHAPED_RX.test(text)) return null;
  const datePrefix = ISO_DATE_PREFIX_RX.exec(text);
  if (datePrefix && !isValid(parseISO(datePrefix[1]))) return null;
  const fallback = new Date(text);
  return isValid(fallback) ? fallback : null;
}

function isUtcMidnight(value: Date): boolean {
  return (
    isValid(value) &&
    value.getUTCHours() === 0 &&
    value.getUTCMinutes() === 0 &&
    value.getUTCSeconds() === 0 &&
    value.getUTCMilliseconds() === 0
  );
}

// `toDateValue`, except that a value at exactly UTC midnight (how Kusto and SQL
// return a day bin, in any form `toDateValue` reads) is read as that local
// calendar day. Converting the instant would put that day bin on Feb 28 for
// every viewer west of UTC. Only for values known to be day bins: an hourly row
// at 00:00Z is an instant.
export function toCalendarDay(
  value: Date | string | number | null | undefined,
): Date | null {
  const date = toDateValue(value);
  if (!date || !isUtcMidnight(date)) return date;
  // setFullYear, not the Date constructor, which reads years 0-99 as 19xx.
  const day = new Date(0);
  day.setFullYear(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
  day.setHours(0, 0, 0, 0);
  return day;
}

// Formats a date-only value (a Dataverse DateOnly column, a CSV or Excel date,
// a Kusto or SQL day bin) for a table cell, tooltip or label as the calendar
// day it names. `new Date("2025-07-09")` is UTC midnight, which every viewer
// west of UTC sees as Jul 8; this reads it as Jul 9 everywhere. Returns
// `empty` when the value is missing or not a date. Not for instants with a
// time of day: format those with `toDateValue`.
export function formatCalendarDay(
  value: Date | string | number | null | undefined,
  pattern = "MMM d, yyyy",
  empty = "",
): string {
  const day = toCalendarDay(value);
  return day ? formatDate(day, pattern) : empty;
}

function bucketStart(date: Date, grain: TimeGrain): Date {
  switch (grain) {
    case "week":
      return startOfWeek(date, { weekStartsOn: 1 });
    case "month":
      return startOfMonth(date);
    case "quarter":
      return startOfQuarter(date);
    default:
      return startOfDay(date);
  }
}

function nextBucket(date: Date, grain: TimeGrain): Date {
  switch (grain) {
    case "week":
      return addWeeks(date, 1);
    case "month":
      return addMonths(date, 1);
    case "quarter":
      return addQuarters(date, 1);
    default:
      return addDays(date, 1);
  }
}

// Sums `value` per time bucket (weeks start Monday), oldest first. Every bucket
// between the first and last row is present and empty ones are 0, unless that
// span would exceed `maxBuckets` (one stray sentinel date such as 1900-01-01
// would otherwise fill a century of days): then only the buckets that hold rows
// are returned. The cap bounds the allocation, so a non-finite `maxBuckets`
// keeps the default. `bucket` is the bucket's start date as "yyyy-MM-dd" (local
// time). Pass `dayBins` for a calendar-binned column (`bin(…, 1d)`,
// `bin(…, 7d)`, `startofday`/`startofweek`/`startofmonth`), as to `inRange`, so
// a UTC-midnight bin lands on its calendar day (`toCalendarDay`);
// without it each date is an instant, as an hourly row is. Rows with an invalid
// date or non-finite value are skipped.
export const MAX_TIME_BUCKETS = 1000;

export function bucketByTime<T>(
  rows: T[],
  date: (r: T) => Date | string | number,
  grain: TimeGrain,
  value: (r: T) => number,
  dayBins = false,
  maxBuckets: number = MAX_TIME_BUCKETS,
): { bucket: string; value: number }[] {
  const totals = new Map<number, number>();
  for (const row of rows) {
    const d = dayBins ? toCalendarDay(date(row)) : toDateValue(date(row));
    const v = value(row);
    if (!d || !isFiniteNumber(v)) continue;
    const start = bucketStart(d, grain).getTime();
    totals.set(start, (totals.get(start) ?? 0) + v);
  }
  if (totals.size === 0) return [];
  const keys = Array.from(totals.keys()).sort((a, b) => a - b);
  const cap = Number.isFinite(maxBuckets)
    ? Math.max(1, Math.floor(maxBuckets))
    : MAX_TIME_BUCKETS;
  const first = keys[0];
  const last = keys[keys.length - 1];
  const out: { bucket: string; value: number }[] = [];
  for (
    let cursor = new Date(first);
    cursor.getTime() <= last;
    cursor = bucketStart(nextBucket(cursor, grain), grain)
  ) {
    if (out.length >= cap) {
      console.warn(
        `bucketByTime: the rows span more than ${cap} ${grain} buckets; returning only the ${keys.length} buckets that hold rows`,
      );
      return keys.map((key) => ({
        bucket: formatDate(new Date(key), "yyyy-MM-dd"),
        value: totals.get(key) ?? 0,
      }));
    }
    out.push({
      bucket: formatDate(cursor, "yyyy-MM-dd"),
      value: totals.get(cursor.getTime()) ?? 0,
    });
  }
  return out;
}

const STEP_UNITS_MS: Record<string, number> = {
  ms: 1,
  s: 1000,
  m: 60_000,
  h: 3_600_000,
  d: 86_400_000,
};

// A Kusto timespan ("30s", "5m", "1h", "1d") or a number of milliseconds, as
// milliseconds; null unless it is a finite whole number of milliseconds, at
// least 1 (a Date's precision, so every step advances the clock).
export function timeStepMs(step: string | number): number | null {
  const wholeMs = (ms: number) => (Number.isInteger(ms) && ms >= 1 && Number.isFinite(ms) ? ms : null);
  if (typeof step === "number") return wholeMs(step);
  const match = /^\s*(\d+(?:\.\d+)?)\s*(ms|s|m|h|d)\s*$/i.exec(step);
  if (!match) return null;
  return wholeMs(Number(match[1]) * STEP_UNITS_MS[match[2].toLowerCase()]);
}

// Telemetry lands minutes after the event: kusto.md ends a window at
// `ago(15m)` unless the probe measured a longer lag. fillTimeGaps never
// writes a 0 into a bin that ends after `landedBy`, 15 minutes ago by default;
// pass `Date.now()` minus the probed lag (plus 5 minutes) when it is longer.
export const INGESTION_LAG_MS = 15 * 60_000;

// Zero-fills evenly spaced instant bins (a Kusto `bin(t, 5m)`, an hourly
// rollup) for a TrendChart: returns the rows oldest first with one added row
// per missing step, its `valueKeys` set to 0, and a row missing one of those
// keys (a quiet series) gets that key as 0 (only in a bin past the ingestion
// lag, like an added row), so a quiet period draws as 0
// instead of a line joining the bins either side of it. Kusto `summarize … by
// bin()` emits no row for an empty bin. Steps align to the epoch, as `bin()`
// does; pass `range` (`resolveTimeRange(window, windowOptions)`) to fill its
// quiet start and end too, with `step` `kqlTimeBin(window, windowOptions)` or
// milliseconds. The end is exclusive, and no bin ending after `landedBy` is
// filled: its rows may not have landed yet (INGESTION_LAG_MS).
// Only for counts and sums: a rate or an average has no value in an empty bin.
// Rows whose x is not a date are dropped. Past `maxBuckets` steps, or with a
// step that does not parse, the rows come back sorted and unfilled.
export function fillTimeGaps<T extends Record<string, unknown>>(
  rows: T[],
  xKey: string,
  step: string | number,
  valueKeys: string[],
  range?: { from: Date | string | number; to: Date | string | number } | null,
  maxBuckets: number = MAX_TIME_BUCKETS,
  landedBy: number = Date.now() - INGESTION_LAG_MS,
): Record<string, unknown>[] {
  const instant = (x: unknown) =>
    typeof x === "string" || typeof x === "number" || x instanceof Date
      ? toDateValue(x)?.getTime()
      : undefined;
  const dated = rows
    .map((row) => ({ row, at: instant(row[xKey]) }))
    .filter((r): r is { row: T; at: number } => r.at !== undefined)
    .sort((a, b) => a.at - b.at);
  const sorted: Record<string, unknown>[] = dated.map((r) => r.row);
  const size = timeStepMs(step);
  const from = range ? toDateValue(range.from)?.getTime() : undefined;
  const to = range ? toDateValue(range.to)?.getTime() : undefined;
  if (size === null) return sorted;
  const binOf = (t: number) => Math.floor(t / size) * size;
  const firstAt = Math.min(dated[0]?.at ?? Infinity, from ?? Infinity);
  // The last bin to fill: the newest row's, or the window's last bin when it
  // has ended (the end is exclusive) and is past the ingestion lag.
  const settled = binOf(landedBy - size);
  const windowEnd = to !== undefined ? Math.min(binOf(to - 1), settled) : -Infinity;
  const lastAt = Math.max(dated.length > 0 ? binOf(dated[dated.length - 1].at) : -Infinity, windowEnd);
  if (!Number.isFinite(firstAt) || !Number.isFinite(lastAt)) return sorted;
  const start = binOf(firstAt);
  const count = (lastAt - start) / size + 1;
  const cap = Number.isFinite(maxBuckets) ? Math.max(1, Math.floor(maxBuckets)) : MAX_TIME_BUCKETS;
  if (count > cap) {
    console.warn(
      `fillTimeGaps: the rows span more than ${cap} steps of ${String(step)}; returning them unfilled`,
    );
    return sorted;
  }
  const sample = dated.length > 0 ? dated[0].row[xKey] : undefined;
  const xAt = (t: number): unknown =>
    typeof sample === "number" ? t : sample instanceof Date ? new Date(t) : new Date(t).toISOString();
  const withZeros = ({ row, at }: { row: T; at: number }): Record<string, unknown> =>
    binOf(at) <= settled && valueKeys.some((key) => row[key] == null)
      ? { ...row, ...Object.fromEntries(valueKeys.filter((key) => row[key] == null).map((key) => [key, 0])) }
      : row;
  const out: Record<string, unknown>[] = [];
  let next = 0;
  for (let i = 0; i < count; i++) {
    const bin = start + i * size;
    let found = false;
    while (next < dated.length && binOf(dated[next].at) <= bin) {
      found ||= binOf(dated[next].at) === bin;
      out.push(withZeros(dated[next++]));
    }
    if (!found && bin <= settled) {
      out.push({ [xKey]: xAt(bin), ...Object.fromEntries(valueKeys.map((key) => [key, 0])) });
    }
  }
  while (next < dated.length) out.push(withZeros(dated[next++]));
  return out;
}

// True when `d` falls on any day from `range.from` through `range.to`
// (whole days, inclusive; a reversed range is read the right way round). Pass
// `dayBins` for a calendar-binned column (as to `bucketByTime`), so a
// UTC-midnight bin is filtered on
// the calendar day its label shows (`toCalendarDay`); without it `d` is an
// instant, as an hourly row is.
export function inRange(
  d: Date | string | number,
  range: DateRange,
  dayBins = false,
): boolean {
  const date = dayBins ? toCalendarDay(d) : toDateValue(d);
  if (!date || !isValid(range.from) || !isValid(range.to)) return false;
  const [lo, hi] =
    range.from.getTime() <= range.to.getTime()
      ? [range.from, range.to]
      : [range.to, range.from];
  const t = date.getTime();
  return t >= startOfDay(lo).getTime() && t <= endOfDay(hi).getTime();
}

// Infinity keeps every item; NaN keeps one.
function clampCount(n: number): number {
  return Number.isNaN(n) ? 1 : Math.max(1, Math.floor(n));
}

// Largest first, at most `n` items in total: when there are more, the top
// n-1 are kept and the rest are summed into one `otherLabel` item. A source
// category already named `otherLabel` is summed into that same item, so the
// chart never shows two "Other" bars. Only for additive measures (counts, sums).
export function topNWithOther(
  items: LabelValue[],
  n: number,
  otherLabel: string = "Other",
): LabelValue[] {
  const sorted = [...items].sort(byValueDesc);
  const limit = clampCount(n);
  if (sorted.length <= limit) return sorted;
  const keptAt = new Set<number>();
  for (let i = 0; i < sorted.length && keptAt.size < limit - 1; i++) {
    if (sorted[i].label !== otherLabel) keptAt.add(i);
  }
  const kept = sorted.filter((_, i) => keptAt.has(i));
  const rest = sorted.reduce(
    (sum, item, i) => (keptAt.has(i) ? sum : sum + item.value),
    0,
  );
  return [...kept, { label: otherLabel, value: rest }];
}

// The largest `n` items, without an "Other" fold: for non-additive measures
// (rates, percents, averages, percentiles, durations), where summing the
// remainder is meaningless.
export function topNOnly(items: LabelValue[], n: number): LabelValue[] {
  return [...items].sort(byValueDesc).slice(0, clampCount(n));
}

const GUID_RX =
  /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;

// Every GUID in `text` shortened to "5947…a1c2", so identifiers stay distinguishable
// without being shown whole.
export function shortId(text: string): string {
  return text.replace(GUID_RX, (g) => `${g.slice(0, 4)}…${g.slice(-4)}`);
}

// Separator: @, a full-width ＠ or a URL-encoded %40. Domain labels: letters
// and digits in any script, _ and -, split by a dot (also ．, 。, ｡ or %2E).
// Local part: letters and digits in any script plus every RFC 5322 atext
// character and ’ (o'brien@…, first&last@…).
const EMAIL_SEPARATOR_RX = /@|＠|%40/g;
const EMAIL_DOMAIN_RX =
  /[\p{L}\p{M}\p{N}_-]+(?:(?:\.|．|。|｡|%2[Ee])[\p{L}\p{M}\p{N}_-]+)+/uy;
const EMAIL_LOCAL_CHAR_RX = /^[\p{L}\p{M}\p{N}!#$%&'’*+/=?^_`{|}~.-]$/u;

// Start of the run of local-part characters that ends at `end`, never before
// `floor`. A run already measured for a separator that had no domain
// ([knownFrom, knownTo)) is skipped in one step, so every character is read
// at most once per call: the scan stays linear on a long separator-free blob.
function localPartStart(
  s: string,
  end: number,
  floor: number,
  knownFrom: number,
  knownTo: number,
): number {
  let i = end;
  while (i > floor) {
    if (i === knownTo && knownFrom < knownTo) {
      i = Math.max(knownFrom, floor);
      continue;
    }
    const low = s.charCodeAt(i - 1);
    const pair =
      i - 2 >= floor &&
      low >= 0xdc00 &&
      low <= 0xdfff &&
      s.charCodeAt(i - 2) >= 0xd800 &&
      s.charCodeAt(i - 2) <= 0xdbff;
    const width = pair ? 2 : 1;
    if (!EMAIL_LOCAL_CHAR_RX.test(s.slice(i - width, i))) break;
    i -= width;
  }
  return i;
}

// Free text from a data source (incident titles, comments) can carry email
// addresses; a dashboard renders "[email]" in their place. Adjacent addresses
// ("alice@x.com/bob@y.com") are each masked; characters joining them that are
// also local-part characters ("/", or "&b=" in "a=alice@x.com&b=bob@y.com")
// are masked with the second address.
export function maskEmails(text: string | null | undefined): string {
  const s = String(text ?? "");
  let out = "";
  let floor = 0;
  let knownFrom = 0;
  let knownTo = 0;
  for (const sep of s.matchAll(EMAIL_SEPARATOR_RX)) {
    const at = sep.index ?? 0;
    if (at < floor) continue;
    const start = localPartStart(s, at, floor, knownFrom, knownTo);
    EMAIL_DOMAIN_RX.lastIndex = at + sep[0].length;
    const domain = start < at ? EMAIL_DOMAIN_RX.exec(s) : null;
    if (!domain) {
      knownFrom = start;
      knownTo = at;
      continue;
    }
    out += s.slice(floor, start) + "[email]";
    floor = EMAIL_DOMAIN_RX.lastIndex;
  }
  return floor === 0 ? s : out + s.slice(floor);
}

// `value` with every string inside it, at any depth (nested arrays and plain or
// null-prototype objects), passed through `maskEmails`. Any other object (a
// Date, Map, class instance) comes back unchanged. A shared or cyclic
// reference maps to one shared copy, and every key (an own "__proto__"
// included) stays an own data field of the copy.
export function maskEmailsDeep<T>(value: T): T {
  return maskDeep(value, new WeakMap()) as T;
}

// A table row with its emails masked: its own fields, and any plain objects
// and arrays nested in them. A class-instance row comes back as a plain object
// of its own enumerable fields (prototype getters are not copied).
export function maskEmailsRow<T>(row: T): T {
  if (row === null || typeof row !== "object" || Array.isArray(row)) {
    return maskEmailsDeep(row);
  }
  if (row instanceof Date) return row;
  const seen = new WeakMap<object, unknown>();
  const out: Record<string, unknown> = {};
  seen.set(row as object, out);
  for (const [key, value] of Object.entries(row)) {
    Object.defineProperty(out, key, {
      value: maskDeep(value, seen),
      enumerable: true,
      writable: true,
      configurable: true,
    });
  }
  return out as T;
}

function maskDeep(value: unknown, seen: WeakMap<object, unknown>): unknown {
  if (typeof value === "string") return maskEmails(value);
  if (value === null || typeof value !== "object") return value;
  if (seen.has(value)) return seen.get(value);
  if (Array.isArray(value)) {
    const out: unknown[] = new Array(value.length);
    seen.set(value, out);
    value.forEach((inner, i) => {
      out[i] = maskDeep(inner, seen);
    });
    return out;
  }
  const proto = Object.getPrototypeOf(value);
  if (proto !== Object.prototype && proto !== null) return value;
  const out: Record<string, unknown> = {};
  seen.set(value, out);
  for (const [key, inner] of Object.entries(value)) {
    Object.defineProperty(out, key, {
      value: maskDeep(inner, seen),
      enumerable: true,
      writable: true,
      configurable: true,
    });
  }
  return out;
}

// "mcp__sharepoint_onedrive__GetDriveItem" -> "Sharepoint onedrive · GetDriveItem".
// Splits on the double underscore (server names carry single ones), shortens any
// GUID, and returns other names unchanged apart from the GUID shortening.
export function toolLabel(raw: string | null | undefined): string {
  const name = shortId(String(raw ?? "").trim());
  if (!name) return "Unknown";
  const [prefix, server, ...rest] = name.split("__");
  if (prefix !== "mcp" || !server || rest.length === 0) return name;
  const readable = server.replace(/[-_]+/g, " ");
  return `${readable.charAt(0).toUpperCase()}${readable.slice(1)} · ${rest.join("__")}`;
}

function severityNumber(severity: number | string | null | undefined): number {
  if (severity == null) return NaN;
  if (typeof severity === "string" && severity.trim() === "") return NaN;
  return Number(severity);
}

// IcM severity 25 is "Sev 2.5"; every other value reads "Sev N".
export function icmSeverityLabel(severity: number | string | null | undefined): string {
  const n = severityNumber(severity);
  if (!Number.isFinite(n)) return "Sev ?";
  return n === 25 ? "Sev 2.5" : `Sev ${n}`;
}

// Sort key that orders IcM severities 1, 2, 2.5, 3, 4.
export function icmSeverityRank(severity: number | string | null | undefined): number {
  const n = severityNumber(severity);
  if (!Number.isFinite(n)) return Number.POSITIVE_INFINITY;
  return n === 25 ? 2.5 : n;
}

// "COPILOTCOWORK\Copilot Cowork (Triage\RFC)" -> "Copilot Cowork (Triage\RFC)".
// Drops only the tenant before the FIRST backslash; the team part may contain more.
export function icmTeamLabel(name: string | null | undefined): string {
  const text = String(name ?? "").trim();
  if (!text) return "Unknown";
  const cut = text.indexOf("\\");
  return cut >= 0 && cut < text.length - 1 ? text.slice(cut + 1) : text;
}

const KUSTO_CACHE_SET = /^\s*set\s+query_results_cache_max_age\b/im;

// Prefixes a KQL query with a results-cache request property, so a retry after a
// gateway timeout and every other viewer within `maxAgeMinutes` read the cluster's
// cached result instead of running the query again. A query that already sets it
// on any line (after a comment or another `set`, say) is returned unchanged.
export function kustoCached(csl: string, maxAgeMinutes = 5): string {
  if (KUSTO_CACHE_SET.test(csl)) return csl;
  const minutes = Number.isFinite(maxAgeMinutes)
    ? Math.max(1, Math.floor(maxAgeMinutes))
    : 5;
  return `set query_results_cache_max_age = time(${minutes}m);\n${csl}`;
}

// Connector ids as `ms.config.json` records them; any other id renders with a
// generic icon and the id itself, so every connection has a source to show.
export type TileConnector =
  | "shared_kusto"
  | "shared_sql"
  | "shared_commondataserviceforapps"
  | "shared_sharepointonline"
  | "shared_excelonlinebusiness"
  | (string & {});

export type TileParamValue = string | number | boolean | string[];

// A file bundled into the app, loaded as one table into the in-browser SQLite
// engine (`runLocalSql` in `@/lib/local-sql`). `embed-csv-data.sh` writes one
// per CSV. `columns` lists every column the table has, in order, keyed by the
// row field it reads; `file` is the bundled file's name, shown in View Query.
export type LocalSqlColumnType = "text" | "integer" | "real";
export type LocalSqlValue = string | number | null;

export interface LocalTable {
  name: string;
  file: string;
  columns: Readonly<Record<string, LocalSqlColumnType>>;
  rows: readonly object[];
}

// The request a tile sent. Query sources carry their text (Kusto without the
// cache line `runKql` adds); a read without a query carries the generated-client
// operation it called and the parameters that shaped the result.
export type TileRequest =
  | { kind: "kql"; cluster: string; database: string; text: string }
  | { kind: "sql"; server: string; database: string; text: string }
  | { kind: "fetchxml"; entity: string; text: string }
  | {
      kind: "operation";
      operation: string;
      params: Record<string, TileParamValue>;
      // "source" when the operation returns figures the source already totalled
      // (a DAX query on a Power BI semantic model, a summary table, a SQL view):
      // the tile then shows no row-cap warning. "none" when no tile totals
      // the rows (a detail table that only lists them): no warning either. Left
      // out, the operation is read as raw rows the browser totals.
      totals?: "source" | "none";
    }
  // A SQL query over bundled files, run in the browser by `runLocalSql`.
  // `tables` are the tables it reads, `params` its `?` values in order. Every
  // row is present, so no tile shows a row-cap warning.
  | {
      kind: "sqlite";
      tables: readonly LocalTable[];
      text: string;
      params?: readonly LocalSqlValue[];
    }
  // Rows bundled into the app (an uploaded file, sample data) and totalled by
  // page code: nothing is fetched, so every row is present and no tile shows
  // a row-cap warning.
  | { kind: "embedded"; file: string; rows?: number };

// One per query, built from the current filters and passed to both the fetch
// and every card that shows the query's result.
export interface TileSource {
  connector: TileConnector;
  // A system label the author knows ("IcM"); never inferred from a URL.
  system?: string;
  request: TileRequest;
  // One sentence for work done in the browser after the rows arrived.
  computed?: string;
}

// A tile fed by one read, or by several joined in the browser (orders against
// targets, say): one entry per read, each shown in the tile's popover.
export type TileSources = TileSource | readonly TileSource[];

export function tileSourceList(sources: TileSources): readonly TileSource[] {
  return "connector" in sources ? [sources] : sources;
}

// An empty list is no source: the card then offers no "View Query" item.
export function tileSourcesOrNone(sources: TileSources | undefined): TileSources | undefined {
  return sources && tileSourceList(sources).length > 0 ? sources : undefined;
}

// Facts known only after the fetch, passed to a card beside its `source`.
export interface TileSourceStats {
  loadedRows?: number;
  // The read stopped at its row cap (5,000 rows walked, or a full single page
  // with no verified end), so the source may hold more rows. A
  // browser-totalled tile with this set shows a row-cap warning icon.
  capped?: boolean;
  // Paged reads: how many requests were sent.
  pages?: number;
}

export type KqlTarget = { cluster: string; database: string; csl: string };

// Sends a Kusto descriptor through the caller's generated-client adapter with the
// results cache added, so the query a tile shows is the query it sent.
export function runKql<R>(
  request: Extract<TileRequest, { kind: "kql" }>,
  send: (target: KqlTarget) => Promise<R>,
  maxAgeMinutes?: number,
): Promise<R> {
  return send({
    cluster: request.cluster,
    database: request.database,
    csl: kustoCached(request.text, maxAgeMinutes),
  });
}

function paramText(value: TileParamValue): string {
  // JSON for a list, so ["a, b"] and ["a", "b"] read differently.
  return Array.isArray(value) ? JSON.stringify(value) : String(value);
}

// Where the request went: "cluster / database", "server / database", the entity
// or the operation.
export function tileRequestTarget(request: TileRequest): string {
  switch (request.kind) {
    case "kql":
      return `${request.cluster} / ${request.database}`;
    case "sql":
      return `${request.server} / ${request.database}`;
    case "fetchxml":
      return request.entity;
    case "operation":
      return request.operation;
    case "sqlite":
      return request.tables
        .map((t) => {
          const n = t.rows.length;
          return `${t.file} as ${t.name} (${numberFormat({}).format(n)} ${n === 1 ? "row" : "rows"})`;
        })
        .join(", ");
    case "embedded":
      return request.file;
  }
}

// A value as a SQLite literal: text quoted with its quotes doubled, a
// non-finite number as NULL, as the engine binds it. sql.js binds a number
// that fits in 32 bits as an INTEGER and any other as a REAL, so a larger
// whole number gets a `.0`; a negative one is parenthesized, so `- ?` never
// becomes a `--` comment. A `?` in ORDER BY or GROUP BY is a constant when
// bound but an inlined integer names a column, so a tile never puts one there.
export function sqliteLiteral(value: LocalSqlValue): string {
  if (value === null) return "NULL";
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return "NULL";
    let text = String(value);
    if (value !== (value | 0) && /^-?\d+$/.test(text)) text += ".0";
    return value < 0 ? `(${text})` : text;
  }
  return `'${value.replaceAll("'", "''")}'`;
}

// As in SQLite's tokenizer, a name is any run of identifier characters, and a
// `$` inside an identifier (`total$usd`) is part of that identifier.
const SQLITE_ID_CHAR = /[\w$\u0080-\uffff]/;

// One pass of SQLite's quoting and comment rules over `text`, the one lexer
// every reader of a tile's SQL shares: the `?` placeholders before the first
// numbered or named parameter (`invalid`), and the `[start, end)` spans of each
// closed double-quoted name (quotes included) and each comment.
export function sqliteSpans(text: string): {
  offsets: number[];
  invalid?: string;
  quoted: [number, number][];
  comments: [number, number][];
} {
  const offsets: number[] = [];
  const quoted: [number, number][] = [];
  const comments: [number, number][] = [];
  let invalid: string | undefined;
  let i = 0;
  while (i < text.length) {
    const ch = text[i];
    const close = ch === "'" || ch === '"' || ch === "`" ? ch : ch === "[" ? "]" : null;
    if (close) {
      const start = i;
      i++;
      while (i < text.length) {
        if (text[i] === close) {
          // A doubled quote is an escaped quote; `]` has no escape.
          if (close !== "]" && text[i + 1] === close) i += 2;
          else break;
        } else i++;
      }
      i++;
      if (close === '"' && i <= text.length) quoted.push([start, i]);
    } else if (ch === "-" && text[i + 1] === "-") {
      const end = text.indexOf("\n", i);
      const start = i;
      i = end < 0 ? text.length : end + 1;
      comments.push([start, i]);
    } else if (ch === "/" && text[i + 1] === "*") {
      const end = text.indexOf("*/", i + 2);
      const start = i;
      i = end < 0 ? text.length : end + 2;
      comments.push([start, i]);
    } else if (ch === "?") {
      if (/\d/.test(text[i + 1] ?? "")) {
        const number = /^\?\d+/.exec(text.slice(i))![0];
        invalid ??= number;
        i += number.length;
        continue;
      }
      if (invalid === undefined) offsets.push(i);
      i++;
    } else if (ch !== "$" && SQLITE_ID_CHAR.test(ch)) {
      while (i < text.length && SQLITE_ID_CHAR.test(text[i])) i++;
    } else if ((ch === ":" || ch === "@" || ch === "#" || ch === "$") && SQLITE_ID_CHAR.test(text[i + 1] ?? "")) {
      let end = i + 1;
      while (end < text.length && SQLITE_ID_CHAR.test(text[end])) end++;
      invalid ??= text.slice(i, end);
      i = end;
    } else i++;
  }
  return invalid === undefined ? { offsets, quoted, comments } : { offsets, invalid, quoted, comments };
}

// Every `?` placeholder in `text` that is SQL, not inside a string literal, a
// quoted identifier or a comment, as its offset; `invalid` names the first
// numbered (`?1`) or named (`:x`, `@x`, `$x`, `#x`, `$1`) parameter, which this
// engine does not bind.
export function sqlitePlaceholders(text: string): { offsets: number[]; invalid?: string } {
  const { offsets, invalid } = sqliteSpans(text);
  return invalid === undefined ? { offsets } : { offsets, invalid };
}

// The query with each `?` replaced by its value as a SQLite literal, so the
// text View Query shows runs as is against the same tables with the app's date
// functions. A `?` with no value stays a `?`.
export function inlineSqliteParams(text: string, params: readonly LocalSqlValue[] = []): string {
  const { offsets } = sqlitePlaceholders(text);
  let out = "";
  let from = 0;
  offsets.forEach((at, index) => {
    if (index >= params.length) return;
    out += text.slice(from, at) + sqliteLiteral(params[index]);
    from = at + 1;
  });
  return out + text.slice(from);
}

// A `DateRangeFilter` range as the two calendar days SQL compares
// `app_date(...)` with, earliest first ("yyyy-MM-dd", local time):
// `WHERE app_date("orderDate", 'local', 'date') BETWEEN ? AND ?`. Selects the
// same days `inRange` keeps. Null when either end is not a date.
export function sqlDayBounds(range: DateRange): [string, string] | null {
  if (!isValid(range.from) || !isValid(range.to)) return null;
  const [lo, hi] =
    range.from.getTime() <= range.to.getTime()
      ? [range.from, range.to]
      : [range.to, range.from];
  return [formatDate(lo, "yyyy-MM-dd"), formatDate(hi, "yyyy-MM-dd")];
}

// The request as copyable text: the query itself, or the operation followed by
// one `name: value` line per parameter.
export function tileRequestText(request: TileRequest): string {
  if (request.kind === "sqlite") return inlineSqliteParams(request.text, request.params);
  if (request.kind === "embedded") {
    return request.rows === undefined
      ? request.file
      : `${request.file}\nrows: ${request.rows}`;
  }
  if (request.kind !== "operation") return request.text;
  const lines = Object.entries(request.params).map(
    ([name, value]) => `${name}: ${paramText(value)}`,
  );
  return [request.operation, ...lines].join("\n");
}

// "3,812 rows loaded · paged, 3 pages · stopped at the row cap", or null.
export function tileStatsLine(stats: TileSourceStats | undefined): string | null {
  if (!stats) return null;
  const parts: string[] = [];
  if (isFiniteNumber(stats.loadedRows)) {
    const rows = Math.max(0, Math.floor(stats.loadedRows));
    parts.push(`${numberFormat({}).format(rows)} ${rows === 1 ? "row" : "rows"} loaded`);
  }
  const pages = isFiniteNumber(stats.pages) ? Math.floor(stats.pages) : 0;
  if (pages > 1) parts.push(`paged, ${pages} pages`);
  if (stats.capped) parts.push("stopped at the row cap");
  return parts.length ? parts.join(" · ") : null;
}

function rangeEndingToday(from: (today: Date) => Date): DateRange {
  const today = new Date();
  return { from: startOfDay(from(today)), to: endOfDay(today) };
}

export const DEFAULT_DATE_RANGE_PRESETS: DateRangePreset[] = [
  { label: "Last 7 days", range: () => rangeEndingToday((t) => subDays(t, 6)) },
  {
    label: "Last 30 days",
    range: () => rangeEndingToday((t) => subDays(t, 29)),
  },
  {
    label: "Last 90 days",
    range: () => rangeEndingToday((t) => subDays(t, 89)),
  },
  { label: "This quarter", range: () => rangeEndingToday(startOfQuarter) },
  { label: "Year to date", range: () => rangeEndingToday(startOfYear) },
  {
    label: "Last 12 months",
    range: () => rangeEndingToday((t) => startOfMonth(subMonths(t, 11))),
  },
];

// Presets for a fixed dataset (an attached CSV or Excel file), anchored to the
// data's own span instead of today: a file that ends in 2025 read in 2026
// leaves every today-relative preset empty. Pass each row's date; values that
// do not parse are skipped. Pass `dayBins` as you pass it to `inRange`, so a
// UTC-midnight day bin counts as the calendar day it names. "All data" comes
// first, so `presets[0].range()` is the default; a preset that covers the whole
// span, or whose days repeat an earlier one's, is dropped. When no value parses,
// `presets[0]` still exists and selects the current day: "All data" while there
// are no values (rows not loaded yet), "No dates parsed" when values were
// passed but none of them parses.
export function dataDateRangePresets(
  values: Iterable<Date | string | number | null | undefined>,
  dayBins = false,
): DateRangePreset[] {
  let first: Date | null = null;
  let last: Date | null = null;
  let anyValue = false;
  for (const value of values) {
    anyValue = true;
    const date = dayBins ? toCalendarDay(value) : toDateValue(value);
    if (!date) continue;
    if (!first || date < first) first = date;
    if (!last || date > last) last = date;
  }
  if (!first || !last) {
    const label = anyValue ? "No dates parsed" : "All data";
    return [{ label, range: () => rangeEndingToday((t) => t) }];
  }
  const start = startOfDay(first);
  const end = endOfDay(last);
  const until = (from: Date): DateRange => ({ from: startOfDay(from), to: end });
  // One preset per calendar year in the span, the latest three at most.
  // setFullYear, not the Date constructor, which reads years 0-99 as 19xx.
  const years: DateRangePreset[] = [];
  const lastYear = end.getFullYear();
  for (let year = lastYear; year >= Math.max(start.getFullYear(), lastYear - 2); year--) {
    const from = new Date(0);
    from.setFullYear(year, 0, 1);
    from.setHours(0, 0, 0, 0);
    const yearEnd = endOfDay(new Date(from));
    yearEnd.setFullYear(year, 11, 31);
    const range = { from, to: yearEnd < end ? yearEnd : end };
    years.push({ label: String(year), range: () => range });
  }
  const quarter = `Q${Math.floor(end.getMonth() / 3) + 1} ${end.getFullYear()}`;
  const relative: [string, DateRange][] = [
    [quarter, until(startOfQuarter(end))],
    ["Last 12 months of data", until(startOfMonth(subMonths(end, 11)))],
    ["Last 90 days of data", until(subDays(end, 89))],
    ["Last 30 days of data", until(subDays(end, 29))],
    ["Last 7 days of data", until(subDays(end, 6))],
  ];
  const all = { from: start, to: end };
  const coversAll = (r: DateRange) => r.from <= start && r.to >= end;
  // DateRangeFilter marks the first preset whose days match, so a later
  // preset with the same days could never show as selected.
  const seen = new Set<string>();
  const distinct = (r: DateRange) => {
    const key = `${startOfDay(r.from).getTime()}/${startOfDay(r.to).getTime()}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  };
  return [
    { label: "All data", range: () => all },
    ...years.filter((p) => !coversAll(p.range()) && distinct(p.range())),
    ...relative
      .filter(([, r]) => !coversAll(r) && distinct(r))
      .map(([label, r]): DateRangePreset => ({ label, range: () => r })),
  ];
}

// What a page stores from a DateRangeFilter over `dataDateRangePresets`, given
// the `(range, preset)` its onChange receives: null when the clicked preset is
// `presets[0]`, so `picked ?? presets[0].range()` follows the rows as they load.
// Without it, "All data" picked before the rows arrive stays stored as today's
// date. A calendar pick (no preset) is kept even when its days match `presets[0]`.
export function dataDateRangePick(
  range: DateRange,
  preset: DateRangePreset | undefined,
  presets: readonly DateRangePreset[],
): DateRange | null {
  return preset !== undefined && preset.label === presets[0]?.label ? null : range;
}

// A two-click calendar pick as a whole-day range: the earlier day starts it at
// midnight and the later one ends it at 23:59:59.999, in either click order.
export function wholeDayRange(first: Date, second: Date): DateRange {
  const [from, to] = second < first ? [second, first] : [first, second];
  return { from: startOfDay(from), to: endOfDay(to) };
}

// "Mar 1 – Mar 31, 2026" (year shown once when both ends share it); an em dash
// when either end is not a valid date.
export function formatDateRange(range: DateRange): string {
  if (!isValid(range.from) || !isValid(range.to)) return EMPTY_METRIC;
  const sameYear = range.from.getFullYear() === range.to.getFullYear();
  const from = formatDate(range.from, sameYear ? "MMM d" : "MMM d, yyyy");
  return `${from} – ${formatDate(range.to, "MMM d, yyyy")}`;
}
