# Catalog build

This package generates the static FastTrack catalog from YAML front matter in resource Markdown files.

## Commands

From this directory:

```powershell
npm ci
npm run check
npm run build
```

- `npm run check` scans and validates metadata without writing files, renders every resource page in memory, verifies that FastTrack links in resource pages and READMEs resolve to real paths (`npm run check:links`), and runs the unit tests. It exits non-zero and lists every file and invalid field when validation fails.
- `npm run build` validates, then writes `catalog.json`, `sitemap.xml`, `feed.xml`, and a shareable page for each resource under `r/` at the repository root. These are generated; do not edit them by hand.
- `npm run og` renders branded social cards (`assets/og/<slug>.png`) for new resources with a local Edge or Chrome. Use `npm run og -- --all` to re-render every card. Cards are committed, so CI does not need a browser.
- `npm run collect:traffic` collects a GitHub traffic snapshot into `traffic-data/`. See [`traffic-data/README.md`](../../traffic-data/README.md).

The scanner covers `scripts`, `samples`, `tools/SimpleGraph`, the supported Copilot agent roots (including `ESS`), `copilot-agent-strategy`, `copilot-analytics-samples`, and top-level prompt Markdown files. It excludes `archive`, `_SAMPLE_Templates`, and `node_modules` paths. Legacy Markdown without front matter is ignored.

See [`docs/CATALOG-METADATA.md`](../../docs/CATALOG-METADATA.md) for the schema and contribution guidance.

## Publishing changes

GitHub Pages serves the generated files that are committed to `master`, so include them in the pull request that changes a resource or `index.html`.

1. From this directory, run `npm run build`.
2. For a new resource, run `npm run og`, then `npm run build` again. Resource pages link to the social card only if it exists when they are built.
3. Commit `catalog.json`, `sitemap.xml`, `feed.xml`, `r/`, and any new `assets/og/` card with your change, and open the pull request.

After the pull request merges, Pages redeploys on its own. The **Build catalog** run on `master` then rebuilds and checks the generated files. The repository blocks GitHub Actions from pushing to `master` or opening pull requests, so the run does not try. If it reports **Generated files are out of date** in its summary, run the commands above on an up-to-date checkout and open a pull request with the result.

Daily traffic collection and the weekly traffic pull request are separate. See [`traffic-data/README.md`](../../traffic-data/README.md).
