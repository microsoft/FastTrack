# M365 Copilot Readiness Assessment

PowerShell script that quickly collects key configuration information from Exchange Online, SharePoint Online, OneDrive, Microsoft Teams, and **Entra ID** to assess Microsoft 365 Copilot deployment readiness.

**New in latest version**: Enhanced with Entra ID external sharing settings and administrator-friendly reporting with clear descriptions for every configuration item.

---

## What it checks

### Exchange Online
* Mailbox inventory and basic configuration
* Connection validation and permissions

### SharePoint Online
* Tenant sharing settings with detailed descriptions
* Site collection inventory (including OneDrive)
* Restricted Access Control (RAC) policies
* Default sharing link configurations
* Anonymous access settings

### Microsoft Teams
* Connection validation
* Teams admin permissions verification

### Entra ID (Azure AD) - **NEW ENHANCED**
* **Authorization Policy**: External user invitation settings and default permissions
* **External Identities Policy**: Guest user lifecycle management (where available)
* **Guest User Settings**: Access restrictions and B2B collaboration controls  
* **Cross-Tenant Access Policy**: Service defaults and custom configurations
* **Guest User Statistics**: Current guest user count and impact assessment
* **Organization Settings**: Contact sync and directory feature configurations

### Licensing & Graph
* Microsoft Graph connection with required scopes
* Copilot license detection and SKU mapping
* Base license eligibility verification
* Comprehensive license inventory

---

## Enhanced Administrator-Friendly Reporting

The script now provides enhanced, administrator-friendly reporting with the following improvements:

### Key Benefits
* **No Technical Guessing**: Every setting includes plain-language explanations
* **Decision Support**: Descriptions help administrators make informed policy decisions
* **Security Awareness**: Clear identification of settings that affect external access
* **Copilot Readiness**: Understand how configurations impact Copilot functionality

### Descriptive Format
All configuration settings include both the actual value and a clear description of what it means:

```json
"AllowInvitesFrom": {
  "Value": "adminsAndGuestInviters",
  "Description": "Who can invite external users (none, adminsAndGuestInviters, adminsGuestInvitersAndAllMembers, everyone)"
}
```

### Enhanced HTML Output
* **Three-Column Tables**: Setting, Value, and Description for maximum clarity
* **Copilot Context**: Explanations of how each setting impacts Copilot usage and security
* **Impact Assessment**: Clear indicators of security considerations and data governance implications

---

## Prerequisites

* **PowerShell:** Windows PowerShell 5.1 or PowerShell 7.x
* **Network access** to Microsoft 365 endpoints for Graph, Exchange Online, SharePoint Online, and Teams
* **Interactive sign-in** capability (unless you adapt for app-only auth; this script is written for interactive admin usage)

### PowerShell modules (auto-installed unless `-SkipModuleInstall`)

| Module                                       | Minimum Version  |
| -------------------------------------------- | ---------------- |
| Microsoft.Graph.Authentication               | 2.8.0            |
| Microsoft.Graph.Identity.DirectoryManagement | 2.8.0            |
| Microsoft.Graph.Search                       | 2.8.0            |
| ExchangeOnlineManagement                     | 3.4.0            |
| MicrosoftTeams                               | 5.6.0            |
| Microsoft.Online.SharePoint.PowerShell       | 16.0.24908.12000 |

> The script imports these modules and will attempt installation for CurrentUser scope if they're missing.

---

## Required permissions / roles

> The script connects **interactively** and uses **read-only** Graph scopes.

* **Graph scopes:**
  `Organization.Read.All`, `Directory.Read.All`, `User.Read.All`, `ExternalItem.Read.All`, `Sites.Read.All`, `ExternalConnection.Read.All`, `Policy.Read.All`
