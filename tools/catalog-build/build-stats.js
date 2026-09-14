import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { replaceClarityDays, unchangedStatsPayload } from './stats-state.js';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const checkOnly = process.argv.includes('--check');
const requireClarity = process.argv.includes('--require-clarity');
const renderOnly = process.argv.includes('--render-only');
const trafficDirectory = join(repositoryRoot, 'traffic-data');
const clarityStatePath = join(trafficDirectory, 'clarity-views.json');
const catalogPath = join(repositoryRoot, 'catalog.json');
const discussionsPath = join(repositoryRoot, 'resource-discussions.json');
const statsPath = join(repositoryRoot, 'resource-stats.json');
const githubToken = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN;
const clarityToken = process.env.CLARITY_API_TOKEN;
const dayMilliseconds = 24 * 60 * 60 * 1000;
const runDate = new Date().toISOString().slice(0, 10);

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function readOptionalJson(path, fallback) {
  if (!existsSync(path)) return fallback;
  try {
    return readJson(path);
  } catch (error) {
    console.warn(`Warning: could not read ${path}: ${error.message}`);
    return fallback;
  }
}

function numberFrom(value) {
  const number = typeof value === 'string' && value.trim() !== '' ? Number(value) : value;
  return Number.isFinite(number) && number >= 0 ? number : undefined;
}

