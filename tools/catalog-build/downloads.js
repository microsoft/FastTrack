// Decides which single file a visitor can download for a resource, and how to present it.
// A resource gets a Download button only when the file is self-sufficient: the page, deck,
// report, or script that stands on its own. Anything else links to the folder on GitHub.
import { existsSync, readdirSync, statSync } from 'node:fs';
import { basename, join } from 'node:path';

// A script that ships next to a module, a data file, or a template needs those files too,
// so downloading the script alone would not run. Authors can still name a file with `download`.
const SUPPORT_EXTENSIONS = ['.ps1', '.psm1', '.psd1', '.json', '.csv', '.xlsx', '.html', '.xml', '.txt', '.config', '.yml', '.yaml'];

function topLevelFiles(directory) {
  return readdirSync(directory).filter(name => statSync(join(directory, name)).isFile());
}

function uniqueWithExtension(files, extension) {
  const matches = files.filter(name => name.toLowerCase().endsWith(extension));
  return matches.length === 1 ? matches[0] : '';
}

// Returns the file name relative to the resource folder, or '' when there is no obvious single file.
export function findDownloadFile(directory, format, explicit) {
  if (explicit) return explicit;
  const files = topLevelFiles(directory);
  if (format === 'interactive') return files.includes('index.html') ? 'index.html' : '';
  if (format === 'pptx') return uniqueWithExtension(files, '.pptx');
  if (format === 'pbix') return uniqueWithExtension(files, '.pbix');
  if (format === 'ps1') {
    const script = uniqueWithExtension(files, '.ps1');
    if (!script) return '';
    const support = files.filter(name => name !== script && SUPPORT_EXTENSIONS.includes(name.slice(name.lastIndexOf('.')).toLowerCase()));
    return support.length ? '' : script;
  }
  return '';
}

// Every interactive page is called index.html, so name the saved file after the resource.
export function downloadName(slug, file) {
  const name = basename(file);
  return name.toLowerCase() === 'index.html' ? `${slug}.html` : name;
}

export function formatBytes(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) return '';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function fileExists(directory, file) {
  const path = join(directory, file);
  return existsSync(path) && statSync(path).isFile();
}
