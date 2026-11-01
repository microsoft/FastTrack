import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { formatBytes } from './downloads.js';
// Build-time generators for the static, shareable side of the site: one crawlable
// page per resource (r/<slug>/), sitemap.xml, and an Atom feed. The interactive
// catalog (index.html) stays the browsing experience; these pages exist so every
// resource has a real URL with a proper title, description, and social preview.

export const SITE_URL = 'https://microsoft.github.io/FastTrack/';
export const REPO_URL = 'https://github.com/microsoft/FastTrack';
const CLARITY_ID = 'w810tntgw1';

const TYPE_LABELS = {
  script: 'Scripts',
  agent: 'Agents',
  strategy: 'Guides & planning',
  analytics: 'Analytics',
  prompt: 'Prompts',
  skill: 'Skills'
};
const ARTIFACT_LABELS = {
  pbix: '.pbix · Power BI',
  ps1: '.ps1 · PowerShell',
  pptx: '.pptx · Slides',
  md: '.md · Doc',
  bundle: 'bundle · Agent',
  declarative: 'declarative · Agent'
};

export const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[character]));

const encodePath = path => path.split('/').map(encodeURIComponent).join('/');

export function typeLabel(type) {
  return TYPE_LABELS[type] ?? type;
}

export function artifactLabel(resource) {
  const format = resource.artifact ?? resource.format ?? 'md';
  if (format === 'interactive') return resource.interactiveKind === 'guide' ? 'Interactive guide' : 'Interactive tool';
  return ARTIFACT_LABELS[format] ?? `.${format}`;
}

export function formatDate(iso) {
  const date = new Date(`${iso}T00:00:00Z`);
  if (Number.isNaN(date.valueOf())) return '';
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });
}

function isSafeHref(href) {
  return /^(https?:\/\/|mailto:|#|\.{0,2}\/)/i.test(href);
}

function inline(text) {
  let html = escapeHtml(text);
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (match, label, href) => (
    isSafeHref(href) ? `<a href="${href}" target="_blank" rel="noopener noreferrer">${label}</a>` : label
  ));
  return html;
}

function dedent(code) {
  const lines = code.replace(/\s+$/, '').split('\n');
  const indents = lines.filter(line => line.trim()).map(line => line.match(/^\s*/)[0].length);
  const strip = indents.length ? Math.min(...indents) : 0;
  return lines.map(line => line.slice(strip)).join('\n');
}

// Mirrors the catalog's lightweight Markdown rendering: paragraphs, ordered and
// unordered lists, inline code, bold, links, and fenced code blocks.
export function renderMarkdown(source = '') {
  const out = [];
  const fence = /```(?:[^\n]*)\n([\s\S]*?)```/g;
  let cursor = 0;
  let match;

  const textBlock = text => {
    let list = null;
    const close = () => {
      if (list) out.push(`<${list.tag}${list.start > 1 ? ` start="${list.start}"` : ''} class="steps">${list.items.join('')}</${list.tag}>`);
      list = null;
    };
    for (const raw of text.trim().split('\n')) {
      const line = raw.trim();
      if (!line) { close(); continue; }
      const ordered = line.match(/^(\d+)\.\s+(.*)/);
      const unordered = line.match(/^[-*]\s+(.*)/);
      if (ordered) {
        if (!list || list.tag !== 'ol') { close(); list = { tag: 'ol', start: Number(ordered[1]), items: [] }; }
        list.items.push(`<li>${inline(ordered[2])}</li>`);
      } else if (unordered) {
        if (!list || list.tag !== 'ul') { close(); list = { tag: 'ul', start: 1, items: [] }; }
        list.items.push(`<li>${inline(unordered[1])}</li>`);
      } else {
        close();
        out.push(`<p>${inline(line)}</p>`);
      }
    }
    close();
  };

  while ((match = fence.exec(source)) !== null) {
    textBlock(source.slice(cursor, match.index));
    out.push(`<pre><code>${escapeHtml(dedent(match[1]))}</code></pre>`);
    cursor = fence.lastIndex;
  }
  textBlock(source.slice(cursor));
  return out.join('\n');
}

export function resourcePath(resource) {
  return `r/${resource.slug}/`;
}

