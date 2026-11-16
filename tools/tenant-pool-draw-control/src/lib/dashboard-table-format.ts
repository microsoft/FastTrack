import type { RowData } from "@tanstack/react-table";

import { toChartNumber, type ChartIssues } from "@/lib/dashboard-charts";

// Conditional formatting for a DashboardTable column, set on its definition:
// `{ accessorKey: "revenue", header: "Revenue", meta: { format: { kind: "dataBar" } } }`.
// Formatting is drawn on the visible page only, scaled over every row so a
// value keeps its look across pages and sorts; the CSV export stays raw.
const CELL_TONES = ["good", "warn", "bad"] as const;
export type CellTone = (typeof CELL_TONES)[number];

const RULE_OPERATORS = [">", ">=", "<", "<=", "="] as const;

export type FormatRule = {
  when: (typeof RULE_OPERATORS)[number];
  value: number;
  tone: CellTone;
  // Read by screen readers in place of the tone's name ("good", "warning", "bad").
  label?: string;
};

export type CellFormat =
  | { kind: "dataBar" }
  | {
      kind: "colorScale";
      // sequential: none -> chart colour. diverging: bad -> none -> good.
      scheme?: "sequential" | "diverging";
      goodDirection?: "up" | "down";
      // Diverging only: defaults to 0 when the values span it, else their middle.
      midpoint?: number;
    }
  // The first rule that matches wins; a value no rule matches is left plain.
  | { kind: "rules"; rules: FormatRule[] };

declare module "@tanstack/react-table" {
  interface ColumnMeta<TData extends RowData, TValue> {
    format?: CellFormat;
  }
}

export type FormatDomain = { min: number; max: number };

// The strongest tint any background takes, so body text keeps WCAG AA
// contrast on it in light and dark mode.
export const MAX_TINT = 0.35;
// The weakest visible tint, for a value just off the scale's start.
const MIN_TINT = 0.06;

const GOOD_COLOR = "var(--color-emerald-500, oklch(0.696 0.17 162.48))";
const BAD_COLOR = "var(--destructive)";
const SCALE_COLOR = "var(--chart-1)";

export function formatDomain(values: readonly unknown[]): FormatDomain | null {
  let min = Infinity;
  let max = -Infinity;
  for (const value of values) {
    const n = toChartNumber(value);
    if (n === null) continue;
    if (n < min) min = n;
    if (n > max) max = n;
  }
  return min <= max ? { min, max } : null;
}

export function tint(color: string, strength: number): string {
  const pct = Math.round(Math.min(1, Math.max(0, strength)) * MAX_TINT * 1000) / 10;
  return `color-mix(in oklch, ${color} ${pct}%, transparent)`;
}

// The bar's left edge and width as percents of the cell, drawn from zero so a
// negative value grows left of a positive one.
export function dataBarExtent(
  value: unknown,
  domain: FormatDomain | null,
): { left: number; width: number; negative: boolean } | null {
  const n = toChartNumber(value);
  if (n === null || !domain) return null;
  const lo = Math.min(0, domain.min);
  const hi = Math.max(0, domain.max);
  const span = hi - lo;
  if (span === 0) return null;
  const zero = ((0 - lo) / span) * 100;
  const width = (Math.abs(n) / span) * 100;
  return { left: n < 0 ? zero - width : zero, width, negative: n < 0 };
}

export function dataBarColor(negative: boolean): string {
  return tint(negative ? BAD_COLOR : SCALE_COLOR, 1);
}

// The cell's background for a colour scale, or undefined to leave it plain.
export function colorScaleBackground(
  value: unknown,
  format: Extract<CellFormat, { kind: "colorScale" }>,
  domain: FormatDomain | null,
): string | undefined {
  const n = toChartNumber(value);
  if (n === null || !domain || domain.max === domain.min) return undefined;
  if (format.scheme !== "diverging") {
    const t = (n - domain.min) / (domain.max - domain.min);
    return t <= 0 ? undefined : tint(SCALE_COLOR, MIN_TINT / MAX_TINT + t * (1 - MIN_TINT / MAX_TINT));
  }
  const mid = Number.isFinite(format.midpoint)
    ? (format.midpoint as number)
    : domain.min < 0 && domain.max > 0
      ? 0
      : (domain.min + domain.max) / 2;
  if (n === mid) return undefined;
  const above = n > mid;
  const reach = above ? domain.max - mid : mid - domain.min;
  if (reach <= 0) return undefined;
  const t = Math.min(1, Math.abs(n - mid) / reach);
  const good = above === ((format.goodDirection ?? "up") === "up");
  return tint(good ? GOOD_COLOR : BAD_COLOR, MIN_TINT / MAX_TINT + t * (1 - MIN_TINT / MAX_TINT));
}

