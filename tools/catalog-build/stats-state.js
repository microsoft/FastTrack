const CLARITY_METRICS = ['views', 'uniques', 'downloads'];

export function numberFrom(value) {
  const number = typeof value === 'string' && value.trim() !== '' ? Number(value) : value;
  return Number.isFinite(number) && number >= 0 ? number : undefined;
}

// Resolves a Clarity page URL to a catalog slug. The catalog's detail view uses
// `/#<slug>` and each shareable resource page lives at `/r/<slug>/`; both count as views.
// A resource's counted download page (`/r/<slug>/download/`) is not a view.
export function slugFromClarityUrl(value, knownSlugs) {
  if (typeof value !== 'string') return undefined;
  try {
    const url = new URL(value);
    const fromHash = decodeURIComponent(url.hash.slice(1));
    if (knownSlugs.has(fromHash)) return fromHash;
    const fromPath = url.pathname.match(/\/r\/([^/]+)\/?$/);
    if (fromPath) {
      const slug = decodeURIComponent(fromPath[1]);
      if (knownSlugs.has(slug)) return slug;
    }
    return undefined;
  } catch {
    return undefined;
  }
}

// Resolves the counted download page of a resource (`/r/<slug>/download/`). Each load of
// that page is one download, which is how downloads reach resource-stats.json.
export function downloadSlugFromClarityUrl(value, knownSlugs) {
  if (typeof value !== 'string') return undefined;
  try {
    const match = new URL(value).pathname.match(/\/r\/([^/]+)\/download\/?$/);
    if (!match) return undefined;
    const slug = decodeURIComponent(match[1]);
    return knownSlugs.has(slug) ? slug : undefined;
  } catch {
    return undefined;
  }
}

function orderedMetrics(metrics) {
  return Object.fromEntries(
    CLARITY_METRICS.filter(metric => metrics[metric] !== undefined).map(metric => [metric, metrics[metric]])
  );
}

function orderedBucket(bucket) {
  return new Map([...bucket].map(([slug, metrics]) => [slug, orderedMetrics(metrics)]));
}

function dateFromClarityRow(row) {
  const value = row.date ?? row.Date ?? row.day ?? row.Day;
  if (typeof value !== 'string') return undefined;
  const match = value.match(/^\d{4}-\d{2}-\d{2}/);
  return match?.[0];
}

function metricsFromClarityRow(row) {
  const explicitViews = numberFrom(
    row.pageViews ?? row.pageviews ?? row.PageViews ?? row.views ??
    row.totalScreenCount ?? row.visitsCount
  );
  const sessions = numberFrom(row.totalSessionCount ?? row.sessions ?? row.sessionCount);
  const pagesPerSession = numberFrom(
    row.pagesPerSession ?? row.PagesPerSession ?? row.PagesPerSessionPercentage
  );
  const views = explicitViews ?? (
    sessions !== undefined && pagesPerSession !== undefined
      ? sessions * pagesPerSession
      : sessions
  );
  const uniques = numberFrom(
    row.distinctUserCount ?? row.distantUserCount ?? row.uniqueUserCount ??
    row.uniqueUsers ?? row.users
  );
  return {
    ...(views !== undefined ? { views: Math.round(views) } : {}),
    ...(uniques !== undefined ? { uniques: Math.round(uniques) } : {})
  };
}

// Turns a Clarity export (URL dimension) into per-resource metrics: page views of a
// resource's pages, and loads of its download page counted as downloads.
export function parseClarityTraffic(data, knownSlugs) {
  const traffic = Array.isArray(data)
    ? data.find(metric => metric?.metricName === 'Traffic')
    : undefined;
  if (!traffic || !Array.isArray(traffic.information)) {
    throw new Error('Clarity response did not include the Traffic metric');
  }
  const totals = new Map();
  const dated = new Map();

  for (const row of traffic.information) {
    const url = row.URL ?? row.Url ?? row.url;
    const viewSlug = slugFromClarityUrl(url, knownSlugs);
    const downloadSlug = viewSlug ? undefined : downloadSlugFromClarityUrl(url, knownSlugs);
    const slug = viewSlug ?? downloadSlug;
    if (!slug) continue;
    const metrics = metricsFromClarityRow(row);
    if (metrics.views === undefined) continue;

    const date = dateFromClarityRow(row);
    const target = date
      ? (dated.get(date) ?? new Map())
      : totals;
    const current = target.get(slug) ?? {};
    if (downloadSlug) {
      current.downloads = (current.downloads ?? 0) + metrics.views;
    } else {
      current.views = (current.views ?? 0) + metrics.views;
      if (metrics.uniques !== undefined) current.uniques = (current.uniques ?? 0) + metrics.uniques;
    }
    target.set(slug, current);
    if (date) dated.set(date, target);
  }

  return {
    totals: orderedBucket(totals),
    dated: new Map([...dated].map(([date, bucket]) => [date, orderedBucket(bucket)]))
  };
}

// Cumulative 1/2/3-day windows are differenced into daily buckets.
export function subtractClarityTotals(larger, smaller) {
  const result = new Map();
  for (const [slug, metrics] of larger) {
    const previous = smaller.get(slug);
    const entry = {};
    for (const metric of ['views', 'downloads']) {
      if (metrics[metric] === undefined) continue;
      const difference = metrics[metric] - (previous?.[metric] ?? 0);
      if (difference < 0) {
        console.warn(`Warning: Clarity returned a negative ${metric} window difference for ${slug}; skipping it.`);
        continue;
      }
      entry[metric] = Math.round(difference);
    }
    if (entry.views !== undefined && metrics.uniques !== undefined && previous?.uniques !== undefined) {
      const uniques = metrics.uniques - previous.uniques;
      if (uniques >= 0) entry.uniques = Math.round(uniques);
    }
    if (Object.keys(entry).length > 0) result.set(slug, orderedMetrics(entry));
  }
  return result;
}

