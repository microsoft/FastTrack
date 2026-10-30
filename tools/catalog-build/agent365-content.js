// Readers for the two Agent 365 artifacts that must stay aligned: the Customer Implementation Guide
// and the Enablement Checklist. Both are generated single-file HTML, so these functions read them as
// text and never modify them.
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import matter from 'gray-matter';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
export const repositoryRoot = join(toolDirectory, '..', '..');
export const guideFolder = join(repositoryRoot, 'copilot-agent-strategy', 'agent-365-customer-implementation-guide');
export const checklistFolder = join(repositoryRoot, 'copilot-agent-strategy', 'agent-365-enablement-checklist');
export const syncStatePath = join(toolDirectory, 'agent365-sync-state.json');

const learnUrlPattern = /https:\/\/learn\.microsoft\.com\/[^"'\s<>)\\\]]+/g;
// The step codes the guide uses in headings such as "4.04a · Enable Purview Data Security". 5·0 is a
// real code, so it must be matched before the generic patterns. The guide's deep-link script and the
// checklist's link builder carry the same pattern; test-agent365-sync.js checks that they agree.
export const codePattern = '5·0|\\d{1,2}\\.\\d{2}[a-z]?|\\d{1,2}[a-z]|PP\\d+';

export function decodeEntities(text) {
  let current = text;
  for (let pass = 0; pass < 3; pass += 1) {
    const next = current
      .replace(/&quot;/g, '"')
      .replace(/&#0?39;|&#x27;|&apos;/g, "'")
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&nbsp;/g, ' ')
      .replace(/&middot;/g, '·')
      .replace(/&amp;/g, '&');
    if (next === current) break;
    current = next;
  }
  return current;
}

export function normalizeLearnUrl(url) {
  const clean = url.replace(/[#?].*$/, '').replace(/[.,;]+$/, '').replace(/\/$/, '');
  // Links with and without the locale reach the same page, so count them once.
  return clean.replace(/^(https:\/\/learn\.microsoft\.com)\/(?![a-z]{2}-[a-z]{2}\/)/i, '$1/en-us/');
}

// The address fragment a step or section is reachable at: #advanced/<key>. Codes are lowercased and 5·0
// becomes 5-0; sections are their two-digit number, or "pp" for Power Platform.
export function guideKey(code) {
  return code.toLowerCase().replace('·', '-');
}

function addUrl(map, url, label) {
  const key = normalizeLearnUrl(url);
  if (!map.has(key)) map.set(key, new Set());
  map.get(key).add(label);
}

function stripTags(markup) {
  return markup
    .replace(/<(script|style)[\s\S]*?<\/\1>/g, ' ')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function hashText(text) {
  return createHash('sha256').update(text).digest('hex').slice(0, 16);
}

function sectionNumberOf(text) {
  const number = /^(\d{2})\./.exec(text);
  return number ? number[1] : /^Power Platform/i.test(text) ? 'PP' : '';
}

// The Detailed view lives in an iframe's srcdoc attribute. Deep links and step codes belong to that
// document only, so it is read separately from the rest of the file.
function splitFrames(source) {
  const start = source.indexOf('id="cxAdvanced"');
  const open = start < 0 ? -1 : source.indexOf('srcdoc="', start);
  if (open < 0) return { detailed: decodeEntities(source), rest: '' };
  const from = open + 'srcdoc="'.length;
  const to = source.indexOf('"', from);
  return { detailed: decodeEntities(source.slice(from, to)), rest: decodeEntities(source.slice(0, from) + source.slice(to)) };
}

export function parseGuide(source) {
  const { detailed, rest } = splitFrames(source);
  const events = [];
  for (const match of detailed.matchAll(/<h2[^>]*>([\s\S]*?)<\/h2>/g)) {
    events.push({ at: match.index, kind: 'section', text: stripTags(match[1]) });
  }
  const headingPattern = new RegExp(`<h[34][^>]*>\\s*(${codePattern})\\s*·\\s*([\\s\\S]*?)</h[34]>`, 'g');
  for (const match of detailed.matchAll(headingPattern)) {
    events.push({ at: match.index, kind: 'code', code: match[1], title: stripTags(match[2]) });
  }
  for (const match of detailed.matchAll(/<article class="task-card"([^>]*)>/g)) {
    const id = /data-task="([^"]+)"/.exec(match[1]);
    if (id) events.push({ at: match.index, kind: 'task', id: id[1] });
  }
  for (const match of detailed.matchAll(/<footer[\s>]/g)) {
    events.push({ at: match.index, kind: 'end' });
  }
  for (const match of detailed.matchAll(learnUrlPattern)) {
    events.push({ at: match.index, kind: 'url', url: match[0] });
  }
  events.sort((left, right) => left.at - right.at);

  const sections = new Map();
  const sectionHashes = new Map();
  const codes = new Map();
  const spans = new Map();
  const tasks = [];
  const urls = new Map();
  let sectionNumber = '';
  let place = '';
  let open = null;
  const closeSpan = at => {
    if (!open) return;
    const text = stripTags(detailed.slice(open.from, at));
    const hrefs = [...detailed.slice(open.from, at).matchAll(/href="([^"]+)"/g)].map(match => match[1]);
    spans.set(open.code, `${spans.get(open.code) ?? ''}\n${text}\n${hrefs.join('\n')}`);
    open = null;
  };
  for (const event of events) {
    if (event.kind !== 'url') closeSpan(event.at);
    if (event.kind === 'end') continue;
    if (event.kind === 'section') {
      sectionNumber = sectionNumberOf(event.text);
      if (sectionNumber) {
        sections.set(sectionNumber, event.text);
        sectionHashes.set(sectionNumber, hashText(event.text));
      }
      place = event.text;
    } else if (event.kind === 'code') {
      if (!codes.has(event.code)) codes.set(event.code, { code: event.code, title: event.title, section: sectionNumber });
      place = `${event.code} ${event.title}`;
      open = { code: event.code, from: event.at };
    } else if (event.kind === 'task') {
      tasks.push({ id: event.id, section: sectionNumber });
    } else if (place) {
      addUrl(urls, event.url, `Guide ${place}`);
    }
  }
  closeSpan(detailed.length);
  for (const entry of codes.values()) entry.fingerprint = hashText(spans.get(entry.code) ?? '');

  // Links in the Simple view and the page chrome, attributed to the nearest heading.
  let simplePlace = '';
  const simpleEvents = [];
  for (const match of rest.matchAll(/<h[23][^>]*>([\s\S]*?)<\/h[23]>/g)) simpleEvents.push({ at: match.index, heading: stripTags(match[1]) });
  for (const match of rest.matchAll(learnUrlPattern)) simpleEvents.push({ at: match.index, url: match[0] });
  simpleEvents.sort((left, right) => left.at - right.at);
  for (const event of simpleEvents) {
    if (event.heading !== undefined) simplePlace = event.heading;
    else addUrl(urls, event.url, `Guide (Simple view) ${simplePlace || 'page'}`.trim());
  }

  const keys = new Set([...sections.keys()].map(key => key.toLowerCase()));
  for (const code of codes.keys()) keys.add(guideKey(code));
  return { sections, sectionHashes, codes, keys, tasks, urls };
}

export function parseChecklist(source) {
  const version = /var CONTENT_VERSION = "([^"]+)"/.exec(source)?.[1] ?? '';
  const reviewed = /var CONTENT_REVIEWED = "([^"]+)"/.exec(source)?.[1] ?? '';
  const workstreams = [];
  for (const match of source.matchAll(/"id":\s*"([^"]+)",\s*"code":\s*"([^"]+)",\s*"name":\s*"((?:[^"\\]|\\.)*)"/g)) {
    workstreams.push({ at: match.index, name: JSON.parse(`"${match[3]}"`) });
  }
  const starts = [];
  const taskPattern = /"n":\s*(\d+),\s*"role":\s*"[^"]*",\s*"title":\s*"((?:[^"\\]|\\.)*)"/g;
  for (const match of source.matchAll(taskPattern)) {
    starts.push({ at: match.index, number: Number(match[1]), title: JSON.parse(`"${match[2]}"`) });
  }
  const tasks = [];
  const urls = new Map();
  starts.forEach((start, index) => {
    const end = index + 1 < starts.length ? starts[index + 1].at : source.length;
    const slice = source.slice(start.at, end);
    const workstream = [...workstreams].reverse().find(candidate => candidate.at < start.at)?.name ?? '';
    const deep = /"deep":\s*"((?:[^"\\]|\\.)*)"/.exec(slice);
    const label = `Checklist ${workstream} task ${start.number}: ${start.title}`;
    const taskUrls = [...slice.matchAll(learnUrlPattern)].map(match => match[0]);
    taskUrls.forEach(url => addUrl(urls, url, label));
    tasks.push({
      workstream,
      number: start.number,
      title: start.title,
      deep: deep ? JSON.parse(`"${deep[1]}"`) : '',
      urlCount: taskUrls.length
    });
  });
  return { version, reviewed, tasks, urls };
}

