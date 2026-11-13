import {
  format,
  isValid,
  startOfDay,
  startOfMonth,
  startOfQuarter,
  startOfWeek,
} from "date-fns";
import { TZDate } from "react-day-picker";
import type { Database, SqlJsStatic, SqlValue, Statement } from "sql.js";

import {
  sqlitePlaceholders,
  sqliteSpans,
  toDateValue,
  type LocalSqlValue,
  type LocalTable,
  type TileRequest,
} from "@/lib/dashboard-data";
import {
  isDashboardTimeZone,
  localTimeZoneName,
  temporalDate,
  type DashboardTimeZone,
  type TemporalKind,
} from "@/lib/dashboard-time-zone";
import loadSqlJs from "@/lib/local-sql-engine";

// Runs a tile's SQL over bundled files in the browser, with SQLite compiled to
// JavaScript (sql.js's asm.js build). The engine loads on the first query and every bundled
// table loads into one in-memory database once, so later tiles and filter
// changes only run their query. Dates go through the dashboard's own parsers,
// via the SQL functions below, so a SQL tile buckets and filters a date exactly
// as `bucketByTime`, `inRange` and the charts read it:
//
//   app_date(value [, zone [, kind]])         -> 'yyyy-MM-dd', or NULL
//   app_bucket(value, grain [, zone [, kind]]) -> the bucket's first day, 'yyyy-MM-dd'
//   app_time(value)                            -> epoch milliseconds, or NULL
//
// `zone` is 'local' (default) or 'utc', the dashboard's `TimeZoneFilter`
// value; `kind` is the column's `TemporalKind`, 'instant' (default), 'date' or
// 'wallClock' (a date or wall-clock column keeps the day it was written on in
// either zone); `grain` is 'day', 'week' (starts Monday), 'month' or 'quarter'.
// Never SQLite's own date() or strftime(): they read only ISO text, in UTC.
//
// How a tile uses them (the CSV embed script prints each table's name and
// columns; double-quote every column):
//
//   - A `DateRangeFilter` window on a calendar-date column:
//     `WHERE app_date("orderDate", 'local', 'date') BETWEEN ? AND ?`, params
//     `...sqlDayBounds(range)`.
//   - A timestamp column follows the `TimeZoneFilter`: pass `filters.timeZone`
//     as the zone param, so it is in the query key,
//     `app_bucket("createdAt", 'month', ?, 'instant')`.
//   - Each `app_date`/`app_bucket` result is already a calendar day in that
//     zone, so the chart that draws it takes `temporalKind="date"` and no
//     `dayBins`.
//   - Each KPI and chart is its own aggregating SELECT, so its View Query
//     shows the figure it draws; a prior-period comparison totals both
//     periods in that one statement,
//     `SUM(CASE WHEN app_date(...) BETWEEN ? AND ? THEN "revenue" END)`,
//     never one row query shared by tiles and totalled in the page. A
//     table's rows are a `SELECT ... LIMIT`.

export type LocalSqlRequest = Extract<TileRequest, { kind: "sqlite" }>;

const GRAINS = new Set(["day", "week", "month", "quarter"]);
const KINDS = new Set<string>(["instant", "date", "wallClock"]);

let engine: Promise<SqlJsStatic> | undefined;
let database: Database | undefined;
// The table object each loaded table was built from: a reloaded data module
// is a new object, and its table is rebuilt.
const loaded = new Map<string, LocalTable>();

function loadEngine(): Promise<SqlJsStatic> {
  engine ??= loadSqlJs();
  // A failed load is retried by the next query, not cached.
  engine.catch(() => {
    engine = undefined;
  });
  return engine;
}

function quoteIdentifier(name: string): string {
  return `"${name.replaceAll('"', '""')}"`;
}

