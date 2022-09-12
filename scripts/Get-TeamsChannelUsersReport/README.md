
# Microsoft FastTrack Open Source - Get-TeamsChannelUsersReport.ps1

Create a CSV file output that contains a row for each user that has a role in each channel of every team in the tenant or specified teams.

## Usage

Report on all teams in the tenant

```PowerShell
.\Get-TeamsChannelUsersReport.ps1 -ExportCSVFilePath "C:\path\to\export.csv"
```

Report on a specific team by its group ID

```PowerShell
.\Get-TeamsChannelUsersReport.ps1 -GroupId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ExportCSVFilePath "C:\path\to\export.csv"
```

Report on teams that the specified user is a member or owner of. Note that at this time it can only retrieve full team memberships due to Graph API limitations. A future update should allow for both full team memberships as well as shared channel-only memberships.

```PowerShell
.\Get-TeamsChannelUsersReport.ps1 -UserId "user@domain.com" -ExportCSVFilePath "C:\path\to\export.csv"
```

Report on all teams, and include incoming shared channels - shared channels that have been shared from other teams into a given team.

**Warning:** The `-IncludeIncomingSharedChannelsInReport` option may add significant time to generating the report depending on shared channel team sharing usage.

```PowerShell
.\Get-TeamsChannelUsersReport.ps1 -ExportCSVFilePath "C:\path\to\export.csv" -IncludeIncomingSharedChannelsInReport
```

### Output columns

- Team Name
- Group ID
- Team Description
- Team Privacy
- Team Is Archived
- Team Classification
- Team Sensivitity Label
- Channel Name
- Channel Membership Type
- Channel Description
- Channel Member Name
- Channel Member Role*
- Channel Member User ID
- Channel Member Email
- Channel Member Organization
- Shared Channel Shared With Team ID
- Shared Channel Shared With Team Name
- Shared Channel Shared With Team Tenant ID
- Shared Channel Shared With Team Organization
- Incoming Shared Channel Host Team ID**
- Incoming Shared Channel Host Tenant ID**
- Incoming Shared Channel Host Organization**

\*Possible values for Channel Member Role:

|Channel Member Role|Description|
|----|----
|owner|Directly assigned owner of channel|
|member|Directly asigned member of channel|
|guest|Team guest via B2B Collaboration, directly assigned member of channel|
|external member|Shared channel member directly assigned externally from another tenant|
|shared team member|Shared channel member via a different team shared to the channel|
|shared host team member|Shared channel member via the host team shared to the channel|
|external shared team member|Shared channel member via an external team from another tenant shared to the channel|

\*\*Only if `-IncludeIncomingSharedChannelsInReport` is specified in parameters while running script

## Applies To

- Microsoft Graph
- Microsoft Teams

## Author

|Author|Last Update Date
|----|--------------------------
|David Whitney|Sept 9, 2022|

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
