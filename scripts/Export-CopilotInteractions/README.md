---
title: Export-CopilotInteractions
type: script
category: PowerShell
summary: >-
  Export user-level Copilot prompts and responses from Microsoft Graph into analysis-ready CSV
  datasets.
author: Alejandro Lopez
version: 1.0.0
published: "2026-05-21"
updated: "2026-05-21"
tags:
  - copilot
  - graph
format: ps1
whatItIs: >-
  A PowerShell exporter for Microsoft 365 Copilot enterprise interaction history that writes
  normalized interactions, users, errors, and pre-aggregated usage CSVs.
whyUseIt:
  - Feed Power BI, Excel, or another analytics tool with user-level interaction data.
  - Use interactive, client-secret, or certificate authentication.
  - Handle throttling, per-user failures, SKU tiers, and app/feature normalization during export.
howToUse: >-
  Install `Microsoft.Graph.Authentication`, grant the documented Graph permissions, and test
  interactively:


  ```powershell

  .\Export-CopilotInteractions.ps1 -TenantId "contoso.onmicrosoft.com" -Interactive -MaxUsers 10

  ```


  Review `Errors.csv`, then remove the user cap for the full export.
prerequisites:
  - PowerShell 5.1 or later
  - Microsoft.Graph.Authentication module
  - User.Read.All, Reports.Read.All, and AiEnterpriseInteraction.Read.All
  - Entra app registration for app-only authentication
---

# Microsoft FastTrack Open Source - Export-CopilotInteractions

Exports Microsoft 365 Copilot user-level interaction history (prompts and AI responses) for licensed Copilot Basic and Copilot Premium users in a tenant. Produces a set of CSV files designed to feed Power BI, Excel, or any downstream analytics tool.

Interaction data is pulled from the Microsoft Graph beta endpoint:

```
/beta/copilot/users/{id}/interactionHistory/getAllEnterpriseInteractions
```

Features:

- Enumerates licensed users and identifies which ones hold a Copilot SKU (Basic or Premium) via a configurable SKU-to-tier map
- Pulls full interaction history per Copilot user and normalizes it into a flat CSV
- Generates two pre-aggregated usage views ready for Power BI:
  - **Usage by user, app, feature, and day**
  - **Usage by app, feature, and day** (including Premium vs Basic user counts)
- Supports three authentication modes: app-only client secret, app-only certificate, and interactive (delegated)
- Built-in retry with exponential backoff and `Retry-After` handling for 429 / 5xx responses
- Throttling-friendly delay between per-user calls (configurable)
- Per-user error CSV so a single failure never stops the run
- UTF-8 CSVs with header-only output when a dataset is empty
- Body content snippet is sanitized (control characters stripped, newlines collapsed, capped at 500 characters)

### Important notes

- This script uses **Microsoft Graph beta** APIs. Beta APIs are subject to change and are not supported for production use.
- `getAllEnterpriseInteractions` **does NOT include Copilot Studio agent interactions**. It covers Microsoft 365 Copilot surfaces (Copilot Chat, Outlook, Word, Excel, PowerPoint, OneNote, Loop, Whiteboard, Teams) and Connected AI Agents / Third-Party Copilot agents.
- The `bodySnippet` column in `Interactions.csv` can contain **actual user prompt text and AI response content**. Review privacy, legal, data retention, and compliance requirements before exporting or sharing the output.
- The default SKU-to-tier mapping may need updates as Microsoft renames Copilot license SKU part numbers. Override the mapping at runtime via the `-SkuTierMap` parameter.

### Prerequisites

- **PowerShell 5.1** or later (PowerShell 7+ also supported)
- **Microsoft.Graph.Authentication** PowerShell module:

  ```powershell
  Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
  ```

- **Microsoft Graph permissions** (grant admin consent for app-only modes):
  - `User.Read.All`
  - `Reports.Read.All`
  - `AiEnterpriseInteraction.Read.All`

- An Entra ID app registration if using app-only (client secret or certificate) authentication.

### Parameters

| Parameter | Description |
|----|----|
| `-TenantId` | Microsoft Entra tenant ID or verified domain. |
| `-ClientId` | Application (client) ID. Required for app-only auth; optional for interactive. |
| `-ClientSecret` | App secret as a `SecureString`. Use `Read-Host -AsSecureString` to avoid putting secrets in shell history. |
| `-CertificateThumbprint` | Certificate thumbprint installed in the current user's certificate store. Use instead of `-ClientSecret`. |
| `-Interactive` | Use delegated interactive sign-in (a browser window opens). Best for testing. |
| `-OutputDirectory` | Folder for the CSV output. Defaults to the script directory. |
| `-StartDate` | Start of the export window. Defaults to UTC now minus 30 days. |
| `-EndDate` | End of the export window. Defaults to UTC now. |
| `-MaxUsers` | Caps the number of Copilot users processed. `0` = no cap. Useful for pilot runs. |
| `-DelayBetweenUserRequestsMilliseconds` | Throttling-friendly delay between per-user Graph calls. Defaults to `200`. |
| `-SkuTierMap` | Hashtable mapping SKU part numbers to tier labels (`Basic` / `Premium`). Override to track new SKUs. |
| `-IncludeAllUsers` | Enumerate **all** directory users instead of only users with an assigned license. |

