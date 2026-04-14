# 📊 Workplace Intelligence Monitor

> Monitor workforce health, collaboration patterns, and Viva Advanced Insights trends through Power BI semantic models — powered by the Power BI Remote MCP Server.

> ℹ️ **Preview.** Power BI Remote MCP Server is in preview. Hit a snag? [Open an issue](https://github.com/microsoft/FastTrack/issues).

## At a Glance

| | |
|---|---|
| **Best for** | Enterprise IT admins, HR analytics leaders, chiefs of staff, business leaders |
| **Complexity** | Medium |
| **Status** | Preview |
| **Activation** | MCP Server (Power BI Remote) |
| **Requires** | Power BI Remote MCP Server, Entra app registration, Power BI admin tenant setting, semantic models with relevant data |
| **Outputs** | Workforce health answers, threshold alerts, trend comparisons, proactive recommendations |
| **Works in** | Both (interactive + autonomous heartbeat) |

## What This Skill Does

Workplace Intelligence Monitor turns PowerClaw into a workforce analytics operator. It can query **any Power BI semantic model**, but the killer use case is **Viva Advanced Insights** data: focus time, meeting hours, collaboration patterns, manager 1:1 frequency, and after-hours work.

It works across four modes:

1. **Explore** — discover what semantic models, tables, measures, and workforce metrics are available.
2. **Query** — ask natural-language questions about workforce patterns, team health, productivity, and collaboration.
3. **Monitor** — use heartbeat to check thresholds automatically and flag concerning changes before someone asks.
4. **Trend** — compare current results with prior snapshots stored in memory so PowerClaw can detect movement over time.

## Why This Is Uniquely PowerClaw

- **Heartbeat-driven monitoring** means org health checks can run every 30 minutes or on a scheduled routine without manual prompting.
- **Persistent memory enables trend tracking** so PowerClaw can compare this week’s results against last month, last quarter, or previous alerts.
- **Cross-source synthesis** combines Viva and Power BI metrics with calendar, email, tasks, and known commitments for more useful interpretation.
- **Proactive nudges** let PowerClaw warn leaders when thresholds are breached instead of waiting for a dashboard review.
- **It goes beyond vanilla M365 Copilot** by turning workforce analytics into an autonomous operating loop, not just a one-time Q&A experience.

## When to Use It

- Monitoring focus time decline across a team or org
- Spotting teams with excessive meeting load
- Checking whether manager 1:1 frequency is falling below expectations
- Tracking after-hours work and collaboration overload
- Preparing an executive org-health briefing from Viva or other Power BI models
- Comparing current workforce signals against prior periods saved in memory
- Running a weekly or monthly workforce risk review on heartbeat
- Investigating whether collaboration changes line up with project deadlines, launches, or restructuring

## Trigger Phrases

- “How much focus time did my org average last month?”
- “Which teams are over-meeting?”
- “Show me after-hours work trends for the last 90 days.”
- “Did manager 1:1 frequency drop this quarter?”
- “What workforce signals look unhealthy right now?”
- “Run a workplace intelligence check.”
- “Compare this month’s collaboration load to last month.”
- “Which orgs are losing focus time fastest?”
- “Are meeting hours trending up across Engineering?”
- “Watch for burnout signals and alert me.”
- “What does the Viva model say about my team’s work patterns?”
- “Give me a workforce health summary from Power BI.”

## Prerequisites

- **Power BI Remote MCP Server** is available in Copilot Studio
- **Entra ID app registration** is created as a **multi-tenant** app
- **API permissions** are granted and admin-consented: **Power BI Service → Delegated**:

  | Permission | Description |
  |---|---|
  | `Item.Execute.All` | Make API calls that require execute permissions on all Fabric items |
  | `MLModel.Execute.All` | Execute ML models |
  | `SemanticModel.Read.All` | Read semantic models |
  | `Workspace.Read.All` | View all workspaces |

  > ⚠️ All four permissions must have **admin consent granted** (green checkmark in the Status column). Without admin consent, schema retrieval may work but query execution will return 401.
- **Power BI admin tenant setting** is enabled: **Users can use the Power BI Model Context Protocol server endpoint (preview)**
- **Power BI Pro (or higher) license** — the user executing queries must have at least a Pro license and Build permissions on the target semantic model. No Premium capacity or PPU is required for schema retrieval or query execution. The GenerateQuery tool (Copilot-powered DAX generation) requires a Copilot license or Fabric capacity (F2+).
- Relevant **Power BI semantic models** exist and are accessible to the signed-in user
- For Viva scenarios, **Viva Advanced Insights data** is flowing into a Power BI semantic model

## Setup

### Step 1 — Create the Entra app registration

1. Open **Microsoft Entra admin center** → **App registrations** → **New registration**.
2. Name the app something clear, such as **PowerClaw Power BI MCP**.
3. Set **Supported account types** to **Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant)**.
4. Add a redirect URI that matches your Copilot Studio OAuth flow requirements.
5. After creation, go to **API permissions** → **Add a permission** → **Power BI Service** → **Delegated permissions**.
6. Add all four permissions: **`Item.Execute.All`**, **`MLModel.Execute.All`**, **`SemanticModel.Read.All`**, **`Workspace.Read.All`**.
7. Click **Grant admin consent for [your tenant]** — all four must show a green checkmark.
8. Go to **Certificates & secrets** and create a **client secret**. Save the secret value securely.
9. Record the **Application (client) ID**, **Directory (tenant) ID**, and secret for Copilot Studio setup.

