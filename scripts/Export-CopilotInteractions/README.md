---
title: Export-CopilotInteractions
type: script
category: PowerShell
summary: >-
  Export licensed Microsoft 365 Copilot users' prompts and responses from Graph into analysis-ready CSV datasets.
author: Alejandro Lopez
version: 2.0.0
published: "2026-05-21"
updated: "2026-10-29"
tags:
  - copilot
  - graph
format: ps1
whatItIs: >-
  A PowerShell exporter for Microsoft 365 Copilot enterprise interaction history that writes
  normalized interactions, users, errors, and pre-aggregated usage CSVs for users with an eligible
  Microsoft 365 Copilot license. It does not collect unlicensed Copilot Chat (Basic) usage.
whyUseIt:
  - Feed Power BI, Excel, or another analytics tool with user-level interaction data.
  - Use app-only client-secret or certificate authentication.
  - Handle throttling, per-user failures, Copilot license detection, and app/feature normalization during export.
howToUse: >-
  Install `Microsoft.Graph.Authentication`, grant the documented application permissions with
  admin consent, and test with a certificate:


  ```powershell

  .\Export-CopilotInteractions.ps1 -TenantId "<tenant-id>" -ClientId "<app-id>" -CertificateThumbprint "<thumbprint>" -MaxUsers 10

  ```


  Review `Errors.csv`, then remove the user cap for the full export.
prerequisites:
  - PowerShell 5.1 or later
  - Microsoft.Graph.Authentication module
  - Eligible Microsoft 365 Copilot license for each user being exported
  - User.Read.All, LicenseAssignment.Read.All, and AiEnterpriseInteraction.Read.All application permissions
  - Entra app registration with admin consent and a client secret or certificate
---

# Microsoft FastTrack Open Source - Export-CopilotInteractions

Exports Microsoft 365 Copilot user-level interaction history (prompts and AI responses) for users with an **eligible Microsoft 365 Copilot license**. Produces a set of CSV files designed to feed Power BI, Excel, or any downstream analytics tool.

Interaction data is pulled from the Microsoft Graph beta endpoint:

```
/beta/copilot/users/{id}/interactionHistory/getAllEnterpriseInteractions
```

### Licensing scope: Copilot Chat (Basic) usage is not collected

Microsoft's [`getAllEnterpriseInteractions` documentation](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/ai-services/interaction-export/aiinteractionhistory-getallenterpriseinteractions) requires a Microsoft 365 Copilot license with the **Microsoft Copilot with Graph-grounded chat** service plan. This exporter therefore limits processing to users with an eligible license. It does **not** collect Copilot Chat (Basic) usage from users without that license.

The API response does not contain a paid/unpaid license-status field. This script calculates `copilotTier` from **current directory license assignments**, not from the interaction payload or the user's license at the time of each historical interaction. `Premium` is retained as a compatibility label for eligible users; it is not evidence that the API supports a separate Basic tier.

For Copilot Chat usage by users **without** a Microsoft 365 Copilot license, use one of these usage-metrics reports instead:

