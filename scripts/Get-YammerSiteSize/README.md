---
title: Get-YammerSiteSize
type: script
category: PowerShell
summary: Report the SharePoint storage used by every site created through Viva Engage (Yammer) communities.
author: Dean Cron
version: 1.0.0
published: "2023-07-20"
updated: "2023-07-20"
tags:
  - viva-engage
  - administration
  - reporting
  - sharepoint
  - storage
format: ps1
featured: false
status: active
whatItIs: >-
  A PowerShell sample that connects to SharePoint Online and Exchange Online, finds the Microsoft 365
  groups whose GroupSku is Yammer, and exports each connected SharePoint site's title, URL, and current
  storage usage to a CSV file. It applies to Viva Engage networks in native mode.
whyUseIt:
  - See how much SharePoint storage Viva Engage communities consume.
  - Identify the largest community sites before storage planning or cleanup.
howToUse: |-
  1. Install the Exchange Online and SharePoint Online PowerShell modules.
  2. Set `$AdminSiteURL` to your tenant's SharePoint admin URL and optionally change `$ReportOutput`.
  3. Run the script and enter your admin credentials when prompted. Sign-in uses `Get-Credential`, which doesn't work for accounts that require MFA:

     ```powershell
     .\Get-YammerSiteSize.ps1
     ```
prerequisites:
  - "Exchange Online and SharePoint Online PowerShell modules"
  - "Admin account with Microsoft 365 Groups and SharePoint Online access that can sign in with a username and password prompt"
---

# Microsoft FastTrack Open Source - Get-YammerSiteSize

This sample script gets all SPO sites created through Yammer community creation and reports the current storage size used in each site.

## Usage

### Prerequisites

There are only 2 variables you may need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. $AdminSiteURL="https://tenant-admin.sharepoint.com"

	Replace the URL with the admin URL for your tenant. Necessary for connecting to SPO via PowerShell.

2. $ReportOutput="c:\temp\YammerSPOStorage{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")

    If you'd like the script to be generated in a specific location, change the path above to reflect your target.

You must have both the Exchange Online and SharePoint Online PowerShell modules installed.

### Parameters

None

### Execution

Once you’ve made and saved those changes, you’re ready to go. To run the script, just call it with no parameters and enter your admin creds when prompted:

	.\Get-YammerSiteSize.ps1

## Applies To

- Yammer / Viva Engage networks in M365 that are in native mode

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|July 20th, 2023|

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