function isRule(rule: unknown): rule is FormatRule {
  return typeof rule === "object" && rule !== null;
}

export function matchRule(
  value: unknown,
  rules: readonly FormatRule[],
): FormatRule | null {
  const n = toChartNumber(value);
  if (n === null) return null;
  for (const rule of rules) {
    if (!isRule(rule) || !CELL_TONES.includes(rule.tone)) continue;
    // The threshold is read like a cell, so "90" from JSON compares as 90.
    const threshold = toChartNumber(rule.value);
    if (threshold === null) continue;
    const hit =
      rule.when === ">"
        ? n > threshold
        : rule.when === ">="
          ? n >= threshold
          : rule.when === "<"
            ? n < threshold
            : rule.when === "<="
              ? n <= threshold
              : rule.when === "="
                ? n === threshold
                : false;
    if (hit) return rule;
  }
  return null;
}

export const TONE_LABEL: Record<CellTone, string> = {
  good: "good",
  warn: "warning",
  bad: "bad",
};

const FORMAT_KINDS: readonly string[] = ["dataBar", "colorScale", "rules"];

const MAX_ROWS_NAMED = 5;

function rowList(rows: number[]): string {
  const named = rows.slice(0, MAX_ROWS_NAMED).join(", ");
  return rows.length > MAX_ROWS_NAMED
    ? `${named} and ${rows.length - MAX_ROWS_NAMED} more`
    : named;
}

// Warnings only: a formatting problem leaves cells plain, it never stops the
// table drawing. Rows are named by their number in `data`, never by content.
export function checkTableFormat(
  columns: readonly { label: string; format: CellFormat }[],
  valuesOf: (index: number) => readonly unknown[],
): ChartIssues {
  const warnings: string[] = [];
  columns.forEach(({ label, format }, index) => {
    const values = valuesOf(index);
    if (!FORMAT_KINDS.includes(format.kind)) {
      warnings.push(`column "${label}" has an unknown format kind; left unformatted`);
      return;
    }
    if (format.kind === "rules" && !Array.isArray(format.rules)) {
      warnings.push(`column "${label}" has a rules format with no rules`);
      return;
    }
    if (format.kind === "rules") {
      if (format.rules.length === 0) {
        warnings.push(`column "${label}" has a rules format with no rules`);
      }
      format.rules.forEach((rule, i) => {
        if (!isRule(rule)) {
          warnings.push(`column "${label}" rule ${i + 1} is not a rule; it never matches`);
          return;
        }
        if (toChartNumber(rule.value) === null) {
          warnings.push(`column "${label}" rule ${i + 1} has no number to compare with; it never matches`);
        }
        if (!RULE_OPERATORS.includes(rule.when)) {
          warnings.push(`column "${label}" rule ${i + 1} has an unknown operator; it never matches`);
        }
        if (!CELL_TONES.includes(rule.tone)) {
          warnings.push(`column "${label}" rule ${i + 1} has an unknown tone; it never matches`);
        }
        if (rule.label !== undefined && typeof rule.label !== "string") {
          warnings.push(`column "${label}" rule ${i + 1} has a label that is not text; the tone's name is read instead`);
        }
      });
    }
    if (
      format.kind === "colorScale" &&
      format.scheme === "diverging" &&
      format.midpoint !== undefined &&
      !Number.isFinite(format.midpoint)
    ) {
      warnings.push(`column "${label}" has a midpoint that is not a number; the default is used`);
    }
    const text: number[] = [];
    let numbers = 0;
    values.forEach((value, row) => {
      if (value === null || value === undefined || value === "") return;
      if (toChartNumber(value) === null) text.push(row + 1);
      else numbers += 1;
    });
    if (text.length > 0) {
      warnings.push(
        `column "${label}" is formatted but row ${rowList(text)} ${text.length === 1 ? "is" : "are"} not a number; left unformatted`,
      );
    } else if (numbers === 0 && values.length > 0) {
      warnings.push(`column "${label}" is formatted but has no number to format`);
    }
  });
  return { errors: [], warnings };
}
