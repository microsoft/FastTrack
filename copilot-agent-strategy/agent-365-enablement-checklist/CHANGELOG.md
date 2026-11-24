# Changelog

## 1.2.1 - 2026-11-23

Rechecked against Microsoft Learn on 2026-11-23 and aligned with Customer Implementation Guide 1.5.0. Task numbers, workstreams, and saved plans are unchanged.

- **Guide links.** Tasks now open the new guide steps: Execution Containers (Shadow agents 14, step 13m), Global Secure Access network discovery and MCP controls (Shadow agents 15, steps 13d and 13n), AI spend, model providers, and credit requests (Operate & value 8, 13, 14, and 15, step 14d), chargeback (Operate & value 16, step 14e), Business Analytics (Operate & value 17 and 18, step 14f), and the Admin center scale tasks (16 to 19, step 15g). Admin center tasks 13 and 15 and Tools & MCP task 10 link to their guide steps, and Low-code agents task 11 now links to PP4.
- **Deadlines and status.** The existing Copilot Studio real-time protection onboarding retires on December 23, 2026, so Defender tasks 1, 7, and 8 say to re-create blocking rules before then. The checklist no longer says a blocking rule stops near-real-time alerts, because Learn doesn't: audit mode generates alerts and block events are in `BehaviorInfo` (Defender 7 and 10, Custom agents 9). The prohibited-local-agents compliance policy is described as in development (Shadow agents 13), and the Execution Containers task is described as a private preview (Shadow agents 14).
- **Shadow and local agents.** Runtime protection (task 9) covers the Intune and Defender portal policy surfaces, device-group targeting, prompt evidence collection, and network inspection as a policy setting, and no longer asks for the Defender Beta Channel. Network discovery (task 15) adds the Log Reader role, client versions, MCP policies, security profiles, and Conditional Access.
- **Identity and data.** Entra tasks 2, 5, 9, and 11 follow the current sponsor group types, the Microsoft-managed "Block all high risk agents" policy, the sponsor transfer templates, and the Global Secure Access source type limit. Purview tasks 6, 7, 10, 19, 21, and 23 follow the PDF support step, the roles, the renamed Copilot DLP location and its limits, the Foundry Manage → Compliance path, the auto-labeling prerequisites, and the Purview SDK middleware notes. SharePoint tasks 2, 4, and 5 follow the data access governance report changes.
- **Platforms and cost.** AI Gateway is its own resource type and the old tier resources stop on January 15, 2027, which replaces the stale preview, region, and SLA wording (Gateway & compute 1 to 4 and 10). New Windows 365 for Agents customers are billed with Copilot Credits only (Gateway & compute 5 and 6, Operate & value 8). Operate & value 13, 14, and 16 add the Enterprise Agreement and CSP purchase change from January 1, 2027, the December 9, 2026 removal of the "Microsoft 365 apps only" model option, and the multi-tenant policy template behavior. Operate & value 2 and 3 follow the Agent Dashboard's two views and the Microsoft Copilot Agents Usage Report (Preview).
- **Agent Builder and Copilot Studio.** Fixed 4 moved Microsoft Learn links: the Agent Builder articles now live under `/en-us/plugins/`. Updated link titles that no longer matched their Learn articles. Foundations 5 and Admin center 4 note that admins can't disable Agent Builder creation separately and that sharing changes apply to new sharing actions. Low-code agents 3, 4, and 5 follow the Azure Bot Service skills connector, update timing, and the Copilot Studio identity blueprint app.
- **Licensing.** Foundations 6 and Admin center 13 and 16 follow the core and premium license split in the service description.

## 1.2.0 - 2026-11-19

Updated for the Agent 365 announcements from Microsoft Ignite. The checklist grows from 160 to 174 tasks and was rechecked against Microsoft Learn on 2026-11-19.

- **New pillars.** The Observe, Govern, and Secure pillars are now Management, Governance, Security, and a new Business Value pillar, matching Microsoft's current Agent 365 messaging. Observability (Discover, Evaluate, Monitor) now applies across every pillar. A saved Observe choice carries over to Management, and existing plans, progress, and backups keep working.
- **Business value and cost.** The "Operate & adopt" workstream is now "Operate & value" and adds six tasks: forecast AI spend and agree a budget (task 13), choose which AI model providers each group can use (14), route credit requests to your approval workflow and automate cost policies (15), charge AI usage back to the departments that fund it (16), connect AI spend to business value (17), and set up Agent 365 Business Analytics (18). The FinOps task (8) was updated. Three features join the feature scope: Multi-tenant agent management; Chargeback, credit requests, and cost automation; and Business value and ROI reporting.
- **Administration.** Four new Agent 365 admin tasks cover managing agents across the tenants you govern (16), syncing agent activity to Azure Monitor (17), reviewing agent use cases to find duplicate and overlapping agents (18), and piloting the Agent 365 Admin plugin in Copilot (19). The registry task (1) now includes agent activity, and the ownerless-agent and risk-triage tasks (13 and 15) were updated.
- **Shadow AI and local agents.** Three new tasks mark devices with prohibited local agents noncompliant (13), set runtime boundaries with Execution Containers (14), and add network discovery and MCP controls with Global Secure Access (15). The discovery sensors, review, containment, and onboarding tasks (3, 4, 8, and 10) were updated, and the Defender runtime protection task (9) is now "Roll out" instead of "Pilot".
- **Data protection.** A new Purview task pilots DLP for Microsoft agents and key local agents (27), and the Copilot processing restriction task (10) was updated.
- **Connected platforms and tools.** The registry sync task (Custom agents 10) is now "Connect external agent platforms through Connected platforms". The tool approval, AI gateway, plugin and skill availability, and Work IQ MCP tasks (Tools 2, 9, 10, and 12) were updated, along with the Windows 365 for Agents prerequisites task (Gateway & compute 5).
- **Licensing and dashboards.** Foundations task 6 now covers the usage and activity insights that qualifying Microsoft 365 subscriptions include since Ignite, and forecasting usage-based spend. The Agent 365 Dashboard task (Operate 2) notes that Viva Insights will remove the Agent 365 license requirement for agent insights.
- **Defender, Entra, and Copilot Studio.** The Defender tasks (1 to 11) cite the guide's renamed "Microsoft Defender for Agent 365" section. The inventory reconciliation task (4), the agent identity inventory and report-only Conditional Access tasks (Entra 1 and 5), and the Microsoft-built agent rollout and partner agent tasks (Low-code agents 1 and Custom agents 12) were updated.
- **Layout.** The pillar and feature pickers now fit five pillars and the new features.

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
