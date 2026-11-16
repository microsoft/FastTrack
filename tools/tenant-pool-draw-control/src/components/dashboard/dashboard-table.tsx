import {
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  type ColumnDef,
} from "@tanstack/react-table";
import {
  ArrowDown,
  ArrowUp,
  ArrowUpDown,
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  CircleCheck,
  TriangleAlert,
} from "lucide-react";
import { useMemo, type CSSProperties, type ReactNode } from "react";

import "@/components/dashboard/dashboard-table.css";
import { ChartCard } from "@/components/dashboard/chart-card";
import { useReportChartIssues } from "@/components/dashboard/chart-hooks";
import { Button } from "@/components/ui/button";
import { TableColumnResizeHandle } from "@/components/ui/table-column-resize-handle";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { maskEmailsRow, type TileSources, type TileSourceStats } from "@/lib/dashboard-data";
import { tableExport } from "@/lib/dashboard-charts";
import {
  checkTableFormat,
  colorScaleBackground,
  dataBarColor,
  dataBarExtent,
  formatDomain,
  matchRule,
  TONE_LABEL,
  type CellFormat,
  type CellTone,
  type FormatDomain,
} from "@/lib/dashboard-table-format";
import { cn } from "@/lib/utils";

// The text colour of a matched rule comes from dashboard-table.css, which
// follows OS dark mode as well as a `.dark` class; Tailwind's `dark:` sees only
// the class.
const TONE_CLASS: Record<CellTone, string> = {
  good: "bg-emerald-500/10 dashboard-tone-good",
  warn: "bg-amber-500/10 dashboard-tone-warn",
  bad: "bg-destructive/10 dashboard-tone-bad",
};

const TONE_ICON = { good: CircleCheck, warn: TriangleAlert, bad: CircleAlert };

// The look one cell takes from its column's format: a class and background
// for the cell, a data bar drawn behind its text, and a rule's icon before it.
function formattedCell(
  value: unknown,
  format: CellFormat | undefined,
  domain: FormatDomain | null,
): {
  className?: string;
  style?: CSSProperties;
  bar?: ReactNode;
  prefix?: ReactNode;
} {
  if (!format) return {};
  if (format.kind === "dataBar") {
    const bar = dataBarExtent(value, domain);
    if (!bar) return {};
    return {
      className: "relative",
      bar: (
        <span
          aria-hidden="true"
          data-bar={bar.negative ? "negative" : "positive"}
          className="pointer-events-none absolute inset-y-1.5"
          style={{
            left: `${bar.left}%`,
            width: `${bar.width}%`,
            background: dataBarColor(bar.negative),
          }}
        />
      ),
    };
  }
  if (format.kind === "colorScale") {
    const background = colorScaleBackground(value, format, domain);
    // A translucent colour, so the row's hover and selected colour shows through it.
    return background ? { style: { background } } : {};
  }
  if (format.kind !== "rules" || !Array.isArray(format.rules)) return {};
  const rule = matchRule(value, format.rules);
  if (!rule) return {};
  const Icon = TONE_ICON[rule.tone];
  return {
    className: TONE_CLASS[rule.tone],
    prefix: (
      <>
        <Icon aria-hidden="true" className="mr-1 inline size-3.5 align-[-2px]" />
        <span className="sr-only">
          {typeof rule.label === "string" ? rule.label : TONE_LABEL[rule.tone]}:{" "}
        </span>
      </>
    ),
  };
}

