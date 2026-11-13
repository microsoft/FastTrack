import { format, isSameDay } from "date-fns";
import {
  Calendar as CalendarIcon,
  Check,
  ChevronDown,
  Clock,
  RotateCcw,
} from "lucide-react";
import { useId, useState, type ReactNode } from "react";
import type { DateRange as DayPickerRange } from "react-day-picker";

import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { NativeSelect, NativeSelectOption } from "@/components/ui/native-select";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { useReportChartIssues } from "@/components/dashboard/chart-hooks";
import { checkFilterOptions } from "@/lib/dashboard-charts";
import {
  DEFAULT_DATE_RANGE_PRESETS,
  formatDateRange,
  multiSelectSummary,
  type DateRange,
  type DateRangePreset,
  wholeDayRange,
} from "@/lib/dashboard-data";
import {
  DEFAULT_TIME_RANGE_MAX_DAYS,
  DEFAULT_TIME_RANGE_PRESETS,
  formatTimeRange,
  resolveTimeRange,
  timeRangeFromParts,
  type TimeRangeOptions,
  type TimeRangePreset,
} from "@/lib/dashboard-time-range";
import {
  dashboardTimeZoneLabel,
  formatTemporalValue,
  inDashboardTimeZone,
  timeInputCandidates,
  type DashboardTimeZone,
} from "@/lib/dashboard-time-zone";
import { cn } from "@/lib/utils";

// Horizontal, wrapping row of filters above a dashboard. Keep filter state in
// the page (or a store) and derive every card from it.
export function FilterBar({
  children,
  onReset,
  className,
}: {
  children: ReactNode;
  onReset?: () => void;
  className?: string;
}) {
  return (
    <div
      role="group"
      aria-label="Filters"
      className={cn(
        "flex flex-wrap items-end gap-3 rounded-lg border bg-card p-3",
        className,
      )}
    >
      {children}
      {onReset && (
        <Button variant="ghost" size="sm" className="ml-auto" onClick={onReset}>
          <RotateCcw aria-hidden="true" />
          Reset filters
        </Button>
      )}
    </div>
  );
}

function sameRange(a: DateRange, b: DateRange): boolean {
  return isSameDay(a.from, b.from) && isSameDay(a.to, b.to);
}


export function DateRangeFilter({
  value,
  onChange,
  presets = DEFAULT_DATE_RANGE_PRESETS,
  label = "Date range",
}: {
  value: DateRange;
  onChange: (range: DateRange, preset?: DateRangePreset) => void;
  presets?: DateRangePreset[];
  label?: string;
}) {
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState<DayPickerRange | undefined>(undefined);
  const activePreset = presets.find((p) => sameRange(p.range(), value));

  // preset is the clicked preset; a calendar pick passes none.
  const commit = (range: DateRange, preset?: DateRangePreset) => {
    onChange(wholeDayRange(range.from, range.to), preset);
    setDraft(undefined);
    setOpen(false);
  };

  return (
    <div className="grid gap-1.5">
      <span className="text-xs font-medium text-muted-foreground">{label}</span>
      <Popover
        open={open}
        onOpenChange={(next) => {
          setOpen(next);
          if (!next) setDraft(undefined);
        }}
      >
        <PopoverTrigger asChild>
          <Button
            variant="outline"
            size="sm"
            className="justify-start font-normal"
            aria-label={`${label}: ${activePreset?.label ?? formatDateRange(value)}`}
          >
            <CalendarIcon aria-hidden="true" />
            {activePreset?.label ?? formatDateRange(value)}
          </Button>
        </PopoverTrigger>
        <PopoverContent align="start" className="flex w-auto flex-col gap-2 p-2 sm:flex-row">
          <div className="flex flex-col gap-1 sm:w-36" aria-label="Presets" role="group">
            {presets.map((preset) => (
              <Button
                key={preset.label}
                variant={preset === activePreset ? "secondary" : "ghost"}
                size="sm"
                className="justify-start"
                aria-pressed={preset === activePreset}
                onClick={() => commit(preset.range(), preset)}
              >
                {preset.label}
                {preset === activePreset && (
                  <Check aria-hidden="true" className="ml-auto" />
                )}
              </Button>
            ))}
          </div>
          <Calendar
            mode="range"
            numberOfMonths={1}
            defaultMonth={draft?.from ?? value.from}
            selected={draft ?? { from: value.from, to: value.to }}
            onSelect={(_range, day) => {
              const start = draft?.from;
              if (!start) {
                setDraft({ from: day, to: undefined });
              } else {
                commit({ from: start, to: day });
              }
            }}
          />
        </PopoverContent>
      </Popover>
    </div>
  );
}

