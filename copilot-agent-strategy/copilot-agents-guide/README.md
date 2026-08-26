---
title: Copilot Agents Guide
type: strategy
category: Interactive
summary: >-
  Compare Microsoft Copilot agent approaches, availability, licensing, FastTrack scope, and common
  scenarios.
author: Microsoft FastTrack
version: 4.0.0
published: "2025-10-28"
updated: "2026-08-21"
tags:
  - guide
  - decision
  - planning
format: interactive
featured: true
whatItIs: >-
  A self-contained interactive guide to Microsoft-built agent experiences, Agents in SharePoint,
  Agent Builder, Copilot Studio harnesses, Microsoft 365 Agents Toolkit, and Microsoft Agent 365.
whyUseIt:
  - Shortlist an agent approach based on the work, audience, skills, governance, and delivery model.
  - Separate generally available capabilities from Frontier and public preview experiences.
  - Review current licensing considerations and the published FastTrack service boundary.
howToUse: >-
  Open `index.html` in a modern browser. Use the Strategy view first, then compare the Overview,
  Guidance, Capabilities, Comparison, Labs, and Message Center tabs.
prerequisites:
  - Modern web browser
---

# Microsoft Copilot Agents Guide

This interactive guide helps business, architecture, IT, and development teams choose a Microsoft
Copilot agent approach without treating every product, authoring tool, runtime, or governance layer
as the same thing.

![Agents Guide preview](./images/Recording%202025-10-28%20170002.gif)

## What changed in version 4.0

- **Copilot Cowork:** Updated from Frontier availability to general availability for work and
  school accounts. The guide now calls out Microsoft 365 Copilot licensing and usage-based billing
  with Copilot Credits.
- **Microsoft-built experiences:** Added current status and guidance for Word, Excel, and PowerPoint
  Agents, Workflows agent, agents in Viva Engage communities, and Microsoft Scout. The Office
  creation-agent guidance calls out the required Anthropic model enablement.
- **Copilot Studio:** Replaced the old "full declarative" and "full custom" framing with the current
  three-harness model: Copilot chat, standard, and GitHub Copilot harnesses.
- **Agent Builder and SharePoint:** Updated knowledge, sharing, pay-as-you-go, creator, and user
  requirements.
- **Microsoft 365 Agents Toolkit:** Updated the supported SDK, TypeSpec, Foundry, Visual Studio,
  Visual Studio Code, CLI, testing, and multi-channel guidance.
- **Microsoft Agent 365:** Updated to its generally available control-plane role for observing,
  governing, and securing agents.
- **FastTrack scope:** Replaced broad "supported" claims with scope-aware remote-guidance wording
  and the current service-description link.
- **Accuracy boundary:** Added official Microsoft links to every decision path and selected
  Microsoft-built experience. Product claims are dated separately from Message Center feed updates.

## Decision paths covered

### 1. Microsoft-built agents and experiences

Selected ready-to-use experiences rather than an exhaustive catalog:

- Researcher
- Analyst
- Copilot Cowork
- Workflows agent
- Agents in Viva Engage communities
- Word, Excel, and PowerPoint Agents
- Microsoft Scout

### 2. Agents in SharePoint

Permission-aware agents grounded in selected SharePoint sites, pages, folders, libraries, and files.

### 3. Agent Builder in Microsoft 365 Copilot

Natural-language and template-based authoring for focused declarative agents in Microsoft Copilot.

### 4. Copilot Studio: Copilot chat harness

Low-code agents that extend Microsoft 365 Copilot Chat with organizational instructions, knowledge,
and tools.

### 5. Copilot Studio: Standard and GitHub Copilot harnesses

- **Standard harness:** Rule-based, predictable conversations.
- **GitHub Copilot harness:** Reasoning-heavy, multi-step processes with skills, memory, files, and
  tool orchestration.

### 6. Microsoft 365 Agents Toolkit

Pro-code tooling for declarative and custom engine agents using Microsoft 365 Agents SDK, Teams SDK,
Microsoft Foundry, TypeSpec, Visual Studio Code, Visual Studio, and CLI workflows.

Microsoft Agent 365 is shown separately because it is a governance and protection control plane,
not an agent-authoring path.

## Views

- **Strategy:** Decision flow, licensing and delivery considerations, scenarios, and governance.
- **Overview:** Description, status, source links, planning metrics, selected experiences, and
  FastTrack boundary.
- **Guidance:** Getting-started steps, practices, and deployment checklist.
- **Capabilities:** Capabilities and constraints for the selected path.
- **Comparison:** Cross-path planning matrix.
- **Labs:** Related Microsoft Copilot Studio labs.
- **Message Center:** Community-mirrored Microsoft 365 Message Center posts filtered by path.

## Accuracy model

The guide separates three kinds of information:

1. **Product facts:** Availability, licensing, capabilities, and FastTrack scope linked to official
   Microsoft guidance and reviewed on **August 21, 2026**.
2. **Planning guidance:** Setup time, scalability, customization, and maintenance ratings are
   directional estimates. They are not Microsoft commitments.
3. **Message Center feed:** Refreshed separately from the core guide. A feed refresh updates only the
   Message Center freshness badge and must not change the core review date.

Preview and Frontier capabilities can change. Check the linked official page before making a
production or licensing decision.

## Run locally

```powershell
Set-Location copilot-agent-strategy\copilot-agents-guide
python -m http.server 8000
```

Then open `http://localhost:8000/index.html`.

## Maintain the Message Center feed

From the repository root:

```powershell
node scripts\update-message-center.js
```

The updater:

- Reads the public `merill/mc` archive.
- Filters recent Copilot and agent-related posts.
- Maps posts to the guide's decision paths.
- Replaces only the embedded Message Center data and freshness badge.

The scheduled workflow is `.github/workflows/update-message-center.yml`.

## Official sources

- [Agents admin guide for Microsoft 365](https://learn.microsoft.com/microsoft-365/copilot/agent-essentials/m365-agents-admin-guide)
- [Copilot Cowork overview](https://learn.microsoft.com/microsoft-365/copilot/cowork/)
- [Agent Builder in Microsoft 365 Copilot](https://learn.microsoft.com/microsoft-365/copilot/extensibility/agent-builder)
- [Get started with agents in SharePoint](https://learn.microsoft.com/sharepoint/get-started-sharepoint-agents)
- [Copilot Studio agents overview](https://learn.microsoft.com/microsoft-copilot-studio/agents-overview)
- [Microsoft 365 Agents Toolkit](https://learn.microsoft.com/microsoftteams/platform/toolkit/overview-agents-toolkit)
- [Microsoft Agent 365 overview](https://learn.microsoft.com/microsoft-agent-365/overview)
- [FastTrack scope for Microsoft Copilot agents](https://learn.microsoft.com/microsoft-365/fasttrack/microsoft-365-copilot#microsoft-copilot-agents)

## Technical details

- React 18
- Tailwind CSS
- Lucide icons
- Babel Standalone for in-browser JSX
- Single HTML application with CDN dependencies
- No backend

## License

This guide is provided as-is for informational and planning purposes. Microsoft, Microsoft 365,
Copilot, and related trademarks are property of Microsoft Corporation.

**Version:** 4.0.0
**Core guidance reviewed:** August 21, 2026
