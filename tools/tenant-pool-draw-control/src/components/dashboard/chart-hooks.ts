import {
  createContext,
  useContext,
  useEffect,
  useId,
  useLayoutEffect,
} from "react";

import type { ChartIssues, ChartTable } from "@/lib/dashboard-charts";

// A ChartCard collects the table of the chart inside it, so its header can
// offer the chart's data as CSV.
export const ChartTableContext = createContext<
  ((table: ChartTable | null) => void) | null
>(null);

// Each ChartDataTable inside a ChartCard claims the card's "View data" with its
// own table, in mount order. Only the first claimant (`owner`) moves its table
// into the card's "⋮" menu; every other one keeps its table under its plot, and
// when the owner lets go the next claimant takes over. A chart with
// `dataTable={false}` renders no ChartDataTable, so it never claims (its CSV
// export still works). The claim returns its release.
export type ChartTableView = {
  owner: string | null;
  claim: (id: string, table: ChartTable) => () => void;
};
export const ChartTableViewContext = createContext<ChartTableView | null>(null);

// The ChartCard header element a chart inside renders its own header controls
// into (the TrendChart's chart-type menu, left of the "⋮" menu); null outside a
// card. Charts claim it in mount order, each keeping its place when it claims
// again, and only the first claimant (`owner`) gets it, so a card holding
// several charts shows one menu in its header.
export type ChartHeaderSlot = {
  element: HTMLElement | null;
  owner: string | null;
  claim: (id: string) => () => void;
};
export const ChartHeaderSlotContext = createContext<ChartHeaderSlot | null>(null);

// The card header element this chart may render its controls into, or null:
// outside a card, before the header has mounted, or while an earlier chart in
// the same card holds it (this chart then keeps its controls above its plot).
export function useChartHeaderSlot(wants: boolean): HTMLElement | null {
  const slot = useContext(ChartHeaderSlotContext);
  const id = useId();
  const claim = slot?.claim;
  // A layout effect, so the menu is in the header by the first paint rather
  // than drawn above the plot and then moved.
  useLayoutEffect(() => {
    if (!claim || !wants) return;
    return claim(id);
  }, [claim, wants, id]);
  return wants && slot?.owner === id ? slot.element : null;
}

// Hands the chart's table to the enclosing ChartCard (if any). Keyed on the
// table's content, not its identity, so a table rebuilt every render does not
// loop. A table with no rows is not handed over: there is nothing to download.
export function useChartTable(table: ChartTable | null) {
  const register = useContext(ChartTableContext);
  const key = table && table.rows.length > 0 ? JSON.stringify(table) : "";
  useEffect(() => {
    if (!register) return;
    register(key ? (JSON.parse(key) as ChartTable) : null);
    return () => register(null);
  }, [register, key]);
}

// How many mounted charts report each line right now.
const reporting = new Map<string, number>();

// Logs a chart data problem once while any mounted chart has it, and again
// once no chart has had it and one does (a remount after an edit, a problem
// that comes back). An error (the chart cannot be drawn) goes to
// console.error, which console-capture forwards to the dev server's
// .browser-errors.log, so the next pre-deploy gate run fails on it. A warning
// (the chart is drawn, the data looks off) goes to console.warn, which reaches
// the preview console but not that log: data such as an unsorted feed must not
// fail a deploy.
// Each line keeps its severity whatever its text holds (a newline included).
export function useReportChartIssues(component: string, issues: ChartIssues) {
  const key = JSON.stringify([
    ...issues.errors.map((e) => ["error", `${component}: ${e}`]),
    ...issues.warnings.map((w) => ["warn", `${component} (warning): ${w}`]),
  ]);
  useEffect(() => {
    const lines = JSON.parse(key) as [string, string][];
    const tags = lines.map(([level, line]) => `${level}:${line}`);
    lines.forEach(([level, line], i) => {
      const n = reporting.get(tags[i]) ?? 0;
      reporting.set(tags[i], n + 1);
      if (n > 0) return;
      if (level === "error") console.error(line);
      else console.warn(line);
    });
    // Released a task later, so StrictMode's cleanup and remount within one
    // commit count as one mount and log once.
    return () => {
      setTimeout(() => {
        for (const tag of tags) {
          const n = reporting.get(tag) ?? 0;
          if (n > 1) reporting.set(tag, n - 1);
          else reporting.delete(tag);
        }
      }, 0);
    };
  }, [key]);
}