### Step 2 — Enable the Power BI admin tenant setting

1. Open the **Power BI admin portal**.
2. Go to **Tenant settings**.
3. Find **Users can use the Power BI Model Context Protocol server endpoint (preview)**.
4. Set it to **Enabled** for the right security group or for the organization, based on your governance policy.
5. Save the change and allow time for the tenant setting to propagate.

### Step 3 — Add the MCP server in Copilot Studio

1. Open **Copilot Studio** and select your **PowerClaw** agent.
2. Go to **Tools** → **Add a tool** → **MCP Server**.
3. Configure the server with:
   - **Endpoint:** `https://api.fabric.microsoft.com/v1/mcp/powerbi`
   - **Authorization URL:** `https://login.microsoftonline.com/common/oauth2/v2.0/authorize`
   - **Token URL:** `https://login.microsoftonline.com/common/oauth2/v2.0/token`
   - **Refresh URL:** `https://login.microsoftonline.com/common/oauth2/v2.0/token`
   - **Scope:** `https://api.fabric.microsoft.com/.default`
   - **Client ID:** your Entra app’s client ID
   - **Client Secret:** the secret you created in Step 1
4. Authenticate the connection.
5. Toggle **ON** all three tools:
   - `GetSemanticModelSchema`
   - `GenerateQuery`
   - `ExecuteQuery`
6. Save the MCP server configuration.

### Step 4 — Publish and test

1. Publish the agent.
2. Ask a simple live question such as: **“How much focus time did my org average last month?”**
3. Confirm that PowerClaw can connect, discover the right model, generate a query, and return a result.
4. Test at least one non-Viva model too, so you know the skill works across broader Power BI scenarios.

> 💡 **No prompt tool needed.** PowerClaw’s generative orchestration chooses the right MCP tool.

## How It Works (No Prompt Tool Needed)

This skill does not use a prompt tool. Instead, PowerClaw routes requests directly across the three Power BI Remote MCP tools:

- **`GetSemanticModelSchema`** — retrieves the model metadata so PowerClaw can understand tables, measures, relationships, and available metrics.
- **`GenerateQuery`** — generates a DAX query from the relevant schema context. **PowerClaw should always try this first** for natural-language requests.
- **`ExecuteQuery`** — runs the DAX query and returns the result set.

> 💡 **Cost note:** GenerateQuery uses Power BI's built-in Copilot capacity to generate DAX. If you prefer not to consume Copilot capacity, disable this tool and let PowerClaw's LLM generate DAX directly from the schema.

Typical orchestration flow:

1. Identify the relevant semantic model.
2. Inspect schema when the model or metrics are unclear.
3. Use **`GenerateQuery`** to produce a DAX query from the natural-language request.
4. Use **`ExecuteQuery`** to run the generated query.
5. Save important outputs or comparisons into memory when trend tracking matters.

This lets PowerClaw handle discovery, question answering, threshold checks, and historical comparisons without building a custom topic flow.

## Proactive Mode (Heartbeat Integration)

> 💡 **Quick start — schedule it:** Add a recurring calendar event named **`[PowerClaw Routine] Workplace Intelligence Review`** and PowerClaw can run autonomous workforce checks on heartbeat.

This is where the skill becomes more than a reporting tool:

- Heartbeat can call the Power BI MCP server on a recurring cadence
- PowerClaw can check thresholds such as falling focus time, rising meeting hours, weak 1:1 cadence, or increased after-hours work
- Results can be compared against memory snapshots from prior runs
- Cross-source synthesis can add context from calendar load, major initiatives, or known organizational commitments
- When a threshold is breached, PowerClaw can send a proactive nudge instead of waiting for a dashboard review

Example autonomous pattern:

1. Heartbeat triggers a workplace review routine.
2. PowerClaw queries the relevant semantic model.
3. Current values are compared to saved baselines in memory.
4. If a meaningful change is detected, PowerClaw creates an alert, summary, or follow-up recommendation.