* **Exchange Online:** permissions sufficient to run **`Get-EXOMailbox`** (e.g., **View-Only Recipients** or higher; many tenants grant this via EXO/Exchange admin roles)
* **SharePoint Online:** **SharePoint Administrator** (or **Global Administrator**) is typically required for **`Get-SPOTenant`**
* **Microsoft Teams:** Teams admin-level read permissions are safest; this script only verifies connection

> If your account lacks a given role, the script continues where possible and records a connection failure and/or data errors in the final report.

---

## Parameters

```powershell
PARAMETERS
----------
-OutputPath <String>
    Directory for report outputs. Defaults to current directory (".").
    Example: -OutputPath "C:\Temp\M365Readiness"

-SkipModuleInstall [Switch]
    If specified, the script will NOT attempt to install missing modules.

-SPOAdminUrl <String>
    Optional explicit SharePoint Admin URL (e.g., https://contoso-admin.sharepoint.com).
    If omitted, the script tries to derive it from your tenant's *.onmicrosoft.com domain.
```

---

## Installation & usage

### 1) Clone or download

```powershell
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

### 2) Run the script (interactive)

```powershell
# Basic run, outputs to current directory
.\Get-M365CopilotReadiness.ps1

# Specify output folder
.\Get-M365CopilotReadiness.ps1 -OutputPath "C:\Temp\M365Readiness"

# Provide SPO Admin URL explicitly (if your tenant derivation is special)
.\Get-M365CopilotReadiness.ps1 -SPOAdminUrl "https://contoso-admin.sharepoint.com"

