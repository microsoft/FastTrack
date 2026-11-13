import { useId, useState } from "react";
import { ShieldAlert, X } from "lucide-react";

import { useConnectorPolicyBlock } from "@/lib/connector-policy-monitor";

export const CONNECTOR_POLICY_BANNER_TITLE = "Blocked by your organization's policy";
export const CONNECTOR_POLICY_BANNER_TEXT =
  "Some of this app's data connections are blocked by your organization's data policy for this environment. Ask an administrator to allow the connector, then reload the app.";

export function connectorPolicyBannerText(connectors: readonly string[], unnamed = false): string {
  if (connectors.length === 0) return CONNECTOR_POLICY_BANNER_TEXT;
  const names = connectors.join(", ");
  if (unnamed) {
    return `The ${names} ${connectors.length === 1 ? "connector" : "connectors"} and other data connections are blocked by your organization's data policy for this environment. Ask an administrator to allow them, then reload the app.`;
  }
  const subject = connectors.length === 1 ? "connector is" : "connectors are";
  const object = connectors.length === 1 ? "this connector" : "these connectors";
  return `The ${names} ${subject} blocked by your organization's data policy for this environment. Ask an administrator to allow ${object}, then reload the app.`;
}

export function ConnectorPolicyBannerView({
  connectors = [],
  unnamed = false,
  onDismiss,
  defaultOpen = false,
}: {
  connectors?: readonly string[];
  unnamed?: boolean;
  onDismiss?: () => void;
  defaultOpen?: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);
  const detailsId = useId();
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-[60] flex justify-center p-3">
      <div
        role="alert"
        className="pointer-events-auto w-full max-w-2xl rounded-lg border border-destructive/50 bg-card text-sm text-destructive shadow-lg"
      >
        <div className="flex items-center gap-2 px-3 py-2">
          <ShieldAlert aria-hidden="true" className="size-4 shrink-0" />
          <span className="min-w-0 flex-1 truncate font-medium">{CONNECTOR_POLICY_BANNER_TITLE}</span>
          <button
            type="button"
            aria-expanded={open}
            aria-controls={detailsId}
            onClick={() => setOpen((value) => !value)}
            className="shrink-0 rounded-sm px-1 text-xs font-medium underline-offset-2 hover:underline"
          >
            {open ? "See less" : "See more"}
          </button>
          {onDismiss ? (
            <button
              type="button"
              aria-label="Dismiss"
              onClick={onDismiss}
              className="shrink-0 rounded-sm p-1 text-muted-foreground hover:text-foreground"
            >
              <X className="size-4" />
            </button>
          ) : null}
        </div>
        {open ? (
          <div id={detailsId} className="border-t border-destructive/20 px-3 py-2">
            <p className="text-muted-foreground">{connectorPolicyBannerText(connectors, unnamed)}</p>
          </div>
        ) : null}
      </div>
    </div>
  );
}

// Mounted beside <App /> in main.tsx, so it shows over any generated page.
export function ConnectorPolicyBanner() {
  const { blocked, connectors, unnamed } = useConnectorPolicyBlock();
  // Dismiss hides the blocks seen so far; a block on a further connector shows the banner again.
  const seen = connectors.length + (unnamed ? 1 : 0);
  const [dismissedCount, setDismissedCount] = useState<number | null>(null);
  if (!blocked || (dismissedCount !== null && seen <= dismissedCount)) return null;
  return (
    <ConnectorPolicyBannerView
      connectors={connectors}
      unnamed={unnamed}
      onDismiss={() => setDismissedCount(seen)}
    />
  );
}