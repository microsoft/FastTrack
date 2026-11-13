import { tileSourceList, type TileSources, type TileSourceStats } from "@/lib/dashboard-data";

// A tile whose source is a connector operation (no query text) reads raw rows
// and totals them in the browser, whatever the connector, unless the read
// declares `totals: "source"` (the source returned figures it already totalled)
// or `totals: "none"` (no tile totals its rows, a list-only detail table).
export function totalsInBrowser(sources: TileSources | undefined): boolean {
  return (
    !!sources &&
    tileSourceList(sources).some(
      (s) => s.request.kind === "operation" && s.request.totals === undefined,
    )
  );
}

// A browser-totalled tile is flagged only when its read stopped at its row
// cap (`stats.capped`): the source may hold more rows than the page loaded, so
// its totals may be incomplete. A read that loaded every row is not flagged.
export function totalsIncomplete(
  sources: TileSources | undefined,
  stats: TileSourceStats | undefined,
): boolean {
  return stats?.capped === true && totalsInBrowser(sources);
}
