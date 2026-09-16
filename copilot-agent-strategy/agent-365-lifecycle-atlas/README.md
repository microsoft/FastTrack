---
title: Agent 365 Lifecycle Atlas
type: strategy
category: Interactive
summary: >-
  Explore Agent 365 lifecycles, discovery, identity, tooling, telemetry, admin
  actions, and 18 public API endpoints in one atlas.
author: Alejandro Lopez
version: 1.1.1
published: "2026-09-10"
updated: "2026-09-16"
tags:
  - agent-365
  - architecture
  - governance
  - lifecycle
format: interactive
featured: true
status: active
whatItIs: >-
  A self-contained interactive architecture reference that maps how Microsoft
  Agent 365 discovers, identifies, governs, and observes agents across Microsoft
  and third-party platforms.
whyUseIt:
  - Follow five agent classes through build, connection, identity, packaging, runtime, and governance.
  - Distinguish registry ingestion, Agent Map inventory, and Shadow AI discovery boundaries.
  - Trace Agent 365 identity, token, SDK, CLI, MCP, telemetry, and administration relationships.
  - Search and filter 18 representative public API endpoints with linked Microsoft Learn sources.
howToUse: >-
  Open `index.html` in a modern browser. Use the section navigation and linked
  architecture nodes to move through the atlas, zoom the main diagram, switch
  themes, and filter the endpoint catalog by text or status.
prerequisites:
  - Modern web browser
  - Current Microsoft Learn documentation for implementation validation
---

# Microsoft Agent 365 Lifecycle Atlas

The Agent 365 Lifecycle Atlas is a self-contained, interactive reference for
developers, architects, and administrators. It shows how agents enter the Agent
365 control plane, how identity and token flows work, where agents continue to
run, and which governance and observability interfaces apply at each stage.

## What the atlas covers

- Eleven linked architecture and sequence diagrams
- Five agent classes across six lifecycle stages
- Native onboarding and connected-platform registry ingestion
- Agent Map inventory and the separate Shadow AI discovery experience
- Entra agent identity objects and token exchanges
- Agent 365 SDK and CLI boundaries
- Governed MCP tooling and telemetry flows
- Administration actions and documented deletion behavior
- Eighteen representative API endpoints with public Microsoft Learn sources

The atlas keeps generally available, preview, and beta capabilities visibly
separate. Preview and beta details must be checked against current Microsoft
documentation for the target tenant, cloud, and scenario before implementation.

## September 16, 2026 accuracy update

This correction pass reconciles conflicting public descriptions of connected
platform and registry synchronization status instead of asserting a single
release stage. It also corrects Entra blueprint deletion behavior, the Agentic
User on-behalf-of token chain, custom MCP server publishing and approval,
conversation and run terminology, Agent Map limits and licensing, and the
documented scope of Shadow AI discovery. The bibliography now contains 31
public sources, with unresolved documentation conflicts called out inline.

## September 15, 2026 update

This update adds a discovery and inventory section to the atlas. It distinguishes
native Agent 365 onboarding from connected-platform metadata synchronization,
shows Agent Map as a registry-backed visual inventory, and keeps Shadow AI in a
separate unmanaged-agent governance lane. Connected-platform synchronization is
manual in the currently documented preview; scheduled synchronization is a
future release. The diagrams also identify the documented external platform
categories and their current examples.

## Usage

Open [`index.html`](./index.html) in a modern browser. No server, build process,
sign-in, or external JavaScript dependency is required.

When browsing the hosted FastTrack site, open the
[Agent 365 Lifecycle Atlas](https://microsoft.github.io/FastTrack/copilot-agent-strategy/agent-365-lifecycle-atlas/).

Use the page to:

1. Select a section from the sticky navigation.
2. Select a node in the main architecture map to jump to its detailed view.
3. Use the zoom controls or keyboard shortcuts on the main map.
4. Search the endpoint catalog by function, path, or permission.
5. Filter endpoint rows by generally available, preview, or beta status.

## Sources and scope

The content is compiled from the public Microsoft Learn and Microsoft 365
Roadmap sources linked inside the atlas. The full atlas was accuracy-reviewed on
September 16, 2026. It is an architecture reference, not a deploy-ready
configuration or an official product specification.

## Applies To

- Microsoft Agent 365
- Microsoft Entra agent identities
- Microsoft 365 Copilot agents
- Microsoft Copilot Studio agents
- Microsoft Foundry agents
- Custom and third-party agent runtimes connected to Agent 365

## Author

| Author | Original Publish Date |
| --- | --- |
| Alejandro Lopez | 2026-09-10 |

## Issues

Please report any issues you find to the
[issues list](https://github.com/microsoft/FastTrack/issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source
initiative are provided as-is. These resources are developed in partnership
with the community and do not represent official Microsoft software. As such,
support is not available through premier or other Microsoft support channels.
If you find an issue or have questions please reach out through the issues list
and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the
[Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft
documentation and other content in this repository under the
[MIT License](../../LICENSE), and grant you a license to any code in the
repository under the [MIT License](../../LICENSE-CODE).

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services
referenced in the documentation may be either trademarks or registered
trademarks of Microsoft in the United States and/or other countries. The
licenses for this project do not grant you rights to use any Microsoft names,
logos, or trademarks. Microsoft's general trademark guidelines can be found at
<http://go.microsoft.com/fwlink/?LinkID=254653>.

Privacy information can be found at <https://privacy.microsoft.com/en-us/>.

Microsoft and any contributors reserve all other rights, whether under their
respective copyrights, patents, or trademarks, whether by implication, estoppel
or otherwise.