export function interactivePath(resource) {
  return resource.artifact === 'interactive' && resource.source
    ? resource.source.replace(/README\.md$/i, 'index.html')
    : null;
}

function ogImagePath(resource, repositoryRoot) {
  const specific = `assets/og/${resource.slug}.png`;
  if (repositoryRoot && existsSync(join(repositoryRoot, specific))) return specific;
  return 'assets/og-default.png';
}

function authorsOf(resource) {
  return Array.isArray(resource.author) ? resource.author : [resource.author].filter(Boolean);
}

function relatedResources(resource, resources) {
  const tags = new Set(resource.tags ?? []);
  const score = other => (other.tags ?? []).filter(tag => tags.has(tag)).length * 2 + (other.type === resource.type ? 1 : 0);
  return resources
    .filter(other => other.slug !== resource.slug && other.status !== 'archived' && score(other) > 0)
    .sort((a, b) => score(b) - score(a) || a.title.localeCompare(b.title))
    .slice(0, 3);
}

function jsonLd(resource) {
  const authors = authorsOf(resource).map(name => (
    name === 'Microsoft FastTrack' ? { '@type': 'Organization', name } : { '@type': 'Person', name }
  ));
  const data = {
    '@context': 'https://schema.org',
    '@type': 'CreativeWork',
    name: resource.title,
    description: resource.summary,
    url: `${SITE_URL}${resourcePath(resource)}`,
    datePublished: resource.published,
    dateModified: resource.updated,
    version: resource.version,
    inLanguage: 'en',
    keywords: (resource.tags ?? []).join(', '),
    author: authors,
    license: 'https://opensource.org/licenses/MIT',
    isPartOf: { '@type': 'WebSite', name: 'Microsoft FastTrack', url: SITE_URL }
  };
  return JSON.stringify(data).replace(/</g, '\\u003c');
}

function section(title, body) {
  return body ? `<section class="block"><h2>${title}</h2>${body}</section>` : '';
}

function siteHeader(root) {
  return `<header class="site-header">
    <div class="wrap bar">
      <a class="brand" href="${root}" aria-label="Microsoft FastTrack catalog">
        <svg viewBox="0 0 21 21" width="21" height="21" aria-hidden="true"><rect x="1" y="1" width="9" height="9" fill="#F25022"/><rect x="11" y="1" width="9" height="9" fill="#7FBA00"/><rect x="1" y="11" width="9" height="9" fill="#00A4EF"/><rect x="11" y="11" width="9" height="9" fill="#FFB900"/></svg>
        Microsoft FastTrack
      </a>
      <nav class="bar-links" aria-label="Site">
        <a href="${root}">Catalog</a>
        <a href="${REPO_URL}" target="_blank" rel="noopener">GitHub</a>
        <button class="icon-btn" id="themeToggle" type="button" aria-label="Toggle dark mode"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/></svg></button>
      </nav>
    </div>
  </header>`;
}

function siteFooter(root) {
  return `<footer class="site-footer">
    <div class="wrap">
      <div class="site-footer-brand">
        <svg viewBox="0 0 21 21" width="16" height="16" aria-hidden="true"><rect x="1" y="1" width="9" height="9" fill="#F25022"/><rect x="11" y="1" width="9" height="9" fill="#7FBA00"/><rect x="1" y="11" width="9" height="9" fill="#00A4EF"/><rect x="11" y="11" width="9" height="9" fill="#FFB900"/></svg>
        <span>Microsoft</span><span class="site-footer-brand-sep" aria-hidden="true"></span><span>FastTrack</span>
      </div>
      <p class="site-footer-disclaimer">Disclaimer: This community catalog of tools, scripts, and guidance from Microsoft FastTrack is provided as-is, without warranty of any kind, including merchantability or fitness for a particular purpose. It is not official Microsoft software, and support is not available through Microsoft support channels. Report problems through GitHub issues; there is no SLA.</p>
      <p class="site-footer-legal"><a href="https://www.microsoft.com/en-us/legal/terms-of-use" target="_blank" rel="noopener">Terms and Conditions</a><a href="https://privacy.microsoft.com/en-us/privacystatement" target="_blank" rel="noopener">Privacy Statement</a><button type="button" data-privacy-notice aria-haspopup="dialog" hidden>Privacy notice</button></p>
      <p><a href="${root}">Browse the catalog</a> · <a href="${REPO_URL}/blob/master/CONTRIBUTING.md" target="_blank" rel="noopener">Contribute</a> · <a href="${REPO_URL}/issues" target="_blank" rel="noopener">Issues</a> · <a href="${REPO_URL}/blob/master/LICENSE" target="_blank" rel="noopener">MIT License</a></p>
    </div>
  </footer>`;
}