function cellValue(value: unknown, table: string, column: string): SqlValue {
  if (value === undefined || value === null) return null;
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string") return value;
  if (typeof value === "boolean") return value ? 1 : 0;
  if (typeof value === "bigint") return Number(value);
  if (value instanceof Date) return isValid(value) ? value.toISOString() : null;
  throw new Error(`Table ${table}, column ${column}: a ${typeof value} cannot be stored in SQL.`);
}

function zoneArg(value: SqlValue | undefined, fn: string): DashboardTimeZone {
  if (value === undefined || value === null) return "local";
  if (typeof value === "string" && isDashboardTimeZone(value)) return value;
  throw new Error(`${fn}: zone must be 'local' or 'utc', not ${String(value)}`);
}

function kindArg(value: SqlValue | undefined, fn: string): TemporalKind {
  if (value === undefined || value === null) return "instant";
  if (typeof value === "string" && KINDS.has(value)) return value as TemporalKind;
  throw new Error(`${fn}: kind must be 'instant', 'date' or 'wallClock', not ${String(value)}`);
}

function dateArg(value: SqlValue): string | number | null {
  return typeof value === "string" || typeof value === "number" ? value : null;
}

// Two date shapes common in a CSV that `temporalDate` does not read, parsed
// field by field here rather than by the browser's `Date` heuristics:
// "3/15/2026" (US month/day/year, optional "h:mm[:ss] [AM|PM]") and RFC 1123
// "Sun, 01 Mar 2026 00:00:00 GMT". A trailing zone names the instant, not the
// calendar day, so the fields are kept as written. Any other shape is NULL.
const US_DATE =
  /^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?(?: ?([AaPp][Mm]))?)?$/;
const RFC_DATE =
  /^(?:[A-Za-z]{3}, ?)?(\d{1,2}) ([A-Za-z]{3}) (\d{4})(?: (\d{2}):(\d{2})(?::(\d{2}))?)?(?: (?:GMT|UTC|Z|[+-]\d{4}))?$/;
const MONTHS = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];

function writtenDate(text: string): Date | null {
  let y: number, mo: number, d: number, h = 0, mi = 0, s = 0;
  const us = US_DATE.exec(text);
  const rfc = us ? null : RFC_DATE.exec(text);
  if (us) {
    [mo, d, y] = [Number(us[1]), Number(us[2]), Number(us[3])];
    if (us[4] !== undefined) [h, mi, s] = [Number(us[4]), Number(us[5]), Number(us[6] ?? 0)];
    if (us[7]) {
      if (h < 1 || h > 12) return null;
      h = (h % 12) + (us[7].toLowerCase() === "pm" ? 12 : 0);
    }
  } else if (rfc) {
    [d, mo, y] = [Number(rfc[1]), MONTHS.indexOf(rfc[2].toLowerCase()) + 1, Number(rfc[3])];
    if (rfc[4] !== undefined) [h, mi, s] = [Number(rfc[4]), Number(rfc[5]), Number(rfc[6] ?? 0)];
  } else {
    return null;
  }
  if (mo < 1 || h > 23 || mi > 59 || s > 59) return null;
  // `Date.UTC` reads years 0-99 as 19xx; `setUTCFullYear` keeps the year written.
  const utc = new Date(0);
  utc.setUTCFullYear(y, mo - 1, d);
  utc.setUTCHours(h, mi, s, 0);
  const date = new TZDate(utc.getTime(), "UTC");
  return date.getUTCMonth() === mo - 1 && date.getUTCDate() === d ? date : null;
}

// The value as `temporalDate` reads it, or for a date or wall-clock column, as
// `writtenDate` reads a shape it does not.
function columnDate(value: SqlValue, zone: SqlValue | undefined, kind: SqlValue | undefined, fn: string): Date | null {
  const k = kindArg(kind, fn);
  const v = dateArg(value);
  const date = temporalDate(v, zoneArg(zone, fn), k);
  if (date || k === "instant" || typeof v !== "string") return date;
  return writtenDate(v.trim());
}

