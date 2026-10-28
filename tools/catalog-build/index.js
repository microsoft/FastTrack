import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import matter from 'gray-matter';
import * as yaml from 'js-yaml';
import { renderFeed, renderResourcePage, renderSitemap, resourcePath } from './site-pages.js';

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');
const checkOnly = process.argv.includes('--check');

const folderRoots = [
  'scripts',
  'samples',
  'tools/SimpleGraph',
  'copilot-agent-samples/copilot-studio-agents',
  'copilot-agent-samples/agent-builder-agents',
  'copilot-agent-samples/github-copilot-agents',
  'copilot-agent-samples/github-copilot-skills',
  'copilot-agent-samples/ESS',
  'copilot-agent-strategy',
  'copilot-analytics-samples'
];
const promptRoot = 'copilot-prompt-samples';
const excludedSegments = new Set(['archive', '_sample_templates', 'node_modules']);
const allowedTypes = new Set(['script', 'agent', 'strategy', 'analytics', 'prompt', 'skill']);
const allowedFormats = new Set(['ps1', 'bundle', 'declarative', 'interactive', 'pptx', 'pbix', 'md']);
const allowedStatuses = new Set(['active', 'preview', 'archived']);
const allowedInteractiveKinds = new Set(['guide', 'tool']);
const semverPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
const datePattern = /^\d{4}-\d{2}-\d{2}$/;
const kebabPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function toPosix(path) {
  return path.split(sep).join('/');
}

// Segments are checked relative to the scanned root so a root that is itself
// named like an excluded segment (for example "samples") is still scanned.
function isExcluded(path, root) {
  return toPosix(relative(root, path))
    .toLowerCase()
    .split('/')
    .some(segment => excludedSegments.has(segment));
}

