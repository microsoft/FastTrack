import { ChartArea, ChartColumn, ChartLine } from "lucide-react";
import { useState } from "react";
import { createPortal } from "react-dom";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  XAxis,
  YAxis,
} from "recharts";

import {
  ChartDataTable,
  ChartProblem,
  TILE_CONTROL_REVEAL,
  TimeZoneNote,
} from "@/components/dashboard/chart-extras";
import {
  useChartHeaderSlot,
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { Button } from "@/components/ui/button";
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { allWholeNumbers, seriesColor, severityPalette } from "@/components/dashboard/chart-utils";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  checkTrendData,
  formatXValue,
  formatXValueWithZone,
  seriesInData,
  tableTimeFormat,
  trendTable,
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
import { cn } from "@/lib/utils";
import type { DashboardTimeZone, TemporalKind } from "@/lib/dashboard-time-zone";

export type ChartSeries = { key: string; label: string; color?: string };

type TrendVariant = "line" | "area" | "bar";

const VARIANTS: { value: TrendVariant; label: string; icon: typeof ChartLine }[] = [
  { value: "line", label: "Line", icon: ChartLine },
  { value: "area", label: "Area", icon: ChartArea },
  { value: "bar", label: "Bars", icon: ChartColumn },
];

// One icon button showing the chart type drawn; it opens a menu to switch.
function ChartTypeMenu({
  value,
  onChange,
}: {
  value: TrendVariant;
  onChange: (value: TrendVariant) => void;
}) {
  const current = VARIANTS.find((v) => v.value === value) ?? VARIANTS[0];
  const Icon = current.icon;
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon-sm"
          aria-label="Chart type"
          title={`Chart type: ${current.label}`}
          data-pdf-exclude=""
          className={TILE_CONTROL_REVEAL}
        >
          <Icon aria-hidden="true" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>Chart type</DropdownMenuLabel>
        <DropdownMenuRadioGroup
          value={value}
          onValueChange={(next) => onChange(next as TrendVariant)}
        >
          {VARIANTS.map(({ value: option, label, icon: OptionIcon }) => (
            <DropdownMenuRadioItem key={option} value={option}>
              <OptionIcon aria-hidden="true" />
              {label}
            </DropdownMenuRadioItem>
          ))}
        </DropdownMenuRadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

// Time series as lines (default), filled areas, or stacked bars (counts per
// period split by a category), in theme chart colours.
// `stacked` says the series are parts of one whole (counts per category that
// add up to the period's total): bars and areas then stack. It defaults to
// true for `variant="bar"` and false otherwise; set it for a stacked area, and
// set `stacked={false}` for side-by-side bars. Lines never stack.
// Pair with bucketByTime() for evenly spaced days, weeks or months, or with
// fillTimeGaps() for minute and hour bins, so an empty period draws as 0.
// The reader can switch line / area / bars (one menu button, in the ChartCard
// header left of its "⋮" menu, or above the plot outside a card or when an earlier
// chart in the same card holds the header) and show or hide each series
// (`controls`), and can open the numbers as a table (`dataTable`).
// The data is checked before drawing: a key missing from the rows or text
// where numbers belong replaces the chart with the problem.
export function TrendChart({
  data,
  xKey,
  series: authored,
  variant = "line",
  stacked: parts = variant === "bar",
  format = "number",
  currency,
  height = 260,
  xFormat = "MMM d",
  dayBins = false,
  timeZone,
  temporalKind,
  ariaLabel,
  controls = true,
  dataTable = true,
}: {
  data: Record<string, unknown>[];
  xKey: string;
  series: ChartSeries[];
  variant?: TrendVariant;
  /** The series add up to a whole, so bars and areas stack. Defaults to `variant === "bar"`. */
  stacked?: boolean;
  format?: MetricFormat;
  currency?: string;
  height?: number;
  /** date-fns pattern for date-like x ticks, tooltip and summary, e.g. "MMM yyyy" for months or "MMM d, HH:mm" for hours. */
  xFormat?: string;
  /** The x column holds raw calendar bins (`bin(…, 1d)`, `bin(…, 7d)`, `startofday`/`startofweek`/`startofmonth`): show a UTC-midnight value as its calendar day. Not needed for bucketByTime output. */
  dayBins?: boolean;
  timeZone?: DashboardTimeZone;
  /** Declare numeric epochs/Excel serials as temporal; omit for numeric category/hour labels. */
  temporalKind?: TemporalKind;
  ariaLabel?: string;
  controls?: boolean;
  dataTable?: boolean;
}) {
  const [chosenVariant, setChosenVariant] = useState<TrendVariant | null>(null);
  const [hidden, setHidden] = useState<ReadonlySet<string>>(() => new Set());

  const issues = checkTrendData(data, xKey, authored, format, dayBins, false, temporalKind);
  // A series with no number to draw is left out of the plot, toggles, summary
  // and table; each keeps the colour of its place in the authored list, or of
  // its log level when every series is one (Error red, Warn amber).
  const levels = severityPalette(authored.map((s) => s.label));
  const series = seriesInData(
    data,
    authored.map((s, i) => ({ ...s, color: s.color ?? levels?.(s.label) ?? seriesColor(i) })),
  );
  const tableXFormat = tableTimeFormat(xFormat);
  const table =
    issues.errors.length === 0
      ? trendTable(data, xKey, series, format, currency, tableXFormat, dayBins, timeZone, temporalKind)
      : null;
  useReportChartIssues("TrendChart", issues);
  useChartTable(table);
  const headerSlot = useChartHeaderSlot(controls && issues.errors.length === 0);
  if (issues.errors.length > 0) return <ChartProblem issues={issues} />;

  const shown = controls ? (chosenVariant ?? variant) : variant;
  // Bars and areas stack only when the author said the series are parts of a
  // whole; a line chart the reader switched to bars compares side by side.
  const stacked = parts && (shown === "bar" || shown === "area") && series.length > 1;
  const colors = series.map((s) => s.color);
  // Hidden keys no longer in `series` are ignored, and if every current
  // series is hidden (the series prop changed) all are drawn again.
  const hiddenNow = series.filter((s) => hidden.has(s.key)).length;
  const isHidden = (key: string) =>
    controls && hiddenNow < series.length && hidden.has(key);
  const visible = series
    .map((s, i) => ({ ...s, color: colors[i] }))
    .filter((s) => !isHidden(s.key));
  const config: ChartConfig = Object.fromEntries(
    series.map((s, i) => [s.key, { label: s.label, color: colors[i] }]),
  );
  // The default tick pattern drops the year (xTickPattern adds it back when the
  // data spans years); the tooltip and summary keep it.
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
  const summary =
    ariaLabel ??
    `${shown === "area" ? (stacked ? "Stacked area" : "Area") : shown === "bar" ? (stacked ? "Stacked bar" : "Bar") : "Line"} chart of ${visible.map((s) => s.label).join(", ")} over ${data.length} periods` +
      (data.length > 0
        ? `, ${xSpanText(valueAt(data[0], xKey), valueAt(data[data.length - 1], xKey), labelPattern, zonePatterns, dayBins, timeZone, temporalKind)}`
        : "");
  const toggleSeries = (key: string) =>
    setHidden((current) => {
      const live = series.filter((s) => current.has(s.key)).map((s) => s.key);
      // Every series hidden is drawn as none hidden; toggle from that.
      const next = new Set(live.length < series.length ? live : []);
      if (next.has(key)) next.delete(key);
      // At least one series stays drawn.
      else if (series.length - next.size > 1) next.add(key);
      return next;
    });
  const seriesToggles = controls && series.length > 1;
  const typeMenu = controls && (
    <ChartTypeMenu value={shown} onChange={setChosenVariant} />
  );

  const axes = [
    <CartesianGrid key="grid" vertical={false} />,
    <XAxis
      key="x"
      dataKey={xKey}
      tickLine={false}
      axisLine={false}
      tickMargin={8}
      minTickGap={24}
      tickFormatter={(v: unknown) => formatXValue(v, tickPattern, dayBins, timeZone, temporalKind)}
    />,
    <YAxis
      key="y"
      tickLine={false}
      axisLine={false}
      tickMargin={4}
      width={56}
      allowDecimals={!allWholeNumbers(data.flatMap((row) => series.map((s) => valueAt(row, s.key))))}
      tickFormatter={(v: number) => formatAxisValue(v, format, currency)}
    />,
    <ChartTooltip
      key="tooltip"
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
                {formatMetric(Number(value), format, currency)}
              </span>
            </div>
          )}
        />
      }
    />,
    ...(series.length > 1 && !seriesToggles
      ? [<ChartLegend key="legend" content={<ChartLegendContent />} />]
      : []),
  ];

  return (
    // `group/tile` reveals the chart-type button on hover when it sits above
    // the plot instead of in a card header.
    <div className="group/tile">
      {typeMenu && headerSlot && createPortal(typeMenu, headerSlot)}
      {controls && (seriesToggles || !headerSlot) && (
        <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
          <div
            role={seriesToggles ? "group" : undefined}
            aria-label={seriesToggles ? "Series shown" : undefined}
            className="flex flex-wrap items-center gap-1"
          >
            {seriesToggles &&
              series.map((s, i) => {
                const on = !isHidden(s.key);
                return (
                  <button
                    key={s.key}
                    type="button"
                    aria-pressed={on}
                    onClick={() => toggleSeries(s.key)}
                    className={cn(
                      "inline-flex items-center gap-1.5 rounded-md px-1.5 py-0.5 text-xs hover:bg-muted focus-visible:outline-2 focus-visible:outline-ring",
                      !on && "text-muted-foreground line-through opacity-60",
                    )}
                  >
                    <span
                      aria-hidden="true"
                      className="size-2.5 shrink-0 rounded-[2px]"
                      style={{ backgroundColor: colors[i] }}
                    />
                    {s.label}
                  </button>
                );
              })}
          </div>
          {!headerSlot && typeMenu}
        </div>
      )}
      <ChartContainer
        config={config}
        className="aspect-auto w-full"
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        {shown === "bar" ? (
          <BarChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            {axes}
            {visible.map((s, i) => (
              <Bar
                key={s.key}
                dataKey={s.key}
                name={s.label}
                stackId={stacked ? "stack" : undefined}
                fill={s.color}
                radius={!stacked || i === visible.length - 1 ? [3, 3, 0, 0] : 0}
                isAnimationActive={false}
              />
            ))}
          </BarChart>
        ) : shown === "area" ? (
          <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            {axes}
            {visible.map((s) => (
              <Area
                key={s.key}
                dataKey={s.key}
                name={s.label}
                type="monotone"
                stackId={stacked ? "stack" : undefined}
                stroke={s.color}
                fill={s.color}
                fillOpacity={stacked ? 0.4 : 0.15}
                strokeWidth={2}
                isAnimationActive={false}
              />
            ))}
          </AreaChart>
        ) : (
          <LineChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            {axes}
            {visible.map((s) => (
              <Line
                key={s.key}
                dataKey={s.key}
                name={s.label}
                type="monotone"
                stroke={s.color}
                strokeWidth={2}
                dot={false}
                isAnimationActive={false}
              />
            ))}
          </LineChart>
        )}
      </ChartContainer>
      {timeZone === undefined && zone && <TimeZoneNote zone={zone} />}
      {timeZone !== undefined && zone && <span hidden data-chart-export-zone={zone} />}
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