const TIME_FORMAT = "HH:mm";
const MS_PER_DAY = 24 * 60 * 60 * 1000;

// `kept` is the instants the fields were filled from (see `timeRangeFromParts`).
type CustomDraft = {
  days: DayPickerRange;
  fromTime: string;
  toTime: string;
  kept: { from: Date; to: Date };
  fromOccurrence?: number;
  toOccurrence?: number;
};

function draftFor(value: string, options: TimeRangeOptions): CustomDraft {
  const range = resolveTimeRange(value, options) ?? {
    from: new Date(Date.now() - MS_PER_DAY),
    to: new Date(),
  };
  return {
    days: {
      from: inDashboardTimeZone(range.from, options.timeZone ?? "local"),
      to: inDashboardTimeZone(range.to, options.timeZone ?? "local"),
    },
    fromTime: formatTemporalValue(range.from, TIME_FORMAT, options.timeZone ?? "local", "instant"),
    toTime: formatTemporalValue(range.to, TIME_FORMAT, options.timeZone ?? "local", "instant"),
    kept: { from: range.from, to: range.to },
  };
}

// A time window as a dropdown, as in Azure Data Explorer: relative presets
// ("Last 24 hours") plus a custom start and end, each a day and a time. The
// value is a string (see `@/lib/dashboard-time-range`), so it goes straight
// into `useUrlFilters`; turn it into a query with `kqlTimeFilter` or
// `resolveTimeRange`, passing them the same `presets`, `maxDays` (7 by
// default) and `timeZone` as here. "Custom range…" is always offered; `maxDays` caps it.
type TimeRangeFilterProps = {
  value: string;
  onChange: (value: string) => void;
  presets?: readonly TimeRangePreset[];
  label?: string;
  maxDays?: number;
  timeZone?: DashboardTimeZone;
};

// Remounting discards an open draft before a mode switch can reinterpret it.
export function TimeRangeFilter(props: TimeRangeFilterProps) {
  return <ZonedTimeRangeFilter key={props.timeZone ?? "local"} {...props} />;
}

