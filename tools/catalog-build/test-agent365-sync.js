import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as yaml from 'js-yaml';
import {
  assertParsed,
  checkSync,
  decodeEntities,
  loadChecklist,
  loadGuide,
  normalizeLearnUrl,
  parseChecklist,
  parseGuide,
  repositoryRoot,
  resolveReference
} from './agent365-content.js';
import { buildReport, classifyResponse, collectCitations, daysBetween, fetchPage, renderMarkdown } from './agent365-freshness.js';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(decodeEntities('a &amp;amp; b &quot;c&quot;') === 'a & b "c"', 'Entities must decode through nested escaping.');
assert(normalizeLearnUrl('https://learn.microsoft.com/purview/x#y') === 'https://learn.microsoft.com/en-us/purview/x',
  'Learn links must drop fragments and gain the locale so duplicates collapse.');
assert(normalizeLearnUrl('https://learn.microsoft.com/en-us/purview/x/?a=1') === 'https://learn.microsoft.com/en-us/purview/x',
  'Learn links must drop query strings and trailing slashes.');

const guideFixture = [
  '<h2 class=&quot;x&quot;>01. Tenant Foundation &amp;amp; RBAC</h2>',
  '<article class=&quot;task-card&quot; data-part=&quot;A&quot; data-task=&quot;foundation-1a&quot;>',
  '<h4>1a · License and enable</h4><a href=&quot;https://learn.microsoft.com/en-us/microsoft-agent-365/overview&quot;>x</a>',
  '<h2>04. Microsoft Purview</h2><h4>4.04a · Enable Purview Data Security</h4>',
  '<a href="https://learn.microsoft.com/purview/ai-agent-365#top">y</a>',
  '<h2>Power Platform for Agent 365</h2><h4>PP3 · Set data policies</h4>',
  '<h2>12. Custom pro-code agents</h2><h3>12b · Phase 0 — Decide the tier</h3>',
  '<h2>05. SharePoint</h2><h4>5·0 · Confirm entitlement</h4>'
].join('\n');
const guide = parseGuide(guideFixture);
assert(guide.sections.size === 5 && guide.sections.has('PP') && guide.sections.has('01'), 'The guide reader must find numbered sections and Power Platform.');
assert(['1a', '4.04a', 'PP3', '12b', '5·0'].every(code => guide.codes.has(code)), 'The guide reader must find every step code format.');
assert(guide.codes.get('4.04a').section === '04' && guide.codes.get('PP3').section === 'PP', 'Steps must record their section.');
assert(guide.tasks.length === 1 && guide.tasks[0].id === 'foundation-1a', 'The guide reader must find task cards.');
assert(guide.urls.get('https://learn.microsoft.com/en-us/purview/ai-agent-365')?.has('Guide 4.04a Enable Purview Data Security'),
  'Guide links must be attributed to the step they appear under.');

const checklistFixture = `var CONTENT_VERSION = "2.9.1";
var CONTENT_REVIEWED = "2026-10-22";
{ "id": "defender", "code": "DEF", "name": "Defender & hunting", "tasks": [
{ "n": 1, "role": "Security", "title": "Verify \\"Security for AI\\"", "deep": "02 Microsoft Defender, AI agent inventory",
  "links": [["Doc", "https://learn.microsoft.com/en-us/defender/x"]] },
{ "n": 2, "role": "Security", "title": "Second task", "links": [] } ] }`;
const checklist = parseChecklist(checklistFixture);
assert(checklist.version === '2.9.1' && checklist.reviewed === '2026-10-22', 'The checklist reader must find its version and review date.');
assert(checklist.tasks.length === 2 && checklist.tasks[0].title === 'Verify "Security for AI"' && checklist.tasks[0].workstream === 'Defender & hunting',
  'The checklist reader must find tasks, decode titles, and attach workstreams.');
assert(checklist.tasks[0].deep.startsWith('02 Microsoft Defender') && checklist.tasks[1].deep === '', 'The checklist reader must read per-task guide references.');
assert([...checklist.urls.keys()].length === 1, 'The checklist reader must collect Learn links.');

