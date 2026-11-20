import { Cell, Pie, PieChart } from "recharts";

import {
  categorySelectHandler,
  OTHER_COLOR,
  seriesColor,
  severityPalette,
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
  MAX_DONUT_SLICES,
  toChartNumber,
} from "@/lib/dashboard-charts";
import {
  formatMetric,
  topNWithOther,
  type LabelValue,
  type MetricFormat,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

const OTHER_LABEL = "Other";

// Part-to-whole shares: a donut by default, a full pie with `variant="pie"`
// (use it when the request says "pie"; a request for a bar chart is a
// BarBreakdown, never this chart). At most six slices; the rest fold into
// "Other". Non-positive values are dropped. Use BarBreakdown for rankings.
// Under the chart: every category as a table (`dataTable`), its first column
// headed by `categoryLabel` (the dimension: Region, Product), else "Category".
export function ShareChart({
  data,
  variant = "donut",
  format = "number",
  currency,
  height = 240,
  onSelect,
  ariaLabel,
  dataTable = true,
  categoryLabel,
}: {
  data: LabelValue[];
  variant?: "donut" | "pie";
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
  categoryLabel?: string;
}) {
  const issues = checkCategoryData(data, "share", format, variant);
  const ok = issues.errors.length === 0;
  // A share chart is part-to-whole, so the table states shares unless the
  // values are percents; it drops them when a value is negative.
  const additive = format !== "percent";
  const table = ok
    ? categoryTable(data, format, currency, { withShare: additive, categoryLabel })
    : null;
  useReportChartIssues("ShareChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;

  const positive = data
    .map((d) => ({ ...d, value: toChartNumber(d.value) ?? 0 }))
    .filter((d) => d.value > 0);
  const items = topNWithOther(positive, MAX_DONUT_SLICES, OTHER_LABEL);
  const folded = positive.length > items.length;
  const isOther = (index: number) => folded && index === items.length - 1;
  const total = items.reduce((sum, item) => sum + item.value, 0);
  const share = (value: number) => (total > 0 ? value / total : 0);
  // Log levels take their own colours (Error red, Warn amber) when every
  // named slice is one; otherwise the palette in order.
  const levels = severityPalette(
    items.filter((_, index) => !isOther(index)).map((item) => item.label),
  );
  const colorAt = (index: number) =>
    isOther(index)
      ? OTHER_COLOR
      : levels
        ? levels(items[index].label)
        : index >= 5
          ? OTHER_COLOR
          : seriesColor(index);
  const summary =
    ariaLabel ??
    `${variant === "pie" ? "Pie" : "Donut"} chart of ${items.length} shares: ` +
      items
        .map(
          (item) =>
            `${item.label} ${formatMetric(share(item.value), "percent")}`,
        )
        .join(", ");

  return (
    // The row layout keys on the card's width, not the viewport's: a donut in a narrow
    // grid column stacks its legend underneath instead of squeezing it off the card.
    // The switch sits at @lg (32rem) so the legend keeps ~15rem beside the 15rem donut.
    <div className="@container">
      {items.length === 0 ? (
        // Nothing positive to divide: say so rather than draw an empty ring.
        <p className="py-8 text-center text-sm text-muted-foreground">
          No positive values to show as shares.
        </p>
      ) : (
        <div className="flex flex-col items-center gap-4 @lg:flex-row">
          <ChartContainer
            config={{ value: { label: "Value" } }}
            className="aspect-square w-full max-w-60 shrink-0"
            style={{ height }}
            role="img"
            aria-label={summary}
          >
            <PieChart>
              <ChartTooltip
                content={
                  <ChartTooltipContent
                    hideLabel
                    formatter={(value, name) => (
                      <div className="flex w-full items-center justify-between gap-4">
                        <span className="text-muted-foreground">
                          {String(name)}
                        </span>
                        <span className="font-mono font-medium text-foreground tabular-nums">
                          {formatMetric(Number(value), format, currency)}
                        </span>
                      </div>
                    )}
                  />
                }
              />
              <Pie
                data={items}
                dataKey="value"
                nameKey="label"
                innerRadius={variant === "pie" ? 0 : "60%"}
                outerRadius="90%"
                strokeWidth={2}
                isAnimationActive={false}
                onClick={categorySelectHandler(items, folded, onSelect)}
                className={cn(onSelect && "cursor-pointer")}
              >
                {items.map((item, index) => (
                  <Cell key={`${item.label}-${index}`} fill={colorAt(index)} />
                ))}
              </Pie>
            </PieChart>
          </ChartContainer>
          {/* grid-cols-1 is minmax(0,1fr): an implicit auto track would grow to the
              longest label's nowrap width and push the values off the card. */}
          <ul className="grid w-full min-w-0 grid-cols-1 gap-1.5 text-sm @lg:w-auto @lg:flex-1">
            {items.map((item, index) => (
              <li
                key={`${item.label}-${index}`}
                className="flex items-center gap-2"
              >
                <span
                  aria-hidden="true"
                  className="size-2.5 shrink-0 rounded-[2px]"
                  style={{ backgroundColor: colorAt(index) }}
                />
                <span className="min-w-0 flex-1 truncate" title={item.label}>
                  {item.label}
                </span>
                <span className="shrink-0 font-medium tabular-nums">
                  {formatMetric(item.value, format, currency)}
                </span>
                <span className="w-12 shrink-0 text-right text-muted-foreground tabular-nums">
                  {formatMetric(share(item.value), "percent")}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
