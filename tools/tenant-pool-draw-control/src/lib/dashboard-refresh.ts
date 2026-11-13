// The page-level refresh state a DashboardHeader shows, folded from the page's
// TanStack queries: the oldest successful update (so "Updated 5 minutes ago" is
// true for every tile, so no timestamp while any query has never loaded), whether
// any query is fetching, and one refetch of all.
export type DashboardQuery = {
  dataUpdatedAt: number;
  isFetching: boolean;
  refetch: () => unknown;
};

export type DashboardRefresh = {
  refreshedAt: number | null;
  refreshing: boolean;
  onRefresh: () => void;
};

export function dashboardRefresh(queries: DashboardQuery[]): DashboardRefresh {
  const updated = queries.map((q) => q.dataUpdatedAt);
  return {
    refreshedAt:
      updated.length && updated.every((at) => at > 0)
        ? Math.min(...updated)
        : null,
    refreshing: queries.some((q) => q.isFetching),
    onRefresh: () => {
      for (const query of queries) void query.refetch();
    },
  };
}
