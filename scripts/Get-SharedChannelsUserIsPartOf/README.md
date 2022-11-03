# Microsoft FastTrack Open Source - Get-SharedChannelsUserIsPartOf
PowerShell script to fetch the shared channels (in resource tenant) that a given user is member or owner of. The script will output a list of shared channel names and their respective team names or a CSV if specified.

## Requirements
---
- Windows PowerShell
- Microsoft Teams PowerShell module
- A Microsoft 365 account with admin rights

## Usage
---
1. Enable remote scripting in PowerShell with this cmdlet: `Set-ExecutionPolicy Unrestricted`
2. Install the latest Microsoft Teams module for PowerShell: `Install-Module MicrosoftTeams -AllowClobber -Force`
3. Open a PowerShell session and connect to Teams: `Connect-MicrosoftTeams`
4. Change directory to where the script is located (*cd*) and run it:
    > `Get-SharedChannelsUserIsPartOf -UserPrincipalName user@contoso.com`

![Get-SharedChannelsUserIsPartOf.ps1 execution](https://i.postimg.cc/8kryp7xJ/MB8r-By-Bkay.png)

## Examples
---
## Shared channels a user is owner of
> `Get-SharedChannelsUserIsPartOf -UserPrincipalName user@contoso.com -Owner $true`

![Owner example](https://i.postimg.cc/nrYSn5MV/Qs-D8g-NV9o-V.png)

## Export CSV
>`Get-SharedChannelsUserIsPartOf -UserPrincipalName user@contoso.com -CSV $true`

![CSV example](https://i.postimg.cc/52cyhRLQ/n-C0t-PW5-IQV.png)

![CSV example result](https://i.postimg.cc/jdhq1Sxm/c-MJa-Stn-EKs.png)

## Applies To
---
- Microsoft Teams

## Author
---
| Author         | Date     |
|--------------|-----------|
| Mihai Filip | 11/2/2022      |

## Issues
---
Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

## Support
---
> The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct
---
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices
---
Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.