// The fragment key a deep reference links to: its first step code, else its section. The checklist's
// guideHref() computes the same key in the browser, and the sync test compares the two.
export function linkKeyFor(label) {
  const [scope, ...rest] = label.split(',');
  const detail = rest.join(',');
  const code = new RegExp(`(?<![\\w.])(${codePattern})(?![\\w.])`).exec(detail);
  if (code) return guideKey(code[1]);
  const section = /^(\d{2})\s/.exec(scope.trim());
  if (section) return section[1];
  return /^Power Platform/i.test(scope.trim()) ? 'pp' : '';
}

// A deep reference reads like "04 Microsoft Purview, 4.04a", "12 Custom pro-code agents, 12d and 12e",
// "Power Platform, PP3", or "06 Microsoft-built agents". Every code and section number is checked
// against the guide. A description with no code cannot be tied to a step, and matching descriptions
// loosely picked the wrong step once, so it is reported as unverified and the sync check rejects it.
export function resolveReference(label, guide) {
  const [scope, ...rest] = label.split(',');
  const detail = rest.join(',').trim();
  const section = sectionNumberOf(scope.trim().replace(/^(\d{2})\s/, '$1. '));
  const problems = [];
  if (!section) problems.push(`Section "${scope.trim()}" has no section number the guide uses.`);
  else if (!guide.sections.has(section)) problems.push(`The guide has no section ${section}.`);

  const codes = [...detail.matchAll(new RegExp(`(?<![\\w.])(${codePattern})(?![\\w.])`, 'g'))].map(match => match[1]);
  for (const code of codes) {
    const entry = guide.codes.get(code);
    if (!entry) problems.push(`The guide has no step ${code}.`);
    else if (section && entry.section && entry.section !== section) {
      problems.push(`Step ${code} is in guide section ${entry.section}, not ${section}.`);
    }
  }
  if (problems.length) return { status: 'broken', codes, section, problems };
  if (codes.length) return { status: 'ok', codes, section, problems };
  if (!detail) return { status: 'section', codes, section, problems };
  return { status: 'unverified', codes, section, problems };
}