function ZonedTimeRangeFilter({
  value,
  onChange,
  presets = DEFAULT_TIME_RANGE_PRESETS,
  label = "Time range",
  maxDays,
  timeZone: suppliedTimeZone,
}: TimeRangeFilterProps) {
  const timeZone = suppliedTimeZone ?? "local";
  const options: TimeRangeOptions = { presets, maxDays, timeZone };
  const id = useId();
  const [open, setOpen] = useState(false);
  const [custom, setCustom] = useState<CustomDraft | null>(null);
  // A calendar preset `maxDays` no longer admits is not applied: the queries
  // get no window, so the trigger must not show it as active.
  const matchedPreset = presets.find((p) => p.value === value);
  const activePreset = matchedPreset && resolveTimeRange(matchedPreset.value, options)
    ? matchedPreset
    : undefined;
  const isCustom = !matchedPreset && resolveTimeRange(value, options) !== null;
  const text = activePreset && suppliedTimeZone !== undefined
    ? activePreset.label
    : formatTimeRange(matchedPreset && !activePreset ? "" : value, presets, timeZone);
  const applied = !custom
    ? null
    : timeRangeFromParts(
        {
          fromDay: custom.days.from,
          toDay: custom.days.to,
          fromTime: custom.fromTime,
          toTime: custom.toTime,
          kept: custom.kept,
          timeZone,
          fromOccurrence: custom.fromOccurrence,
          toOccurrence: custom.toOccurrence,
        },
        maxDays,
      );

  const commit = (next: string) => {
    onChange(next);
    setCustom(null);
    setOpen(false);
  };

  const occurrenceSelect = (end: "from" | "to") => {
    if (!custom) return null;
    const day = end === "from" ? custom.days.from : custom.days.to ?? custom.days.from;
    if (!day) return null;
    const time = end === "from" ? custom.fromTime : custom.toTime;
    const candidates = timeInputCandidates(day, time, timeZone);
    if (candidates.length < 2) return null;
    const field = end === "from" ? "fromOccurrence" : "toOccurrence";
    const keptMinute = Math.floor(custom.kept[end].getTime() / 60_000) * 60_000;
    const preserved = candidates.findIndex((date) => date.getTime() === keptMinute);
    return (
      <>
        <Label htmlFor={`${id}-${end}-occurrence`} className="text-xs text-muted-foreground">
          {end === "from" ? "Start" : "End"} time occurrence
        </Label>
        <NativeSelect
          id={`${id}-${end}-occurrence`}
          value={custom[field] ?? (preserved < 0 ? "" : preserved)}
          onChange={(event) => setCustom({
            ...custom,
            [field]: event.target.value === "" ? undefined : Number(event.target.value),
          })}
        >
          <NativeSelectOption value="">Choose occurrence</NativeSelectOption>
          {candidates.map((date, index) => (
            <NativeSelectOption key={date.getTime()} value={index}>
              {index === 0 ? "First" : "Second"} ({format(date, "XXX")})
            </NativeSelectOption>
          ))}
        </NativeSelect>
      </>
    );
  };

  return (
    <div className="grid gap-1.5">
      <span id={id} className="text-xs font-medium text-muted-foreground">
        {label}
      </span>
      <Popover
        open={open}
        onOpenChange={(next) => {
          setOpen(next);
          setCustom(next && isCustom ? draftFor(value, options) : null);
        }}
      >
        <PopoverTrigger asChild>
          <Button
            variant="outline"
            size="sm"
            className="justify-start font-normal"
            aria-label={`${label}: ${text}`}
          >
            <Clock aria-hidden="true" />
            {text}
            <ChevronDown aria-hidden="true" className="ml-1 opacity-60" />
          </Button>
        </PopoverTrigger>
        <PopoverContent
          align="start"
          className="flex max-h-[var(--radix-popover-content-available-height)] w-auto max-w-[calc(100vw-1rem)] flex-col gap-2 overflow-y-auto p-2 sm:flex-row"
        >
          <div className="flex flex-col gap-1 sm:w-44" role="group" aria-labelledby={id}>
            {presets.map((preset) => (
              <Button
                key={preset.value}
                disabled={!resolveTimeRange(preset.value, options)}
                title={preset.calendar && !resolveTimeRange(preset.value, options)
                  ? `Requires a full ${preset.calendar === "month" ? 31 : 1}-day calendar budget; maxDays is ${maxDays ?? DEFAULT_TIME_RANGE_MAX_DAYS}.`
                  : undefined}
                variant={preset === activePreset && !custom ? "secondary" : "ghost"}
                size="sm"
                className="justify-start"
                aria-pressed={preset === activePreset}
                onClick={() => commit(preset.value)}
              >
                {suppliedTimeZone === undefined ? formatTimeRange(preset.value, presets, timeZone) : preset.label}
                {preset === activePreset && <Check aria-hidden="true" className="ml-auto" />}
              </Button>
            ))}
            <div role="separator" className="my-1 border-t" />
            <Button
              variant={custom ? "secondary" : "ghost"}
              size="sm"
              className="justify-start"
              aria-pressed={isCustom}
              aria-expanded={custom !== null}
              onClick={() => setCustom(custom ? null : draftFor(value, options))}
            >
              Custom range…
              {isCustom && <Check aria-hidden="true" className="ml-auto" />}
            </Button>
          </div>
          {custom && (
            <div className="flex flex-col gap-2" role="group" aria-label="Custom range">
              {suppliedTimeZone === undefined && (
                <p className="px-1 text-xs text-muted-foreground">{dashboardTimeZoneLabel(timeZone)}</p>
              )}
              <Calendar
                timeZone={timeZone === "utc" ? "UTC" : undefined}
                mode="range"
                numberOfMonths={1}
                defaultMonth={custom.days.from}
                selected={custom.days}
                onSelect={(_range, day) => {
                  const { from, to } = custom.days;
                  const days: DayPickerRange =
                    !from || to
                      ? { from: day, to: undefined }
                      : day < from
                        ? { from: day, to: from }
                        : { from, to: day };
                  setCustom({ ...custom, days, fromOccurrence: undefined, toOccurrence: undefined });
                }}
              />
              <div className="grid grid-cols-2 gap-2 px-1">
                <div className="grid gap-1">
                  <Label htmlFor={`${id}-from`} className="text-xs text-muted-foreground">
                    Start time
                  </Label>
                  <Input
                    id={`${id}-from`}
                    type="time"
                    className="h-8"
                    value={custom.fromTime}
                    onChange={(event) => setCustom({ ...custom, fromTime: event.target.value, fromOccurrence: undefined })}
                  />
                  {occurrenceSelect("from")}
                </div>
                <div className="grid gap-1">
                  <Label htmlFor={`${id}-to`} className="text-xs text-muted-foreground">
                    End time
                  </Label>
                  <Input
                    id={`${id}-to`}
                    type="time"
                    className="h-8"
                    value={custom.toTime}
                    onChange={(event) => setCustom({ ...custom, toTime: event.target.value, toOccurrence: undefined })}
                  />
                  {occurrenceSelect("to")}
                </div>
              </div>
              <div className="flex items-center justify-between gap-2 px-1">
                <p role="status" className="text-xs text-destructive">
                  {applied && "error" in applied ? applied.error : ""}
                </p>
                <Button
                  size="sm"
                  disabled={!applied || !("value" in applied)}
                  onClick={() => {
                    if (applied && "value" in applied) commit(applied.value);
                  }}
                >
                  Apply
                </Button>
              </div>
            </div>
          )}
        </PopoverContent>
      </Popover>
    </div>
  );
}

