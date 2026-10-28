# Catalog build

This package generates the static FastTrack catalog from YAML front matter in resource Markdown files.

## Commands

From this directory:

```powershell
npm ci
npm run check
npm run build
```

- `npm run check` scans and validates metadata without writing files, renders every resource page in memory, and runs the unit tests. It exits non-zero and lists every file and invalid field when validation fails.
- `npm run build` validates, then writes `catalog.json`, `sitemap.xml`, `feed.xml`, and a shareable page for each resource under `r/` at the repository root. These are generated; do not edit them by hand.
- `npm run og` renders branded social cards (`assets/og/<slug>.png`) for new resources with a local Edge or Chrome. Use `npm run og -- --all` to re-render every card. Cards are committed, so CI does not need a browser.
- `npm run collect:traffic` collects a GitHub traffic snapshot into `traffic-data/`. See [`traffic-data/README.md`](../../traffic-data/README.md).

The scanner covers `scripts`, `samples`, `tools/SimpleGraph`, the supported Copilot agent roots (including `ESS`), `copilot-agent-strategy`, `copilot-analytics-samples`, and top-level prompt Markdown files. It excludes `archive`, `_SAMPLE_Templates`, and `node_modules` paths. Legacy Markdown without front matter is ignored.

See [`docs/CATALOG-METADATA.md`](../../docs/CATALOG-METADATA.md) for the schema and contribution guidance.
