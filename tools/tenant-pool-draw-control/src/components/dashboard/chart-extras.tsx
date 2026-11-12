import {
  CodeXml,
  Download,
  EllipsisVertical,
  Table as TableIcon,
  X,
} from "lucide-react";
import {
  useContext,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
  type RefObject,
} from "react";

import { BrowserTotalsWarning } from "@/components/dashboard/browser-totals-notice";
import {
  ChartTableContext,
  ChartTableViewContext,
} from "@/components/dashboard/chart-hooks";
import { SourceDetails } from "@/components/dashboard/source-inspector";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Popover,
  PopoverAnchor,
  PopoverContent,
} from "@/components/ui/popover";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  exportFileName,
  formatTableCell,
  tableToCsv,
  type ChartIssues,
  type ChartTable,
} from "@/lib/dashboard-charts";
import {
  tileSourcesOrNone,
  type TileSources,
  type TileSourceStats,
} from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// The pieces every dashboard chart shares: its data as a table, the notice
// that replaces a chart its data cannot draw, and the card's "⋮" menu (data
// source, CSV / PNG export).

// The zone a time-of-day axis is drawn in, under the plot ("Times in PDT"),
// so a reader comparing with UTC log data knows which clock the axis shows.
export function TimeZoneNote({ zone }: { zone: string }) {
  return (
    <p data-slot="chart-time-zone" className="text-xs text-muted-foreground">
      Times in {zone}
    </p>
  );
}

// The chart's numbers as a real table: screen readers and anyone checking an
// exact value read it instead of the SVG. Inside a ChartCard the first such
// table is not drawn here: the card's "⋮" menu opens it in a popover
// ("View data"). Any other table, in a card or not, stays collapsed under its plot.
export function ChartDataTable({
  table,
  label = "View data",
}: {
  table: ChartTable;
  label?: string;
}) {
  const view = useContext(ChartTableViewContext);
  const id = useId();
  const key = table.rows.length > 0 ? JSON.stringify(table) : "";
  const claim = view?.claim;
  useLayoutEffect(() => {
    if (!claim || !key) return;
    return claim(id, JSON.parse(key) as ChartTable);
  }, [claim, id, key]);
  // In a card nothing is drawn until the claims settle (an owner is known), so
  // the owner's table never flashes under its plot.
  if (!key || (view && (view.owner === null || view.owner === id))) return null;
  return (
    <details className="group mt-3 text-sm" data-pdf-exclude="">
      <summary className="cursor-pointer text-muted-foreground select-none hover:text-foreground">
        {label}
      </summary>
      <DataTableView table={table} className="mt-2" />
    </details>
  );
}

