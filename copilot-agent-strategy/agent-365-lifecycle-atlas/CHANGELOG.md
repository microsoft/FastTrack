# Changelog

All notable changes to the Agent 365 Lifecycle Atlas are documented here.

## 1.3.0 - 2026-09-22

- Corrected `a365 setup all` runtime-configuration synchronization: it depends on
  detecting a supported project (with a configuration-file-directory fallback),
  not on a project-path flag alone, so the config-free path can still write
  configuration and only `--agent-registration-only` deliberately skips it.
- Scoped the setup sequence diagram, heading, and accessible description to the
  default standard-agent, non-AI-teammate path, and clarified that `--aiteammate`
  provisions only the blueprint and permissions during setup.
- Clarified language-specific generated defaults: .NET `TokenValidation.Enabled =
  false` and `EnableAgent365Exporter ??= false` (explicit values preserved);
  Node.js/Python `ENABLE_A365_OBSERVABILITY_EXPORTER=false`. Noted that written
  configuration does not prove the SDK, token validation, or exporter is active.
- Corrected observability identity binding so `gen_ai.agent.id` equals the agent's
  authenticated `appId` / OAuth `client_id`, never the Entra object or blueprint
  ID, and added per-request identity resolution for shared multi-instance hosts.
- Added a "What changes in my code?" runtime-integration architecture diagram and
  illustrative code-area table describing customer-hosted integration boundaries.
- Labeled the package lifecycle specifically as Microsoft 365 package distribution.
- Corrections grounded in public Microsoft Learn and the pinned public
  `microsoft/Agent365-devTools` source reviewed on September 22, 2026.

## 1.2.3 - 2026-09-16

- Aligned connected-platform registry sync labels with the public Microsoft
  Learn integration-options guidance, which documents registry sync as Preview.
- Replaced the longer status-conflict note with a concise citation while
  preserving the existing capability and hosting boundaries.

## 1.2.2 - 2026-09-16

- Improved the visibility of the connected-platform and registry synchronization
  status-note badges with larger bold text and a dedicated row, without changing
  their wording or status meaning.

## 1.2.1 - 2026-09-16

- Fixed overlapping sticky headers in horizontally scrollable atlas tables
  while preserving the page-level table header offset.

## 1.2.0 - 2026-09-16

- Added an SDK-adjacent section and sequence diagram for the seven stages behind
  `a365 setup all`.
- Documented blueprint, child identity, credential, permission, grant, and
  programmatic registration relationships.
- Clarified application ID, object ID, and Agent 365 identity mappings,
  including the current CLI's child service-principal object ID behavior.
- Added representative Microsoft Graph operations, conditional project-path
  synchronization behavior, production checks, and recovery guidance.
- Clarified that setup neither deploys hosted agent code nor installs an SDK,
  and that host deployment is separate from ZIP publishing and administrator
  availability-instance creation.
- Expanded the public bibliography from 31 to 36 sources, including pinned
  public CLI implementation references reviewed on September 16, 2026, without
  treating that source version as a universal installed-binary guarantee.

## 1.1.1 - 2026-09-16

- Reconciled conflicting public documentation for connected-platform and
  registry synchronization status and capabilities.
- Corrected Entra blueprint deletion cascade behavior and the Agentic User
  on-behalf-of token flow.
- Clarified custom MCP server publishing and tenant administrator approval.
- Corrected conversation and run terminology, Agent Map limits and licensing,
  and the documented scope of Shadow AI discovery.
- Expanded the public bibliography from 25 to 31 sources and marked unresolved
  source conflicts inline.

## 1.1.0 - 2026-09-15

- Expanded the whole-system map with connected-platform registry ingestion,
  Agent Map inventory, and a separate Shadow AI governance lane.
- Added two discovery and inventory diagrams, bringing the atlas to eleven.
- Clarified that connected-platform synchronization is currently manual and
  metadata-only, with scheduled synchronization listed as a future release.
- Added documented external platform categories and examples.
- Preserved the existing 18-endpoint catalog and linked public Learn sources.

## 1.0.0 - 2026-09-10

- Published the initial public interactive atlas.
- Added nine architecture and sequence diagrams.
- Added searchable coverage of 18 representative Agent 365 API endpoints.
- Linked every factual section to canonical public Microsoft Learn sources.
