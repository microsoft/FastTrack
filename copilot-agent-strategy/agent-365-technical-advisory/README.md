---
title: "Microsoft Agent 365 Technical Advisory"
type: strategy
category: "Interactive"
summary: "Reference architecture and best practices to discover, govern, secure, build, and measure agents with Agent 365, as a 19-page PDF."
author:
  - "Carlos Suarez"
  - "Alejandro Lopez"
version: 1.0.0
published: 2026-10-28
updated: 2026-10-28
tags:
  - agent-365
  - architecture
  - governance
  - security
  - identity
format: interactive
interactiveKind: guide
preview: preview.webp
featured: true
status: active
whatItIs: >-
  A 19-page technical advisory for architects, identity, security, developer, and business leaders.
  It lays out an enterprise reference architecture and best practices for discovering, governing,
  securing, building, and measuring AI agents with Microsoft Agent 365, with 75 cited Microsoft
  Learn and Microsoft sources. This page wraps the PDF in a viewer so you can jump to any page.
whyUseIt:
  - "See how every onboarding route converges on one governed inventory across Microsoft Entra, Purview, and Defender."
  - "Design agent identity, accountability, and lifecycle: blueprints per workload and environment, sponsors and owners, and retirement."
  - "Compare four agent types (Agent Builder, Copilot Studio, Microsoft Foundry, and custom pro-code) across identity, access, risk, and operations."
  - "Follow a phased configuration blueprint, an operating model with RACI and cadence, and the analytics that show usage, adoption, and impact."
howToUse: |-
  1. Open `index.html` in a modern browser, or use the hosted copy from the catalog.
  2. Use the Contents list to jump to a page, and copy a link to share a specific page.
  3. Download the PDF to read it offline or share it. If your browser cannot show PDFs inline, the page offers the download instead.
  4. Treat it as guidance: confirm product availability, licensing, roles, and preview or Frontier status in your tenant before making production changes.
prerequisites:
  - "Modern web browser or PDF reader"
  - "Current Microsoft Learn documentation to validate preview and Frontier capabilities for your tenant"
---

# Microsoft Agent 365 Technical Advisory

Enterprise reference architecture and best practices for Microsoft Agent 365, for architects, identity, security, developer, and business leaders. The advisory is a 19-page PDF with a viewer page that lets you jump to any page and copy a link to it.

Open [`index.html`](index.html) in a modern browser to read it, or open the PDF directly: [`Agent-365-Technical-Advisory.pdf`](Agent-365-Technical-Advisory.pdf).

## What it covers

The advisory is organized into five themes:

- **Orient.** The advisory map, the enterprise reference architecture, and how agents are discovered.
- **Govern and secure.** Agent identity architecture and lifecycle, authentication, authorization and MCP governance, risk, observability and human oversight, and blast-radius control.
- **Agent types and build.** How identity, access, risk, and operations differ across four agent types, and a developer guide for bringing pro-code agents into Agent 365.
- **Configure and operate.** The Agent 365 control plane, a phased configuration blueprint, least-privilege setup for connected platforms, and an operating model with roles, RACI, and cadence.
- **Measure and learn.** Usage, adoption, and impact analytics, case studies and lessons learned, references, and a change log.

## Current version

Version `v20260930`. The change log on the last page of the PDF lists what changed in each version, who updated it, and whose feedback shaped it.

## Companion resources

- [Agent 365 Customer Implementation Guide](../agent-365-customer-implementation-guide/): step-by-step portal paths and validation for the configuration the advisory recommends.
- [Agent 365 Enablement Checklist](../agent-365-enablement-checklist/): plan and track the rollout, with go-live readiness.
- [Agents Cost Calculator](../copilot-agents-cost-tool/): estimate agent consumption and licensing costs.

This advisory replaces the [Agent 365 Lifecycle Atlas](../agent-365-lifecycle-atlas/), which is archived and kept at its original address so existing links keep working.

## Disclaimer

This is a community resource, provided as is. It is not official Microsoft documentation and is based on Microsoft Learn. Preview and Frontier capabilities may change, so validate product availability, licensing, roles, and portal behavior in your tenant before making production changes.

## Authors

|Author|Original Publish Date
|----|--------------------------
|Carlos Suarez and Alejandro Lopez, Microsoft|October 28th, 2026|

Contributor: Victor Adeyanju.

## Issues

Please [report problems or suggest updates](https://github.com/microsoft/FastTrack/issues/new?template=resource-feedback.yml&resource=Microsoft%20Agent%20365%20Technical%20Advisory) with the resource feedback form.
