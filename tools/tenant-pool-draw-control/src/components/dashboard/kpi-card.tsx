import { ArrowDownRight, ArrowUpRight, Minus } from "lucide-react";
import { Line, LineChart } from "recharts";

import { SlowQueryHint } from "@/components/dashboard/slow-query-hint";
import { ChartCardMenu } from "@/components/dashboard/chart-extras";
import { useReportChartIssues } from "@/components/dashboard/chart-hooks";
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ChartContainer } from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/ui/spinner";
import { checkKpiTarget } from "@/lib/dashboard-charts";
import {
  formatMetric,
  formatPercentChange,
  percentChange,
  targetAttainment,
  targetStatus,
  tileSourcesOrNone,
  type MetricFormat,
  type TileSources,
  type TileSourceStats,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// One headline number with its change against a previous period, an optional
// target and an optional sparkline. The delta carries an arrow and a sign, and
// the target an "On track" / "Off track" word, not only colour.
// `refreshing` keeps the number, dims it and spins a small indicator.
// `source` adds the "⋮" menu whose "View Query" item shows where the number
// came from.
export function KpiCard({
  label,
  description,
  value,
  format = "number",
  currency,
  digits,
  previous,
  deltaLabel,
  goodDirection = "up",
  target,
  targetLabel = "target",
  trend,
  loading,
  refreshing,
  error,
  slowAfterMs,
  onRetry,
  source: sourceProp,
  sourceStats,
  className,
}: {
  label: string;
  // What the number counts when the label alone could be misread
  // ("4xx and 5xx responses", "Share of requests over 2 s"), under the label.
  description?: string;
  value: number | null | undefined;
  format?: MetricFormat;
  currency?: string;
  // Fraction digits for a `number` or `percent` value the query already
  // rounded (`round(x, 2)` -> 2), so the tile agrees with a table beside it.
  digits?: number;
  previous?: number | null;
  deltaLabel?: string;
  goodDirection?: "up" | "down";
  // The goal `value` is measured against, in the same unit. `goodDirection`
  // decides which side of it is on track; null shows "No target".
  target?: number | null;
  // Names the target in the tile ("82% of Q3 goal"); defaults to "target".
  targetLabel?: string;
  trend?: number[];
  loading?: boolean;
  // A fetch is running while a value is already shown (the query's `isFetching`).
  refreshing?: boolean;
  error?: string | null;
  // How long a load runs before "Running query… N s" appears (default 5 s).
  slowAfterMs?: number;
  // Shown as a Retry button in the error state only.
  onRetry?: () => void;
  // The query's descriptor, the same constant its fetch reads.
  source?: TileSources;
  sourceStats?: TileSourceStats;
  className?: string;
}) {
  const source = tileSourcesOrNone(sourceProp);
  const updating = !loading && !!refreshing;
  useReportChartIssues(
    "KpiCard",
    target === undefined ? NO_ISSUES : checkKpiTarget(target, format),
  );
  return (
    <Card data-kpi-card="" className={cn("group/tile gap-3 py-5", className)}>
      <CardHeader className="px-5">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          <h3>{label}</h3>
        </CardTitle>
        {description && (
          <CardDescription data-slot="card-kpi-description" className="text-xs">
            {description}
          </CardDescription>
        )}
        {(updating || source) && (
          <CardAction className="-my-1.5 flex items-center gap-1">
            {updating && (
              <Spinner
                aria-label={`Refreshing ${label}`}
                className="text-muted-foreground"
              />
            )}
            {source && (
              <ChartCardMenu
                title={label}
                source={source}
                stats={loading || error ? undefined : sourceStats}
                refreshing={updating && !error}
              />
            )}
          </CardAction>
        )}
      </CardHeader>
      <CardContent
        aria-busy={updating || undefined}
        className={cn("space-y-2 px-5 transition-opacity", updating && "opacity-60")}
      >
        {loading ? (
          <div
            role="status"
            aria-label={`Loading ${label}`}
            className="space-y-2"
          >
            <Skeleton className="h-8 w-28" />
            <Skeleton className="h-4 w-36" />
            <SlowQueryHint afterMs={slowAfterMs} />
          </div>
        ) : error ? (
          <div className="space-y-2">
            <p role="alert" className="text-sm text-destructive">
              {error}
            </p>
            {onRetry && (
              <Button variant="outline" size="sm" onClick={onRetry}>
                Retry
              </Button>
            )}
          </div>
        ) : (
          <>
            <p className="text-3xl font-semibold tracking-tight tabular-nums">
              {formatMetric(value, format, currency, digits)}
            </p>
            {(previous !== undefined || deltaLabel) && (
              <div className="flex flex-wrap items-center gap-2 text-xs">
                {previous !== undefined && (
                  <DeltaChip
                    change={percentChange(value, previous)}
                    goodDirection={goodDirection}
                  />
                )}
                {deltaLabel && (
                  <span className="text-muted-foreground">{deltaLabel}</span>
                )}
              </div>
            )}
            {target !== undefined && (
              <TargetProgress
                label={label}
                value={value}
                target={target}
                targetLabel={targetLabel}
                goodDirection={goodDirection}
                format={format}
                currency={currency}
              />
            )}
            {trend && trend.length > 1 && (
              <Sparkline
                label={label}
                values={trend}
                format={format}
                currency={currency}
              />
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}

function DeltaChip({
  change,
  goodDirection,
}: {
  change: number | null;
  goodDirection: "up" | "down";
}) {
  const direction =
    change === null || change === 0 ? "flat" : change > 0 ? "up" : "down";
  const tone =
    direction === "flat"
      ? "neutral"
      : direction === goodDirection
        ? "good"
        : "bad";
  const Icon =
    direction === "up"
      ? ArrowUpRight
      : direction === "down"
        ? ArrowDownRight
        : Minus;
  const spoken =
    change === null
      ? "No comparison"
      : direction === "up"
        ? "Up"
        : direction === "down"
          ? "Down"
          : "No change";
  return (
    <span
      data-direction={direction}
      data-tone={tone}
      className={cn(
        "inline-flex items-center gap-0.5 rounded-md px-1.5 py-0.5 font-medium tabular-nums",
        tone === "good" &&
          "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
        tone === "bad" && "bg-destructive/10 text-destructive",
        tone === "neutral" && "bg-muted text-muted-foreground",
      )}
    >
      {change !== null && <Icon className="size-3.5" aria-hidden="true" />}
      <span className="sr-only">{spoken} </span>
      {formatPercentChange(change)}
    </span>
  );
}

const NO_ISSUES = { errors: [], warnings: [] };

const TARGET_STATUS_WORD = {
  on: "On track",
  off: "Off track",
} as const;

// The value as a share of its target with a slim bar, and whether that is on
// track. A zero or negative target has no share (no bar, no misleading 0%) but
// still says on or off track; a missing value or target says neither.
function TargetProgress({
  label,
  value,
  target,
  targetLabel,
  goodDirection,
  format,
  currency,
}: {
  label: string;
  value: number | null | undefined;
  target: number | null;
  targetLabel: string;
  goodDirection: "up" | "down";
  format: MetricFormat;
  currency?: string;
}) {
  const status = targetStatus(value, target, goodDirection);
  // An off-track share never rounds to 100%, so it cannot contradict the chip.
  const rawAttainment = targetAttainment(value, target);
  const attainment =
    rawAttainment === null || status !== "off"
      ? rawAttainment
      : goodDirection === "down"
        ? Math.max(rawAttainment, 1.001)
        : Math.min(rawAttainment, 0.999);
  const targetText = formatMetric(target, format, currency);
  const shareText =
    attainment === null ? null : formatMetric(attainment, "percent");
  const hasTarget = target !== null && Number.isFinite(target);
  const word =
    status !== "none"
      ? TARGET_STATUS_WORD[status]
      : hasTarget
        ? "No value"
        : "No target";
  const summary = !hasTarget
    ? `${label} has no ${targetLabel}.`
    : status === "none"
      ? `${label} ${targetLabel} ${targetText}, no value to compare.`
      : shareText === null
        ? `${label} ${targetLabel} ${targetText}, ${word.toLowerCase()}.`
        : `${label} is ${shareText} of ${targetLabel} ${targetText}, ${word.toLowerCase()}.`;
  const fill = attainment === null ? 0 : Math.min(Math.max(attainment, 0), 1);
  return (
    <div data-target-status={status} className="space-y-1.5 text-xs">
      <p className="sr-only">{summary}</p>
      <div aria-hidden="true" className="flex flex-wrap items-center gap-2">
        <span
          className={cn(
            "inline-flex items-center rounded-md px-1.5 py-0.5 font-medium",
            status === "on" &&
              "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
            status === "off" && "bg-destructive/10 text-destructive",
            status === "none" && "bg-muted text-muted-foreground",
          )}
        >
          {word}
        </span>
        {hasTarget && (
          <span className="text-muted-foreground tabular-nums">
            {shareText === null
              ? `${capitalize(targetLabel)} ${targetText}`
              : `${shareText} of ${targetLabel} (${targetText})`}
          </span>
        )}
      </div>
      {attainment !== null && (
        <div
          aria-hidden="true"
          data-slot="target-bar"
          className="h-1.5 w-full overflow-hidden rounded-full bg-muted"
        >
          <div
            className={cn(
              "h-full rounded-full",
              status === "on" ? "bg-emerald-500" : "bg-destructive",
            )}
            style={{ width: `${(fill * 100).toFixed(1)}%` }}
          />
        </div>
      )}
    </div>
  );
}

function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function Sparkline({
  label,
  values,
  format,
  currency,
}: {
  label: string;
  values: number[];
  format: MetricFormat;
  currency?: string;
}) {
  const data = values.map((value, index) => ({ index, value }));
  return (
    <ChartContainer
      config={{ value: { label, color: "var(--chart-1)" } }}
      className="aspect-auto h-10"
      role="img"
      aria-label={`${label} trend over ${values.length} periods, from ${formatMetric(values[0], format, currency)} to ${formatMetric(values[values.length - 1], format, currency)}`}
    >
      <LineChart data={data} margin={{ top: 4, right: 2, bottom: 4, left: 2 }}>
        <Line
          type="monotone"
          dataKey="value"
          stroke="var(--color-value)"
          strokeWidth={2}
          dot={false}
          isAnimationActive={false}
        />
      </LineChart>
    </ChartContainer>
  );
}
