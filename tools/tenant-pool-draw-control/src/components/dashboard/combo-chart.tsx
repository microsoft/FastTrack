import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Line,
  XAxis,
  YAxis,
} from "recharts";

import {
  ChartDataTable,
  ChartProblem,
  TimeZoneNote,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { allWholeNumbers, seriesColor } from "@/components/dashboard/chart-utils";
import type { ChartSeries } from "@/components/dashboard/trend-chart";
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import {
  checkComboData,
  comboLines,
  comboTable,
  formatXValue,
  formatXValueWithZone,
  hasNumbers,
  seriesInData,
  tableTimeFormat,
  valueAt,
  xSpanText,
  xTickPattern,
  xTimeZoneLabel,
} from "@/lib/dashboard-charts";
import {
  formatAxisValue,
  formatMetric,
  type MetricFormat,
} from "@/lib/dashboard-data";
import type { DashboardTimeZone, TemporalKind } from "@/lib/dashboard-time-zone";

// Columns and lines over one time axis: a volume as bars (orders, revenue)
// with a rate or a second measure as lines (conversion, margin, a target).
// The lines share the bars' axis while `lineFormat` is the bars' `format`;
// a different `lineFormat` (revenue in currency, margin in percent) draws
// them against a second axis on the right, the one case two axes are honest:
// two units, each axis labelled in its own. Bars stack when `stacked` (parts
// of one whole); lines never do. A line on a key a bar already draws is left
// out with a warning: one column has one format; with no line left the chart
// is an error, as with no lines at all. Same checks and View data table as
// TrendChart.
export function ComboChart({
  data,
  xKey,
  bars: authoredBars,
  lines: authoredLines,
  format = "number",
  lineFormat = format,
  currency,
  stacked = false,
  height = 280,
  xFormat = "MMM d",
  dayBins = false,
  timeZone,
  temporalKind,
  ariaLabel,
  dataTable = true,
}: {
  data: Record<string, unknown>[];
  xKey: string;
  bars: ChartSeries[];
  lines: ChartSeries[];
  format?: MetricFormat;
  /** The lines' format; when it differs from `format`, the lines get their own axis on the right. */
  lineFormat?: MetricFormat;
  currency?: string;
  stacked?: boolean;
  height?: number;
  /** date-fns pattern for date-like x ticks, tooltip and summary. */
  xFormat?: string;
  /** The x column holds raw calendar bins; see TrendChart. */
  dayBins?: boolean;
  timeZone?: DashboardTimeZone;
  /** Declare numeric epochs/Excel serials as temporal; omit for numeric category/hour labels. */
  temporalKind?: TemporalKind;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const issues = checkComboData(
    data,
    xKey,
    authoredBars,
    authoredLines,
    format,
    lineFormat,
    dayBins,
    temporalKind,
  );
  // Colours follow the place in bars-then-lines, so a line never takes a bar's.
  // A list with nothing to draw is left out while the other list draws.
  const drawn = (list: ChartSeries[]) => list.some((s) => hasNumbers(data, s.key));
  // A line on a key the bars already draw is left out (the check warns).
  const ownLines = comboLines(
    authoredBars,
    authoredLines.map((s, i) => ({
      ...s,
      color: s.color ?? seriesColor(authoredBars.length + i),
    })),
  );
  const barsDrawn = drawn(authoredBars);
  const linesDrawn = drawn(ownLines);
  const bars =
    barsDrawn || !linesDrawn
      ? seriesInData(
          data,
          authoredBars.map((s, i) => ({ ...s, color: s.color ?? seriesColor(i) })),
        )
      : [];
  const lines =
    linesDrawn || !barsDrawn
      ? seriesInData(data, ownLines)
      : [];
  const ok = issues.errors.length === 0;
  const tableXFormat = tableTimeFormat(xFormat);
  const table = ok
    ? comboTable(data, xKey, bars, lines, format, lineFormat, currency, tableXFormat, dayBins, timeZone, temporalKind)
    : null;
  useReportChartIssues("ComboChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;

  const twoAxes = lineFormat !== format && bars.length > 0 && lines.length > 0;
  const leftFormat = bars.length > 0 ? format : lineFormat;
  const stackBars = stacked && bars.length > 1;
  const config: ChartConfig = Object.fromEntries(
    [...bars, ...lines].map((s) => [s.key, { label: s.label, color: s.color }]),
  );
  const labelPattern = xFormat === "MMM d" ? "MMM d, yyyy" : xFormat;
  const tickPattern = xTickPattern(
    data.map((row) => valueAt(row, xKey)),
    xFormat,
    dayBins,
    timeZone,
    temporalKind,
  );
  const zonePatterns = [tickPattern, labelPattern];
  const zone = xTimeZoneLabel(
    data.map((row) => valueAt(row, xKey)),
    zonePatterns,
    dayBins,
    timeZone,
    temporalKind,
  );
  const formatOf = new Map<string, MetricFormat>([
    ...bars.map((s) => [s.key, format] as const),
    ...lines.map((s) => [s.key, lineFormat] as const),
  ]);
  const summary =
    ariaLabel ??
    (bars.length > 0
      ? `${stackBars ? "Stacked bar" : "Bar"} chart of ${bars.map((s) => s.label).join(", ")}`
      : "Chart") +
      (lines.length > 0
        ? ` with ${lines.map((s) => s.label).join(", ")} as ${lines.length > 1 ? "lines" : "a line"}${twoAxes ? " on a second axis" : ""}`
        : "") +
      `, over ${data.length} periods` +
    (data.length > 0
      ? `, ${xSpanText(valueAt(data[0], xKey), valueAt(data[data.length - 1], xKey), labelPattern, zonePatterns, dayBins, timeZone, temporalKind)}`
      : "");
  const values = (series: ChartSeries[]) =>
    data.flatMap((row) => series.map((s) => valueAt(row, s.key)));
  const axisProps = {
    tickLine: false,
    axisLine: false,
    tickMargin: 4,
    width: 56,
  } as const;

  return (
    <div>
      <ChartContainer
        config={config}
        className="aspect-auto w-full"
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <ComposedChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
          <CartesianGrid vertical={false} />
          <XAxis
            dataKey={xKey}
            tickLine={false}
            axisLine={false}
            tickMargin={8}
            minTickGap={24}
            tickFormatter={(v: unknown) => formatXValue(v, tickPattern, dayBins, timeZone, temporalKind)}
          />
          <YAxis
            yAxisId="left"
            {...axisProps}
            allowDecimals={!allWholeNumbers(twoAxes ? values(bars) : values([...bars, ...lines]))}
            tickFormatter={(v: number) => formatAxisValue(v, leftFormat, currency)}
          />
          {twoAxes && (
            <YAxis
              yAxisId="right"
              orientation="right"
              {...axisProps}
              allowDecimals={!allWholeNumbers(values(lines))}
              tickFormatter={(v: number) => formatAxisValue(v, lineFormat, currency)}
            />
          )}
          <ChartTooltip
            content={
              <ChartTooltipContent
                labelFormatter={(_, payload) =>
                  timeZone === undefined || zone?.includes(", then ")
                    ? formatXValueWithZone(valueAt(payload?.[0]?.payload, xKey), labelPattern, zonePatterns, dayBins, timeZone, temporalKind)
                    : formatXValue(valueAt(payload?.[0]?.payload, xKey), labelPattern, dayBins, timeZone, temporalKind)
                }
                formatter={(value, name, item) => (
                  <div className="flex w-full items-center justify-between gap-4">
                    <span className="flex items-center gap-1.5 text-muted-foreground">
                      <span
                        className="size-2.5 shrink-0 rounded-[2px]"
                        style={{ backgroundColor: item.color }}
                      />
                      {String(name)}
                    </span>
                    <span className="font-mono font-medium text-foreground tabular-nums">
                      {formatMetric(
                        Number(value),
                        formatOf.get(String(item.dataKey)) ?? format,
                        currency,
                      )}
                    </span>
                  </div>
                )}
              />
            }
          />
          <ChartLegend content={<ChartLegendContent />} />
          {bars.map((s, i) => (
            <Bar
              key={s.key}
              yAxisId="left"
              dataKey={s.key}
              name={s.label}
              stackId={stackBars ? "stack" : undefined}
              fill={s.color}
              radius={!stackBars || i === bars.length - 1 ? [3, 3, 0, 0] : 0}
              isAnimationActive={false}
            />
          ))}
          {lines.map((s) => (
            <Line
              key={s.key}
              yAxisId={twoAxes ? "right" : "left"}
              dataKey={s.key}
              name={s.label}
              type="monotone"
              stroke={s.color}
              strokeWidth={2}
              dot={false}
              isAnimationActive={false}
            />
          ))}
        </ComposedChart>
      </ChartContainer>
      {timeZone === undefined && zone && <TimeZoneNote zone={zone} />}
      {timeZone !== undefined && zone && <span hidden data-chart-export-zone={zone} />}
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
