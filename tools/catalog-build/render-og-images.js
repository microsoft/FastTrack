import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { escapeHtml, typeLabel } from './site-pages.js';

// Optional local tool: renders branded 1200x630 social cards (assets/og/<slug>.png),
// the default card (assets/og-default.png), and the GitHub social preview
// (assets/social-preview.png) with a locally installed Edge or Chrome.
//
//   npm run og                 render cards that are missing
//   npm run og -- --all        re-render every card
//   BROWSER_PATH=... npm run og   use a specific browser binary
//
// Cards are committed, so CI never needs a browser. Resources without a card fall
// back to assets/og-default.png.

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const renderAll = process.argv.includes('--all');

const TYPE_COLORS = {
  script: '#34d399', agent: '#818cf8', strategy: '#fb923c',
  analytics: '#38bdf8', prompt: '#f472b6', skill: '#a1a1aa'
};

function findBrowser() {
  const candidates = [
    process.env.BROWSER_PATH,
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/microsoft-edge',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium'
  ].filter(Boolean);
  const found = candidates.find(path => existsSync(path));
  if (!found) throw new Error('No Edge or Chrome found. Set BROWSER_PATH to a Chromium-based browser.');
  return found;
}

const baseCss = `
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { width: 100%; height: 100%; }
  body { font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; background: #0a0a0b; color: #ededed; overflow: hidden; position: relative; }
  body::after { content: ''; position: absolute; width: 900px; height: 900px; right: -300px; top: -420px; background: radial-gradient(circle, var(--accent) 0%, transparent 65%); opacity: 0.22; }
  .card { position: relative; z-index: 1; width: 100%; height: 100%; padding: 56px 72px; display: flex; flex-direction: column; }
  .brand { display: flex; align-items: center; gap: 14px; font-size: 26px; font-weight: 600; color: #ededed; }
  .brand svg { width: 30px; height: 30px; }
  .chip { display: inline-flex; align-items: center; gap: 10px; align-self: flex-start; margin-top: auto; padding: 8px 18px; border-radius: 999px; font-size: 22px; font-weight: 600; letter-spacing: 0.04em; text-transform: uppercase; color: var(--accent); background: color-mix(in srgb, var(--accent) 16%, transparent); border: 1px solid color-mix(in srgb, var(--accent) 45%, transparent); }
  .chip i { width: 10px; height: 10px; border-radius: 50%; background: var(--accent); }
  h1 { margin-top: 22px; font-size: 68px; line-height: 1.08; font-weight: 700; letter-spacing: -0.03em; max-width: 1020px; }
  p.sub { margin-top: 20px; font-size: 30px; line-height: 1.35; color: #a1a1aa; max-width: 980px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .foot { margin-top: 34px; display: flex; justify-content: space-between; align-items: center; font-size: 22px; color: #71717a; }
  .foot b { color: #a1a1aa; font-weight: 600; }
`;

const logo = '<svg viewBox="0 0 21 21"><rect x="1" y="1" width="9" height="9" fill="#F25022"/><rect x="11" y="1" width="9" height="9" fill="#7FBA00"/><rect x="1" y="11" width="9" height="9" fill="#00A4EF"/><rect x="11" y="11" width="9" height="9" fill="#FFB900"/></svg>';

function cardHtml({ accent, chip, title, summary, footLeft }) {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>:root{--accent:${accent}}${baseCss}</style></head>
<body><div class="card">
  <div class="brand">${logo}Microsoft FastTrack</div>
  <div class="chip"><i></i>${escapeHtml(chip)}</div>
  <h1>${escapeHtml(title)}</h1>
  <p class="sub">${escapeHtml(summary)}</p>
  <div class="foot"><span>${escapeHtml(footLeft)}</span><b>microsoft.github.io/FastTrack</b></div>
</div></body></html>`;
}

function shrinkTitle(html, title) {
  const size = title.length > 60 ? 52 : title.length > 40 ? 60 : 68;
  return html.replace('font-size: 68px;', `font-size: ${size}px;`);
}

function screenshot(browser, html, output, width, height, workDirectory) {
  const page = join(workDirectory, 'card.html');
  writeFileSync(page, html);
  mkdirSync(dirname(output), { recursive: true });
  // A throwaway profile keeps headless runs independent of any open browser window, and the
  // timeout plus one retry stops a rare hung render from stalling the whole batch.
  const args = [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
    `--user-data-dir=${join(workDirectory, 'profile')}`,
    `--window-size=${width},${height}`, `--screenshot=${output}`, pathToFileURL(page).href
  ];
  for (let attempt = 1; attempt <= 2; attempt += 1) {
    try {
      execFileSync(browser, args, { stdio: 'ignore', timeout: 45000 });
      if (existsSync(output)) return;
    } catch (error) {
      if (attempt === 2) throw new Error(`Could not render ${output}: ${error.message}`);
    }
  }
}

const browser = findBrowser();
const workDirectory = mkdtempSync(join(tmpdir(), 'fasttrack-og-'));
try {
  const catalog = JSON.parse(readFileSync(join(repositoryRoot, 'catalog.json'), 'utf8'));
  const defaultCard = cardHtml({
    accent: '#818cf8',
    chip: 'Open-source catalog',
    title: 'Tools & guides for Microsoft 365 Copilot and agents',
    summary: 'Field-tested guides, agents, scripts, and analytics to plan, deploy, govern, and measure Microsoft 365 Copilot and Agent 365.',
    footLeft: 'Guides · Agents · Scripts · Analytics'
  });
  const defaultOutput = join(repositoryRoot, 'assets', 'og-default.png');
  const socialOutput = join(repositoryRoot, 'assets', 'social-preview.png');
  if (renderAll || !existsSync(defaultOutput) || !existsSync(socialOutput)) {
    screenshot(browser, defaultCard, defaultOutput, 1200, 630, workDirectory);
    screenshot(browser, defaultCard, socialOutput, 1280, 640, workDirectory);
    console.log('Rendered assets/og-default.png and assets/social-preview.png');
  }

  let rendered = 0;
  for (const resource of catalog.resources) {
    if (resource.status === 'archived') continue;
    const output = join(repositoryRoot, 'assets', 'og', `${resource.slug}.png`);
    if (!renderAll && existsSync(output)) continue;
    const html = shrinkTitle(cardHtml({
      accent: TYPE_COLORS[resource.type] ?? '#818cf8',
      chip: `${typeLabel(resource.type)} · ${resource.category}`,
      title: resource.title,
      summary: resource.summary,
      footLeft: (resource.tags ?? []).slice(0, 4).join(' · ')
    }), resource.title);
    screenshot(browser, html, output, 1200, 630, workDirectory);
    rendered += 1;
  }
  console.log(`Rendered ${rendered} resource card${rendered === 1 ? '' : 's'} in assets/og/`);

  // Drop cards for resources that were removed or archived so stale images never accumulate.
  const keep = new Set(catalog.resources.filter(resource => resource.status !== 'archived').map(resource => `${resource.slug}.png`));
  let removed = 0;
  for (const file of readdirSync(join(repositoryRoot, 'assets', 'og'))) {
    if (file.endsWith('.png') && !keep.has(file)) {
      rmSync(join(repositoryRoot, 'assets', 'og', file));
      removed += 1;
    }
  }
  if (removed) console.log(`Removed ${removed} stale card${removed === 1 ? '' : 's'}.`);
} finally {
  rmSync(workDirectory, { recursive: true, force: true });
}
