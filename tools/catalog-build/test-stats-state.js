import {
  clarityStateContains,
  collectClarityTotals,
  downloadSlugFromClarityUrl,
  parseClarityTraffic,
  reconcileClarityStates,
  replaceClarityDays,
  slugFromClarityUrl,
  subtractClarityTotals,
  unchangedStatsPayload
} from './stats-state.js';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// Views on both the catalog detail route (#slug) and the shareable page (/r/slug/) count.
const known = new Set(['ai-council', 'agents-cost-calculator']);
assert(slugFromClarityUrl('https://microsoft.github.io/FastTrack/#ai-council', known) === 'ai-council',
  'Hash routes must resolve to a slug.');
assert(slugFromClarityUrl('https://microsoft.github.io/FastTrack/r/agents-cost-calculator/', known) === 'agents-cost-calculator',
  'Shareable resource pages must resolve to a slug.');
assert(slugFromClarityUrl('https://microsoft.github.io/FastTrack/r/agents-cost-calculator', known) === 'agents-cost-calculator',
  'A missing trailing slash must still resolve.');
assert(slugFromClarityUrl('https://microsoft.github.io/FastTrack/r/unknown/', known) === undefined,
  'Unknown slugs must not resolve.');
assert(slugFromClarityUrl('https://microsoft.github.io/FastTrack/', known) === undefined,
  'The landing page is not a resource view.');

// Loads of the counted download page (/r/slug/download/) are downloads, never views.
const site = 'https://microsoft.github.io/FastTrack';
assert(slugFromClarityUrl(`${site}/r/ai-council/download/`, known) === undefined,
  'A download page load must not count as a resource view.');
assert(downloadSlugFromClarityUrl(`${site}/r/ai-council/download/`, known) === 'ai-council' &&
  downloadSlugFromClarityUrl(`${site}/r/ai-council/download?utm=x`, known) === 'ai-council',
  'The download page must resolve to its slug with or without the trailing slash or a query.');
assert(downloadSlugFromClarityUrl(`${site}/r/ai-council/`, known) === undefined &&
  downloadSlugFromClarityUrl(`${site}/r/unknown/download/`, known) === undefined &&
  downloadSlugFromClarityUrl(`${site}/#ai-council`, known) === undefined,
  'Only the download page of a known resource is a download.');

const row = (path, sessions, users, date) => ({
  URL: `${site}${path}`, totalSessionCount: String(sessions), distinctUserCount: String(users), ...(date ? { Date: date } : {})
});
const traffic = rows => [{ metricName: 'Traffic', information: rows }];

const rolling = parseClarityTraffic(traffic([
  row('/r/ai-council/download/', 3, 2),
  row('/r/ai-council/', 10, 6),
  row('/#ai-council', 5, 4),
  row('/r/agents-cost-calculator/download/', 1, 1),
  row('/r/unknown/download/', 9, 9),
  row('/', 99, 50)
]), known);
assert(JSON.stringify(rolling.totals.get('ai-council')) === '{"views":15,"uniques":10,"downloads":3}',
  'Views, uniques and downloads must be summed per resource in a fixed key order.');
assert(JSON.stringify(rolling.totals.get('agents-cost-calculator')) === '{"downloads":1}',
  'A resource with only downloads must not invent views.');
assert(rolling.totals.size === 2 && rolling.dated.size === 0, 'Unknown and non-resource URLs must be ignored.');

const dailyExport = parseClarityTraffic(traffic([
  row('/r/ai-council/download/', 2, 2, '2026-10-28'),
  row('/r/ai-council/', 4, 3, '2026-10-28'),
  row('/r/ai-council/download/', 1, 1, '2026-10-29')
]), known);
assert(JSON.stringify(dailyExport.dated.get('2026-10-28').get('ai-council')) === '{"views":4,"uniques":3,"downloads":2}' &&
  JSON.stringify(dailyExport.dated.get('2026-10-29').get('ai-council')) === '{"downloads":1}',
  'Dated exports must produce one bucket per day.');

const threeDays = parseClarityTraffic(traffic([row('/r/ai-council/', 9, 5), row('/r/ai-council/download/', 4, 3)]), known).totals;
const twoDays = parseClarityTraffic(traffic([row('/r/ai-council/', 6, 4), row('/r/ai-council/download/', 3, 2)]), known).totals;
assert(JSON.stringify(subtractClarityTotals(threeDays, twoDays).get('ai-council')) === '{"views":3,"uniques":1,"downloads":1}',
  'Cumulative windows must be differenced for downloads as well as views.');
