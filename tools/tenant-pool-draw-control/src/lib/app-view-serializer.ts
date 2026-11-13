/**
 * App-view serialiser: what the user can see, as an accessible-name tree.
 *
 * Pure functions over a DOM subtree and a route list. This module decides
 * the BOUND of the app-view channel, so its allow-lists are the security
 * contract: it emits roles, accessible names and visible text, one node per
 * line, and nothing else. It never reads a form control's text value, a link
 * target, an image source, an id, a class, a `data-*` attribute, storage, or
 * the location; its only DOM property reads are the boolean `checked` state
 * and a control's `labels`, both state rather than values. Hidden subtrees
 * are skipped. The output is cut at whole lines
 * to `APP_VIEW_MAX_TREE_CHARS` and bounded in depth and node count, so a
 * runaway render cannot produce an unbounded message.
 *
 * Reads exactly the attributes in `ALLOWED_ATTRIBUTES`, through one helper,
 * so a reviewer can point at the line that decides what crosses.
 */

import { matchPath } from "react-router-dom";

import {
  APP_VIEW_MAX_ROUTE_CHARS,
  APP_VIEW_MAX_TREE_CHARS,
} from "../types/app-message";

/** Nodes below this depth are cut (and mark the tree truncated). */
export const APP_VIEW_MAX_DEPTH = 32;

/** Nodes beyond this count are cut (and mark the tree truncated). */
export const APP_VIEW_MAX_NODES = 4_000;

/** Route reported when no manifest pattern matches (the not-found route). */
export const APP_VIEW_UNMATCHED_ROUTE = "*";

/** The only attributes the serialiser may read. Names and states, never targets or values. */
const ALLOWED_ATTRIBUTES = new Set([
  "role",
  "aria-label",
  "aria-labelledby",
  "aria-hidden",
  "aria-checked",
  "aria-expanded",
  "aria-selected",
  "aria-disabled",
  "aria-required",
  "alt",
  "title",
  "type",
  "hidden",
  "inert",
  "contenteditable",
  "disabled",
  "required",
]);

/** Subtrees that never carry visible, readable content. */
/**
 * Tags whose text IS a form value (typed, chosen or generated). They emit their
 * own control line via `roleOf`; they never contribute to a NAME computed from
 * a wrapping `<label>`, an `aria-labelledby` target or a leaf's visible text,
 * because that is how `<label>Notes <textarea>secret</textarea></label>` would
 * leak the draft as `textbox: Notes secret`.
 */
const VALUE_BEARING_TAGS = new Set([
  "input",
  "textarea",
  "select",
  "option",
  "optgroup",
  "datalist",
  "output",
  "progress",
  "meter",
]);

const SKIPPED_TAGS = new Set([
  "script",
  "style",
  "template",
  "noscript",
  "svg",
  "iframe",
  "object",
  "embed",
  "canvas",
  "video",
  "audio",
  "head",
  "link",
  "meta",
]);

/** Implicit roles by tag. Tags absent here are transparent containers. */
const TAG_ROLES: Readonly<Record<string, string>> = {
  h1: "heading",
  h2: "heading",
  h3: "heading",
  h4: "heading",
  h5: "heading",
  h6: "heading",
  button: "button",
  a: "link",
  nav: "navigation",
  main: "main",
  header: "banner",
  footer: "contentinfo",
  aside: "complementary",
  section: "region",
  article: "article",
  form: "form",
  fieldset: "group",
  details: "group",
  summary: "button",
  dialog: "dialog",
  table: "table",
  tr: "row",
  th: "columnheader",
  td: "cell",
  ul: "list",
  ol: "list",
  li: "listitem",
  img: "image",
  label: "label",
  textarea: "textbox",
  select: "combobox",
  option: "option",
  progress: "progressbar",
  output: "status",
};

/** Roles for `<input>` by `type`. Anything else is a textbox. */
const INPUT_ROLES: Readonly<Record<string, string>> = {
  checkbox: "checkbox",
  radio: "radio",
  button: "button",
  submit: "button",
  reset: "button",
  image: "button",
  range: "slider",
  number: "spinbutton",
  search: "searchbox",
};

/**
 * Roles whose accessible name IS their content. The serialiser emits
 * `role: name` and does not descend, so a button's label is one line, not a
 * line plus a quoted duplicate. Deliberately NOT here: `listitem`, `cell`,
 * `label` — the canonical App Builder shape is a list or table with a button
 * or link inside each row, and flattening the row would erase the control the
 * user is asking about. Those descend like any container.
 */
