import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as yaml from 'js-yaml';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const workflowPath = join(repositoryRoot, '.github', 'workflows', 'traffic-stats.yml');
const catalogWorkflowPath = join(repositoryRoot, '.github', 'workflows', 'build-catalog.yml');
const workflowSource = readFileSync(workflowPath, 'utf8');
const workflow = yaml.load(workflowSource);
const catalogWorkflow = yaml.load(readFileSync(catalogWorkflowPath, 'utf8'));

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const schedules = workflow.on.schedule;
const dailySchedule = schedules.find(schedule => schedule.cron === '0 6 * * *');
const weeklySchedule = schedules.find(schedule => schedule.cron === '0 8 * * 5');
assert(dailySchedule, 'Daily collection must continue at 06:00 UTC.');
assert(weeklySchedule?.timezone === 'America/Chicago',
  'Weekly publishing must run Friday at 08:00 America/Chicago so DST is handled honestly.');

const collectJob = workflow.jobs['collect-traffic'];
const weeklyJob = workflow.jobs['publish-weekly'];
assert(collectJob.if.includes("github.event.schedule == '0 6 * * *'"),
  'The daily schedule must run collection only.');
assert(weeklyJob.if.includes("github.event.schedule == '0 8 * * 5'"),
  'The Friday schedule must run weekly publishing only.');
assert(collectJob.env.STAGING_BRANCH === weeklyJob.env.STAGING_BRANCH,
  'Daily collection and weekly publishing must share one durable staging branch.');
assert(weeklyJob.env.PUBLISH_BRANCH &&
  weeklyJob.env.PUBLISH_BRANCH !== weeklyJob.env.STAGING_BRANCH,
  'The Friday PR head must be separate so daily staging pushes do not mutate an open review.');

const collectSteps = collectJob.steps;
const collectById = new Map(collectSteps.filter(step => step.id).map(step => [step.id, step]));
const githubTraffic = collectById.get('github-traffic');
const stats = collectById.get('stats');
const persist = collectById.get('persist');
const prepare = collectSteps.find(step => step.name === 'Prepare durable staging branch');
const finalFailure = collectSteps.find(
  step => step.name === 'Fail when collection or publishing was incomplete'
);

assert(prepare.run.includes('git checkout -B "$STAGING_BRANCH" origin/master') &&
  prepare.run.includes('git merge --no-edit origin/master') &&
  prepare.run.includes('git merge --abort'),
  'First-run staging creation and non-destructive master synchronization must be explicit.');
assert(!prepare.run.includes('reset --hard') && !prepare.run.includes('push --force'),
  'The durable branch must never be reset or force-pushed.');
assert(prepare.run.includes("grep -Ev '^(resource-stats\\.json|design-concepts/resource-stats\\.json|traffic-data/clarity-views\\.json)$'") &&
  prepare.run.includes('reconcile-stats-conflict.js "$file"') &&
  !prepare.run.includes("! printf '%s\\n' \"$conflicts\""),
  'Master synchronization must reconcile only validated durable state and regenerable files.');
const safeConflict = /^(resource-stats\.json|design-concepts\/resource-stats\.json|traffic-data\/clarity-views\.json)$/;
const hasUnsafeConflict = conflicts => conflicts.some(file => !safeConflict.test(file));
assert(!hasUnsafeConflict(['resource-stats.json', 'design-concepts/resource-stats.json']),
  'Derived-only conflicts must be eligible for regeneration.');
assert(!hasUnsafeConflict(['traffic-data/clarity-views.json']),
  'A durable Clarity state conflict must be eligible for structured reconciliation.');
assert(hasUnsafeConflict(['resource-stats.json', 'traffic-data/2026-09-14.json']),
  'A mixed conflict set must stop synchronization instead of overwriting source data.');
assert(githubTraffic?.['continue-on-error'] === true,
  'GitHub traffic failure must not block the independent Clarity source.');
assert(stats?.['continue-on-error'] === true && stats.run.includes('--require-clarity'),
  'Clarity must report unavailability without blocking a healthy GitHub snapshot.');
assert(stats?.if === 'always()', 'Stats must run even when GitHub traffic collection fails.');
assert(persist?.['continue-on-error'] === true,
  'Staging failures must reach the explicit reporting and final failure steps.');
assert(persist.run.includes('git push origin "HEAD:refs/heads/$STAGING_BRANCH"') &&
  persist.run.includes('No pull request was attempted') &&
  !persist.run.includes('gh pr create') &&
  !persist.run.includes('gh pr merge'),
  'Daily collection must persist safely without attempting a PR or auto-merge.');
