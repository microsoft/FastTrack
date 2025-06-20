# Microsoft FastTrack Open Source - Get-AllEntraUsers.ps1

This sample script generates a report of all users present in the target Entra tenant. This can be used to build the Organizational Data file which is later uploaded into M365 or Viva Advanced Insights.

#### NOTE: This is similar to Get-GroupsMembersManagers.ps1, but focuses on user info only, not groups and their members.

## Usage

### Pre-Requisites

- [Microsoft Graph Module](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0) 

### Parameters

None

### Output

The following properties are exported:

|DisplayName|UserPrincipalName|Department|ManagerUPN 

### Execution

Run the script like so:

	.\Get-AllEntraUsers.ps1
    
## Applies To

- M365 / Organizational Data Import / Viva Insights 

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 13th, 2025|
|Alejandro Lopez, Microsoft|June 13th, 2025|


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