> Date filtering is applied **client-side** after retrieval. The beta `getAllEnterpriseInteractions` endpoint does not currently support `$filter` on `createdDateTime`.

### Execution

**Interactive (recommended for first run / testing):**

```powershell
.\Export-CopilotInteractions.ps1 `
  -TenantId 'contoso.onmicrosoft.com' `
  -Interactive `
  -StartDate (Get-Date).AddDays(-7) `
  -MaxUsers 10
```

**App-only with client secret:**

```powershell
$secret = Read-Host 'Client secret' -AsSecureString
.\Export-CopilotInteractions.ps1 `
  -TenantId '<tenant-id>' `
  -ClientId '<app-id>' `
  -ClientSecret $secret
```

**App-only with certificate:**

```powershell
.\Export-CopilotInteractions.ps1 `
  -TenantId '<tenant-id>' `
  -ClientId '<app-id>' `
  -CertificateThumbprint '<thumbprint>' `
  -OutputDirectory '.\out'
```

### Output files

All files are written to `-OutputDirectory` (defaults to the script directory).

| File | Description |
|----|----|
| `Users.csv` | One row per Copilot-licensed user: `userId`, `displayName`, `userPrincipalName`, `copilotTier` (Basic/Premium/Unknown), `licenses` (semicolon-delimited SKU part numbers). |
| `Interactions.csv` | One row per interaction (prompt or AI response). Columns include `userId`, `userPrincipalName`, `interactionId`, `sessionId`, `appClass`, friendly `app` and `feature`, `agentId`, `interactionType` (`userPrompt` / `aiResponse`), `conversationType`, `createdDateTime`, `activityDate`, `copilotTier`, `contextTypes`, `contextNames`, `linkTypes`, `bodyContentType`, `bodySnippet` (truncated, sanitized). |
| `UsageByUserAppDay.csv` | Pre-aggregated daily usage per user/app/feature: `promptCount`, `responseCount`, `totalInteractions`, `uniqueSessions`. |
| `UsageByAppFeatureDay.csv` | Pre-aggregated daily usage per app/feature: `uniqueUsers`, `promptCount`, `responseCount`, `totalInteractions`, `premiumUsers`, `basicUsers`. |
| `Errors.csv` | One row per user that failed during processing: `userId`, `userPrincipalName`, `errorMessage`, `timestampUtc`. |

### App / feature normalization

`appClass` values returned by Graph are mapped to friendly `app` and `feature` columns:

| `appClass` pattern | `app` | `feature` | `agentId` |
|----|----|----|----|
| `...ConnectedAIApp.Entra.<guid>` | `Connected AI Agent` | `Connected Agent` | extracted GUID |
| `...Copilot.ThirdPartyCopilot` | `Third-Party Agent` | `Third-Party Copilot` | — |
| `...Copilot.BizChat` | `Copilot Chat` | `Copilot Chat (Work)` or `Copilot Chat (Web)` (from `conversationType`) | — |
| `...Copilot.Teams` | `Teams` | `Teams Copilot` / `Teams Meeting` / `Teams Chat` | — |
| `...Copilot.Outlook` / `Word` / `Excel` / `PowerPoint` / `OneNote` / `Loop` / `Whiteboard` | matching app name | `<App> Copilot` | — |
| anything else | `Unknown` | last segment of `appClass` | — |

### Notes

- Run with `-MaxUsers 10` first to validate auth and permissions before exporting your full tenant.
- For large tenants, run during off-peak hours and consider increasing `-DelayBetweenUserRequestsMilliseconds` if you see frequent 429s.
- The `Errors.csv` file is your friend — if `Interactions.csv` looks light, check it for permission, license, or throttling failures.
- Body content can contain sensitive customer/business information. Treat the output as confidential by default and apply your organization's DLP, retention, and access controls before sharing.

## Applies To

- Microsoft 365 Copilot (Basic and Premium)
- Microsoft Graph beta — Copilot interaction history
- Power BI / Excel reporting on Copilot adoption

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|May 21st, 2026|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.
