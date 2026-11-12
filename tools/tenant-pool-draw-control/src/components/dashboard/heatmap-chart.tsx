import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import {
  checkHeatmapData,
  heatmapColor,
  heatmapGrid,
  heatmapShade,
  heatmapTable,
  type HeatCell,
  type HeatmapGrid,
} from "@/lib/dashboard-charts";
import { formatMetric, type MetricFormat } from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// Up to this many columns a cell shows its value; past it, the tooltip and
// the data table do.
const MAX_LABELLED_COLUMNS = 12;

// A value per (x, y) pair as a grid of shaded cells: activity by weekday and
// hour, a cohort by month, a score by team and quarter. Columns and rows keep
// the order given in `xOrder` / `yOrder`, else the order first seen in
// `data`, never sorted; labels the data has but the order leaves out are drawn
// after the listed ones (warned). A pair with no row or no number is BLANK
// ("No data", dashed outline), never zero: send 0 for a real zero. Repeated
// pairs are added together (warned); a row with a blank x or y is left out.
// The shade scale runs from zero (or the minimum, when values go below zero)
// to the maximum. Under the grid: the data pivoted to one row per y and one
// column per x (`dataTable`). `onSelect` gets the clicked cell's x and y as
// drawn: trimmed strings, so `2024` arrives as "2024". More than
// MAX_HEATMAP_CELLS columns × rows is an error.
export function HeatmapChart({
  data,
  xOrder,
  yOrder,
  format = "number",
  currency,
  height,
  onSelect,
  ariaLabel,
  dataTable = true,
  rowLabel,
  valueLabel = "Value",
}: {
  data: HeatCell[];
  xOrder?: (string | number)[];
  yOrder?: (string | number)[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (x: string, y: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
  rowLabel?: string;
  valueLabel?: string;
}) {
  const issues = checkHeatmapData(data, format, xOrder, yOrder);
  const ok = issues.errors.length === 0;
  const grid: HeatmapGrid =
    ok && data.length > 0
      ? heatmapGrid(data, xOrder, yOrder)
      : { xs: [], ys: [], values: [], min: 0, max: 0 };
  const drawn = grid.values.some((row) => row.some((v) => v !== null && v !== 0));
  const table = ok && drawn ? heatmapTable(grid, format, currency, rowLabel) : null;
  useReportChartIssues("HeatmapChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!drawn) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const { xs, ys, values, min, max } = grid;
  const fmt = (v: number) => formatMetric(v, format, currency);
  const blanks = values.flat().filter((v) => v === null).length;
  const topRow = values.findIndex((row) => row.includes(max));
  const top = { y: topRow, x: values[topRow].indexOf(max) };
  const summary =
    ariaLabel ??
    `Heatmap of ${ys.length} rows by ${xs.length} columns, ${fmt(Math.min(0, min))} to ${fmt(max)}; highest at ${ys[top.y]}, ${xs[top.x]} (${fmt(max)})${blanks > 0 ? `; ${blanks} ${blanks === 1 ? "cell has" : "cells have"} no data` : ""}`;
  const showValues = xs.length <= MAX_LABELLED_COLUMNS;

  return (
    <div>
      <div
        role={onSelect ? "group" : "img"}
        aria-label={summary}
        className="grid w-full gap-0.5 text-xs"
        style={{
          gridTemplateColumns: `max-content repeat(${xs.length}, minmax(0, 1fr))`,
          gridTemplateRows: height
            ? `repeat(${ys.length}, minmax(0, 1fr)) auto`
            : `repeat(${ys.length}, minmax(1.75rem, auto)) auto`,
          height,
        }}
      >
        {ys.map((y, yi) => [
          <div
            key={`y-${yi}`}
            className="max-w-[10rem] self-center truncate pr-2 text-right text-muted-foreground"
            title={y}
          >
            {y}
          </div>,
          ...xs.map((x, xi) => {
            const v = values[yi][xi];
            const shade = v === null ? null : heatmapShade(v, min, max);
            const text = v === null ? "No data" : fmt(v);
            const Tag = onSelect ? "button" : "div";
            return (
              <Tag
                key={`c-${yi}-${xi}`}
                type={onSelect ? "button" : undefined}
                aria-label={onSelect ? `${text}: ${y}, ${x}` : undefined}
                onClick={onSelect ? () => onSelect(x, y) : undefined}
                data-heat-cell=""
                data-x={x}
                data-y={y}
                className={cn(
                  "group relative flex min-w-0 items-center justify-center rounded-sm font-mono tabular-nums",
                  shade === null
                    ? "border border-dashed border-border text-muted-foreground"
                    : "text-foreground",
                  onSelect &&
                    "cursor-pointer hover:ring-2 hover:ring-ring/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                )}
                style={shade === null ? undefined : { backgroundColor: heatmapColor(shade) }}
              >
                {showValues && v !== null && (
                  // A backing in the page's background colour keeps the
                  // theme's text contrast over every shade, as TreemapChart does;
                  // the title keeps a clipped value readable, as the axis labels do.
                  <span
                    data-heat-value=""
                    className="truncate rounded-sm bg-background px-1 text-foreground"
                    title={fmt(v)}
                  >
                    {fmt(v)}
                  </span>
                )}
                <span
                  aria-hidden="true"
                  className={cn(
                    "pointer-events-none absolute z-10 hidden whitespace-nowrap rounded-lg border border-border/50 bg-background px-2.5 py-1.5 font-sans text-xs text-foreground shadow-xl group-hover:block group-focus-visible:block",
                    yi === 0 ? "top-full mt-1" : "bottom-full mb-1",
                    xi < xs.length / 2 ? "left-0" : "right-0",
                  )}
                >
                  <span className="text-muted-foreground">
                    {y} · {x}
                  </span>{" "}
                  <span className="font-mono font-medium tabular-nums">
                    {valueLabel}: {text}
                  </span>
                </span>
              </Tag>
            );
          }),
        ])}
        <div />
        {xs.map((x, xi) => (
          <div
            key={`x-${xi}`}
            className="min-w-0 truncate pt-1 text-center text-muted-foreground"
            title={x}
          >
            {x}
          </div>
        ))}
      </div>
      <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground" aria-hidden="true">
        <span className="tabular-nums">{fmt(Math.min(0, min))}</span>
        <span
          className="h-2 w-32 rounded-full"
          style={{ backgroundImage: `linear-gradient(to right, ${heatmapColor(0)}, ${heatmapColor(1)})` }}
        />
        <span className="tabular-nums">{fmt(max)}</span>
        {blanks > 0 && (
          <span className="ml-3 flex items-center gap-1">
            <span className="size-3 rounded-sm border border-dashed border-border" />
            No data
          </span>
        )}
      </div>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
