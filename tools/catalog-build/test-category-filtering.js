import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// Validates the root catalog's "Guides & planning" cross-listing behavior.
// Interactive guides (format: interactive + interactiveKind: guide) must surface
// under Guides & planning (the strategy category) in addition to their own type,
// without ever mutating r.type, duplicating cards, or broadening other categories.

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const indexPath = join(toolDirectory, '..', '..', 'index.html');
const indexSource = readFileSync(indexPath, 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// --- Extract the real predicate shipped in index.html (single source of truth) ---
const predicateMatch = indexSource.match(
  /\/\* @category-predicate:start \*\/([\s\S]*?)\/\* @category-predicate:end \*\//
);
assert(predicateMatch, 'Could not locate the @category-predicate block in index.html.');
const predicateSource = predicateMatch[1];

const factory = new Function(`${predicateSource}; return { matchesCategory, isInteractiveGuide };`);
const { matchesCategory, isInteractiveGuide } = factory();

// --- Wiring assertions: every matcher/count path must use the central helper ---
assert(
  (indexSource.match(/const matchesCategory =/g) || []).length === 1,
  'matchesCategory must be defined exactly once (one central reusable predicate).'
);
assert(
  indexSource.includes('const matchType = matchesCategory(r, state.type);'),
  'Main filtering (getFilteredResources) must use matchesCategory.'
);
assert(
  indexSource.includes('const matchType = matchesCategory(r, tempState.type);'),
  'Temp-state tag/search facet filtering must use matchesCategory.'
);
assert(
  (indexSource.match(/RESOURCES\.filter\(r => matchesCategory\(r, t\.id\)\)\.length/g) || []).length === 2,
  'Category tile counts and pill counts must both use matchesCategory.'
);
assert(
  indexSource.includes('RESOURCES.filter(r => r.type === resource.type'),
  'Related resources must keep original-type (r.type) semantics, not the cross-listing.'
);
assert(
  !indexSource.includes('r.type === state.type') && !indexSource.includes('r.type === tempState.type'),
  'No filtering path may keep the old direct r.type === state.type comparison.'
);

// --- Representative dataset covering every required scenario ---
const dataset = [
  { slug: 'strategy-md', type: 'strategy', format: 'md' },
  { slug: 'strategy-guide', type: 'strategy', format: 'interactive', interactiveKind: 'guide' },
  { slug: 'strategy-tool', type: 'strategy', format: 'interactive' },
  { slug: 'analytics-report', type: 'analytics', format: 'pbix' },
  { slug: 'analytics-guide', type: 'analytics', format: 'interactive', interactiveKind: 'guide' },
  { slug: 'analytics-tool', type: 'analytics', format: 'interactive' },
  { slug: 'prompt-interactive-nokind', type: 'prompt', format: 'interactive' },
  { slug: 'agent-bundle', type: 'agent', format: 'bundle' },
  { slug: 'script-ps1', type: 'script', format: 'ps1' }
];
const bySlug = Object.fromEntries(dataset.map(r => [r.slug, r]));

// Mirror of getFilteredResources() so scenarios exercise the same predicate wiring.
const selectSlugs = (typeId, q = '', tag = 'all') => {
  const query = q.toLowerCase();
  return dataset
    .filter(r => {
      const matchQ = !query || r.slug.toLowerCase().includes(query);
      const matchTag = tag === 'all';
      return matchQ && matchesCategory(r, typeId) && matchTag;
    })
    .map(r => r.slug);
};

// 1. Strategy markdown retained (still in strategy, still not another type).
assert(matchesCategory(bySlug['strategy-md'], 'strategy'), 'Strategy markdown must remain under Guides & planning.');
assert(matchesCategory(bySlug['strategy-md'], 'all'), 'Strategy markdown must remain in the All listing.');
assert(!matchesCategory(bySlug['strategy-md'], 'analytics'), 'Strategy markdown must not leak into Analytics.');

// 2. Analytics interactive guide appears in BOTH Analytics and Guides & planning.
assert(matchesCategory(bySlug['analytics-guide'], 'analytics'), 'Analytics guide must appear under Analytics (original type).');
assert(matchesCategory(bySlug['analytics-guide'], 'strategy'), 'Analytics guide must be cross-listed under Guides & planning.');
assert(isInteractiveGuide(bySlug['analytics-guide']), 'Analytics guide must satisfy the interactive-guide predicate.');

// 3. Unrelated interactive tool excluded from Guides & planning (stays in its own type).
assert(!matchesCategory(bySlug['analytics-tool'], 'strategy'), 'Interactive tool must not be cross-listed under Guides & planning.');
assert(matchesCategory(bySlug['analytics-tool'], 'analytics'), 'Interactive tool must remain under its own type.');

// 4. Missing interactiveKind excluded from Guides & planning.
assert(!isInteractiveGuide(bySlug['prompt-interactive-nokind']), 'Interactive resource without a kind is not a guide.');
assert(!matchesCategory(bySlug['prompt-interactive-nokind'], 'strategy'), 'Missing-kind interactive must not be cross-listed.');

// 5. No duplicate cards in any selection, including All.
for (const typeId of ['all', 'strategy', 'analytics', 'prompt', 'agent', 'script']) {
  const slugs = selectSlugs(typeId);
  assert(new Set(slugs).size === slugs.length, `Duplicate cards detected under "${typeId}".`);
}
assert(selectSlugs('all').length === dataset.length, 'All listing must include every resource exactly once.');

// 6. Counts, search, and temp-state filtering stay consistent with the cross-listed set.
const strategyCount = dataset.filter(r => matchesCategory(r, 'strategy')).length;
const expectedStrategy = ['strategy-md', 'strategy-guide', 'strategy-tool', 'analytics-guide'];
assert(strategyCount === expectedStrategy.length, `Guides & planning count must equal the cross-listed set (${expectedStrategy.length}).`);
assert(
  JSON.stringify(selectSlugs('strategy')) === JSON.stringify(expectedStrategy),
  'Guides & planning selection must equal the cross-listed set.'
);
// The count path and the main filtering path must agree.
assert(strategyCount === selectSlugs('strategy').length, 'Strategy count and strategy filtering must match.');
// Analytics count is unchanged and still includes the guide (cross-listing never removes originals).
assert(selectSlugs('analytics').length === 3, 'Analytics count must be unaffected by cross-listing.');
assert(selectSlugs('analytics').includes('analytics-guide'), 'Analytics guide must stay counted under Analytics.');
// Search within Guides & planning still honors the cross-listing.
assert(
  JSON.stringify(selectSlugs('strategy', 'analytics-guide')) === JSON.stringify(['analytics-guide']),
  'Searching within Guides & planning must find the cross-listed analytics guide.'
);
// Temp-state facet base uses the same predicate, so its membership matches the main filter.
assert(
  JSON.stringify(selectSlugs('strategy', 'guide')) ===
    JSON.stringify(dataset.filter(r => r.slug.includes('guide') && matchesCategory(r, 'strategy')).map(r => r.slug)),
  'Temp-state facet filtering must stay consistent with main filtering.'
);

console.log('Guides & planning cross-listing predicate and wiring are valid.');