function collectReadmes(directory, root = directory, files = []) {
  if (!existsSync(directory) || isExcluded(directory, root)) return files;

  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (isExcluded(path, root)) continue;
    if (entry.isDirectory()) collectReadmes(path, root, files);
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
  if (data.interactiveKind !== undefined && !allowedInteractiveKinds.has(data.interactiveKind)) {
    add('interactiveKind', `must be one of: ${[...allowedInteractiveKinds].join(', ')}`);
  }
  if (data.interactiveKind !== undefined && data.format !== 'interactive') {
    add('interactiveKind', 'is only allowed when format is interactive');
  }
  if (data.preview !== undefined) {
    if (!isNonEmptyString(data.preview)) add('preview', 'must be a non-empty string');
    else if (/^[a-z]+:\/\//i.test(data.preview) || data.preview.startsWith('/') || data.preview.includes('..') || data.preview.includes('\\')) {
      add('preview', 'must be a relative path inside the resource folder (no URL, absolute path, "..", or backslash)');
    } else if (!existsSync(join(dirname(file), data.preview))) {
      add('preview', 'points to a file that does not exist');
    }
  }
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
  const preview = data.preview
    ? toPosix(relative(repositoryRoot, join(dirname(file), data.preview)))
    : undefined;
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
    interactiveKind: data.interactiveKind,
    preview,
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

const seenSlugs = new Map();
for (const resource of resources) {
  const first = seenSlugs.get(resource.slug);
  if (first) {
    errors.push({ file: join(repositoryRoot, resource.source), field: 'title', message: `produces the slug "${resource.slug}", which is already used by ${first}` });
  } else {
    seenSlugs.set(resource.slug, resource.source);
  }
}

const siteConfigPath = join(toolDirectory, 'site-config.json');
let siteConfig = { spotlight: undefined, collections: [] };

// The spotlight and "Start here" collections are editorial config. Validating
// them here keeps the landing page from ever pointing at a missing or archived resource.
function validateSiteConfig(config) {
  const problems = [];
  const bySlug = new Map(resources.map(resource => [resource.slug, resource]));
  const add = message => problems.push({ file: siteConfigPath, field: 'site-config', message });
  const checkSlug = (slug, where) => {
    const resource = bySlug.get(slug);
    if (!resource) add(`${where} references unknown slug "${slug}"`);
    else if (resource.status === 'archived') add(`${where} references archived resource "${slug}"`);
  };

  const spotlight = config.spotlight;
  if (spotlight !== undefined) {
    for (const field of ['eyebrow', 'title', 'description', 'primary']) {
      if (!isNonEmptyString(spotlight[field])) add(`spotlight.${field} must be a non-empty string`);
    }
    if (isNonEmptyString(spotlight.primary)) checkSlug(spotlight.primary, 'spotlight.primary');
    if (!Array.isArray(spotlight.secondary) || spotlight.secondary.length === 0) add('spotlight.secondary must list at least one slug');
    else spotlight.secondary.forEach(slug => checkSlug(slug, 'spotlight.secondary'));
  }

  const ids = new Set();
  if (!Array.isArray(config.collections)) add('collections must be a list');
  for (const collection of Array.isArray(config.collections) ? config.collections : []) {
    const where = `collection "${collection.id}"`;
    if (!isNonEmptyString(collection.id) || !kebabPattern.test(collection.id)) add(`${where} needs a kebab-case id`);
    if (ids.has(collection.id)) add(`${where} is defined more than once`);
    ids.add(collection.id);
    if (!isNonEmptyString(collection.title)) add(`${where} needs a title`);
    if (!isNonEmptyString(collection.description)) add(`${where} needs a description`);
    else if ([...collection.description].length > 90) add(`${where} description must be 90 characters or fewer`);
    if (!isStringList(collection.slugs)) add(`${where} needs a non-empty slugs list`);
    else {
      if (new Set(collection.slugs).size !== collection.slugs.length) add(`${where} lists a slug more than once`);
      collection.slugs.forEach(slug => checkSlug(slug, where));
    }
  }
  return problems;
}

if (errors.length === 0) {
  try {
    siteConfig = JSON.parse(readFileSync(siteConfigPath, 'utf8'));
    errors.push(...validateSiteConfig(siteConfig));
  } catch (error) {
    errors.push({ file: siteConfigPath, field: 'site-config', message: `could not be read: ${error.message}` });
  }
}

function writeSiteOutputs(sortedResources, collections) {
  const pagesDirectory = join(repositoryRoot, 'r');
  rmSync(pagesDirectory, { recursive: true, force: true });
  for (const resource of sortedResources) {
    const directory = join(pagesDirectory, resource.slug);
    mkdirSync(directory, { recursive: true });
    writeFileSync(join(directory, 'index.html'), renderResourcePage(resource, { resources: sortedResources, collections, repositoryRoot }));
  }
  writeFileSync(join(repositoryRoot, 'sitemap.xml'), renderSitemap(sortedResources));
  writeFileSync(join(repositoryRoot, 'feed.xml'), renderFeed(sortedResources));
}

if (errors.length > 0) {
  console.error(`Catalog validation failed with ${errors.length} error${errors.length === 1 ? '' : 's'}:`);
  for (const error of errors) {
    console.error(`- ${toPosix(relative(repositoryRoot, error.file))}: ${error.field} ${error.message}`);
  }
  process.exitCode = 1;
} else if (checkOnly) {
  // Rendering every page in memory proves the templates cope with all current metadata.
  for (const resource of resources) {
    renderResourcePage(resource, { resources, collections: siteConfig.collections, repositoryRoot });
  }
  console.log(`Catalog metadata is valid for ${resources.length} resources.`);
} else {
  resources.sort((a, b) => a.title.localeCompare(b.title));
  for (const resource of resources) resource.permalink = resourcePath(resource);
  const latestUpdated = resources.reduce((max, resource) => (
    resource.updated && resource.updated > max ? resource.updated : max
  ), '');
  const catalog = {
    generatedAt: latestUpdated,
    count: resources.length,
    spotlight: siteConfig.spotlight,
    collections: siteConfig.collections,
    resources
  };
  writeFileSync(join(repositoryRoot, 'catalog.json'), `${JSON.stringify(catalog, null, 2)}\n`);
  writeSiteOutputs(resources, siteConfig.collections);
  console.log(`Wrote catalog.json, sitemap.xml, feed.xml, and ${resources.length} pages under r/.`);
}


