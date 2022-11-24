# Microsoft FastTrack Open Source - TMS-GRPRX (Group Restriction)
A tool to manage Microsoft 365 group creation restrictions.

![TMS-GRPRX logo](https://i.postimg.cc/hPyhL5GK/TMS-GRPRX.png)

## Requirements
- Windows OS
- [AzureADPreview](https://learn.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0) PowerShell module

## Usage
1. Run the executable (or script)
2. Sign in with a Microsoft 365 admin account (the application will use AzureADPreview\Connect-AzureAD)
3. Choose an option
    - **Enable restriction**: with this option you can provide a security group name and select Enable to restrict Microsoft 365 group creation only to the members of the provided security group
    - **Check restriction**: with this option you can verify if Microsoft 365 group creation restriction is already in place and the id of the security group the restriction is scoped to
    - **Disable restriction**: with this option you can disable Microsoft 365 group creation restriction

> If the executable crashes, comment out line 16 in the script and run it to look for errors.

## Other
- The tool was built using PowerShell and compiled with [PS2EXE](https://www.powershellgallery.com/packages/ps2exe/1.0.4)
- For further details on group restriction, see: https://aka.ms/create-o365-groups

## Examples
## Sign in
![Sign in example](https://i.postimg.cc/qq4cjzX3/KZ1dsze-NVt.png)

## Enable restriction
![Enable restriction example](https://i.postimg.cc/kGTSsw-g0/xcrxrpk-FGO.png)

## Check restriction
![Check restriction example](https://i.postimg.cc/GmG2hq1b/Dv-VVq-ZUVpt.png)

## Disable restriction
![Disable restriction example](https://i.postimg.cc/FKGh76CX/3chur5-D4f-P.png)

## Applies To
- Microsoft 365 (Outlook, SharePoint, Yammer, Microsoft Stream, Microsoft Teams, Planner, Power BI, Project for the web / Roadmap)

## Author
| Author         | Date     |
|--------------|-----------|
| Mihai Filip | 11/23/2022      |

## Issues
Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

## Support
> The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

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