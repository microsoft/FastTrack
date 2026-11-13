// Syntax colouring for the queries a dashboard tile shows under "View Query",
// from Prism's KQL (kusto), SQL and XML grammars. Prism only tokenizes here:
// React renders each token as text, so no Prism-built HTML reaches the page.
// The tokens always join back to the input text.
import "./prism-manual";
import Prism from "prismjs";
import "prismjs/components/prism-sql";
import "prismjs/components/prism-kusto";

export type QueryLanguage = "kql" | "sql" | "xml";

export type QueryTokenKind =
  | "plain"
  | "keyword"
  | "function"
  | "string"
  | "number"
  | "comment"
  | "pipe"
  | "tag"
  | "attr";

export interface QueryToken {
  kind: QueryTokenKind;
  text: string;
}

const GRAMMAR: Record<QueryLanguage, string> = { kql: "kusto", sql: "sql", xml: "markup" };

// Prism token types (and aliases) to the colours the inspector shows. A type
// not listed takes its enclosing token's kind, so a tag's `<` and `>` stay tag.
const KIND: Record<string, QueryTokenKind> = {
  comment: "comment",
  prolog: "comment",
  doctype: "comment",
  cdata: "comment",
  string: "string",
  "attr-value": "string",
  keyword: "keyword",
  boolean: "keyword",
  "class-name": "keyword",
  function: "function",
  number: "number",
  tag: "tag",
  "attr-name": "attr",
};

function kindOf(token: Prism.Token, inherited: QueryTokenKind, text: string): QueryTokenKind {
  if (token.type === "operator") {
    // KQL's `|` pipe; SQL's word operators (AND, IN, LIKE) read as keywords.
    if (text === "|") return "pipe";
    return /^[A-Za-z]/.test(text) ? "keyword" : inherited;
  }
  const aliases = Array.isArray(token.alias) ? token.alias : token.alias ? [token.alias] : [];
  for (const name of [token.type, ...aliases]) {
    if (Object.hasOwn(KIND, name)) return KIND[name];
  }
  return inherited;
}

function contentText(content: Prism.TokenStream): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) return content.map(contentText).join("");
  return contentText(content.content);
}

export function highlightQuery(text: string, language: QueryLanguage): QueryToken[] {
  const tokens: QueryToken[] = [];
  const push = (kind: QueryTokenKind, piece: string) => {
    if (!piece) return;
    const last = tokens[tokens.length - 1];
    if (last && last.kind === kind) last.text += piece;
    else tokens.push({ kind, text: piece });
  };
  const walk = (stream: Prism.TokenStream, inherited: QueryTokenKind) => {
    if (typeof stream === "string") push(inherited, stream);
    else if (Array.isArray(stream)) for (const part of stream) walk(part, inherited);
    else walk(stream.content, kindOf(stream, inherited, contentText(stream.content)));
  };
  walk(Prism.tokenize(text, Prism.languages[GRAMMAR[language]]), "plain");
  return tokens;
}
