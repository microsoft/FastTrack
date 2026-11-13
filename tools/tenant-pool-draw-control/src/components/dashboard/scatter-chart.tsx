import {
  CartesianGrid,
  Scatter,
  ScatterChart as RechartsScatterChart,
  XAxis,
  YAxis,
  ZAxis,
} from "recharts";

import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { allWholeNumbers, seriesColor } from "@/components/dashboard/chart-utils";
import { ChartContainer, ChartTooltip } from "@/components/ui/chart";
import {
  checkPointData,
  pointTable,
  toChartNumber,
  valueAt,
} from "@/lib/dashboard-charts";
import {
  formatAxisValue,
  formatMetric,
  type MetricFormat,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

type Axis = { key: string; label: string; format?: MetricFormat };

// One point per row, `x` against `y`, to show whether two measures move
// together (deal size against days to close, spend against conversions).
// `size` makes it a bubble chart: a third measure as the point's area, in
// proportion from zero. A row with no size, a zero or a negative one is left
// out with a warning; sizes that are all zero show the empty state, and no
// positive size otherwise is an error.
// `labelKey` names each point in its tooltip and the data table. Rows missing
// x or y are left out with a warning. Under the plot: every point as a table
// (`dataTable`).
// `onSelect` gets the clicked point's label (needs `labelKey`).
export function ScatterChart({
  data,
  x,
  y,
  size,
  labelKey,
  currency,
  height = 300,
  onSelect,
  ariaLabel,
  dataTable = true,
}: {
  data: Record<string, unknown>[];
  x: Axis;
  y: Axis;
  size?: Axis;
  labelKey?: string;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const keys = { x: x.key, y: y.key, size: size?.key };
  const formats = { x: x.format, y: y.format, size: size?.format };
  const issues = checkPointData(data, keys, formats);
  const ok = issues.errors.length === 0;
  const labels = { x: x.label, y: y.label, size: size?.label, label: "Point" };
  // Recharts reads a key as a path; the points are copied flat so a numeric
  // string draws as the number the check accepted.
  const points = data
    .map((row) => ({
      x: toChartNumber(valueAt(row, x.key)),
      y: toChartNumber(valueAt(row, y.key)),
      size: size ? toChartNumber(valueAt(row, size.key)) : 1,
      label: labelKey ? String(valueAt(row, labelKey) ?? "") : "",
    }))
    .filter((p) => p.x !== null && p.y !== null && p.size !== null && p.size > 0);
  const table =
    ok && points.length > 0
      ? pointTable(data, { ...keys, label: labelKey }, labels, formats, currency)
      : null;
  useReportChartIssues("ScatterChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (points.length === 0) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  // The area runs from zero, so a bubble twice the size has twice the area.
  const largest = Math.max(0, ...points.map((p) => p.size ?? 0));
  const summary =
    ariaLabel ??
    `${size ? "Bubble" : "Scatter"} chart of ${y.label} against ${x.label}${size ? ` sized by ${size.label}` : ""}, ${points.length} points`;
  const line = (label: string, value: unknown, format?: MetricFormat) => (
    <div key={label} className="flex w-full items-center justify-between gap-4">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-mono font-medium text-foreground tabular-nums">
        {formatMetric(toChartNumber(value), format ?? "number", currency)}
      </span>
    </div>
  );

  return (
    <div>
      <ChartContainer
        config={{ points: { label: y.label, color: seriesColor(0) } }}
        className={cn(
          "aspect-auto w-full",
          onSelect && labelKey && "[&_.recharts-scatter-symbol]:cursor-pointer",
        )}
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <RechartsScatterChart margin={{ top: 8, right: 16, left: 0, bottom: 0 }}>
          <CartesianGrid />
          <XAxis
            type="number"
            dataKey="x"
            name={x.label}
            tickLine={false}
            axisLine={false}
            tickMargin={8}
            domain={["auto", "auto"]}
            allowDecimals={!allWholeNumbers(points.map((p) => p.x))}
            tickFormatter={(v: number) => formatAxisValue(v, x.format ?? "number", currency)}
          />
          <YAxis
            type="number"
            dataKey="y"
            name={y.label}
            tickLine={false}
            axisLine={false}
            tickMargin={4}
            width={56}
            domain={["auto", "auto"]}
            allowDecimals={!allWholeNumbers(points.map((p) => p.y))}
            tickFormatter={(v: number) => formatAxisValue(v, y.format ?? "number", currency)}
          />
          <ZAxis
            type="number"
            dataKey="size"
            domain={size ? [0, largest > 0 ? largest : 1] : undefined}
            range={size ? [0, 600] : [48, 48]}
          />
          <ChartTooltip
            cursor={{ strokeDasharray: "3 3" }}
            content={({ active, payload }) => {
              const point = payload?.[0]?.payload as (typeof points)[number] | undefined;
              if (!active || !point) return null;
              return (
                <div className="grid min-w-[8rem] gap-1 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  {point.label && <div className="font-medium">{point.label}</div>}
                  {line(x.label, point.x, x.format)}
                  {line(y.label, point.y, y.format)}
                  {size && line(size.label, point.size, size.format)}
                </div>
              );
            }}
          />
          <Scatter
            data={points}
            fill="var(--color-points)"
            fillOpacity={size ? 0.6 : 0.8}
            isAnimationActive={false}
            onClick={
              onSelect && labelKey
                ? (_: unknown, index: number) => {
                    const point = points[index];
                    if (point?.label) onSelect(point.label);
                  }
                : undefined
            }
          />
        </RechartsScatterChart>
      </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