# Skip auto-install of modules (if you pre-installed everything)
.\Get-M365CopilotReadiness.ps1 -SkipModuleInstall
```

> You'll be prompted to sign in for each service connection (Graph, EXO, SPO, Teams). If a connection fails, the script logs the error and continues.

---

## Output files & schema

### `copilot-readiness.json`

High-level structure:

```json
{
  "GeneratedAtUtc": "2025-08-19T14:12:34Z",
  "ScriptDurationSec": 12.34,
  "LearnReferences": [...],
  "Connections": { "Graph": true, "EXO": true, "Teams": true, "SPO": true },
  "Tenant": {
    "DisplayName": "Contoso Ltd",
    "Id": "...",
    "DefaultDomain": "contoso.onmicrosoft.com",
    "VerifiedDomains": [ "contoso.com", "contoso.onmicrosoft.com", ... ],
    "CountryLetterCode": "...",
    "TenantType": "..."
  },
  "Licensing": {
    "CopilotSkuPresent": true,
    "CopilotSkus": [ { "SkuPartNumber": "...", "ConsumedUnits": 123, ... } ],
    "EligibleBaseLicenses": [ { "SkuPartNumber": "MICROSOFT_365_E5", ... } ],
    "AllRelevantSkus": [ ... ]
  },
  "Services": {
    "ExchangeOnline": { "Connected": true, "UserMailboxCount": 123, "Notes": "" },
    "SharePointOnline": {
      "Connected": true,
      "AdminUrl": "https://contoso-admin.sharepoint.com",
      "TenantProperties": { "OneDriveStorageQuota": "...", "SharingCapability": "...", ... },
      "TotalSites": 456,
      "OneDriveSites": 123,
      "SharingSettings": {
        "TenantSharingLevel": {
          "Value": "ExternalUserAndGuestSharing",
          "Description": "Tenant-wide sharing level (Disabled, ExternalUserSharingOnly, ExistingExternalUserSharingOnly, ExternalUserAndGuestSharing)"
        },
        "DefaultSharingLinkType": {
          "Value": "Internal",
          "Description": "Default sharing link type for new sharing links (None, Direct, Internal, AnonymousAccess)"
        },
        "FileAnonymousLinkType": {
          "Value": "Edit",
          "Description": "Anonymous link permissions for files (None, View, Edit)"
        }
      },
      "RacPolicySites": [ ... ],
      "RestrictedSites": [ ... ],
      "Notes": ""
    },
    "Teams": { "Connected": true },
    "EntraId": {
      "Connected": true,
      "AuthorizationPolicy": {
        "AllowInvitesFrom": {
          "Value": "adminsAndGuestInviters",
          "Description": "Who can invite external users (none, adminsAndGuestInviters, adminsGuestInvitersAndAllMembers, everyone)"
        },
        "AllowEmailVerifiedUsersToJoinOrganization": {
          "Value": true,
          "Description": "Whether email-verified users can join the organization without invitation"
        },
        "DefaultUserRolePermissions": { ... }
      },
      "ExternalSharingSettings": {
        "AllowExternalIdentitiesToLeave": {
          "Value": true,
          "Description": "Whether external users can leave the organization on their own"
        },
        "AllowDeletedIdentitiesDataRemoval": {
          "Value": true,
          "Description": "Whether data is automatically removed when external identities are deleted"
        }
      },
      "GuestUserSettings": { ... },
      "CrossTenantAccessPolicy": {
        "IsServiceDefault": {
          "Value": true,
          "Description": "Whether this policy uses service defaults (true) or has custom configuration (false)"
        }
      },
      "GuestUserStatistics": {
        "TotalGuestUsers": {
          "Value": 42,
          "Description": "Number of guest users currently in the tenant"
        },
        "Impact": {
          "Value": "External users present",
          "Description": "Potential impact on Copilot data access and security considerations"
        }
      },
      "OrganizationSettings": { ... },
      "Notes": ""
    },
    "Graph": { "Connected": true, "Scopes": [ "Organization.Read.All", ... ] }
  }
}
```

### `copilot-readiness.html`

A compact, readable dashboard summarizing:

* Connection status per service
* Licensing highlights (base/Copilot)
* Basic Exchange / SPO / OneDrive signals
* **Enhanced Entra ID external sharing and guest user configuration with descriptions**
* **Improved SharePoint sharing settings with contextual explanations**
* **Three-column tables showing Setting, Value, and Description for better admin understanding**
* **Contextual guidance about how settings impact Copilot usage and security**
* Links to Microsoft Learn references
* Error/notes section (if any)

---

## Troubleshooting

### Common Issues

* **Graph connection fails / consent prompts:**
  Ensure your account can grant or has admin consent for the read-only scopes listed above. Retry after consent or run as an admin with sufficient rights.

* **`Get-SPOTenant` access denied:**
  You likely need the **SharePoint Administrator** or **Global Administrator** role.

* **`Get-EXOMailbox` access denied / throttled:**
  Ensure you have Exchange permissions (View-Only Recipients or above). Large tenants may throttle; rerun or scope with your own adaptation if needed.

* **Entra ID policy access denied:**
  The script requires `Policy.Read.All` permissions to retrieve authorization and external identity policies. Ensure your account has sufficient permissions or admin consent has been granted for this scope.

* **External Identities Policy warnings:**
  If you see informational messages about External Identities Policy not being available, this is expected behavior in many tenant configurations. This policy is only available in tenants with specific licensing (like Azure AD Premium P2) or certain configurations.

* **Teams connection fails but others succeed:**
  This does not block report generation; it will be recorded as not connected. Verify the **MicrosoftTeams** module is current and that your account has Teams admin access.

* **Module import/installation errors:**
  Use `-SkipModuleInstall` if your environment restricts `Install-Module`, and pre-install the required modules with your standard process (e.g., internal repository).

---

## Author & date

* **Author:** John Cummings ([john@jcummings.net](mailto:john@jcummings.net))
* **Date:** August 20, 2025

---

## Notes for contributors

* This script currently performs **readiness heuristics** with a "best effort" connection model and light signals. Pull requests that add deeper checks (e.g., detailed Teams/EXO settings, network egress validation, Purview/Defender signals, richer licensing mapping) are welcome—please keep output backward-compatible or gate behind a switch.
* If you contribute app-only authentication support, add a separate section in this README with Azure AD app registration steps and exact Graph permissions (Application) required.
