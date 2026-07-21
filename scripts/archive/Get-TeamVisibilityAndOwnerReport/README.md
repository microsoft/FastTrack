# Microsoft FastTrack Open Source - Teams PowerShell - Get a list of Teams,Owners according to visibility status
## Usage

Script to list all existing Teams. Filters on visibility status (Public or Private). And lists the owners, which are listed in way that's easy to paste into an email for mass mailing if necessary.

Output example:
| GroupID                              | TeamName  | Visibility | Owners                               |
|--------------------------------------|-----------|------------|--------------------------------------|
| zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz | TestTeam  | Public     | user1@contoso.com; user2@contoso.com |
| xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | TestTeam2 | Private    | user3@contoso.com; user4@contoso.com |

Microsoft Teams powershell module can be installed following the instructions at this link: https://aka.ms/AAatf62
 
    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to the defaulted script directory
        .\Get-TeamVisibilityAndOwnerReport.ps1 -GroupVisility Public

    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to specific directory, do not include trailing '\'
        .\Get-TeamVisibilityAndOwnerReport.ps1 -GroupVisility Public -ExportPath "C:\Scripts"

## Applies To
-Teams

## Author

|Author|Original Publish Date
|----|--------------------------
|Brian Baldock|2020-01-14|

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