assert(persist.run.includes('git fetch origin "$STAGING_BRANCH"') &&
  persist.run.includes('Merging once and retrying without force') &&
  persist.run.includes('reconcile-stats-conflict.js "$file"') &&
  persist.run.includes('build-stats.js --render-only'),
  'A concurrent staging advance must receive one bounded merge-and-push retry.');
assert(persist.run.includes('if [ "${{ steps.stats.outputs.generated }}" = "true" ]; then') &&
  persist.run.includes('git add resource-stats.json resource-discussions.json traffic-data/clarity-views.json') &&
  !persist.run.includes('git add traffic-data/ resource-stats.json'),
  'Generated stats must only be staged after the builder marks them safe.');

function evaluateCondition(expression, state) {
  const replacements = new Map([
    ['always()', true],
    ["steps.github-traffic.outcome == 'success'", state.github],
    ["steps.github-traffic.outcome == 'failure'", !state.github],
    ["steps.stats.outputs.clarity_available == 'true'", state.clarity],
    ["steps.stats.outcome == 'failure'", !state.clarity],
    ["steps.persist.outcome == 'failure'", state.persistFailed]
  ]);
  let evaluable = expression;
  for (const [token, value] of replacements) evaluable = evaluable.replaceAll(token, String(value));
  assert(!evaluable.includes('steps.') && /^[\s()!&|truefals]+$/.test(evaluable),
    `Unsupported workflow condition: ${expression}`);
  return Function(`"use strict"; return Boolean(${evaluable});`)();
}

const combinations = [
  { github: true, clarity: true, persistFailed: false, persist: true, fail: false },
  { github: true, clarity: false, persistFailed: false, persist: true, fail: true },
  { github: false, clarity: true, persistFailed: false, persist: true, fail: true },
  { github: false, clarity: false, persistFailed: false, persist: false, fail: true },
  { github: true, clarity: true, persistFailed: true, persist: true, fail: true }
];

for (const combination of combinations) {
  assert(evaluateCondition(persist.if, combination) === combination.persist,
    `Unexpected staging decision for GitHub=${combination.github}, Clarity=${combination.clarity}.`);
  assert(evaluateCondition(finalFailure.if, combination) === combination.fail,
    `Unexpected final status for GitHub=${combination.github}, Clarity=${combination.clarity}.`);
}

const weeklySteps = weeklyJob.steps;
const weeklyById = new Map(weeklySteps.filter(step => step.id).map(step => [step.id, step]));
const sync = weeklyById.get('sync');
const weeklyPr = weeklyById.get('weekly-pr');
assert(sync.run.includes('node tools/catalog-build/build-stats.js --render-only'),
  'Weekly synchronization must render from persisted source state without recollecting.');
assert(sync.run.includes('merge_safely "origin/$STAGING_BRANCH"') &&
  sync.run.includes('HEAD:refs/heads/$PUBLISH_BRANCH') &&
  sync.run.includes('reconcile-stats-conflict.js "$file"'),
  'Friday publishing must copy accumulated state to a separate weekly branch.');
assert(sync.run.includes('git diff --quiet origin/master HEAD'),
  'Friday publishing must skip PR work when staging has no unpublished content.');
assert(weeklyPr.run.includes('gh pr list --head "$PUBLISH_BRANCH" --base master --state open') &&
  weeklyPr.run.includes('gh api --method PATCH') &&
  weeklyPr.run.includes('gh pr create'),
  'Friday publishing must update one open PR before attempting to create another.');
assert(weeklyPr.run.includes('AUTOMATION_PAT_CONFIGURED') &&
  weeklyPr.run.includes('COMPARE_URL') &&
  !weeklyPr.run.includes('gh pr merge'),
  'Blocked PR creation must provide a manual compare URL and remain review-required.');

const catalogStats = catalogWorkflow.jobs.publish.steps.find(
  step => typeof step.run === 'string' && step.run.includes('build:stats')
);
assert(catalogStats.run.includes('--render-only') && !catalogStats.env,
  'Catalog publishing must render persisted stats without collecting short-lived sources.');
assert(!workflowSource.includes('BRANCH="traffic-data/$DATE"'),
  'The workflow must not create date-named daily PR branches.');

console.log('Daily staging and weekly traffic publishing workflow is valid.');
