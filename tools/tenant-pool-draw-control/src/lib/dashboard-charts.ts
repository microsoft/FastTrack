import type { Table } from "@tanstack/react-table";
import { format as formatDate, formatISO, startOfDay } from "date-fns";

import {
  formatExactCurrency,
  formatMetric,
  maskEmails,
  toCalendarDay,
  toDateValue,
  type LabelValue,
  type MetricFormat,
} from "@/lib/dashboard-data";
import {
  formatTemporalValue,
  temporalDate,
  type DashboardTimeZone,
  type TemporalKind,
} from "@/lib/dashboard-time-zone";

// Pure helpers behind the dashboard chart components: pre-draw data checks,
// the chart's data as a table, and CSV. No React here.

export type ChartSeriesRef = { key: string; label: string };

// A chart's data as a table, for the accessible data table and CSV export.
// Cells hold raw values; `kind` says how a cell is shown on screen.
export type ChartTableColumn = {
  label: string;
  kind: "x" | "text" | MetricFormat;
  currency?: string;
  xFormat?: string;
  dayBins?: boolean;
  timeZone?: DashboardTimeZone;
  temporalKind?: TemporalKind;
};
export type ChartTable = {
  columns: ChartTableColumn[];
  rows: (string | number | null)[][];
};

// Problems found before drawing. An error means the chart cannot be drawn
// honestly and is replaced by its message; a warning is drawn but logged.
export type ChartIssues = { errors: string[]; warnings: string[] };

const PERCENT_RATIO_LIMIT = 1.5;
export const MAX_DONUT_SLICES = 6;

