# Microsoft FastTrack Open Source - SimpleGraph module for generic PowerShell access to MS Graph API

This PowerShell module provides a generic but simplified way to access Microsoft Graph API resources with PowerShell. It relies on the Graph authentication provided with the PnP PowerShell module from the Office Dev/SharePoint PnP team.

Please note this module is written as a simple web call-based (and therefore always up to date) alternative to the official [Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell), which fully wraps Graph calls in resource-appropriate cmdlets.

## Usage

The SimpleGraph module allows for simple calls to Graph, while providing flexibity to have complex calls as needed. Basic examples of the commands available:

```PowerShell
Get-SimpleGraphObject users/you@domain.com

$newteam = @{
    "template@odata.bind" = "https://graph.microsoft.com/v1.0/teamsTemplates('standard')";
    "displayName" = "My Sample Team";
    "description" = "My Sample Team's Description"
}
New-SimpleGraphObject teams -Body $newteam

Set-SimpleGraphObject groups/5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad -Body @{"description" = "New Team Description"}

Remove-SimpleGraphObject groups/5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad

Invoke-SimpleGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/you@domain.com" -Method GET -Raw
```

**Before running any of these commands, see the below steps to get connected to Graph and import the SimpleGraph module.**

**Note:** More help on available parameters and examples on the SimpleGraph commands can be seen inline after importing the module, for example:

```PowerShell
help Get-SimpleGraphObject -Full
```

### Authenticate to Graph API

SimpleGraph relies on the SharePoint Online PnP module to authenticate to Graph, so installing and connecting with that module is a required.

#### Install PnP PowerShell module (one time only)

```PowerShell
Install-Module SharePointPnPPowerShellOnline
```

Visit the [PnP PowerShell github](https://github.com/pnp/PnP-PowerShell) for more details.

#### Install SimpleGraph module (one time only)

Download the SimpleGraph.psm1 file and place into the desired location, for example ```C:\Users\you\Scripts\SimpleGraph.psm1```

#### Connect to Graph with SharePoint Online PnP

PnP PowerShell supports many methods of authenticating to Graph. Interactive sessions will typically be able to request the required **Delegated** permission with Scopes. Refer to the specific Graph API call in docs for the required. For example:

```PowerShell
Connect-PnPOnline -Scopes "User.Read.All", "Group.Read.All"
```

Some Graph API calls or scenarios require **Application** permissions, in which case an app must be created in Azure AD with appropriate permissions granted and an application secret created to use for authentication. See the [PnP PowerShell Application Permissions example](https://github.com/pnp/PnP-PowerShell/tree/master/Samples/Graph.ConnectUsingAppPermissions) for more guidance. Example from that reference:

```PowerShell
Connect-PnPOnline -AppId '2994aca5-7ef4-4179-89ff-c1ce18fa052f' -AppSecret 'NvgASDFS4564fas' -AADDomain 'techmikael.onmicrosoft.com'
```

#### Import SimpleGraph module

```PowerShell
Import-Module "C:\Users\you\Scripts\SimpleGraph.psm1"
```

## Applies To

- Microsoft Graph API
- Microsoft PowerShell

## Author


|Author|Original Publish Date
|----|--------------------------
| David Whitney | October 15, 2020 |

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
