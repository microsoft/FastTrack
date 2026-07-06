# 🔍 Copilot Audit Dashboard

> [!IMPORTANT]
> **New version (April 21, 2026).** More accurate app & agent classification — Microsoft pre-built agents (Word Drafting Agent, Researcher, Analyst, etc.) no longer inflate host-app counts, and third-party agents are cleanly separated from first-party Copilot Chat. Agent name and ID now populate for autonomous agents. See the [Changelog](#-changelog) for details.

## 📊 Overview

A Power BI dashboard for analyzing Microsoft 365 Copilot usage and adoption across your organization. Combines Microsoft Purview audit data with Entra user details to surface:

- **Who's using Copilot** — by department, role, license type
- **Where they're using it** — Word, Excel, Outlook, Teams, Copilot Chat, agents
- **How usage is trending** — over time, by team, by app

![Power BI Dashboard](./Images/image.png)

> [!WARNING]
> Microsoft Purview audit logs are intended for security and compliance — not as an official source for Copilot usage reporting. Metrics may differ from the M365 Admin Center or Viva Insights. Use this dashboard to identify **trends and adoption patterns**, not for precise measurement.

## 🚀 Getting Started (3 Steps)

### Step 1: Export Copilot Audit Logs from Purview

1. Go to the **[Microsoft Purview portal](https://purview.microsoft.com/)** → **Audit**.
2. On the **Search** tab:
   - **Date range**: choose your period (e.g., Last 30 days)
   - **Record Types**: select **`CopilotInteraction`**
   - Leave **Users** blank
3. Click **Search**, then **Export** → **Download all results** when ready.
4. Save the CSV.

> See [Get started with audit search](https://learn.microsoft.com/en-us/purview/audit-search#get-started-with-search) for more detail.

### Step 2: Export Entra User Details

1. Download `Export-M365CopilotReports.ps1`.
2. Run it in PowerShell and choose **Export Entra Users Details**.
   ![PowerShell menu](./Images/2025-03-27%2014_42_33-AlejanlDev.png)
3. The script checks for required modules (`Microsoft.Graph`, `ExchangeOnlineManagement`) and offers to install them if missing.

### Step 3: Load into Power BI

1. Open the `.pbix` file.
2. **Home** → **Transform Data**. Update the two parameters:
   - `PathToCopilotAuditActivitiesCSV` — your Purview export
   - `PathToEntraUsersCSV` — your Entra export
   ![Update parameters](./Images/image-updateparameters.png)
3. **Close & Apply**.

<details>
<summary><b>Alternative: export the audit logs via PowerShell instead of the Purview UI</b></summary>

For smaller tenants or automated pipelines you can skip the portal and export the same data with PowerShell. Run `Export-M365CopilotReports.ps1`, choose **Export Purview Audit Logs**, and it produces a **raw `AuditData` CSV that matches the Purview portal export** — so it loads straight into the **same** `.pbix` above (just point `PathToCopilotAuditActivitiesCSV` at the generated file). All app/agent classification is handled by the Power BI query, so there is now a single source of truth.

> [!WARNING]
> `Search-UnifiedAuditLog` can time out or return incomplete data on high-volume tenants. The Purview UI export is still the recommended path.

> [!NOTE]
> The legacy `AlternateMethod/` `.pbix` (which consumed a pre-flattened CSV) is **deprecated**. The PowerShell export now feeds the main dashboard directly, so the alternate model is no longer required.

</details>

## 📋 How Usage Is Categorized

The dashboard groups every Copilot event into a clear **AppCategory** so leaders can see adoption at a glance:

| Category | What it represents |
| :--- | :--- |
| **Copilot Chat** | Copilot Chat / BizChat across all entry points (Office.com, M365 App, Bing, Edge, browser) |
| **Word / Excel / PowerPoint / Outlook / OneNote / Teams** | Direct Copilot usage inside that app |
| **SharePoint & OneDrive** | Copilot activity tied to content surfaces |
| **Other M365 Apps** | Loop, Whiteboard, Forms, Planner, Stream, Designer, Bookings, Power BI |
| **Viva** | Viva Engage, Viva Copilot, Viva Goals, Viva Pulse |
| **Admin & Security** | Copilot in Purview, Defender, Intune, Azure, M365 / Teams Admin centers, Security Copilot |
| **Microsoft Agents** | Microsoft pre-built agents (Word Drafting Agent, Researcher, Analyst, etc.) |
| **3P Agents** | Third-party / ISV-built Copilot extensions (e.g., Jira Cloud) |
| **Copilot Studio** | User-built Copilot Studio agents |

<details>
<summary><b>Why Microsoft agents are separated from host apps</b></summary>

When someone uses **Word Drafting Agent** inside Word, Purview records it with `AppHost = "Word"`. Earlier versions of this dashboard counted that as Word usage — inflating the Word bucket and hiding agent adoption. The current version routes these to **Microsoft Agents** so leaders can see agent adoption distinctly from direct in-app Copilot usage.

</details>

<details>
<summary><b>A note on Purview audit row counts</b></summary>

Purview `CopilotInteraction` exports are close to one row per prompt in most tenants, but retries, agent hops, and schema changes can cause minor inflation. If you need precise prompt-level counts (vs raw audit row counts), consider a deduplication measure on **User + ThreadId + CreationTime**.

</details>

## 🧩 Prerequisites

- **Admin Permissions** — to search the Purview audit log and run the Graph PowerShell script
- **PowerShell 5.1+** — for the Entra user export
- **Power BI Desktop** — to open the `.pbix`

## 🏛️ Sovereign Clouds (GCC / GCC High / DoD)

The audit export and Entra user export are **cloud-agnostic** — they read whatever SKUs your tenant actually has directly from Microsoft Graph, so the CSVs load into the dashboard in any cloud.

> [!NOTE]
> The dashboard's **license friendly-name mapping currently assumes Commercial SKU values.** Government clouds use different license identifiers — the SKU GUID (`skuId`) differs between Commercial and GCC/GCC High/DoD, and some part numbers/friendly names carry a gov-specific variant. As a result, the **license type** shown in the report may display the raw SKU part number (or blank) instead of a friendly name for gov tenants.

**What this affects:** only the *display name* of the license in the report. All other data — usage, apps, agents, users — is unaffected.

**How to adjust for your cloud:** in Power BI Desktop, edit the license lookup in the query/model to match your tenant's SKU part numbers (run `Get-MgSubscribedSku | Select SkuId, SkuPartNumber` to list them). If you'd like your GCC/GCC High/DoD SKU values folded into the template so it works out of the box, please share them via the [issues list](../../../../issues).

## 📚 Additional Resources

- [Microsoft 365 Copilot documentation](https://learn.microsoft.com/en-us/microsoft-365-copilot/)
- [Microsoft Purview audit logging](https://learn.microsoft.com/en-us/purview/audit-log-search)
- [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/overview)

## ❓ Issues & Support

Please report issues to the [issues list](../../../../issues). This is an open-source community solution; support is not available through official Microsoft channels.

## 👨‍💻 Publish Details

| Publisher | Original Publish Date | Latest Publish Date |
| :--- | :--- | :--- |
| Alejandro Lopez (alejandro.lopez@microsoft.com) | March 26th, 2025 | April 21st, 2026 |

## 📝 Changelog

### July 6, 2026
- **Sovereign cloud guidance.** Documented that the exports are cloud-agnostic but the dashboard's license friendly-name mapping assumes Commercial SKUs, with steps for GCC / GCC High / DoD tenants to adjust the license lookup. Native gov SKU mappings to follow.

### July 2, 2026
- **Unified PowerShell export with the main dashboard.** The **Export Purview Audit Logs** option now emits a raw `AuditData` CSV that mirrors the Purview portal export, so it loads directly into `Copilot_Audit_PBI.pbix`. Retired the stale PowerShell app/agent classification (now a single source of truth in the Power BI query) and deprecated the separate `AlternateMethod` model.

### April 21, 2026
- **Agent name & ID for autonomous agents.** Autonomous (Copilot Studio) agents now show their name and ID parsed from AppIdentity, with a 3-tier fallback (AgentName → AppIdentity → ConnectorUsage).
- **Fixed blank-row detection bug.** `HasCopilotEventDataRecord` now correctly reads from the parsed AuditData record, preventing valid rows from being silently dropped.

### April 20, 2026
- **More accurate agent classification.** Microsoft pre-built agents (Word Drafting Agent, Researcher, Analyst, Outlook Coaching, etc.) now route to a dedicated **Microsoft Agents** category instead of counting toward their host app (Word, Outlook, etc.).
- **Third-party agents separated.** ISV-built Copilot extensions (e.g., Jira Cloud) now have their own **3P Agents** category, cleanly distinct from Microsoft agents and user-built Copilot Studio agents.
- **Cleaner Copilot Chat bucket.** All Copilot Chat entry points (BizChat, Office.com, M365 App, Bing, Edge, and non-first-party callers) now roll up into one **Copilot Chat** category.
- **Expanded AppCategory coverage** — Viva, Admin & Security, Other M365 Apps, SharePoint & OneDrive buckets added for broader visibility.
- **License visibility** — surfaces license type (e.g., Premium) where Purview includes it.

### April 3, 2026
- Comprehensive AppHost mapping with case-insensitive, future-proof fallback.
- Added grouped **AppCategory** column for clean executive dashboards.
- Support for Copilot Studio lite and full-agent events.

### March 26, 2025
- Initial release (Purview UI export + Entra user enrichment).