// Columns accept TanStack's sorting, sizing and enableResizing options.
export function DashboardTable<T>({
  title,
  columns,
  data,
  loading,
  refreshing,
  error,
  pageSize = 10,
  emptyMessage = "No rows for this selection",
  onRetry,
  source,
  sourceStats,
  className,
}: {
  title: string;
  columns: ColumnDef<T, unknown>[];
  data: T[];
  loading?: boolean;
  // A fetch is running while rows are already shown (the query's `isFetching`).
  refreshing?: boolean;
  error?: string | null;
  pageSize?: number;
  emptyMessage?: string;
  // Shown as a Retry button in the error state only.
  onRetry?: () => void;
  // The query's descriptor, the same constant its fetch reads.
  source?: TileSources;
  sourceStats?: TileSourceStats;
  className?: string;
}) {
  // Free text (incident titles, comments) can carry email addresses; every
  // string in a row's fields and their plain nesting is masked before any cell,
  // custom renderer or tooltip sees it. The "View Query" popover shows the
  // request the app sent, as sent: it is the app's own query, not row data.
  const rows = useMemo(() => data.map(maskEmailsRow), [data]);
  const rowsPerPage = Number.isFinite(pageSize) ? Math.max(1, Math.floor(pageSize)) : 10;
  const table = useReactTable({
    data: rows,
    columns,
    defaultColumn: { size: 180, minSize: 72, maxSize: 800 },
    columnResizeMode: "onChange",
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageIndex: 0, pageSize: rowsPerPage } },
  });
  // Read on every render: the table instance is stable while its sorting and
  // rows change, so a memo keyed on it would export stale data.
  const exportTable = tableExport(table);
  const pageCount = table.getPageCount();

  // Scales span every row, not the page, so a value looks the same on any
  // page and in any sort order.
  // Memoized on the rows and columns, so a sort, page or resize does not
  // re-read every value.
  const coreRows = table.getCoreRowModel().rows;
  const leafColumns = table.getAllLeafColumns();
  const { domains, issues } = useMemo(() => {
    const formatted = leafColumns.flatMap((column) => {
      const format = column.columnDef.meta?.format;
      return format
        ? [
            {
              id: column.id,
              label:
                typeof column.columnDef.header === "string"
                  ? column.columnDef.header
                  : column.id,
              format,
              values: coreRows.map((row) => row.getValue(column.id)),
            },
          ]
        : [];
    });
    return {
      domains: new Map(
        formatted.map((c) => [
          c.id,
          c.format.kind === "dataBar" || c.format.kind === "colorScale"
            ? formatDomain(c.values)
            : null,
        ]),
      ),
      issues: checkTableFormat(formatted, (i) => formatted[i].values),
    };
  }, [coreRows, leafColumns]);
  useReportChartIssues("DashboardTable", issues);

  return (
    <ChartCard
      title={title}
      loading={loading}
      refreshing={refreshing}
      error={error}
      empty={data.length === 0}
      emptyMessage={emptyMessage}
      onRetry={onRetry}
      exportTable={exportTable}
      source={source}
      sourceStats={sourceStats}
      className={className}
    >
      <div className="overflow-x-auto">
        <Table className="table-fixed" style={{ width: table.getTotalSize() }}>
          <colgroup>
            {table.getVisibleLeafColumns().map((column) => (
              <col key={column.id} style={{ width: column.getSize() }} />
            ))}
          </colgroup>
          <TableHeader>
            {table.getHeaderGroups().map((group) => (
              <TableRow key={group.id}>
                {group.headers.map((header) => {
                  const sorted = header.column.getIsSorted();
                  const content = header.isPlaceholder
                    ? null
                    : flexRender(
                        header.column.columnDef.header,
                        header.getContext(),
                      );
                  return (
                    <TableHead
                      key={header.id}
                      colSpan={header.colSpan}
                      className="relative overflow-hidden pr-4"
                      aria-sort={
                        sorted === "asc"
                          ? "ascending"
                          : sorted === "desc"
                            ? "descending"
                            : undefined
                      }
                    >
                      {header.column.getCanSort() && !header.isPlaceholder ? (
                        <Button
                          variant="ghost"
                          size="xs"
                          className="-ml-2 max-w-full"
                          onClick={header.column.getToggleSortingHandler()}
                        >
                          <span className="truncate">{content}</span>
                          {sorted === "asc" ? (
                            <ArrowUp aria-hidden="true" />
                          ) : sorted === "desc" ? (
                            <ArrowDown aria-hidden="true" />
                          ) : (
                            <ArrowUpDown
                              aria-hidden="true"
                              className="opacity-50"
                            />
                          )}
                        </Button>
                      ) : (
                        content
                      )}
                      {!header.isPlaceholder &&
                        !header.subHeaders.length &&
                        header.column.getCanResize() && (
                          <TableColumnResizeHandle
                            label={`Resize ${typeof content === "string" ? content : header.column.id} column`}
                            size={header.column.getSize()}
                            minSize={header.column.columnDef.minSize ?? 72}
                            maxSize={header.column.columnDef.maxSize ?? 800}
                            resizing={header.column.getIsResizing()}
                            onResizeStart={header.getResizeHandler()}
                            onResize={(size) =>
                              table.setColumnSizing((current) => ({
                                ...current,
                                [header.column.id]: size,
                              }))
                            }
                            onReset={() => header.column.resetSize()}
                          />
                        )}
                    </TableHead>
                  );
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.map((row) => (
              <TableRow key={row.id}>
                {row.getVisibleCells().map((cell) => {
                  const value = cell.getValue();
                  const look = formattedCell(
                    value,
                    cell.column.columnDef.meta?.format,
                    domains.get(cell.column.id) ?? null,
                  );
                  return (
                    <TableCell
                      key={cell.id}
                      className={look.className}
                      style={look.style}
                    >
                      {look.bar}
                      {/* Cells never wrap, so long text is clipped here instead of
                          spilling over the next column; the full value is the hover title. */}
                      <div
                        className={cn(
                          "overflow-hidden text-ellipsis",
                          look.bar && "relative",
                        )}
                        title={
                          typeof value === "string" || typeof value === "number"
                            ? String(value)
                            : undefined
                        }
                      >
                        {look.prefix}
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext(),
                        )}
                      </div>
                    </TableCell>
                  );
                })}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
      {pageCount > 1 && (
        <nav
          aria-label={`${title} pages`}
          className="flex items-center justify-end gap-2 pt-3 text-sm text-muted-foreground"
        >
          <span>
            Page {table.getState().pagination.pageIndex + 1} of {pageCount}
          </span>
          <Button
            variant="outline"
            size="icon-sm"
            aria-label="Previous page"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
          >
            <ChevronLeft aria-hidden="true" />
          </Button>
          <Button
            variant="outline"
            size="icon-sm"
            aria-label="Next page"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
          >
            <ChevronRight aria-hidden="true" />
          </Button>
        </nav>
      )}
    </ChartCard>
  );
}
