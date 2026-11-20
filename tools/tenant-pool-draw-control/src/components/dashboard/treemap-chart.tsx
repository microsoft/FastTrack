import { Treemap } from "recharts";

import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { OTHER_COLOR, seriesColor } from "@/components/dashboard/chart-utils";
import { ChartContainer, ChartTooltip } from "@/components/ui/chart";
import {
  categoryTable,
  checkCategoryData,
  isBlankLabel,
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

type Tile = { name: string; value: number; fill: string; other: boolean };

// Each category as a rectangle whose area is its share of a whole: many parts
// of one additive total (spend by vendor, storage by site) where a donut would
// need more than six slices and a bar list would run long. Values must add up
// (counts, sums); a rate or an average has no area. Beyond `topN` tiles the
// smallest fold into one grey "Other" tile. Zero and negative values have no
// area and are left out with a warning, as is a category with a blank label;
// with no positive value at all the chart shows its empty state. Under the plot: every
// category as a table (`dataTable`), its first column headed by `categoryLabel`
// (the dimension: Vendor, Site), else "Category". `onSelect`
// gets the clicked tile's label ("Other" is not selectable).
export function TreemapChart({
  data,
  topN = 12,
  format = "number",
  currency,
  height = 300,
  onSelect,
  ariaLabel,
  dataTable = true,
  categoryLabel,
}: {
  data: LabelValue[];
  topN?: number;
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
  categoryLabel?: string;
}) {
  const issues = checkCategoryData(data, "treemap", format);
  const ok = issues.errors.length === 0;
  const present = data
    .filter((d) => !isBlankLabel(d.label))
    .map((d) => ({ label: String(d.label).trim(), value: toChartNumber(d.value) }))
    .filter((d): d is LabelValue => d.value !== null && d.value > 0);
  const table =
    ok && present.length > 0
      ? categoryTable(present, format, currency, { withShare: true, categoryLabel })
      : null;
  useReportChartIssues("TreemapChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (present.length === 0) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const items = topNWithOther(present, Number.isNaN(topN) ? 2 : Math.max(2, topN), OTHER_LABEL);
  const folded =
    items[items.length - 1]?.label === OTHER_LABEL && present.length > items.length;
  const tiles: Tile[] = items.map((item, i) => {
    const other = folded && i === items.length - 1;
    return {
      name: String(item.label),
      value: item.value,
      fill: other ? OTHER_COLOR : seriesColor(i),
      other,
    };
  });
  const total = tiles.reduce((sum, t) => sum + t.value, 0);
  const share = (v: number) => formatMetric(total > 0 ? v / total : null, "percent");
  const summary =
    ariaLabel ??
    `Treemap of ${tiles.length} categories: ` +
      tiles
        .slice(0, 3)
        .map((t) => `${t.name} ${formatMetric(t.value, format, currency)} (${share(t.value)})`)
        .join(", ") +
      (tiles.length > 3 ? ", and more" : "");

  return (
    <div>
      <ChartContainer
        config={{ value: { label: "Value", color: seriesColor(0) } }}
        className={cn("aspect-auto w-full", onSelect && "[&_.recharts-treemap-depth-1]:cursor-pointer")}
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <Treemap
          data={tiles}
          dataKey="value"
          nameKey="name"
          aspectRatio={4 / 3}
          isAnimationActive={false}
          onClick={
            onSelect
              ? (node: { name?: unknown; other?: unknown }) => {
                  if (!node.other && typeof node.name === "string") onSelect(node.name);
                }
              : undefined
          }
          content={<TreemapTile format={format} currency={currency} />}
        >
          <ChartTooltip
            content={({ active, payload }) => {
              const tile = payload?.[0]?.payload as Tile | undefined;
              if (!active || !tile) return null;
              return (
                <div className="flex min-w-[8rem] items-center justify-between gap-4 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  <span className="text-muted-foreground">{tile.name}</span>
                  <span className="font-mono font-medium text-foreground tabular-nums">
                    {formatMetric(tile.value, format, currency)} · {share(tile.value)}
                  </span>
                </div>
              );
            }}
          />
        </Treemap>
      </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}

// Recharts clones `content` with the tile's geometry and its data row; the
// label and value are written only where they fit.
function TreemapTile(props: {
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  depth?: number;
  name?: string;
  value?: number;
  fill?: string;
  format: MetricFormat;
  currency?: string;
}) {
  const { x = 0, y = 0, width = 0, height = 0, depth, name, value, fill, format, currency } = props;
  if (depth !== 1) return null;
  const roomForName = width > 48 && height > 22;
  const roomForValue = width > 48 && height > 40;
  const chars = Math.max(1, Math.floor((width - 16) / 7));
  const label = name && name.length > chars ? `${name.slice(0, chars - 1)}…` : name;
  const shown = roomForValue ? formatMetric(value ?? null, format, currency) : "";
  // The text sits on a backing in the page's own background colour, so it
  // keeps the theme's foreground contrast over any of the five chart colours.
  const backingWidth = Math.min(
    width - 8,
    Math.max((label ?? "").length * 7, shown.length * 6.5) + 8,
  );
  return (
    <g>
      <rect
        x={x}
        y={y}
        width={width}
        height={height}
        rx={4}
        fill={fill}
        stroke="var(--background)"
        strokeWidth={2}
      />
      {roomForName && (
        <rect
          x={x + 4}
          y={y + 4}
          width={backingWidth}
          height={roomForValue ? 32 : 17}
          rx={3}
          fill="var(--background)"
        />
      )}
      {roomForName && (
        <text x={x + 8} y={y + 16} fontSize={12} className="fill-foreground" fontWeight={500}>
          {label}
        </text>
      )}
      {roomForValue && (
        <text x={x + 8} y={y + 31} fontSize={11} className="fill-foreground">
          {shown}
        </text>
      )}
    </g>
  );
}