const NAMED_LEAF_ROLES = new Set([
  "heading",
  "button",
  "link",
  "option",
  "columnheader",
  "tab",
  "menuitem",
]);

/** Form-control roles: emit role, name and boolean state; never descend. */
const CONTROL_ROLES = new Set([
  "textbox",
  "searchbox",
  "checkbox",
  "radio",
  "combobox",
  "listbox",
  "slider",
  "spinbutton",
  "switch",
]);

interface TreeBuilder {
  lines: string[];
  chars: number;
  nodes: number;
  truncated: boolean;
  transparentDepth: number;
}

function readAllowedAttribute(element: Element, name: string): string | null {
  if (!ALLOWED_ATTRIBUTES.has(name)) {
    return null;
  }
  return element.getAttribute(name);
}

function collapse(text: string | null | undefined): string {
  return (text ?? "").replace(/\s+/g, " ").trim();
}

function isHidden(element: Element): boolean {
  if (readAllowedAttribute(element, "hidden") !== null) {
    return true;
  }
  if (readAllowedAttribute(element, "aria-hidden") === "true") {
    return true;
  }
  if (readAllowedAttribute(element, "inert") !== null) {
    return true;
  }
  if (
    element.tagName.toLowerCase() === "input" &&
    readAllowedAttribute(element, "type") === "hidden"
  ) {
    return true;
  }
  // Tailwind's `hidden` utility and friends are display:none via a class, so
  // the attribute checks above miss them. Browsers answer that in one cheap
  // call (`checkVisibility`, Chromium 105+/Firefox 106+/Safari 17.4+); a DOM
  // without it (happy-dom in tests) falls back to computed style where a view
  // exists, and skips the check where there is none.
  const visibility = (
    element as Element & { checkVisibility?: (options?: { visibilityProperty?: boolean }) => boolean }
  ).checkVisibility;
  if (typeof visibility === "function") {
    // `visibilityProperty` makes the browser answer match the computed-style
    // fallback below, which also treats `visibility: hidden` as hidden (F14).
    return !visibility.call(element, { visibilityProperty: true });
  }
  const view = element.ownerDocument.defaultView;
  if (view && typeof view.getComputedStyle === "function") {
    const style = view.getComputedStyle(element);
    if (style.display === "none" || style.visibility === "hidden") {
      return true;
    }
  }
  return false;
}

function roleOf(element: Element): string | null {
  if (isEditable(element)) {
    // A rich-text editor: a control whose body is the user's draft, so it
    // emits `textbox: <name>` and nothing of what was typed.
    return "textbox";
  }
  const explicit = collapse(readAllowedAttribute(element, "role"));
  if (explicit) {
    return explicit.split(" ")[0] ?? null;
  }
  const tag = element.tagName.toLowerCase();
  if (tag === "input") {
    const type = collapse(readAllowedAttribute(element, "type")).toLowerCase();
    return INPUT_ROLES[type] ?? "textbox";
  }
  return TAG_ROLES[tag] ?? null;
}

/** `contenteditable` set to anything but "false": the element body is a form value. */
function isEditable(element: Element): boolean {
  const value = readAllowedAttribute(element, "contenteditable");
  return value !== null && value.toLowerCase() !== "false";
}

/**
 * An element whose OWN text is a form value: a value-bearing tag or an editable
 * region. Checked on entry as well as on descent — as a child `visibleText`
 * skips, as an `aria-labelledby` target, and as the element `walk` is about to
 * descend into — because the leak is the same whichever door the element
 * arrives through (N3: a `<textarea>` named by `aria-labelledby`, a plain
 * `<output>` in a form, a contenteditable label target).
 */
function isValueBearing(element: Element): boolean {
  return VALUE_BEARING_TAGS.has(element.tagName.toLowerCase()) || isEditable(element);
}

/** A name from labels only — aria-label, aria-labelledby, title — never from content. */
function labelOnlyName(element: Element): string {
  return (
    collapse(readAllowedAttribute(element, "aria-label")) ||
    labelledByText(element) ||
    collapse(readAllowedAttribute(element, "title"))
  );
}

