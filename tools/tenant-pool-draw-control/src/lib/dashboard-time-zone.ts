import { format, parseISO } from "date-fns";
import { TZDate } from "react-day-picker";

import { toCalendarDay, toDateValue } from "@/lib/dashboard-data";

export type DashboardTimeZone = "local" | "utc";
export type TemporalKind = "instant" | "date" | "wallClock";

export function isDashboardTimeZone(value: string): value is DashboardTimeZone {
  return value === "local" || value === "utc";
}

export function localTimeZoneName(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

export function dashboardTimeZoneLabel(zone: DashboardTimeZone): string {
  return zone === "utc" ? "UTC" : `Local (${localTimeZoneName()})`;
}

export function inDashboardTimeZone(date: Date, zone: DashboardTimeZone): Date {
  return zone === "utc" ? new TZDate(date.getTime(), "UTC") : new Date(date);
}

// Non-instant strings accept date-fns ISO calendar syntax and Excel serials.
// SQL's explicit UTC/GMT suffixes are also field carriers. Other native-Date
// syntaxes are rejected, never interpreted as an instant and shifted locally.
function calendarStringDate(text: string): Date | null {
  const serial = toDateValue(text, { serialWallClock: true });
  if (serial instanceof TZDate) return serial;
  const hasTime = /[T ]\d{2}/.test(text);
  let fields = text;
  if (hasTime) {
    // SQL datetimeoffset text spaces its offset ("02:00:00.0000000 +05:30").
    // The suffix pattern has no unbounded quantifier and the whitespace before
    // it is trimmed separately: a `\s+` inside it rescans a long whitespace
    // run from every start position, quadratic on a long malformed cell.
    const suffix = /(?:Z|UTC|GMT|([+-])(\d{2})(?::?(\d{2}))?)$/i.exec(fields);
    if (suffix) {
      const head = fields.slice(0, suffix.index);
      const spaced = head.trimEnd();
      const zulu = suffix[0].toUpperCase() === "Z";
      // UTC/GMT is a field carrier only after whitespace ("10:00 UTC").
      if (zulu || suffix[1] !== undefined || spaced !== head) {
        if (Number(suffix[2]) > 23 || Number(suffix[3]) > 59) return null;
        fields = zulu ? head : spaced;
      }
    }
    // ISO permits 24:00 as the next day; a literal wall clock cannot display
    // it without changing its stated calendar day, so reject it explicitly.
    const hour = /[T ](\d{2})/.exec(fields);
    if (hour && Number(hour[1]) >= 24) return null;
  }
  // An explicit zero offset takes parseISO's timestamp path. Its offsetless
  // calendar setters can normalize a local DST gap even with a TZDate context.
  const parsed = parseISO(`${fields}${hasTime ? "Z" : "T00:00Z"}`);
  return Number.isNaN(parsed.getTime()) ? null : new TZDate(parsed.getTime(), "UTC");
}

// A field carrier past year 9999 ("10000-01-01T00:00:00Z") is no ISO text
// and parses to an Invalid Date, which every later `format` throws on. Such
// a cell (an Excel serial past 9999-12-31, an epoch near Date's limit) is
// unreadable, so it is NULL like any other.
function validDate(date: Date | null): Date | null {
  return date && !Number.isNaN(date.getTime()) ? date : null;
}

// Explicit date/wall-clock strings carry calendar fields, not an instant.
// UTC is only a field-preserving calendar here: even a local DST-gap time
// must remain 02:30, rather than normalizing to 03:30.
export function temporalDate(
  value: Date | string | number | null | undefined,
  timeZone: DashboardTimeZone,
  kind: TemporalKind,
): Date | null {
  if (typeof value === "string" && kind !== "instant") {
    // A text serial or expanded-year ISO string can parse past 9999; the
    // wall-clock arm writes no field carrier, so bound the year here too.
    const date = calendarStringDate(value.trim());
    if (!date || date.getUTCFullYear() > 9999) return null;
    return kind === "date"
      ? validDate(new TZDate(`${format(date, "yyyy-MM-dd")}T00:00:00Z`, "UTC"))
      : date;
  }
  const parsed = toDateValue(value, { serialWallClock: kind !== "instant" });
  const date = validDate(kind === "date" && !(parsed instanceof TZDate) ? toCalendarDay(value) : parsed);
  if (!date) return null;
  if (kind === "instant") return inDashboardTimeZone(date, timeZone);
  // The numeric-field TZDate constructor first constructs in the system
  // zone and can normalize a DST gap before applying UTC. An ISO field
  // carrier does not take that lossy route.
  const fields = kind === "date"
    ? `${format(date, "yyyy-MM-dd")}T00:00:00.000`
    : format(date, "yyyy-MM-dd'T'HH:mm:ss.SSS");
  return validDate(new TZDate(`${fields}Z`, "UTC"));
}

// Missing and invalid temporal cells use the scaffold's empty-cell convention.
export function formatTemporalValue(
  value: Date | string | number | null | undefined,
  pattern: string,
  timeZone: DashboardTimeZone,
  kind: TemporalKind,
): string {
  const date = temporalDate(value, timeZone, kind);
  return date ? format(date, pattern) : "";
}

// Bounded offset discovery, not a one-hour DST assumption. Every candidate
// must round-trip to the requested calendar minute (gaps have none, folds two).
export function timeInputCandidates(
  day: Date,
  time: string,
  timeZone: DashboardTimeZone = "local",
): Date[] {
  if (Number.isNaN(day.getTime()) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return [];
  const key = `${format(day, "yyyy-MM-dd")} ${time}`;
  const wall = new TZDate(`${format(day, "yyyy-MM-dd")}T${time}:00Z`, "UTC").getTime();
  if (timeZone === "utc") return [new Date(wall)];
  const offsets = new Set<number>();
  for (let hours = -48; hours <= 48; hours += 3) {
    offsets.add(new Date(wall + hours * 3_600_000).getTimezoneOffset());
  }
  return [...offsets]
    .map((offset) => new Date(wall + offset * 60_000))
    .filter((date) => format(date, "yyyy-MM-dd HH:mm") === key)
    .sort((a, b) => a.getTime() - b.getTime());
}