// A finite number, or a string that is one ("12.5"); anything else is null.
export function toChartNumber(value: unknown): number | null {
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string" && value.trim() !== "") {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

// NaN, Infinity and a blank cell are gaps in the line, as Recharts draws
// them, not text.
function isTextWhereNumberBelongs(value: unknown): boolean {
  return (
    value != null &&
    !(typeof value === "string" && value.trim() === "") &&
    typeof value !== "number" &&
    toChartNumber(value) === null
  );
}

// What a non-number cell holds, for an error that must not echo the cell:
// the message reaches .browser-errors.log.
function kindOf(value: unknown): string {
  if (typeof value === "string") return "text";
  if (Array.isArray(value)) return "a list";
  if (value instanceof Date) return "a date";
  return typeof value === "object" ? "an object" : `a ${typeof value}`;
}

type Lookup = { found: boolean; value: unknown };

// A path's segments: dotted names, bracketed indexes and quoted bracket keys
// ('metrics["net.revenue"]' -> metrics, net.revenue).
const PATH_SEGMENT = /\[(["'])((?:\\.|(?!\1)[^\\])*)\1\]|[^.[\]]+/g;

function pathOf(key: string): string[] {
  return Array.from(key.matchAll(PATH_SEGMENT), (m) =>
    m[1] ? m[2].replace(/\\(.)/g, "$1") : m[0],
  );
}

// A data key as Recharts reads it: the row's own property first, else a
// dotted or bracketed path ("metrics.revenue", "items[0].v", 'm["v"]').
function lookup(row: unknown, key: string): Lookup {
  if (row == null || typeof row !== "object") return { found: false, value: undefined };
  if (key in row) return { found: true, value: (row as Record<string, unknown>)[key] };
  let current: unknown = row;
  for (const part of pathOf(key)) {
    if (current == null || typeof current !== "object" || !(part in current)) {
      return { found: false, value: undefined };
    }
    current = (current as Record<string, unknown>)[part];
  }
  return { found: true, value: current };
}

export function valueAt(row: unknown, key: string): unknown {
  return lookup(row, key).value;
}

export function hasKey(data: Record<string, unknown>[], key: string): boolean {
  return data.some((row) => lookup(row, key).found);
}

// Diagnostics are structural: they name the authored x key, a series by its
// place in `series`, a row by number, never a row's own keys, a label or a
// cell (a pivoted row's keys are customer content, and errors reach
// .browser-errors.log).
function percentWarning(
  what: string,
  values: (number | null)[],
  format: MetricFormat,
): string | null {
  if (format !== "percent") return null;
  const big = values.findIndex(
    (v) => v !== null && Math.abs(v) > PERCENT_RATIO_LIMIT,
  );
  return big < 0
    ? null
    : `format "percent" takes a ratio (0.12 shows as 12%), but ${what} is outside ±${PERCENT_RATIO_LIMIT} at row ${big + 1}; if the values are already percents (45 for 45%), divide by 100`;
}

// Numbers (and numeric strings) remain category labels unless the author
// explicitly declares temporalKind. A display-zone switch alone is not
// permission to reinterpret an hour-of-day or category axis as timestamps.
function isTemporalX(value: unknown, temporalKind?: TemporalKind): value is Date | string | number {
  return value instanceof Date ||
    (typeof value === "string" && (temporalKind !== undefined || /^\d{4}-\d{2}-\d{2}/.test(value))) ||
    (typeof value === "number" && temporalKind !== undefined);
}

const OFFSETLESS_DATE_TIME = /^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?$/;

function isOffsetlessDateTime(value: unknown): boolean {
  return typeof value === "string" && OFFSETLESS_DATE_TIME.test(value.trim());
}

// A valid bare "yyyy-MM-dd" (bucketByTime's bucket) names a calendar day: it
// is a date, not local midnight, so a UTC display mode never moves it a day.
// An undeclared offsetless date-time carries no zone, so UTC mode shows its
// fields as written rather than promoting them to a local instant.
function xTemporalKind(
  value: unknown,
  temporalKind?: TemporalKind,
  timeZone?: DashboardTimeZone,
): TemporalKind | undefined {
  if (temporalKind !== undefined || typeof value !== "string") return temporalKind;
  const text = value.trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    return temporalDate(text, "utc", "date") ? "date" : undefined;
  }
  return timeZone === "utc" && isOffsetlessDateTime(text) ? "wallClock" : undefined;
}

// A month ("2026-03") is dated for ordering, though shown as written on an
// untyped axis. Calendar bins keep their source calendar-day contract. An
// undeclared offsetless date-time is keyed on its fields in every mode, so two
// clock times in a local DST gap stay two periods.
function xSortKey(value: unknown, dayBins = false, temporalKind?: TemporalKind): number | null {
  if (!dayBins && temporalKind === undefined && isOffsetlessDateTime(value)) {
    return temporalDate(value as string, "utc", "wallClock")?.getTime() ?? null;
  }
  if (
    dayBins &&
    (value instanceof Date ||
      typeof value === "string" ||
      typeof value === "number")
  ) {
    return toCalendarDay(value)?.getTime() ?? null;
  }
  if (
    isTemporalX(value, temporalKind) ||
    (typeof value === "string" && /^\d{4}-\d{2}(?:-\d{2}|$)/.test(value))
  ) {
    return temporalDate(value, "local", temporalKind ?? "instant")?.getTime() ?? null;
  }
  return null;
}

function isMissingX(value: unknown): boolean {
  return value == null || (typeof value === "string" && value.trim() === "");
}

// The period an x value names: its instant when dated (with `dayBins`, its
// calendar day), otherwise its text.
function periodKey(value: unknown, dayBins: boolean, temporalKind?: TemporalKind): string {
  const instant = xSortKey(value, dayBins, temporalKind);
  return instant !== null ? `t${instant}` : `s${String(value)}`;
}

// True when a later dated x comes before an earlier one; undated x values
// (a gap, a label) are skipped, so one missing date does not hide the rest.
function outOfTimeOrder(keys: (number | null)[]): boolean {
  let previous: number | null = null;
  for (const k of keys) {
    if (k === null) continue;
    if (previous !== null && k < previous) return true;
    previous = k;
  }
  return false;
}

// Whether any row holds a number the chart can plot under `key`.
export function hasNumbers(data: Record<string, unknown>[], key: string): boolean {
  return data.some((row) => toChartNumber(valueAt(row, key)) !== null);
}

// The series with a number to draw, in order; all of them when none has one
// (or there are no rows), which checkTrendData reports as an error instead.
export function seriesInData<S extends ChartSeriesRef>(
  data: Record<string, unknown>[],
  series: S[],
): S[] {
  const present = series.filter((s) => hasNumbers(data, s.key));
  return present.length > 0 ? present : series;
}

export function checkTrendData(
  data: Record<string, unknown>[],
  xKey: string,
  series: ChartSeriesRef[],
  format: MetricFormat = "number",
  dayBins = false,
  // Another series list on the same chart draws (ComboChart's other list).
  othersDraw = false,
  temporalKind?: TemporalKind,
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (data.length === 0) return { errors, warnings };

  if (!hasKey(data, xKey)) {
    errors.push(`x key "${xKey}" is not in any row`);
  }
  // A filter can leave a series with no rows (no P1 tickets this week), or
  // with only blanks; that is a warning while another series still draws (it
  // is left out, as seriesInData does), an error when none does.
  const drawable = othersDraw || series.some((s) => hasNumbers(data, s.key));
  series.forEach((s, i) => {
    const which = `series ${i + 1}`;
    const values = data.map((row) => valueAt(row, s.key));
    const text = values.findIndex(isTextWhereNumberBelongs);
    if (text >= 0) {
      errors.push(
        `${which} has text where numbers belong (row ${text + 1} holds ${kindOf(values[text])})`,
      );
      return;
    }
    if (!hasNumbers(data, s.key)) {
      const message = hasKey(data, s.key)
        ? `${which} has no numbers to draw`
        : `the key of ${which} is not in any row`;
      if (drawable) warnings.push(`${message}; it is not drawn`);
      else errors.push(message);
      return;
    }
    const warning = percentWarning(which, values.map(toChartNumber), format);
    if (warning) warnings.push(warning);
  });
  if (errors.length > 0) return { errors, warnings };

  // Keyed on the instant when x is a date, so two timestamps a few
  // milliseconds apart are two periods even though they print alike. A row
  // with no x is no period, so blanks never repeat.
  const seen = new Map<string, { row: number; n: number }>();
  data.forEach((row, i) => {
    const x = valueAt(row, xKey);
    if (isMissingX(x)) return;
    const key = periodKey(x, dayBins, temporalKind);
    const entry = seen.get(key);
    if (entry) entry.n += 1;
    else seen.set(key, { row: i + 1, n: 1 });
  });
  const repeated = Array.from(seen.values()).find((e) => e.n > 1);
  if (repeated) {
    warnings.push(
      `the x value of row ${repeated.row} appears ${repeated.n} times; aggregate to one row per period first (bucketByTime)`,
    );
  }
  if (outOfTimeOrder(data.map((row) => xSortKey(valueAt(row, xKey), dayBins, temporalKind)))) {
    warnings.push("x values are not in time order; sort the rows oldest first");
  } else {
    const skipped = skippedPeriod(
      data.map((row) => xSortKey(valueAt(row, xKey), dayBins, temporalKind)),
    );
    if (skipped !== null) {
      warnings.push(
        `the x values skip a period after row ${skipped}, so the chart joins the points either side of it; zero-fill counts with fillTimeGaps (minute and hour bins) or bucketByTime (days and longer)`,
      );
    }
  }
  return { errors, warnings };
}

// The row (1-based) after which dated x values skip a period: a step more than
// 1.9 times the smallest step between them, so months of 28 to 31 days and
// days across a clock change are even. Needs three dated rows; null when
// nothing is skipped.
export function skippedPeriod(keys: (number | null)[]): number | null {
  const dated = keys
    .map((at, i) => ({ at, row: i + 1 }))
    .filter((k): k is { at: number; row: number } => k.at !== null);
  if (dated.length < 3) return null;
  const steps = dated.slice(1).map((k, i) => k.at - dated[i].at);
  // A loop, not Math.min(...steps): spreading a long series overflows the stack.
  let smallest = Infinity;
  for (const s of steps) if (s > 0 && s < smallest) smallest = s;
  if (!Number.isFinite(smallest)) return null;
  const at = steps.findIndex((s) => s > smallest * 1.9);
  return at < 0 ? null : dated[at].row;
}

// A KpiCard target always draws (a missing one reads "No target"), so it only
// warns: a NaN or infinite target reads "No target" though a goal was given, a
// negative target has no share to show, and a percent KPI's target past ±1.5
// is likely a whole percent where a ratio belongs.
export function checkKpiTarget(
  target: number | null | undefined,
  format: MetricFormat = "number",
): ChartIssues {
  const warnings: string[] = [];
  if (typeof target === "number" && !Number.isFinite(target)) {
    warnings.push("the target is not a finite number (NaN or Infinity), so the card shows No target");
  } else if (typeof target === "number") {
    if (target < 0) {
      warnings.push("the target is negative, so no share of it is shown; only on or off track");
    }
    if (format === "percent" && Math.abs(target) > PERCENT_RATIO_LIMIT) {
      warnings.push(
        `format "percent" takes a ratio (0.12 shows as 12%), but the target is outside ±${PERCENT_RATIO_LIMIT}; if it is already a percent (45 for 45%), divide by 100`,
      );
    }
  }
  return { errors: [], warnings };
}

// A filter's options must not depend on its own selection: options built from
// rows that are already filtered by it shrink to the chosen value, so the user
// must clear the filter before picking another. Warns (never errors) when a
// chosen value is missing from the options or is the only option offered. No
// options yet (their query is loading or failed) is nothing to compare against.
export function checkFilterOptions(
  value: readonly string[],
  options: readonly { value: string }[],
): ChartIssues {
  const chosen = value.filter((v) => v !== "");
  if (chosen.length === 0 || options.length === 0) return { errors: [], warnings: [] };
  const offered = new Set(options.map((o) => o.value));
  const missing = chosen.filter((v) => !offered.has(v));
  const warnings: string[] = [];
  if (missing.length > 0) {
    warnings.push(
      `${missing.length} chosen value${missing.length === 1 ? " is" : "s are"} not among the options; build the options from the unfiltered dimension (its own query without this filter), never from the filtered rows`,
    );
  } else if (options.length === 1) {
    warnings.push(
      "the only option offered is the chosen one; if the dimension has other values, the options may come from the filtered rows: build them from the unfiltered dimension (its own query without this filter), so another value can be picked without clearing the filter",
    );
  }
  return { errors: [], warnings };
}

// A label or path segment that names nothing: missing, null or only spaces.
export function isBlankLabel(value: unknown): boolean {
  return value == null || String(value).trim() === "";
}

export function checkCategoryData(
  data: LabelValue[],
  chart: "bar" | "share" | "treemap" | "funnel",
  format: MetricFormat = "number",
  shareVariant: "donut" | "pie" = "donut",
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  const rows = data as unknown as Record<string, unknown>[];
  for (const key of ["label", "value"]) {
    if (data.length > 0 && !hasKey(rows, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  if (chart === "treemap" || chart === "funnel") {
    // A tile or stage with no name cannot be read or selected, so it is left out.
    const blank = data.findIndex((d) => isBlankLabel(d.label));
    if (blank >= 0) {
      const n = data.filter((d) => isBlankLabel(d.label)).length;
      if (n === data.length) {
        errors.push(`no category has a label; give each row a label to draw it`);
        return { errors, warnings };
      }
      warnings.push(
        `${n} ${n === 1 ? "category has" : "categories have"} a blank label, starting with category ${blank + 1}; ${n === 1 ? "it is" : "they are"} not drawn`,
      );
    }
  }
  const text = data.findIndex((d) => isTextWhereNumberBelongs(d.value));
  if (text >= 0) {
    errors.push(
      `category ${text + 1} has text where a number belongs (it holds ${kindOf(data[text].value)})`,
    );
    return { errors, warnings };
  }
  const values = data.map((d) => toChartNumber(d.value));
  const percent = percentWarning("a value", values, format);
  if (percent) warnings.push(percent);

  const counts = new Map<string, { row: number; n: number }>();
  data.forEach((d, i) => {
    const trims = chart === "treemap" || chart === "funnel";
    if (trims && isBlankLabel(d.label)) return;
    // String(): a label can be a number at runtime, and 1 and "1" draw as one
    // category. A treemap or funnel draws the trimmed label, so " Ads" is "Ads".
    const label = trims ? String(d.label).trim() : String(d.label);
    const entry = counts.get(label);
    if (entry) entry.n += 1;
    else counts.set(label, { row: i + 1, n: 1 });
  });
  const repeated = Array.from(counts.values()).find((e) => e.n > 1);
  if (repeated) {
    warnings.push(
      `the label of category ${repeated.row} appears ${repeated.n} times; aggregate first (groupSum)`,
    );
  }
  if (chart === "share") {
    const negative = values.filter((v) => v !== null && v < 0).length;
    if (negative > 0) {
      warnings.push(
        `a ${shareVariant} cannot show negative values; ${negative} dropped (use BarBreakdown)`,
      );
    }
    const positive = values.filter((v) => v !== null && v > 0).length;
    if (positive > MAX_DONUT_SLICES) {
      warnings.push(
        `${positive} slices is too many for a ${shareVariant}; ${positive - MAX_DONUT_SLICES + 1} folded into "Other" (use BarBreakdown to rank them)`,
      );
    }
  }
  // A blank-label row is already left out (and counted) by its own warning, so
  // the value warnings count the labelled rows only.
  const labelled = values.filter((_, i) => !isBlankLabel(data[i].label));
  if (chart === "treemap" || chart === "funnel") {
    const negative = labelled.filter((v) => v !== null && v < 0).length;
    if (negative > 0) {
      warnings.push(
        `a ${chart} cannot show negative values; ${negative} dropped (use BarBreakdown)`,
      );
    }
  }
  if (chart === "treemap") {
    // A zero has no area. When every value is zero the chart shows its empty
    // state instead, so the warning is only for a zero beside drawn tiles.
    const zero = labelled.filter((v) => v === 0).length;
    if (zero > 0 && labelled.some((v) => v !== null && v > 0)) {
      warnings.push(`${zero} ${zero === 1 ? "category is" : "categories are"} zero and ${zero === 1 ? "has" : "have"} no area; not drawn`);
    }
  }
  if (chart === "funnel") {
    // Each stage is a subset of the one before; a wider stage is usually rows
    // in the wrong order or stages counted over different populations.
    // Stages are numbered as drawn, so the warning names the band the reader sees.
    let previous: number | null = null;
    let drawn = 0;
    // The drawn-stage count when each missing stage was met: none before it
    // starts the funnel, all of them before it ends the funnel.
    const missingAt: number[] = [];
    let larger: number | null = null;
    for (let i = 0; i < values.length; i++) {
      const v = values[i];
      if (isBlankLabel(data[i].label)) continue;
      if (v === null) {
        missingAt.push(drawn);
        continue;
      }
      if (v < 0) continue;
      drawn += 1;
      if (larger === null && previous !== null && v > previous) larger = drawn;
      previous = v;
    }
    if (larger !== null) {
      warnings.push(
        `stage ${larger} is larger than the stage before it; list stages in funnel order, each a subset of the last`,
      );
    }
    const stages = (n: number, where: string) =>
      `${n} ${n === 1 ? "stage" : "stages"}${where} ${n === 1 ? "has" : "have"} no value and ${n === 1 ? "is" : "are"} not drawn`;
    const leading = drawn > 0 ? missingAt.filter((at) => at === 0).length : 0;
    const trailing = drawn > 0 ? missingAt.filter((at) => at === drawn).length : 0;
    const inner = missingAt.length - leading - trailing;
    if (drawn === 0 && inner > 0) {
      warnings.push(stages(inner, ""));
    }
    if (leading > 0) {
      warnings.push(`${stages(leading, " before the first drawn")}; the funnel starts at the first stage drawn`);
    }
    if (drawn > 0 && inner > 0) {
      warnings.push(
        `${stages(inner, "")}; the drop across ${inner === 1 ? "it" : "them"} is merged into the next stage`,
      );
    }
    if (trailing > 0) {
      warnings.push(`${stages(trailing, " after the last drawn")}; the funnel ends at the last stage drawn`);
    }
  }
  return { errors, warnings };
}

// x values that look like dates (Date, "2026-03-01…") are formatted with
// `pattern`; anything else is shown as text. With `dayBins` (a calendar-binned
// column: `bin(…, 1d)`, `bin(…, 7d)`, `startofday`/`startofweek`/`startofmonth`)
// every form `inRange` and `bucketByTime` read, epoch numbers included, is a
// date, and a UTC-midnight value is shown as its calendar day (`toCalendarDay`);
// without it dated values follow the declared temporal kind and selected
// display zone (instants in Local by default). Numeric values require an
// explicit temporalKind; otherwise they remain legacy category/hour labels.
export function formatXValue(
  value: unknown,
  pattern = "MMM d, yyyy",
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string {
  const declared = temporalKind !== undefined;
  temporalKind = xTemporalKind(value, temporalKind, timeZone);
  if (
    dayBins &&
    (value instanceof Date ||
      typeof value === "string" ||
      typeof value === "number")
  ) {
    const date = toCalendarDay(value);
    if (date) return formatDate(date, pattern);
  } else if (isTemporalX(value, temporalKind)) {
    // An undeclared value that does not parse stays as written, as the CSV does.
    const text = formatTemporalValue(value, pattern, timeZone, temporalKind ?? "instant");
    if (text || declared) return text;
  }
  return value == null ? "" : String(value);
}

// The tick pattern for an x axis: `pattern` as given, plus a two-digit year
// ("May 1 '25") when the dated x values span more than one calendar year and
// the pattern names no year, so 18 months of ticks never repeat "May" for two
// different years.
export function xTickPattern(
  values: unknown[],
  pattern: string,
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string {
  if (/[yYuR]/.test(pattern.replace(/'[^']*'/g, ""))) return pattern;
  let year: number | null = null;
  for (const value of values) {
    const instant = xSortKey(value, dayBins, temporalKind);
    if (instant === null) continue;
    const text = formatXValue(value, "yyyy", dayBins, timeZone, temporalKind);
    if (!text) continue;
    const y = Number(text);
    if (year === null) year = y;
    else if (y !== year) return `${pattern} ''yy`;
  }
  return pattern;
}

// The zone one x value of a time-of-day axis is drawn in ("PDT", "GMT+2"), or
// null when it needs none: calendar-day bins, a pattern with no hour or minute,
// or a value that is not a date. Dated x values render in the viewer's local
// or UTC zone while log data and its query windows are usually UTC, so a chart
// showing hours names its zone per value. Dates and wall clocks have no zone.
export function xValueZone(
  value: unknown,
  patterns: string[],
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string | null {
  temporalKind = xTemporalKind(value, temporalKind, timeZone);
  if (dayBins || (temporalKind ?? "instant") !== "instant") return null;
  if (!patterns.some((p) => /[HhKkm]/.test(p.replace(/'[^']*'/g, ""))))
    return null;
  if (!isTemporalX(value, temporalKind)) return null;
  const date = toDateValue(value);
  if (!date || Number.isNaN(date.getTime())) return null;
  if (timeZone === "utc") return "UTC";
  return (
    new Intl.DateTimeFormat("en-US", { timeZoneName: "short" })
      .formatToParts(date)
      .find((part) => part.type === "timeZoneName")?.value ?? null
  );
}

// Every zone the axis's values are drawn in, in order: "PDT", or "PDT, then
// PST" for a window across a DST change; null when the axis needs none.
export function xTimeZoneLabel(
  values: unknown[],
  patterns: string[],
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string | null {
  const zones: string[] = [];
  for (const value of values) {
    const zone = xValueZone(value, patterns, dayBins, timeZone, temporalKind);
    if (zone && !zones.includes(zone)) zones.push(zone);
  }
  return zones.length > 0 ? zones.join(", then ") : null;
}

// One x value as the tooltip and summary print it, with its own zone.
export function formatXValueWithZone(
  value: unknown,
  pattern: string,
  zonePatterns: string[],
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string {
  const zone = xValueZone(value, zonePatterns, dayBins, timeZone, temporalKind);
  return formatXValue(value, pattern, dayBins, timeZone, temporalKind) + (zone ? ` ${zone}` : "");
}

// The summary's "from X to Y" span: one zone at the end when both ends share
// it, each end's own zone when the window crosses a DST change.
export function xSpanText(
  first: unknown,
  last: unknown,
  pattern: string,
  zonePatterns: string[],
  dayBins = false,
  timeZone: DashboardTimeZone = "local",
  temporalKind?: TemporalKind,
): string {
  const sameZone =
    xValueZone(first, zonePatterns, dayBins, timeZone, temporalKind) ===
    xValueZone(last, zonePatterns, dayBins, timeZone, temporalKind);
  const from = sameZone
    ? formatXValue(first, pattern, dayBins, timeZone, temporalKind)
    : formatXValueWithZone(first, pattern, zonePatterns, dayBins, timeZone, temporalKind);
  return `from ${from} to ${formatXValueWithZone(last, pattern, zonePatterns, dayBins, timeZone, temporalKind)}`;
}

// A Date as local ISO time with its offset ("2026-03-01T00:00:00+01:00"), so
// the time the chart shows stays the time in the file, and its milliseconds
// when it has any; an invalid Date is an empty cell, not a throw.
function dateCell(value: Date): string | null {
  if (Number.isNaN(value.getTime())) return null;
  return value.getMilliseconds()
    ? formatDate(value, "yyyy-MM-dd'T'HH:mm:ss.SSSXXX")
    : formatISO(value);
}

// A day bin (with `dayBins`, a Date or epoch-millisecond number at UTC or
// local midnight, or an Excel serial) is written as the calendar day the chart
// and table show, not as a local instant on the day before for viewers west of
// UTC, nor a bare number. Any other Date or number the chart reads as a date is
// its instant. An explicitly selected display mode exports timestamps with
// that zone's offset; date and wall-clock exports never imply an instant.
// Undeclared offsetless date-times, and undeclared date-shaped strings that do
// not parse, are exported as written.
function rawX(
  value: unknown,
  dayBins = false,
  timeZone?: DashboardTimeZone,
  temporalKind?: TemporalKind,
): string | number | null {
  if (temporalKind === undefined && !dayBins && typeof value === "string") {
    if (isOffsetlessDateTime(value)) return value;
    if (/^\d{4}-\d{2}-\d{2}$/.test(value.trim()) && xTemporalKind(value) === undefined) {
      return value;
    }
  }
  const declared = temporalKind !== undefined;
  temporalKind = xTemporalKind(value, temporalKind);
  if (dayBins && (value instanceof Date || typeof value === "number")) {
    const date = toCalendarDay(value);
    if (date) {
      const midnight = date.getTime() === startOfDay(date).getTime();
      return midnight ? formatDate(date, "yyyy-MM-dd") : dateCell(date);
    }
  }
  if (!dayBins && isTemporalX(value, temporalKind)) {
    if (temporalKind !== undefined && temporalKind !== "instant") {
      return formatTemporalValue(value, temporalKind === "date" ? "yyyy-MM-dd" : "yyyy-MM-dd'T'HH:mm:ss.SSS",
        timeZone ?? "local", temporalKind) || null;
    }
    if (timeZone !== undefined || temporalKind !== undefined) {
      const date = temporalDate(value, timeZone ?? "local", temporalKind ?? "instant");
      if (date) {
        return formatDate(date, date.getMilliseconds()
          ? "yyyy-MM-dd'T'HH:mm:ss.SSSXXX" : "yyyy-MM-dd'T'HH:mm:ssXXX");
      }
      // An undeclared value that does not parse is shown as written, so it
      // exports as written too.
      if (!declared && typeof value === "string") return value;
      return null;
    }
  }
  if (value instanceof Date) return dateCell(value);
  if (typeof value === "number" || typeof value === "string") return value;
  return value == null ? null : String(value);
}

// One row per x value, one column per series.
export function trendTable(
  data: Record<string, unknown>[],
  xKey: string,
  series: ChartSeriesRef[],
  format: MetricFormat = "number",
  currency?: string,
  xFormat = "MMM d, yyyy",
  dayBins = false,
  timeZone?: DashboardTimeZone,
  temporalKind?: TemporalKind,
): ChartTable {
  return {
    columns: [
      { label: "Period", kind: "x", xFormat, dayBins, timeZone, temporalKind },
      ...series.map((s) => ({ label: s.label, kind: format, currency })),
    ],
    rows: data.map((row) => [
      rawX(valueAt(row, xKey), dayBins, timeZone, temporalKind),
      ...series.map((s) => toChartNumber(valueAt(row, s.key))),
    ]),
  };
}

// A table's dimension header: the caller's label, or `fallback` when it is
// missing or blank, so no builder heads a column with an empty cell.
export function dimensionHeader(label: string | undefined, fallback: string): string {
  return label?.trim() || fallback;
}

// Every category, largest first (or in the given order), with its share of
// the total when the measure adds up. `categoryLabel` heads the first column
// with the dimension the rows are (Region, Product); without one it reads
// "Category".
export function categoryTable(
  data: LabelValue[],
  format: MetricFormat = "number",
  currency?: string,
  {
    withShare = format !== "percent",
    ordered = false,
    categoryLabel,
  }: { withShare?: boolean; ordered?: boolean; categoryLabel?: string } = {},
): ChartTable {
  const items = ordered
    ? data
    : [...data].sort(
        (a, b) =>
          (toChartNumber(b.value) ?? -Infinity) -
            (toChartNumber(a.value) ?? -Infinity) ||
          String(a.label).localeCompare(String(b.label)),
      );
  const total = items.reduce(
    (sum, d) => sum + Math.max(0, toChartNumber(d.value) ?? 0),
    0,
  );
  const share =
    withShare &&
    total > 0 &&
    items.every((d) => (toChartNumber(d.value) ?? 0) >= 0);
  return {
    columns: [
      { label: dimensionHeader(categoryLabel, "Category"), kind: "text" },
      { label: "Value", kind: format, currency },
      ...(share ? [{ label: "Share", kind: "percent" as const }] : []),
    ],
    rows: items.map((d) => {
      const v = toChartNumber(d.value);
      return share
        ? [d.label, v, v !== null && v >= 0 ? v / total : null]
        : [d.label, v];
    }),
  };
}

export function formatTableCell(
  value: string | number | null,
  column: ChartTableColumn,
): string {
  if (column.kind === "x") return formatXValue(
      value,
      column.xFormat ?? "MMM d, yyyy",
      column.dayBins,
      column.timeZone,
      column.temporalKind,
    );
  if (column.kind === "text") return value == null ? "" : String(value);
  if (column.kind === "currency") {
    return formatExactCurrency(toChartNumber(value), column.currency);
  }
  return formatMetric(toChartNumber(value), column.kind, column.currency);
}

// A spreadsheet opening the file would run a cell starting with one of these
// as a formula, some importers after trimming leading whitespace; prefix it
// with a quote so it stays text.
const FORMULA_START = /^\s*[=+\-@\t\r]/;

// A number held as text ("-5") stays a number in the spreadsheet.
function defuseFormula(text: string): string {
  return FORMULA_START.test(text) && toChartNumber(text) === null
    ? `'${text}`
    : text;
}

function csvCell(value: string | number | null): string {
  if (value == null) return "";
  if (typeof value === "number") return String(value);
  // Excel in a semicolon-separator locale splits a cell on ";" even inside
  // quotes, so every piece after one is defused as a cell of its own.
  const text = String(value).split(";").map(defuseFormula).join(";");
  return /[",;\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

// Raw values, so the numbers stay numbers in a spreadsheet.
export function tableToCsv(table: ChartTable): string {
  const lines = [
    table.columns.map((c) => csvCell(c.label)).join(","),
    ...table.rows.map((row) => row.map(csvCell).join(",")),
  ];
  return lines.join("\r\n") + "\r\n";
}

// "Sales by region" -> "sales-by-region"; "Ventes été" -> "ventes-ete";
// other scripts keep their letters and marks ("データ", "बिक्री").
export function exportFileName(title: string, extension: string): string {
  const words = title
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .normalize("NFC")
    .toLowerCase()
    .replace(/[^\p{L}\p{M}\p{N}]+/gu, "-")
    .replace(/^-+/, "");
  const slug = Array.from(words).slice(0, 60).join("").replace(/-+$/, "");
  return `${slug || "chart"}.${extension}`;
}

// Strings have email addresses masked, as on screen; an object or a list is
// written as JSON rather than "[object Object]".
function plainCell(value: unknown): string | number | null {
  if (value == null) return null;
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (value instanceof Date) return dateCell(value);
  if (typeof value === "object") {
    try {
      return maskEmails(JSON.stringify(value));
    } catch {
      return maskEmails(String(value));
    }
  }
  return maskEmails(String(value));
}

// A DashboardTable's data as TanStack resolves it, from the table's leaf
// columns and its rows before pagination (every page, in the shown sort
// order): every column with an accessor (an `accessorKey`, dotted or not, an
// `accessorFn`, the leaves of a grouped column). A display column (no
// accessor) is left out; a column whose header is not a string is labelled
// with its id.
export function tableExport<T>(table: Table<T>): ChartTable | null {
  const columns = table.getAllLeafColumns().filter((c) => c.accessorFn);
  const rows = table.getPrePaginationRowModel().rows;
  if (columns.length === 0 || rows.length === 0) return null;
  return {
    columns: columns.map((c) => ({
      label: typeof c.columnDef.header === "string" ? c.columnDef.header : c.id,
      kind: "text" as const,
    })),
    rows: rows.map((row) => columns.map((c) => plainCell(row.getValue(c.id)))),
  };
}
// ---------------------------------------------------------------------------
// ComboChart: bars and lines over one x column.

function inList(kind: string): (message: string) => string {
  return (message) => message.replace(/\bseries (\d+)/g, `${kind} series $1`);
}

// The bars and the lines are checked as two TrendChart series lists, each
// series named by its list ("bar series 1", "line series 2"); a problem with
// the shared x column is said once. A list with nothing to draw is a warning
// while the other list draws, as one blank series is in a TrendChart.
export function checkComboData(
  data: Record<string, unknown>[],
  xKey: string,
  bars: ChartSeriesRef[],
  lines: ChartSeriesRef[],
  format: MetricFormat = "number",
  lineFormat: MetricFormat = format,
  dayBins = false,
  temporalKind?: TemporalKind,
): ChartIssues {
  const draws = (list: ChartSeriesRef[]) => list.some((s) => hasNumbers(data, s.key));
  const b = checkTrendData(data, xKey, bars, format, dayBins, draws(lines), temporalKind);
  const l = checkTrendData(data, xKey, lines, lineFormat, dayBins, draws(bars), temporalKind);
  const errors = [
    ...new Set([...b.errors.map(inList("bar")), ...l.errors.map(inList("line"))]),
  ];
  const warnings = [
    ...new Set([...b.warnings.map(inList("bar")), ...l.warnings.map(inList("line"))]),
  ];
  if (bars.length === 0) {
    errors.push("a combo chart needs at least one bar series; use TrendChart for lines alone");
  }
  if (lines.length === 0) {
    errors.push("a combo chart needs at least one line series; use TrendChart for bars alone");
  } else if (comboLines(bars, lines).length === 0) {
    errors.push(
      "every line series draws a column a bar series already draws; a combo chart needs at least one line of its own (use TrendChart for bars alone)",
    );
  } else {
    // Keys can be customer text from a pivot, so the warning names positions only.
    lines.forEach((l, i) => {
      const bar = bars.findIndex((b) => b.key === l.key);
      if (bar >= 0) {
        warnings.push(
          `line series ${i + 1} draws the column bar series ${bar + 1} already draws; it is drawn as a bar only`,
        );
      }
    });
  }
  return { errors, warnings };
}

// The lines a ComboChart draws: a key the bars already draw is left out, so
// one column has one series, one format and one tooltip row.
export function comboLines<T extends ChartSeriesRef>(bars: ChartSeriesRef[], lines: T[]): T[] {
  const barKeys = new Set(bars.map((s) => s.key));
  return lines.filter((s) => !barKeys.has(s.key));
}

// The table keeps the time of day when the axis shows it (hourly data), to
// the second or millisecond when the axis does.
export function tableTimeFormat(xFormat: string): string | undefined {
  return /[Hhkm]/.test(xFormat)
    ? `MMM d, yyyy HH:mm${/S/.test(xFormat) ? ":ss.SSS" : /s/.test(xFormat) ? ":ss" : ""}`
    : undefined;
}

// One row per x value: the bar columns in the bars' format, then the line
// columns in the lines'.
export function comboTable(
  data: Record<string, unknown>[],
  xKey: string,
  bars: ChartSeriesRef[],
  lines: ChartSeriesRef[],
  format: MetricFormat = "number",
  lineFormat: MetricFormat = format,
  currency?: string,
  xFormat = "MMM d, yyyy",
  dayBins = false,
  timeZone?: DashboardTimeZone,
  temporalKind?: TemporalKind,
): ChartTable {
  const b = trendTable(data, xKey, bars, format, currency, xFormat, dayBins, timeZone, temporalKind);
  const l = trendTable(data, xKey, lines, lineFormat, currency, xFormat, dayBins, timeZone, temporalKind);
  return {
    columns: [...b.columns, ...l.columns.slice(1)],
    rows: b.rows.map((row, i) => [...row, ...l.rows[i].slice(1)]),
  };
}

// ---------------------------------------------------------------------------
// ScatterChart: one point per row, x against y, optionally sized.

export type PointKeys = { x: string; y: string; size?: string };
export type PointFormats = {
  x?: MetricFormat;
  y?: MetricFormat;
  size?: MetricFormat;
};

function pointRoles(keys: PointKeys): ["x" | "y" | "size", string][] {
  return [
    ["x", keys.x],
    ["y", keys.y],
    ...(keys.size ? [["size", keys.size] as ["size", string]] : []),
  ];
}

export function checkPointData(
  data: Record<string, unknown>[],
  keys: PointKeys,
  formats: PointFormats = {},
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (data.length === 0) return { errors, warnings };
  for (const [role, key] of pointRoles(keys)) {
    if (!hasKey(data, key)) {
      errors.push(`${role} key "${key}" is not in any row`);
      continue;
    }
    const values = data.map((row) => valueAt(row, key));
    const text = values.findIndex(isTextWhereNumberBelongs);
    if (text >= 0) {
      errors.push(
        `the ${role} value of row ${text + 1} is ${kindOf(values[text])} where a number belongs`,
      );
      continue;
    }
    const warning = percentWarning(`the ${role} value`, values.map(toChartNumber), formats[role] ?? "number");
    if (warning) warnings.push(warning);
  }
  if (errors.length > 0) return { errors, warnings };
  const missing = data.filter(
    (row) =>
      toChartNumber(valueAt(row, keys.x)) === null ||
      toChartNumber(valueAt(row, keys.y)) === null,
  ).length;
  if (missing === data.length) {
    errors.push("no row has both an x and a y number to plot");
  } else if (missing > 0) {
    warnings.push(`${missing} of ${data.length} rows lack an x or a y number; they are not drawn`);
  }
  if (keys.size) {
    // A bubble's area is its size, so a row with no size, a zero or a negative
    // one has no bubble to draw; drawing it at some floor would read as measured.
    // Sizes that are all zero are a quiet window, drawn as the empty state.
    const plotted = data.filter(
      (row) =>
        toChartNumber(valueAt(row, keys.x)) !== null &&
        toChartNumber(valueAt(row, keys.y)) !== null,
    );
    const sizes = plotted.map((row) => toChartNumber(valueAt(row, keys.size!)));
    const noSize = sizes.filter((v) => v === null).length;
    const negative = sizes.filter((v) => v !== null && v < 0).length;
    const zero = sizes.filter((v) => v === 0).length;
    const positive = plotted.length - noSize - negative - zero;
    if (positive === 0 && zero < plotted.length) {
      errors.push("no plotted row has a positive size; a bubble's area is its size");
    } else if (positive > 0) {
      if (zero > 0) {
        warnings.push(
          `${zero} ${zero === 1 ? "row has" : "rows have"} a size of zero and no area; ${zero === 1 ? "it is" : "they are"} not drawn`,
        );
      }
      if (noSize > 0) {
        warnings.push(
          `${noSize} ${noSize === 1 ? "row has" : "rows have"} no size number; ${noSize === 1 ? "it is" : "they are"} not drawn`,
        );
      }
      if (negative > 0) {
        warnings.push(
          `${negative} ${negative === 1 ? "row has" : "rows have"} a negative size; a bubble cannot be smaller than nothing, so ${negative === 1 ? "it is" : "they are"} not drawn`,
        );
      }
    }
  }
  return { errors, warnings };
}

export function pointTable(
  data: Record<string, unknown>[],
  keys: PointKeys & { label?: string },
  labels: { x: string; y: string; size?: string; label?: string },
  formats: PointFormats = {},
  currency?: string,
): ChartTable {
  const roles = pointRoles(keys);
  return {
    columns: [
      ...(keys.label ? [{ label: dimensionHeader(labels.label, "Point"), kind: "text" as const }] : []),
      ...roles.map(([role]) => ({
        label: labels[role] ?? role,
        kind: formats[role] ?? "number",
        currency,
      })),
    ],
    rows: data.map((row) => [
      ...(keys.label ? [plainCell(valueAt(row, keys.label)) as string | number | null] : []),
      ...roles.map(([, key]) => toChartNumber(valueAt(row, key))),
    ]),
  };
}

// ---------------------------------------------------------------------------
// FunnelChart: ordered stages, each a subset of the one before.

// The stages a funnel draws, in the given order: a stage with a blank label,
// no value or a negative value is left out (checkCategoryData warns).
export function funnelStages(data: LabelValue[]): { label: string; v: number }[] {
  return data
    .filter((d) => !isBlankLabel(d.label))
    .map((d) => ({ label: String(d.label).trim(), v: toChartNumber(d.value) }))
    .filter((d): d is { label: string; v: number } => d.v !== null && d.v >= 0);
}

// Every stage in order, with its share of the first stage and of the stage
// before it (the step's conversion).
export function funnelTable(
  data: LabelValue[],
  format: MetricFormat = "number",
  currency?: string,
): ChartTable {
  const stages = funnelStages(data);
  const first = stages[0]?.v ?? 0;
  return {
    columns: [
      { label: "Stage", kind: "text" },
      { label: "Value", kind: format, currency },
      { label: "% of first", kind: "percent" },
      { label: "% of previous", kind: "percent" },
    ],
    rows: stages.map((s, i) => {
      const previous = i > 0 ? stages[i - 1].v : null;
      return [
        s.label,
        s.v,
        first > 0 ? s.v / first : null,
        previous !== null && previous > 0 ? s.v / previous : null,
      ];
    }),
  };
}

// The plot's right edge, from one band of a funnel: every band is centred on
// the plot, whose widest band spans it, so the edge is the centre mirrored
// across the plot's left edge.
export function funnelCaptionX(bandX: number, bandWidth: number, plotLeft: number): number {
  return 2 * (bandX + bandWidth / 2) - plotLeft;
}

// ---------------------------------------------------------------------------
// WaterfallChart: a running total built from signed steps.

// A step adds its value to the running total; a `total` row is a subtotal or
// total bar from zero. A total with a value sets the running total to it (an
// opening balance, a reported subtotal); a total without one shows the running
// total so far.
export type WaterfallStep = {
  label: string;
  value?: number | string | null;
  total?: boolean;
};
export type WaterfallBar = {
  label: string;
  kind: "increase" | "decrease" | "total";
  /** The step's change, or the total's value. */
  value: number;
  /** The running total after this bar. */
  end: number;
  /** Bottom and top of the bar, low first, as a Recharts range bar reads it. */
  range: [number, number];
};

// The bars a waterfall draws, in the given order: a row with a blank label, or
// a step with no number, is left out (checkWaterfallData reports it).
export function waterfallBars(data: WaterfallStep[]): WaterfallBar[] {
  const bars: WaterfallBar[] = [];
  let running = 0;
  for (const d of data) {
    if (isBlankLabel(d.label)) continue;
    const label = String(d.label).trim();
    const v = toChartNumber(d.value);
    if (d.total) {
      if (v !== null) running = v;
      bars.push({ label, kind: "total", value: running, end: running, range: [Math.min(0, running), Math.max(0, running)] });
      continue;
    }
    if (v === null) continue;
    const start = running;
    running += v;
    bars.push({
      label,
      kind: v < 0 ? "decrease" : "increase",
      value: v,
      end: running,
      range: [Math.min(start, running), Math.max(start, running)],
    });
  }
  return bars;
}

export function checkWaterfallData(
  data: WaterfallStep[],
  format: MetricFormat = "number",
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (data.length === 0) return { errors, warnings };
  const rows = data as unknown as Record<string, unknown>[];
  for (const key of ["label", "value"]) {
    if (!hasKey(rows, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  const blank = data.findIndex((d) => isBlankLabel(d.label));
  if (blank >= 0) {
    const n = data.filter((d) => isBlankLabel(d.label)).length;
    if (n === data.length) {
      errors.push("no step has a label; give each row a label to draw it");
      return { errors, warnings };
    }
    // A dropped row with a value would move the running totals after it, so it
    // fails the chart; a blank-labelled step of 0, or one with nothing to draw, only warns.
    const held = data.findIndex((d) => {
      if (!isBlankLabel(d.label)) return false;
      if (isTextWhereNumberBelongs(d.value)) return true;
      const v = toChartNumber(d.value);
      return v !== null && (d.total || v !== 0);
    });
    if (held >= 0) {
      errors.push(`row ${held + 1} has a blank label but holds a value; label it or remove it`);
      return { errors, warnings };
    }
    warnings.push(
      `${n} ${n === 1 ? "row has" : "rows have"} a blank label, starting with row ${blank + 1}; ${n === 1 ? "it is" : "they are"} not drawn`,
    );
  }
  const labelled = data
    .map((d, i) => ({ d, row: i + 1, v: toChartNumber(d.value) }))
    .filter((r) => !isBlankLabel(r.d.label));
  // A dropped step would move every running total after it, so text in a step
  // or a total fails the chart rather than drawing a bridge that does not add up.
  const text = labelled.find((r) => isTextWhereNumberBelongs(r.d.value));
  if (text) {
    errors.push(`row ${text.row} has text where a number belongs (it holds ${kindOf(text.d.value)})`);
    return { errors, warnings };
  }
  const missing = labelled.filter((r) => !r.d.total && r.v === null);
  if (missing.length > 0) {
    const n = missing.length;
    warnings.push(
      `${n} ${n === 1 ? "step has" : "steps have"} no number, starting with row ${missing[0].row}; ${n === 1 ? "it is" : "they are"} not drawn`,
    );
  }
  if (!labelled.some((r) => r.v !== null)) {
    errors.push("no step has a value to draw");
    return { errors, warnings };
  }
  const percent = percentWarning("a value", data.map((d) => toChartNumber(d.value)), format);
  if (percent) warnings.push(percent);

  // A reported total that disagrees with the steps before it means the bridge
  // does not add up: a step is missing or counted twice. Totals are compared
  // as numbers within a relative float tolerance, never as displayed text: a
  // compact or duration format rounds real gaps of several percent away.
  const sameTotal = (a: number, b: number) =>
    Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(a), Math.abs(b));
  let running = 0;
  let drawn = false;
  let mismatch: number | null = null;
  for (const r of labelled) {
    if (r.d.total) {
      if (r.v !== null && drawn && mismatch === null && !sameTotal(r.v, running)) mismatch = r.row;
      if (r.v !== null) running = r.v;
      drawn = true;
    } else if (r.v !== null) {
      running += r.v;
      drawn = true;
    }
  }
  if (mismatch !== null) {
    warnings.push(
      `the total in row ${mismatch} does not match the running total of the rows before it; its bar shows the given total, so check for a missing or repeated step`,
    );
  }

  const counts = new Map<string, { row: number; n: number }>();
  for (const r of labelled) {
    const label = String(r.d.label).trim();
    const entry = counts.get(label);
    if (entry) entry.n += 1;
    else counts.set(label, { row: r.row, n: 1 });
  }
  const repeated = Array.from(counts.values()).find((e) => e.n > 1);
  if (repeated) {
    warnings.push(
      `the label of row ${repeated.row} appears ${repeated.n} times; give each step its own label`,
    );
  }
  return { errors, warnings };
}

// Every bar in order: its change (empty for a total), the running total after
// it, and whether it is an increase, a decrease or a total.
export function waterfallTable(
  data: WaterfallStep[],
  format: MetricFormat = "number",
  currency?: string,
): ChartTable {
  return {
    columns: [
      { label: "Step", kind: "text" },
      { label: "Change", kind: format, currency },
      { label: "Running total", kind: format, currency },
      { label: "Type", kind: "text" },
    ],
    rows: waterfallBars(data).map((b) => [
      b.label,
      b.kind === "total" ? null : b.value,
      b.end,
      WATERFALL_KIND_LABEL[b.kind],
    ]),
  };
}

export const WATERFALL_KIND_LABEL = {
  increase: "Increase",
  decrease: "Decrease",
  total: "Total",
} as const;

// A change with its sign: "+1,200", "-300".
export function signedMetric(value: number, format: MetricFormat = "number", currency?: string): string {
  return `${value > 0 ? "+" : ""}${formatMetric(value, format, currency)}`;
}

// ---------------------------------------------------------------------------
// SankeyChart: weighted flows from a source to a target.

export type Flow = { source: string; target: string; value: number | string | null };
export type FlowGraph = {
  nodes: { name: string }[];
  links: { source: number; target: number; value: number }[];
};

// Whether the flows' links form a loop anywhere, in one pass (Kahn's algorithm).
function hasCycle(adjacency: Map<string, Set<string>>): boolean {
  const incoming = new Map<string, number>();
  for (const [source, targets] of adjacency) {
    if (!incoming.has(source)) incoming.set(source, 0);
    for (const t of targets) incoming.set(t, (incoming.get(t) ?? 0) + 1);
  }
  const ready = [...incoming].filter(([, n]) => n === 0).map(([node]) => node);
  let removed = 0;
  while (ready.length > 0) {
    const node = ready.pop()!;
    removed += 1;
    for (const t of adjacency.get(node) ?? []) {
      const n = incoming.get(t)! - 1;
      incoming.set(t, n);
      if (n === 0) ready.push(t);
    }
  }
  return removed < incoming.size;
}

function reaches(adjacency: Map<string, Set<string>>, from: string, to: string): boolean {
  const seen = new Set<string>();
  const stack = [from];
  while (stack.length > 0) {
    const node = stack.pop()!;
    if (node === to) return true;
    if (seen.has(node)) continue;
    seen.add(node);
    for (const next of adjacency.get(node) ?? []) stack.push(next);
  }
  return false;
}

// A flow's source and target names, trimmed, or null when either is missing,
// null or blank. Trimmed so "Site " and "Site" are one node.
function flowEnds(flow: Flow): [string, string] | null {
  const name = (end: unknown) => (isBlankLabel(end) ? null : String(end).trim());
  const source = name(flow.source);
  const target = name(flow.target);
  return source === null || target === null ? null : [source, target];
}

export function checkFlowData(flows: Flow[], format: MetricFormat = "number"): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (flows.length === 0) return { errors, warnings };
  const rows = flows as unknown as Record<string, unknown>[];
  for (const key of ["source", "target", "value"]) {
    if (!hasKey(rows, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  const text = flows.findIndex((f) => isTextWhereNumberBelongs(f.value));
  if (text >= 0) {
    errors.push(
      `flow ${text + 1} has text where a number belongs (it holds ${kindOf(flows[text].value)})`,
    );
    return { errors, warnings };
  }
  const percent = percentWarning("a value", flows.map((f) => toChartNumber(f.value)), format);
  if (percent) warnings.push(percent);

  const adjacency = new Map<string, Set<string>>();
  const pairs = new Map<string, { row: number; n: number }>();
  const drawn: [number, string, string][] = [];
  let dropped = 0;
  let zeros = 0;
  let unnamed = 0;
  let firstUnnamed = 0;
  let firstUnnamedLive = 0;
  for (let i = 0; i < flows.length; i++) {
    const v = toChartNumber(flows[i].value);
    const ends = flowEnds(flows[i]);
    if (!ends) {
      if (unnamed === 0) firstUnnamed = i + 1;
      unnamed += 1;
      if (firstUnnamedLive === 0 && v !== null && v > 0) firstUnnamedLive = i + 1;
      continue;
    }
    if (v === null || v <= 0) {
      dropped += 1;
      if (v === 0) zeros += 1;
      continue;
    }
    const [source, target] = ends;
    if (source === target) {
      errors.push(`flow ${i + 1} goes from a node to itself; a Sankey only moves forward`);
      return { errors, warnings };
    }
    drawn.push([i, source, target]);
    if (!adjacency.has(source)) adjacency.set(source, new Set());
    adjacency.get(source)!.add(target);
    const pair = JSON.stringify([source, target]);
    const entry = pairs.get(pair);
    if (entry) entry.n += 1;
    else pairs.set(pair, { row: i + 1, n: 1 });
  }
  // Only a graph with a loop pays for naming the flow that closes it.
  if (hasCycle(adjacency)) {
    const seen = new Map<string, Set<string>>();
    for (const [i, source, target] of drawn) {
      if (reaches(seen, target, source)) {
        errors.push(
          `flow ${i + 1} closes a loop back to an earlier node; a Sankey only moves forward, so split a returning node into its own stage`,
        );
        return { errors, warnings };
      }
      if (!seen.has(source)) seen.set(source, new Set());
      seen.get(source)!.add(target);
    }
  }
  // Named rows that are all zero are an empty window unless a positive value
  // on a blank-ended row would be hidden. Missing or negative named values
  // and flows with no named ends at all remain errors when nothing is drawn.
  if (unnamed === flows.length) {
    errors.push("no flow has both a source and a target to draw");
    return { errors, warnings };
  }
  if (drawn.length === 0 && (dropped > zeros || firstUnnamedLive > 0)) {
    errors.push(
      firstUnnamedLive > 0
        ? `no flow with both a source and a target has a positive value to draw; flow ${firstUnnamedLive} has a blank source or target`
        : "no flow has a positive value to draw",
    );
    return { errors, warnings };
  }
  if (unnamed > 0) {
    warnings.push(
      `${unnamed} flows have a blank source or target, starting with flow ${firstUnnamed}; they are not drawn`,
    );
  }
  if (dropped > 0 && drawn.length > 0) {
    warnings.push(`${dropped} flows have no positive value; they are not drawn`);
  }
  const repeated = Array.from(pairs.values()).find((e) => e.n > 1);
  if (repeated) {
    warnings.push(
      `the source and target of flow ${repeated.row} appear ${repeated.n} times; they are added together`,
    );
  }
  return { errors, warnings };
}

// Average glyph width at the 12px label size, enough to decide what fits.
const FLOW_LABEL_CHAR_WIDTH = 6.5;

// Columns after the first: the longest chain of flows from any source.
export function flowDepth(nodeCount: number, links: { source: number; target: number }[]): number {
  const depth = new Array<number>(nodeCount).fill(0);
  for (let pass = 0; pass < nodeCount; pass++) {
    let changed = false;
    for (const l of links) {
      if (depth[l.target] < depth[l.source] + 1) {
        depth[l.target] = depth[l.source] + 1;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return Math.max(0, ...depth);
}

// What of "name value" fits in `room` pixels: both, the name alone, the name
// cut with an ellipsis, or nothing.
export function flowNodeLabel(
  name: string,
  value: string,
  room: number,
): { name: string; value: string } | null {
  const fits = (text: string) => text.length * FLOW_LABEL_CHAR_WIDTH <= room;
  if (fits(`${name} ${value}`)) return { name, value: ` ${value}` };
  if (fits(name)) return { name, value: "" };
  const chars = Math.floor(room / FLOW_LABEL_CHAR_WIDTH) - 1;
  return chars >= 3 ? { name: `${name.slice(0, chars)}…`, value: "" } : null;
}

// Nodes in first-seen order and one link per source and target pair, with
// repeated pairs added together. Flows with a blank source or target, or no
// positive value, are left out.
export function flowGraph(flows: Flow[]): FlowGraph {
  const index = new Map<string, number>();
  const nodes: { name: string }[] = [];
  const nodeOf = (name: string) => {
    let i = index.get(name);
    if (i === undefined) {
      i = nodes.length;
      index.set(name, i);
      nodes.push({ name });
    }
    return i;
  };
  const links = new Map<string, { source: number; target: number; value: number }>();
  for (const flow of flows) {
    const ends = flowEnds(flow);
    const v = toChartNumber(flow.value);
    if (!ends || v === null || v <= 0) continue;
    const source = nodeOf(ends[0]);
    const target = nodeOf(ends[1]);
    const key = `${source}>${target}`;
    const link = links.get(key);
    if (link) link.value += v;
    else links.set(key, { source, target, value: v });
  }
  return { nodes, links: Array.from(links.values()) };
}

// Every drawn flow, largest first.
export function flowTable(
  flows: Flow[],
  format: MetricFormat = "number",
  currency?: string,
): ChartTable {
  const graph = flowGraph(flows);
  return {
    columns: [
      { label: "From", kind: "text" },
      { label: "To", kind: "text" },
      { label: "Value", kind: format, currency },
    ],
    rows: [...graph.links]
      .sort((a, b) => b.value - a.value)
      .map((l) => [graph.nodes[l.source].name, graph.nodes[l.target].name, l.value]),
  };
}

// ---------------------------------------------------------------------------
// SunburstChart: a value per path through a hierarchy (region, country, city).

export type PathValue = { path: string[]; value: number | string | null };
export type HierarchyNode = {
  name: string;
  value: number;
  children?: HierarchyNode[];
};

function isPath(value: unknown): value is unknown[] {
  return Array.isArray(value) && value.length > 0;
}

// A path's segment names, trimmed, or null when any segment is missing, null
// or blank: a segment named "null" or "" would mislead the reader.
function pathSegments(path: unknown): string[] | null {
  if (!isPath(path) || path.some(isBlankLabel)) return null;
  return path.map((part) => String(part).trim());
}

function pathKey(path: string[]): string {
  return JSON.stringify(path);
}

export function checkPathData(rows: PathValue[], format: MetricFormat = "number"): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (rows.length === 0) return { errors, warnings };
  const records = rows as unknown as Record<string, unknown>[];
  for (const key of ["path", "value"]) {
    if (!hasKey(records, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  const badPath = rows.findIndex((r) => !isPath(r.path));
  if (badPath >= 0) {
    errors.push(
      `the path of row ${badPath + 1} is ${Array.isArray(rows[badPath].path) ? "an empty list" : kindOf(rows[badPath].path)}; give each row a list of labels from the top level down`,
    );
    return { errors, warnings };
  }
  const text = rows.findIndex((r) => isTextWhereNumberBelongs(r.value));
  if (text >= 0) {
    errors.push(
      `row ${text + 1} has text where a number belongs (it holds ${kindOf(rows[text].value)})`,
    );
    return { errors, warnings };
  }
  const blank = rows.findIndex((r) => pathSegments(r.path) === null);
  if (blank >= 0) {
    const n = rows.filter((r) => pathSegments(r.path) === null).length;
    if (n === rows.length) {
      errors.push("every row's path has a blank segment; give each level a label");
      return { errors, warnings };
    }
    warnings.push(
      `${n} ${n === 1 ? "row has" : "rows have"} a blank segment in ${n === 1 ? "its" : "their"} path, starting with row ${blank + 1}; ${n === 1 ? "it is" : "they are"} not drawn`,
    );
  }
  const percent = percentWarning("a value", rows.map((r) => toChartNumber(r.value)), format);
  if (percent) warnings.push(percent);
  const named = rows
    .map((r, i) => ({ row: i + 1, path: pathSegments(r.path), value: toChartNumber(r.value) }))
    .filter((r): r is { row: number; path: string[]; value: number | null } => r.path !== null)
    .map((r) => ({ row: r.row, path: r.path, v: r.value ?? 0, zero: r.value === 0 }));
  const drawn = named.filter((r) => r.v > 0);
  // Well-formed rows that are all zero are an empty window: the empty state.
  // A missing or negative value is malformed, so nothing drawn beside one is an error.
  if (drawn.length === 0) {
    if (!named.every((r) => r.zero)) errors.push("no row has a positive value to draw");
    return { errors, warnings };
  }
  if (drawn.length < named.length) {
    warnings.push(`${named.length - drawn.length} rows have no positive value; they are not drawn`);
  }
  const keys = new Map<string, { row: number; n: number }>();
  for (const r of drawn) {
    const key = pathKey(r.path);
    const entry = keys.get(key);
    if (entry) entry.n += 1;
    else keys.set(key, { row: r.row, n: 1 });
  }
  const repeated = Array.from(keys.values()).find((e) => e.n > 1);
  if (repeated) {
    warnings.push(
      `the path of row ${repeated.row} appears ${repeated.n} times; they are added together`,
    );
  }
  const prefixes = new Set<string>();
  for (const r of drawn) {
    for (let depth = 1; depth < r.path.length; depth++) {
      prefixes.add(pathKey(r.path.slice(0, depth)));
    }
  }
  const inner = drawn.find((r) => prefixes.has(pathKey(r.path)));
  if (inner) {
    warnings.push(
      `row ${inner.row} stops at a level other rows go below; it is not drawn, since its segment is the sum of the rows under it`,
    );
  }
  return { errors, warnings };
}

// The rows as a tree whose every node holds the sum of its children, largest
// first at each level, under a root holding the total. A row whose path is a
// prefix of another's is left out: its segment is the sum below it. A row
// with a blank segment is left out.
export function pathTree(rows: PathValue[]): HierarchyNode {
  const drawn = rows
    .map((r) => ({ path: pathSegments(r.path), v: toChartNumber(r.value) ?? 0 }))
    .filter((r): r is { path: string[]; v: number } => r.path !== null && r.v > 0);
  const prefixes = new Set<string>();
  for (const r of drawn) {
    for (let depth = 1; depth < r.path.length; depth++) {
      prefixes.add(pathKey(r.path.slice(0, depth)));
    }
  }
  type Building = { name: string; value: number; children: Map<string, Building> };
  const root: Building = { name: "All", value: 0, children: new Map() };
  for (const r of drawn) {
    if (prefixes.has(pathKey(r.path))) continue;
    const v = r.v;
    let node = root;
    node.value += v;
    for (const part of r.path) {
      let child = node.children.get(part);
      if (!child) {
        child = { name: part, value: 0, children: new Map() };
        node.children.set(part, child);
      }
      child.value += v;
      node = child;
    }
  }
  const finish = (node: Building): HierarchyNode => {
    const children = Array.from(node.children.values())
      .sort((a, b) => b.value - a.value || a.name.localeCompare(b.name))
      .map(finish);
    return children.length > 0
      ? { name: node.name, value: node.value, children }
      : { name: node.name, value: node.value };
  };
  return finish(root);
}

function hierarchyDepth(node: HierarchyNode): number {
  return node.children ? 1 + Math.max(...node.children.map(hierarchyDepth)) : 0;
}

// One row per drawn leaf in tree order: a column per level, the value and its
// share of the total.
export function pathTable(
  rows: PathValue[],
  levels: string[] = [],
  format: MetricFormat = "number",
  currency?: string,
): ChartTable {
  const tree = pathTree(rows);
  const depth = hierarchyDepth(tree);
  const out: (string | number | null)[][] = [];
  const walk = (node: HierarchyNode, trail: string[]) => {
    if (!node.children) {
      const cells: (string | number | null)[] = Array.from(
        { length: depth },
        (_, i) => trail[i] ?? null,
      );
      out.push([...cells, node.value, tree.value > 0 ? node.value / tree.value : null]);
      return;
    }
    for (const child of node.children) walk(child, [...trail, child.name]);
  };
  if (tree.children) walk(tree, []);
  return {
    columns: [
      ...Array.from({ length: depth }, (_, i) => ({
        label: dimensionHeader(levels[i], `Level ${i + 1}`),
        kind: "text" as const,
      })),
      { label: "Value", kind: format, currency },
      { label: "Share", kind: "percent" as const },
    ],
    rows: out,
  };
}

// ---------------------------------------------------------------------------
// HeatmapChart: a value per (x, y) pair, drawn as a grid of shaded cells.

export type HeatCell = {
  x: string | number;
  y: string | number;
  value: number | string | null;
};

// A heatmap's cells laid out: column and row labels in drawn order and
// `values[row][column]`, null where no cell carries a number (drawn blank,
// never as zero). `min` and `max` span the drawn values.
export type HeatmapGrid = {
  xs: string[];
  ys: string[];
  values: (number | null)[][];
  min: number;
  max: number;
};

// The most cells (columns × rows) a heatmap lays out; past it the chart is
// an error, checked before the grid is built.
export const MAX_HEATMAP_CELLS = 2500;

function heatLabel(value: unknown): string | null {
  return isBlankLabel(value) ? null : String(value).trim();
}

// A row or column order: the given labels (trimmed, blanks and repeats
// dropped) first, then the data's labels the order leaves out, as first seen.
function heatOrder(order: (string | number)[] | undefined, seen: string[]): string[] {
  const out: string[] = [];
  const has = new Set<string>();
  for (const label of [...(order ?? []), ...seen]) {
    const name = heatLabel(label);
    if (name === null || has.has(name)) continue;
    has.add(name);
    out.push(name);
  }
  return out;
}

function heatSeen(cells: HeatCell[], axis: "x" | "y"): string[] {
  const out: string[] = [];
  const has = new Set<string>();
  for (const cell of cells) {
    const name = heatLabel(cell[axis]);
    if (name === null || heatLabel(cell[axis === "x" ? "y" : "x"]) === null || has.has(name)) {
      continue;
    }
    has.add(name);
    out.push(name);
  }
  return out;
}

export function checkHeatmapData(
  cells: HeatCell[],
  format: MetricFormat = "number",
  xOrder?: (string | number)[],
  yOrder?: (string | number)[],
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (cells.length === 0) return { errors, warnings };
  const rows = cells as unknown as Record<string, unknown>[];
  for (const key of ["x", "y", "value"]) {
    if (!hasKey(rows, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  const text = cells.findIndex(
    (c) => heatLabel(c.x) !== null && heatLabel(c.y) !== null && isTextWhereNumberBelongs(c.value),
  );
  if (text >= 0) {
    errors.push(
      `cell ${text + 1} has text where a number belongs (it holds ${kindOf(cells[text].value)})`,
    );
    return { errors, warnings };
  }
  const blank = cells.findIndex((c) => heatLabel(c.x) === null || heatLabel(c.y) === null);
  if (blank >= 0) {
    const n = cells.filter((c) => heatLabel(c.x) === null || heatLabel(c.y) === null).length;
    if (n === cells.length) {
      errors.push("no cell has both an x and a y label; give each row both to draw it");
      return { errors, warnings };
    }
    warnings.push(
      `${n} ${n === 1 ? "cell has" : "cells have"} a blank x or y label, starting with cell ${blank + 1}; ${n === 1 ? "it is" : "they are"} not drawn`,
    );
  }
  const columns = heatOrder(xOrder, heatSeen(cells, "x")).length;
  const rowCount = heatOrder(yOrder, heatSeen(cells, "y")).length;
  if (columns * rowCount > MAX_HEATMAP_CELLS) {
    errors.push(
      `${columns} columns by ${rowCount} rows is ${columns * rowCount} cells, more than the ${MAX_HEATMAP_CELLS} a heatmap draws; group or filter the x and y labels first`,
    );
    return { errors, warnings };
  }
  const percent = percentWarning("a value", cells.map((c) => toChartNumber(c.value)), format);
  if (percent) warnings.push(percent);

  const pairs = new Map<string, { row: number; n: number }>();
  cells.forEach((c, i) => {
    const x = heatLabel(c.x);
    const y = heatLabel(c.y);
    if (x === null || y === null) return;
    const pair = JSON.stringify([x, y]);
    const entry = pairs.get(pair);
    if (entry) entry.n += 1;
    else pairs.set(pair, { row: i + 1, n: 1 });
  });
  const repeated = [...pairs.values()].find((p) => p.n > 1);
  if (repeated) {
    warnings.push(
      `the x and y of cell ${repeated.row} appear ${repeated.n} times; their values are added together, so aggregate to one row per pair first if that is not the sum you mean`,
    );
  }
  for (const [axis, order, name] of [
    ["x", xOrder, "xOrder"],
    ["y", yOrder, "yOrder"],
  ] as const) {
    if (!order) continue;
    const listed = new Set(order.map(heatLabel));
    const extra = heatSeen(cells, axis).filter((label) => !listed.has(label)).length;
    if (extra > 0) {
      warnings.push(
        `${extra} ${axis} ${extra === 1 ? "label is" : "labels are"} not in ${name}; ${extra === 1 ? "it is" : "they are"} drawn after the listed ones`,
      );
    }
  }
  return { errors, warnings };
}

// Rows with a blank x or y are left out; repeated (x, y) pairs are summed; a
// pair with no number is blank. Labels keep the order given, else the order
// first seen in the data, never sorted.
export function heatmapGrid(
  cells: HeatCell[],
  xOrder?: (string | number)[],
  yOrder?: (string | number)[],
): HeatmapGrid {
  const xs = heatOrder(xOrder, heatSeen(cells, "x"));
  const ys = heatOrder(yOrder, heatSeen(cells, "y"));
  const xi = new Map(xs.map((x, i) => [x, i]));
  const yi = new Map(ys.map((y, i) => [y, i]));
  const values: (number | null)[][] = ys.map(() => xs.map(() => null));
  for (const cell of cells) {
    const x = heatLabel(cell.x);
    const y = heatLabel(cell.y);
    const v = toChartNumber(cell.value);
    if (x === null || y === null || v === null) continue;
    const row = values[yi.get(y)!];
    const col = xi.get(x)!;
    row[col] = (row[col] ?? 0) + v;
  }
  const drawn = values.flat().filter((v): v is number => v !== null);
  return {
    xs,
    ys,
    values,
    min: drawn.length > 0 ? Math.min(...drawn) : 0,
    max: drawn.length > 0 ? Math.max(...drawn) : 0,
  };
}

// Where a value sits on the colour scale, 0 (lightest) to 1 (strongest). The
// scale starts at zero, or at the minimum when values go below zero, so a
// cell's shade reads as its size rather than its rank.
export function heatmapShade(value: number, min: number, max: number): number {
  const lo = Math.min(0, min);
  if (max <= lo) return value > lo ? 1 : 0;
  return Math.min(1, Math.max(0, (value - lo) / (max - lo)));
}

// The colour for a shade: the first chart colour mixed into the muted
// surface, 12% for the lowest value up to the full colour for the highest.
// One hue, so it reads in order in light and dark themes alike. Mixed in
// oklab: the muted surface is a hue-0 grey, so an oklch mix would sweep the
// hue between the two. Shared by HeatmapChart and FilledMap.
export function heatmapColor(shade: number): string {
  return `color-mix(in oklab, var(--chart-1) ${Math.round(12 + 88 * shade)}%, var(--muted))`;
}

// The grid pivoted for the data table: one row per y, one column per x;
// a blank cell is an empty table cell.
export function heatmapTable(
  grid: HeatmapGrid,
  format: MetricFormat = "number",
  currency?: string,
  rowLabel = "Row",
): ChartTable {
  return {
    columns: [
      { label: dimensionHeader(rowLabel, "Row"), kind: "text" },
      ...grid.xs.map((x) => ({ label: x, kind: format, currency })),
    ],
    rows: grid.ys.map((y, i) => [y, ...grid.values[i]]),
  };
}

// ---------------------------------------------------------------------------
// PivotTable: flat rows grouped by row and column fields, one aggregate per
// value field, with group subtotals and grand totals.

export type PivotAgg = "sum" | "count" | "avg" | "min" | "max";

export type PivotValue = {
  field: string;
  agg: PivotAgg;
  format?: MetricFormat;
  label?: string;
};

// One row of the pivot: a group (it has children, its cells are the
// subtotal) or a leaf. `cells` runs column by column, each column holding one
// cell per value field; the Total column, when there is one, comes last. A
// cell is null where no source row gives that aggregate a number (a count
// there is 0).
export type PivotRowNode = {
  id: string;
  path: string[];
  depth: number;
  cells: (number | null)[];
  children: PivotRowNode[];
};

// `columns` holds each column's labels, one per column field, in the order
// first seen in the data (or `columnOrder`'s), with columns that share an
// outer label kept together under it; with no column fields it is one
// unlabelled column.
// `total` is the grand total row, aggregated from the source rows (not from
// the subtotals, so avg, min and max stay right).
export type PivotGrid = {
  columns: string[][];
  totalColumn: boolean;
  values: PivotValue[];
  rows: PivotRowNode[];
  total: (number | null)[];
};

export const PIVOT_AGGS: readonly PivotAgg[] = ["sum", "count", "avg", "min", "max"];

// A count is a number of non-blank values, so it never takes the field's currency or
// percent format.
export function pivotValueFormat(value: PivotValue): MetricFormat {
  return value.agg === "count" ? "number" : (value.format ?? "number");
}

// The most source rows a pivot aggregates in the browser; past it the table is
// an error, and the query should aggregate by the row and column fields.
export const MAX_PIVOT_SOURCE_ROWS = 20000;
// The most distinct columns (combinations of column labels) a pivot draws.
export const MAX_PIVOT_COLUMNS = 60;
// The most value cells (rows, subtotals and the total row, times columns
// including Total, times value fields) a pivot draws.
export const MAX_PIVOT_CELLS = 20000;

export const PIVOT_BLANK_LABEL = "(blank)";
// The labels the table and its CSV give the Total column, subtotal rows and
// the grand total row.
const PIVOT_TOTAL_LABELS = ["total", "grand total"];

const PIVOT_AGG_LABEL: Record<PivotAgg, string> = {
  sum: "Sum",
  count: "Count",
  avg: "Average",
  min: "Min",
  max: "Max",
};

// Labels are customer content: emails are masked, as DashboardTable masks its
// rows. A blank label is grouped as "(blank)" so totals still add up.
function pivotLabel(value: unknown): string {
  return isBlankLabel(value) ? PIVOT_BLANK_LABEL : maskEmails(String(value).trim());
}

export function pivotValueLabel(value: PivotValue): string {
  return value.label ?? `${PIVOT_AGG_LABEL[value.agg] ?? value.agg} of ${value.field}`;
}

function pivotShape(
  data: Record<string, unknown>[],
  rowFields: string[],
  columnFields: string[],
): { columns: number; rowNodes: number } {
  const columns = new Set<string>();
  const rowNodes = new Set<string>();
  for (const row of data) {
    columns.add(JSON.stringify(columnFields.map((f) => pivotLabel(valueAt(row, f)))));
    const path = rowFields.map((f) => pivotLabel(valueAt(row, f)));
    for (let d = 1; d <= path.length; d++) rowNodes.add(JSON.stringify(path.slice(0, d)));
  }
  return { columns: columns.size, rowNodes: rowNodes.size };
}

export function checkPivotData(
  data: Record<string, unknown>[],
  rowFields: string[],
  columnFields: string[],
  values: PivotValue[],
  columnOrder?: (string | number)[],
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (rowFields.length === 0) {
    errors.push("rows names no field; give at least one field to group rows by");
  }
  if (values.length === 0) {
    errors.push("values names no field; give at least one { field, agg }");
  }
  const fields = [...rowFields, ...columnFields];
  const repeated = fields.find((f, i) => fields.indexOf(f) !== i);
  if (repeated !== undefined) {
    errors.push(`the "${repeated}" field is listed more than once across rows and columns`);
  }
  values.forEach((v, i) => {
    if (!PIVOT_AGGS.includes(v.agg)) {
      errors.push(`values[${i}] has agg "${String(v.agg)}"; use one of ${PIVOT_AGGS.join(", ")}`);
    }
  });
  if (errors.length > 0 || data.length === 0) return { errors, warnings };
  if (data.length > MAX_PIVOT_SOURCE_ROWS) {
    errors.push(
      `${data.length} source rows is more than the ${MAX_PIVOT_SOURCE_ROWS} a pivot table aggregates in the browser; aggregate in the query by the row and column fields and pivot that (its totals are right for sum, min and max; for an average return a sum and a count, and sum a count)`,
    );
    return { errors, warnings };
  }
  for (const field of [...fields, ...values.map((v) => v.field)]) {
    if (!hasKey(data, field)) errors.push(`the "${field}" field is not in any row`);
  }
  if (errors.length > 0) return { errors: [...new Set(errors)], warnings };
  for (const field of fields) {
    const at = data.findIndex((row) => {
      const value = valueAt(row, field);
      return value !== null && typeof value === "object";
    });
    if (at >= 0) {
      errors.push(
        `the "${field}" field holds ${kindOf(valueAt(data[at], field))} at row ${at + 1}; a row or column label must be text or a number, so format a date as text first (formatCalendarDay)`,
      );
    }
  }
  if (errors.length > 0) return { errors, warnings };
  values.forEach((v, i) => {
    if (v.agg === "count") return;
    const text = data.findIndex((row) => isTextWhereNumberBelongs(valueAt(row, v.field)));
    if (text >= 0) {
      errors.push(
        `values[${i}] ("${v.field}") has text where a number belongs at row ${text + 1} (it holds ${kindOf(valueAt(data[text], v.field))}); use agg "count" to count it`,
      );
    }
  });
  if (errors.length > 0) return { errors, warnings };
  // Masking runs before grouping, so two different addresses would merge into
  // one "[email]" group and add their totals together without a word. A label
  // already reading "[email]" counts too, since an address merges into it.
  // Labels group only under the same parent labels (the outer row fields, or
  // the outer column fields), so they are compared there. Addresses differing
  // only in letter case are treated as one mailbox (a mail host may tell them
  // apart, so the merge is warned below, never silent).
  fields.forEach((field, i) => {
    const outer = i < rowFields.length ? rowFields.slice(0, i) : columnFields.slice(0, i - rowFields.length);
    const rawByGroup = new Map<string, Set<string>>();
    const spellingsByGroup = new Map<string, Map<string, number>>();
    data.forEach((row, at) => {
      const value = valueAt(row, field);
      if (isBlankLabel(value)) return;
      const raw = String(value).trim();
      const label = pivotLabel(value);
      const group = JSON.stringify([...outer.map((f) => pivotLabel(valueAt(row, f))), label]);
      const spellings = spellingsByGroup.get(group) ?? new Map<string, number>();
      const spelling = `${typeof value}:${String(value)}`;
      if (!spellings.has(spelling)) spellings.set(spelling, at);
      spellingsByGroup.set(group, spellings);
      if (label === raw && !label.includes("[email]")) return;
      const raws = rawByGroup.get(group) ?? new Set<string>();
      raws.add(raw.toLowerCase());
      rawByGroup.set(group, raws);
    });
    const merged = Math.max(0, ...[...rawByGroup.values()].map((s) => s.size));
    if (merged > 1) {
      errors.push(
        `the "${field}" field holds ${merged} different labels with email addresses (or a literal "[email]"), which are masked alike and would merge into one group; group by a name or ID field instead`,
      );
    } else {
      const spelled = [...spellingsByGroup.values()].find((s) => s.size > 1);
      if (spelled) {
        const [first, second] = [...spelled.values()];
        warnings.push(
          `the "${field}" field holds one label written ${spelled.size} ways, first at rows ${first + 1} and ${second + 1} (extra spaces, an address's letter case, or a number and text), which are grouped together; clean the labels in the query if they are different`,
        );
      }
    }
  });
  if (errors.length > 0) return { errors, warnings };

  const { columns, rowNodes } = pivotShape(data, rowFields, columnFields);
  if (columns > MAX_PIVOT_COLUMNS) {
    errors.push(
      `the column fields make ${columns} columns, more than the ${MAX_PIVOT_COLUMNS} a pivot table draws; move a field to rows, or group or filter its labels first`,
    );
    return { errors, warnings };
  }
  const cells = (rowNodes + 1) * (columns + (columnFields.length > 0 ? 1 : 0)) * values.length;
  if (cells > MAX_PIVOT_CELLS) {
    errors.push(
      `${rowNodes} rows by ${columns} columns of ${values.length} ${values.length === 1 ? "value" : "values"} is ${cells} cells, more than the ${MAX_PIVOT_CELLS} a pivot table draws; filter the rows or group their labels first`,
    );
    return { errors, warnings };
  }

  const isBlankRow = (row: Record<string, unknown>) =>
    fields.some((f) => isBlankLabel(valueAt(row, f)));
  const blank = data.findIndex(isBlankRow);
  if (blank >= 0) {
    const n = data.filter(isBlankRow).length;
    warnings.push(
      `${n} ${n === 1 ? "row has" : "rows have"} a blank row or column label, starting with row ${blank + 1}; ${n === 1 ? "it is" : "they are"} grouped under "${PIVOT_BLANK_LABEL}"`,
    );
    const shared = fields.find(
      (f) =>
        data.some((row) => isBlankLabel(valueAt(row, f))) &&
        data.some((row) => !isBlankLabel(valueAt(row, f)) && pivotLabel(valueAt(row, f)) === PIVOT_BLANK_LABEL),
    );
    if (shared !== undefined) {
      warnings.push(
        `the "${shared}" field also holds the label "${PIVOT_BLANK_LABEL}", so its rows are grouped with the blank ones`,
      );
    }
  }
  for (const field of fields) {
    const marker = data
      .map((row) => valueAt(row, field))
      .find((value) => PIVOT_TOTAL_LABELS.includes(pivotLabel(value).toLowerCase()));
    if (marker !== undefined) {
      warnings.push(
        `the "${field}" field holds the label "${pivotLabel(marker)}", which reads like the table's own total row or column; rename it in the query`,
      );
    }
  }
  values.forEach((v, i) => {
    if (v.format !== "percent" || v.agg === "count") return;
    if (v.agg === "sum") {
      warnings.push(
        `values[${i}] adds up "percent" values with agg "sum"; a sum of ratios is rarely the number meant, so use "avg" or compute the ratio in the query`,
      );
    }
    const percent = percentWarning(
      `values[${i}]`,
      data.map((row) => toChartNumber(valueAt(row, v.field))),
      "percent",
    );
    if (percent) warnings.push(percent);
  });
  warnings.push(...pivotOrderWarnings(data, columnFields, columnOrder));
  return { errors, warnings };
}

type PivotAcc = { sum: number; numbers: number; count: number; min: number; max: number };

function pivotAcc(): PivotAcc {
  return { sum: 0, numbers: 0, count: 0, min: Infinity, max: -Infinity };
}

function pivotAdd(accs: PivotAcc[], row: Record<string, unknown>, values: PivotValue[]) {
  values.forEach((v, i) => {
    const raw = valueAt(row, v.field);
    const acc = accs[i];
    if (!isBlankLabel(raw)) acc.count += 1;
    const n = toChartNumber(raw);
    if (n === null) return;
    acc.numbers += 1;
    acc.sum += n;
    acc.min = Math.min(acc.min, n);
    acc.max = Math.max(acc.max, n);
  });
}

function pivotResult(acc: PivotAcc, agg: PivotAgg): number | null {
  if (agg === "count") return acc.count;
  if (acc.numbers === 0) return null;
  if (agg === "sum") return acc.sum;
  if (agg === "avg") return acc.sum / acc.numbers;
  return agg === "min" ? acc.min : acc.max;
}

// The first column field's labels that `columnOrder` leaves out, as first seen.
function pivotUnlisted(
  data: Record<string, unknown>[],
  field: string,
  columnOrder: (string | number)[],
): string[] {
  const listed = new Set(columnOrder.map(pivotLabel));
  const out = new Set<string>();
  for (const row of data) {
    const label = pivotLabel(valueAt(row, field));
    if (!listed.has(label)) out.add(label);
  }
  return [...out];
}

function pivotOrderWarnings(
  data: Record<string, unknown>[],
  columnFields: string[],
  columnOrder: (string | number)[] | undefined,
): string[] {
  if (!columnOrder) return [];
  if (columnFields.length === 0) {
    return ["columnOrder is set but columns names no field; it is ignored"];
  }
  const extra = pivotUnlisted(data, columnFields[0], columnOrder).length;
  if (extra === 0) return [];
  return [
    `${extra} "${columnFields[0]}" ${extra === 1 ? "label is" : "labels are"} not in columnOrder; ${extra === 1 ? "it is" : "they are"} drawn after the listed ones`,
  ];
}

// Groups `data` by the row fields (nested, in that order) and the column
// fields, aggregating each value field at every level from the source rows.
// Rows keep the order first seen in the data, never sorted: the query's order
// is the table's. Columns do too, grouped so the columns sharing a label at
// each column field sit together under one header, except that `columnOrder`
// puts the listed labels of the first column field first, in its order.
export function pivotGrid(
  data: Record<string, unknown>[],
  rowFields: string[],
  columnFields: string[],
  values: PivotValue[],
  columnOrder?: (string | number)[],
): PivotGrid {
  const seen = new Map<string, string[]>();
  const keyed = data.map((row) => {
    const labels = columnFields.map((f) => pivotLabel(valueAt(row, f)));
    const key = JSON.stringify(labels);
    if (!seen.has(key)) seen.set(key, labels);
    return { row, key, path: rowFields.map((f) => pivotLabel(valueAt(row, f))) };
  });
  const columns = [...seen.values()];
  const rank = new Map<string, number>();
  if (columnFields.length > 0) {
    columnOrder?.forEach((label) => {
      const name = pivotLabel(label);
      if (!rank.has(name)) rank.set(name, rank.size);
    });
  }
  const firstSeen = new Map<string, number>();
  const sortKeys = new Map(
    columns.map((labels) => {
      const key = labels.map((_, d) => {
        const prefix = JSON.stringify(labels.slice(0, d + 1));
        if (!firstSeen.has(prefix)) firstSeen.set(prefix, firstSeen.size);
        return firstSeen.get(prefix)!;
      });
      return [labels, [rank.get(labels[0]) ?? rank.size, ...key]];
    }),
  );
  columns.sort((a, b) => {
    const ka = sortKeys.get(a)!;
    const kb = sortKeys.get(b)!;
    for (let i = 0; i < ka.length; i++) if (ka[i] !== kb[i]) return ka[i] - kb[i];
    return 0;
  });
  const columnIndex = new Map(columns.map((labels, i) => [JSON.stringify(labels), i]));
  const totalColumn = columnFields.length > 0;
  const width = columns.length + (totalColumn ? 1 : 0);
  type Build = { node: PivotRowNode; accs: PivotAcc[][]; kids: Map<string, Build> };
  const build = (path: string[]): Build => ({
    node: { id: JSON.stringify(path), path, depth: path.length - 1, cells: [], children: [] },
    accs: Array.from({ length: width }, () => values.map(pivotAcc)),
    kids: new Map(),
  });
  const root = build([]);
  for (const { row, key, path } of keyed) {
    const column = columnIndex.get(key)!;
    const add = (b: Build) => {
      pivotAdd(b.accs[column], row, values);
      if (totalColumn) pivotAdd(b.accs[columns.length], row, values);
    };
    add(root);
    let at = root;
    path.forEach((label, d) => {
      let next = at.kids.get(label);
      if (!next) {
        next = build(path.slice(0, d + 1));
        at.kids.set(label, next);
        at.node.children.push(next.node);
      }
      at = next;
      add(at);
    });
  }
  const finish = (b: Build) => {
    b.node.cells = b.accs.flatMap((slot) => slot.map((acc, i) => pivotResult(acc, values[i].agg)));
    b.kids.forEach(finish);
  };
  finish(root);
  return { columns, totalColumn, values, rows: root.node.children, total: root.node.cells };
}

// A label joined into a multi-field column header: one holding "/" or a quote
// is quoted, its quotes doubled, so ["A / B", "C"] and ["A", "B / C"] keep
// different headers.
const pivotHeaderSegment = (label: string) =>
  /["/]/.test(label) ? `"${label.replaceAll('"', '""')}"` : label;

// One header per value cell, in `cells` order: the column's labels joined by
// " / " (quoted where a label holds "/" or a quote), then the value's label
// when there is more than one value (or no column fields); the Total column is
// "Total".
export function pivotCellLabels(grid: PivotGrid): string[] {
  const slots = [
    ...grid.columns.map((labels) =>
      labels.length > 1 ? labels.map(pivotHeaderSegment).join(" / ") : labels.join(""),
    ),
    ...(grid.totalColumn ? ["Total"] : []),
  ];
  return slots.flatMap((slot) =>
    grid.values.map((v) => {
      const value = pivotValueLabel(v);
      if (!slot) return value;
      return grid.values.length > 1 ? `${slot} · ${value}` : slot;
    }),
  );
}

// The pivoted view as a table, for CSV: one text column per row field, then
// one column per value cell. Each group's subtotal row (its path, then
// "Total") comes before its children, as drawn with every group expanded, and
// the grand total row comes last.
export function pivotTable(
  grid: PivotGrid,
  rowLabels: string[],
  currency?: string,
): ChartTable {
  const columns: ChartTableColumn[] = [
    ...rowLabels.map((label, i) => ({
      label: dimensionHeader(label, `Level ${i + 1}`),
      kind: "text" as const,
    })),
    ...pivotCellLabels(grid).map((label, i) => ({
      label,
      kind: pivotValueFormat(grid.values[i % grid.values.length]),
      currency,
    })),
  ];
  const rows: (string | number | null)[][] = [];
  const pad = (path: string[], fill: string) =>
    rowLabels.map((_, i) => (i < path.length ? path[i] : i === path.length ? fill : ""));
  const walk = (node: PivotRowNode) => {
    rows.push([...pad(node.path, "Total"), ...node.cells]);
    node.children.forEach(walk);
  };
  grid.rows.forEach(walk);
  rows.push([...pad([], "Grand total"), ...grid.total]);
  return { columns, rows };
}

// ---------------------------------------------------------------------------
// FilledMap: a value per region, drawn as a shaded map.

export type FilledMapRow = {
  region: string | number;
  value: number | string | null;
};

// A region on a filled map, as the map's outline data names it.
export type FilledMapRegion = { code: string; fips: string; name: string };

// Regions keyed by the map's values, in the data's first-seen order, with the
// row label each region was first given as (what `onSelect` hands back).
export type FilledMapValues = {
  values: Map<string, number>;
  labels: Map<string, string>;
  order: string[];
  min: number;
  max: number;
};

// A region label as matched: case, commas, repeated spaces and a dot after a
// letter ignored, so "TX", "tx", "Texas", "District of Columbia" and
// "Washington, D.C." all match. A dot after a digit is kept, so a decimal such
// as "1.0" matches no FIPS code rather than becoming "10" (Delaware). Never
// fuzzy.
function regionKey(value: unknown): string | null {
  if (isBlankLabel(value)) return null;
  const key = String(value)
    .toUpperCase()
    .replace(/([A-Z])\./g, "$1")
    .replace(/[\s,]+/g, " ")
    .trim();
  return key === "" ? null : key;
}

// Every label a region answers to: its postal code ("TX"), its FIPS code
// ("48", and "6" as well as "06") and its name ("Texas").
export function filledMapIndex(regions: readonly FilledMapRegion[]): Map<string, string> {
  const index = new Map<string, string>();
  for (const r of regions) {
    for (const label of [r.code, r.fips, String(Number(r.fips)), r.name]) {
      const key = regionKey(label);
      if (key !== null) index.set(key, r.code);
    }
  }
  if (index.has("DC")) index.set("WASHINGTON DC", "DC");
  return index;
}

export function checkFilledMapData(
  rows: FilledMapRow[],
  regions: readonly FilledMapRegion[],
  format: MetricFormat = "number",
  mapName = "map",
): ChartIssues {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (rows.length === 0) return { errors, warnings };
  const records = rows as unknown as Record<string, unknown>[];
  for (const key of ["region", "value"]) {
    if (!hasKey(records, key)) errors.push(`the ${key} key is not in any row`);
  }
  if (errors.length > 0) return { errors, warnings };
  // Only rows on the map are drawn, so only their values are checked: a
  // territory or a "Total" row holding text is left out with a warning, and
  // never blanks the map.
  const index = filledMapIndex(regions);
  const blank: number[] = [];
  const unmatched: number[] = [];
  const matched: (number | null)[] = rows.map(() => null);
  const seen = new Map<string, { row: number; n: number; sum: number }>();
  let text = -1;
  rows.forEach((r, i) => {
    const key = regionKey(r.region);
    if (key === null) {
      blank.push(i + 1);
      return;
    }
    const code = index.get(key);
    if (code === undefined) {
      unmatched.push(i + 1);
      return;
    }
    if (text < 0 && isTextWhereNumberBelongs(r.value)) text = i;
    const v = toChartNumber(r.value);
    matched[i] = v;
    const entry = seen.get(code);
    if (entry) {
      entry.n += 1;
      entry.sum += v ?? 0;
    } else seen.set(code, { row: i + 1, n: 1, sum: v ?? 0 });
  });
  if (text >= 0) {
    errors.push(
      `row ${text + 1} has text where a number belongs (it holds ${kindOf(rows[text].value)})`,
    );
    return { errors, warnings };
  }
  const huge = [...seen.values()].find((p) => !Number.isFinite(p.sum));
  if (huge) {
    errors.push(
      `the values for the region of row ${huge.row} add up to more than a number can hold`,
    );
    return { errors, warnings };
  }
  if (seen.size === 0) {
    errors.push(
      blank.length === rows.length
        ? "no row has a region; give each row one to draw it"
        : `no row's region is on the ${mapName}; name regions by postal code ("TX"), FIPS code ("48") or full name ("Texas")`,
    );
    return { errors, warnings };
  }
  if (blank.length > 0) {
    const n = blank.length;
    warnings.push(
      `${n} ${n === 1 ? "row has" : "rows have"} a blank region, starting with row ${blank[0]}; ${n === 1 ? "it is" : "they are"} not drawn`,
    );
  }
  if (unmatched.length > 0) {
    const n = unmatched.length;
    warnings.push(
      `${n} ${n === 1 ? "row names a region" : "rows name regions"} not on the ${mapName}, starting with row ${unmatched[0]}; ${n === 1 ? "it is" : "they are"} not drawn (use postal codes, FIPS codes or full names)`,
    );
  }
  const repeated = [...seen.values()].find((p) => p.n > 1);
  if (repeated) {
    warnings.push(
      `the region of row ${repeated.row} appears ${repeated.n} times; their values are added together, so aggregate to one row per region first if that is not the sum you mean`,
    );
  }
  const percent = percentWarning("a value", matched, format);
  if (percent) warnings.push(percent);
  return { errors, warnings };
}

// Rows matched to regions: blank and unmatched rows are left out, repeats
// are summed, a region with no number has no value (drawn as no data, never
// zero).
export function filledMapValues(
  rows: FilledMapRow[],
  regions: readonly FilledMapRegion[],
): FilledMapValues {
  const index = filledMapIndex(regions);
  const values = new Map<string, number>();
  const labels = new Map<string, string>();
  const order: string[] = [];
  for (const r of rows) {
    const key = regionKey(r.region);
    const code = key === null ? undefined : index.get(key);
    if (code === undefined) continue;
    if (!labels.has(code)) {
      labels.set(code, String(r.region).trim());
      order.push(code);
    }
    const v = toChartNumber(r.value);
    if (v !== null) values.set(code, (values.get(code) ?? 0) + v);
  }
  const drawn = [...values.values()];
  return {
    values,
    labels,
    order,
    min: drawn.length > 0 ? Math.min(...drawn) : 0,
    max: drawn.length > 0 ? Math.max(...drawn) : 0,
  };
}

// One row per region the data names, in the data's order; a region with no
// number is an empty cell.
export function filledMapTable(
  map: FilledMapValues,
  regions: readonly FilledMapRegion[],
  format: MetricFormat = "number",
  currency?: string,
  regionLabel = "Region",
  valueLabel = "Value",
): ChartTable {
  const names = new Map(regions.map((r) => [r.code, r.name]));
  return {
    columns: [
      { label: dimensionHeader(regionLabel, "Region"), kind: "text" },
      { label: valueLabel, kind: format, currency },
    ],
    rows: map.order.map((code) => [names.get(code) ?? code, map.values.get(code) ?? null]),
  };
}
