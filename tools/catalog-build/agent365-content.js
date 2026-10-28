// Readers for the two Agent 365 artifacts that must stay aligned: the Customer Implementation Guide
// and the Enablement Checklist. Both are generated single-file HTML, so these functions read them as
// text and never modify them.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import matter from 'gray-matter';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
export const repositoryRoot = join(toolDirectory, '..', '..');
export const guideFolder = join(repositoryRoot, 'copilot-agent-strategy', 'agent-365-customer-implementation-guide');
export const checklistFolder = join(repositoryRoot, 'copilot-agent-strategy', 'agent-365-enablement-checklist');

const learnUrlPattern = /https:\/\/learn\.microsoft\.com\/[^"'\s<>)\\\]]+/g;
// 5·0 is a real code in the guide, so it must be matched before the generic patterns.
const codePattern = '5·0|\\d{1,2}\\.\\d{2}[a-z]?|\\d{1,2}[a-z]|PP\\d+';

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

function addUrl(map, url, label) {
  const key = normalizeLearnUrl(url);
  if (!map.has(key)) map.set(key, new Set());
  map.get(key).add(label);
}

function stripTags(markup) {
  return markup.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}

export function parseGuide(source) {
  const document = decodeEntities(source);
  const events = [];
  for (const match of document.matchAll(/<h2[^>]*>([\s\S]*?)<\/h2>/g)) {
    events.push({ at: match.index, kind: 'section', text: stripTags(match[1]) });
  }
  const headingPattern = new RegExp(`<h[34][^>]*>\\s*(${codePattern})\\s*·\\s*([\\s\\S]*?)</h[34]>`, 'g');
  for (const match of document.matchAll(headingPattern)) {
    events.push({ at: match.index, kind: 'code', code: match[1], title: stripTags(match[2]) });
  }
  for (const match of document.matchAll(/<article class="task-card"([^>]*)>/g)) {
    const id = /data-task="([^"]+)"/.exec(match[1]);
    if (id) events.push({ at: match.index, kind: 'task', id: id[1] });
  }
  for (const match of document.matchAll(learnUrlPattern)) {
    events.push({ at: match.index, kind: 'url', url: match[0] });
  }
  events.sort((left, right) => left.at - right.at);

  const sections = new Map();
  const codes = new Map();
  const tasks = [];
  const urls = new Map();
  let section = '';
  let sectionNumber = '';
  let place = '';
  for (const event of events) {
    if (event.kind === 'section') {
      section = event.text;
      const number = /^(\d{2})\./.exec(section);
      sectionNumber = number ? number[1] : /^Power Platform/i.test(section) ? 'PP' : '';
      if (sectionNumber) sections.set(sectionNumber, section);
      place = section;
    } else if (event.kind === 'code') {
      if (!codes.has(event.code)) codes.set(event.code, { code: event.code, title: event.title, section: sectionNumber });
      place = `${event.code} ${event.title}`;
    } else if (event.kind === 'task') {
      tasks.push({ id: event.id, section: sectionNumber });
    } else if (place) {
      addUrl(urls, event.url, `Guide ${place}`);
    }
  }
  return { sections, codes, tasks, urls };
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

// A deep reference reads like "04 Microsoft Purview, 4.04a", "12 Custom pro-code agents, 12d and 12e",
// "Power Platform, PP3", or "06 Microsoft-built agents". Codes and section numbers can be checked
// against the guide; a description with no code can only be matched loosely, so it is reported as
// unverified instead of failing.
export function resolveReference(label, guide) {
  const [scope, ...rest] = label.split(',');
  const detail = rest.join(',').trim();
  const sectionMatch = /^(\d{2})\s/.exec(scope.trim());
  const section = sectionMatch ? sectionMatch[1] : /^Power Platform/i.test(scope.trim()) ? 'PP' : '';
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
  if (problems.length) return { status: 'broken', codes, problems };
  if (codes.length) return { status: 'ok', codes, problems };
  if (!detail) return { status: 'section', codes, problems };
  const words = [...new Set(detail.toLowerCase().match(/[a-z]{4,}/g) ?? [])];
  const inSection = [...guide.codes.values()].filter(entry => entry.section === section);
  const needed = Math.max(1, Math.ceil(words.length / 2));
  const match = inSection.find(entry => words.filter(word => entry.title.toLowerCase().includes(word)).length >= needed);
  return match
    ? { status: 'ok', codes: [match.code], problems }
    : { status: 'unverified', codes, problems };
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
  const referencedCodes = new Set();
  const referencedSections = new Set();
  for (const reference of references.values()) {
    const result = resolveReference(reference.label, guide);
    result.codes.forEach(code => referencedCodes.add(code));
    const sectionMatch = /^(\d{2})\s/.exec(reference.label) ?? (/^Power Platform/i.test(reference.label) ? [null, 'PP'] : null);
    if (sectionMatch) referencedSections.add(sectionMatch[1]);
    if (result.status === 'broken') broken.push({ ...reference, problems: result.problems });
    if (result.status === 'unverified') unverified.push(reference);
  }
  const uncovered = [...guide.codes.values()].filter(entry => !referencedCodes.has(entry.code));
  return { referenceCount: references.size, broken, unverified, uncovered, referencedSections };
}

export function loadGuide() {
  const source = readFileSync(join(guideFolder, 'index.html'), 'utf8');
  const readme = matter(readFileSync(join(guideFolder, 'README.md'), 'utf8')).data;
  return { ...parseGuide(source), version: String(readme.version ?? ''), reviewed: dateOnly(readme.updated) };
}

export function loadChecklist() {
  return parseChecklist(readFileSync(join(checklistFolder, 'index.html'), 'utf8'));
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
  if (!guide.reviewed) problems.push('Found no updated date in the guide README.');
  if (problems.length) throw new Error(`Agent 365 guide or checklist format changed:\n- ${problems.join('\n- ')}`);
}

function dateOnly(value) {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value ?? '').slice(0, 10);
}
