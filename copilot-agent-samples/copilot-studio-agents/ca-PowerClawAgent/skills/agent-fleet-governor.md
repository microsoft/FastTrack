# 🏛️ Agent Fleet Governor

> Monitor, audit, and govern your organization's AI agent fleet — powered by the M365 Admin Center MCP.

## At a Glance

| | |
|---|---|
| **Best for** | IT admins, governance teams, Copilot Studio platform owners |
| **Complexity** | Medium |
| **Activation** | MCP Server (M365 Admin Center) |
| **Requires** | M365 Admin Center MCP Server enabled, admin permissions |
| **Outputs** | Agent inventory reports, orphan alerts, governance actions, trend tracking |
| **Works in** | Both (interactive + autonomous heartbeat) |

## What This Skill Does

Agent Fleet Governor turns PowerClaw into an enterprise AI governance operator. Instead of only helping one person manage their own work, PowerClaw can inspect the organization’s Agent365 fleet, identify governance drift, and take approved remediation actions through the **M365 Admin Center MCP Server**.

It works across four modes:

1. **Inventory** — “How many agents do we have? Who owns them? Which are active?”
2. **Audit** — “Show me orphaned agents, agents with no recent usage, agents deployed this week.”
3. **Govern** — “Block that rogue agent” or “Assign Sarah as owner of the HR Benefits agent.”
4. **Monitor** — heartbeat runs a weekly governance scan to detect drift such as new orphaned agents, blocked agents, or usage anomalies.

## Why This Is Uniquely PowerClaw

- **M365 Copilot alone cannot do this** — these are admin MCP tools, not standard end-user chat capabilities.
- **Heartbeat enables autonomous governance** so reviews can happen weekly without someone remembering to run a manual audit.
- **Memory tracks trends over time** such as “orphaned agent count went from 3 to 7 this month.”
- **Read + write actions live together** in one conversational interface, so PowerClaw can investigate and remediate in the same flow.
- **The system gets smarter over time** as PowerClaw learns normal ownership, deployment, and usage patterns in your environment.

## When to Use It

- Monthly agent governance review
- New agent onboarding oversight
- Orphaned agent cleanup
- Blocking unauthorized or risky agents
- Ownership transfer when people leave the organization
- Executive briefing on AI agent adoption metrics

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

## Prerequisites

- **M365 Admin Center MCP Server** is enabled in Copilot Studio
- **Admin permissions** — the user running PowerClaw has appropriate Microsoft 365 admin rights
- The following MCP tools are toggled **ON** in the MCP server configuration:
  - `getAgent365Agents`
  - `getAgent365AgentDetails`
  - `postAgent365ManagementAction`
  - `assignAgent365AgentOwner`
  - `getAgent365AgentInsights`

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

> 💡 **No prompt tool needed.** Unlike the other skills in this library, Agent Fleet Governor works through MCP server tools directly. PowerClaw’s generative orchestration chooses the right MCP tool based on the user’s natural-language request.

## How It Works (No Prompt Tool Needed)

This skill does not use a copy-paste prompt tool. Instead, you enable MCP server tools and let PowerClaw’s AI orchestration route requests automatically:

- Agent inventory questions → `getAgent365Agents`
- Questions about one specific agent → `getAgent365AgentDetails`
- Block or unblock requests → `postAgent365ManagementAction`
- Ownership transfer requests → `assignAgent365AgentOwner`
- Org-wide governance metrics → `getAgent365AgentInsights`

The model handles routing, reasoning, and response formatting. No topic flow or prompt tool setup is required.

## Proactive Mode (Heartbeat Integration)

> 💡 **Quick start — schedule it:** Add a recurring calendar event named **`[PowerClaw Routine] Agent Governance Review`** and PowerClaw can run an autonomous governance scan on heartbeat.

This skill is especially strong when paired with PowerClaw’s autonomous loop:

- Call `getAgent365AgentInsights` weekly to check orphan counts, deployment changes, and fleet health signals
- Compare current results against memory to detect trend changes
- Send a proactive alert such as **“3 orphaned agents detected this week”**
- Save governance snapshots in memory using a scope like `governance:weekly`
- Remember which agents were previously flagged so follow-up reviews become smarter over time

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

## Extension Ideas

- Weekly governance digest email with trend charts
- Auto-block agents that exceed orphaned + inactive thresholds
- Integration with compliance workflows for sensitive-data or policy checks
- Dashboard view of agent fleet health exported to Word and saved in SharePoint

## Related Skills

- [Executive Radar](executive-radar.md) — attention triage across your personal M365 signals
- [Commitment Tracker](commitment-tracker.md) — track follow-through on governance remediation actions
- [Weekly Status Report](weekly-status-report.md) — include agent fleet metrics in leadership updates