function logicalRepoPath(pathname) {
  // Strip the `/owner/repo/(tree|blob)/<ref>/` prefix so `/tree/` folder views and
  // `/blob/` file views normalize to the same repo-relative path. Repo-root and
  // bare `/tree/<ref>` paths (which map to nothing) collapse to an empty string.
  if (typeof pathname !== 'string') return '';
  const stripped = pathname.replace(/^\/[^/]+\/[^/]+\/(?:tree|blob)\/[^/]+\//, '');
  return stripped === pathname ? '' : stripped.replace(/\/+$/, '');
}

function collectFallbackViews(resourceFolders) {
  if (!existsSync(trafficDirectory)) return new Map();

  const snapshots = readdirSync(trafficDirectory)
    .filter(file => /^\d{4}-\d{2}-\d{2}\.json$/.test(file))
    .sort()
    .map(file => ({
      date: new Date(`${file.slice(0, 10)}T00:00:00Z`),
      file
    }))
    .filter(snapshot => !Number.isNaN(snapshot.date.valueOf()));

  const totals = new Map();
  let lastAccepted;

  for (const snapshot of snapshots) {
    if (lastAccepted && snapshot.date - lastAccepted < 14 * dayMilliseconds) continue;

    let data;
    try {
      data = readJson(join(trafficDirectory, snapshot.file));
    } catch (error) {
      console.warn(`Warning: skipping ${snapshot.file}: ${error.message}`);
      continue;
    }

    lastAccepted = snapshot.date;
    for (const entry of Array.isArray(data.paths) ? data.paths : []) {
      if (typeof entry.path !== 'string' ||
          !Number.isFinite(entry.count) ||
          !Number.isFinite(entry.uniques)) continue;

      // Roll a resource's own folder view and any traffic to files/subfolders beneath it
      // into that resource. resourceFolders is sorted longest-first, so each path is
      // credited to its most specific resource and never to an ancestor folder.
      const logical = logicalRepoPath(entry.path);
      if (!logical) continue;
      const match = resourceFolders.find(
        folder => logical === folder.path || logical.startsWith(`${folder.path}/`)
      );
      if (!match) continue;

      const total = totals.get(match.slug) ?? { views: 0, viewsUniques: 0 };
      total.views += entry.count;
      total.viewsUniques += entry.uniques;
      totals.set(match.slug, total);
    }
  }

  return totals;
}

function slugFromClarityUrl(value, knownSlugs) {
  if (typeof value !== 'string') return undefined;
  try {
    const slug = decodeURIComponent(new URL(value).hash.slice(1));
    return knownSlugs.has(slug) ? slug : undefined;
  } catch {
    return undefined;
  }
}

function dateFromClarityRow(row) {
  const value = row.date ?? row.Date ?? row.day ?? row.Day;
  if (typeof value !== 'string') return undefined;
  const match = value.match(/^\d{4}-\d{2}-\d{2}/);
  return match?.[0];
}

function metricsFromClarityRow(row) {
  const explicitViews = numberFrom(
    row.pageViews ?? row.pageviews ?? row.PageViews ?? row.views ??
    row.totalScreenCount ?? row.visitsCount
  );
  const sessions = numberFrom(row.totalSessionCount ?? row.sessions ?? row.sessionCount);
  const pagesPerSession = numberFrom(
    row.pagesPerSession ?? row.PagesPerSession ?? row.PagesPerSessionPercentage
  );
  const views = explicitViews ?? (
    sessions !== undefined && pagesPerSession !== undefined
      ? sessions * pagesPerSession
      : sessions
  );
  const uniques = numberFrom(
    row.distinctUserCount ?? row.distantUserCount ?? row.uniqueUserCount ??
    row.uniqueUsers ?? row.users
  );
  return {
    ...(views !== undefined ? { views: Math.round(views) } : {}),
    ...(uniques !== undefined ? { uniques: Math.round(uniques) } : {})
  };
}

function parseClarityTraffic(data, knownSlugs) {
  const traffic = Array.isArray(data)
    ? data.find(metric => metric?.metricName === 'Traffic')
    : undefined;
  if (!traffic || !Array.isArray(traffic.information)) {
    throw new Error('Clarity response did not include the Traffic metric');
  }
  const totals = new Map();
  const dated = new Map();

  for (const row of traffic.information) {
    const slug = slugFromClarityUrl(row.URL ?? row.Url ?? row.url, knownSlugs);
    if (!slug) continue;
    const metrics = metricsFromClarityRow(row);
    if (metrics.views === undefined) continue;

    const date = dateFromClarityRow(row);
    const target = date
      ? (dated.get(date) ?? new Map())
      : totals;
    const current = target.get(slug) ?? { views: 0 };
    current.views += metrics.views;
    if (metrics.uniques !== undefined) current.uniques = (current.uniques ?? 0) + metrics.uniques;
    target.set(slug, current);
    if (date) dated.set(date, target);
  }

  return { totals, dated };
}

async function fetchClarity(days, knownSlugs) {
  const url = new URL('https://www.clarity.ms/export-data/api/v1/project-live-insights');
  url.searchParams.set('numOfDays', String(days));
  url.searchParams.set('dimension1', 'URL');
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${clarityToken}`,
      Accept: 'application/json'
    }
  });
  if (!response.ok) throw new Error(`Clarity returned ${response.status}`);
  return parseClarityTraffic(await response.json(), knownSlugs);
}

function subtractClarityTotals(larger, smaller) {
  const result = new Map();
  for (const [slug, metrics] of larger) {
    const previous = smaller.get(slug);
    const views = metrics.views - (previous?.views ?? 0);
    if (views < 0) {
      console.warn(`Warning: Clarity returned a negative window difference for ${slug}; skipping it.`);
      continue;
    }
    const entry = { views: Math.round(views) };
    if (metrics.uniques !== undefined && previous?.uniques !== undefined) {
      const uniques = metrics.uniques - previous.uniques;
      if (uniques >= 0) entry.uniques = Math.round(uniques);
    }
    result.set(slug, entry);
  }
  return result;
}

function setActionOutput(name, value) {
  if (process.env.GITHUB_OUTPUT) {
    appendFileSync(process.env.GITHUB_OUTPUT, `${name}=${value}\n`);
  }
}

async function updateClarityState(state, knownSlugs) {
  if (renderOnly) {
    console.log('Render-only mode; using persisted Clarity views without collecting.');
    return { available: false, changed: false };
  }
  if (!clarityToken) {
    console.log('CLARITY_API_TOKEN is not set; preserving accumulated Clarity views.');
    return { available: false, changed: false };
  }

  try {
    const threeDays = await fetchClarity(3, knownSlugs);
    if (threeDays.dated.size > 0) {
      replaceClarityDays(state, threeDays.dated, runDate);
    } else {
      // The API normally returns rolling aggregates rather than dates. Cumulative 1/2/3-day
      // windows are differenced so each run persists overlap-safe daily buckets.
      const [twoDays, oneDay] = await Promise.all([
        fetchClarity(2, knownSlugs),
        fetchClarity(1, knownSlugs)
      ]);
      const dates = [0, 1, 2].map(offset =>
        new Date(Date.parse(`${runDate}T00:00:00Z`) - offset * dayMilliseconds)
          .toISOString().slice(0, 10)
      );
      replaceClarityDays(state, new Map([
        [dates[0], oneDay.totals],
        [dates[1], subtractClarityTotals(twoDays.totals, oneDay.totals)],
        [dates[2], subtractClarityTotals(threeDays.totals, twoDays.totals)]
      ]), runDate);
    }
    return { available: true, changed: true };
  } catch (error) {
    console.warn(`Warning: could not collect Clarity views: ${error.message}`);
    return { available: false, changed: false };
  }
}

function collectClarityViews(state, knownSlugs) {
  const totals = new Map();
  for (const bucket of Object.values(state.days)) {
    if (!bucket || typeof bucket !== 'object') continue;
    for (const [slug, metrics] of Object.entries(bucket)) {
      if (!knownSlugs.has(slug) || !metrics || typeof metrics !== 'object') continue;
      const views = numberFrom(metrics.views);
      if (views === undefined) continue;
      const total = totals.get(slug) ?? { views: 0 };
      total.views += Math.round(views);
      const uniques = numberFrom(metrics.uniques);
      if (uniques !== undefined) total.viewsUniques = (total.viewsUniques ?? 0) + Math.round(uniques);
      totals.set(slug, total);
    }
  }
  return totals;
}

async function githubGraphql(query, variables) {
  const response = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${githubToken}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'User-Agent': 'fasttrack-stats'
    },
    body: JSON.stringify({ query, variables })
  });
  if (!response.ok) throw new Error(`GitHub returned ${response.status}`);
  const payload = await response.json();
  if (payload.errors?.length) throw new Error(payload.errors.map(error => error.message).join('; '));
  return payload.data;
}

async function collectDiscussions() {
  const discussions = [];
  if (renderOnly) {
    console.log('Render-only mode; using persisted discussion stats without collecting.');
    return { available: false, discussions };
  }
  if (!githubToken) {
    console.log('GITHUB_TOKEN or GH_TOKEN is not set; skipping discussion upvotes.');
    return { available: false, discussions };
  }

  const query = `query($owner:String!,$name:String!,$after:String) {
    repository(owner:$owner,name:$name) {
      discussions(first:100,after:$after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          number
          url
          title
          category { name }
          reactionGroups { content reactors { totalCount } }
        }
      }
    }
  }`;
  let after = null;
  try {
    do {
      const data = await githubGraphql(query, { owner: 'microsoft', name: 'FastTrack', after });
      const connection = data?.repository?.discussions;
      if (!connection) throw new Error('GitHub did not return the discussions connection');
      discussions.push(...connection.nodes.filter(
        discussion => discussion?.category?.name === 'Resource Votes'
      ));
      after = connection.pageInfo.hasNextPage ? connection.pageInfo.endCursor : null;
    } while (after);
  } catch (error) {
    console.warn(`Warning: could not collect GitHub Discussions: ${error.message}`);
    return { available: false, discussions: [] };
  }
  return { available: true, discussions };
}

function mapDiscussions(discussions, knownSlugs, explicitMap) {
  const byNumber = new Map(discussions.map(discussion => [discussion.number, discussion]));
  const result = new Map();

  for (const slug of knownSlugs) {
    const hasExplicitMapping = Object.hasOwn(explicitMap, slug);
    const mappedNumber = explicitMap[slug];
    let discussion;
    if (hasExplicitMapping) {
      discussion = Number.isInteger(mappedNumber) ? byNumber.get(mappedNumber) : undefined;
      if (!discussion) {
        console.warn(`Warning: mapped discussion #${mappedNumber} for ${slug} was not found.`);
        continue;
      }
    } else {
      discussion = discussions.find(item => item.title === slug) ??
        discussions.find(item => item.title.includes(slug));
    }
    if (!discussion) continue;
    const count = (discussion.reactionGroups ?? []).reduce((sum, group) => {
      const total = group?.reactors?.totalCount;
      return sum + (Number.isInteger(total) && total > 0 ? total : 0);
    }, 0);
    result.set(slug, {
      upvotes: count,
      discussion: { number: discussion.number, url: discussion.url }
    });
  }
  return result;
}

