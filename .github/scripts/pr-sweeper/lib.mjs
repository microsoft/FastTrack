// Shared helpers for the PR Sweeper scripts. Node builtins only — no npm deps,
// so the trusted report job needs no `npm install` step.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
export const configPath = join(here, "..", "..", "pr-sweeper.config.mjs");

export async function loadConfig() {
  // Use a file:// URL so dynamic import works with absolute paths on all OSes.
  const mod = await import(pathToFileURL(configPath).href);
  return mod.default;
}

export function artifactDir() {
  return process.env.SWEEPER_ARTIFACT_DIR || "sweeper-artifact";
}

export function artifactPath(name) {
  return join(artifactDir(), name);
}

export function readTextIfExists(name) {
  const p = artifactPath(name);
  return existsSync(p) ? readFileSync(p, "utf8") : "";
}

export function readJsonIfExists(name, fallback = null) {
  const p = artifactPath(name);
  if (!existsSync(p)) return fallback;
  try {
    return JSON.parse(readFileSync(p, "utf8"));
  } catch {
    return fallback;
  }
}

export function writeJson(name, value) {
  writeFileSync(artifactPath(name), `${JSON.stringify(value, null, 2)}\n`);
}

// Convert a simple glob (supporting ** and *) to an anchored RegExp.
export function globToRegExp(glob) {
  let re = "^";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === "*") {
      if (glob[i + 1] === "*") {
        re += ".*";
        i++;
        if (glob[i + 1] === "/") i++;
      } else {
        re += "[^/]*";
      }
    } else if ("\\^$.|?+()[]{}".includes(c)) {
      re += `\\${c}`;
    } else {
      re += c;
    }
  }
  return new RegExp(`${re}$`);
}

export function matchesAnyGlob(path, globs) {
  return globs.some((g) => globToRegExp(g).test(path));
}

// Redact matched evidence completely so no fragment of a real secret is ever
// echoed back into a public PR comment. The finding already carries file:line
// and a rule id, which is enough for the author to locate it.
export function redact() {
  return "[redacted]";
}

// Parse a unified diff into per-file entries with the ADDED lines and their
// new-file line numbers. Hunk-aware: file headers (--- / +++) are only honoured
// in the header section, so an added line whose *content* looks like a diff
// header cannot smuggle a secret past the added-line scan.
export function parseDiff(patch) {
  const files = [];
  if (!patch) return files;
  const lines = patch.split("\n");
  let current = null;
  let inHunk = false;
  let newLine = 0;

  const push = () => {
    if (current && current.path) files.push(current);
  };

  const hunkHeader = (line) =>
    line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);

  for (const line of lines) {
    // A new file header always starts at column 0 with no diff prefix char, so
    // this reliably ends the previous file's hunk regardless of state.
    if (line.startsWith("diff --git ")) {
      push();
      current = { path: null, oldPath: null, binary: false, added: [], addedCount: 0 };
      inHunk = false;
      newLine = 0;
      // Fallback path from "a/<old> b/<new>" so binaries (which emit no +++ line)
      // still get a path. Overridden by the +++ header for text files.
      const m = line.match(/^diff --git a\/(.+) b\/(.+)$/);
      if (m) current.path = stripPrefix(`b/${stripQuotes(m[2])}`);
      continue;
    }
    if (!current) continue;

    if (!inHunk) {
      // File-header section (before the first @@ of this file).
      if (line.startsWith("Binary files")) {
        current.binary = true;
        continue;
      }
      if (line.startsWith("--- ")) {
        const p = line.slice(4).trim();
        current.oldPath = p === "/dev/null" ? null : stripPrefix(p);
        continue;
      }
      if (line.startsWith("+++ ")) {
        const p = line.slice(4).trim();
        if (p !== "/dev/null") current.path = stripPrefix(p);
        continue;
      }
      const h = hunkHeader(line);
      if (h) {
        inHunk = true;
        newLine = parseInt(h[1], 10);
      }
      // All other header lines (index, mode, rename, similarity…) are ignored.
      continue;
    }

    // Inside a hunk: classify strictly by the first character.
    const c = line[0];
    if (c === "@") {
      const h = hunkHeader(line);
      if (h) newLine = parseInt(h[1], 10);
      continue;
    }
    if (c === "+") {
      current.added.push({ line: newLine, text: line.slice(1) });
      current.addedCount++;
      newLine++;
    } else if (c === "-") {
      // removed line — new-file counter does not advance
    } else if (c === "\\") {
      // "\ No newline at end of file"
    } else {
      // context line (leading space) or a blank line within the hunk
      newLine++;
    }
  }
  push();
  return files;
}

function stripQuotes(p) {
  return p.replace(/^"(.*)"$/, "$1");
}

function stripPrefix(p) {
  // Strip git's a/ or b/ prefix and surrounding quotes.
  let s = stripQuotes(p);
  if (s.startsWith("a/") || s.startsWith("b/")) s = s.slice(2);
  return s;
}

export function parseNameStatus(text) {
  const map = {};
  if (!text) return map;
  for (const raw of text.split("\n")) {
    const line = raw.replace(/\r$/, "");
    if (!line.trim()) continue;
    const parts = line.split("\t");
    const code = parts[0]?.[0];
    const path = parts[parts.length - 1];
    if (path) map[path] = code;
  }
  return map;
}

export function parseSizes(text) {
  const map = {};
  if (!text) return map;
  for (const raw of text.split("\n")) {
    const line = raw.replace(/\r$/, "");
    if (!line.trim()) continue;
    const idx = line.indexOf("\t");
    if (idx === -1) continue;
    const bytes = parseInt(line.slice(0, idx), 10);
    const path = line.slice(idx + 1);
    if (!Number.isNaN(bytes) && path) map[path] = bytes;
  }
  return map;
}

export function extname(path) {
  const base = path.split("/").pop() || "";
  const dot = base.lastIndexOf(".");
  return dot > 0 ? base.slice(dot).toLowerCase() : "";
}

export function topRoot(path) {
  return path.split("/")[0];
}