const warn = console.warn;
console.warn = () => {};
const shrinking = subtractClarityTotals(
  parseClarityTraffic(traffic([row('/r/ai-council/', 9, 5), row('/r/ai-council/download/', 1, 1)]), known).totals,
  parseClarityTraffic(traffic([row('/r/ai-council/', 6, 4), row('/r/ai-council/download/', 3, 2)]), known).totals
);
console.warn = warn;
assert(JSON.stringify(shrinking.get('ai-council')) === '{"views":3,"uniques":1}',
  'A negative download difference must be skipped without dropping the views.');

const totalsState = {
  lastRun: '2026-10-29',
  days: {
    '2026-10-28': { 'ai-council': { views: 4, uniques: 3, downloads: 2 }, ghost: { views: 1 } },
    '2026-10-29': { 'ai-council': { downloads: 1 }, 'agents-cost-calculator': { views: 2 } }
  }
};
const collected = collectClarityTotals(totalsState, known);
assert(JSON.stringify(collected.get('ai-council')) === '{"views":4,"viewsUniques":3,"downloads":3}' &&
  JSON.stringify(collected.get('agents-cost-calculator')) === '{"views":2}' && !collected.has('ghost'),
  'Persisted days must add up to per-resource views and downloads for known resources only.');
assert(clarityStateContains(totalsState, { lastRun: '2026-10-29', days: { '2026-10-29': { 'ai-council': { downloads: 1 } } } }),
  'A downloads metric must be a valid persisted metric.');

const state = {
  lastRun: '2026-09-10',
  days: {
    '2026-09-10': { existing: { views: 4 } },
    '2026-09-11': { resource: { views: 2 } }
  }
};

replaceClarityDays(state, new Map([
  ['2026-09-11', new Map([['resource', { views: 5 }]])],
  ['2026-09-12', new Map([['new-resource', { views: 3 }]])]
]), '2026-09-12');

assert(state.days['2026-09-10'].existing.views === 4,
  'Daily collection must retain accumulated days outside the rolling export.');
assert(state.days['2026-09-11'].resource.views === 5,
  'A rerun must replace an overlapping daily bucket instead of double-counting it.');
assert(state.days['2026-09-12']['new-resource'].views === 3,
  'Daily collection must append newly available Clarity days.');
assert(state.lastRun === '2026-09-12', 'The state must record the latest successful run.');

const payload = {
  sources: { views: 'clarity', downloads: 'clarity', upvotes: 'github-discussions' },
  resources: { resource: { views: 5, downloads: 2 } }
};
assert(unchangedStatsPayload({ generatedAt: 'old', ...payload }, payload),
  'Timestamp-only differences must not create a new stats commit.');
assert(!unchangedStatsPayload({ ...payload, resources: {} }, payload),
  'Substantive resource changes must produce a new stats output.');

const published = {
  lastRun: '2026-09-11',
  days: {
    '2026-09-10': { existing: { views: 4 } },
    '2026-09-11': { resource: { views: 5 } }
  }
};
const staged = {
  lastRun: '2026-09-13',
  days: {
    ...published.days,
    '2026-09-12': { resource: { views: 3 } },
    '2026-09-13': { new: { views: 2, uniques: 1 } }
  }
};
const superset = reconcileClarityStates(published, staged);
assert(superset.relation === 'theirs-superset' && clarityStateContains(superset.state, staged),
  'A newer staging state must win over an older weekly publication without losing days.');

const union = reconcileClarityStates(staged, {
  lastRun: '2026-09-14',
  days: {
    ...published.days,
    '2026-09-12': { resource: { views: 8 } },
    '2026-09-13': { extra: { views: 7 } },
    '2026-09-14': { new: { views: 1 } }
  }
});
assert(union.relation === 'structured-union' &&
  union.state.days['2026-09-12'].resource.views === 8 &&
  union.state.days['2026-09-13'].new.views === 2 &&
  union.state.days['2026-09-13'].extra.views === 7,
  'Independent resources must be unioned while newer rolling-window values replace older ones.');

const sameRun = reconcileClarityStates(staged, {
  ...staged,
  days: {
    ...staged.days,
    '2026-09-13': { new: { views: 3, uniques: 4 } }
  }
});
assert(sameRun.state.days['2026-09-13'].new.views === 3 &&
  sameRun.state.days['2026-09-13'].new.uniques === 4,
  'Same-run branch states must reconcile counters monotonically.');

console.log('Stats accumulation and idempotency behavior is valid.');
