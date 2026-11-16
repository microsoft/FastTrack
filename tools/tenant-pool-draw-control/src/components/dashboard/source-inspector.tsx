import {
  Check,
  Copy,
  Database,
  FileSpreadsheet,
  List,
  Plug,
  Table,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/button";
import {
  tileRequestTarget,
  tileRequestText,
  tileSourceList,
  tileStatsLine,
  type TileRequest,
  type TileSource,
  type TileSources,
  type TileSourceStats,
} from "@/lib/dashboard-data";
import {
  highlightQuery,
  type QueryLanguage,
  type QueryTokenKind,
} from "@/lib/query-highlight";

// Keyed by the bare connector id in `ms.config.json` (an ARM path such as
// `/providers/Microsoft.PowerApps/apis/shared_sql` resolves by its last segment),
// never by a cluster or server name; an id not listed here shows a plug icon and
// the id itself.
const CONNECTOR_DISPLAY: Record<string, { icon: LucideIcon; label: string }> = {
  shared_kusto: { icon: Database, label: "Azure Data Explorer" },
  shared_sql: { icon: Database, label: "SQL Server" },
  shared_commondataserviceforapps: { icon: Table, label: "Dataverse" },
  shared_sharepointonline: { icon: List, label: "SharePoint" },
  shared_excelonlinebusiness: { icon: FileSpreadsheet, label: "Excel" },
  // Not a connector: a file bundled into the app.
  embedded: { icon: FileSpreadsheet, label: "Bundled file" },
};

const REQUEST_LABEL: Record<TileRequest["kind"], string> = {
  kql: "KQL query",
  sql: "SQL query",
  fetchxml: "FetchXML query",
  operation: "Request",
  sqlite: "SQL query (SQLite, in your browser)",
  embedded: "Bundled data",
};

const COPIED_MS = 1500;

const REQUEST_LANGUAGE: Partial<Record<TileRequest["kind"], QueryLanguage>> = {
  kql: "kql",
  sql: "sql",
  fetchxml: "xml",
  sqlite: "sql",
};

// The page is dark under an explicit `.dark` class or, with no `.light` class,
// under the OS preference (index.css mirrors the dark theme there); `dark:`
// sees only the class, so each colour names the OS case too.
const TOKEN_CLASS: Record<QueryTokenKind, string | undefined> = {
  plain: undefined,
  keyword:
    "text-blue-700 dark:text-blue-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-blue-300",
  function:
    "text-violet-700 dark:text-violet-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-violet-300",
  string:
    "text-emerald-700 dark:text-emerald-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-emerald-300",
  number:
    "text-amber-700 dark:text-amber-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-amber-300",
  comment: "text-muted-foreground italic",
  pipe: "font-semibold text-pink-700 dark:text-pink-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-pink-300",
  tag: "text-blue-700 dark:text-blue-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-blue-300",
  attr: "text-violet-700 dark:text-violet-300 [@media(prefers-color-scheme:dark)]:[:root:not(.light)_&]:text-violet-300",
};

function QueryCode({ text, language }: { text: string; language?: QueryLanguage }) {
  if (!language) return text;
  return highlightQuery(text, language).map((token, index) => {
    const className = TOKEN_CLASS[token.kind];
    return className ? (
      <span key={index} className={className}>
        {token.text}
      </span>
    ) : (
      token.text
    );
  });
}

function connectorDisplay(connector: string): {
  icon: LucideIcon;
  label: string;
} {
  const id = connector.slice(connector.lastIndexOf("/") + 1);
  // Own keys only: `toString` or `__proto__` must reach the fallback too.
  return Object.hasOwn(CONNECTOR_DISPLAY, id)
    ? CONNECTOR_DISPLAY[id]
    : { icon: Plug, label: connector };
}

// A tile's data sources, one block per read: the connector and optional system
// label, where the request went, the request itself (copyable, as sent) and any
// work done in the browser after it returned. Stats describe the tile as a whole.
export function SourceDetails({
  title,
  source,
  stats,
  refreshing,
}: {
  title: string;
  source: TileSources;
  stats?: TileSourceStats;
  refreshing?: boolean;
}) {
  const sources = tileSourceList(source);
  const statsLine = tileStatsLine(stats);
  return (
    <div className="space-y-3" data-slot="tile-source-details">
      {sources.map((one, index) => (
        <OneSource
          key={index}
          source={one}
          copyLabel={
            sources.length > 1
              ? `Copy request ${index + 1} of ${sources.length} for ${title}`
              : `Copy the request for ${title}`
          }
          divided={index > 0}
        />
      ))}
      {statsLine && (
        <p data-slot="tile-source-stats" className="text-xs text-muted-foreground">
          {statsLine}
        </p>
      )}
      {refreshing && (
        <p data-slot="tile-source-refreshing" className="text-xs text-muted-foreground">
          Refreshing: the tile is reading its data again.
        </p>
      )}
    </div>
  );
}

function OneSource({
  source,
  copyLabel,
  divided,
}: {
  source: TileSource;
  copyLabel: string;
  divided: boolean;
}) {
  const { icon: Icon, label } = connectorDisplay(source.connector);
  const language = REQUEST_LANGUAGE[source.request.kind];
  const text = tileRequestText(source.request);
  const target = tileRequestTarget(source.request);
  // Each attempt gets its own number, so a repeat restarts the timer and a write
  // that finishes after a newer attempt, or after the request changed, shows nothing.
  const [feedback, setFeedback] = useState<{
    attempt: number;
    text: string;
    status: "copied" | "failed";
  } | null>(null);
  const attempts = useRef(0);

  useEffect(() => {
    if (!feedback) return;
    const timer = setTimeout(() => setFeedback(null), COPIED_MS);
    return () => clearTimeout(timer);
  }, [feedback]);

  const copy = async () => {
    const attempt = ++attempts.current;
    const sent = text;
    let status: "copied" | "failed" = "copied";
    try {
      await navigator.clipboard.writeText(sent);
    } catch (error: unknown) {
      // warn, not error: console.error lines fail the pre-deploy gate.
      console.warn("SourceDetails: copying the request failed", error);
      status = "failed";
    }
    if (attempt === attempts.current) setFeedback({ attempt, text: sent, status });
  };
  const copied = feedback && feedback.text === text ? feedback.status : "idle";

  const system = source.system?.trim();

  return (
    <div
      className={divided ? "space-y-3 border-t pt-3" : "space-y-3"}
      data-slot="tile-source-entry"
    >
      <div className="flex items-center gap-2">
        <span className="flex size-8 shrink-0 items-center justify-center rounded-md bg-muted">
          <Icon aria-hidden="true" className="size-4" />
        </span>
        <div className="min-w-0">
          <p className="font-medium" data-slot="tile-source-connector">
            {label}
            {system && system.toLowerCase() !== label.toLowerCase() && (
              <span
                data-slot="tile-source-system"
                className="ml-2 rounded bg-primary/10 px-1.5 py-0.5 text-xs font-medium text-primary"
              >
                {system}
              </span>
            )}
          </p>
          <p
            data-slot="tile-source-target"
            className="truncate text-xs text-muted-foreground"
            title={target}
          >
            {target}
          </p>
        </div>
      </div>
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <p className="text-xs font-medium text-muted-foreground">
            {REQUEST_LABEL[source.request.kind]}
          </p>
          <Button
            variant="ghost"
            size="xs"
            aria-label={
              copied === "copied"
                ? "Copied"
                : copied === "failed"
                  ? "Copy failed; select the request to copy it"
                  : copyLabel
            }
            onClick={() => void copy()}
          >
            {copied === "copied" ? <Check aria-hidden="true" /> : <Copy aria-hidden="true" />}
            {copied === "copied" ? "Copied" : copied === "failed" ? "Copy failed" : "Copy"}
          </Button>
        </div>
        <pre
          data-slot="tile-source-request"
          className="max-h-80 overflow-auto rounded-md border bg-muted/60 px-3 py-2 font-mono text-xs leading-relaxed whitespace-pre [tab-size:2]"
        >
          <code>
            <QueryCode text={text} language={language} />
          </code>
        </pre>
      </div>
      {source.computed && (
        <p data-slot="tile-source-computed" className="text-xs text-muted-foreground">
          {source.computed}
        </p>
      )}
    </div>
  );
}
