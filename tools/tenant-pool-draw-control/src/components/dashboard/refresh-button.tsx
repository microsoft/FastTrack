import { RefreshCw } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

// Icon-only refresh for a DashboardHeader, the same size and variant as
// CopyLinkButton; its name is in the tooltip and aria-label. While a refresh
// runs the icon spins and the button is disabled, so a second click cannot
// queue another round of queries.
export function RefreshButton({
  onRefresh,
  refreshing = false,
  label = "Refresh data",
}: {
  onRefresh: () => void;
  refreshing?: boolean;
  label?: string;
}) {
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <span className="inline-flex" tabIndex={refreshing ? 0 : undefined}>
            <Button
              variant="outline"
              size="icon-sm"
              disabled={refreshing}
              aria-label={label}
              aria-busy={refreshing}
              onClick={onRefresh}
            >
              <RefreshCw
                aria-hidden="true"
                className={cn(refreshing && "animate-spin motion-reduce:animate-none")}
              />
            </Button>
          </span>
        </TooltipTrigger>
        <TooltipContent>{label}</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