export function renderResourcePage(resource, { resources, repositoryRoot }) {
  const slug = resource.slug;
  const canonical = `${SITE_URL}${resourcePath(resource)}`;
  const archived = resource.status === 'archived';
  const preview = resource.preview ? `../../${encodePath(resource.preview)}` : null;
  const interactive = interactivePath(resource);
  const interactiveHref = interactive ? `../../${encodePath(interactive)}` : null;
  const ogImage = `${SITE_URL}${encodePath(ogImagePath(resource, repositoryRoot))}`;
  const label = typeLabel(resource.type);
  const title = `${resource.title} | Microsoft FastTrack`;
  const description = resource.summary;
  const related = relatedResources(resource, resources);
  const issueUrl = `${REPO_URL}/issues/new?template=resource-feedback.yml&resource=${encodeURIComponent(resource.title)}&title=${encodeURIComponent(`[${resource.title}] `)}`;

  const statusBadge = archived
    ? '<span class="badge badge-archived">Archived</span>'
    : resource.status === 'preview' ? '<span class="badge badge-preview">Preview</span>' : '';

  const whyItems = (resource.whyUseIt ?? []).map(item => `<li>${inline(item)}</li>`).join('');
  const prerequisiteItems = (resource.prerequisites ?? []).map(item => `<li>${inline(item)}</li>`).join('');
  const tagLinks = (resource.tags ?? [])
    .map(tag => `<a class="tag" href="../../?tag=${encodeURIComponent(tag)}">${escapeHtml(tag)}</a>`)
    .join('');
  const detailRows = [
    ['Type', escapeHtml(label)],
    ['Category', escapeHtml(resource.category)],
    ['Format', escapeHtml(artifactLabel(resource))],
    ['Version', escapeHtml(resource.version)],
    ['Updated', escapeHtml(formatDate(resource.updated))],
    ['Author', escapeHtml(authorsOf(resource).join(', '))]
  ].filter(([, value]) => value).map(([key, value]) => `<div class="row"><dt>${key}</dt><dd>${value}</dd></div>`).join('');

  const primary = interactiveHref
    ? `<a class="btn btn-primary" href="${interactiveHref}" data-event="resource_preview">Open the ${resource.interactiveKind === 'guide' ? 'guide' : 'tool'}<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 17l9.2-9.2M17 16.2V7H8.8"/></svg></a>
       <a class="btn" href="${escapeHtml(resource.url)}" target="_blank" rel="noopener">View on GitHub</a>`
    : `<a class="btn btn-primary" href="${escapeHtml(resource.url)}" target="_blank" rel="noopener">View on GitHub<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 17l9.2-9.2M17 16.2V7H8.8"/></svg></a>`;

  const downloadSize = formatBytes(resource.downloadSize);
  const downloadButton = resource.download
    ? `
        <a class="btn" href="download/" aria-label="Download ${escapeHtml(resource.downloadName)}${downloadSize ? ` (${downloadSize})` : ''}"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v11M7.5 11l4.5 4.5 4.5-4.5M5 19h14"/></svg>Download${downloadSize ? `<span class="btn-size">${downloadSize}</span>` : ''}</a>`
    : '';

  const relatedHtml = related.length ? `
    <section class="block related">
      <h2>Related resources</h2>
      <ul class="related-list">${related.map(other => `
        <li><a href="../${other.slug}/"><strong>${escapeHtml(other.title)}</strong><span>${escapeHtml(other.summary)}</span></a></li>`).join('')}
      </ul>
    </section>` : '';

  return `<!DOCTYPE html>
<html lang="en" data-slug="${escapeHtml(slug)}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeHtml(description)}">
  <link rel="canonical" href="${canonical}">${archived ? '\n  <meta name="robots" content="noindex">' : ''}
  <meta property="og:type" content="article">
  <meta property="og:site_name" content="Microsoft FastTrack">
  <meta property="og:title" content="${escapeHtml(resource.title)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:url" content="${canonical}">
  <meta property="og:image" content="${ogImage}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeHtml(resource.title)}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <meta name="twitter:image" content="${ogImage}">
  <meta name="theme-color" content="#4f46e5">
  <link rel="icon" href="../../assets/favicon.svg" type="image/svg+xml">
  <link rel="alternate" type="application/atom+xml" title="FastTrack updates" href="../../feed.xml">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Figtree:wght@400;500;600;700&display=swap" rel="stylesheet">
  <script>try{var t=localStorage.getItem('theme');document.documentElement.setAttribute('data-theme',t||(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'))}catch(e){}</script>
  <link rel="stylesheet" href="../../assets/resource-page.css">
  <link rel="stylesheet" href="../../assets/site-footer.css">
  <script type="application/ld+json">${jsonLd(resource)}</script>
</head>
<body class="type-${escapeHtml(resource.type)}">
  ${siteHeader('../../')}

  <main class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb">
      <a href="../../">Catalog</a><span aria-hidden="true">/</span><a href="../../?type=${encodeURIComponent(resource.type)}">${escapeHtml(label)}</a><span aria-hidden="true">/</span><span aria-current="page">${escapeHtml(resource.title)}</span>
    </nav>

    <section class="hero">
      <div class="eyebrow"><span class="dot"></span>${escapeHtml(label)} · ${escapeHtml(resource.category)} ${statusBadge}</div>
      <h1>${escapeHtml(resource.title)}</h1>
      <p class="lede">${escapeHtml(resource.summary)}</p>
      <div class="actions">
        ${primary}${downloadButton}
        <button class="btn" id="copyLink" type="button" data-url="${canonical}">Copy link</button>
      </div>
      ${tagLinks ? `<div class="tags">${tagLinks}</div>` : ''}
    </section>
${archived ? '\n    <p class="notice">This resource is archived and kept for reference. It is no longer actively maintained; check the README for a current alternative.</p>\n' : ''}${resource.status === 'preview' ? '\n    <p class="notice">Preview: this resource is still maturing. Validate it in a non-production environment before relying on it.</p>\n' : ''}${preview ? `
    <figure class="preview">
      ${interactiveHref ? `<a href="${interactiveHref}" data-event="resource_preview">` : ''}<img src="${preview}" alt="Preview of ${escapeHtml(resource.title)}" width="1600" height="960" loading="lazy" decoding="async">${interactiveHref ? '</a>' : ''}
    </figure>` : ''}
    <div class="layout">
      <article>
        ${section('What it is', resource.whatItIs ? renderMarkdown(resource.whatItIs) : `<p>${escapeHtml(resource.summary)}</p>`)}
        ${section('Why use it', whyItems ? `<ul>${whyItems}</ul>` : '')}
        ${section('How to use it', resource.howToUse ? renderMarkdown(resource.howToUse) : '<p>Open the resource on GitHub and follow the instructions in its README.</p>')}
        ${section('Prerequisites', prerequisiteItems ? `<ul>${prerequisiteItems}</ul>` : '')}
        ${relatedHtml}
      </article>
      <aside>
        <dl class="details">${detailRows}</dl>
        <div class="aside-links">
          <a href="${escapeHtml(issueUrl)}" target="_blank" rel="noopener">Report a problem or suggest an update</a>
          <a href="../../#${escapeHtml(slug)}">Comments &amp; upvotes in the catalog</a>
        </div>
      </aside>
    </div>
  </main>

  ${siteFooter('../../')}
  <script src="../../assets/privacy-notice.js" defer></script>
  <script src="../../assets/resource-page.js" data-clarity="${CLARITY_ID}" defer></script>
</body>
</html>
`;
}

