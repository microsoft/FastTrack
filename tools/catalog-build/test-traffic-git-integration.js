import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const resolver = join(toolDirectory, 'reconcile-stats-conflict.js');
const testRoot = mkdtempSync(join(toolDirectory, '.traffic-reconcile-'));
const repository = join(testRoot, 'repository');
const statePath = join(repository, 'traffic-data', 'clarity-views.json');

function git(...args) {
  return execFileSync('git', ['-C', repository, ...args], { encoding: 'utf8' }).trim();
}

function runGit(...args) {
  return spawnSync('git', ['-C', repository, ...args], { encoding: 'utf8' });
}

function state(lastRun, days) {
  writeFileSync(statePath, `${JSON.stringify({ lastRun, days }, null, 2)}\n`);
}

function readState() {
  return JSON.parse(readFileSync(statePath, 'utf8'));
}

function commit(message) {
  git('add', '.');
  git('commit', '-m', message);
}

function mergeDurable(source) {
  const result = runGit('merge', '--no-edit', source);
  if (result.status === 0) return false;
  const conflicts = git('diff', '--name-only', '--diff-filter=U').split(/\r?\n/).filter(Boolean);
  if (conflicts.length !== 1 || conflicts[0] !== 'traffic-data/clarity-views.json') {
    throw new Error(`Unexpected conflicts while merging ${source}: ${conflicts.join(', ')}`);
  }
  execFileSync(process.execPath, [resolver, 'traffic-data/clarity-views.json'], {
    cwd: repository,
    stdio: 'pipe'
  });
  git('add', 'traffic-data/clarity-views.json');
  git('commit', '--no-edit');
  return true;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

try {
  execFileSync('git', ['init', '-b', 'master', repository]);
  git('config', 'user.name', 'Traffic Test');
  git('config', 'user.email', 'traffic-test@example.invalid');
  execFileSync('node', ['-e',
    "require('fs').mkdirSync(process.argv[1], { recursive: true })",
    dirname(statePath)
  ]);

  state('2026-09-10', { '2026-09-10': { base: { views: 1 } } });
  writeFileSync(join(repository, 'source.js'), 'export const version = 1;\n');
  commit('initial source');

  git('checkout', '-b', 'staging');
  state('2026-09-11', {
    '2026-09-10': { base: { views: 1 } },
    '2026-09-11': { staged: { views: 2 } }
  });
  commit('daily staging');

  git('checkout', '-b', 'weekly', 'master');
  git('merge', '--no-ff', '--no-edit', 'staging');

  git('checkout', 'master');
  git('merge', '--squash', 'weekly');
  commit('squash weekly publication');
  state('2026-09-12', {
    ...readState().days,
    '2026-09-12': { upstream: { views: 3 } }
  });
  writeFileSync(join(repository, 'source.js'), 'export const version = 2;\n');
  commit('upstream source progress');

  git('checkout', 'staging');
  state('2026-09-12', {
    ...readState().days,
    '2026-09-11': { staged: { views: 5 } },
    '2026-09-12': { daily: { views: 4 } }
  });
  commit('next daily collection');
  assert(mergeDurable('master'),
    'Daily staging must reproduce the post-squash Clarity merge conflict.');
  let reconciled = readState();
  assert(reconciled.days['2026-09-11'].staged.views === 5 &&
    reconciled.days['2026-09-12'].daily.views === 4 &&
    reconciled.days['2026-09-12'].upstream.views === 3,
  'Daily synchronization must retain newer rolling-window values and union independent resources.');
  assert(readFileSync(join(repository, 'source.js'), 'utf8').includes('version = 2'),
    'Daily synchronization must retain non-conflicting upstream source changes.');

  git('checkout', 'weekly');
  mergeDurable('master');
  mergeDurable('staging');
  reconciled = readState();
  assert(reconciled.days['2026-09-12'].daily.views === 4,
    'Weekly synchronization must bring newer staging state, not retain the older publication.');

  git('checkout', 'master');
  git('merge', '--squash', 'weekly');
  commit('second squash weekly publication');

  git('checkout', 'staging');
  state('2026-09-13', {
    ...readState().days,
    '2026-09-13': { daily: { views: 5 } }
  });
  commit('second cycle daily collection');
  mergeDurable('master');

  git('checkout', 'weekly');
  mergeDurable('master');
  mergeDurable('staging');
  assert(readState().days['2026-09-13'].daily.views === 5,
    'A second squash cycle must preserve the newly accumulated day.');

  git('checkout', '-b', 'unsafe-master', 'master');
  writeFileSync(join(repository, 'source.js'), 'export const version = "master";\n');
  commit('master code edit');
  git('checkout', '-b', 'unsafe-staging', 'master');
  writeFileSync(join(repository, 'source.js'), 'export const version = "staging";\n');
  commit('staging code edit');
  const unsafeMerge = runGit('merge', '--no-edit', 'unsafe-master');
  assert(unsafeMerge.status !== 0 &&
    git('diff', '--name-only', '--diff-filter=U') === 'source.js',
  'The regression setup must produce a real source-code conflict.');
  const refused = spawnSync(process.execPath, [resolver, 'source.js'], {
    cwd: repository,
    encoding: 'utf8'
  });
  assert(refused.status !== 0 && refused.stderr.includes('Unsupported durable stats conflict'),
    'The resolver must refuse source-code conflicts instead of choosing a side.');
  git('merge', '--abort');

  console.log('Squash-cycle traffic branch reconciliation is valid.');
} finally {
  rmSync(testRoot, { recursive: true, force: true });
}
