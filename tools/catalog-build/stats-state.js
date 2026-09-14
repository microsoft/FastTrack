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
        if (!['views', 'uniques'].includes(metric) ||
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
