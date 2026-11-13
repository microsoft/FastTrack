import { useEffect, useState } from "react";
import { Layer, Rectangle, Sankey } from "recharts";

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
  checkFlowData,
  flowDepth,
  flowGraph,
  flowNodeLabel,
  flowTable,
  toChartNumber,
  type Flow,
} from "@/lib/dashboard-charts";
import { formatMetric, type MetricFormat } from "@/lib/dashboard-data";

// Weighted flows from one stage to the next (budget to department to
// project, traffic source to landing page to outcome): each band's width is
// the amount moving along it, and each node's height is what passes through
// it. One row per flow, `{ source, target, value }`; repeated pairs are added
// together. Flows only move forward: a loop or a node flowing to itself is an
// error, so give a returning node its own name per stage ("Visit (again)").
// Under the plot: every flow as a table (`dataTable`).
export function SankeyChart({
  flows,
  format = "number",
  currency,
  height = 320,
  ariaLabel,
  dataTable = true,
}: {
  flows: Flow[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const issues = checkFlowData(flows, format);
  const ok = issues.errors.length === 0;
  const [box, setBox] = useState<HTMLDivElement | null>(null);
  const [boxWidth, setBoxWidth] = useState(0);
  useEffect(() => {
    if (!box) return;
    setBoxWidth(box.clientWidth);
    if (typeof window.ResizeObserver === "undefined") return;
    const observer = new window.ResizeObserver(() => setBoxWidth(box.clientWidth));
    observer.observe(box);
    return () => observer.disconnect();
  }, [box]);
  const graph = ok ? flowGraph(flows) : null;
  const table = graph && graph.links.length > 0 ? flowTable(flows, format, currency) : null;
  useReportChartIssues("SankeyChart", issues);
  useChartTable(table);
  if (!ok || !graph) return <ChartProblem issues={issues} />;
  if (graph.links.length === 0) {
    return <p className="py-6 text-sm text-muted-foreground">No flows to show.</p>;
  }

  const summary =
    ariaLabel ??
    `Flow diagram of ${graph.links.length} flows between ${graph.nodes.length} nodes; largest: ` +
      [...graph.links]
        .sort((a, b) => b.value - a.value)
        .slice(0, 3)
        .map(
          (l) =>
            `${graph.nodes[l.source].name} to ${graph.nodes[l.target].name} ${formatMetric(l.value, format, currency)}`,
        )
        .join(", ");

  // A node label sits in the gap before the next column (the last column
  // uses the right margin), so it gets as much text as that gap holds.
  const maxDepth = flowDepth(graph.nodes.length, graph.links);
  const columnGap =
    maxDepth > 0 ? (boxWidth - MARGIN.left - MARGIN.right - NODE_WIDTH) / maxDepth : 0;

  return (
    <div ref={setBox}>
      <ChartContainer
        config={{ value: { label: "Value", color: seriesColor(0) } }}
        className="aspect-auto w-full"
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <Sankey
          data={graph}
          // Keep each node in its own stage's column: the default "justify"
          // pushes every node with no outgoing flow to the last column, so a
          // stage where most flows end is torn apart across columns.
          align="left"
          nodePadding={16}
          nodeWidth={NODE_WIDTH}
          margin={MARGIN}
          link={{ stroke: "var(--chart-1)", strokeOpacity: 0.25 }}
          node={
            <SankeyNode
              format={format}
              currency={currency}
              room={(depth) =>
                boxWidth === 0
                  ? Number.POSITIVE_INFINITY
                  : (depth >= maxDepth ? MARGIN.right : columnGap - NODE_WIDTH) - LABEL_GAP - 4
              }
            />
          }
        >
          <ChartTooltip
            content={({ active, payload }) => {
              const item = payload?.[0];
              if (!active || !item) return null;
              return (
                <div className="flex min-w-[8rem] items-center justify-between gap-4 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  <span className="text-muted-foreground">{String(item.name ?? "")}</span>
                  <span className="font-mono font-medium text-foreground tabular-nums">
                    {formatMetric(toChartNumber(item.value), format, currency)}
                  </span>
                </div>
              );
            }}
          />
        </Sankey>
      </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}

const MARGIN = { top: 8, right: 120, bottom: 8, left: 8 };
const NODE_WIDTH = 10;
const LABEL_GAP = 6;
// Recharts clones `node` with each node's geometry and payload; the name and
// its throughput sit to the node's right, cut to the room before the next
// column, with a halo in the page colour so they read over the bands.
function SankeyNode(props: {
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  index?: number;
  payload?: { name?: string; value?: number; depth?: number };
  format: MetricFormat;
  currency?: string;
  room: (depth: number) => number;
}) {
  const { x = 0, y = 0, width = 0, height = 0, index = 0, payload, format, currency, room } =
    props;
  const label =
    height >= 12
      ? flowNodeLabel(
          payload?.name ?? "",
          formatMetric(payload?.value ?? null, format, currency),
          room(payload?.depth ?? 0),
        )
      : null;
  return (
    <Layer>
      <Rectangle x={x} y={y} width={width} height={height} fill={seriesColor(index)} />
      {label && (
        <text
          x={x + width + LABEL_GAP}
          y={y + height / 2}
          dominantBaseline="middle"
          fontSize={12}
          className="fill-foreground"
          stroke="var(--background)"
          strokeWidth={3}
          paintOrder="stroke"
        >
          {label.name}
          {label.value && <tspan className="fill-muted-foreground">{label.value}</tspan>}
        </text>
      )}
    </Layer>
  );
}