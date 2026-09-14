import {
  clarityStateContains,
  reconcileClarityStates,
  replaceClarityDays,
  unchangedStatsPayload
} from './stats-state.js';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

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
  sources: { views: 'clarity', upvotes: 'github-discussions' },
  resources: { resource: { views: 5 } }
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
