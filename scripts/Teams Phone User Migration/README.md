
# Microsoft FastTrack Open Source - Teams Phone User Migration example scripts

Pair of scripts created as an example of a bulk two-phase user voice migration, both of which read a CSV of users with columns for voice-related policies, phone number, and emergency location to assign.

An example CSV is included - [Contoso_List_Users_TeamsVoicePoliciesAndNumbers.csv](Contoso_List_Users_TeamsVoicePoliciesAndNumbers.csv)

[Voice related policies - user assignment - Phase 1.ps1](Voice%20related%20policies%20-%20user%20assignment%20-%20Phase%201.ps1) - This script reads the CSV file and assigns the voice-related policies that are listed for each user. It will also check for disabled users or unlicensed users, and log errors encountered. This script is intended to be run in the days prior to voice migration day, and will not assign a phone number nor will activate the dial pad in Teams.

[Phone Number and EV - user assignment - Phase 2 - Cutover.ps1](Phone%20Number%20and%20EV%20-%20user%20assignment%20-%20Phase%202%20-%20Cutover.ps1) - This script reads the CSV file and assigns the phone numbers and emergency locations that are listed for each user. In the case of location, if only City is filled in and not LocationID, then it will pick the first emergency location for that city. If there are cities with multiple emergency addresses, make sure to fill out the LocationID column for applicable users. The scripot will log any errors encountered.

## Prerequisites

Install latest Microsoft Teams PowerShell Module

```PowerShell
Install-Module MicrosoftTeams
```

## Usage

Phase 1 - assign voice-related policies ahead of voice migration day. The script will connect to Teams PowerShell, ask for an input CSV, and assign voice policies per the input CSV.

```PowerShell
.\Voice related policies - user assignment - Phase 1.ps1
```

Phase 2 - assign phone numbers and emergency addresses on voice migration day. The script will connect to Teams PowerShell, ask for an input CSV, and assign phone numbers and locations per the input CSV.

```PowerShell
.\Phone Number and EV - user assignment - Phase 2 - Cutover.ps1
```

## Applies To

- Microsoft Teams

## Author

|Author|Last Update Date
|----|--------------------------
|Laure Van der Hauwaert|Oct 21, 2024

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
