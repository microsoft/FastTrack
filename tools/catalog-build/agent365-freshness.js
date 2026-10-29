// Weekly freshness report for the Agent 365 Customer Implementation Guide and Enablement Checklist.
// It reads both files, checks every Microsoft Learn link they cite, and reports what needs a human
// review. It never edits content.
//
//   node agent365-freshness.js [--offline] [--out report.md] [--issue-out issue.md] [--json report.json]
//                              [--max-age-days 30] [--concurrency 6]
//
// Exit code 0 means a report was produced (it may still contain findings). Exit code 2 means the
// check could not run: a file's format changed, or Microsoft Learn was mostly unreachable.
import { appendFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { assertParsed, checkSync, loadChecklist, loadGuide } from './agent365-content.js';

const USER_AGENT = 'FastTrack-content-freshness (+https://github.com/microsoft/FastTrack)';
const sleep = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

export function daysBetween(from, to) {
  return Math.floor((Date.parse(to) - Date.parse(from)) / 86400000);
}

function comparablePath(url) {
  return new URL(url).pathname.replace(/^\/[a-z]{2}-[a-z]{2}(?=\/)/i, '').replace(/\/$/, '').toLowerCase();
}

export function classifyResponse(requestedUrl, result) {
  if (result.error) return { kind: 'unreachable', detail: result.error };
  if (result.status === 404 || result.status === 410) return { kind: 'broken', detail: `HTTP ${result.status}` };
  if (result.status >= 400) return { kind: 'unreachable', detail: `HTTP ${result.status}` };
  if (result.finalUrl && comparablePath(result.finalUrl) !== comparablePath(requestedUrl)) {
    return { kind: 'moved', detail: result.finalUrl.replace(/[#?].*$/, ''), updatedAt: result.updatedAt };
  }
  return { kind: 'ok', updatedAt: result.updatedAt };
}

function metaDate(head, name) {
  const match = new RegExp(`<meta[^>]+name="${name}"[^>]+content="([^"]*)"`, 'i').exec(head);
  return match ? match[1].slice(0, 10) : '';
}

async function readHead(response) {
  if (!response.body) return '';
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let text = '';
  try {
    while (text.length < 300000) {
      const { done, value } = await reader.read();
      if (done) break;
      text += decoder.decode(value, { stream: true });
      if (text.includes('</head>')) break;
    }
  } finally {
    await reader.cancel().catch(() => {});
  }
  return text;
}

export async function fetchPage(url, fetchImpl = fetch) {
  let lastError = '';
  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (attempt) await sleep(1000 * attempt * attempt);
    try {
      const response = await fetchImpl(url, {
        redirect: 'follow',
        headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en-US' },
        signal: AbortSignal.timeout(20000)
      });
      if (response.status === 429 || response.status >= 500) {
        lastError = `HTTP ${response.status}`;
        await response.body?.cancel().catch(() => {});
        continue;
      }
      const head = await readHead(response);
      return {
        status: response.status,
        finalUrl: response.url,
        updatedAt: metaDate(head, 'updated_at') || metaDate(head, 'ms.date')
      };
    } catch (error) {
      lastError = error.message;
    }
  }
  return { error: lastError || 'request failed' };
}

async function mapLimit(items, limit, worker) {
  const results = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    for (;;) {
      const index = next;
      next += 1;
      if (index >= items.length) return;
      results[index] = await worker(items[index]);
    }
  }));
  return results;
}

// Which artifact cites each Learn URL, and from where.
export function collectCitations(guide, checklist) {
  const citations = new Map();
  const add = (artifact, urls) => {
    for (const [url, labels] of urls) {
      if (!citations.has(url)) citations.set(url, { guide: [], checklist: [] });
      citations.get(url)[artifact].push(...labels);
    }
  };
  add('guide', guide.urls);
  add('checklist', checklist.urls);
  return citations;
}

