import { useEffect, useState, type ReactNode } from "react";

import "@/components/dashboard/dashboard-theme.css";
import { FreshnessBadge } from "@/components/dashboard/freshness-badge";
import { setQueryCacheEnabled } from "@/lib/query-cache";
import { queryClient } from "@/lib/query-client";
import type { DashboardTimeZone } from "@/lib/dashboard-time-zone";
import { RefreshButton } from "@/components/dashboard/refresh-button";
import { cn } from "@/lib/utils";

// A cached query can answer a refetch in a few milliseconds; the header reads
// as refreshing for at least this long after a click so the click is visible.
const MIN_REFRESH_FEEDBACK_MS = 800;

// Outer frame of a dashboard page: the scoped dashboard theme, a tinted
// full-height canvas, a centred max width and even spacing between sections.
// `savedData` saves the tiles' `meta: { persist: true }` results in the
// viewer's browser (src/lib/query-cache.ts); without it, saved data an
// earlier version left is deleted.
export function DashboardPage({
  children,
  className,
  savedData = false,
}: {
  children: ReactNode;
  className?: string;
  savedData?: boolean;
}) {
  // During render, so the cache is listening before the tiles below fetch.
  setQueryCacheEnabled(savedData, queryClient);
  return (
    <div className={cn("dashboard-root min-h-full", className)}>
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 p-4 sm:p-6">
        {children}
      </div>
    </div>
  );
}

// 12-column dashboard grid: one column on small screens, 12 from `lg`. Each
// child sets its width with `lg:col-span-*` (KPI: 3, half: 6, full: 12). A
// child without one gets a default from dashboard-theme.css: a KpiCard spans
// 3 (four across), anything else spans the full row.
export function DashboardGrid({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      data-dashboard-grid=""
      className={cn("grid grid-cols-1 gap-4 lg:grid-cols-12", className)}
    >
      {children}
    </div>
  );
}

// Page title row for a dashboard: title and optional description on the left;
// on the right ONE cluster: the icon buttons in a row (refresh, then `actions`,
// i.e. CopyLinkButton) with the page's freshness under them ("Updated 3 minutes
// ago", "Refreshing…" while a refresh runs, and for at least
// MIN_REFRESH_FEEDBACK_MS after a click). The cluster is the page's only
// freshness; tiles carry none. Spread `dashboardRefresh(queries)` into it.
export function DashboardHeader({
  title,
  description,
  refreshedAt,
  refreshing = false,
  onRefresh,
  actions,
  timeZone,
}: {
  title: string;
  description?: string;
  refreshedAt?: Date | string | number | null;
  refreshing?: boolean;
  // Omit on a page with no live query (sample data never changes).
  onRefresh?: () => void;
  actions?: ReactNode;
  timeZone?: DashboardTimeZone;
}) {
  const [held, setHeld] = useState(false);
  useEffect(() => {
    if (!held) return;
    const id = setTimeout(() => setHeld(false), MIN_REFRESH_FEEDBACK_MS);
    return () => clearTimeout(id);
  }, [held]);
  const busy = refreshing || held;
  return (
      <header className="flex flex-wrap items-start justify-between gap-x-4 gap-y-2">
        <div className="min-w-0 space-y-1">
          <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
          {description && (
            <p className="text-sm text-muted-foreground">{description}</p>
          )}
        </div>
        <div className="flex flex-col items-end gap-1">
          <div className="flex items-center gap-2">
            {onRefresh && (
              <RefreshButton
                onRefresh={() => {
                  setHeld(true);
                  onRefresh();
                }}
                refreshing={busy}
              />
            )}
            {actions}
          </div>
          {onRefresh && (
            <span aria-live="polite" className="text-xs text-muted-foreground empty:hidden">
              {busy && "Refreshing…"}
            </span>
          )}
          {!busy && <FreshnessBadge refreshedAt={refreshedAt} timeZone={timeZone} />}
        </div>
      </header>
  );
}
