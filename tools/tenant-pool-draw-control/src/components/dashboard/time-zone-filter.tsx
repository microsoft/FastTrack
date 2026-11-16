import { useId } from "react";

import { Label } from "@/components/ui/label";
import { NativeSelect, NativeSelectOption } from "@/components/ui/native-select";
import {
  dashboardTimeZoneLabel,
  isDashboardTimeZone,
  type DashboardTimeZone,
} from "@/lib/dashboard-time-zone";

export function TimeZoneFilter({
  value,
  onChange,
  hasTimestamps,
}: {
  value: DashboardTimeZone;
  onChange: (value: DashboardTimeZone) => void;
  hasTimestamps: boolean;
}) {
  const id = useId();
  if (!hasTimestamps) return null;
  return (
    // A PDF keeps the selector: controlled charts carry no zone caption of their own.
    <div className="min-w-0">
      <Label htmlFor={id} className="sr-only">
        Time zone
      </Label>
      <NativeSelect
        id={id}
        size="sm"
        value={value}
        onChange={(event) => {
          if (isDashboardTimeZone(event.target.value)) onChange(event.target.value);
        }}
      >
        <NativeSelectOption value="local">{dashboardTimeZoneLabel("local")}</NativeSelectOption>
        <NativeSelectOption value="utc">UTC</NativeSelectOption>
      </NativeSelect>
    </div>
  );
}