export function buildReport({ guide, checklist, sync, pages, citations, now, maxAgeDays, offline }) {
  const today = now.slice(0, 10);
  const artifacts = {
    guide: { name: 'Customer Implementation Guide', version: guide.version, reviewed: guide.reviewed, basis: 'README `updated` date' },
    checklist: { name: 'Enablement Checklist', version: checklist.version, reviewed: checklist.reviewed, basis: '`CONTENT_REVIEWED` date' }
  };
  for (const artifact of Object.values(artifacts)) artifact.ageDays = daysBetween(artifact.reviewed, today);

  const links = { checked: 0, broken: [], moved: [], unreachable: 0, updated: { guide: [], checklist: [] } };
  if (!offline) {
    for (const [url, citedBy] of citations) {
      const page = pages.get(url);
      if (!page) continue;
      links.checked += 1;
      if (page.kind === 'unreachable') links.unreachable += 1;
      else if (page.kind === 'broken') links.broken.push({ url, detail: page.detail, citedBy });
      else if (page.kind === 'moved') links.moved.push({ url, detail: page.detail, citedBy });
      if (page.kind === 'ok' || page.kind === 'moved') {
        for (const key of ['guide', 'checklist']) {
          if (citedBy[key].length && page.updatedAt && page.updatedAt > artifacts[key].reviewed) {
            links.updated[key].push({ url, updatedAt: page.updatedAt, citedBy: citedBy[key] });
          }
        }
      }
    }
    links.updated.guide.sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
    links.updated.checklist.sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
  }

  const timing = artifacts.guide.reviewed > artifacts.checklist.reviewed
    ? `The guide was updated on ${artifacts.guide.reviewed}, after the checklist was last reviewed on ${artifacts.checklist.reviewed}. Re-check the checklist tasks that point at changed guide sections.`
    : '';
  const reasons = [];
  if (sync.broken.length) reasons.push(`${sync.broken.length} checklist reference(s) no longer resolve in the guide`);
  for (const artifact of Object.values(artifacts)) {
    if (artifact.ageDays > maxAgeDays) reasons.push(`${artifact.name} was last reviewed ${artifact.ageDays} days ago (limit ${maxAgeDays})`);
  }
  if (timing) reasons.push('The guide is newer than the checklist review');
  if (links.broken.length) reasons.push(`${links.broken.length} broken Learn link(s)`);
  if (links.moved.length) reasons.push(`${links.moved.length} moved Learn link(s)`);
  for (const key of ['guide', 'checklist']) {
    if (links.updated[key].length) reasons.push(`${links.updated[key].length} Learn page(s) updated since the ${artifacts[key].name} was last reviewed`);
  }
  return { generatedAt: now, maxAgeDays, offline, artifacts, timing, sync, links, reasons, actionable: reasons.length > 0 };
}

const escapeCell = text => String(text).replace(/\|/g, '\\|').replace(/\r?\n/g, ' ');

function citedByCell(labels) {
  const unique = [...new Set(labels)];
  const shown = unique.slice(0, 2).map(escapeCell).join('<br>');
  return unique.length > 2 ? `${shown}<br>and ${unique.length - 2} more` : shown;
}

function table(headers, rows, limit) {
  const shown = rows.slice(0, limit);
  const lines = [`| ${headers.join(' | ')} |`, `| ${headers.map(() => '---').join(' | ')} |`, ...shown.map(row => `| ${row.join(' | ')} |`)];
  if (rows.length > shown.length) lines.push('', `_Showing ${shown.length} of ${rows.length}. The workflow run summary lists every row._`);
  return lines.join('\n');
}

