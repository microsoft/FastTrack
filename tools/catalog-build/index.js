import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import matter from 'gray-matter';
import yaml from 'js-yaml';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const checkOnly = process.argv.includes('--check');

const folderRoots = [
  'scripts',
  'copilot-agent-samples/copilot-studio-agents',
  'copilot-agent-samples/agent-builder-agents',
  'copilot-agent-samples/github-copilot-agents',
  'copilot-agent-samples/github-copilot-skills',
  'copilot-agent-strategy',
  'copilot-analytics-samples'
];
const promptRoot = 'copilot-prompt-samples';
const excludedSegments = new Set(['archive', '_sample_templates', 'samples']);
const allowedTypes = new Set(['script', 'agent', 'strategy', 'analytics', 'prompt', 'skill']);
const allowedFormats = new Set(['ps1', 'bundle', 'declarative', 'interactive', 'pptx', 'pbix', 'md']);
const allowedStatuses = new Set(['active', 'preview', 'archived']);
const semverPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
const datePattern = /^\d{4}-\d{2}-\d{2}$/;

function toPosix(path) {
  return path.split(sep).join('/');
}

function isExcluded(path) {
  return toPosix(relative(repositoryRoot, path))
    .toLowerCase()
    .split('/')
    .some(segment => excludedSegments.has(segment));
}

function collectReadmes(directory, files = []) {
  if (!existsSync(directory) || isExcluded(directory)) return files;

  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (isExcluded(path)) continue;
    if (entry.isDirectory()) collectReadmes(path, files);
    else if (entry.name.toLowerCase() === 'readme.md') files.push(path);
  }
  return files;
}

function collectCandidates() {
  const files = folderRoots.flatMap(root => collectReadmes(join(repositoryRoot, ...root.split('/'))));
  const promptsDirectory = join(repositoryRoot, promptRoot);

  if (existsSync(promptsDirectory)) {
    for (const entry of readdirSync(promptsDirectory, { withFileTypes: true })) {
      if (entry.isFile() && entry.name.toLowerCase().endsWith('.md') && entry.name.toLowerCase() !== 'readme.md') {
        files.push(join(promptsDirectory, entry.name));
      }
    }
  }

  return [...new Set(files)].sort();
}

function hasFrontMatter(source) {
  return source.replace(/^\uFEFF/, '').startsWith('---\n') ||
    source.replace(/^\uFEFF/, '').startsWith('---\r\n');
}

