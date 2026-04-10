# 🏛️ Agent Fleet Governor

> Monitor, audit, govern, and rationalize your organization's AI agent fleet — powered by the M365 Admin Center MCP.

## At a Glance

| | |
|---|---|
| **Best for** | IT admins, governance teams, Copilot Studio platform owners, AI Center of Excellence leads |
| **Complexity** | Medium |
| **Activation** | MCP Server (M365 Admin Center) + optional Prompt Tool for catalog intelligence |
| **Requires** | M365 Admin Center MCP Server enabled, admin permissions |
| **Outputs** | Agent inventory reports, orphan alerts, governance actions, duplicate analysis, consolidation recommendations, trend tracking |
| **Works in** | Both (interactive + autonomous heartbeat) |

## What This Skill Does

Agent Fleet Governor turns PowerClaw into an enterprise AI governance operator. Instead of only helping one person manage their own work, PowerClaw can inspect the organization’s Agent365 fleet, identify governance drift, and take approved remediation actions through the **M365 Admin Center MCP Server**.

It works across five modes:

1. **Inventory** — “How many agents do we have? Who owns them? Which are active?”
2. **Audit** — “Show me orphaned agents, agents with no recent usage, agents deployed this week.”
3. **Govern** — “Block that rogue agent” or “Assign Sarah as owner of the HR Benefits agent.”
4. **Monitor** — heartbeat runs a weekly governance scan to detect drift such as new orphaned agents, blocked agents, or usage anomalies.
5. **Catalog Intelligence** — classify agents by build type, detect duplicates, recommend consolidation, and assess catalog health. *(Requires the optional prompt tool — see setup below.)*

