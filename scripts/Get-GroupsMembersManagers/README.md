---
title: Get-GroupsMembersManagers
type: script
category: PowerShell
summary: Export Entra group members with manager and profile details to CSV for Viva Insights organizational data uploads.
author:
  - Alejandro Lopez
  - Dean Cron
  - J.G. Parra
version: 1.0.0
published: "2024-07-26"
updated: "2026-04-22"
tags:
  - viva-insights
  - organizational-data
  - entra
  - reporting
format: ps1
featured: false
status: active
whatItIs: >-
  A PowerShell script that uses the Microsoft Graph PowerShell module to report Microsoft Entra group
  members and their managers. An interactive menu lets you export users from all groups, from one group
  chosen by display name, or from a CSV with a UPN column. It writes EntraGroupMembersExport.csv with
  profile details and the manager's UPN.
whyUseIt:
  - Build the file for organizational data uploads in Microsoft 365 or Viva Advanced Insights from existing Entra groups.
  - Include extended profile fields such as job title, department, office location, company, and address details.
  - Target a pilot population with a CSV of UPNs instead of the whole tenant.
howToUse: |-
  1. Install the Microsoft Graph PowerShell module.
  2. Run the script, sign in with consent for the `Group.Read.All` and `User.Read.All` scopes, and choose an option from the menu (all groups, one group, a CSV of UPNs, or exit). The CSV is written to the current directory:

     ```powershell
     .\Get-GroupsMembersManagers.ps1
     ```
prerequisites:
  - "Microsoft Graph PowerShell module"
  - "Account that can consent to the Group.Read.All and User.Read.All Microsoft Graph scopes"
  - "Optional CSV with a UPN column for the CSV option"
---

# Microsoft FastTrack Open Source - Get-GroupsMembersManagers.ps1

This sample script generates a report of Microsoft Entra groups, their members, and their managers. It supports three input modes: all groups, a single group by display name, or users supplied from a CSV file. The output can be used to build the Organizational Data file later uploaded into M365 or Viva Advanced Insights.

## Usage

### Pre-Requisites

- [Microsoft Graph Module](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0) 

### Parameters

None

### Output

The following properties are exported:

| Column | Description |
|---|---|
| GroupName | Source Entra group display name. Blank when CSV mode is used. |
| DisplayName | User display name. |
| JobTitle | User job title. |
| Department | User department. |
| OfficeLocation | User office location. |
| CompanyName | User company name. |
| UsageLocation | User usage location. |
| PreferredLanguage | User preferred language. |
| StreetAddress | User street address. |
| City | User city. |
| State | User state or province. |
| Country | User country or region. |
| PostalCode | User postal code. |
| UserPrincipalName | User sign-in UPN. |
| ManagerUPN | Manager user principal name, when available. |

### Execution

Run the script like so:

	.\Get-GroupsMembersManagers.ps1

When the script starts, choose one of the interactive menu options:

- **1** - Export all users from all Entra groups
- **2** - Export members from one group (search by display name)
- **3** - Export users from a CSV file with a required **UPN** column
- **4** - Exit without exporting
    
## Applies To

- M365 / Organizational Data Import / Viva Insights 

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|July 26th,2024|
|Dean Cron, Microsoft|July 26th, 2024|
|J.G. Parra, Microsoft|April 22nd, 2026|

## Issues

Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
