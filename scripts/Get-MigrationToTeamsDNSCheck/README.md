# Microsoft FastTrack Open Source - MigrationToTeamsDNSCheck

Powershell Script used to query all Skype for Business hardcoded DNS's to help you migrate the tenant to TeamsOnly Mode

## Usage

Once you execute the script, you will be prompt to enter your Office 365 credentials.
The credentials will be used to obtain all the domains automatically from the tenant - "Get-AzureADDomain".
#### The script will detect the DNS that does not exists.
#### The script will detect the DNS that are poiting to Online.
#### The script will detect the DNS that are poiting to On-Premises.
#### The script will detect the A records.
####
#### ----> Always use the most recent version of the Script <----
![Tool](https://github.com/tiagoroxo/Fastrack/Get-MigrationToTeamsDNSCheck/blob/main/tool.JPG?raw=true)
## Applies To

- Microsoft Teams
- Skype for Business

## Author

|Author|Original Publish Date
|----|--------------------------
|_Tiago Roxo_|_02/02/2021_|

## Issues

Please report any issues you find to the [issues list](/issues).

_ENSURE THE ISSUES LINK ABOVE IS CORRECT. ADD EXTRA ISSUE DETAILS, IF APPLICABLE. EXAMPLE: "IF YOU GET ERROR X, ENSURE YOU DID CONFIGURATION Y"


_DO NOT DELETE/ALTER THE SECTIONS BELOW_

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
