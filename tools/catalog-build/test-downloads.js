import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { downloadName, fileExists, findDownloadFile, formatBytes } from './downloads.js';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const roots = [];
function folder(files) {
  const directory = mkdtempSync(join(tmpdir(), 'fasttrack-download-'));
  roots.push(directory);
  for (const file of files) {
    if (file.endsWith('/')) mkdirSync(join(directory, file));
    else writeFileSync(join(directory, file), 'x');
  }
  return directory;
}

try {
  assert(findDownloadFile(folder(['README.md', 'index.html']), 'interactive', '') === 'index.html', 'An interactive resource must offer its index.html.');
  assert(findDownloadFile(folder(['README.md']), 'interactive', '') === '', 'An interactive resource without index.html has nothing to download.');

  assert(findDownloadFile(folder(['README.md', 'Deck.pptx', 'Images/']), 'pptx', '') === 'Deck.pptx', 'A single .pptx must be offered.');
  assert(findDownloadFile(folder(['README.md', 'A.pptx', 'B.pptx']), 'pptx', '') === '', 'Two decks are ambiguous, so none is offered.');
  assert(findDownloadFile(folder(['README.md', 'Report.pbix', 'Export.ps1']), 'pbix', '') === 'Report.pbix', 'A report must offer its .pbix even with helper scripts.');

  assert(findDownloadFile(folder(['README.md', 'Do-It.ps1', 'screenshot.png', 'GUIDE.docx']), 'ps1', '') === 'Do-It.ps1', 'A lone script with only images and documents next to it must be offered.');
  assert(findDownloadFile(folder(['README.md', 'Do-It.ps1', 'Helpers.psm1']), 'ps1', '') === '', 'A script that ships with a module must not be offered alone.');
  assert(findDownloadFile(folder(['README.md', 'Do-It.ps1', 'sample.csv']), 'ps1', '') === '', 'A script that ships with a data file must not be offered alone.');
  assert(findDownloadFile(folder(['README.md', 'Do-It.ps1', 'communities.json']), 'ps1', '') === '', 'A script that ships with a template must not be offered alone.');
  assert(findDownloadFile(folder(['README.md', 'A.ps1', 'B.ps1']), 'ps1', '') === '', 'Two scripts are ambiguous, so none is offered.');
  assert(findDownloadFile(folder(['README.md', '.gitignore', 'Do-It.ps1']), 'ps1', '') === 'Do-It.ps1', 'Dotfiles must not count as support files.');

  assert(findDownloadFile(folder(['README.md', 'agent.json']), 'declarative', '') === '', 'Declarative agents have no single file.');
  assert(findDownloadFile(folder(['README.md']), 'md', '') === '', 'Markdown resources have no download.');
  assert(findDownloadFile(folder(['README.md', 'A.ps1', 'B.ps1']), 'ps1', 'B.ps1') === 'B.ps1', 'An explicit download must win.');

  const directory = folder(['README.md', 'a.txt']);
  assert(fileExists(directory, 'a.txt') && !fileExists(directory, 'missing.txt') && !fileExists(directory, '.'), 'fileExists must accept only regular files.');
} finally {
  for (const directory of roots) rmSync(directory, { recursive: true, force: true });
}

assert(downloadName('my-guide', 'a/b/index.html') === 'my-guide.html', 'An index.html download must be named after the resource.');
assert(downloadName('my-guide', 'a/b/Index.HTML') === 'my-guide.html', 'The index.html rule must ignore case.');
assert(downloadName('my-guide', 'a/Deck With Spaces.pptx') === 'Deck With Spaces.pptx', 'Other files keep their own name.');
assert(formatBytes(0) === '' && formatBytes(undefined) === '', 'No size means no label.');
assert(formatBytes(500) === '500 B' && formatBytes(2048) === '2 KB' && formatBytes(100) === '100 B', 'Small sizes must use B and KB.');
assert(formatBytes(1) === '1 B' && formatBytes(1100) === '1 KB' && formatBytes(836668) === '817 KB', 'Sizes must round to whole kilobytes.');
assert(formatBytes(2374553) === '2.3 MB', 'Large sizes must use MB with one decimal.');

console.log('Download file selection and naming are valid.');
