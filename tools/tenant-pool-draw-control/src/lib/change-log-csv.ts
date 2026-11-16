import type { ChangeEntry } from "@/data/environments";

const SOURCE_LABEL: Record<ChangeEntry["source"], string> = { sweep: "Rule", bulk: "Selection", row: "Switch" };
const DOWNLOAD_URL_TTL_MS = 60_000;

/** Quote a CSV cell and neutralise spreadsheet formulas in names that start with = + - @. */
function cell(value: string | number): string {
  let s = String(value);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

/** One row per environment per change, so runs over hundreds of environments are fully listed. */
export function changeLogCsv(entries: ChangeEntry[], nameOf: (id: string) => string): string {
  const header = ["Run ID", "Time (UTC)", "Action", "Started from", "Environment name", "Environment ID", "Result", "Detail"];
  const lines = [header.join(",")];
  for (const e of entries) {
    const base = [e.id, e.at, e.action === "disable" ? "Disable pool draw" : "Enable pool draw", SOURCE_LABEL[e.source]];
    const add = (ids: string[], result: string, fallback = "") => {
      for (const id of ids) {
        const name = e.names[id] ?? nameOf(id);
        lines.push([...base, name, id, result, e.details[id] ?? fallback].map(cell).join(","));
      }
    };
    add(e.updatedIds, "Changed", "Confirmed by read-back");
    add(e.lockedIds, "Locked", "Locked by an environment group rule");
    add(e.failedIds, "Not confirmed");
  }
  return lines.join("\r\n") + "\r\n";
}

/** Start a browser download of the CSV. Returns false if the browser refused. */
export function downloadCsv(fileName: string, csv: string): boolean {
  let url: string | undefined;
  try {
    // BOM so Excel opens non-ASCII environment names correctly.
    url = URL.createObjectURL(new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    link.remove();
    return true;
  } catch {
    return false;
  } finally {
    const revoke = url;
    if (revoke) setTimeout(() => URL.revokeObjectURL(revoke), DOWNLOAD_URL_TTL_MS);
  }
}

export function csvFileName(prefix: string, at = new Date()): string {
  const stamp = at.toISOString().slice(0, 16).replace(/[:T]/g, "-");
  return `${prefix}-${stamp}.csv`;
}
