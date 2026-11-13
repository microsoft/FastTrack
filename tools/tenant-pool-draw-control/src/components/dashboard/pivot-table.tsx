import { ChevronRight } from "lucide-react";
import { useMemo, useState, type ReactNode } from "react";

import { ChartProblem } from "@/components/dashboard/chart-extras";
import {
  useChartTable,
  useReportChartIssues,
} from "@/components/dashboard/chart-hooks";
import { Button } from "@/components/ui/button";
import {
  checkPivotData,
  pivotGrid,
  pivotTable,
  pivotValueFormat,
  pivotValueLabel,
  type PivotGrid,
  type PivotRowNode,
  type PivotValue,
} from "@/lib/dashboard-charts";
import { formatMetric } from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// Sticky cells need an opaque background, or scrolled cells show through them.
const HEAD_BG = "bg-card";
const GROUP_BG = "bg-[color-mix(in_oklch,var(--muted)_60%,var(--card))]";
const TOTAL_BG = "bg-[color-mix(in_oklch,var(--muted)_90%,var(--card))]";

type Expansion = { rowsKey: string; all: boolean; flipped: Set<string> };

const NO_COLUMNS: string[] = [];

// Column runs at one header level: consecutive columns that share their
// labels up to that level are one header cell.
function headerRuns(columns: string[][], level: number): { label: string; span: number }[] {
  const runs: { label: string; span: number; key: string }[] = [];
  for (const labels of columns) {
    const key = JSON.stringify(labels.slice(0, level + 1));
    const last = runs[runs.length - 1];
    if (last && last.key === key) last.span += 1;
    else runs.push({ label: labels[level], span: 1, key });
  }
  return runs;
}