export function checkSync(guide, checklist) {
  const references = new Map();
  for (const task of checklist.tasks) {
    if (!task.deep) continue;
    if (!references.has(task.deep)) references.set(task.deep, { label: task.deep, tasks: [] });
    references.get(task.deep).tasks.push(`${task.workstream} task ${task.number}: ${task.title}`);
  }
  const broken = [];
  const unverified = [];
  const missingTargets = [];
  const referencedCodes = new Map();
  const referencedSections = new Map();
  for (const reference of references.values()) {
    const result = resolveReference(reference.label, guide);
    for (const code of result.codes) {
      if (!referencedCodes.has(code)) referencedCodes.set(code, []);
      referencedCodes.get(code).push(...reference.tasks);
    }
    if (result.section) {
      if (!referencedSections.has(result.section)) referencedSections.set(result.section, []);
      referencedSections.get(result.section).push(...reference.tasks);
    }
    if (result.status === 'broken') broken.push({ ...reference, problems: result.problems });
    if (result.status === 'unverified') unverified.push(reference);
    const key = linkKeyFor(reference.label);
    if (result.status !== 'broken' && result.status !== 'unverified' && !guide.keys.has(key)) missingTargets.push({ ...reference, key });
  }
  const uncovered = [...guide.codes.values()].filter(entry => !referencedCodes.has(entry.code));
  return {
    referenceCount: references.size,
    broken,
    unverified,
    missingTargets,
    uncovered,
    referencedCodes,
    referencedSections
  };
}

