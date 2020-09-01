# Microsoft FastTrack Open Source - Teams Upgrade Snippets

Here are a few common Teams Upgrade PowerShell snippets that our customers have found useful in their journey to Teams Only mode.

## Usage

These snippets are not provided as PowerShell scripts as they are only a few lines each, and would often be run interactively or as a one-off.

Note we do assume the appropriate Office 365 remote PowerShell session has already been established. For assistance, please see the following docs pages:

- [Skype for Business Online PowerShell](https://docs.microsoft.com/en-us/office365/enterprise/powershell/manage-skype-for-business-online-with-office-365-powershell)

We recommend that you use the new ```Enable-CsOnlineSessionForReconnection``` command after establishing a Skype for Business Online PowerShell session to mitigate the typical 60 minute remote PowerShell session timeout as noted in the [Skype for Business Online remote PowerShell troubleshooting page](https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/diagnose-problems-with-the-skype-for-business-online-connector). For example:

```PowerShell
Import-Module SkypeOnlineConnector
$sfbSession = New-CsOnlineSession
Import-PSSession $sfbSession
Enable-CsOnlineSessionForReconnection
```

## Applies To

- Microsoft Teams
- Skype for Business Online

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
Get-CsOnlineUser -ResultsSize Unlimited | Export-Csv "C:\path\to\exportusers.csv"
```

## Run the Meeting Migration Service after upgrading to Teams Only org-wide

As discussed in the [Meeting Migration Service (MMS) doc article](https://docs.microsoft.com/en-us/skypeforbusiness/audio-conferencing-in-office-365/setting-up-the-meeting-migration-service-mms), Skype for Business meetings will automatically be upgraded to Teams meetings when upgrading individual users to Teams Only mode or Skype for Business with Teams Collaboration and Meetings mode (also called *Meetings First* mode), but will not upgrade meetings automatically when the org-wide setting for Teams Upgrade is flipped to one of these modes. The following snippet will find all users who are in Teams Only mode or Meetings First mode by org-wide setting inheritance, not by individual upgrade mode assignment, and will queue up MMS for them.

```PowerShell
$orgwideupgradeusers = Get-CsOnlineUser -Filter {TeamsUpgradePolicy -eq $null} | where TeamsUpgradeEffectiveMode -in "TeamsOnly","SfBWithTeamsCollabAndMeetings"

foreach ($user in $orgwideupgradeusers) {
    Start-CsExMeetingMigration -Identity $user.UserPrincipalName -SourceMeetingType SfB -TargetMeetingType Teams -Confirm:$false
}
```

### Report on Meeting Migration Service status

```PowerShell
Get-CsMeetingMigrationStatus -SummaryOnly
```

Export MMS queued attempts that have ended in a Failed status to a CSV file for further investigation:

```PowerShell
Get-CsMeetingMigrationStatus -State Failed | Export-Csv "C:\path\to\MMSFailedreport.csv"
```

## Author

|Author|Original Publish Date
|----|--------------------------
|David Whitney, Microsoft|January 30, 2020|

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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