function previousUpvotes(previousStats, knownSlugs) {
  const result = new Map();
  for (const [slug, stats] of Object.entries(previousStats?.resources ?? {})) {
    if (!knownSlugs.has(slug) || !stats || typeof stats !== 'object') continue;
    const upvotes = numberFrom(stats.upvotes);
    if (upvotes === undefined) continue;
    result.set(slug, {
      upvotes: Math.round(upvotes),
      ...(stats.discussion ? { discussion: stats.discussion } : {})
    });
  }
  return result;
}

const catalog = readJson(catalogPath);
const knownSlugs = new Set(catalog.resources.map(resource => resource.slug));
const resourceFolders = catalog.resources
  .map(resource => {
    try {
      return { slug: resource.slug, path: logicalRepoPath(new URL(resource.url).pathname) };
    } catch {
      console.warn(`Warning: could not parse URL for ${resource.slug}.`);
      return { slug: resource.slug, path: '' };
    }
  })
  .filter(folder => folder.path)
  .sort((left, right) => right.path.length - left.path.length);
const discussionConfig = readOptionalJson(discussionsPath, {
  repo: 'microsoft/FastTrack',
  note: 'Maps gallery resource slug -> GitHub Discussion number in the Resource Votes category.',
  map: {}
});
const previousStats = readOptionalJson(statsPath, {});
const clarityState = readOptionalJson(clarityStatePath, { lastRun: '', days: {} });
if (!clarityState.days || typeof clarityState.days !== 'object') clarityState.days = {};

