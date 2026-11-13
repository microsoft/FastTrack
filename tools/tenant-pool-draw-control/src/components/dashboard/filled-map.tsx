import { useId, useRef, useState, type PointerEvent } from "react";

import {
  ChartDataTable,
  ChartProblem,
} from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import {
  checkFilledMapData,
  filledMapTable,
  filledMapValues,
  heatmapColor,
  heatmapShade,
  type FilledMapRow,
} from "@/lib/dashboard-charts";
import { formatMetric, type MetricFormat } from "@/lib/dashboard-data";
import { US_STATES, US_STATES_VIEWBOX } from "@/lib/us-states-geo";
import { cn } from "@/lib/utils";

type Hover = { code: string; x: number; y: number; wide: boolean };

// A value per US state (and DC), drawn as a shaded map: sales, headcount or
// tickets by state. Each row names its region by postal code ("TX"), FIPS
// code ("48" or 48) or full name ("Texas"); case, commas, spaces and the dots
// of an abbreviation ("D.C.") do not matter, nothing is guessed. Rows naming
// anything else (territories, countries, cities, typos, "1.0") are left out
// and warned by row number, and their values are not checked. Repeated
// regions are added together (warned). A state with no row or no number is
// drawn with a dashed outline ("No data"), never as zero: send 0 for a real zero. The shade
// scale runs from zero (or the minimum, when values go below zero) to the
// maximum. Under the map: one row per region the data names (`dataTable`).
// `onSelect` gets the clicked state's region as the data wrote it (trimmed)
// and its postal code; states with no data are not clickable. Like TreemapChart,
// clicking is a pointer shortcut: keep a filter control for the same field so
// keyboard users can pick a state too. The outlines
// ship with the app (about 15 KB gzipped), so the map needs no connector,
// tiles or network.
export function FilledMap({
  data,
  format = "number",
  currency,
  height,
  onSelect,
  ariaLabel,
  dataTable = true,
  regionLabel = "State",
  valueLabel = "Value",
}: {
  data: FilledMapRow[];
  format?: MetricFormat;
  currency?: string;
  height?: number;
  onSelect?: (region: string, code: string) => void;
  ariaLabel?: string;
  dataTable?: boolean;
  regionLabel?: string;
  valueLabel?: string;
}) {
  const titleId = useId();
  const box = useRef<HTMLDivElement>(null);
  const [hover, setHover] = useState<Hover | null>(null);
  const issues = checkFilledMapData(data, US_STATES, format, "US states map");
  const ok = issues.errors.length === 0;
  const map = ok
    ? filledMapValues(data, US_STATES)
    : { values: new Map<string, number>(), labels: new Map<string, string>(), order: [], min: 0, max: 0 };
  const drawn = [...map.values.values()].some((v) => v !== 0);
  const table = ok && drawn
    ? filledMapTable(map, US_STATES, format, currency, regionLabel, valueLabel)
    : null;
  useReportChartIssues("FilledMap", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!drawn) {
    return <p className="py-6 text-sm text-muted-foreground">No values to show.</p>;
  }

  const { values, labels, min, max } = map;
  const fmt = (v: number) => formatMetric(v, format, currency);
  const top = US_STATES.find((s) => values.get(s.code) === max)!;
  const blanks = US_STATES.length - values.size;
  const summary =
    ariaLabel ??
    `Map of US states, ${values.size} of ${US_STATES.length} with data, ${fmt(Math.min(0, min))} to ${fmt(max)}; highest ${top.name} (${fmt(max)})${blanks > 0 ? `; ${blanks} ${blanks === 1 ? "has" : "have"} no data` : ""}`;
  const hovered = hover ? US_STATES.find((s) => s.code === hover.code) : undefined;

  const track = (code: string) => (e: PointerEvent<SVGPathElement>) => {
    const rect = box.current?.getBoundingClientRect();
    if (!rect) return;
    const x = e.clientX - rect.left;
    setHover({ code, x, y: e.clientY - rect.top, wide: x > rect.width / 2 });
  };
  // Leaving a state for the sea or a gap between states hides the tooltip;
  // entering a neighbour sets it again on its first move.
  const untrack = (code: string) => () =>
    setHover((h) => (h?.code === code ? null : h));

  return (
    <div>
      <div ref={box} className="relative w-full">
        <svg
          role="img"
          aria-labelledby={titleId}
          viewBox={US_STATES_VIEWBOX}
          preserveAspectRatio="xMidYMid meet"
          className="block w-full"
          style={{ height: height ?? "auto", maxHeight: height }}
          onPointerLeave={() => setHover(null)}
        >
          <title id={titleId}>{summary}</title>
          {US_STATES.map((s) => {
            const v = values.get(s.code);
            const has = v !== undefined;
            const pick = onSelect && has ? () => onSelect(labels.get(s.code)!, s.code) : undefined;
            return (
              <path
                key={s.code}
                d={s.d}
                data-region={s.code}
                data-has-value={has ? "" : undefined}
                fill={has ? heatmapColor(heatmapShade(v, min, max)) : "var(--background)"}
                stroke={hover?.code === s.code ? "var(--foreground)" : has ? "var(--background)" : "var(--border)"}
                strokeWidth={hover?.code === s.code ? 2 : 1}
                strokeDasharray={has ? undefined : "3 2"}
                vectorEffect="non-scaling-stroke"
                className={cn("forced-colors:stroke-[CanvasText]", pick && "cursor-pointer")}
                onPointerMove={track(s.code)}
                onPointerLeave={untrack(s.code)}
                onClick={pick}
              />
            );
          })}
        </svg>
        {hover && hovered && (
          <div
            aria-hidden="true"
            data-map-tooltip=""
            className="pointer-events-none absolute z-10 whitespace-nowrap rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs text-foreground shadow-xl"
            style={{
              top: hover.y + 12,
              ...(hover.wide ? { right: `calc(100% - ${hover.x - 12}px)` } : { left: hover.x + 12 }),
            }}
          >
            <span className="text-muted-foreground">{hovered.name}</span>{" "}
            <span className="font-mono font-medium tabular-nums">
              {valueLabel}: {values.has(hovered.code) ? fmt(values.get(hovered.code)!) : "No data"}
            </span>
          </div>
        )}
      </div>
      <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground" aria-hidden="true">
        <span className="tabular-nums">{fmt(Math.min(0, min))}</span>
        <span
          className="h-2 w-32 rounded-full"
          style={{ backgroundImage: `linear-gradient(to right, ${heatmapColor(0)}, ${heatmapColor(1)})` }}
        />
        <span className="tabular-nums">{fmt(max)}</span>
        {blanks > 0 && (
          <span className="ml-3 flex items-center gap-1">
            <span className="size-3 rounded-sm border border-dashed border-border" />
            No data
          </span>
        )}
      </div>
      {dataTable && table && <ChartDataTable table={table} />}
    </div>
  );
}