// Sums the persisted daily buckets into per-resource totals.
export function collectClarityTotals(state, knownSlugs) {
  const totals = new Map();
  for (const bucket of Object.values(state.days)) {
    if (!bucket || typeof bucket !== 'object') continue;
    for (const [slug, metrics] of Object.entries(bucket)) {
      if (!knownSlugs.has(slug) || !metrics || typeof metrics !== 'object') continue;
      const total = totals.get(slug) ?? {};
      for (const [metric, key] of [['views', 'views'], ['uniques', 'viewsUniques'], ['downloads', 'downloads']]) {
        const value = numberFrom(metrics[metric]);
        if (value !== undefined) total[key] = (total[key] ?? 0) + Math.round(value);
      }
      totals.set(slug, total);
    }
  }
  return new Map([...totals].map(([slug, total]) => [slug, Object.fromEntries(
    ['views', 'viewsUniques', 'downloads'].filter(key => total[key] !== undefined).map(key => [key, total[key]])
  )]));
}

export function replaceClarityDays(state, buckets, lastRun) {
  for (const [date, metrics] of buckets) {
    state.days[date] = Object.fromEntries(
      [...metrics].sort(([left], [right]) => left.localeCompare(right))
    );
  }
  state.lastRun = lastRun;
}

function isRecord(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function sortedRecord(entries) {
  return Object.fromEntries([...entries].sort(([left], [right]) => left.localeCompare(right)));
}

function validateClarityState(state, label) {
  if (!isRecord(state) || !isRecord(state.days)) {
    throw new Error(`${label} Clarity state must contain a days object.`);
  }
  if (typeof state.lastRun !== 'string' ||
      (state.lastRun !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(state.lastRun))) {
    throw new Error(`${label} Clarity state has an invalid lastRun.`);
  }
  for (const [date, resources] of Object.entries(state.days)) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !isRecord(resources)) {
      throw new Error(`${label} Clarity state has an invalid day bucket: ${date}.`);
    }
    for (const [slug, metrics] of Object.entries(resources)) {
      if (!slug || !isRecord(metrics)) {
        throw new Error(`${label} Clarity state has invalid metrics for ${date}/${slug}.`);
      }
      for (const [metric, value] of Object.entries(metrics)) {
        if (!CLARITY_METRICS.includes(metric) ||
            !Number.isFinite(value) || value < 0 || !Number.isInteger(value)) {
          throw new Error(`${label} Clarity state has invalid ${metric} for ${date}/${slug}.`);
        }
      }
    }
  }
}

function equalJson(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function clarityStateContains(container, candidate) {
  validateClarityState(container, 'Container');
  validateClarityState(candidate, 'Candidate');
  return Object.entries(candidate.days).every(([date, resources]) =>
    Object.entries(resources).every(([slug, metrics]) =>
      equalJson(container.days[date]?.[slug], metrics)
    )
  );
}

export function reconcileClarityStates(ours, theirs) {
  validateClarityState(ours, 'Ours');
  validateClarityState(theirs, 'Theirs');

  const oursContainsTheirs = clarityStateContains(ours, theirs);
  const theirsContainsOurs = clarityStateContains(theirs, ours);
  const newerState = ours.lastRun === theirs.lastRun
    ? null
    : (ours.lastRun > theirs.lastRun ? ours : theirs);
  const days = {};

  for (const date of [...new Set([...Object.keys(ours.days), ...Object.keys(theirs.days)])].sort()) {
    const resources = new Map();
    for (const [state, source] of [
      [ours, ours.days[date] ?? {}],
      [theirs, theirs.days[date] ?? {}]
    ]) {
      for (const [slug, metrics] of Object.entries(source)) {
        const existing = resources.get(slug);
        if (existing && !equalJson(existing, metrics)) {
          if (!newerState) {
            resources.set(slug, sortedRecord(new Map(
              [...new Set([...Object.keys(existing), ...Object.keys(metrics)])]
                .map(metric => [metric, Math.max(existing[metric] ?? 0, metrics[metric] ?? 0)])
            )));
            continue;
          }
          if (state !== newerState) continue;
        }
        resources.set(slug, metrics);
      }
    }
    days[date] = sortedRecord(resources);
  }

  const extraKeys = new Set([
    ...Object.keys(ours).filter(key => !['lastRun', 'days'].includes(key)),
    ...Object.keys(theirs).filter(key => !['lastRun', 'days'].includes(key))
  ]);
  const extras = {};
  for (const key of extraKeys) {
    if (Object.hasOwn(ours, key) && Object.hasOwn(theirs, key) &&
        !equalJson(ours[key], theirs[key])) {
      throw new Error(`Clarity state has competing top-level ${key} values.`);
    }
    extras[key] = Object.hasOwn(theirs, key) ? theirs[key] : ours[key];
  }

  return {
    state: {
      ...sortedRecord(Object.entries(extras)),
      lastRun: [ours.lastRun, theirs.lastRun].sort().at(-1),
      days
    },
    relation: oursContainsTheirs
      ? (theirsContainsOurs ? 'equal' : 'ours-superset')
      : (theirsContainsOurs ? 'theirs-superset' : 'structured-union')
  };
}

export function unchangedStatsPayload(previous, next) {
  if (!previous || typeof previous !== 'object') return false;
  return JSON.stringify(previous.sources) === JSON.stringify(next.sources) &&
    JSON.stringify(previous.resources) === JSON.stringify(next.resources);
}
