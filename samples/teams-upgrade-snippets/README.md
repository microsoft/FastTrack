---
title: Teams Upgrade Snippets
type: script
category: PowerShell
summary: PowerShell snippets to upgrade Skype for Business users to Teams Only mode and run the Meeting Migration Service.
author: David Whitney
version: 1.0.0
published: "2020-01-30"
updated: "2021-03-16"
tags:
  - teams
  - teams-upgrade
  - skype-for-business
  - meeting-migration
  - snippets
format: md
featured: false
status: archived
whatItIs: >-
  A README of PowerShell snippets, run with the MicrosoftTeams module, for the journey from Skype for
  Business to Teams Only mode. They upgrade a list of users with Grant-CsTeamsUpgradePolicy, run a
  server-side batch policy assignment for long lists, and queue and report on the Meeting Migration
  Service after an org-wide upgrade. Kept for reference because Skype for Business Online has been
  retired.
whyUseIt:
  - Reference for the upgrade policy, batch policy assignment, and Meeting Migration Service cmdlets.
  - Example of using a CSV of users with TeamsUpgradePolicy and `New-CsBatchPolicyAssignmentOperation`.
howToUse: |-
  1. Install the MicrosoftTeams PowerShell module (2.0.0 or later) and connect with `Connect-MicrosoftTeams`.
  2. Prepare a CSV with a `UserPrincipalName` column.
  3. Run the snippet you need from the README, for example to upgrade a list of users to Teams Only mode:

     ```powershell
     $upgradeusers = Import-Csv "C:\path\to\upgradeusers.csv"

     foreach ($user in $upgradeusers) {
         Grant-CsTeamsUpgradePolicy -Identity $user.UserPrincipalName -PolicyName "UpgradeToTeams"
     }
     ```
prerequisites:
  - "MicrosoftTeams PowerShell module, version 2.0.0 or later"
  - "CSV with a UserPrincipalName column for the bulk snippets"
---

> **Archived:** These snippets cover upgrading Skype for Business users to Teams Only mode and running the Meeting Migration Service. Skype for Business Online was retired on July 31, 2021, and Skype for Business Server 2015 and 2019 reached end of support on October 14, 2025, so this sample is kept for reference. See [Skype for Business Online retirement](https://learn.microsoft.com/microsoftteams/skype-for-business-online-retirement) and the current Teams upgrade guidance on Microsoft Learn instead.

# Microsoft FastTrack Open Source - Teams Upgrade Snippets

Here are a few common Teams Upgrade PowerShell snippets that our customers have found useful in their journey to Teams Only mode.

## Usage

These snippets are not provided as PowerShell scripts as they are only a few lines each, and would often be run interactively or as a one-off.

Note we do assume the MicrosoftTeams PowerShell module has been installed and signed in. For assistance, please see the following docs page:

- [Microsoft Teams PowerShell](https://docs.microsoft.com/en-us/MicrosoftTeams/teams-powershell-install)

After installing the Microsoft Teams module, here's an example of connecting to remote Teams/Skype for Business Online PowerShell:

```PowerShell
Import-Module MicrosoftTeams
Connect-MicrosoftTeams
```

**Note:** Ensure you are running the 2.0.0 (March 2021) or later version of the MicrosoftTeams module. You can verify installed versions with `Get-Module MicrosoftTeams -ListAvailable`, and if needed install the latest update from an elevated PowerShell session with `Update-Module MicrosoftTeams`

## Upgrade a list of users to Teams Only mode

***Input CSV needs a column with name UserPrincipalName.***

```PowerShell
$upgradeusers = Import-Csv "C:\path\to\upgradeusers.csv"

foreach ($user in $upgradeusers) {
    Grant-CsTeamsUpgradePolicy -Identity $user.UserPrincipalName -PolicyName "UpgradeToTeams"
}
```

If you need a quick start creating an input csv to start from, download your full list of Skype/Teams users and save off the desired user rows to the ```upgradeusers.csv``` file from this export:

```PowerShell
Get-CsOnlineUser -ResultSize Unlimited | Export-Csv "C:\path\to\exportusers.csv"
```

### Server-side batch upgrade for long list of users

Alternatively, for a long list of users, you can use the new batch policy assignments process. In particular this can help avoid the 60-minute timeout. This batch policy assignment is only available in the Microsoft Teams module, not the Skype for Business Online one.

**Important** It's recommended to break up the batches into groups of about 5000 and not run more than a handful of batches at a time.

```PowerShell
$upgradeusers = Import-Csv "C:\path\to\upgradeusers.csv"

New-CsBatchPolicyAssignmentOperation -PolicyType TeamsUpgradePolicy -PolicyName "UpgradetoTeams" -Identity $upgradeusers.UserPrincipalName -OperationName "Teams Upgrade Batch 1"
```

Report on previous batch policy assignments with ```Get-CsBatchPolicyAssignmentOperation```. With the specific OperationId returned from the above New batch policy assignment or from the list from that Get command, pull complete details of a single batch policy assignment:

```PowerShell
Get-CsBatchPolicyAssignmentOperation -Identity xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Format-List *
```

## Run the Meeting Migration Service after upgrading to Teams Only org-wide

As discussed in the [Meeting Migration Service (MMS) doc article](https://docs.microsoft.com/en-us/skypeforbusiness/audio-conferencing-in-office-365/setting-up-the-meeting-migration-service-mms), Skype for Business meetings will automatically be upgraded to Teams meetings when upgrading individual users to Teams Only mode or Skype for Business with Teams Collaboration and Meetings mode (also called *Meetings First* mode), but will not upgrade meetings automatically when the org-wide setting for Teams Upgrade is flipped to one of these modes. The following snippet will find all users who are in Teams Only mode or Meetings First mode by org-wide setting inheritance, not by individual upgrade mode assignment, and will queue up MMS for them.

```PowerShell
$orgwideupgradeusers = Get-CsOnlineUser -Filter {(Enabled -eq $true) -and (TeamsUpgradePolicy -eq $null)} | where TeamsUpgradeEffectiveMode -in "TeamsOnly","SfBWithTeamsCollabAndMeetings"

foreach ($user in $orgwideupgradeusers) {
    Start-CsExMeetingMigration -Identity $user.UserPrincipalName -SourceMeetingType SfB -TargetMeetingType Teams -Confirm:$false
}
```

### Report on Meeting Migration Service status

```PowerShell
Get-CsMeetingMigrationStatus -SummaryOnly
```

Export MMS attempts that have ended in a Failed status to a CSV file for further investigation:

```PowerShell
Get-CsMeetingMigrationStatus -State Failed | Export-Csv "C:\path\to\MMSFailedreport.csv"
```

## Author

|Author|Last Updated Date
|----|--------------------------
|David Whitney, Microsoft|March 16, 2021|

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
