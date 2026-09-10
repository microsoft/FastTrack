import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as yaml from 'js-yaml';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const workflowPath = join(toolDirectory, '..', '..', '.github', 'workflows', 'traffic-stats.yml');
const workflow = yaml.load(readFileSync(workflowPath, 'utf8'));
const steps = workflow.jobs['collect-traffic'].steps;
const byId = new Map(steps.filter(step => step.id).map(step => [step.id, step]));

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const githubTraffic = byId.get('github-traffic');
const stats = byId.get('stats');
const publish = byId.get('publish');
const finalFailure = steps.find(step => step.name === 'Fail when collection or publishing was incomplete');

assert(githubTraffic?.['continue-on-error'] === true,
  'GitHub traffic failure must not block the independent Clarity source.');
assert(stats?.['continue-on-error'] === true && stats.run.includes('--require-clarity'),
  'Clarity must report unavailability without blocking a healthy GitHub snapshot.');
assert(stats?.if === 'always()',
  'Stats must run even when GitHub traffic collection fails.');
assert(publish?.['continue-on-error'] === true,
  'Publishing failures must reach the explicit reporting and final failure steps.');
assert(publish.run.includes('if [ "${{ steps.stats.outputs.generated }}" = "true" ]; then') &&
  publish.run.includes('git add resource-stats.json resource-discussions.json traffic-data/clarity-views.json') &&
  !publish.run.includes('git add traffic-data/ resource-stats.json'),
  'Generated stats must only be staged after the builder marks them safe.');

function evaluateCondition(expression, state) {
  const replacements = new Map([
    ['always()', true],
    ["steps.github-traffic.outcome == 'success'", state.github],
    ["steps.github-traffic.outcome == 'failure'", !state.github],
    ["steps.stats.outputs.clarity_available == 'true'", state.clarity],
    ["steps.stats.outcome == 'failure'", !state.clarity],
    ["steps.publish.outcome == 'failure'", state.publishFailed]
  ]);
  let evaluable = expression;
  for (const [token, value] of replacements) {
    evaluable = evaluable.replaceAll(token, String(value));
  }
  assert(!evaluable.includes('steps.') && /^[\s()!&|truefals]+$/.test(evaluable),
    `Unsupported workflow condition: ${expression}`);
  return Function(`"use strict"; return Boolean(${evaluable});`)();
}

const combinations = [
  { github: true, clarity: true, publishFailed: false, publish: true, fail: false },
  { github: true, clarity: false, publishFailed: false, publish: true, fail: true },
  { github: false, clarity: true, publishFailed: false, publish: true, fail: true },
  { github: false, clarity: false, publishFailed: false, publish: false, fail: true },
  { github: true, clarity: true, publishFailed: true, publish: true, fail: true }
];

for (const combination of combinations) {
  assert(evaluateCondition(publish.if, combination) === combination.publish,
    `Unexpected publishing decision for GitHub=${combination.github}, Clarity=${combination.clarity}.`);
  assert(evaluateCondition(finalFailure.if, combination) === combination.fail,
    `Unexpected final status for GitHub=${combination.github}, Clarity=${combination.clarity}.`);
}

console.log('Traffic workflow source availability matrix is valid.');