function parseFrontMatter(source) {
  return matter(source, {
    engines: {
      yaml: input => yaml.load(input, { schema: yaml.JSON_SCHEMA })
    }
  }).data;
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isStringList(value) {
  return Array.isArray(value) && value.length > 0 && value.every(isNonEmptyString);
}

function isValidDate(value) {
  if (!isNonEmptyString(value) || !datePattern.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.valueOf()) && parsed.toISOString().slice(0, 10) === value;
}

function gitUpdatedDate(file) {
  const relativePath = toPosix(relative(repositoryRoot, file));
  try {
    return execFileSync('git', ['log', '-1', '--format=%cs', '--', relativePath], {
      cwd: repositoryRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    }).trim();
  } catch {
    return '';
  }
}

function validate(data, file) {
  const errors = [];
  const add = (field, message) => errors.push({ file, field, message });

  for (const field of ['title', 'type', 'category', 'summary', 'author', 'version', 'published']) {
    if (data[field] === undefined || data[field] === null || data[field] === '') {
      add(field, 'is required');
    }
  }

  if (data.title !== undefined && !isNonEmptyString(data.title)) add('title', 'must be a non-empty string');
  if (data.type !== undefined && !allowedTypes.has(data.type)) add('type', `must be one of: ${[...allowedTypes].join(', ')}`);
  if (data.category !== undefined && !isNonEmptyString(data.category)) add('category', 'must be a non-empty string');
  if (data.summary !== undefined) {
    if (!isNonEmptyString(data.summary)) add('summary', 'must be a non-empty string');
    else if ([...data.summary].length > 140) add('summary', `must be 140 characters or fewer (found ${[...data.summary].length})`);
  }
  if (data.author !== undefined && !isNonEmptyString(data.author) && !isStringList(data.author)) {
    add('author', 'must be a non-empty string or a non-empty list of strings');
  }
  if (data.version !== undefined && (!isNonEmptyString(data.version) || !semverPattern.test(data.version))) {
    add('version', 'must be a semantic version such as 1.0.0');
  }
  if (data.published !== undefined && !isValidDate(data.published)) add('published', 'must use YYYY-MM-DD');
  if (data.updated !== undefined && !isValidDate(data.updated)) add('updated', 'must use YYYY-MM-DD');
  if (data.tags !== undefined && !isStringList(data.tags)) add('tags', 'must be a non-empty list of strings');
  if (data.format !== undefined && !allowedFormats.has(data.format)) add('format', `must be one of: ${[...allowedFormats].join(', ')}`);
  if (data.featured !== undefined && typeof data.featured !== 'boolean') add('featured', 'must be true or false');
  if (data.status !== undefined && !allowedStatuses.has(data.status)) add('status', `must be one of: ${[...allowedStatuses].join(', ')}`);
  if (data.whatItIs !== undefined && !isNonEmptyString(data.whatItIs)) add('whatItIs', 'must be a non-empty string');
  if (data.whyUseIt !== undefined && !isStringList(data.whyUseIt)) add('whyUseIt', 'must be a non-empty list of strings');
  if (data.howToUse !== undefined && !isNonEmptyString(data.howToUse)) add('howToUse', 'must be a non-empty Markdown string');
  if (data.prerequisites !== undefined && !isStringList(data.prerequisites)) add('prerequisites', 'must be a non-empty list of strings');
  if (data.url !== undefined) {
    try {
      const url = new URL(data.url);
      if (url.protocol !== 'https:') add('url', 'must be an HTTPS URL');
    } catch {
      add('url', 'must be a valid HTTPS URL');
    }
  }

  return errors;
}

function deriveUrl(file) {
  const relativePath = toPosix(relative(repositoryRoot, file));
  const isPrompt = relativePath.startsWith(`${promptRoot}/`);
  const target = isPrompt ? relativePath : relativePath.replace(/\/readme\.md$/i, '');
  const encodedTarget = target.split('/').map(encodeURIComponent).join('/');
  return `https://github.com/microsoft/FastTrack/${isPrompt ? 'blob' : 'tree'}/master/${encodedTarget}`;
}

function slugify(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function createResource(data, file, updated) {
  const relativePath = toPosix(relative(repositoryRoot, file));
  const resource = {
    name: data.title,
    title: data.title,
    slug: slugify(data.title),
    type: data.type,
    subcategory: data.category,
    category: data.category,
    description: data.summary,
    summary: data.summary,
    tags: data.tags ?? [],
    artifact: data.format ?? 'md',
    format: data.format ?? 'md',
    featured: data.featured ?? false,
    status: data.status ?? 'active',
    author: data.author,
    version: data.version,
    published: data.published,
    updated,
    whatItIs: data.whatItIs,
    whyUseIt: data.whyUseIt ?? [],
    howToUse: data.howToUse,
    prerequisites: data.prerequisites ?? [],
    url: data.url ?? deriveUrl(file),
    source: relativePath
  };

  return Object.fromEntries(Object.entries(resource).filter(([, value]) => value !== undefined));
}

const candidates = collectCandidates();
const resources = [];
const errors = [];

for (const file of candidates) {
  const source = readFileSync(file, 'utf8');
  if (!hasFrontMatter(source)) continue;

  let data;
  try {
    data = parseFrontMatter(source);
  } catch (error) {
    errors.push({ file, field: 'front matter', message: error.message });
    continue;
  }

  const updated = data.updated ?? gitUpdatedDate(file);
  if (!updated) errors.push({ file, field: 'updated', message: 'is required or must be derivable from Git history' });
  else data.updated = updated;
  errors.push(...validate(data, file));

  if (!errors.some(error => error.file === file)) {
    resources.push(createResource(data, file, updated));
  }
}

if (resources.length === 0 && errors.length === 0) {
  errors.push({ file: repositoryRoot, field: 'catalog', message: 'contains no resources with YAML front matter' });
}

if (errors.length > 0) {
  console.error(`Catalog validation failed with ${errors.length} error${errors.length === 1 ? '' : 's'}:`);
  for (const error of errors) {
    console.error(`- ${toPosix(relative(repositoryRoot, error.file))}: ${error.field} ${error.message}`);
  }
  process.exitCode = 1;
} else if (checkOnly) {
  console.log(`Catalog metadata is valid for ${resources.length} resources.`);
} else {
  resources.sort((a, b) => a.title.localeCompare(b.title));
  const latestUpdated = resources.reduce((max, resource) => (
    resource.updated && resource.updated > max ? resource.updated : max
  ), '');
  const catalog = {
    generatedAt: latestUpdated,
    count: resources.length,
    resources
  };
  const output = `${JSON.stringify(catalog, null, 2)}\n`;
  const rootOutput = join(repositoryRoot, 'catalog.json');
  const siteOutput = join(repositoryRoot, 'design-concepts', 'catalog.json');
  writeFileSync(rootOutput, output);
  if (existsSync(dirname(siteOutput))) writeFileSync(siteOutput, output);
  console.log(`Wrote ${resources.length} resources to ${toPosix(relative(repositoryRoot, rootOutput))} and design-concepts/catalog.json.`);
}
