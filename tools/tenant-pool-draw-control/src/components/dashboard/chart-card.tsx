import { useCallback, useMemo, useRef, useState, type ReactNode } from "react";
import { ChartColumn } from "lucide-react";

import {
  ChartCardMenu,
  ChartTableProvider,
} from "@/components/dashboard/chart-extras";
import {
  ChartHeaderSlotContext,
  ChartTableViewContext,
} from "@/components/dashboard/chart-hooks";
import { SlowQueryHint } from "@/components/dashboard/slow-query-hint";
import { EmptyState, ErrorState } from "@/components/states";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/ui/spinner";
import type { ChartTable } from "@/lib/dashboard-charts";
import { tileSourcesOrNone, type TileSources, type TileSourceStats } from "@/lib/dashboard-data";
import { cn } from "@/lib/utils";

// Card frame for one chart or table: title, description and actions in the
// header (the page's freshness is the DashboardHeader's alone); loading, error and empty states replace the body
// (in that order of precedence), so a chart never renders on bad data.
// `refreshing` (a refetch over data already shown) keeps the body, dims it and
// spins a small indicator in the header, so a refresh is visible per tile.
// Any dashboard chart inside (TrendChart, ComboChart, BarBreakdown,
// ShareChart, TreemapChart, FunnelChart, ScatterChart, SankeyChart,
// SunburstChart) hands the card its data,
// and the header's "⋮" menu then offers "View data" (the first chart's table in a
// popover, in place of a table under its plot; any other chart in the card keeps
// its table under its plot) and Download PNG / CSV; a TrendChart's
// chart-type menu sits left of "⋮" (the first TrendChart's only, when a card
// holds several: the others keep theirs above their plots).
// `source` puts "View Query" in the "⋮" menu, in every state; it opens a
// popover with where the data came from and the request that fetched it;
// `sourceStats` adds what the fetch loaded; it is withheld while a loading or
// error state replaces the body.
export function ChartCard({
  title,
  description,
  loading,
  refreshing,
  error,
  empty,
  emptyMessage = "No data for this selection",
  actions,
  slowAfterMs,
  onRetry,
  exportTable,
  source: sourceProp,
  sourceStats,
  children,
  className,
}: {
  title: string;
  description?: string;
  loading?: boolean;
  // A fetch is running while data is already shown (the query's `isFetching`).
  refreshing?: boolean;
  error?: string | null;
  empty?: boolean;
  emptyMessage?: string;
  actions?: ReactNode;
  // How long a load runs before "Running query… N s" appears (default 5 s).
  slowAfterMs?: number;
  // Shown as a Retry button in the error state only; never put Retry in `actions`.
  onRetry?: () => void;
  // The data offered as CSV when the card's content is not one of the
  // dashboard charts (which supply their own).
  exportTable?: ChartTable | null;
  // The query's descriptor, the same constant its fetch reads.
  source?: TileSources;
  sourceStats?: TileSourceStats;
  children: ReactNode;
  className?: string;
}) {
  const source = tileSourcesOrNone(sourceProp);
  const cardRef = useRef<HTMLDivElement>(null);
  const [chartTable, setChartTable] = useState<ChartTable | null>(null);
  const [viewClaims, setViewClaims] = useState<{ id: string; table: ChartTable }[]>([]);
  // Like the header slot below: a claim keeps the place of its first one, so a
  // chart whose table changes keeps "View data".
  const viewOrder = useRef(new Map<string, number>());
  const claimTableView = useCallback((id: string, claimed: ChartTable) => {
    const order = viewOrder.current;
    if (!order.has(id)) order.set(id, order.size);
    setViewClaims((claims) =>
      [...claims.filter((c) => c.id !== id), { id, table: claimed }].sort(
        (a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0),
      ),
    );
    return () => setViewClaims((claims) => claims.filter((c) => c.id !== id));
  }, []);
  const viewOwner = viewClaims[0] ?? null;
  const tableView = useMemo(
    () => ({ owner: viewOwner?.id ?? null, claim: claimTableView }),
    [viewOwner?.id, claimTableView],
  );
  const [headerSlot, setHeaderSlot] = useState<HTMLSpanElement | null>(null);
  const [slotClaims, setSlotClaims] = useState<string[]>([]);
  // Each chart keeps the place of its first claim, so one that lets go and
  // claims again (its data error clears) takes the header back.
  const claimOrder = useRef(new Map<string, number>());
  const claimSlot = useCallback((id: string) => {
    const order = claimOrder.current;
    if (!order.has(id)) order.set(id, order.size);
    setSlotClaims((claims) =>
      [...claims, id].sort((a, b) => (order.get(a) ?? 0) - (order.get(b) ?? 0)),
    );
    return () => setSlotClaims((claims) => claims.filter((c) => c !== id));
  }, []);
  const slotOwner = slotClaims[0] ?? null;
  const slot = useMemo(
    () => ({ element: headerSlot, owner: slotOwner, claim: claimSlot }),
    [headerSlot, slotOwner, claimSlot],
  );
  // The CSV follows the table View data shows; a card whose charts all opted
  // out of a shown table still downloads the last one registered.
  const table = exportTable ?? viewOwner?.table ?? chartTable;
  const showing = !loading && !error && !empty;
  const updating = !loading && !!refreshing;
  let body: ReactNode = (
    <ChartHeaderSlotContext.Provider value={slot}>
      <ChartTableViewContext.Provider value={tableView}>
        <ChartTableProvider onTable={setChartTable}>{children}</ChartTableProvider>
      </ChartTableViewContext.Provider>
    </ChartHeaderSlotContext.Provider>
  );
  if (loading) {
    body = (
      <div role="status" aria-label={`Loading ${title}`} className="space-y-2">
        <Skeleton className="h-60 w-full rounded-lg" />
        <SlowQueryHint afterMs={slowAfterMs} />
      </div>
    );
  } else if (error) {
    body = (
      <ErrorState
        title="Couldn't load this view"
        description={error}
        action={
          onRetry && (
            <Button variant="outline" size="sm" onClick={onRetry}>
              Retry
            </Button>
          )
        }
        className="py-10"
      />
    );
  } else if (empty) {
    body = (
      <EmptyState icon={ChartColumn} title={emptyMessage} className="py-10" />
    );
  }

  return (
    <Card ref={cardRef} className={cn("group/tile gap-4", className)}>
      {/* A wrapping row, not CardHeader's `1fr auto` grid: there the actions'
          column takes its full width first and the title collapses to nothing,
          so wide actions (a SegmentedFilter of several metrics) move below the
          title instead, and the title keeps a readable width. */}
      <CardHeader className="flex flex-wrap items-start gap-x-2 gap-y-4">
        <div className="grid min-w-[min(100%,10rem)] flex-[1_1_10rem] gap-2">
          <CardTitle>
            <h3>{title}</h3>
          </CardTitle>
          {description && <CardDescription>{description}</CardDescription>}
        </div>
        {(actions || source || (showing && (table || viewOwner || slotOwner)) || updating) && (
          <CardAction className="-my-2 ml-auto flex max-w-full flex-wrap items-center justify-end gap-1">
            {updating && (
              <Spinner
                aria-label={`Refreshing ${title}`}
                className="mx-1 text-muted-foreground"
              />
            )}
            {actions}
            {showing && slotOwner && (
              <span ref={setHeaderSlot} className="contents" />
            )}
            {(source || (showing && (table || viewOwner))) && (
              <ChartCardMenu
                title={title}
                table={table}
                dataTable={showing ? (viewOwner?.table ?? null) : null}
                download={showing && !!table}
                cardRef={cardRef}
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
        className={cn("transition-opacity", updating && "opacity-60")}
      >
        {body}
      </CardContent>
    </Card>
  );
}
