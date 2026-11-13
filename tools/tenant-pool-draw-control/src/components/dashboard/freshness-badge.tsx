import { useEffect, useState } from "react";
import { formatDistanceToNow } from "date-fns";
import { Clock } from "lucide-react";

import { toDateValue } from "@/lib/dashboard-data";
import { dashboardTimeZoneLabel, formatTemporalValue, type DashboardTimeZone } from "@/lib/dashboard-time-zone";
import { cn } from "@/lib/utils";

// "Updated 3 minutes ago", with the absolute time on hover. Renders nothing
// when there is no timestamp. Re-renders once a minute so the text stays true.
// A numeric `refreshedAt` is epoch milliseconds (TanStack Query's
// `dataUpdatedAt`); multiply Unix seconds by 1000 first.
export function FreshnessBadge({
  refreshedAt,
  className,
  timeZone,
}: {
  refreshedAt: Date | string | number | null | undefined;
  className?: string;
  timeZone?: DashboardTimeZone;
}) {
  const date = toDateValue(refreshedAt);
  const time = date ? date.getTime() : null;
  const [, setTick] = useState(0);

  useEffect(() => {
    if (time === null) return;
    const id = setInterval(() => setTick((t) => t + 1), 60_000);
    return () => clearInterval(id);
  }, [time]);

  if (!date) return null;
  // A timestamp slightly in the future (clock skew) reads as "just now".
  const shown = date.getTime() > Date.now() ? new Date() : date;
  return (
    <time
      dateTime={date.toISOString()}
      title={formatTemporalValue(date, "PPpp", timeZone ?? "local", "instant") +
        (timeZone ? ` ${dashboardTimeZoneLabel(timeZone)}` : "")}
      className={cn(
        "inline-flex items-center gap-1 text-xs text-muted-foreground",
        className,
      )}
    >
      <Clock className="size-3" aria-hidden="true" />
      Updated {formatDistanceToNow(shown, { addSuffix: true })}
    </time>
  );
}
