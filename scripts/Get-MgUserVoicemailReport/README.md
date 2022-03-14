# Microsoft FastTrack Open Source - Get-MgUserVoicemailReport

This script uses Graph API to read and save a report of all voicemail messages for a specific or all users. It depends on the Graph SDK for PowerShell and Application permissions to read user messages.

## Pre-requisites

- Install the [Graph SDK for PowerShell]("https://docs.microsoft.com/en-us/graph/powershell/installation")
- Create an [Azure AD application]("https://docs.microsoft.com/en-us/graph/powershell/app-only?tabs=azure-portal") and grant 'Mail.Read' permissions to it

## Usage

**Important:** Before running the script, connect to Graph in PowerShell by running `Connect-MgGraph` with [App-only authentication](https://docs.microsoft.com/en-us/graph/powershell/app-only?tabs=azure-portal#authenticate).

To create a report of the voicemails of all users, simply run the script:

`Get-MgUserVoicemailReport.ps1`

To specify a date range, use one or both of the `ReceivedDateTimeStart` and `ReceivedDateTimeEnd` parameters:

`Get-MgUserVoicemailReport.ps1 -ReceivedDateTimeStart "2022-01-01" -ReceivedDateTimeEnd "2022-03-31"`

To create a report for only a single specific user, provide the username with the `User` parameter:

`Get-MgUserVoicemailReport.ps1 -User "userA@domain.com"`

To specify the export file, use `-ExportCsvFilePath`.

`Get-MgUserVoicemailReport.ps1 -ExportCsvFilePath "C:\Users\me\Downloads\VMUserReport.csv"`

**Note:** By default the script saves a timestamped file to the same directly where the script was run.

## Output

The saved CSV file report contains these columns:

* userPrincipalName
* mail
* receivedDateTime
* fromName
* fromAddress
* subject
* id

## Applies To

- Exchange Online
- Microsoft Teams

## Author

|Author|Original Publish Date
|----|--------------------------
|David Whitney|March 14, 2022|

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
