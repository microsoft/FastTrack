# Change Log

This repository is updated continuously. For the authoritative, up-to-date record of changes, see the [commit history](https://github.com/microsoft/FastTrack/commits/master). To follow new and updated resources, subscribe to the [Atom feed](https://microsoft.github.io/FastTrack/feed.xml).

This file captures only selected high-level milestones.

## History

### October 2026

#### New resources

* Added the Agent 365 Enablement Checklist, a sample Agent 365 deployment plan in one HTML file, and a check that fails when a FastTrack link in a resource page or README no longer resolves.
* Added a check that every guide reference in the Agent 365 Enablement Checklist still resolves in the Customer Implementation Guide, and a weekly workflow that reports broken or moved Microsoft Learn links and Learn pages that changed since either file was last reviewed.
* Added deep links to the Agent 365 Customer Implementation Guide (`#advanced/<step>`). Each Enablement Checklist task now opens its exact guide step, and a check fails the pull request when a cited guide step changes without a review of the checklist tasks that depend on it.
* Added the Microsoft Agent 365 Technical Advisory, a 19-page reference architecture and best-practices PDF with a page-by-page viewer. It replaces the Agent 365 Lifecycle Atlas, which is archived and stays at its address so existing links keep working.

#### Catalog and site

* Added a shareable page for every resource (`r/<slug>/`) with link previews, plus `sitemap.xml` and an Atom `feed.xml`.
* The Build catalog workflow no longer tries to push to `master` or open pull requests when the repository blocks it. It reports which generated files are out of date in its run summary instead, and `tools/catalog-build/README.md` now describes how to publish them. It warns only when the catalog itself changed; a stats-only difference, which happens on every run, is a notice.
* Added a shareable page for every resource; archived resources are now hidden by default; added an Agent 365 highlight row (driven by the `agent-365` tag) and "New" badges to the landing page.
* Cataloged 23 previously unlisted scripts, snippets, and samples (Viva Engage administration, Teams Phone and Rooms, SimpleGraph, ESS extensions) and archived scripts that depend on retired modules or services.
* Archived the prompt samples and removed a 41 MB archived demo video.
* The daily **Collect Traffic Data** workflow no longer collects GitHub repository traffic (views, clones, referrers), which needs a token that expires every few days under organization policy. It skips that step with a notice and keeps collecting Clarity page analytics and discussion votes. Set the repository variable `COLLECT_GITHUB_TRAFFIC` to `true` and replace `TRAFFIC_TOKEN` to resume.

### April 20, 2018

#### New Samples

* Added create team sample showing SharePoint Framework field customizer, PnPjs, React, Graph, and TypeScript
