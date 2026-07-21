import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const catalogPath = join(repositoryRoot, 'catalog.json');
const discussionsPath = join(repositoryRoot, 'resource-discussions.json');
const confirmed = process.argv.includes('--yes');
const token = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN;

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function writeDiscussions(config) {
  writeFileSync(discussionsPath, `${JSON.stringify(config, null, 2)}\n`);
}

async function graphql(query, variables) {
  const response = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'User-Agent': 'fasttrack-stats'
    },
    body: JSON.stringify({ query, variables })
  });
  if (!response.ok) throw new Error(`GitHub returned ${response.status}: ${await response.text()}`);
  const payload = await response.json();
  if (payload.errors?.length) throw new Error(payload.errors.map(error => error.message).join('; '));
  return payload.data;
}

async function resolveRepositoryAndCategory(repo) {
  const [owner, name] = repo.split('/');
  const query = `query($owner:String!,$name:String!) {
    repository(owner:$owner,name:$name) {
      id
      discussionCategories(first:100) { nodes { id name } }
    }
  }`;
  const repository = (await graphql(query, { owner, name }))?.repository;
  if (!repository) throw new Error(`Repository ${repo} was not found.`);
  const category = repository.discussionCategories.nodes.find(
    item => item.name === 'Resource Votes'
  );
  if (!category) throw new Error('Discussion category "Resource Votes" was not found.');
  return { repositoryId: repository.id, categoryId: category.id };
}

async function createDiscussion(repositoryId, categoryId, resource) {
  const mutation = `mutation($input:CreateDiscussionInput!) {
    createDiscussion(input:$input) {
      discussion { number url }
    }
  }`;
  const body = [
    'React with 👍 to upvote this resource in the FastTrack gallery.',
    '',
    `Resource: ${resource.url}`,
    `Slug: \`${resource.slug}\``
  ].join('\n');
  return (await graphql(mutation, {
    input: {
      repositoryId,
      categoryId,
      title: resource.slug,
      body
    }
  })).createDiscussion.discussion;
}

const catalog = readJson(catalogPath);
const discussionConfig = existsSync(discussionsPath)
  ? readJson(discussionsPath)
  : {
      repo: 'microsoft/FastTrack',
      note: 'Maps gallery resource slug -> GitHub Discussion number in the Resource Votes category.',
      map: {}
    };
discussionConfig.map ??= {};
const pending = catalog.resources.filter(
  resource => !Object.hasOwn(discussionConfig.map, resource.slug)
);

console.log('Note: this legacy filename now creates GitHub Discussions, not issues.');
if (pending.length === 0) {
  console.log('All catalog resources already have entries in resource-discussions.json.');
} else if (!confirmed) {
  console.log(`Dry run: would create ${pending.length} discussion${pending.length === 1 ? '' : 's'} in ${discussionConfig.repo}:`);
  for (const resource of pending) console.log(`- ${resource.slug}`);
  console.log('Re-run with --yes to create them.');
  if (!token) console.log('Set GITHUB_TOKEN or GH_TOKEN before re-running with --yes.');
} else if (!token) {
  console.error('Set GITHUB_TOKEN or GH_TOKEN before creating discussions.');
  process.exitCode = 1;
} else {
  try {
    const ids = await resolveRepositoryAndCategory(discussionConfig.repo);
    let created = 0;
    for (const resource of pending) {
      try {
        const discussion = await createDiscussion(ids.repositoryId, ids.categoryId, resource);
        discussionConfig.map[resource.slug] = discussion.number;
        writeDiscussions(discussionConfig);
        created += 1;
        console.log(`Created #${discussion.number}: ${resource.slug} (${discussion.url})`);
      } catch (error) {
        console.warn(`Warning: could not create discussion for ${resource.slug}: ${error.message}`);
      }
    }
    console.log(`Created ${created} of ${pending.length} vote discussions.`);
  } catch (error) {
    console.error(`Could not prepare discussion creation: ${error.message}`);
    process.exitCode = 1;
  }
}
