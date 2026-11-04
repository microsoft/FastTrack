import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// Manual GitHub traffic collection. Writes the same traffic-data/YYYY-MM-DD.json
// snapshot as .github/workflows/traffic-stats.yml, so it is a drop-in way to
// keep the data healthy while the scheduled workflow's token is being fixed.
//
// GitHub only keeps a rolling 14 days of traffic, so run this at least every two
// weeks. Each snapshot overlaps the previous one; the analysis unions days by date.
//
//   gh auth login            (an account with push access to the repository, SSO-authorized for the org)
//   npm run collect:traffic
//
// Options:  --repo owner/name   (default microsoft/FastTrack)
//           --out <directory>   (default <repo root>/traffic-data)
//           --date YYYY-MM-DD   (default: today, UTC)
//
// Authentication comes from gh. To use a token explicitly, set GH_TOKEN first.

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');

function option(name, fallback) {
  const index = process.argv.indexOf(name);
  return index > -1 && process.argv[index + 1] ? process.argv[index + 1] : fallback;
}

const repo = option('--repo', 'microsoft/FastTrack');
const [owner, name] = repo.split('/');
const outputDirectory = option('--out', join(repositoryRoot, 'traffic-data'));
const date = option('--date', new Date().toISOString().slice(0, 10));

if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`--date must be YYYY-MM-DD (received "${date}")`);

const nonRetryable = /Bad credentials|SAML enforcement|Resource not accessible|Must have (admin rights|push access)|HTTP 404|HTTP 422/;

const sleep = milliseconds => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);

function gh(args, { required = true } = {}) {
  let delay = 3000;
  let lastError = '';
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      return JSON.parse(execFileSync('gh', ['api', ...args], {
        encoding: 'utf8',
        maxBuffer: 256 * 1024 * 1024,
        stdio: ['ignore', 'pipe', 'pipe']
      }));
    } catch (error) {
      lastError = `${error.stderr ?? ''}${error.message ?? ''}`.trim();
      if (nonRetryable.test(lastError) || attempt === 3) break;
      sleep(delay);
      delay *= 2;
    }
  }
  if (!required) {
    console.warn(`warning: optional call failed (${args[0]}): ${lastError.split('\n')[0]}`);
    return undefined;
  }
  console.error(`\nFailed: gh api ${args.join(' ')}\n${lastError}\n`);
  console.error('Traffic needs an authenticated account with push access to the repository.');
  console.error('If the message mentions SAML, authorize your token for the organization:');
  console.error('  https://docs.github.com/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on');
  process.exit(1);
}

console.log(`Collecting traffic for ${repo} on ${date}...`);
const views = gh([`repos/${repo}/traffic/views`]);
const clones = gh([`repos/${repo}/traffic/clones`]);
const referrers = gh([`repos/${repo}/traffic/popular/referrers`]);
const paths = gh([`repos/${repo}/traffic/popular/paths`]);

const metadata = gh([`repos/${repo}`], { required: false }) ?? {};

let starTimeline = [];
const stargazerPages = gh(['--paginate', '--slurp', '-H', 'Accept: application/vnd.github.star+json', `repos/${repo}/stargazers`], { required: false });
if (Array.isArray(stargazerPages)) {
  starTimeline = stargazerPages.flat()
    .map(entry => entry?.starred_at)
    .filter(value => typeof value === 'string' && value.length > 0)
    .sort();
}

let locations = [];
const locationResponse = gh([
  'graphql',
  '-f', 'query=query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { stargazers(last: 30) { nodes { ... on User { location } } } } }',
  '-F', `owner=${owner}`,
  '-F', `name=${name}`
], { required: false });
if (locationResponse && !(locationResponse.errors?.length > 0)) {
  locations = (locationResponse.data?.repository?.stargazers?.nodes ?? [])
    .map(node => node?.location)
    .filter(value => typeof value === 'string' && value.length > 0);
}

const snapshot = {
  collected_at: date,
  views,
  clones,
  referrers,
  paths,
  stars: metadata.stargazers_count ?? 0,
  forks: metadata.forks_count ?? 0,
  star_timeline: starTimeline,
  stargazer_locations: locations
};

mkdirSync(outputDirectory, { recursive: true });
const file = join(outputDirectory, `${date}.json`);
writeFileSync(file, `${JSON.stringify(snapshot, null, 2)}\n`);

const days = views.views?.length ?? 0;
console.log(`Saved ${file}`);
console.log(`  views: ${views.count} (${views.uniques} unique) over ${days} days, clones: ${clones.count} (${clones.uniques} unique)`);
console.log(`  stars: ${snapshot.stars}, forks: ${snapshot.forks}, referrers: ${referrers.length}, paths: ${paths.length}`);
