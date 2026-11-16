import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

// Structural page region: a consistent heading + description + action slot and
// vertical rhythm. Use instead of ad-hoc `<div className="space-y-4">` wrappers.
// It imposes structure, NOT a visual style — compose freely inside.
export function PageSection({
  title,
  description,
  action,
  children,
  className,
}: {
  title?: ReactNode;
  description?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={cn("space-y-4", className)}>
      {(title || description || action) && (
        <div className="flex items-start justify-between gap-4">
          {(title || description) && (
            <div className="space-y-1">
              {title && (
                <h2 className="text-lg font-semibold tracking-tight">{title}</h2>
              )}
              {description && (
                <p className="text-sm text-muted-foreground">{description}</p>
              )}
            </div>
          )}
          {action}
        </div>
      )}
      {children}
    </section>
  );
}