/** Visible text of a subtree, collapsed. Used for names only, never emitted raw. */
function visibleText(element: Element, depth: number): string {
  if (depth > APP_VIEW_MAX_DEPTH) {
    return "";
  }
  const parts: string[] = [];
  for (const child of Array.from(element.childNodes)) {
    if (child.nodeType === 3) {
      parts.push(collapse(child.nodeValue));
      continue;
    }
    if (child.nodeType !== 1) {
      continue;
    }
    const childElement = child as Element;
    const childTag = childElement.tagName.toLowerCase();
    if (SKIPPED_TAGS.has(childTag) || isHidden(childElement) || isValueBearing(childElement)) {
      // A value-bearing child — a rich-text editor's body included (F15) — names nothing.
      continue;
    }
    const aria = collapse(readAllowedAttribute(childElement, "aria-label"));
    parts.push(aria || visibleText(childElement, depth + 1));
  }
  return collapse(parts.join(" "));
}

function labelledByText(element: Element): string {
  const ids = collapse(readAllowedAttribute(element, "aria-labelledby"));
  if (!ids) {
    return "";
  }
  const doc = element.ownerDocument;
  const parts = ids.split(" ").map((id) => {
    const target = doc.getElementById(id);
    return target && !isHidden(target) && !isValueBearing(target) ? visibleText(target, 0) : "";
  });
  return collapse(parts.join(" "));
}

function controlLabelsText(element: Element): string {
  const labels = (element as HTMLInputElement).labels;
  if (!labels || labels.length === 0) {
    return "";
  }
  return collapse(
    Array.from(labels)
      .filter((label) => !isHidden(label))
      .map((label) => visibleText(label, 0))
      .join(" "),
  );
}

function accessibleName(element: Element, role: string | null): string {
  const aria = collapse(readAllowedAttribute(element, "aria-label"));
  if (aria) {
    return aria;
  }
  const labelled = labelledByText(element);
  if (labelled) {
    return labelled;
  }
  if (role === "image") {
    return collapse(readAllowedAttribute(element, "alt"));
  }
  if (role !== null && CONTROL_ROLES.has(role)) {
    return controlLabelsText(element) || collapse(readAllowedAttribute(element, "title"));
  }
  if (role !== null && NAMED_LEAF_ROLES.has(role)) {
    return visibleText(element, 0) || collapse(readAllowedAttribute(element, "title"));
  }
  return collapse(readAllowedAttribute(element, "title"));
}

function controlState(element: Element): string {
  const states: string[] = [];
  const checked =
    readAllowedAttribute(element, "aria-checked") === "true" ||
    (element as HTMLInputElement).checked === true;
  if (checked) {
    states.push("checked");
  }
  if (
    readAllowedAttribute(element, "disabled") !== null ||
    readAllowedAttribute(element, "aria-disabled") === "true"
  ) {
    states.push("disabled");
  }
  if (
    readAllowedAttribute(element, "required") !== null ||
    readAllowedAttribute(element, "aria-required") === "true"
  ) {
    states.push("required");
  }
  const expanded = readAllowedAttribute(element, "aria-expanded");
  if (expanded === "true" || expanded === "false") {
    states.push(expanded === "true" ? "expanded" : "collapsed");
  }
  if (readAllowedAttribute(element, "aria-selected") === "true") {
    states.push("selected");
  }
  return states.length ? ` [${states.join(", ")}]` : "";
}

/** Append one line if it fits; otherwise mark truncation and refuse. */
function pushLine(builder: TreeBuilder, depth: number, text: string): boolean {
  if (builder.truncated) {
    return false;
  }
  const line = `${"  ".repeat(depth)}${text}`;
  const added = line.length + (builder.lines.length ? 1 : 0);
  if (builder.chars + added > APP_VIEW_MAX_TREE_CHARS || builder.nodes >= APP_VIEW_MAX_NODES) {
    builder.truncated = true;
    return false;
  }
  builder.lines.push(line);
  builder.chars += added;
  builder.nodes += 1;
  return true;
}

