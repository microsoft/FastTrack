// Prism highlights every `code[class*=language-]` element on the page once it
// loads unless `Prism.manual` is already set; generated apps render markdown
// code blocks with those classes under React, so Prism must never touch them.
// Imported before `prismjs`, which reads this flag as it starts.
const scope = globalThis as { Prism?: { manual?: boolean } };
scope.Prism = scope.Prism ?? {};
scope.Prism.manual = true;

export {};
