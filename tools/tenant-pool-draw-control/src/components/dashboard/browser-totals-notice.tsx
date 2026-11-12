import { useState } from "react";
import { TriangleAlert } from "lucide-react";

import { totalsIncomplete } from "@/components/dashboard/browser-totals";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { TileSources, TileSourceStats } from "@/lib/dashboard-data";

// Fixed words, naming no connector, for a tile whose browser totals stopped
// at the row cap (browser-totals.ts). A full single page has no verified
// continuation, so the words say the source may hold more rows, never that it does.
export const BROWSER_TOTALS_TITLE = "Totals may not cover every row";
export const BROWSER_TOTALS_TEXT =
  "This tile loaded as many rows as the dashboard reads from its source (up to " +
  "5,000 per source), and the source may hold more, so totals calculated in your " +
  "browser cover only the loaded rows. For " +
  "exact totals, point the tile at a source that totals the data itself, such as " +
  "a SQL view, a Kusto query or a Power BI semantic model.";

// A warning icon in the tile header, beside "⋮", shown only for that tile.
// Hover or keyboard focus shows the explanation; a click or tap toggles it,
// so it also opens on a touch screen.
export function BrowserTotalsWarning({
  title,
  sources,
  stats,
}: {
  title: string;
  sources: TileSources | undefined;
  stats: TileSourceStats | undefined;
}) {
  const [open, setOpen] = useState(false);
  if (!totalsIncomplete(sources, stats)) return null;
  return (
    <TooltipProvider>
      <Tooltip open={open} onOpenChange={setOpen}>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={`${title}: ${BROWSER_TOTALS_TITLE}`}
            data-browser-totals-warning=""
            className="text-amber-600 hover:text-amber-700 dark:text-amber-400"
            // Radix closes a tooltip on press; a press here toggles it instead.
            onPointerDown={(event) => event.preventDefault()}
            onClick={(event) => {
              event.preventDefault();
              setOpen((was) => !was);
            }}
          >
            <TriangleAlert aria-hidden="true" />
          </Button>
        </TooltipTrigger>
        <TooltipContent
          data-browser-totals-text=""
          className="max-w-xs text-left text-balance leading-relaxed"
        >
          <p className="font-medium">{BROWSER_TOTALS_TITLE}</p>
          <p>{BROWSER_TOTALS_TEXT}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}