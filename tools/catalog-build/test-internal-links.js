import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// Fails when a resource page or README links to a FastTrack path that does not exist in
// this repository. Companion resources (for example the Agent 365 guide and checklist)
// link to each other by URL, so a rename or removal must not silently break the pair.
//
// Checked link shapes:
//   https://microsoft.github.io/FastTrack/<path>
//   https://github.com/microsoft/FastTrack/(tree|blob)/master/<path>
// A target is valid when the file exists, or the folder exists (and, for the site URLs,
// contains an index.html because GitHub Pages serves folders through it).

const toolDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(toolDirectory, '..', '..');

const skippedDirectories = new Set(['.git', 'node_modules', 'archive', 'traffic-data', 'r', 'assets', '_SAMPLE_Templates']);
const scannedExtensions = new Set(['.html', '.md']);
const sitePattern = /https:\/\/microsoft\.github\.io\/FastTrack\/([^"'<>\s)\]`\\#?&]*)/g;
const repoPattern = /https:\/\/github\.com\/microsoft\/FastTrack\/(?:tree|blob)\/master\/([^"'<>\s)\]`\\#?&]*)/g;
const skippedFiles = new Set(['TEMPLATE-README.md']); // contains placeholder links
const generatedSitePaths = new Set(['feed.xml', 'sitemap.xml']);

function collectFiles(directory, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!skippedDirectories.has(entry.name)) collectFiles(join(directory, entry.name), files);
    } else if (!skippedFiles.has(entry.name)) {
      const extension = entry.name.slice(entry.name.lastIndexOf('.')).toLowerCase();
      if (scannedExtensions.has(extension)) files.push(join(directory, entry.name));
    }
  }
  return files;
}

function clean(value) {
  let path;
  try {
    path = decodeURIComponent(value);
  } catch {
    path = value;
  }
  return path.replace(/[.,;:]+$/, '').replace(/\/+$/, '');
}

function siteTargetExists(path) {
  if (path === '' || generatedSitePaths.has(path)) return true;
  const absolute = join(repositoryRoot, ...path.split('/'));
  if (!existsSync(absolute)) return false;
  return statSync(absolute).isDirectory() ? existsSync(join(absolute, 'index.html')) : true;
}

function repoTargetExists(path) {
  return path === '' || existsSync(join(repositoryRoot, ...path.split('/')));
}

const broken = [];
for (const file of collectFiles(repositoryRoot)) {
  const lines = readFileSync(file, 'utf8').split(/\r?\n/);
  lines.forEach((line, index) => {
    for (const [pattern, exists, kind] of [[sitePattern, siteTargetExists, 'site'], [repoPattern, repoTargetExists, 'repo']]) {
      for (const match of line.matchAll(pattern)) {
        const path = clean(match[1]);
        if (!exists(path)) {
          broken.push(`${relative(repositoryRoot, file).split(sep).join('/')}:${index + 1} ${kind} link to "${path}" does not exist`);
        }
      }
    }
  });
}

if (broken.length > 0) {
  console.error(`Found ${broken.length} broken internal link${broken.length === 1 ? '' : 's'}:`);
  for (const message of broken) console.error(`- ${message}`);
  process.exitCode = 1;
} else {
  console.log('Internal FastTrack links all resolve.');
}