> 💡 **Catalog Intelligence is inspired by [Agent Steward](https://github.com/microsoft/copilot-agent-inventory-samples/tree/main/samples/agent-steward)** — a Microsoft sample that demonstrates tenant-wide agent governance using the Graph Package Management API. This mode brings that analytical thinking into PowerClaw as a conversational capability.

## Why This Is Uniquely PowerClaw

- **M365 Copilot alone cannot do this** — these are admin MCP tools, not standard end-user chat capabilities.
- **Heartbeat enables autonomous governance** so reviews can happen weekly without someone remembering to run a manual audit.
- **Memory tracks trends over time** such as “orphaned agent count went from 3 to 7 this month” or “duplicate count dropped after last month’s cleanup.”
- **Read + write actions live together** in one conversational interface, so PowerClaw can analyze the catalog and remediate in the same flow.
- **Catalog intelligence goes beyond listing** — PowerClaw classifies agents by build type, detects duplicates across four categories, and recommends consolidation with confidence levels.
- **The system gets smarter over time** as PowerClaw learns normal ownership, deployment, and usage patterns in your environment.

## When to Use It

- Monthly agent governance review
- New agent onboarding oversight
- Orphaned agent cleanup
- Blocking unauthorized or risky agents
- Ownership transfer when people leave the organization
- Executive briefing on AI agent adoption metrics
- Quarterly catalog rationalization — find duplicates and consolidation opportunities
- Before rolling out an org-wide agent, check for existing alternatives
- AI Center of Excellence governance cadence

## Trigger Phrases

- “How many agents do we have?”
- “Show me orphaned agents.”
- “Who owns the HR Benefits agent?”
- “Block the unauthorized sales bot.”
- “Give me an agent governance summary.”
- “What agents were deployed this week?”
- “Assign Sarah Chen as owner of the HR Benefits agent.”
- “Which agents have no recent usage?”
- “Agent fleet health check.”
- “Weekly governance report.”
- “Show me blocked agents.”
- “What changed in our agent fleet this month?”
- “Analyze our agent catalog for duplicates.”
- “Classify all agents by how they were built.”
- “Which agents overlap and could be consolidated?”
- “Find candidates for org-wide promotion.”
- “Give me a catalog health report.”
- “Run a catalog stewardship review.”

## Prerequisites

- **M365 Admin Center MCP Server** is enabled in Copilot Studio
- **Admin permissions** — the user running PowerClaw has appropriate Microsoft 365 admin rights
- The following MCP tools are toggled **ON** in the MCP server configuration:
  - `getAgent365Agents`
  - `getAgent365AgentDetails`
  - `postAgent365ManagementAction`
  - `assignAgent365AgentOwner`
  - `getAgent365AgentInsights`
- Optional: A **Prompt Tool** configured for Catalog Intelligence (see setup below)
- Optional: **Code Interpreter** enabled for large catalog analysis

## Setup

### Step 1 — Enable the M365 Admin Center MCP Server

1. Open **Copilot Studio** and select your **PowerClaw** agent.
2. Go to **Tools** → **Add a tool**.
3. Search for **M365 Admin Center** or **Microsoft 365 Admin Center MCP**.
4. Select the MCP server and click **Add**.
5. Create or confirm the connection, then authenticate with an admin account.

### Step 2 — Enable the Agent365 tools

1. Open the MCP server configuration.
2. Toggle **ON**:
   - `getAgent365Agents`
   - `getAgent365AgentDetails`
   - `postAgent365ManagementAction`
   - `assignAgent365AgentOwner`
   - `getAgent365AgentInsights`
3. Save the configuration.

### Step 3 — Publish and test

1. Publish the agent.
2. In Teams, ask: **“How many agents do we have in our organization?”**
3. Verify that PowerClaw returns agent inventory data from the MCP tools.

> 💡 **No prompt tool needed for core governance.** Agent Fleet Governor’s Inventory, Audit, Govern, and Monitor modes work through MCP server tools directly. For **Catalog Intelligence** (classification, duplicates, consolidation), see the optional prompt tool setup below.

## How It Works (Core Modes)

The first four modes work through MCP server tools directly — no prompt tool needed. You enable the tools and let PowerClaw’s AI orchestration route requests automatically:

- Agent inventory questions → `getAgent365Agents`
- Questions about one specific agent → `getAgent365AgentDetails`
- Block or unblock requests → `postAgent365ManagementAction`
- Ownership transfer requests → `assignAgent365AgentOwner`
- Org-wide governance metrics → `getAgent365AgentInsights`

The model handles routing, reasoning, and response formatting. No topic flow or prompt tool setup is required.

## Catalog Intelligence (Optional Prompt Tool)

The first four modes (Inventory, Audit, Govern, Monitor) work through MCP tools alone — no prompt needed. **Catalog Intelligence** adds a deeper analytical layer through an optional prompt tool that classifies agents, detects duplicates, and recommends consolidation.

### Setup

#### Step 1 — Create the Prompt Tool

1. In **Copilot Studio**, go to **Tools** → **Add a tool** → **Prompt**.
2. Choose **Create new prompt**.
3. Name it **Catalog Intelligence**.
4. Add one input:
   - **`analysisType`** → **Text** → mark as **Optional**
5. Paste the prompt from below.
6. Save the prompt.

#### Step 2 — Choose the prompt model

Click the **Model** dropdown at the top of the prompt editor:

| Tier | Model | Best for |
|---|---|---|
| Standard | GPT-4.1 | Solid catalog analysis for tenants with < 50 agents |
| Standard | GPT-5 chat | Better semantic grouping and consolidation reasoning |
| Premium | GPT-5 reasoning | Best for large catalogs (100+ agents) with complex overlap patterns |

> 💡 For catalogs with 50+ agents, prefer **GPT-5 chat** or higher. Classification and duplicate detection benefit from stronger reasoning.
>
> ⚠️ **Claude Sonnet 4.6** works for text analysis but may struggle with large structured datasets. Prefer GPT models for this skill.

#### Step 3 — (Optional) Enable Code Interpreter

For large catalogs, Code Interpreter lets PowerClaw process the full agent list as structured data (sorting, filtering, clustering, charting).

1. Go to your agent settings in Copilot Studio.
2. Enable **Code Interpreter** if not already active.

#### Step 4 — Add orchestration guidance

In the agent’s instructions, add:

> When the user asks to analyze agents for duplicates, classify agents by build type, find consolidation candidates, run a catalog review, or assess catalog health, use the **Catalog Intelligence** prompt.

#### Step 5 — Publish and test

Publish the agent and ask: **“Analyze our agent catalog for duplicates.”**

### Prompt Tool: Catalog Intelligence

**Purpose:** Analytical intelligence layer for the tenant’s Copilot agent catalog
**When PowerClaw calls it:** When the user asks about agent duplicates, catalog health, consolidation, classification, or deployment analysis
**Inputs:** `analysisType` (text, optional) — e.g. `duplicates`, `classify`, `consolidation`, `health`, `full review`
**Output:** Structured catalog analysis with actionable recommendations

**Prompt:**

```text
You are PowerClaw, a 24/7 AI Chief of Staff for Microsoft 365.

Your job is to perform strategic analysis of the organization’s Copilot agent catalog — classifying agents, detecting duplicates, and recommending consolidation.

Use `analysisType` to determine the focus. Valid types:
- "classify" — classify agents by build type and deployment scope
- "duplicates" — detect duplicate and overlapping agents
- "consolidation" — recommend agents to merge, retire, or promote org-wide
- "health" — overall catalog hygiene assessment
- "full review" — all of the above
If blank, default to "full review".

---

TOOLS TO USE:

Use the M365 Admin Center MCP tools:
- `getAgent365Agents` — retrieve the full agent inventory
- `getAgent365AgentDetails` — get details for specific agents (use selectively, not for every agent)
- `getAgent365AgentInsights` — usage data if available

IMPORTANT: Use a two-pass approach for efficiency:
1. Pass 1: Retrieve the full inventory list with `getAgent365Agents`
2. Pass 2: Fetch details only for agents that are candidates for duplication, consolidation, or need classification clarification

---

CLASSIFICATION TAXONOMY:

Classify each agent into one of these build types based on available metadata:

| Label | Evidence required |
|---|---|
| Agent Builder | type=shared AND elementType contains DeclarativeCopilots |
| Copilot Studio (Custom) | elementType contains CustomEngineCopilots |
| 1st Party | type=firstParty |
| 3rd Party | type=thirdParty |
| Unclassified | insufficient metadata to determine |

If the response fields do not include explicit type or elementType data, classify using available signals:
- Publisher/source information
- Name patterns (e.g. "Microsoft" publisher → likely 1P)
- Description or category metadata
In this case, prefix the label with "Likely" (e.g. "Likely Agent Builder") and note that classification is based on inference, not confirmed metadata.

DEPLOYMENT SCOPE:

| Scope | Meaning |
|---|---|
| Admin-deployed (LOB) | Pushed tenant-wide by an admin; discoverable in the Agent Store |
| Shared | Published by a user via link; audience depends on sharing settings |
| Unknown | Deployment scope not available in response data |

KEY RULE: An agent may appear twice — once as shared and once as admin-deployed. This means it was shared first, then promoted. Treat these as the SAME agent at different deployment stages, not as duplicates.

---

DUPLICATE DETECTION:

Analyze the agent list for these four categories:

1. **Active Duplicates** — Multiple agents serving the same purpose with users split between them.
   Evidence: similar names + similar descriptions + both have recent activity.
   Risk: fragmented user experience, wasted maintenance effort.

2. **Orphaned Agents** — Superseded by a newer or better version but still in the catalog.
   Evidence: similar purpose to an active agent but with declining or zero usage.
   Risk: user confusion, catalog noise.

3. **Catalog Clutter** — Agents in the catalog with no usage and no clear owner.
   Evidence: no recent activity + no assigned owner or inactive owner.
   Risk: governance blind spots, abandoned resources.

4. **Fragmented Deployments** — The same agent deployed across multiple scopes or teams when a single org-wide deployment would be better.
   Evidence: same or near-identical name/description deployed by different owners.
   Risk: inconsistent versions, duplicated maintenance.

CONFIDENCE LEVELS for duplicate detection:
- **Confirmed**: Same stable identifier (app ID, manifest ID, package ID) appearing in multiple entries
- **High confidence**: Same name + same publisher/owner + very similar description
- **Potential overlap**: Semantically similar purpose but different names/owners — needs human review

ALWAYS state the confidence level for each finding. Never present potential overlaps as confirmed duplicates.

---

CONSOLIDATION RECOMMENDATIONS:

For each duplicate cluster or overlapping group, recommend ONE of:
- **Retire** — remove the less-used version from the catalog
- **Consolidate** — merge multiple agents into one and redirect users
- **Promote org-wide** — take a shared/team agent and deploy it tenant-wide
- **Investigate further** — insufficient data to make a recommendation

Include for each recommendation:
- Which agents are involved
- Why (usage data, overlap evidence, deployment gaps)
- Suggested next step

---

CATALOG HEALTH ASSESSMENT:

If analysisType is "health" or "full review", also evaluate:
- **Naming consistency** — are agents named clearly and consistently?
- **Description quality** — do agents have useful descriptions?
- **Ownership coverage** — what percentage have an assigned owner?
- **Usage distribution** — are there long-tail unused agents?
- **Deployment balance** — ratio of admin-deployed vs shared-only agents

Provide a simple scorecard:
| Dimension | Rating | Notes |
|---|---|---|
| Naming | 🟢🟡🔴 | ... |
| Descriptions | 🟢🟡🔴 | ... |
| Ownership | 🟢🟡🔴 | ... |
| Usage spread | 🟢🟡🔴 | ... |
| Deployment | 🟢🟡🔴 | ... |

---

OUTPUT FORMAT:

# Agent Catalog Intelligence Report
**Analysis type:** [resolved type]
**Agents scanned:** [count]
**Scan date:** [today]

## Classification Summary
[table of agent counts by build type]

## Duplicate Analysis
[grouped findings with confidence levels]

## Consolidation Recommendations
[actionable recommendations]

## Catalog Health Scorecard
[scorecard table]

## Suggested Next Steps
[top 3–5 prioritized actions]

---

RULES:
- Only claim "inactive owner", "promoted from shared to admin-deployed", or "confirmed duplicate" when the raw tool response explicitly supports it with matching identifiers or explicit status fields.
- If a data point is not present in the tool response, output "Unable to assess from available metadata" for that dimension. Do not infer ownership status, deployment history, or agent lineage from absence of data.
- Be thorough but concise — use tables and bullets, not long paragraphs.
- NEVER fabricate agent names, IDs, or usage data not in the tool responses.
- If data is insufficient for a category, say so honestly.
- If Code Interpreter is available and the catalog has more than 30 agents, use it to process the inventory as structured data for better analysis.
- If the user asks for details on a specific cluster, use `getAgent365AgentDetails` to fetch additional info.
- Always end with suggested next steps, including which operational actions (block, reassign) can be taken immediately.
```

### Catalog Intelligence Examples

#### Full catalog review

> **You:** Run a catalog stewardship review.
>
> **PowerClaw:** Here’s your Agent Catalog Intelligence Report.
>
> **Analysis type:** Full review — **Agents scanned:** 63 — **Scan date:** 2026-04-10
>
> **Classification Summary**
> | Build Type | Count |
> |---|---|
> | Agent Builder | 28 |
> | Copilot Studio (Custom) | 12 |
> | 1st Party | 18 |
> | 3rd Party | 3 |
> | Likely Agent Builder | 1 |
> | Unclassified | 1 |
>
> **Duplicate Analysis**
> - **Active Duplicates (High confidence):** “HR Benefits FAQ” (45 users) ↔ “Benefits Helper” (22 users) — same purpose, split audience
> - **Catalog Clutter:** “Test Onboarding Agent” — no usage in 90 days, no owner
> - **Fragmented Deployments (Potential overlap — needs human review):** “Expense Report Helper” appears in 3 variants across Finance, Sales, and Engineering
>
> **Consolidation Recommendations**
> 1. **Consolidate** HR Benefits FAQ + Benefits Helper → keep the more-used one, redirect users
> 2. **Retire** Test Onboarding Agent — no active users
> 3. **Investigate** Expense Report Helper variants — may benefit from a single org-wide deployment
>
> **Catalog Health:** Naming 🟡 | Descriptions 🟡 | Ownership 🔴 (8 agents with no owner) | Usage 🟡 | Deployment 🟡
>
> Want me to block the clutter agents or reassign ownership? I can handle that directly.

#### Quick duplicate check

> **You:** Are there any active duplicates in our agent catalog?
>
> **PowerClaw:** Found 2 active duplicate clusters:
>
> 1. **HR Benefits FAQ** (45 users) ↔ **Benefits Helper** (22 users)
>    — Confidence: **High** — same purpose, similar descriptions, both active
>    — Recommendation: Consolidate into one and retire the other
>
> 2. **IT Helpdesk Agent** (admin-deployed) ↔ **IT Support Bot** (shared, 31 users)
>    — Confidence: **High** — near-identical descriptions
>    — Recommendation: Promote the admin-deployed version org-wide, retire the shared one
>
> Want me to take action on either?

### Advanced: Full-Fidelity Classification with Graph Package Management API

For organizations that need **deterministic classification** and **exact deployment scope analysis**, consider supplementing this skill with the [Microsoft Graph Package Management API](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/api/admin-settings/package/overview) — the same API used by the [Agent Steward sample](https://github.com/microsoft/copilot-agent-inventory-samples/tree/main/samples/agent-steward).

The Graph API (`/beta/copilot/admin/catalog/packages`) returns explicit fields:
- `type` (shared, lob, firstParty, thirdParty) — enables deterministic build-type classification
- `elementDetails.elementType` (DeclarativeCopilots, CustomEngineCopilots) — confirms Agent Builder vs Custom Engine
- `supportedHosts`, `manifestVersion`, `sensitivity` — richer catalog metadata

**To add this capability:**
1. Register an Entra ID app with `CopilotPackages.Read.All` delegated permission
2. Create an OAuth client registration in the Teams Developer Portal
3. Add the Graph Package Management API as a connector action in Copilot Studio
4. Update the Catalog Intelligence prompt to prefer Graph API data when available

This is an advanced setup requiring Global Administrator or AI Administrator roles. For most organizations, the MCP-based analysis provides a strong starting point.

---

## Proactive Mode (Heartbeat Integration)

> 💡 **Quick start — schedule it:** Add a recurring calendar event named **`[PowerClaw Routine] Agent Governance Review`** and PowerClaw can run an autonomous governance scan on heartbeat.

This skill is especially strong when paired with PowerClaw’s autonomous loop:

- Call `getAgent365AgentInsights` weekly to check orphan counts, deployment changes, and fleet health signals
- Compare current results against memory to detect trend changes
- Send a proactive alert such as **“3 orphaned agents detected this week”**
- Save governance snapshots in memory using a scope like `governance:weekly`
- Remember which agents were previously flagged so follow-up reviews become smarter over time
- Run a monthly **Catalog Intelligence** scan to detect new duplicates, catalog clutter growth, or declining health scores
- Schedule via **`[PowerClaw Routine] Monthly Catalog Review`** for automatic catalog rationalization

## Example Interactions

### Example 1: Governance overview

> **You:** Give me an agent governance summary for this week.
>
> **PowerClaw:** Here’s your org’s agent fleet status:
>
> **📊 Agent Fleet Summary**
> - Total agents: 47
> - Active (used in last 30 days): 31
> - Orphaned (no owner): 5
> - Blocked: 2
> - Deployed this week: 3
>
> **⚠️ Attention needed**
> - 5 orphaned agents — recommend assigning owners
> - “Sales Lead Qualifier” has not been used in 60 days
>
> Want me to show details on any of these, or assign owners to the orphaned agents?

### Example 2: Investigate and remediate

> **You:** Show me the orphaned agents and block any that haven’t been used in 90 days.
>
> **PowerClaw:** Found 5 orphaned agents. 2 have had no usage in 90+ days:
>
> | Agent | Last Used | Status |
> |---|---|---|
> | Legacy FAQ Bot | 94 days ago | Orphaned |
> | Test Onboarding Agent | 112 days ago | Orphaned |
>
> I’ll block both. Done ✅
> - Blocked: Legacy FAQ Bot
> - Blocked: Test Onboarding Agent
>
> The remaining 3 orphaned agents are still active. Want me to assign owners?

### Example 3: Ownership transfer

> **You:** Assign Sarah Chen as owner of the HR Benefits agent.
>
> **PowerClaw:** ✅ Done — Sarah Chen is now the owner of the HR Benefits agent. I’ve saved this in memory so it is reflected in future governance reviews.

## Tips

- Start with read-only inventory or audit queries before using management actions.
- Schedule a recurring Monday governance review via **`[PowerClaw Routine] Agent Governance Review`**.
- Pair this skill with memory so PowerClaw can track governance trends across weeks.
- Block actions are reversible — ask PowerClaw to unblock an agent when needed.
- In large environments, filter by department, owner, or deployment state to keep results manageable.

## Limitations

- Requires Microsoft 365 admin permissions and is not suitable for regular end users.
- Management actions such as block or owner reassignment change real production state.
- Usage metrics may lag by 24–48 hours depending on the source system.
- PowerClaw can manage existing agents, but it cannot create or delete agents through this skill.
- Availability depends on the M365 Admin Center MCP Server being enabled in your tenant.
- **Catalog Intelligence classification accuracy depends on available metadata.** If the MCP tools do not expose explicit build-type fields, classification falls back to inference and findings are marked as “Likely” rather than confirmed.
- **Duplicate detection is semantic, not deterministic.** Without stable identifiers, duplicates are identified by name/description similarity. Always verify before taking action.

## Extension Ideas

- Weekly governance digest email with trend charts
- Auto-block agents that exceed orphaned + inactive thresholds
- Integration with compliance workflows for sensitive-data or policy checks
- Dashboard view of agent fleet health exported to Word and saved in SharePoint
- Catalog diff reports — “what changed in our catalog since last month?”
- Team-level catalog views — “show me all agents owned by the Finance team”
- Agent quality scoring per agent based on description quality, naming, usage, and ownership
- Graph Package Management API connector for full-fidelity classification (see Advanced section)

## Related Skills

- [Executive Radar](executive-radar.md) — attention triage across your personal M365 signals
- [Commitment Tracker](commitment-tracker.md) — track follow-through on governance remediation actions
- [Weekly Status Report](weekly-status-report.md) — include agent fleet metrics in leadership updates