function appDate(value: SqlValue, zone?: SqlValue, kind?: SqlValue): string | null {
  const date = columnDate(value, zone, kind, "app_date");
  return date ? format(date, "yyyy-MM-dd") : null;
}

function appBucket(
  value: SqlValue,
  grain: SqlValue,
  zone?: SqlValue,
  kind?: SqlValue,
): string | null {
  if (typeof grain !== "string" || !GRAINS.has(grain)) {
    throw new Error(
      `app_bucket: grain must be 'day', 'week', 'month' or 'quarter', not ${String(grain)}`,
    );
  }
  const date = columnDate(value, zone, kind, "app_bucket");
  if (!date) return null;
  // A TZDate (UTC, or a date/wall-clock value) keeps its zone through date-fns.
  const start =
    grain === "week"
      ? startOfWeek(date, { weekStartsOn: 1 })
      : grain === "month"
        ? startOfMonth(date)
        : grain === "quarter"
          ? startOfQuarter(date)
          : startOfDay(date);
  return format(start, "yyyy-MM-dd");
}

function appTime(value: SqlValue): number | null {
  const date = toDateValue(dateArg(value));
  return date ? date.getTime() : null;
}

// SQLite calls these once per row, and each call parses and formats its value
// (tens of microseconds), so a filter over 100k rows froze the page for tens
// of seconds. A file holds few distinct dates, so each result is kept by its
// arguments. Once the map holds UDF_CACHE_LIMIT keys or UDF_CACHE_CHARS key
// characters, a new result is computed but not kept: the kept keys still hit,
// and a scan over more distinct values than fit never empties and refills the
// map. A 'local' result follows the browser's time zone, which can change
// while the page is open, so each query empties the map when the zone's name
// or its offsets differ from those its entries were computed in; replacing a
// bundled table empties it too. A call that throws (a bad zone, kind or grain)
// caches nothing.
const UDF_CACHE_LIMIT = 100_000;
const UDF_CACHE_CHARS = 8_000_000;
const udfCache = new Map<string, string | number | null>();
let udfCacheChars = 0;
let udfCacheZone: string | undefined;

function clearUdfCache(): void {
  udfCache.clear();
  udfCacheChars = 0;
}

// `Date`'s local offsets are read separately from Intl's zone name: an engine
// could update one without the other.
function localZoneStamp(): string {
  const year = new Date().getFullYear();
  const january = new Date(year, 0, 1).getTimezoneOffset();
  const july = new Date(year, 6, 1).getTimezoneOffset();
  return `${localTimeZoneName()}\u0000${january}\u0000${july}`;
}

function argKey(value: SqlValue | undefined): string | undefined {
  if (typeof value === "string") return `s${value}`;
  if (typeof value === "number") return `n${value}`;
  if (value === null) return "z";
  if (value === undefined) return "u";
  return undefined;
}

function cached<T extends string | number | null>(
  fn: string,
  args: (SqlValue | undefined)[],
  compute: () => T,
): T {
  const parts = args.map(argKey);
  if (parts.includes(undefined)) return compute();
  // JSON keeps the key injective: a text value may hold any character.
  const key = JSON.stringify([fn, ...parts]);
  if (udfCache.has(key)) return udfCache.get(key) as T;
  const result = compute();
  if (udfCache.size < UDF_CACHE_LIMIT && udfCacheChars + key.length <= UDF_CACHE_CHARS) {
    udfCache.set(key, result);
    udfCacheChars += key.length;
  }
  return result;
}