// The Download button opens this page, so every download is a countable page load that
// reaches resource-stats.json through the Clarity URL export. It starts the file download
// by itself and always shows a link to the same file for when scripts are blocked.
export function renderDownloadPage(resource) {
  const slug = resource.slug;
  const canonical = `${SITE_URL}${resourcePath(resource)}`;
  const size = formatBytes(resource.downloadSize);
  const fileHref = `../../../${encodePath(resource.download)}`;
  const title = `Download ${resource.downloadName} | Microsoft FastTrack`;

  return `<!DOCTYPE html>
<html lang="en" data-download-slug="${escapeHtml(slug)}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  <meta name="robots" content="noindex">
  <link rel="canonical" href="${canonical}">
  <meta name="theme-color" content="#4f46e5">
  <link rel="icon" href="../../../assets/favicon.svg" type="image/svg+xml">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Figtree:wght@400;500;600;700&display=swap" rel="stylesheet">
  <script>try{var t=localStorage.getItem('theme');document.documentElement.setAttribute('data-theme',t||(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'))}catch(e){}</script>
  <link rel="stylesheet" href="../../../assets/resource-page.css">
  <link rel="stylesheet" href="../../../assets/site-footer.css">
</head>
<body class="type-${escapeHtml(resource.type)}">
  ${siteHeader('../../../')}

  <main class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb">
      <a href="../../../">Catalog</a><span aria-hidden="true">/</span><a href="../">${escapeHtml(resource.title)}</a><span aria-hidden="true">/</span><span aria-current="page">Download</span>
    </nav>

    <section class="hero">
      <div class="eyebrow"><span class="dot"></span>Download</div>
      <h1>Your download is starting</h1>
      <p class="lede">${escapeHtml(resource.title)}: ${escapeHtml(resource.downloadName)}${size ? ` (${size})` : ''}</p>
      <div class="actions">
        <a class="btn btn-primary" href="${fileHref}" download="${escapeHtml(resource.downloadName)}" data-autodownload>Download again${size ? `<span class="btn-size">${size}</span>` : ''}</a>
        <a class="btn" href="../">Back to ${escapeHtml(resource.title)}</a>
      </div>
      <p class="fine">If the file does not save automatically, select <strong>Download again</strong>. Provided as-is under the <a href="${REPO_URL}/blob/master/LICENSE" target="_blank" rel="noopener">MIT License</a>; review it before you use it in your tenant.</p>
    </section>
  </main>

  ${siteFooter('../../../')}
  <script src="../../../assets/privacy-notice.js" defer></script>
  <script src="../../../assets/resource-page.js" data-clarity="${CLARITY_ID}" defer></script>
</body>
</html>
`;
}

