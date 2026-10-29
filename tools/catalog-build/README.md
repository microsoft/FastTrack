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

## Agent 365 guide and checklist

The [Enablement Checklist](../../copilot-agent-strategy/agent-365-enablement-checklist/) names the section or step of the [Customer Implementation Guide](../../copilot-agent-strategy/agent-365-customer-implementation-guide/) behind most of its tasks (for example `04 Microsoft Purview, 4.04a`). Two checks keep the pair accurate. Neither one edits content.

- **On every pull request** (`npm run check:agent365`, part of `npm run check`): every guide reference in the checklist must resolve to a section or step that exists in the guide. Renumbering or removing a guide step, or mistyping a reference, fails the check and names the checklist tasks affected. It also lists guide steps that no checklist task points at, for information.
- **Every Monday** (`.github/workflows/agent365-freshness.yml`): reads both files, checks every Microsoft Learn link they cite, and opens or updates one issue labeled `agent-365-freshness` when something needs a look. It reports broken links, links that moved (with the new address), Learn pages that changed after each file was last reviewed, a review older than 30 days, and a guide that is newer than the checklist review. The issue closes itself when everything is clear.

Run the report on demand with `npm run freshness:agent365` (add `-- --offline` to skip the Learn requests), or start the workflow from the Actions tab.

Each file records its last review in one place, and the next run measures from that date:

| File | Review date |
| --- | --- |
| Checklist | `CONTENT_REVIEWED` in `index.html` |
| Guide | `updated` in its README front matter |

Set these only after you have actually reviewed the content. Bumping the guide's `updated` date without a review clears its Learn changes from the report.