// Options must not depend on the filter's own selection (`checkFilterOptions`):
// a chosen value missing from `options` is still offered, so the select shows it.
function withChosen(
  options: { value: string; label: string }[],
  chosen: readonly string[],
): { value: string; label: string }[] {
  const offered = new Set(options.map((o) => o.value));
  const missing = chosen.filter((v) => v !== "" && !offered.has(v));
  return missing.length === 0
    ? options
    : [...options, ...missing.map((v) => ({ value: v, label: v }))];
}

// Native select: accessible, mobile-friendly and allows "" as the "All" value.
// Pass every value of the dimension as `options`, never only those left after
// this filter is applied.
export function SelectFilter({
  label,
  value,
  options,
  onChange,
  allLabel,
}: {
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (value: string) => void;
  allLabel?: string;
}) {
  const id = useId();
  useReportChartIssues(`SelectFilter "${label}"`, checkFilterOptions([value], options));
  const shown = withChosen(options, [value]);
  return (
    <div className="grid gap-1.5">
      <Label htmlFor={id} className="text-xs font-medium text-muted-foreground">
        {label}
      </Label>
      <NativeSelect
        id={id}
        size="sm"
        value={value}
        onChange={(event) => onChange(event.target.value)}
      >
        {allLabel !== undefined && (
          <NativeSelectOption value="">{allLabel}</NativeSelectOption>
        )}
        {shown.map((option) => (
          <NativeSelectOption key={option.value} value={option.value}>
            {option.label}
          </NativeSelectOption>
        ))}
      </NativeSelect>
    </div>
  );
}

