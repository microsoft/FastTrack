import ReactMarkdown, { type Components } from "react-markdown";
import remarkGfm from "remark-gfm";
import { safeUrl } from "@/lib/safe-url";
import { cn } from "@/lib/utils";

// Renders untrusted Markdown (an AgentNode / inline agent answer, an LLM reply,
// a connector's Markdown field) as React elements. LOCKED — app code uses
// `<MarkdownText>` and never imports `react-markdown` or `remark-gfm` itself.
//
// Safety: raw HTML in the source is dropped (never parsed into the DOM), only
// the elements below are rendered, every link passes through `safeUrl()` and
// opens in a new tab without an opener or referrer, and images render as their
// alt text — a remote image URL in untrusted text would otherwise be fetched on
// render and could carry data out in its query string.
const ALLOWED_ELEMENTS = [
  "a",
  "blockquote",
  "br",
  "code",
  "del",
  "em",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "hr",
  "img",
  "input",
  "li",
  "ol",
  "p",
  "pre",
  "strong",
  "table",
  "tbody",
  "td",
  "th",
  "thead",
  "tr",
  "ul",
] as const;

function urlTransform(url: string): string | undefined {
  return safeUrl(url);
}

const components: Components = {
  a: ({ href, children }) =>
    href ? (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className="font-medium text-primary underline underline-offset-4 hover:no-underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
      >
        {children}
      </a>
    ) : (
      <span>{children}</span>
    ),
  img: ({ alt }) => (alt ? <span className="italic text-muted-foreground">[{alt}]</span> : null),
  input: ({ checked }) => (
    <input type="checkbox" checked={Boolean(checked)} disabled readOnly className="mr-2 align-middle" />
  ),
  p: ({ children }) => <p className="leading-relaxed [&:not(:first-child)]:mt-3">{children}</p>,
  h1: ({ children }) => <h3 className="mt-4 text-lg font-semibold tracking-tight first:mt-0">{children}</h3>,
  h2: ({ children }) => <h4 className="mt-4 text-base font-semibold tracking-tight first:mt-0">{children}</h4>,
  h3: ({ children }) => <h5 className="mt-3 text-sm font-semibold first:mt-0">{children}</h5>,
  h4: ({ children }) => <h6 className="mt-3 text-sm font-semibold first:mt-0">{children}</h6>,
  h5: ({ children }) => <h6 className="mt-3 text-sm font-medium first:mt-0">{children}</h6>,
  h6: ({ children }) => <h6 className="mt-3 text-sm font-medium text-muted-foreground first:mt-0">{children}</h6>,
  ul: ({ children }) => <ul className="my-3 ml-5 list-disc space-y-1 first:mt-0">{children}</ul>,
  ol: ({ children }) => <ol className="my-3 ml-5 list-decimal space-y-1 first:mt-0">{children}</ol>,
  li: ({ children }) => <li className="leading-relaxed">{children}</li>,
  blockquote: ({ children }) => (
    <blockquote className="my-3 border-l-2 border-border pl-4 text-muted-foreground first:mt-0">{children}</blockquote>
  ),
  hr: () => <hr className="my-4 border-border" />,
  pre: ({ children }) => (
    <pre className="my-3 overflow-x-auto rounded-md bg-muted p-3 text-xs leading-relaxed first:mt-0 [&>code]:bg-transparent [&>code]:p-0">
      {children}
    </pre>
  ),
  code: ({ children }) => <code className="rounded bg-muted px-1 py-0.5 font-mono text-[0.9em]">{children}</code>,
  table: ({ children }) => (
    <div className="my-3 w-full overflow-x-auto first:mt-0">
      <table className="w-full border-collapse text-sm">{children}</table>
    </div>
  ),
  th: ({ children, style }) => (
    <th style={{ textAlign: style?.textAlign }} className="border-b border-border px-3 py-2 text-left font-semibold">
      {children}
    </th>
  ),
  td: ({ children, style }) => (
    <td style={{ textAlign: style?.textAlign }} className="border-b border-border px-3 py-2 align-top">
      {children}
    </td>
  ),
};

export type MarkdownTextProps = {
  /** The Markdown source. Untrusted text is fine: see the safety note above. */
  children: string | null | undefined;
  className?: string;
};

export function MarkdownText({ children, className }: MarkdownTextProps) {
  if (!children) return null;
  return (
    <div className={cn("min-w-0 break-words text-sm", className)}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        skipHtml
        allowedElements={ALLOWED_ELEMENTS}
        unwrapDisallowed
        urlTransform={urlTransform}
        components={components}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}
