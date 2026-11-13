import { SunburstChart as RechartsSunburstChart, type SunburstData } from "recharts";

import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { seriesColor } from "@/components/dashboard/chart-utils";
import { ChartContainer, ChartTooltip } from "@/components/ui/chart";
import {
  checkPathData,
  pathTable,
  pathTree,
  type HierarchyNode,
  type PathValue,
} from "@/lib/dashboard-charts";
import { formatMetric, type MetricFormat } from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// One additive total broken down level by level (region, country, city; or
// department, team, cost line) as rings: the inner ring is the first level,
// each ring outward splits its parent. One row per leaf, `{ path, value }`
// with `path` the labels from the top level down; every segment is the sum of
// the leaves under it, so values must add up. Name the levels with `levels`
// for the table's columns. For one level use ShareChart or TreemapChart.
// Under the plot: every leaf with its share (`dataTable`). `onSelect` gets the clicked
// segment's path.
export function SunburstChart({
  rows,
  levels = [],
  format = "number",
  currency,
  height = 320,
  onSelect,
  ariaLabel,
  dataTable = true,
}: {
  rows: PathValue[];
  levels?: string[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (path: string[]) => void;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const issues = checkPathData(rows, format);
  const ok = issues.errors.length === 0;
  const tree = ok && rows.length > 0 ? pathTree(rows) : null;
  const table = tree?.children ? pathTable(rows, levels, format, currency) : null;
  useReportChartIssues("SunburstChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!tree?.children) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const total = tree.value;
  const data = colourTree(tree);
  const summary =
    ariaLabel ??
    `Sunburst of ${formatMetric(total, format, currency)} ${levels[0] ? `by ${levels[0]}` : `across ${tree.children.length} groups`}: ` +
      tree.children
        .slice(0, 3)
        .map((c) => `${c.name} ${formatMetric(c.value / total, "percent")}`)
        .join(", ") +
      (tree.children.length > 3 ? ", and more" : "");

  return (
    <div>
      <ChartContainer
        config={{ value: { label: "Value", color: seriesColor(0) } }}
        className={cn("aspect-auto w-full", onSelect && "[&_.recharts-sector]:cursor-pointer")}
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <RechartsSunburstChart
          data={data}
          dataKey="value"
          nameKey="name"
          innerRadius={36}
          stroke="var(--background)"
          // Recharts writes each segment's raw value on its arc; the tooltip and
          // the table carry the formatted value instead.
          textOptions={{ visibility: "hidden" }}
          onClick={
            onSelect
              ? (node: SunburstData) => {
                  if (Array.isArray(node.path)) onSelect(node.path as string[]);
                }
              : undefined
          }
        >
          <ChartTooltip
            content={({ active, payload }) => {
              const node = payload?.[0]?.payload as SunburstData | undefined;
              if (!active || !node) return null;
              const path = Array.isArray(node.path) ? (node.path as string[]) : [node.name];
              return (
                <div className="grid min-w-[8rem] gap-1 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  <div className="font-medium">{path.join(" › ")}</div>
                  <div className="flex justify-between gap-4">
                    <span className="text-muted-foreground">Value</span>
                    <span className="font-mono font-medium text-foreground tabular-nums">
                      {formatMetric(node.value ?? null, format, currency)} ·{" "}
                      {formatMetric(total > 0 ? (node.value ?? 0) / total : null, "percent")}
                    </span>
                  </div>
                </div>
              );
            }}
          />
        </RechartsSunburstChart>
      </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}

// Each top-level branch takes a series colour; its descendants take the same
// hue, lighter at each ring, so a branch reads as one family.
function colourTree(root: HierarchyNode): SunburstData {
  const visit = (node: HierarchyNode, base: string, depth: number, path: string[]): SunburstData => ({
    name: node.name,
    value: node.value,
    path,
    fill: depth <= 1 ? base : `color-mix(in oklch, ${base} ${Math.max(35, 100 - (depth - 1) * 25)}%, white)`,
    ...(node.children
      ? { children: node.children.map((c) => visit(c, base, depth + 1, [...path, c.name])) }
      : {}),
  });
  return {
    name: root.name,
    value: root.value,
    children: (root.children ?? []).map((c, i) => visit(c, seriesColor(i), 1, [c.name])),
  };
}