function openDatabase(sql: SqlJsStatic): Database {
  const db = new sql.Database();
  // sql.js registers a function per name and argument count, so each optional
  // argument is its own registration.
  const date = (...a: SqlValue[]) => cached("app_date", a, () => appDate(a[0], a[1], a[2]));
  const bucket = (...a: SqlValue[]) =>
    cached("app_bucket", a, () => appBucket(a[0], a[1], a[2], a[3]));
  db.create_function("app_date", (v: SqlValue) => date(v));
  db.create_function("app_date", (v: SqlValue, z: SqlValue) => date(v, z));
  db.create_function("app_date", (v: SqlValue, z: SqlValue, k: SqlValue) => date(v, z, k));
  db.create_function("app_bucket", (v: SqlValue, g: SqlValue) => bucket(v, g));
  db.create_function("app_bucket", (v: SqlValue, g: SqlValue, z: SqlValue) => bucket(v, g, z));
  db.create_function("app_bucket", (v: SqlValue, g: SqlValue, z: SqlValue, k: SqlValue) =>
    bucket(v, g, z, k),
  );
  db.create_function("app_time", (v: SqlValue) => cached("app_time", [v], () => appTime(v)));
  return db;
}

const SQL_TYPE = { text: "TEXT", integer: "INTEGER", real: "REAL" } as const;

// SQLite matches identifiers ignoring ASCII case, so `Sales` and `sales` name
// one table and `Id` and `ID` one column.
const sqlKey = (name: string) => name.replace(/[A-Z]/g, (c) => c.toLowerCase());

function loadTable(db: Database, table: LocalTable): void {
  if (!table.name.trim()) throw new Error(`The table for ${table.file} has no name.`);
  const columns = Object.entries(table.columns);
  if (columns.length === 0) throw new Error(`Table ${table.name} has no columns.`);
  const seen = new Map<string, string>();
  for (const [column] of columns) {
    const other = seen.get(sqlKey(column));
    if (other !== undefined) {
      throw new Error(`Table ${table.name} has columns ${other} and ${column}, which SQLite reads as one name.`);
    }
    seen.set(sqlKey(column), column);
  }
  const name = quoteIdentifier(table.name);
  const definitions = columns.map(([column, type]) => {
    if (!Object.hasOwn(SQL_TYPE, type)) {
      throw new Error(`Table ${table.name}, column ${column}: unknown type ${String(type)}.`);
    }
    return `${quoteIdentifier(column)} ${SQL_TYPE[type]}`;
  });
  db.run("BEGIN");
  try {
    db.run(`DROP TABLE IF EXISTS ${name}`);
    db.run(`CREATE TABLE ${name} (${definitions.join(", ")})`);
    const insert = db.prepare(
      `INSERT INTO ${name} VALUES (${columns.map(() => "?").join(", ")})`,
    );
    try {
      for (const row of table.rows) {
        const record = row as Record<string, unknown>;
        insert.run(
          columns.map(([column]) =>
            cellValue(Object.hasOwn(record, column) ? record[column] : undefined, table.name, column),
          ),
        );
      }
    } finally {
      insert.free();
    }
    db.run("COMMIT");
  } catch (error) {
    db.run("ROLLBACK");
    throw error;
  }
}

// The one statement `text` holds. More than one is refused: only the first
// would run, while View Query shows them all.
function singleStatement(db: Database, text: string): Statement {
  // Only the first statement is compiled: compiling a later one can already
  // change the shared connection (some PRAGMAs act when prepared), so the rest
  // is read as text and must be nothing but comments.
  let rest: string | undefined;
  const statements = db.iterateStatements(text);
  for (const statement of statements) {
    rest = statements.getRemainingSQL();
    statement.free();
    break;
  }
  if (rest === undefined) throw new Error("The query has no SQL statement.");
  let code = "";
  let from = 0;
  for (const [start, end] of sqliteSpans(rest).comments) {
    code += rest.slice(from, start);
    from = end;
  }
  if ((code + rest.slice(from)).replace(/[\s;]+/gu, "") !== "") {
    throw new Error("The query has more than one SQL statement; a tile runs one SELECT.");
  }
  return db.prepare(text);
}

