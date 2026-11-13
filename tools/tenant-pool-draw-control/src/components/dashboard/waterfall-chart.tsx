import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  LabelList,
  ReferenceLine,
  XAxis,
  YAxis,
} from "recharts";

import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import {
  allWholeNumbers,
  categorySelectHandler,
} from "@/components/dashboard/chart-utils";
import { ChartContainer, ChartTooltip } from "@/components/ui/chart";
import {
  checkWaterfallData,
  signedMetric,
  WATERFALL_KIND_LABEL,
  waterfallBars,
  waterfallTable,
  type WaterfallBar,
  type WaterfallStep,
} from "@/lib/dashboard-charts";
import {
  formatAxisValue,
  formatMetric,
  type MetricFormat,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

const KIND_COLOR: Record<WaterfallBar["kind"], string> = {
  increase: "var(--chart-2)",
  decrease: "var(--chart-4)",
  total: "var(--chart-1)",
};

type Drawn = WaterfallBar & { caption: string };

// A running total built from signed steps: a P&L bridge (revenue, costs, net)
// or a period-over-period variance bridge. Each row is `{ label, value }`, a
// signed change, drawn in the given order as a floating bar from the running
// total before it to the one after; `total: true` makes a row a subtotal or
// total bar from zero. A total with a value sets the running total to it (an
// opening balance, a reported subtotal) and is warned about when it does not
// match the steps before it; a total without a value shows the running total so far.
// Increases, decreases and totals each take their own colour and legend
// entry. A step with no number, or a blank-labelled step with no value or 0, is
// left out with a warning; text where a number belongs, or any other value in a
// blank-labelled row, is an error. The summary states the change across the bridge
// (from an opening total, or from zero), and the table under the plot each bar
// with its change and running total (`dataTable`). `onSelect` gets the clicked bar's label.
export function WaterfallChart({
  data,
  format = "number",
  currency,
  height = 280,
  onSelect,
  ariaLabel,
  dataTable = true,
}: {
  data: WaterfallStep[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (label: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
}) {
  const issues = checkWaterfallData(data, format);
  const ok = issues.errors.length === 0;
  const bars: Drawn[] = ok
    ? waterfallBars(data).map((b) => ({
        ...b,
        caption:
          b.kind === "total"
            ? formatMetric(b.value, format, currency)
            : signedMetric(b.value, format, currency),
      }))
    : [];
  const drawn = bars.some((b) => b.value !== 0);
  const table = ok && drawn ? waterfallTable(data, format, currency) : null;
  useReportChartIssues("WaterfallChart", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!drawn) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const first = bars[0];
  const last = bars[bars.length - 1];
  const from =
    first.kind === "total"
      ? `${first.label} ${formatMetric(first.end, format, currency)}`
      : formatMetric(0, format, currency);
  const summary =
    ariaLabel ??
    `Waterfall of ${bars.length} bars from ${from} to ${last.label} ${formatMetric(last.end, format, currency)}`;
  const kinds = (["increase", "decrease", "total"] as const).filter((k) =>
    bars.some((b) => b.kind === k),
  );
  const select = categorySelectHandler(bars, false, onSelect);

  return (
    <div>
      <ChartContainer
        config={Object.fromEntries(
          kinds.map((k) => [k, { label: WATERFALL_KIND_LABEL[k], color: KIND_COLOR[k] }]),
        )}
        className={cn(
          "aspect-auto w-full",
          onSelect && "[&_.recharts-bar-rectangle]:cursor-pointer",
        )}
        style={{ height }}
        role="img"
        aria-label={summary}
      >
        <BarChart data={bars} margin={{ top: 20, right: 8, left: 0, bottom: 0 }}>
          <CartesianGrid vertical={false} />
          <XAxis
            dataKey="label"
            tickLine={false}
            axisLine={false}
            tickMargin={8}
            interval="preserveStartEnd"
            minTickGap={8}
            tickFormatter={(v: string) => (v.length > 12 ? `${v.slice(0, 11)}…` : v)}
          />
          <YAxis
            tickLine={false}
            axisLine={false}
            width={56}
            allowDecimals={!allWholeNumbers(bars.flatMap((b) => [b.value, b.end]))}
            tickFormatter={(v: number) => formatAxisValue(v, format, currency)}
          />
          <ReferenceLine y={0} stroke="var(--border)" />
          <ChartTooltip
            cursor={false}
            content={({ active, payload }) => {
              const bar = payload?.[0]?.payload as Drawn | undefined;
              if (!active || !bar) return null;
              return (
                <div className="grid min-w-[9rem] gap-1 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl">
                  <span className="font-medium text-foreground">{bar.label}</span>
                  {bar.kind !== "total" && (
                    <span className="flex justify-between gap-4">
                      <span className="text-muted-foreground">Change</span>
                      <span className="font-mono font-medium text-foreground tabular-nums">
                        {bar.caption}
                      </span>
                    </span>
                  )}
                  <span className="flex justify-between gap-4">
                    <span className="text-muted-foreground">
                      {bar.kind === "total" ? "Total" : "Running total"}
                    </span>
                    <span className="font-mono font-medium text-foreground tabular-nums">
                      {formatMetric(bar.end, format, currency)}
                    </span>
                  </span>
                </div>
              );
            }}
          />
          <Bar dataKey="range" isAnimationActive={false} onClick={select}>
            {bars.map((b, i) => (
              <Cell key={`${b.label}-${i}`} fill={KIND_COLOR[b.kind]} />
            ))}
            <LabelList
              dataKey="caption"
              position="top"
              fontSize={11}
              className="fill-foreground"
            />
          </Bar>
        </BarChart>
      </ChartContainer>
      <ul className="mt-2 flex flex-wrap justify-center gap-4 text-xs text-muted-foreground">
        {kinds.map((k) => (
          <li key={k} className="flex items-center gap-1.5">
            <span
              className="size-2.5 shrink-0 rounded-[2px]"
              style={{ backgroundColor: KIND_COLOR[k] }}
            />
            {WATERFALL_KIND_LABEL[k]}
          </li>
        ))}
      </ul>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
