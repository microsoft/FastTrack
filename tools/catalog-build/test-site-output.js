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

// 5. Only the four main types have filter pills; Prompts and Skills stay hidden for now.
assert(/id: 'prompt'[^\n]*hidden: true/.test(indexSource), 'The Prompts pill must stay hidden.');
assert(/id: 'skill'[^\n]*hidden: true/.test(indexSource), 'The Skills pill must stay hidden.');
for (const id of ['strategy', 'agent', 'analytics', 'script']) {
  assert(!new RegExp(`id: '${id}'[^\\n]*hidden: true`).test(indexSource), `The ${id} pill must stay visible.`);
}

// 6. The highlight row is driven by a tag, not hand-written content.
assert(/const HIGHLIGHT = \{\s*tag: '[a-z0-9-]+'/.test(indexSource), 'index.html must define the HIGHLIGHT tag.');
assert(!/id="spotlight"/.test(indexSource), 'The hand-written spotlight must not return.');

// 7. Download buttons: only resources with a derived file get one, and clicks are tracked.
const downloadable = { ...base, slug: 'dl', title: 'Download demo', download: 'scripts/demo/My Script.ps1', downloadName: 'My Script.ps1', downloadSize: 2048 };
const downloadPage = renderResourcePage(downloadable, context([downloadable]));
assert(downloadPage.includes('href="../../scripts/demo/My%20Script.ps1"'), 'The Download link must point at the encoded file path.');
assert(downloadPage.includes('download="My Script.ps1"') && downloadPage.includes('data-event="resource_download"'), 'The Download link must name the file and fire the Clarity event.');
assert(downloadPage.includes('<span class="btn-size">2 KB</span>'), 'The Download link must show the file size.');
assert(!page.includes('resource_download'), 'A resource without a download file must not render the button.');

const catalogResources = JSON.parse(readFileSync(join(toolDirectory, '..', '..', 'catalog.json'), 'utf8')).resources;
const bySlug = slug => catalogResources.find(resource => resource.slug === slug);
assert(bySlug('agent-365-enablement-checklist')?.downloadName === 'agent-365-enablement-checklist.html', 'The checklist must download as a named single HTML file.');
assert(bySlug('microsoft-agent-365-technical-advisory')?.downloadName === 'Agent-365-Technical-Advisory.pdf', 'The advisory must download its PDF.');
assert(catalogResources.filter(resource => resource.status === 'archived').every(resource => !resource.download), 'Archived resources must not offer a download.');
assert(catalogResources.filter(resource => ['bundle', 'declarative', 'md'].includes(resource.format)).every(resource => !resource.download), 'Bundles, declarative agents and Markdown resources must not offer a download.');
assert(indexSource.includes('btnDetailDownload') && indexSource.includes("'resource_download'"), 'index.html must render the Download button and track it in Clarity.');

console.log('Static resource pages and landing-page guards are valid.');