export function renderMarkdown(report, limit = Infinity) {
  const { artifacts, sync, links } = report;
  const out = [];
  out.push('## Agent 365 content freshness report', '');
  out.push(`Checked **${report.generatedAt.slice(0, 10)}**. This is a review list, not an automatic change. A maintainer decides what to update.`, '');
  out.push('| | Version | Last reviewed | Days ago |', '| --- | --- | --- | --- |');
  for (const artifact of Object.values(artifacts)) {
    out.push(`| ${artifact.name} | ${artifact.version} | ${artifact.reviewed} (${artifact.basis}) | ${artifact.ageDays}${artifact.ageDays > report.maxAgeDays ? ' ⚠️' : ''} |`);
  }
  out.push('');
  if (!report.actionable) {
    out.push('✅ Nothing needs attention: references resolve, reviews are recent, and no cited Learn page changed since the last review.', '');
  } else {
    out.push('### What needs attention', '', ...report.reasons.map(reason => `- ${reason}`), '');
  }

  out.push('### Guide and checklist alignment', '');
  out.push(`The checklist points at the guide from ${sync.referenceCount} distinct references. ${sync.broken.length ? `**${sync.broken.length} no longer resolve.**` : 'All of them resolve to a section or step in the guide.'}`, '');
  if (report.timing) out.push(`⚠️ ${report.timing}`, '');
  if (sync.broken.length) {
    out.push(table(['Checklist reference', 'Problem', 'Tasks'], sync.broken.map(item => [escapeCell(item.label), escapeCell(item.problems.join(' ')), citedByCell(item.tasks)]), limit), '');
  }
  if (sync.unverified.length) {
    out.push(`${sync.unverified.length} reference(s) describe a step without its code, so they cannot be verified automatically: ${sync.unverified.map(item => `\`${escapeCell(item.label)}\``).join(', ')}.`, '');
  }
  if (sync.uncovered.length) {
    out.push(`<details><summary>${sync.uncovered.length} guide step(s) have no checklist task pointing at them</summary>`, '');
    out.push(table(['Step', 'Title'], sync.uncovered.map(entry => [`\`${entry.code}\``, escapeCell(entry.title)]), limit), '', '</details>', '');
  }

  out.push('### Microsoft Learn links', '');
  if (report.offline) {
    out.push('Skipped (offline run).', '');
  } else {
    out.push(`Checked ${links.checked} distinct Learn pages: ${links.broken.length} broken, ${links.moved.length} moved, ${links.unreachable} could not be checked.`, '');
    if (links.broken.length) {
      out.push('#### Broken', '', table(['Link', 'Result', 'Cited by'], links.broken.map(item => [item.url, item.detail, citedByCell([...item.citedBy.guide, ...item.citedBy.checklist])]), limit), '');
    }
    if (links.moved.length) {
      out.push('#### Moved', '', table(['Link', 'Now at', 'Cited by'], links.moved.map(item => [item.url, item.detail, citedByCell([...item.citedBy.guide, ...item.citedBy.checklist])]), limit), '');
    }
    for (const key of ['checklist', 'guide']) {
      const rows = links.updated[key];
      if (!rows.length) continue;
      out.push(`#### Updated on Learn since the ${artifacts[key].name} was last reviewed (${artifacts[key].reviewed})`, '');
      out.push(table(['Page', 'Updated', 'Cited by'], rows.map(item => [item.url, item.updatedAt, citedByCell(item.citedBy)]), limit), '');
    }
  }

  out.push('### How to clear this', '');
  out.push('1. Open the changed Learn pages, update any task or step that no longer matches, and fix broken or moved links.');
  out.push('2. When you finish a review, record it: set `CONTENT_REVIEWED` in the checklist, and bump `version` and `updated` in the guide README. The next run measures from that date.');
  out.push('3. Run `npm run check` in `tools/catalog-build` before opening the pull request. It also verifies that every guide reference in the checklist still resolves.', '');
  out.push('_Opened and updated by the Agent 365 Content Freshness workflow._');
  return out.join('\n');
}

function parseArguments(argv) {
  const options = { offline: false, maxAgeDays: 30, concurrency: 6 };
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === '--offline') options.offline = true;
    else if (value === '--out') options.out = argv[++index];
    else if (value === '--issue-out') options.issueOut = argv[++index];
    else if (value === '--json') options.json = argv[++index];
    else if (value === '--max-age-days') options.maxAgeDays = Number(argv[++index]);
    else if (value === '--concurrency') options.concurrency = Number(argv[++index]);
    else throw new Error(`Unknown option ${value}`);
  }
  if (!Number.isFinite(options.maxAgeDays) || options.maxAgeDays < 1) throw new Error('--max-age-days must be a positive number.');
  return options;
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const guide = loadGuide();
  const checklist = loadChecklist();
  assertParsed(guide, checklist);
  const sync = checkSync(guide, checklist);
  const citations = collectCitations(guide, checklist);

  const pages = new Map();
  if (!options.offline) {
    const urls = [...citations.keys()];
    console.log(`Checking ${urls.length} Microsoft Learn pages...`);
    await mapLimit(urls, options.concurrency, async url => {
      pages.set(url, classifyResponse(url, await fetchPage(url)));
    });
    const unreachable = [...pages.values()].filter(page => page.kind === 'unreachable').length;
    if (unreachable > urls.length * 0.25) {
      console.error(`Could not check Microsoft Learn: ${unreachable} of ${urls.length} requests failed. Not reporting link results.`);
      process.exitCode = 2;
      return;
    }
  }

  const report = buildReport({ guide, checklist, sync, pages, citations, now: new Date().toISOString(), maxAgeDays: options.maxAgeDays, offline: options.offline });
  const full = renderMarkdown(report);
  console.log(full);
  if (options.out) writeFileSync(options.out, full);
  if (options.issueOut) writeFileSync(options.issueOut, renderMarkdown(report, 40));
  if (options.json) writeFileSync(options.json, JSON.stringify(report, null, 2));
  if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, `${full}\n`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch(error => {
    console.error(error.message);
    process.exitCode = 2;
  });
}