function DataTableView({
  table,
  className,
}: {
  table: ChartTable;
  className?: string;
}) {
  return (
      <div className={cn("max-h-72 overflow-auto rounded-md border", className)}>
        <Table>
          <TableHeader>
            <TableRow>
              {table.columns.map((column, i) => (
                <TableHead
                  key={`${column.label}-${i}`}
                  scope="col"
                  className={cn(i > 0 && column.kind !== "text" && "text-right")}
                >
                  {column.label}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {table.rows.map((row, r) => (
              <TableRow key={r}>
                {row.map((cell, i) => {
                  const column = table.columns[i];
                  const text = formatTableCell(cell, column);
                  return i === 0 ? (
                    <TableHead key={i} scope="row" className="font-normal">
                      {text}
                    </TableHead>
                  ) : (
                    <TableCell
                      key={i}
                      className={cn(
                        column.kind !== "text" && "text-right tabular-nums",
                      )}
                    >
                      {text}
                    </TableCell>
                  );
                })}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
  );
}

// Drawn in place of a chart whose data cannot be plotted honestly (a key
// missing from the rows, text where numbers belong), so a wrong key shows as
// a message instead of an empty axis.
export function ChartProblem({ issues }: { issues: ChartIssues }) {
  return (
    <div
      role="alert"
      className="rounded-md border border-destructive/40 bg-destructive/5 px-3 py-4 text-sm"
    >
      <p className="font-medium text-destructive">Can't draw this chart</p>
      <ul className="mt-1 list-disc pl-5 text-muted-foreground">
        {issues.errors.map((error) => (
          <li key={error}>{error}</li>
        ))}
      </ul>
    </div>
  );
}

export function ChartTableProvider({
  onTable,
  children,
}: {
  onTable: (table: ChartTable | null) => void;
  children: ReactNode;
}) {
  return (
    <ChartTableContext.Provider value={onTable}>
      {children}
    </ChartTableContext.Provider>
  );
}

function download(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.style.display = "none";
  document.body.append(link);
  link.click();
  link.remove();
  // FileSaver's interval: a slow device may not have read a large blob after 1s.
  setTimeout(() => URL.revokeObjectURL(url), 40_000);
}

function downloadCsv(table: ChartTable, title: string) {
  // The byte-order mark makes Excel read the file as UTF-8.
  download(
    new Blob(["\uFEFF", tableToCsv(table)], { type: "text/csv;charset=utf-8" }),
    exportFileName(title, "csv"),
  );
}

async function downloadPng(card: HTMLElement, title: string) {
  const { default: html2canvas } = await import("html2canvas-pro");
  const canvas = await html2canvas(card, {
    backgroundColor: getComputedStyle(card).backgroundColor || "#ffffff",
    scale: 2,
    logging: false,
    ignoreElements: (element) => element.hasAttribute("data-pdf-exclude"),
    onclone: (document, clonedCard) => {
      for (const marker of Array.from(clonedCard.querySelectorAll<HTMLElement>("[data-chart-export-zone]"))) {
        const zone = marker.dataset.chartExportZone;
        if (zone) {
          const note = document.createElement("p");
          note.className = "text-xs text-muted-foreground";
          note.textContent = `Times in ${zone}`;
          marker.after(note);
        }
      }
    },
  });
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/png"),
  );
  if (blob) download(blob, exportFileName(title, "png"));
}

// The tile's header controls ("⋮" and the chart-type button) stay hidden until
// the pointer is over the tile (`group/tile` on its root) or focus is inside
// it, and while their menu is open. A touch screen has no hover: there they
// always show.
export const TILE_CONTROL_REVEAL =
  "opacity-0 transition-opacity group-hover/tile:opacity-100 group-focus-within/tile:opacity-100 focus-visible:opacity-100 data-[state=open]:opacity-100 pointer-coarse:opacity-100";

// A card's vertical "⋮" menu, shared by chart, table and KPI cards: "View
// Query" (when the card has a `source`) and "View data" (when a chart inside
// has `dataTable` on) each open a popover anchored to the menu button;
// Download PNG / CSV appear while the card shows a chart or table with data. A
// KPI card passes no `cardRef` and no table, so its menu holds only "View Query".
// After "⋮", at the header's right edge, a tile whose browser totals stopped at
// the row cap shows a warning icon; "⋮" keeps its space while hidden, so the
// icon does not move when it is revealed.
export function ChartCardMenu({
  title,
  table = null,
  dataTable = null,
  download = false,
  cardRef,
  source,
  stats,
  refreshing,
}: {
  title: string;
  table?: ChartTable | null;
  dataTable?: ChartTable | null;
  download?: boolean;
  cardRef?: RefObject<HTMLElement | null>;
  source?: TileSources;
  stats?: TileSourceStats;
  refreshing?: boolean;
}) {
  const shown = tileSourcesOrNone(source);
  const data = dataTable && dataTable.rows.length > 0 ? dataTable : null;
  const [panel, setPanel] = useState<"query" | "data" | null>(null);
  // A tile whose source or data goes away closes its popover, so a later one
  // does not reopen it unasked.
  if ((panel === "query" && !shown) || (panel === "data" && !data)) setPanel(null);
  // Set when "View Query" or "View data" is chosen. The popover opens once the
  // menu has closed: opened while the menu still holds focus, the menu's
  // teardown moves focus to the page and the popover dismisses itself as focus
  // left it.
  const opening = useRef<"query" | "data" | null>(null);
  const menuButton = useRef<HTMLButtonElement>(null);
  // Set when the popover is dismissed by a click or focus elsewhere: focus then
  // stays where the user put it instead of returning to "⋮".
  const dismissedOutside = useRef(false);
  return (
    <>
    <Popover open={panel !== null} onOpenChange={(open) => !open && setPanel(null)}>
      <DropdownMenu>
        <PopoverAnchor asChild>
          <DropdownMenuTrigger asChild>
            <Button
              ref={menuButton}
              variant="ghost"
              size="icon-sm"
              aria-label={`More actions for ${title}`}
              data-tile-menu=""
              data-pdf-exclude=""
              // The popover is anchored here, so "⋮" stays shown while it is open.
              className={cn(TILE_CONTROL_REVEAL, panel !== null && "opacity-100")}
            >
              <EllipsisVertical aria-hidden="true" />
            </Button>
          </DropdownMenuTrigger>
        </PopoverAnchor>
        <DropdownMenuContent
          align="end"
          onCloseAutoFocus={(event) => {
            const next = opening.current;
            if (!next) return;
            opening.current = null;
            event.preventDefault();
            setPanel(next);
          }}
        >
          {shown && (
            <DropdownMenuItem
              data-tile-source-trigger=""
              onSelect={() => {
                opening.current = "query";
              }}
            >
              <CodeXml aria-hidden="true" />
              View Query
            </DropdownMenuItem>
          )}
          {data && (
            <DropdownMenuItem
              data-tile-data-trigger=""
              onSelect={() => {
                opening.current = "data";
              }}
            >
              <TableIcon aria-hidden="true" />
              View data
            </DropdownMenuItem>
          )}
          {download && cardRef && (
            <DropdownMenuItem
              onSelect={() => {
                const card = cardRef.current;
                if (!card) return;
                downloadPng(card, title).catch((error: unknown) =>
                  // warn, not error: a failed export is no defect in the app, and
                  // console.error lines fail the pre-deploy gate.
                  console.warn(`ChartCard: PNG export of "${title}" failed`, error),
                );
              }}
            >
              <Download aria-hidden="true" />
              Download PNG
            </DropdownMenuItem>
          )}
          {download && table && (
            <DropdownMenuItem onSelect={() => downloadCsv(table, title)}>
              <Download aria-hidden="true" />
              Download CSV
            </DropdownMenuItem>
          )}
        </DropdownMenuContent>
      </DropdownMenu>
      {(shown || data) && (
        <PopoverContent
          align="end"
          aria-label={panel === "data" ? `Data for ${title}` : `Query for ${title}`}
          className={cn(
            "max-h-(--radix-popover-content-available-height) overflow-y-auto text-sm",
            "w-[min(36rem,calc(100vw-2rem))]",
          )}
          onOpenAutoFocus={() => {
            dismissedOutside.current = false;
          }}
          onInteractOutside={() => {
            dismissedOutside.current = true;
          }}
          // The popover has no trigger of its own; a keyboard close returns focus to "⋮".
          onCloseAutoFocus={(event) => {
            event.preventDefault();
            if (dismissedOutside.current) return;
            menuButton.current?.focus();
          }}
        >
          <div className="mb-3 flex items-center justify-between gap-2">
            <p className="truncate font-medium">{title}</p>
            <Button
              variant="ghost"
              size="icon-sm"
              aria-label="Close"
              data-tile-source-close=""
              className="-my-1 -mr-2 shrink-0"
              onClick={() => setPanel(null)}
            >
              <X aria-hidden="true" />
            </Button>
          </div>
          {panel === "data" && data ? (
            <div data-slot="tile-data-table">
              <DataTableView table={data} />
            </div>
          ) : (
            shown && (
              <SourceDetails
                title={title}
                source={shown}
                stats={stats}
                refreshing={refreshing}
              />
            )
          )}
        </PopoverContent>
      )}
    </Popover>
    <BrowserTotalsWarning title={title} sources={shown} stats={stats} />
    </>
  );
}
