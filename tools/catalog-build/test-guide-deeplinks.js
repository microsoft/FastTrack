// Opens the Customer Implementation Guide in a real headless browser at a sample of #advanced/<key>
// addresses and checks that the guide finds each step. This exercises the deep-link script itself, which
// the offline checks cannot. It skips when no Chromium-based browser is installed unless
// --require-browser is given.
//
//   node test-guide-deeplinks.js [--require-browser] [--all]
//   BROWSER_PATH=... node test-guide-deeplinks.js
import { execFile } from 'node:child_process';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { promisify } from 'node:util';
import { guideKey, loadChecklist, loadGuide, linkKeyFor } from './agent365-content.js';
import { guidePath } from './guide-deeplinks.js';

const candidates = [
  process.env.BROWSER_PATH,
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/microsoft-edge',
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser'
].filter(Boolean);
const browser = candidates.find(path => existsSync(path));
if (!browser) {
  if (process.argv.includes('--require-browser')) {
    console.error('No Edge or Chrome found. Set BROWSER_PATH to a Chromium-based browser.');
    process.exit(1);
  }
  console.log('Skipped the browser deep-link test: no Edge or Chrome found.');
  process.exit(0);
}

const guide = loadGuide();
const checklist = loadChecklist();
// Every address the checklist links to, plus one section and one step from each guide section so a
// section the checklist does not cite is still covered.
const keys = new Set(checklist.tasks.filter(task => task.deep).map(task => linkKeyFor(task.deep)));
if (!process.argv.includes('--all')) {
  const bySection = new Map();
  for (const entry of guide.codes.values()) if (!bySection.has(entry.section)) bySection.set(entry.section, guideKey(entry.code));
  for (const [section, key] of bySection) {
    keys.add(key);
    keys.add(section.toLowerCase());
  }
} else {
  for (const key of guide.keys) keys.add(key);
}
const targets = [...keys].sort();
const MISSING = 'zz9';

const profile = mkdtempSync(join(tmpdir(), 'fasttrack-deeplink-'));
const base = pathToFileURL(guidePath).href;
const run = promisify(execFile);
let launches = 0;

// A browser launch occasionally reports nothing under load, so a target only fails after three tries.
async function open(key, expected) {
  let result = '';
  for (let attempt = 1; attempt <= 3 && result !== expected; attempt += 1) {
    launches += 1;
    const args = [
      '--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--virtual-time-budget=6000',
      `--user-data-dir=${join(profile, String(launches))}`, ...(process.env.CI ? ['--no-sandbox'] : []),
      '--dump-dom', `${base}#advanced/${key}`
    ];
    try {
      const { stdout } = await run(browser, args, { encoding: 'utf8', timeout: 60000, maxBuffer: 256 * 1024 * 1024 });
      result = /<html[^>]*\sdata-deeplink="([^"]*)"/.exec(stdout)?.[1] ?? '';
    } catch {
      result = '';
    }
  }
  return result;
}

const failures = [];
try {
  const queue = [...targets.map(key => [key, `found:${key}`]), [MISSING, `missing:${MISSING}`]];
  await Promise.all(Array.from({ length: 4 }, async () => {
    for (let next = queue.shift(); next; next = queue.shift()) {
      const [key, expected] = next;
      const result = await open(key, expected);
      if (result !== expected) failures.push(`#advanced/${key}: expected "${expected}" but the guide reported "${result || 'nothing'}"`);
    }
  }));
} finally {
  rmSync(profile, { recursive: true, force: true });
}
if (failures.length) {
  console.error(`The guide's deep links do not work in ${browser}:\n- ${failures.join('\n- ')}`);
  process.exit(1);
}
console.log(`The guide opened ${targets.length} deep-link targets and reported a missing step correctly (${browser}).`);
