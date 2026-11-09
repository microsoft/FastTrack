# Changelog

## 1.0.4 - 2026-11-09

- Rechecked every task that cites a Microsoft Learn page that moved or changed since the 2026-10-22 review, and updated what no longer matched.
- Fixed 22 moved Microsoft Learn links. The Agent 365 admin center, Tools, and registry articles now live under `microsoft-agent-365/admin/`, and the Copilot credits, Copilot plan comparison, Package Management API, and Azure AI Gateway articles have new addresses.
- Frontier: enrolling users in Frontier doesn't need a Copilot license, which is needed only to use Copilot-related Frontier features (Foundations task 13).
- Overview and release preferences: usage metrics for third-party agents start at license activation (Foundations task 12), and the release preference exception limit is 10,000 users, with the unified release preferences experience arriving in November 2026 (Operate & adopt task 6).
- Defender local agent discovery is generally available on Windows and macOS, and Defender lists most agents only after it observes them running, except installed VS Code extensions (Shadow agents tasks 3 and 12).
- Gateway & compute: the AI Gateway tier in API Management is being replaced by the AI Gateway resource type. The tasks now say existing tier resources work until January 15, 2027, and the new resource type doesn't support private endpoints or the content safety policy (Gateway & compute tasks 1, 3, and 10).
- Registry sync (Custom agents task 10) adds Databricks Genie observability and the outbound IP addresses to allow, and the cleanup task (Custom agents task 15) lists the roles it needs.
- Purview: the Copilot DLP location supports administrative units, but support is still rolling out (task 10), and Restricted Content Discovery is a temporary control (task 21).
- Blocking a SharePoint or Foundry agent limits it only in Copilot Chat (Defender task 10 and Operate & adopt task 9), and maker updates to a shared Copilot Studio agent reach users after the maker publishes and a new session starts (Low-code agents task 4).
- Updated link titles that no longer matched their Learn articles. No other task content changed.

## 1.0.3 - 2026-10-30

- The version shown on the Help page, in the printed report, and in exports now matches the catalog version. It showed an internal number (2.9.1) before.
- Fixed a broken Microsoft Learn link on the Gateway & compute task "Configure private networking for the gateway". The Learn article for the API Management AI Gateway tier no longer exists. The task now links to the AI Gateway resource article, which lists the limits of the new resource, including that private endpoints aren't supported, and to the AI Gateway overview. The task's steps still describe the earlier gateway tier; validate them against the gateway you use.
- The two Defender tasks that cite "Connected platforms in Microsoft Agent 365" now link to that article at its current address.
- The Help page's "Report an issue or suggest a change" link opens the resource feedback form.
- No other task content changed.

## 1.0.2 - 2026-10-29

- Each task's guide link now opens the exact step in the Customer Implementation Guide's Detailed view (for example `#advanced/4.04a`) instead of the top of the Detailed view.
- Six Defender tasks named their guide step in words. They now name its code (2.01, 2.02, 2.03, 2.06, 2.07, and 2.10), so each links to the right step. The "real-time protection rules" task now points at 2.06.

## 1.0.1 - 2026-10-28

- Replaced the link to the archived Agent 365 Lifecycle Atlas with the Microsoft Agent 365 Technical Advisory on the Help and links page.

## 1.0.0 - 2026-10-28

- Initial release of the Agent 365 Enablement Checklist: a self-contained, offline tracker with scoping by agent type, pillar, or feature, role-based tasks, a readiness dashboard, and Excel, CSV, JSON, and print export.
- Links to the Agent 365 Customer Implementation Guide (Detailed view) and the Agents Cost Calculator.