// Flat rows as a matrix: grouped down by `rows` (nested in that order, each
// group a collapsible row carrying its subtotal) and across by `columns`, one
// aggregate per entry in `values`, with a Total column (when `columns` is set)
// and a grand total row. Every total is aggregated from the source rows, so
// avg, min and max totals are right. Rows and columns keep the order first
// seen in `data`, never sorted (columns sharing an outer label are drawn
// together under it): order the query, or list the first column
// field's labels in `columnOrder` (quarters, months) to put them first in that
// order. A blank label groups as
// "(blank)" (warned); a cell no source row gives a number to is blank, never
// zero (a `count` there shows 0, and a count is never currency or percent formatted). Different email addresses under one parent
// group fail the check, since masking would merge them (addresses differing only in
// letter case count as one, and are warned); an object, list or Date label is
// an error; a "Total" or "Grand total" label, or labels that group only after trimming
// or as a number and text, is warned. Prefer rows the query has already aggregated by the row and column
// fields (their totals are right for sum, min and max; for an average return a
// sum and a count, and sum a count): more than MAX_PIVOT_SOURCE_ROWS source rows, MAX_PIVOT_COLUMNS
// columns or MAX_PIVOT_CELLS value cells is an error. The header and first
// column stay put while the table scrolls inside `maxHeight`. Inside a
// ChartCard, the "⋮" menu downloads the pivoted view (every group expanded) as
// CSV.
export function PivotTable({
  data,
  rows,
  columns = NO_COLUMNS,
  columnOrder,
  values,
  currency,
  rowLabels,
  defaultExpanded = true,
  maxHeight = 480,
  ariaLabel,
}: {
  data: Record<string, unknown>[];
  rows: string[];
  columns?: string[];
  columnOrder?: (string | number)[];
  values: PivotValue[];
  currency?: string;
  // Header labels for the row fields, in `rows` order; the field names otherwise.
  rowLabels?: string[];
  defaultExpanded?: boolean;
  maxHeight?: number;
  ariaLabel?: string;
}) {
  // A group's id is its label path, so toggles are kept across a data refresh
  // and apply only under the row fields they were made under, since under
  // other row fields the same path names another group.
  const rowsKey = JSON.stringify(rows);
  const fresh = (all: boolean): Expansion => ({ rowsKey, all, flipped: new Set() });
  const [stored, setExpansion] = useState<Expansion>(() => fresh(defaultExpanded));
  const expansion = stored.rowsKey === rowsKey ? stored : fresh(defaultExpanded);
  // Toggling a group re-renders with the same props, so the pivot is not rebuilt;
  // the spec is keyed by content, so inline `rows={[...]}` arrays do not rebuild it either.
  const specKey = JSON.stringify([rows, columns, values, columnOrder ?? null, rowLabels ?? null, currency ?? null]);
  const { issues, grid, labels, table } = useMemo(() => {
    const [r, c, v, order, names, cur] = JSON.parse(specKey) as [
      string[],
      string[],
      PivotValue[],
      (string | number)[] | null,
      string[] | null,
      string | null,
    ];
    const issues = checkPivotData(data, r, c, v, order ?? undefined);
    const grid: PivotGrid | null =
      issues.errors.length === 0 && data.length > 0
        ? pivotGrid(data, r, c, v, order ?? undefined)
        : null;
    const labels = r.map((field, i) => names?.[i] ?? field);
    const table = grid ? pivotTable(grid, labels, cur ?? undefined) : null;
    return { issues, grid, labels, table };
  }, [data, specKey]);
  const ok = issues.errors.length === 0;
  useReportChartIssues("PivotTable", issues);
  useChartTable(table);
  if (!ok) return <ChartProblem issues={issues} />;
  if (!grid || grid.rows.length === 0) {
    return <p className="py-6 text-sm text-muted-foreground">No rows to show.</p>;
  }

  const isExpanded = (id: string) => expansion.all !== expansion.flipped.has(id);
  const toggle = (id: string) =>
    setExpansion((current) => {
      const base = current.rowsKey === rowsKey ? current : fresh(defaultExpanded);
      const flipped = new Set(base.flipped);
      if (!flipped.delete(id)) flipped.add(id);
      return { rowsKey, all: base.all, flipped };
    });
  const hasGroups = grid.rows.some((node) => node.children.length > 0);
  const fmt = (v: number | null, i: number) => {
    if (v === null) return "";
    return formatMetric(v, pivotValueFormat(values[i % values.length]), currency);
  };
  const showValueRow = values.length > 1 || columns.length === 0;
  const headerRows = columns.length + (showValueRow ? 1 : 0);
  const slots = grid.columns.length + (grid.totalColumn ? 1 : 0);
  const summary =
    ariaLabel ??
    `Pivot table of ${values.map(pivotValueLabel).join(", ")} by ${labels.join(", ")}${columns.length > 0 ? ` and ${columns.join(", ")}` : ""}`;

  const valueCells = (cells: (number | null)[], strong: boolean, className?: string) =>
    cells.map((v, i) => (
      <td
        key={i}
        data-pivot-cell=""
        className={cn(
          "whitespace-nowrap px-2 py-1.5 text-right font-mono tabular-nums",
          strong && "font-semibold",
          i % values.length === 0 && i > 0 && "border-l border-border/60",
          className,
        )}
      >
        {fmt(v, i)}
      </td>
    ));

  const body: ReactNode[] = [];
  const walk = (node: PivotRowNode) => {
    const group = node.children.length > 0;
    const open = group && isExpanded(node.id);
    const label = node.path[node.path.length - 1];
    body.push(
      <tr
        key={node.id}
        data-pivot-row={node.depth}
        data-pivot-group={group ? "" : undefined}
        className={cn("border-b border-border/60", group ? GROUP_BG : "hover:bg-muted/40")}
      >
        <th
          scope="row"
          className={cn(
            "sticky left-0 z-[1] max-w-[18rem] whitespace-normal break-words px-2 py-1.5 text-left font-normal",
            group ? cn(GROUP_BG, "font-medium") : HEAD_BG,
          )}
          style={{ paddingLeft: `${0.5 + node.depth * 1.25 + (hasGroups && !group ? 1.5 : 0)}rem` }}
        >
          <span className="flex min-w-0 items-center gap-1">
            {group && (
              <button
                type="button"
                aria-expanded={open}
                aria-label={`${open ? "Collapse" : "Expand"} ${label}`}
                onClick={() => toggle(node.id)}
                className="-ml-1 rounded-sm p-0.5 text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                <ChevronRight
                  aria-hidden="true"
                  className={cn("size-4 transition-transform", open && "rotate-90")}
                />
              </button>
            )}
            <span className="min-w-0">{label}</span>
          </span>
        </th>
        {valueCells(node.cells, group)}
      </tr>,
    );
    if (open) node.children.forEach(walk);
  };
  grid.rows.forEach(walk);

  return (
    <div>
      {hasGroups && (
        <div className="mb-2 flex justify-end gap-1">
          <Button
            type="button"
            variant="ghost"
            size="xs"
            onClick={() => setExpansion(fresh(true))}
          >
            Expand all
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="xs"
            onClick={() => setExpansion(fresh(false))}
          >
            Collapse all
          </Button>
        </div>
      )}
      <div
        className="relative w-full overflow-auto rounded-md border border-border"
        style={{ maxHeight }}
      >
        <table aria-label={summary} className="w-full border-separate border-spacing-0 text-sm">
          <thead className={cn("sticky top-0 z-[2]", HEAD_BG)}>
            {Array.from({ length: headerRows }, (_, level) => {
              const valueRow = showValueRow && level === headerRows - 1;
              return (
                <tr key={level}>
                  {level === 0 && (
                    <th
                      scope="col"
                      rowSpan={headerRows}
                      className={cn(
                        "sticky left-0 z-[3] whitespace-normal break-words border-b border-border px-2 py-1.5 text-left align-bottom font-medium text-muted-foreground",
                        HEAD_BG,
                      )}
                    >
                      {labels.join(" / ")}
                    </th>
                  )}
                  {valueRow
                    ? Array.from({ length: slots }, (_, s) =>
                        values.map((v, vi) => (
                          <th
                            key={`${s}-${vi}`}
                            scope="col"
                            className={cn(
                              "whitespace-normal break-words border-b border-border px-2 py-1.5 text-right font-medium text-muted-foreground",
                              vi === 0 && s > 0 && "border-l border-border/60",
                            )}
                          >
                            {pivotValueLabel(v)}
                          </th>
                        )),
                      )
                    : [
                        ...headerRuns(grid.columns, level).map((run, r) => (
                          <th
                            key={r}
                            scope="colgroup"
                            colSpan={run.span * values.length}
                            className={cn(
                              "max-w-[12rem] whitespace-normal break-words border-b border-border px-2 py-1.5 font-medium",
                              values.length > 1 || level < columns.length - 1
                                ? "text-center"
                                : "text-right",
                              r > 0 && "border-l border-border/60",
                            )}
                          >
                            {run.label}
                          </th>
                        )),
                        level === 0 && grid.totalColumn && (
                          <th
                            key="total"
                            scope="colgroup"
                            rowSpan={columns.length}
                            colSpan={values.length}
                            className={cn(
                              "whitespace-nowrap border-b border-l border-border px-2 py-1.5 font-semibold",
                              values.length > 1 ? "text-center" : "text-right",
                            )}
                          >
                            Total
                          </th>
                        ),
                      ]}
                </tr>
              );
            })}
          </thead>
          <tbody>{body}</tbody>
          <tfoot className={cn("sticky bottom-0 z-[2]", TOTAL_BG)}>
            <tr data-pivot-total="">
              <th
                scope="row"
                className={cn(
                  "sticky left-0 z-[3] whitespace-nowrap border-t-2 border-border px-2 py-1.5 text-left font-semibold",
                  TOTAL_BG,
                )}
              >
                Grand total
              </th>
              {valueCells(grid.total, true, "border-t-2 border-border")}
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  );
}