const clarityResult = await updateClarityState(clarityState, knownSlugs);
const clarityViews = collectClarityViews(clarityState, knownSlugs);
const fallbackViews = collectFallbackViews(resourceFolders);
const discussionResult = await collectDiscussions();
const upvoteTotals = discussionResult.available
  ? mapDiscussions(discussionResult.discussions, knownSlugs, discussionConfig.map ?? {})
  : previousUpvotes(previousStats, knownSlugs);
const resources = {};
let viewCount = 0;
let upvoteCount = 0;

for (const resource of catalog.resources) {
  const stats = {};
  const clarity = clarityViews.get(resource.slug);
  const fallback = fallbackViews.get(resource.slug);

  // Clarity is authoritative once it has a nonzero cumulative total; legacy GitHub
  // path traffic only prevents existing resources from losing views during migration.
  const views = clarity?.views > 0 ? clarity : fallback;
  if (views) {
    Object.assign(stats, views);
    viewCount += 1;
  }

  const upvotes = upvoteTotals.get(resource.slug);
  if (upvotes) {
    Object.assign(stats, upvotes);
    upvoteCount += 1;
  }

  if (Object.keys(stats).length > 0) resources[resource.slug] = stats;
}

const payload = {
  sources: {
    views: 'clarity',
    upvotes: 'github-discussions'
  },
  resources
};
const generatedAt = unchangedStatsPayload(previousStats, payload) && previousStats.generatedAt
  ? previousStats.generatedAt
  : new Date().toISOString();
const output = `${JSON.stringify({ generatedAt, ...payload }, null, 2)}\n`;

if (!checkOnly) {
  mkdirSync(trafficDirectory, { recursive: true });
  writeFileSync(statsPath, output);
  if (!existsSync(discussionsPath)) {
    writeFileSync(discussionsPath, `${JSON.stringify(discussionConfig, null, 2)}\n`);
  }
  if (clarityResult.changed || !existsSync(clarityStatePath)) {
    writeFileSync(clarityStatePath, `${JSON.stringify(clarityState, null, 2)}\n`);
  }
}

console.log(`${checkOnly ? 'Checked' : 'Wrote'} real stats for ${viewCount} resource${viewCount === 1 ? '' : 's'} with views and ${upvoteCount} resource${upvoteCount === 1 ? '' : 's'} with upvotes.`);

setActionOutput('generated', 'true');
setActionOutput('clarity_available', String(clarityResult.available));

if (requireClarity && !clarityResult.available) {
  console.error('Clarity collection is required but unavailable; accumulated values were preserved and no missing metrics were replaced with zero.');
  process.exitCode = 1;
}