## Example Interactions

### Example 1: Viva Insights org health query

> **You:** How much focus time did my org average last month?
>
> **PowerClaw:** Last month, your org averaged **6.8 hours of focus time per person per week**.
>
> **Highlights**
> - Down **0.9 hours** from the prior month
> - Lowest focus time: Sales and Customer Success
> - Biggest driver appears to be increased recurring meeting load
>
> I can break this down by team, manager, or compare it to meeting hours if you want.

### Example 2: Meeting load analysis + trend

> **You:** Which teams are over-meeting?
>
> **PowerClaw:** Based on the Viva semantic model, the teams with the highest meeting load this month are:
>
> | Team | Avg weekly meeting hours | Change vs prior month |
> |---|---|---|
> | Customer Success | 19.4 | +2.1 |
> | Engineering Program Mgmt | 18.7 | +1.6 |
> | Product Leadership | 17.9 | +0.8 |
>
> **Trend signal:** Customer Success has been above the 18-hour threshold for **3 straight months**.
>
> Want me to compare this against focus time and after-hours work to identify the highest-risk team?

### Example 3: Proactive heartbeat alert

> **PowerClaw:** ⚠️ **Workplace intelligence alert**
>
> Your team’s collaboration score dropped **11%** compared with the prior 30-day baseline.
>
> **What changed**
> - Focus time decreased
> - Meeting hours increased
> - Manager 1:1 frequency fell below the recent norm
>
> I also see a heavier calendar load tied to the QBR prep cycle. Recommend reviewing meeting volume and 1:1 cadence this week.

## Tips

- Start with a clear business question such as focus time, meeting load, or after-hours work.
- If the answer looks off, have PowerClaw inspect the semantic model schema first.
- Use **`GenerateQuery`** before hand-written DAX whenever possible.
- Save monthly or weekly snapshots in memory so trend comparisons get smarter over time.
- For Viva use cases, define explicit alert thresholds for metrics like focus time, meeting hours, or 1:1 frequency.
- Test with one known semantic model first, then expand to broader Power BI models.

## Limitations

- **GenerateQuery consumes Copilot capacity.** The GenerateQuery tool uses Power BI Copilot to generate DAX and requires a Copilot license or Fabric capacity (F2+). As a cost-conscious alternative, you can disable GenerateQuery and let PowerClaw's own LLM generate DAX directly — it just won't use the Power BI-native DAX generation. See [Microsoft docs](https://learn.microsoft.com/en-us/rest/api/power-bi/datasets/execute-queries) for details.
- Results depend on the quality, freshness, and access permissions of the underlying Power BI semantic model.
- Viva Advanced Insights data is not universal; it must already be available in a Power BI model for those scenarios.
- Some workforce metrics may lag depending on data refresh schedules.
- Natural-language requests still depend on good model design and understandable measure names.
- Cross-source interpretation is powerful, but PowerClaw should avoid making causal claims without supporting evidence.
- This skill reads and analyzes model data; it does not redesign the semantic model itself.

## Extension Ideas

- Weekly org-health digest delivered to leaders with trend snapshots
- Department-specific threshold packs for burnout, focus protection, or manager quality
- Escalation workflows when collaboration or after-hours risk crosses a set threshold
- Combine workforce signals with project delivery metrics for a broader operating review
- Export monthly workforce summaries into Word or SharePoint for leadership review

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Schema works but ExecuteQuery returns 401 | Missing API permissions or admin consent not granted | Verify all 4 Power BI Service permissions are added **and** admin consent is granted (green checkmark). Delete and re-create the Copilot Studio connection after fixing. |
| Connection fails during OAuth | App not configured as multi-tenant | Set Supported account types to "Accounts in any organizational directory" in the Entra app registration. |
| MCP server not available in Copilot Studio | Tenant setting not propagated | Enable the Power BI MCP tenant setting and wait ~15 minutes. |
| GenerateQuery returns empty or errors | Missing Copilot license or Fabric capacity | GenerateQuery requires a Copilot license or Fabric capacity (F2+). Alternatively, disable it and let PowerClaw's LLM generate DAX directly. |
| No semantic models found | User lacks workspace access | The signed-in user needs at least Viewer role on the workspace containing the semantic model. |

## Related Skills

- [Executive Radar](executive-radar.md) — combine workplace analytics with live email, calendar, and task attention signals
- [Weekly Status Report](weekly-status-report.md) — turn workforce insights and operating signals into a leadership-ready update
- [Commitment Tracker](commitment-tracker.md) — connect org-health issues to follow-up actions and accountability
