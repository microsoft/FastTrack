import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import {
  connectorErrorMessage,
  isConnectorPolicyBlock,
} from "@/lib/connector-error";
import { cn } from "@/lib/utils";

// Designed empty / error / loading states. Use these so every zero-data,
// failure, and loading case looks intentional instead of a bare container.

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
}: {
  icon?: LucideIcon;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col items-center gap-3 py-16 text-center",
        className,
      )}
    >
      {Icon && (
        <Icon className="size-10 text-muted-foreground" aria-hidden="true" />
      )}
      <p className="font-medium">{title}</p>
      {description && (
        <p className="max-w-sm text-sm text-muted-foreground">{description}</p>
      )}
      {action}
    </div>
  );
}

export function ErrorState({
  title = "Something went wrong",
  description,
  action,
  className,
}: {
  title?: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col items-center gap-3 py-16 text-center",
        className,
      )}
    >
      <p className="font-medium text-destructive">{title}</p>
      {description && (
        <p className="max-w-sm text-sm text-muted-foreground">{description}</p>
      )}
      {action}
    </div>
  );
}

// The error state for any failed connector call: pass `result.error` (or the
// query error it was rethrown as). A DLP/ACP policy block names the policy;
// anything else stays generic.
export function ConnectorErrorState({
  error,
  connector,
  action,
  className,
}: {
  error: unknown;
  connector: string;
  action?: ReactNode;
  className?: string;
}) {
  const blocked = isConnectorPolicyBlock(error);
  return (
    <ErrorState
      title={blocked ? "Blocked by your organization's policy" : undefined}
      description={connectorErrorMessage(error, connector)}
      action={blocked ? undefined : action}
      className={className}
    />
  );
}

// Generic-shape loading fallback. For a table, card grid, or chart, write a
// Skeleton that MIRRORS the final layout instead — shaped skeletons read as
// intentional; uniform rows everywhere look generic.
export function LoadingState({
  rows = 3,
  className,
}: {
  rows?: number;
  className?: string;
}) {
  return (
    <div
      role="status"
      aria-label="Loading"
      className={cn("space-y-3", className)}
    >
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} className="h-14 w-full rounded-lg" />
      ))}
    </div>
  );
}
