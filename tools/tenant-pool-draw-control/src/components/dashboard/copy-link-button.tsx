import { getContext } from "@microsoft/managed-apps/app";
import { Link2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { isPreviewMount } from "@/lib/app-view-serializer";
import { buildShareLink } from "@/lib/dashboard-url-state";

const APP_ID_TIMEOUT_MS = 5000;
const UNAVAILABLE_HINT = "A link is not available here";

// Icon-only button that copies the published app's link with the page's current
// query string (the filters useUrlFilters keeps there), for a DashboardHeader's
// actions; its name is in the tooltip and aria-label. In the Cowork preview there
// is no published app to link to, so the button stays disabled and the host
// context is never asked for. A host that has not answered within five seconds
// shows the unavailable reason, and a late answer still enables the button.
export function CopyLinkButton({ label = "Copy link" }: { label?: string }) {
  const preview = isPreviewMount(import.meta.env.BASE_URL ?? "./");
  // undefined while the app id is loading, null when it cannot be had.
  const [appId, setAppId] = useState<string | null | undefined>(undefined);

  useEffect(() => {
    if (preview) return;
    let live = true;
    const timer = setTimeout(() => {
      if (live) setAppId((id) => id ?? null);
    }, APP_ID_TIMEOUT_MS);
    Promise.resolve()
      .then(() => (live ? getContext() : undefined))
      .then(
        (context) => {
          clearTimeout(timer);
          if (live) setAppId(context?.app?.appId || null);
        },
        (error: unknown) => {
          clearTimeout(timer);
          // warn, not error: console.error lines fail the pre-deploy gate.
          console.warn("CopyLinkButton: the host context is not available", error);
          if (live) setAppId(null);
        },
      );
    return () => {
      live = false;
      clearTimeout(timer);
    };
  }, [preview]);

  const hint = preview
    ? `${label} is disabled in preview mode`
    : appId === null
      ? UNAVAILABLE_HINT
      : undefined;
  const name = preview ? hint : hint ? `${label} (${hint})` : label;

  const copy = async () => {
    if (!appId) return;
    const link = buildShareLink(appId, new URLSearchParams(window.location.search));
    try {
      await navigator.clipboard.writeText(link);
      toast.success("Link copied");
    } catch (error: unknown) {
      console.warn("CopyLinkButton: copying the link failed", error);
      toast.error("Couldn't copy the link");
    }
  };

  // A disabled button gets no pointer events, so the tooltip hangs off a wrapper
  // that stays focusable while the button is disabled.
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <span className="inline-flex" tabIndex={appId ? undefined : 0}>
            <Button
              variant="outline"
              size="icon-sm"
              disabled={!appId}
              aria-label={name}
              onClick={() => void copy()}
            >
              <Link2 aria-hidden="true" />
            </Button>
          </span>
        </TooltipTrigger>
        <TooltipContent>{hint ?? label}</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