const xml = value => String(value).replace(/[&<>"']/g, character => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;'
}[character]));

export function renderSitemap(resources) {
  const active = resources.filter(resource => resource.status !== 'archived');
  const latest = active.reduce((max, resource) => (resource.updated > max ? resource.updated : max), '');
  const entries = [
    `  <url><loc>${SITE_URL}</loc>${latest ? `<lastmod>${latest}</lastmod>` : ''}<priority>1.0</priority></url>`,
    ...active.map(resource => `  <url><loc>${SITE_URL}${resourcePath(resource)}</loc><lastmod>${resource.updated}</lastmod></url>`)
  ];
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries.join('\n')}\n</urlset>\n`;
}

export function renderFeed(resources) {
  const recent = resources
    .filter(resource => resource.status !== 'archived')
    .sort((a, b) => b.updated.localeCompare(a.updated) || a.title.localeCompare(b.title))
    .slice(0, 20);
  const updated = recent.length ? `${recent[0].updated}T00:00:00Z` : '1970-01-01T00:00:00Z';
  const entries = recent.map(resource => `  <entry>
    <id>${SITE_URL}${resourcePath(resource)}</id>
    <title>${xml(`${resource.title} (v${resource.version})`)}</title>
    <link href="${SITE_URL}${resourcePath(resource)}"/>
    <updated>${resource.updated}T00:00:00Z</updated>
    <summary>${xml(resource.summary)}</summary>
  </entry>`).join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>${SITE_URL}</id>
  <title>Microsoft FastTrack: new and updated resources</title>
  <subtitle>The 20 most recently updated tools, guides, agents, and scripts in the FastTrack catalog.</subtitle>
  <link href="${SITE_URL}feed.xml" rel="self"/>
  <link href="${SITE_URL}"/>
  <updated>${updated}</updated>
${entries}
</feed>
`;
}