- [Microsoft Copilot Chat usage report](https://learn.microsoft.com/microsoft-365/admin/activity-reports/microsoft-copilot-usage) in the Microsoft 365 admin center, which supports CSV export.
- [Copilot Dashboard data export](https://learn.microsoft.com/viva/insights/org-team-insights/export-copilot-metrics) in Viva Insights, including **Copilot Chat metrics (without Copilot license)**. This export is in public preview and has separate licensing and access prerequisites; see the linked documentation.

These are usage-metrics exports, not exports of actual prompts and responses. This script does not call those reports or Purview audit APIs.

### Features

- Detects the required Copilot service plan (`3f30311c-6b1e-48a4-ab79-725b469da960` / `M365_COPILOT_BUSINESS_CHAT`) using each user's `assignedLicenses` and `assignedPlans`, joined to the tenant's `subscribedSkus`. This covers standalone licenses and qualifying bundles, such as Microsoft 365 E7.
- Requires the plan to be enabled for an assigned license and have an `Enabled` or `Warning` user capability status. `Warning` is a grace period in which the plan remains available for normal use.
- Uses only explicitly mapped `Premium` SKUs as a fallback when a subscribed SKU has no service plan metadata. Even then, an available, configured service plan ID must be present for the user and not disabled for that license.
- Retrieves available interaction history per eligible user and normalizes it into a flat CSV
- Generates two pre-aggregated usage views ready for Power BI:
  - **Usage by user, app, feature, and day**
  - **Usage by app, feature, and day**
- Supports app-only client secret and certificate authentication
- Built-in retry with exponential backoff and `Retry-After` handling for 429 / 5xx responses
- Throttling-friendly delay between per-user calls (configurable)
- Per-user error CSV so a single failure never stops the run
- UTF-8 CSVs with header-only output when a dataset is empty
- Body content snippet is sanitized (control characters stripped, newlines collapsed, capped at 500 characters)

### Important notes

- This script uses **Microsoft Graph beta** APIs. Beta APIs are subject to change and are not supported for production use.
- Only users with an **eligible Microsoft 365 Copilot license** are exported. See [Licensing scope](#licensing-scope-copilot-chat-basic-usage-is-not-collected).
- The interaction-export API supports **application permissions only**. Delegated interactive sign-in is not supported.
- `getAllEnterpriseInteractions` **does NOT include Copilot Studio agent interactions**. It covers Microsoft 365 Copilot surfaces (Copilot Chat, Outlook, Word, Excel, PowerPoint, OneNote, Loop, Whiteboard, Teams) and Connected AI Agents / Third-Party Copilot agents.
- The `bodySnippet` column in `Interactions.csv` can contain **actual user prompt text and AI response content**. Review privacy, legal, data retention, and compliance requirements before exporting or sharing the output.
- Microsoft can change service plan IDs and SKU part numbers. Override license detection with `-CopilotServicePlans` or `-SkuTierMap` when needed.

### Prerequisites

- **PowerShell 5.1** or later (PowerShell 7+ also supported)
- **Microsoft.Graph.Authentication** PowerShell module:

  ```powershell
  Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
  ```

- **Microsoft Graph application permissions**, with admin consent:
  - `User.Read.All`
  - `LicenseAssignment.Read.All`
  - `AiEnterpriseInteraction.Read.All`

- An Entra ID app registration with a client secret or certificate.

Directory lookups use the app-only-compatible [`users`](https://learn.microsoft.com/graph/api/user-list) and [`subscribedSkus`](https://learn.microsoft.com/graph/api/subscribedsku-list) endpoints. The script does not call `/users/{id}/licenseDetails`, which [does not support application permissions](https://learn.microsoft.com/graph/api/user-list-licensedetails).

### Parameters

| Parameter | Description |
|----|----|
| `-TenantId` | Microsoft Entra tenant ID or verified domain. |
| `-ClientId` | Application (client) ID. Required. |
| `-ClientSecret` | App secret as a `SecureString`. Use `Read-Host -AsSecureString` to avoid putting secrets in shell history. |
| `-CertificateThumbprint` | Certificate thumbprint installed in the current user's certificate store. Use instead of `-ClientSecret`. |
| `-OutputDirectory` | Folder for the CSV output. Defaults to the script directory. |
| `-StartDate` | Start of the export window. Defaults to UTC now minus 30 days. |
| `-EndDate` | End of the export window. Defaults to UTC now. |
| `-MaxUsers` | Caps eligible Copilot users attempted, including users whose interaction requests fail. `0` = no cap. Useful for pilot runs. |
| `-DelayBetweenUserRequestsMilliseconds` | Throttling-friendly delay between per-user Graph calls. Defaults to `200`. |
| `-CopilotServicePlans` | Service plan IDs or names identifying Microsoft 365 Copilot. Defaults to `3f30311c-6b1e-48a4-ab79-725b469da960` and `M365_COPILOT_BUSINESS_CHAT`. User availability and per-license disabled plans are checked. |
| `-SkuTierMap` | Fallback hashtable of SKU part numbers mapped to `Premium`, used only when SKU service plan metadata is empty and an available, configured service plan ID is assigned to the user. Other tier mappings are ignored with a warning. |
| `-IncludeAllUsers` | Enumerate **all** directory users instead of only users with an assigned license. This does not bypass Copilot eligibility checks. |

> This script applies date filtering **client-side** after retrieval. This is an implementation choice, not a claim that the API lacks date-filter support.

### Execution

**App-only with certificate (first run with a small user cap):**

```powershell
.\Export-CopilotInteractions.ps1 `
  -TenantId '<tenant-id>' `
  -ClientId '<app-id>' `
  -CertificateThumbprint '<thumbprint>' `
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
| `Users.csv` | One row per eligible user: `userId`, `displayName`, `userPrincipalName`, `copilotTier` (always `Premium`), `licenses` (semicolon-delimited SKU part numbers granting Copilot). |
| `Interactions.csv` | One row per interaction (prompt or AI response). Columns include `userId`, `userPrincipalName`, `interactionId`, `sessionId`, `appClass`, friendly `app` and `feature`, `agentId`, `interactionType` (`userPrompt` / `aiResponse`), `conversationType`, `createdDateTime`, `activityDate`, `copilotTier`, `contextTypes`, `contextNames`, `linkTypes`, `bodyContentType`, `bodySnippet` (truncated, sanitized). |
| `UsageByUserAppDay.csv` | Pre-aggregated daily usage per user/app/feature: `promptCount`, `responseCount`, `totalInteractions`, `uniqueSessions`. |
| `UsageByAppFeatureDay.csv` | Pre-aggregated daily usage per app/feature: `uniqueUsers`, `promptCount`, `responseCount`, `totalInteractions`, `premiumUsers`. |
| `Errors.csv` | One row per user that failed during processing: `userId`, `userPrincipalName`, `errorMessage`, `timestampUtc`. |

The run summary includes `UsersSkippedWithoutCopilotLicense`: users checked but skipped because no eligible, available Copilot plan was found. Missing required license metadata is recorded as an error instead of being silently treated as an unlicensed user.

### Upgrading from 1.x

- `basicUsers` has been removed from `UsageByAppFeatureDay.csv`. Update Power BI, Excel, or other consumers that reference that column. It did not establish support for unlicensed users.
- `copilotTier` remains for compatibility and is always `Premium` for exported users.
- `-Interactive` has been removed. Supply `-TenantId`, `-ClientId`, and either `-ClientSecret` or `-CertificateThumbprint`.
- Existing app registrations need the `LicenseAssignment.Read.All` **application permission** and admin consent. This script no longer uses `Reports.Read.All`.
- Custom `-SkuTierMap` entries mapped to `Basic` or any value other than `Premium` are ignored. They cannot enable Basic exports or override a disabled plan.

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

> The `Copilot Chat` app in these files represents activity by eligible Copilot-licensed users. It is not a separate Copilot Chat (Basic) usage dataset. Work/web conversation labels do not identify paid versus unpaid users.

### Notes

- Run with `-MaxUsers 10` first to validate auth and permissions before exporting your full tenant.
- For large tenants, run during off-peak hours and consider increasing `-DelayBetweenUserRequestsMilliseconds` if you see frequent 429s.
- The `Errors.csv` file is your friend — if `Interactions.csv` looks light, check it for permission, license, or throttling failures.
- Body content can contain sensitive customer/business information. Treat the output as confidential by default and apply your organization's DLP, retention, and access controls before sharing.

## Applies To

- Microsoft 365 Copilot (users with an eligible Microsoft 365 Copilot license)
- Microsoft Graph beta — Copilot interaction history
- Power BI / Excel reporting on Copilot adoption

## Version history

| Version | Date | Changes |
|----|----|----|
| 2.0.0 | October 29, 2026 | Corrected licensing scope, added service-plan-based eligibility checks and app-only-compatible license lookups, removed unsupported interactive authentication and the `basicUsers` column, and added skipped-user reporting. |
| 1.0.0 | May 21, 2026 | Initial release. |

See [CHANGELOG.md](CHANGELOG.md) for migration details.

## Offline regression tests

With Pester 5 installed, run from the repository root:

```powershell
Invoke-Pester -Path .\scripts\Export-CopilotInteractions\tests\Export-CopilotInteractions.Tests.ps1
```

The tests use synthetic users and mocked Graph requests. They do not authenticate to a tenant or export real user content.

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
