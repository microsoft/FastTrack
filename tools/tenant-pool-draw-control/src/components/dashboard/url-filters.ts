import { useCallback, useInsertionEffect, useRef } from "react";
import { useLocation, useSearchParams } from "react-router-dom";

import {
  encodeFilterValue,
  readUrlFilters,
  type UrlFilterDefaults,
  type UrlFilterOptions,
  writeUrlFilters,
} from "@/lib/dashboard-url-state";

// One filter state for a dashboard page, kept in the query string so the
// address (and CopyLinkButton) carries the view. Returns the current values,
// a setter that merges a patch, and a reset to the defaults. Writes replace
// the history entry, keep every other param and drop values equal to their
// default; a value absent from the URL or invalid reads as its default.
export function useUrlFilters<T extends UrlFilterDefaults>(
  defaults: T,
  options?: UrlFilterOptions<T>,
): [T, (patch: Partial<T>) => void, () => void] {
  const [params, setParams] = useSearchParams();
  const latest = useRef({ defaults, options });
  latest.current = { defaults, options };

  // Read on every render, so a predicate option is always applied, but hand
  // back the previous object while the values are the same, so pages can key
  // memos and effects on them even when defaults and options are built inline.
  const read = readUrlFilters(params, defaults, options);
  const cacheKey = JSON.stringify(
    Object.entries(read).map(([key, value]) => [key, encodeFilterValue(value)]),
  );
  const cache = useRef<{ key: string; values: T } | null>(null);
  if (cache.current?.key !== cacheKey) {
    cache.current = { key: cacheKey, values: read };
  }
  const values = cache.current.values;

  // react-router hands every functional update the query of the render whose
  // setter it is, so a second write before the next commit builds on the first
  // one's query here instead of dropping it. A queued query is tied to the
  // location it was built on, so once any navigation commits (even to the same
  // query) a write starts from the URL again. The key is the committed one: an
  // insertion effect moves it on commit, before any layout or passive effect
  // can write, and a render that never commits (a held transition) never moves
  // it, so a committed handler keeps building on the queued query. Reading it
  // from a ref keeps the setters' identity tied to the query alone, so an
  // effect that lists a setter does not re-run on every write it makes.
  const { key: locationKey } = useLocation();
  const committedKey = useRef(locationKey);
  useInsertionEffect(() => {
    committedKey.current = locationKey;
  }, [locationKey]);
  const pending = useRef<{ key: string; params: URLSearchParams } | null>(null);

  const write = useCallback(
    (next: (base: URLSearchParams) => URLSearchParams) => {
      setParams(
        (previous) => {
          const key = committedKey.current;
          const queued = pending.current?.key === key ? pending.current.params : null;
          const params = next(queued ?? previous);
          pending.current = { key, params };
          return params;
        },
        { replace: true },
      );
    },
    [setParams],
  );

  // Only the patched keys are written: an untouched key keeps its raw value,
  // so a shared value whose options have not loaded yet is not erased.
  const setFilters = useCallback(
    (patch: Partial<T>) => {
      const base = latest.current.defaults;
      const keys = Object.keys(patch).filter((key) => key in base);
      const patchedDefaults = Object.fromEntries(keys.map((key) => [key, base[key]])) as T;
      write((previous) => writeUrlFilters(previous, patch as T, patchedDefaults));
    },
    [write],
  );

  const resetFilters = useCallback(() => {
    const base = latest.current.defaults;
    write((previous) => writeUrlFilters(previous, base, base));
  }, [write]);

  return [values, setFilters, resetFilters];
}
