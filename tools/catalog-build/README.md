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

After the pull request merges, Pages redeploys on its own. The **Build catalog** run on `master` then rebuilds and checks the generated files. The repository blocks GitHub Actions from pushing to `master` or opening pull requests, so the run does not try. If it reports **Generated files are out of date** in its summary, run the commands above on an up-to-date checkout and open a pull request with the result. That warning only covers the catalog itself (`catalog.json`, `sitemap.xml`, `feed.xml`, and `r/`). Resource stats are stamped with the time they are rendered and are published by the weekly traffic pull request, so a stats-only difference shows as a notice, not a warning.

Daily traffic collection and the weekly traffic pull request are separate. See [`traffic-data/README.md`](../../traffic-data/README.md).

## Agent 365 guide and checklist

The [Enablement Checklist](../../copilot-agent-strategy/agent-365-enablement-checklist/) names the step of the [Customer Implementation Guide](../../copilot-agent-strategy/agent-365-customer-implementation-guide/) behind most of its tasks (for example `04 Microsoft Purview, 4.04a`), and each task links to that step. The two files change independently, so these checks keep them aligned. None of them edits content.

**How the links work.** The guide opens `index.html#advanced/<key>` in its Detailed view, scrolls to the step, and highlights it. The key is a step code in lowercase (`4.04a`, `12b`, `pp3`, and `5-0` for step 5·0) or a section number (`04`, or `pp`). The checklist's `guideHref()` builds the address from the first step code in a task's guide reference, or from its section when the reference has no code. The guide builds its list of keys from its own headings, so a new step is linkable as soon as it has a code heading.

**On every pull request** (`npm run check:agent365`, part of `npm run check`):

- Every guide reference in the checklist must name a section or step that exists in the guide, and every reference must include a step code or be section-only. A reference with only a description cannot be linked or verified, and matching one loosely picked the wrong step once.
- The checklist's `guideHref()` must build the address this check expects for every reference, and the guide must offer that address.
- The guide must carry the deep-link script exactly as `guide-deeplinks.js` writes it. If the guide is regenerated without it, run `npm run patch:guide` and commit the result. The patch is repeatable, and it fails loudly if the guide's structure changed enough that it no longer applies.
- Every guide step and section that the checklist cites must be unchanged since the checklist was last aligned with it. `agent365-sync-state.json` records a fingerprint of each one (its text and links). When you edit a cited step, the check fails and names the checklist tasks that depend on it. Review those tasks against the guide, update whichever is out of date, then run `npm run sync:agent365` and commit the updated state file. The pull request template has a matching checkbox.

It also lists guide steps that no checklist task points at, for information.

**Every Monday** (`.github/workflows/agent365-freshness.yml`):

- Reads both files, checks every Microsoft Learn link they cite, and opens or updates one issue labeled `agent-365-freshness` when something needs a look. It reports broken links, links that moved (with the new address), Learn pages that changed after each file was last reviewed, a review older than 30 days, and a guide that is newer than the checklist review. The issue closes itself when everything is clear.
- A second job opens every address the checklist links to in a real headless browser and checks that the guide finds each step (`npm run test:guide-deeplinks`). Run it locally the same way; it skips if no Edge or Chrome is installed unless you pass `-- --require-browser`.

Run the report on demand with `npm run freshness:agent365` (add `-- --offline` to skip the Learn requests), or start the workflow from the Actions tab.

**Review dates.** Each file records its last review in one place, and the next report measures from that date:

| File | Review date | Update it with |
| --- | --- | --- |
| Checklist | `CONTENT_REVIEWED` in `index.html` | Edit the value |
| Guide | `reviewed.guide` in `agent365-sync-state.json` | `npm run sync:agent365 -- --guide-reviewed` |

Set these only after you have actually reviewed the content against Microsoft Learn. The guide's README `updated` date is separate on purpose, because it also moves for changes that are not a content review.

**If the guide or checklist is regenerated elsewhere**, carry two things over: the deep-link patch (`npm run patch:guide` applies it to the regenerated guide) and, in the checklist, the `guideHref()` function and the explicit step codes in its guide references. `npm run check` fails until both are back.
