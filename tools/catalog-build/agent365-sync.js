// Records which version of each cited guide step and section the Enablement Checklist was last aligned
// with, in agent365-sync-state.json. Run it after you have reviewed the checklist tasks that cite a
// step you changed in the guide. `npm run check` fails until the recorded state matches the guide.
//
//   node agent365-sync.js                      record the current state of every cited step
//   node agent365-sync.js --guide-reviewed     also set the guide's review date to today
//   node agent365-sync.js --guide-reviewed 2026-10-15
import { assertParsed, checkSync, compareFingerprints, currentFingerprints, loadChecklist, loadGuide, loadSyncState, saveSyncState } from './agent365-content.js';

const args = process.argv.slice(2);
const reviewedFlag = args.indexOf('--guide-reviewed');
let reviewedDate = '';
if (reviewedFlag >= 0) {
  reviewedDate = /^\d{4}-\d{2}-\d{2}$/.test(args[reviewedFlag + 1] ?? '') ? args[reviewedFlag + 1] : new Date().toISOString().slice(0, 10);
}

const guide = loadGuide();
const checklist = loadChecklist();
assertParsed(guide, checklist);
const sync = checkSync(guide, checklist);
const unresolved = [...sync.broken, ...sync.unverified, ...sync.missingTargets];
if (unresolved.length) {
  console.error('Fix these checklist references before recording the sync state:');
  for (const item of unresolved) console.error(`- "${item.label}"${item.problems ? `: ${item.problems.join(' ')}` : ''}`);
  process.exit(1);
}

const state = loadSyncState();
const current = currentFingerprints(guide, sync);
const changes = compareFingerprints(state, current, sync);
state.steps = current.steps;
state.sections = current.sections;
state.reviewed = { ...state.reviewed, ...(reviewedDate ? { guide: reviewedDate } : {}) };
saveSyncState(state);

console.log(`Recorded ${Object.keys(current.steps).length} guide steps and ${Object.keys(current.sections).length} sections.`);
for (const change of changes) {
  console.log(`- ${change.label} ${change.key} ${change.reason}${change.tasks.length ? `; cited by ${change.tasks.length} checklist task(s)` : ''}`);
}
if (reviewedDate) console.log(`Guide review date set to ${reviewedDate}.`);