const richGuide = parseGuide([
  '<h2>02. Microsoft Defender for Agent 365</h2><h4>2.07 · Review AI agent inventory and posture</h4>',
  '<h2>04. Microsoft Purview</h2><h4>4.04a · Enable Purview Data Security</h4>',
  '<h2>06. Microsoft-built agents</h2><h2>12. Custom pro-code agents</h2><h3>12d · Phase 3</h3>',
  '<h2>Power Platform for Agent 365</h2><h4>PP3 · Set data policies</h4>'
].join('\n'));
const status = label => resolveReference(label, richGuide).status;
assert(status('04 Microsoft Purview, 4.04a') === 'ok', 'A matching code must resolve.');
assert(status('12 Custom pro-code agents, 12d and 12e') === 'broken', 'A reference with one missing code must fail.');
assert(status('04 Microsoft Purview, 4.99') === 'broken', 'An unknown code must fail.');
assert(status('02 Microsoft Defender, 4.04a') === 'broken', 'A code in a different section must fail.');
assert(status('99 Missing section, 4.04a') === 'broken', 'An unknown section must fail.');
assert(status('06 Microsoft-built agents') === 'section', 'A section-only reference must resolve to the section.');
assert(status('Power Platform, PP3') === 'ok', 'Power Platform references must resolve.');
assert(status('02 Microsoft Defender, AI agent inventory and advanced hunting') === 'ok', 'A description must match a step title loosely.');
assert(status('02 Microsoft Defender, something unrelated entirely') === 'unverified', 'An unmatched description must be reported as unverified, not failed.');

const sync = checkSync(richGuide, { tasks: [
  { workstream: 'W', number: 1, title: 'A', deep: '04 Microsoft Purview, 4.04a' },
  { workstream: 'W', number: 2, title: 'B', deep: '04 Microsoft Purview, 4.99' }
] });
assert(sync.referenceCount === 2 && sync.broken.length === 1 && sync.uncovered.some(entry => entry.code === 'PP3'),
  'The sync check must report broken references and guide steps nothing points at.');

assert(classifyResponse('https://learn.microsoft.com/en-us/a/b', { status: 404 }).kind === 'broken', '404 must be broken.');
assert(classifyResponse('https://learn.microsoft.com/en-us/a/b', { status: 503 }).kind === 'unreachable', '5xx must be unreachable, not broken.');
assert(classifyResponse('https://learn.microsoft.com/a/b', { status: 200, finalUrl: 'https://learn.microsoft.com/en-us/a/b/' }).kind === 'ok',
  'A locale or trailing-slash redirect must not count as moved.');
const moved = classifyResponse('https://learn.microsoft.com/en-us/a/b', { status: 200, finalUrl: 'https://learn.microsoft.com/en-us/c/b?x=1', updatedAt: '2026-10-23' });
assert(moved.kind === 'moved' && moved.detail === 'https://learn.microsoft.com/en-us/c/b', 'A path change must be reported as moved with the new address.');
assert(classifyResponse('https://learn.microsoft.com/en-us/a/b', { error: 'timeout' }).kind === 'unreachable', 'Network errors must be unreachable.');
assert(daysBetween('2026-10-22', '2026-10-28') === 6, 'Day counts must be whole days.');

const stubPage = body => async () => ({
  status: 200,
  url: 'https://learn.microsoft.com/en-us/a/b',
  body: new ReadableStream({ start(controller) { controller.enqueue(new TextEncoder().encode(body)); controller.close(); } })
});
const fetched = await fetchPage('https://learn.microsoft.com/en-us/a/b', stubPage('<head><meta name="ms.date" content="2026-05-01T00:00:00Z"><meta name="updated_at" content="2026-10-23T01:03:00Z"></head><body>'));
assert(fetched.updatedAt === '2026-10-23', 'The page reader must prefer updated_at over ms.date.');
assert((await fetchPage('https://learn.microsoft.com/en-us/a/b', stubPage('<head><meta name="ms.date" content="2026-05-01T00:00:00Z"></head>'))).updatedAt === '2026-05-01',
  'The page reader must fall back to ms.date.');