// Several values of one dimension at once (severities, regions). `value` is
// the chosen option values; [] means no filter. The trigger names the choice
// from the options themselves (`multiSelectSummary`), so it never claims a
// subset is "all". In URL state keep it as `value.join(",")`. As with
// `SelectFilter`, `options` is every value of the dimension.
export function MultiSelectFilter({
  label,
  value,
  options: given,
  onChange,
  allLabel = "All",
}: {
  label: string;
  value: string[];
  options: { value: string; label: string }[];
  onChange: (value: string[]) => void;
  allLabel?: string;
}) {
  const id = useId();
  useReportChartIssues(`MultiSelectFilter "${label}"`, checkFilterOptions(value, given));
  const options = withChosen(given, value);
  const chosen = new Set(value);
  const toggle = (option: string) => {
    const next = new Set(chosen);
    if (next.has(option)) next.delete(option);
    else next.add(option);
    onChange(options.map((o) => o.value).filter((v) => next.has(v)));
  };
  return (
    <div className="grid gap-1.5">
      <Label htmlFor={id} className="text-xs font-medium text-muted-foreground">
        {label}
      </Label>
      <Popover>
        <PopoverTrigger asChild>
          <Button
            id={id}
            variant="outline"
            size="sm"
            className="min-w-32 justify-between font-normal"
          >
            <span className="truncate">
              {multiSelectSummary(value, options, allLabel)}
            </span>
            <ChevronDown className="size-4 opacity-50" aria-hidden />
          </Button>
        </PopoverTrigger>
        <PopoverContent align="start" className="w-56 p-2">
          <div role="group" aria-label={label} className="grid gap-1">
            {options.map((option) => {
              const optionId = `${id}-${option.value}`;
              return (
                <div key={option.value} className="flex items-center gap-2 rounded px-1 py-1">
                  <Checkbox
                    id={optionId}
                    checked={chosen.has(option.value)}
                    onCheckedChange={() => toggle(option.value)}
                  />
                  <Label htmlFor={optionId} className="flex-1 text-sm font-normal">
                    {option.label}
                  </Label>
                </div>
              );
            })}
          </div>
          {value.length > 0 && (
            <Button
              variant="ghost"
              size="sm"
              className="mt-1 w-full"
              onClick={() => onChange([])}
            >
              Clear
            </Button>
          )}
        </PopoverContent>
      </Popover>
    </div>
  );
}

// A short row of mutually exclusive choices (a grain, a view) where every
// option should stay visible; a time window is a `TimeRangeFilter` instead.
// The chosen option is filled with the primary colour, so the selection reads
// at a glance; it can never be cleared.
export function SegmentedFilter({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (value: string) => void;
}) {
  const id = useId();
  return (
    <div className="grid min-w-0 max-w-full gap-1.5">
      <span id={id} className="text-xs font-medium text-muted-foreground">
        {label}
      </span>
      {/* Options wrap onto further rows when they do not fit (a phone-width
          card header); spacing gives each option its own border and rounded
          corners, so every wrapped row stays outlined. */}
      <ToggleGroup
        type="single"
        variant="outline"
        size="sm"
        aria-labelledby={id}
        value={value}
        onValueChange={(next) => {
          if (next) onChange(next);
        }}
        spacing={1}
        className="max-w-full flex-wrap"
      >
        {options.map((option) => (
          <ToggleGroupItem
            key={option.value}
            value={option.value}
            className="data-[state=on]:border-primary data-[state=on]:bg-primary data-[state=on]:text-primary-foreground data-[state=on]:hover:bg-primary/90 data-[state=on]:hover:text-primary-foreground"
          >
            {option.label}
          </ToggleGroupItem>
        ))}
      </ToggleGroup>
    </div>
  );
}