function walk(builder: TreeBuilder, node: Node, depth: number): void {
  if (builder.truncated) {
    return;
  }
  if (node.nodeType === 3) {
    const text = collapse(node.nodeValue);
    if (text) {
      pushLine(builder, depth, `"${text}"`);
    }
    return;
  }
  if (node.nodeType !== 1) {
    return;
  }
  const element = node as Element;
  if (SKIPPED_TAGS.has(element.tagName.toLowerCase()) || isHidden(element)) {
    return;
  }
  if (depth > APP_VIEW_MAX_DEPTH) {
    builder.truncated = true;
    return;
  }
  const role = roleOf(element);
  if (isValueBearing(element) && !(role !== null && CONTROL_ROLES.has(role))) {
    // A value-bearing element that is not a control — <output>, <progress>,
    // <meter>, <datalist>, <optgroup>, an <option> outside a <select>, an
    // <input> button: its text IS a form value, so it is named only by an
    // aria-label, an aria-labelledby target or a title, and is never descended
    // into. A role-less one (<meter>, <datalist>, <optgroup>) says nothing.
    if (role === null) {
      return;
    }
    const label = labelOnlyName(element);
    if (NAMED_LEAF_ROLES.has(role)) {
      if (label) {
        pushLine(builder, depth, `${role}: ${label}${controlState(element)}`);
      }
      return;
    }
    pushLine(builder, depth, `${label ? `${role}: ${label}` : role}${controlState(element)}`);
    return;
  }
  if (role === null) {
    // Transparent container: descend without indenting, but still count the
    // level so APP_VIEW_MAX_DEPTH fires on a plain <div> chain (F13).
    if (builder.transparentDepth >= APP_VIEW_MAX_DEPTH) {
      builder.truncated = true;
      return;
    }
    builder.transparentDepth += 1;
    try {
      for (const child of Array.from(element.childNodes)) {
        walk(builder, child, depth);
      }
    } finally {
      builder.transparentDepth -= 1;
    }
    return;
  }
  const name = accessibleName(element, role);
  if (CONTROL_ROLES.has(role)) {
    pushLine(builder, depth, `${role}: ${name}${controlState(element)}`.trimEnd());
    return;
  }
  if (NAMED_LEAF_ROLES.has(role) || role === "image") {
    if (name) {
      pushLine(builder, depth, `${role}: ${name}${controlState(element)}`);
    }
    return;
  }
  const header = name ? `${role}: ${name}` : role;
  if (!pushLine(builder, depth, `${header}${controlState(element)}`)) {
    return;
  }
  for (const child of Array.from(element.childNodes)) {
    walk(builder, child, depth + 1);
  }
}

/**
 * Serialise what the user can see under `root` as an accessible-name tree.
 *
 * One node per line, two spaces of indentation per depth. Elements with a
 * role emit `role: name`; text leaves emit `"text"`; transparent containers
 * emit nothing and pass their children through. Cut at whole lines to
 * `APP_VIEW_MAX_TREE_CHARS`, `APP_VIEW_MAX_DEPTH` and `APP_VIEW_MAX_NODES`;
 * any cut sets `truncated`.
 */
export function serializeAppView(root: Element): { tree: string; truncated: boolean } {
  const builder: TreeBuilder = { lines: [], chars: 0, nodes: 0, truncated: false, transparentDepth: 0 };
  for (const child of Array.from(root.childNodes)) {
    walk(builder, child, 0);
  }
  return { tree: builder.lines.join("\n"), truncated: builder.truncated };
}

/**
 * The route PATTERN (from the routes manifest) that matches `pathname`, or
 * `APP_VIEW_UNMATCHED_ROUTE` when none does. Never returns the pathname
 * itself: a pattern like `/invoices/:id` carries no record id, while the
 * pathname does. Cut to `APP_VIEW_MAX_ROUTE_CHARS`.
 */
export function matchedRoutePattern(
  pathname: string,
  patterns: readonly string[],
): string {
  for (const pattern of patterns) {
    if (matchPath(pattern, pathname) !== null) {
      return pattern.slice(0, APP_VIEW_MAX_ROUTE_CHARS);
    }
  }
  return APP_VIEW_UNMATCHED_ROUTE;
}

/**
 * The preview-mount gate: the signal renders only when the app was BUILT with
 * the orchestrator-baked `/v1/` base. It reads the same `BASE_URL` that
 * `getRouterBasename` (App.tsx) starts from, but deliberately adds no pathname
 * conjunct: the basename falls back to the runtime pathname when the build base
 * does not match it, whereas this gate must answer from the build alone — a
 * preview build is one wherever the document is served, and a build without
 * the base never is. A deployed app inside the player host has no Cowork
 * receiver, so it
 * must not observe or post at all. Kept pure so BOTH directions are unit-tested;
 * a gate that is only ever exercised in its "on" state can default open after a
 * refactor without any test noticing.
 */
export function isPreviewMount(baseUrl: string): boolean {
  return baseUrl.startsWith("/v1/");
}
