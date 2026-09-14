import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { reconcileClarityStates } from './stats-state.js';

const path = process.argv[2];
if (path !== 'traffic-data/clarity-views.json') {
  console.error(`Unsupported durable stats conflict: ${path ?? '(missing path)'}`);
  process.exit(1);
}

function readStage(stage) {
  try {
    return JSON.parse(execFileSync('git', ['show', `:${stage}:${path}`], { encoding: 'utf8' }));
  } catch (error) {
    throw new Error(`Could not read merge stage ${stage} for ${path}: ${error.message}`);
  }
}

try {
  const { state, relation } = reconcileClarityStates(readStage(2), readStage(3));
  writeFileSync(path, `${JSON.stringify(state, null, 2)}\n`);
  console.log(`Reconciled ${path} using ${relation}; overlapping daily resource values were identical.`);
} catch (error) {
  console.error(`Refusing to auto-resolve ${path}: ${error.message}`);
  process.exit(1);
}
