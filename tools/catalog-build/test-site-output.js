import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { renderFeed, renderMarkdown, renderResourcePage, renderSitemap } from './site-pages.js';

// Guards the static resource pages (escaping, status handling, sitemap/feed) and the
// landing-page behaviors that must not regress (archived hidden, no hard-coded counts).

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const indexSource = readFileSync(join(toolDirectory, '..', '..', 'index.html'), 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const base = {
  slug: 'demo', title: 'Demo <script>alert(1)</script>', type: 'script', category: 'PowerShell',
  summary: 'A "quoted" & <b>bold</b> summary', tags: ['a<b'], artifact: 'ps1', status: 'active',
  author: ['Microsoft FastTrack'], version: '1.0.0', published: '2026-01-01', updated: '2026-02-03',
  whatItIs: 'Click [bad](javascript:alert(1)) or [good](https://example.com).',
  whyUseIt: ['Reason with `code` and **bold**'],
  howToUse: '1. First\n2. Second\n\n```powershell\nGet-Date <# x #>\n```',
  prerequisites: ['Needs <img src=x onerror=alert(1)>'],
  url: 'https://github.com/microsoft/FastTrack/tree/master/scripts/demo', source: 'scripts/demo/README.md'
};
const context = resources => ({ resources, repositoryRoot: undefined });

// 1. Untrusted metadata is escaped everywhere it is rendered.
const page = renderResourcePage(base, context([base]));
assert(!page.includes('<script>alert(1)</script>'), 'Title markup must be escaped.');
assert(!page.includes('<img src=x'), 'Prerequisite markup must be escaped.');
assert(!page.includes('<b>bold</b>'), 'Summary markup must be escaped.');
assert(!/href="javascript:/i.test(page), 'javascript: links must never be rendered.');
assert(page.includes('href="https://example.com"'), 'https links must still render.');
assert(page.includes('<code>code</code>') && page.includes('<strong>bold</strong>'), 'Inline Markdown must render.');
assert(page.includes('<pre><code>Get-Date &lt;# x #&gt;'), 'Fenced code must be escaped.');
assert(!page.includes('</script>alert'), 'JSON-LD must not allow script breakout.');

// 2. Archived resources are noindex and excluded from the sitemap and feed.
const archived = { ...base, slug: 'old', title: 'Old', status: 'archived' };
assert(renderResourcePage(archived, context([archived])).includes('name="robots" content="noindex"'), 'Archived pages must be noindex.');
assert(!renderResourcePage(base, context([base])).includes('noindex'), 'Active pages must be indexable.');
const sitemap = renderSitemap([base, archived]);
assert(sitemap.includes('/r/demo/') && !sitemap.includes('/r/old/'), 'Sitemap must list active resources only.');
const feed = renderFeed([base, archived]);
assert(feed.includes('/r/demo/') && !feed.includes('/r/old/'), 'Feed must list active resources only.');

// 3. Ordered lists keep their numbering across fenced blocks.
assert(renderMarkdown('3. Third\n4. Fourth').includes('<ol start="3"'), 'Ordered lists must keep their start number.');

// 4. The landing page hides archived resources and has no hard-coded counts.
assert(indexSource.includes("r.status !== 'archived'"), 'index.html must hide archived resources by default.');
assert(!/countDisplay = "\d+"/.test(indexSource), 'index.html must not hard-code resource counts.');
assert(!/Browse all \d+ scripts/.test(indexSource), 'index.html must not hard-code the script total.');
assert(!/\d+ resource types/.test(indexSource.replace('id="heroTypeCount">Resource types', '')), 'index.html must derive the resource-type count.');

// 5. The browse cards are exactly Guides, Agents, Analytics, and Scripts, in that order.
assert(
  indexSource.includes("const TILE_TYPES = ['strategy', 'agent', 'analytics', 'script'];"),
  'The landing page cards must be Guides, Agents, Analytics, and Scripts.'
);

console.log('Static resource pages and landing-page guards are valid.');
