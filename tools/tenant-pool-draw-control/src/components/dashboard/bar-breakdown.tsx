import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  LabelList,
  XAxis,
  YAxis,
} from "recharts";

import {
  allWholeNumbers,
  CATEGORY_LABEL_CHARS,
  categoryAxisWidth,
  categorySelectHandler,
  OTHER_COLOR,
  seriesColor,
  severityPalette,
  valueLabelRoom,
} from "@/components/dashboard/chart-utils";
import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";
import {
  categoryTable,
  checkCategoryData,
  toChartNumber,
} from "@/lib/dashboard-charts";
import {
  formatAxisValue,
  formatMetric,
  topNWithOther,
  topNOnly,
  type LabelValue,
  type MetricFormat,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

const OTHER_LABEL = "Other";

// Ranked category bars, largest first. Beyond `topN` bars the smallest
// categories fold into one "Other" bar when the measure is additive (counts,
// sums); a rate or percent is not additive, and a duration is usually an
// average or a percentile, so both show the top N only by default: pass
// `foldOther={true}` for a summed duration and `foldOther={false}` for any other
// non-additive measure, such as an average in "number" format. A source
// category already labelled "Other" is merged into the folded bar. A fold
// draws at least two bars (one named bar plus "Other"), even for `topN` 1.
// `onSelect` makes bars clickable for drill-down or cross-filtering (the folded
// "Other" bar is not selectable). `ordered` keeps the given order for ordinal
// categories (severity, stage, age bucket) and draws every category.
// Under the bars: every category as a table (`dataTable`); `categoryLabel` names
// the dimension (Region, Product) that heads its first column and the CSV's,
// "Category" when omitted. Shares of the total are stated only when
// `additive` says the values add up to a meaningful whole (counts, sums); a
// p95, an average or a rate does not, and a percent never does.
export function BarBreakdown({
  data,
  orientation = "horizontal",
  topN = 8,
  format = "number",
  currency,
  height,
  onSelect,
  ariaLabel,
  ordered = false,
  foldOther = format !== "percent" && format !== "duration" && !ordered,
  additive = false,
  dataTable = true,
  categoryLabel,
}: {
  data: LabelValue[];
  orientation?: "horizontal" | "vertical";
  topN?: number;
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  ordered?: boolean;
  foldOther?: boolean;
  additive?: boolean;
  dataTable?: boolean;
  categoryLabel?: string;
}) {
  const issues = checkCategoryData(data, "bar", format);
  const shares = additive && format !== "percent";
  const ok = issues.errors.length === 0;
  // Numeric strings ("12") are drawn as the numbers the check accepted; a gap
  // ("" or null) is not a bar and is never summed into "Other". An `ordered`
  // chart keeps a gap category as an empty slot, so the scale stays in order.
  const values = data.map((d) => ({ ...d, value: toChartNumber(d.value) }));
  const present = values.filter((d): d is LabelValue => d.value !== null);
  // Rows that are all gaps have nothing to draw or download.
  const noValues = data.length > 0 && present.length === 0;
  // A one-row result keeps its table too: the sentence drawn in place of a
  // lone bar rounds the value, while CSV writes the raw number and View data
  // shows a currency amount to its minor unit (other formats round as drawn).
  const table =
    ok && data.length > 0 && !noValues
      ? categoryTable(data, format, currency, {
          withShare: shares,
          ordered,
          categoryLabel,
        })
      : null;
  useReportChartIssues("BarBreakdown", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (noValues) {
    return (
      <p className="py-6 text-sm text-muted-foreground">No values to show.</p>
    );
  }

  // A fold keeps at least one named bar: a lone "Other" bar says nothing and
  // cannot be selected.
  const foldLimit = Number.isNaN(topN) ? 2 : Math.max(2, topN);
  const items = ordered
    ? (values as LabelValue[])
    : foldOther
      ? topNWithOther(present, foldLimit, OTHER_LABEL)
      : topNOnly(present, topN);
  const folded =
    foldOther &&
    !ordered &&
    items.length > 0 &&
    items[items.length - 1].label === OTHER_LABEL &&
    present.length > items.length;
  const isOther = (index: number) =>
    folded && index === items.length - 1;
  // One category compares nothing; say the value instead of drawing it. Only
  // when the source had one row: a list cut to one bar, or one value beside
  // gaps, still draws it. Either way its table stays available (above).
  if (items.length === 1 && data.length === 1) {
    return (
      <div>
        <p className="py-6 text-sm text-muted-foreground">
          All results are{" "}
          <span className="font-medium text-foreground">{items[0].label}</span> (
          {formatMetric(items[0].value, format, currency)}).
        </p>
        {dataTable && table && <ChartDataTable table={table} />}
      </div>
    );
  }
  const horizontal = orientation === "horizontal";
  const chartHeight =
    height ?? (horizontal ? Math.max(160, items.length * 36 + 16) : 280);
  const summary =
    ariaLabel ??
    `Bar chart of ${items.length} categories: ` +
      items
        .slice(0, 3)
        .map(
          (item) =>
            `${item.label} ${formatMetric(item.value, format, currency)}`,
        )
        .join(", ") +
      (items.length > 3 ? ", and more" : "");
  const select = categorySelectHandler(items, folded, onSelect);
  // Log levels take their own colours (Error red, Warn amber) when every
  // named bar is one; otherwise every bar is the first palette colour.
  const levels = severityPalette(
    items.filter((_, index) => !isOther(index)).map((item) => item.label),
  );
  const valueText = (v: unknown) =>
    formatMetric(toChartNumber(v), format, currency);
  // A negative bar's label goes past its left end: pad the value axis there so
  // it clears the category labels.
  const room = valueLabelRoom(
    items.flatMap((item) => {
      const n = toChartNumber(item.value);
      return n === null ? [] : [n];
    }),
    valueText,
  );

  return (
    <div>
    <ChartContainer
      config={{ value: { label: "Value", color: seriesColor(0) } }}
      className={cn(
        "aspect-auto w-full",
        onSelect && "[&_.recharts-bar-rectangle]:cursor-pointer",
      )}
      style={{ height: chartHeight }}
      role="img"
      aria-label={summary}
    >
      <BarChart
        data={items}
        layout={horizontal ? "vertical" : "horizontal"}
        margin={{ top: 4, right: horizontal ? room.right : 8, left: 0, bottom: 0 }}
      >
        <CartesianGrid horizontal={!horizontal} vertical={horizontal} />
        {horizontal ? (
          <>
            <XAxis
              type="number"
              dataKey="value"
              hide
              padding={{ left: room.left, right: 0 }}
            />
            <YAxis
              type="category"
              dataKey="label"
              tickLine={false}
              axisLine={false}
              width={categoryAxisWidth(items.map((item) => item.label))}
              tickFormatter={(v: string) =>
                v.length > CATEGORY_LABEL_CHARS
                  ? `${v.slice(0, CATEGORY_LABEL_CHARS - 1)}…`
                  : v
              }
            />
          </>
        ) : (
          <>
            <XAxis
              type="category"
              dataKey="label"
              tickLine={false}
              axisLine={false}
              tickMargin={8}
              interval="preserveStartEnd"
              minTickGap={8}
              tickFormatter={(v: string) =>
                v.length > 12 ? `${v.slice(0, 11)}…` : v
              }
            />
            <YAxis
              type="number"
              tickLine={false}
              axisLine={false}
              width={56}
              allowDecimals={!allWholeNumbers(items.map((item) => item.value))}
              tickFormatter={(v: number) =>
                formatAxisValue(v, format, currency)
              }
            />
          </>
        )}
        <ChartTooltip
          cursor={false}
          content={
            <ChartTooltipContent
              hideIndicator
              formatter={(value, _name, item) => (
                <div className="flex w-full items-center justify-between gap-4">
                  <span className="text-muted-foreground">
                    {String(item.payload?.label ?? "")}
                  </span>
                  <span className="font-mono font-medium text-foreground tabular-nums">
                    {formatMetric(toChartNumber(value), format, currency)}
                  </span>
                </div>
              )}
              hideLabel
            />
          }
        />
        <Bar
          dataKey="value"
          radius={4}
          isAnimationActive={false}
          onClick={select}
        >
          {items.map((item, index) => (
            <Cell
              key={`${item.label}-${index}`}
              fill={
                isOther(index)
                  ? OTHER_COLOR
                  : (levels?.(item.label) ?? "var(--color-value)")
              }
            />
          ))}
          {horizontal && (
            <LabelList
              dataKey="value"
              position="right"
              className="fill-foreground"
              fontSize={12}
              formatter={valueText}
            />
          )}
        </Bar>
      </BarChart>
    </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
