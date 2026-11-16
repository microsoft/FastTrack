import { useEffect, useState } from "react";

// Shown under a loading skeleton once a query has run longer than `afterMs`, with
// the elapsed seconds, so a slow warehouse or Kusto query reads as working rather
// than as a dead tile. Renders nothing before then.
export function SlowQueryHint({ afterMs = 5000 }: { afterMs?: number }) {
  const [started] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => setElapsed(Date.now() - started), 1000);
    return () => clearInterval(timer);
  }, [started]);

  if (elapsed < afterMs) return null;
  return (
    <p aria-live="polite" className="text-xs text-muted-foreground">
      Running query… {Math.round(elapsed / 1000)} s
    </p>
  );
}