// The query with every double-quoted identifier quoted in backticks instead.
// SQLite reads a double-quoted name that is no column as a string literal, so
// `AVG("Resolved On")` over a table whose column is `resolvedOn` runs and
// draws nothing, and `SELECT "Ticket ID"` shows that text on every row; a
// backtick-quoted name is always an identifier, so preparing this text fails
// with "no such column" instead. Strings ('...'), comments and other quoting
// are kept as written.
function strictIdentifiers(text: string): string {
  let out = "";
  let from = 0;
  for (const [start, end] of sqliteSpans(text).quoted) {
    const name = text.slice(start + 1, end - 1).replaceAll('""', '"');
    out += text.slice(from, start) + "`" + name.replaceAll("`", "``") + "`";
    from = end;
  }
  return out + text.slice(from);
}

// SQLite's error for a column or table that does not exist, with the tables'
// columns listed: the CSV embed script names each column by a key
// (`resolvedOn`), not by the file's header ("Resolved On"). Any other error is
// returned as it is.
function withColumnKeys(error: unknown, tables: Iterable<LocalTable>): unknown {
  const message = error instanceof Error ? error.message : String(error);
  if (!/^no such (column|table)/.test(message)) return error;
  const known = [...tables]
    .map((table) => `${table.name}: ${Object.keys(table.columns).map(quoteIdentifier).join(", ")}`)
    .join("; ");
  return new Error(
    `${message}. Name a column by its key in double quotes (${known}); a quoted name that is no column reads as text, and a string value takes single quotes.`,
  );
}

// Throws when a double-quoted name in the query is no column, table or alias:
// SQLite would read it as text.
function checkIdentifiers(db: Database, text: string, tables: Iterable<LocalTable>): void {
  const strict = strictIdentifiers(text);
  if (strict === text) return;
  try {
    db.prepare(strict).free();
  } catch (error) {
    const hinted = withColumnKeys(error, tables);
    if (hinted !== error) throw hinted;
  }
}

// The rows `request.text` selects, one object per row keyed by column name.
// Binds `request.params` to its `?` placeholders in order and throws when the
// counts differ, so the query View Query shows is the query that ran. The text
// is one read-only statement, and every double-quoted name in it is a column,
// table or alias.
export async function runLocalSql<T = Record<string, LocalSqlValue>>(
  request: LocalSqlRequest,
): Promise<T[]> {
  const params = request.params ?? [];
  const { offsets, invalid } = sqlitePlaceholders(request.text);
  if (invalid) {
    throw new Error(`Use ? placeholders with params, not ${invalid}.`);
  }
  if (offsets.length !== params.length) {
    throw new Error(
      `The query has ${offsets.length} ? placeholders but ${params.length} params.`,
    );
  }
  const names = new Map<string, LocalTable>();
  for (const table of request.tables) {
    const key = sqlKey(table.name);
    const other = names.get(key);
    if (other && other !== table) {
      throw new Error(`Two tables are named ${table.name} (${other.file} and ${table.file}).`);
    }
    names.set(key, table);
  }
  const sql = await loadEngine();
  // Everything below is synchronous, so two tiles never interleave a load.
  database ??= openDatabase(sql);
  const db = database;
  const zone = localZoneStamp();
  if (zone !== udfCacheZone) {
    clearUdfCache();
    udfCacheZone = zone;
  }
  db.run("PRAGMA query_only = OFF");
  try {
    for (const [key, table] of names) {
      const previous = loaded.get(key);
      if (previous === table) continue;
      if (previous) clearUdfCache();
      loadTable(db, table);
      loaded.set(key, table);
    }
  } finally {
    // A tile reads; it never changes the bundled tables another tile reads.
    db.run("PRAGMA query_only = ON");
  }
  let statement: Statement;
  try {
    statement = singleStatement(db, request.text);
  } catch (error) {
    throw withColumnKeys(error, names.values());
  }
  try {
    checkIdentifiers(db, request.text, names.values());
    statement.bind(params.map((value) => (typeof value === "number" && !Number.isFinite(value) ? null : value)));
    const rows: T[] = [];
    while (statement.step()) rows.push(statement.getAsObject() as T);
    return rows;
  } finally {
    statement.free();
  }
}