const citations = collectCitations(
  { urls: new Map([['https://learn.microsoft.com/en-us/p/1', new Set(['Guide 1a'])], ['https://learn.microsoft.com/en-us/p/2', new Set(['Guide 1b'])]]) },
  { urls: new Map([['https://learn.microsoft.com/en-us/p/1', new Set(['Checklist W task 1: A'])]]) }
);
const pages = new Map([
  ['https://learn.microsoft.com/en-us/p/1', { kind: 'ok', updatedAt: '2026-10-25' }],
  ['https://learn.microsoft.com/en-us/p/2', { kind: 'ok', updatedAt: '2026-10-01' }]
]);
const reportInput = {
  guide: { version: '1.3.0', reviewed: '2026-10-15' },
  checklist: { version: '2.9.1', reviewed: '2026-10-22' },
  sync: { referenceCount: 2, broken: [], unverified: [], uncovered: [] },
  pages,
  citations,
  now: '2026-10-28T12:00:00.000Z',
  maxAgeDays: 30,
  offline: false
};
const report = buildReport(reportInput);
assert(report.links.updated.checklist.length === 1 && report.links.updated.guide.length === 1,
  'A Learn page must be flagged only for an artifact that was reviewed before the page changed.');
assert(report.actionable && report.reasons.some(reason => /updated since the Enablement Checklist/.test(reason)), 'Changed pages must make the report actionable.');
const clean = buildReport({ ...reportInput, pages: new Map([['https://learn.microsoft.com/en-us/p/1', { kind: 'ok', updatedAt: '2026-09-01' }]]), guide: { version: '1.3.0', reviewed: '2026-10-20' } });
assert(!clean.actionable && /Nothing needs attention/.test(renderMarkdown(clean)), 'A clean report must say nothing needs attention.');
const stale = buildReport({ ...reportInput, now: '2026-12-31T00:00:00.000Z', pages: new Map() });
assert(stale.reasons.some(reason => /last reviewed 7\d days ago/.test(reason)), 'An old review must be flagged.');
const newerGuide = buildReport({ ...reportInput, guide: { version: '1.4.0', reviewed: '2026-10-27' }, pages: new Map() });
assert(newerGuide.timing && newerGuide.reasons.some(reason => /guide is newer/.test(reason)), 'A guide newer than the checklist review must be flagged.');
const many = { ...report, links: { ...report.links, moved: Array.from({ length: 60 }, (_, index) => ({ url: `https://learn.microsoft.com/en-us/m/${index}`, detail: 'https://learn.microsoft.com/en-us/n', citedBy: { guide: ['Guide x'], checklist: [] } })) } };
assert(/Showing 40 of 60/.test(renderMarkdown(many, 40)) && !/Showing/.test(renderMarkdown(many)), 'The issue copy must cap long tables and the full copy must not.');

const realGuide = loadGuide();
const realChecklist = loadChecklist();
assertParsed(realGuide, realChecklist);
const realSync = checkSync(realGuide, realChecklist);
assert(realSync.broken.length === 0,
  `The checklist points at guide sections or steps that do not exist:\n${realSync.broken.map(item => `- "${item.label}": ${item.problems.join(' ')}`).join('\n')}\nUpdate the checklist reference or the guide so they match.`);

const freshnessWorkflowSource = readFileSync(join(repositoryRoot, '.github', 'workflows', 'agent365-freshness.yml'), 'utf8');
const freshnessWorkflow = yaml.load(freshnessWorkflowSource);
assert(Boolean(freshnessWorkflow.on.schedule?.[0]?.cron) && Boolean(freshnessWorkflow.on.workflow_dispatch),
  'The freshness workflow must run weekly and on demand.');
assert(JSON.stringify(freshnessWorkflow.permissions) === JSON.stringify({ contents: 'read', issues: 'write' }),
  'The freshness workflow must only read the repository and write issues.');
assert(!freshnessWorkflowSource.includes('gh pr ') && !freshnessWorkflowSource.includes('git push'),
  'The freshness workflow must not push or open pull requests; the repository blocks both.');

console.log(`Agent 365 guide and checklist stay aligned: ${realSync.referenceCount} references resolve; ${realSync.uncovered.length} guide steps have no checklist task (informational).`);
