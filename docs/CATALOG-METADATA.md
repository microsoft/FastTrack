# Catalog metadata schema

The FastTrack catalog is generated from YAML front matter at the very top of each resource's `README.md`. The catalog build ignores legacy Markdown files without front matter. (The `prompt` type is still accepted by the schema for a single archived sample, but FastTrack is not adding new prompts.)

Use `---` on its own line before and after the YAML. YAML block scalars (`>-` and `|-`) are recommended for readable detail content.

## Copy-paste example

```yaml
---
title: "Get-M365CopilotReadiness"
type: script
category: "PowerShell"
summary: "Assess Microsoft 365 Copilot readiness across identity, licensing, collaboration, and compliance settings."
author:
  - "John Cummings"
version: 1.0.0
published: 2025-08-20
updated: 2025-09-09
tags:
  - copilot
  - readiness
  - governance
format: ps1
featured: true
status: active
whatItIs: >-
  A PowerShell assessment that collects tenant configuration signals and produces
  JSON and HTML reports for Microsoft 365 Copilot deployment planning.
whyUseIt:
  - "Review identity, licensing, Exchange, SharePoint, OneDrive, Teams, and Graph readiness in one run."
  - "Give administrators readable descriptions and actionable context for collected settings."
howToUse: |-
  1. Download the resource and open PowerShell.
  2. Sign in with the read permissions documented in the README.
  3. Run:

     ```powershell
     .\Get-M365CopilotReadiness.ps1 -OutputPath "C:\Temp\M365Readiness"
     ```
prerequisites:
  - "Windows PowerShell 5.1 or PowerShell 7"
  - "Read access to Microsoft Graph, Exchange Online, SharePoint Online, and Teams"
# url: "https://github.com/microsoft/FastTrack/tree/master/scripts/Get-M365CopilotReadiness"
---
```

## Required fields

| Field | Type | Guidance |
| --- | --- | --- |
| `title` | string | Human-readable resource name. It becomes `name` in `catalog.json`. |
| `type` | enum | One of `script`, `agent`, `strategy`, `analytics`, `prompt`, or `skill`. |
| `category` | string | Short sub-label such as `PowerShell`, `Copilot Studio`, `Agent Builder`, `Power BI`, or `Interactive`. |
| `summary` | string | Card description. Must be 140 characters or fewer. |
| `author` | string or string list | Original author(s), substantial co-authors, or `Microsoft FastTrack`. |
| `version` | semver string | `MAJOR.MINOR.PATCH`, for example `1.2.0`. Quote it only if your YAML editor changes its type. |
| `published` | date string | Original publication date in `YYYY-MM-DD` format. Do not change it on updates. |
| `updated` | date string | Most recent resource change in `YYYY-MM-DD` format. The generator can derive it from Git when omitted, but committed metadata should normally be explicit. |

## Recommended fields

| Field | Type | Guidance |
| --- | --- | --- |
| `tags` | string list | Lowercase discovery terms. Prefer a few specific tags over many broad ones. |
| `format` | enum | One of `ps1`, `bundle`, `declarative`, `interactive`, `pptx`, `pbix`, or `md`. This replaces the former `artifact` label. |
| `interactiveKind` | enum | Only for `format: interactive`. Set `guide` for a walkthrough or implementation/decision guide, or `tool` for a calculator or utility. Defaults to `tool`, which the catalog labels "Interactive tool"; `guide` is labeled "Interactive guide". A `guide` is also cross-listed under **Guides & planning** (see below), while a `tool` is not. |
| `preview` | string | Optional relative path (inside the resource folder) to a screenshot the catalog detail page renders above the description, for example `preview.webp`. Use an optimized local image (WebP or PNG). No URLs, absolute paths, `..`, or backslashes. Omit it for resources without a screenshot. |
| `download` | string | Optional relative path (inside the resource folder) of the one file the **Download** button saves, for example `Report.pbix`. No URLs, absolute paths, `..`, or backslashes. Without it, the catalog picks the file itself: `index.html` for `interactive`, the only `.pptx` or `.pbix` in the folder, and the only `.ps1` for `ps1` when the folder has no module, data, or template files next to it. Other resources get no Download button. Archived resources never get one. The button opens the resource's download page (`r/<slug>/download/`), which saves the file and records the download: each load of that page is counted in `resource-stats.json` as `downloads`, and Clarity logs a `resource_download` event. |
| `featured` | boolean | Use sparingly for resources selected for catalog promotion. Default is `false`. |
| `status` | enum | `active`, `preview`, or `archived`. Default is `active`. `archived` resources are hidden from the default catalog view and the sitemap (visitors can reveal them with **Show archived**), and their pages are marked `noindex`. `preview` resources get a Preview badge. |
| `url` | HTTPS URL | Optional GitHub or destination URL. When omitted, the generator derives a GitHub URL from the resource path. |

## Guides & planning cross-listing

The catalog site keeps every resource's `type` exactly as authored, but the root catalog's **Guides & planning** selection is a virtual, cross-topic collection. It lists every `strategy` resource **plus** any interactive guide (`format: interactive` with `interactiveKind: guide`) regardless of that resource's own `type`.

- An interactive guide keeps its own category too. An `analytics` interactive guide appears under both **Analytics** (by its `type`) and **Guides & planning** (as a guide).
- Interactive tools and calculators (`format: interactive` without `interactiveKind: guide`) are **not** cross-listed; they stay only under their own `type`.
- Cross-listing is display-only. It never changes `type`, badges, tags, folders, URLs, the **All** listing, related-resource suggestions, or `catalog.json`. The **Guides & planning** count reflects this same cross-listed set, and each resource still renders as a single card with no duplicates.

Set `interactiveKind: guide` (rather than the default `tool`) when you want a walkthrough or implementation/decision guide to be discoverable under **Guides & planning** in addition to its own category. This is purely a browsing convenience in the site; the metadata schema and generated catalog are unchanged.

## Detail-page content

These fields answer what the resource is, why someone should consider it, and how to use it.

| Field | Type | Guidance |
| --- | --- | --- |
| `whatItIs` | string | A short factual paragraph describing the resource, its output, and scope. |
| `whyUseIt` | string list | Concrete benefits and when-to-use scenarios. Do not make claims that the README or resource cannot support. |
| `howToUse` | multiline Markdown string | Concise install, configuration, and usage steps. Use a `|-` block scalar so lists and fenced code remain readable. |
| `prerequisites` | string list | Optional licenses, permissions, products, runtimes, modules, or inputs needed before use. |

## Versioning and authorship

- Patch releases fix behavior or documentation; minor releases add backward-compatible capability; major releases make breaking changes or substantial rewrites.
- Bump `version` and `updated` for every resource change.
- Preserve the original `published` date.
- Add substantial co-authors to `author`; do not remove the original author.
- Keep a resource-level `CHANGELOG.md` for non-trivial resources.
- Git history is the authoritative audit trail.

## Validation

From the repository root:

```powershell
npm ci --prefix tools\catalog-build
npm run check --prefix tools\catalog-build
```

Validation reports every file and field that must be fixed. The default `npm run build` command writes `catalog.json`, a shareable page per resource under `r/`, `sitemap.xml`, and `feed.xml` at the repository root. Do not edit those generated files by hand.

## Social cards

Each resource page and the landing page use a 1200x630 social card for link previews in Teams, LinkedIn, and similar apps. Cards are committed under `assets/og/<slug>.png`. Render missing ones locally (needs Edge or Chrome) with `npm run og` from `tools/catalog-build`, or re-render all with `npm run og -- --all`. Resources without a card fall back to `assets/og-default.png`.
