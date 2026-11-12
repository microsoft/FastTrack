import { ChevronRight } from "lucide-react";
import { Fragment, useEffect, useState } from "react";

import { BarBreakdown } from "@/components/dashboard/bar-breakdown";
import { useReportChartIssues } from "@/components/dashboard/chart-hooks";
import { NativeSelect, NativeSelectOption } from "@/components/ui/native-select";
import { hasKey } from "@/lib/dashboard-charts";
import { formatMetric, type MetricFormat } from "@/lib/dashboard-data";
import { drillLevel, misnamedLevels, type DrillLevel } from "@/lib/dashboard-drill";
import type { DashboardTimeZone, TemporalKind } from "@/lib/dashboard-time-zone";

const levelId = (level: DrillLevel | undefined) => `${level?.key}/${level?.time ?? ""}`;

// A bar breakdown you can click into: Region > Country > City, or
// Year > Month > Day for a date field (`time`). Every level is rolled up on the
// client from `rows` already loaded at the finest grain, so drilling issues no
// query; `value` is summed (omit it to count rows), so use an additive measure
// only. The breadcrumb above the bars drills back up. A "Drill into…" select
// under the bars is the keyboard path down, and lists every category; a level
// with one bucket shows a button instead. On a category level, categories past
// `topN` fold into an "Other" bar that cannot be clicked, but the select still
// reaches them; a date level draws every bucket in order and ignores `topN`.
// Pass `dayBins` when the date field holds day bins (`bin(…, 1d)`), as on
// TrendChart; without it an instant is booked on its day in `timeZone`, the
// dashboard's Local/UTC mode (local by default). Pass `temporalKind="date"`
// when the field holds date-only Dates (an Excel date via `toDateValue`, a
// UTC-midnight DateOnly), as on TrendChart; a Date is otherwise an instant.
export function DrillBreakdown({
  rows,
  levels,
  value,
  format = "number",
  currency,
  topN = 8,
  orientation = "horizontal",
  height,
  dayBins = false,
  timeZone = "local",
  temporalKind,
}: {
  rows: Record<string, unknown>[];
  levels: DrillLevel[];
  value?: string;
  format?: MetricFormat;
  currency?: string;
  topN?: number;
  orientation?: "horizontal" | "vertical";
  height?: number;
  dayBins?: boolean;
  timeZone?: DashboardTimeZone;
  temporalKind?: TemporalKind;
}) {
  const [picked, setPath] = useState<{ level: string; label: string }[]>([]);
  // Keep only the picks that still name a bar on the same level once `rows` or
  // `levels` change, and forget the rest so they cannot return with the rows.
  const path: string[] = [];
  for (const pick of picked.slice(0, Math.max(0, levels.length - 1))) {
    if (pick.level !== levelId(levels[path.length])) break;
    if (!drillLevel(rows, levels, path, value, dayBins, timeZone, temporalKind).data.some((d) => d.label === pick.label)) break;
    path.push(pick.label);
  }
  useEffect(() => {
    if (picked.length > path.length) setPath(picked.slice(0, path.length));
  });
  const depth = path.length;
  const view = drillLevel(rows, levels, path, value, dayBins, timeZone, temporalKind);
  const canDrill = depth < levels.length - 1;
  const total = view.data.reduce((sum, d) => sum + d.value, 0);
  const drillInto = (label: string) =>
    setPath([...picked.slice(0, depth), { level: levelId(levels[depth]), label }]);
  // BarBreakdown draws a lone category as a sentence with no bar to click.
  const lone = canDrill && view.data.length === 1 ? view.data[0].label : null;
  // A misnamed `value` or date field, or object category cells, skip every
  // row; say so instead of "no rows".
  const level = levels[depth];
  const suspects = [
    value && `"${value}" is a number field`,
    level &&
      (level.time ? `"${level.key}" is a date field` : `"${level.key}" holds text or numbers, not objects`),
  ].filter(Boolean);
  const unusable =
    view.data.length === 0 && view.skipped > 0
      ? `all ${view.skipped} rows at this level were skipped: check that ${suspects.join(" and ")} on the rows`
      : null;
  const usable = [value && "value", level && (level.time ? "date" : "category")].filter(Boolean).join(" or ");
  const leftOut =
    view.data.length > 0 && view.skipped > 0
      ? `${view.skipped} rows at this level have no usable ${usable} and are left out`
      : null;
  // A drilled-into bucket may hold no dates, so it only warns. A level whose
  // values give no row a bucket fails the deploy before anyone drills, as does
  // a top-level key no row carries (a typo: one "(Blank)" bar). Below the top,
  // an absent key only warns: a source may omit a nullable field's nulls.
  const misnamed = misnamedLevels(rows, levels, dayBins, timeZone, temporalKind).map((l) => {
    const absent = !hasKey(rows, l.key);
    const text = absent
      ? `no row has a "${l.key}" field (${l.label} level): check that "${l.key}" names a field on the rows`
      : l.time
        ? `no row has a usable date in "${l.key}" (${l.label} level): check that "${l.key}" names the date field on the rows`
        : `no row has a usable category in "${l.key}" (${l.label} level): check that "${l.key}" holds text or numbers, not objects`;
    return { text, warn: absent && l !== levels[0] };
  });
  useReportChartIssues("DrillBreakdown", {
    errors: [
      ...(levels.length === 0 ? ["levels is empty: pass at least one DrillLevel"] : []),
      ...(unusable && depth === 0 ? [unusable] : []),
      ...misnamed.filter((m) => !m.warn).map((m) => m.text),
    ],
    warnings: [
      ...(unusable && depth > 0 ? [unusable] : []),
      ...(leftOut ? [leftOut] : []),
      ...misnamed.filter((m) => m.warn).map((m) => m.text),
    ],
  });

  return (
    <div className="space-y-2">
      <nav aria-label="Drill path" className="flex flex-wrap items-center gap-1 text-sm">
        {[{ label: "All", up: 0 }, ...path.slice(0, depth).map((label, i) => ({ label, up: i + 1 }))].map(
          (crumb, i) => (
            <Fragment key={`${crumb.label}-${i}`}>
              {i > 0 && <ChevronRight className="size-3 text-muted-foreground" aria-hidden />}
              {i < depth ? (
                <button
                  type="button"
                  className="text-primary underline-offset-2 hover:underline"
                  onClick={() => setPath(picked.slice(0, crumb.up))}
                >
                  {crumb.label}
                </button>
              ) : (
                <span className="font-medium" aria-current="location">
                  {crumb.label}
                </span>
              )}
            </Fragment>
          ),
        )}
        <span className="text-muted-foreground">
          · by {levels[depth]?.label ?? ""}
          {view.data.length > 0 && ` · ${formatMetric(total, format, currency)}`}
          {leftOut && ` · ${view.skipped} rows left out`}
          {canDrill && view.data.length > 1 && " · click a bar to drill down"}
        </span>
      </nav>
      {view.data.length === 0 ? (
        <p className="py-6 text-sm text-muted-foreground">
          {unusable ? `No data: ${unusable}.` : "No rows at this level."}
        </p>
      ) : (
        <>
          <BarBreakdown
            data={view.data}
            orientation={orientation}
            topN={topN}
            format={format}
            currency={currency}
            height={height}
            ordered={view.ordered}
            foldOther
            additive
            categoryLabel={levels[depth]?.label}
            onSelect={canDrill ? drillInto : undefined}
          />
          {canDrill && view.data.length > 1 && (
            <NativeSelect
              size="sm"
              aria-label={`Drill into a ${levels[depth]?.label ?? "category"}`}
              value=""
              onChange={(event) => event.target.value && drillInto(event.target.value)}
            >
              <NativeSelectOption value="">Drill into…</NativeSelectOption>
              {view.data.map((d) => (
                <NativeSelectOption key={d.label} value={d.label}>
                  {d.label}
                </NativeSelectOption>
              ))}
            </NativeSelect>
          )}
          {lone !== null && (
            <button
              type="button"
              className="text-sm text-primary underline-offset-2 hover:underline"
              onClick={() => drillInto(lone)}
            >
              Drill into {lone} by {levels[depth + 1]?.label}
            </button>
          )}
        </>
      )}
    </div>
  );
}
