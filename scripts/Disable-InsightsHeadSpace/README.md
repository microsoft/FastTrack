---
title: Disable-InsightsHeadSpace
type: script
category: PowerShell
summary: Disable the retired Headspace feature in Viva Insights for every user with a Personal Insights service plan.
author: Dean Cron
version: 1.0.0
published: "2024-07-18"
updated: "2024-07-19"
tags:
  - viva-insights
  - headspace
  - administration
  - exchange-online
format: ps1
featured: false
status: archived
whatItIs: >-
  A PowerShell script that uses Microsoft Graph to find users assigned the Exchange Analytics or
  MyAnalytics (Personal Insights) service plans and runs `Set-VivaInsightsSettings -Feature headspace
  -Enabled $false` for each of them through Exchange Online. Microsoft has removed Headspace from Viva
  Insights, so it is kept for reference only.
whyUseIt:
  - Reference for how Viva Insights features were disabled per user with `Set-VivaInsightsSettings`.
  - Example of filtering users by service plan ID with the Microsoft Graph PowerShell module.
howToUse: |-
  1. Install the Microsoft Graph PowerShell (`Microsoft.Graph.Users`) and Exchange Online (`ExchangeOnlineManagement`) modules.
  2. Run the script and sign in to Microsoft Graph (`User.Read.All`) and Exchange Online when prompted:

     ```powershell
     .\Disable-InsightsHeadSpace.ps1
     ```
prerequisites:
  - "Microsoft.Graph.Users and ExchangeOnlineManagement PowerShell modules"
  - "Account that can consent to the User.Read.All Microsoft Graph scope and run Set-VivaInsightsSettings in Exchange Online"
---

> **Archived:** Microsoft removed Headspace content from Viva Insights in July 2024 (Message Center MC823285), so there is nothing left for this script to disable. It is kept for reference only and no replacement is needed.

# Microsoft FastTrack Open Source - Disable-InsightsHeadSpace

This sample script disables HeadSpace in Viva Insights for all users with a Personal Insights service plan

## Usage

### Prerequisites

- The script must be run by a user with the appropriate permissions to connect to Exchange Online and MSOL
  
### Parameters

None

### Execution

Run the script like so:

	.\Disable-InsightsHeadSpace.ps1

## Applies To

- M365 / Personal Insights in Viva

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|July 18th, 2024|

## Issues

Please report any issues you find to the [issues list](/issues).

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
