import {
  Cell,
  Funnel,
  FunnelChart as RechartsFunnelChart,
  LabelList,
} from "recharts";

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
  checkCategoryData,
  flowNodeLabel,
  funnelCaptionX,
  funnelStages,
  funnelTable,
} from "@/lib/dashboard-charts";
import {
  formatMetric,
  type LabelValue,
  type MetricFormat,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

type Stage = { label: string; value: number; fill: string; caption: string };

// Ordered stages of one process, each a subset of the stage before (visits,
// sign-ups, trials, purchases): the width of each band is its count, so the
// drop between stages is the story. Give the stages in process order; they
// are drawn in that order, never sorted. A stage larger than the one before
// it is drawn but warned about (it is not a funnel), and a negative stage or
// one with a blank label is left out; with no stage above zero the chart shows
// its empty state. A caption too long for the column right of the plot drops
// its value, then shortens its name. Under the plot: each stage with its % of the first and of the previous
// stage (`dataTable`). `onSelect` gets the clicked stage's label.
export function FunnelChart({
  data,
  format = "number",
  currency,
  height,
  onSelect,
  ariaLabel,
  dataTable = true,
}: {
  data: LabelValue[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const issues = checkCategoryData(data, "funnel", format);
  const ok = issues.errors.length === 0;
  const stages: Stage[] = funnelStages(data).map((d, i) => {
    const fitted = flowNodeLabel(d.label, `· ${formatMetric(d.v, format, currency)}`, CAPTION_ROOM);
    return {
      label: d.label,
      value: d.v,
      fill: seriesColor(i),
      caption: fitted ? `${fitted.name}${fitted.value}` : "",
    };
  });
  const drawn = stages.some((s) => s.value > 0);
  const table = ok && drawn && stages.length > 1 ? funnelTable(data, format, currency) : null;
  useReportChartIssues("FunnelChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!drawn) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const first = stages[0].value;
  const ofFirst = (v: number) => formatMetric(first > 0 ? v / first : null, "percent");
  const summary =
    ariaLabel ??
    `Funnel of ${stages.length} stages from ${stages[0].label} ${formatMetric(first, format, currency)} to ${stages[stages.length - 1].label} ${formatMetric(stages[stages.length - 1].value, format, currency)} (${ofFirst(stages[stages.length - 1].value)} of the first)`;

  return (
    <div>
      <ChartContainer
        config={{ value: { label: "Value", color: seriesColor(0) } }}
        className={cn(
          "aspect-auto w-full",
          onSelect && "[&_.recharts-funnel-trapezoid]:cursor-pointer",
        )}
        style={{ height: height ?? Math.max(180, stages.length * 52) }}
        role="img"
        aria-label={summary}
      >
        <RechartsFunnelChart margin={MARGIN}>
          <ChartTooltip
            content={({ active, payload }) => {
              const stage = payload?.[0]?.payload as Stage | undefined;
              if (!active || !stage) return null;
              return (
                <div className="flex min-w-[8rem] items-center justify-between gap-4 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  <span className="text-muted-foreground">{stage.label}</span>
                  <span className="font-mono font-medium text-foreground tabular-nums">
                    {formatMetric(stage.value, format, currency)} · {ofFirst(stage.value)}
                  </span>
                </div>
              );
            }}
          />
          <Funnel
            data={stages}
            dataKey="value"
            nameKey="label"
            isAnimationActive={false}
            onClick={
              onSelect
                ? (entry: { label?: unknown; payload?: { label?: unknown } }) => {
                    const label = entry.label ?? entry.payload?.label;
                    if (typeof label === "string") onSelect(label);
                  }
                : undefined
            }
          >
            {stages.map((s, i) => (
              <Cell key={`${s.label}-${i}`} fill={s.fill} />
            ))}
            <LabelList dataKey="caption" content={StageCaption} />
          </Funnel>
        </RechartsFunnelChart>
      </ChartContainer>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}

const MARGIN = { top: 4, right: 140, left: 8, bottom: 4 };
// The caption starts 8px right of the plot and keeps 4px clear of the edge.
const CAPTION_ROOM = MARGIN.right - 12;

// Each stage's name and value, in one column right of the widest band: a
// label beside its own band would sit over the wider band above it, and a
// value inside a band does not fit once the band narrows to a point.
function StageCaption(props: { viewBox?: unknown; value?: unknown }) {
  const box = (props.viewBox ?? {}) as {
    x?: number;
    y?: number;
    upperWidth?: number;
    height?: number;
  };
  const { x = 0, y = 0, upperWidth = 0, height = 0 } = box;
  return (
    <text
      x={funnelCaptionX(x, upperWidth, MARGIN.left) + 8}
      y={y + height / 2}
      dominantBaseline="middle"
      fontSize={12}
      className="fill-foreground"
    >
      {String(props.value ?? "")}
    </text>
  );
}
