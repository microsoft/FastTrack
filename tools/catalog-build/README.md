# Catalog build

This package generates the static FastTrack catalog from YAML front matter in resource Markdown files.

## Commands

From this directory:

```powershell
npm ci
npm run check
npm run build
```

- `npm run check` scans and validates metadata without writing files. It exits non-zero and lists every file and invalid field when validation fails.
- `npm run build` validates, then writes `catalog.json` at the repository root and mirrors the same file to `design-concepts/catalog.json`. The mirror lets the catalog page fetch `catalog.json` when `design-concepts` is served as the web root.

The scanner covers `scripts`, the supported Copilot agent roots, `copilot-agent-strategy`, `copilot-analytics-samples`, and top-level prompt Markdown files. It excludes `archive`, `_SAMPLE_Templates`, and `samples` paths. Legacy Markdown without front matter is ignored.

See [`docs/CATALOG-METADATA.md`](../../docs/CATALOG-METADATA.md) for the schema and contribution guidance.