// The recorded fingerprint of every guide step and section the checklist cites. The sync check fails
// when a cited step's text changes, so the checklist tasks that depend on it get reviewed in the same
// pull request. `npm run sync:agent365` records the new state after that review.
export function currentFingerprints(guide, sync) {
  const steps = {};
  for (const code of [...sync.referencedCodes.keys()].sort()) {
    const entry = guide.codes.get(code);
    if (entry) steps[code] = entry.fingerprint;
  }
  const sections = {};
  for (const section of [...sync.referencedSections.keys()].sort()) {
    if (guide.sectionHashes.has(section)) sections[section] = guide.sectionHashes.get(section);
  }
  return { steps, sections };
}

export function compareFingerprints(recorded, current, sync) {
  const changes = [];
  const compare = (kind, label, recordedMap, currentMap, citedBy) => {
    for (const [key, hash] of Object.entries(currentMap)) {
      if (!(key in recordedMap)) changes.push({ kind, key, label, reason: 'is not recorded yet', tasks: citedBy.get(key) ?? [] });
      else if (recordedMap[key] !== hash) changes.push({ kind, key, label, reason: 'changed', tasks: citedBy.get(key) ?? [] });
    }
    for (const key of Object.keys(recordedMap)) {
      if (!(key in currentMap)) changes.push({ kind, key, label, reason: 'is recorded but no longer cited or no longer in the guide', tasks: [] });
    }
  };
  compare('step', 'Guide step', recorded.steps ?? {}, current.steps, sync.referencedCodes);
  compare('section', 'Guide section', recorded.sections ?? {}, current.sections, sync.referencedSections);
  return changes;
}

export function loadSyncState() {
  if (!existsSync(syncStatePath)) return { reviewed: {}, steps: {}, sections: {} };
  return JSON.parse(readFileSync(syncStatePath, 'utf8'));
}

export function saveSyncState(state) {
  writeFileSync(syncStatePath, `${JSON.stringify(state, null, 2)}\n`);
}

export function loadGuide() {
  const source = readFileSync(join(guideFolder, 'index.html'), 'utf8');
  const readme = matter(readFileSync(join(guideFolder, 'README.md'), 'utf8')).data;
  // The guide has no review date of its own, and its README `updated` date also moves for changes that
  // are not a content review. The review date lives in the sync state and moves only when someone says
  // they reviewed it.
  const reviewed = loadSyncState().reviewed?.guide ?? '';
  return { ...parseGuide(source), version: String(readme.version ?? ''), reviewed, source };
}

export function loadChecklist() {
  const source = readFileSync(join(checklistFolder, 'index.html'), 'utf8');
  return { ...parseChecklist(source), source };
}

// These floors exist so that a change to either file's format cannot silently turn the checks
// into no-ops. If one trips, the artifact was restructured and the readers above need updating.
export function assertParsed(guide, checklist) {
  const problems = [];
  if (guide.codes.size < 60) problems.push(`Read only ${guide.codes.size} step headings from the guide (expected 60 or more).`);
  if (guide.tasks.length < 40) problems.push(`Read only ${guide.tasks.length} task cards from the guide (expected 40 or more).`);
  if (guide.sections.size < 10) problems.push(`Read only ${guide.sections.size} sections from the guide (expected 10 or more).`);
  if (checklist.tasks.length < 100) problems.push(`Read only ${checklist.tasks.length} tasks from the checklist (expected 100 or more).`);
  if (!checklist.tasks.some(task => task.deep)) problems.push('Found no guide references in the checklist.');
  if (!checklist.reviewed) problems.push('Found no CONTENT_REVIEWED date in the checklist.');
  if (!guide.reviewed) problems.push('Found no guide review date in tools/catalog-build/agent365-sync-state.json.');
  if (problems.length) throw new Error(`Agent 365 guide or checklist format changed:\n- ${problems.join('\n- ')}`);
}
