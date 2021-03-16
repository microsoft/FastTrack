# Microsoft FastTrack Open Source - Teams Audio Conferencing Snippets

Here are a few common Teams Audio Conferencing configuration PowerShell snippets that our customers rely on to update user settings for Audio Conferencing.

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

If you need a quick start creating an input csv for the below examples, download your full list of Skype/Teams users and save off the desired user rows to be the input CSV file from this export:

```PowerShell
Get-CsOnlineUser -ResultSize Unlimited | Export-Csv "C:\path\to\allusers.csv"
```

## Limit call me/dial-out from an Audio Conferencing-enabled Teams meeting

By default, all users can dial out to any destination with the call me at (sometimes referred to as "join with phone") and add PSTN participant feature. This is subject to the included dial out minute pool for [Zone A](https://docs.microsoft.com/en-us/microsoftteams/audio-conferencing-zones) target numbers and [Communication Credits](https://docs.microsoft.com/en-us/microsoftteams/what-are-communications-credits) for non-Zone A target numbers and minute pool overage dial outs. For full details on this, read the ["Dial-Out"/"Call Me At" minutes benefit docs page](https://docs.microsoft.com/en-us/microsoftteams/audio-conferencing-subscription-dial-out).

You may want to adjust which destinations your users can dial out to, or disable it outright. To do so in bulk, we must use the `Grant-CsDialOutPolicy` command for each user to limit Communications Credits consumption. See the [Outbound calling restrictions policies docs page](https://docs.microsoft.com/en-us/microsoftteams/outbound-calling-restriction-policies) for full details. Following are a couple examples of using a CSV file input to do so. 

### Disable dial out completely from Audio Conferencing-enabled meetings:

**_Input CSV needs a column with name UserPrincipalName._**

```PowerShell
$nodialoutusers = Import-Csv "C:\path\to\nodialoutusers.csv"

foreach ($user in $nodialoutusers) {
    Grant-CsDialOutPolicy -Identity $user.UserPrincipalName -PolicyName "DialoutCPCDisabledPSTNInternational"
}
```

If you want to disable this for **all users** who are not already set so, a CSV input is not required and instead we can simply run against all enabled users:

```PowerShell
Get-CsOnlineUser -Filter {Enabled -eq $true -and OnlineDialOutPolicy -ne "DialoutCPCDisabledPSTNInternational"} | Grant-CsDialOutPolicy -PolicyName "DialoutCPCDisabledPSTNInternational"
```

### Limit dial out to only Zone A countries from Audio Conferencing-enabled meetings:

***Input CSV needs a column with name UserPrincipalName.***

```PowerShell
$zoneadialoutusers = Import-Csv "C:\path\to\zoneadialoutusers.csv"

foreach ($user in $zoneadialoutusers) {
    Grant-CsDialOutPolicy -Identity $user.UserPrincipalName -PolicyName "DialoutCPCZoneAPSTNInternational"
}
```

## Disable toll-free dial-in for users

By default, all users are allowed to use toll-free bridge numbers and will have them added to their meeting invites assuming they are enabled for Audio Conferencing and a toll-free number suitable for their region is activated in the tenant. Both the acquisition and ongoing use of toll-free dial-in require a positive [Communication Credits](https://docs.microsoft.com/en-us/microsoftteams/what-are-communications-credits) balance.

You may want to [disable the use of toll-free dial-in numbers for some users](https://docs.microsoft.com/en-us/microsoftteams/disabling-toll-free-numbers-for-specific-teams-users) while leaving it enabled for others. To do so in bulk requires a PowerShell command run per user. Here's an example of how to do so with a CSV input.

***Input CSV needs a column with name UserPrincipalName.***

```PowerShell
$notollfreeusers = Import-Csv "C:\path\to\notollfreeusers.csv"

foreach ($user in $notollfreeusers) {
    Set-CsOnlineDialInConferencingUser -Identity $user.UserPrincipalName -AllowTollFreeDialIn $false
}
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
