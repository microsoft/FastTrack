# Microsoft FastTrack Open Source - SimpleGraph module for generic PowerShell access to MS Graph API

This PowerShell module provides a generic but simplified way to access Microsoft Graph API resources with PowerShell. It relies on the Graph authentication provided with the [MSAL.PS PowerShell module](https://github.com/AzureAD/MSAL.PS).

Visit the [Microsoft Graph API REST API reference](https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0) for complete details on how to make requests against Graph API with HTTPS, which is what this module uses.

Please note this module is written as a simple web call-based (and therefore always up to date) alternative to the official [Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell), which fully wraps Graph calls in resource-appropriate cmdlets.

## Authenticate and connect to Graph API

SimpleGraph relies on the MSAL.PS PowerShell module to authenticate to Graph, so installing that module is required before using SimpleGraph. Any authentication to Graph also requires an application to be created in the tenant to be the context for authentication.

#### Create an application in Azure AD for Graph authentication (one time only)

To authenticate to Graph, you will need to create an application registration in your tenant's Azure AD. Brief steps below, and see the [Graph App registration docs](https://docs.microsoft.com/en-us/graph/auth-register-app-v2) for full details.

1. Navigate to Azure AD's **App Registration** page
2. Start to create a new app with **New registration**
3. Give a meaningful name to the app, keep other defaults, and click **Register**
4. Once created, go to **Authentication** within the app page and click **+Add a platform**
5. Select **Mobile and desktop applications** and check the box next to the Redirect URIs entry for `https://login.microsoftonline.com/common/oauth2/nativeclient`
6. Click **Configure** in the flyout and then **Save** at the top
7. _Optionally_, create a client secret or upload a client certificate and add appropriate API permissions for Graph to be used for direct sign-in Application contexts (vs Delegated user sign-in)

#### Install MSAL.PS module for Graph authentication (one time only)

```PowerShell
Install-Module MSAL.PS
```

#### Install SimpleGraph module (one time only)

Download the SimpleGraph.psm1 file and place into the desired location, for example ```C:\Users\you\Scripts\SimpleGraph.psm1```

#### Import SimpleGraph module

```PowerShell
Import-Module "C:\Users\you\Scripts\SimpleGraph.psm1"
```

#### Connect to Graph

There are a few ways to authenticate to Graph. Interactive sessions will typically use **Delegated** permissions for the required Scopes based on the Graph calls planning to be made. Refer to the specific Graph API call in docs for what permissions would be required for Delegated permissions. For example:

```PowerShell
Connect-SimpleGraph -ClientId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -TenantId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -Scopes "User.Read.All", "Group.Read.All"
```

Some Graph API calls or scenarios require **Application** permissions, in which case the app must have appropriate permissions already granted. Application permission authentication can be done with a Client Certificate or a Client Secret. For Example:

```PowerShell
$clientCertThumbprint = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$clientCertObject = Get-Item "Cert:\CurrentUser\My\$($clientCertThumbprint)"

Connect-SimpleGraph -ClientID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -TenantId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ClientCertificate $clientCertObject
```

```PowerShell
$clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | ConvertTo-SecureString -AsPlainText -Force

Connect-SimpleGraph -ClientID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -TenantId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ClientSecret $clientSecret
```

## Usage

The SimpleGraph module allows for simple calls to Graph, while providing flexibity to have complex calls as needed. Here are some basic examples of each of the commands available.

#### Get an object/read an API endpoint in Graph with a GET web call

In this example, we're reading a specific user, you@domain.com. See Graph API reference [Get a user](https://docs.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0&tabs=http).

```PowerShell
Get-SimpleGraphObject users/you@domain.com
```

#### Create an object in Graph with a POST web call

In this example, creating a simple team called "My Sample Team", using the standard blank team template. This requires specifying the body of the request, which is constructed either as a JSON string or as a hashtable. See Graph API reference [Create team](https://docs.microsoft.com/en-us/graph/api/team-post?view=graph-rest-1.0&tabs=http).

```PowerShell
$newteam = @{
    "template@odata.bind" = "https://graph.microsoft.com/v1.0/teamsTemplates('standard')";
    "displayName" = "My Sample Team";
    "description" = "My Sample Team's Description"
}
New-SimpleGraphObject teams -Body $newteam
```

#### Update an object in Graph with a PATCH web call

In this example, updating the description for a team with id 5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad. This requires specifying the body of the request, which is constructed either as a JSON string or as a hashtable. See Graph API reference [Update group](https://docs.microsoft.com/en-us/graph/api/group-update?view=graph-rest-1.0&tabs=http).

```PowerShell
Set-SimpleGraphObject groups/5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad -Body @{"description" = "New Team Description"}
```

#### Remove an object in Graph with a DELETE web call

In this example, deleting a group (which may be teams-enabled) with id 5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad. See Graph API reference [Delete group](https://docs.microsoft.com/en-us/graph/api/group-delete?view=graph-rest-1.0&tabs=http).

```PowerShell
Remove-SimpleGraphObject groups/5dcbffc1-a762-43a1-aa5a-2ae7edfa6aad
```

#### Construct a custom call to Graph

This can include method choice and an option for not massaging return. In this case, getting a specific user, but asking for raw object return:

```PowerShell
Invoke-SimpleGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/you@domain.com" -Method GET -Raw
```

#### Save a report from Graph

In this example, pull down the last 7 days of Office 365 user activity counts by workload. For more, see Graph API reference on [available data in reports](https://docs.microsoft.com/en-us/graph/reportroot-concept-overview#what-data-can-i-access-by-using-the-reports-apis).

```PowerShell
Get-SimpleGraphReport getOffice365ActiveUserCounts -Days 7
```

**Note:** More help on available parameters and examples on the SimpleGraph commands can be seen inline after importing the module using the `help` command followed by the command name:

```PowerShell
help Invoke-SimpleGraphRequest -Full
```

## Applies To

- Microsoft Graph API
- Microsoft PowerShell

## Author

|Author|Original Publish Date|Last Updated Date
|----|--------------------------|--------------
| David Whitney | October 15, 2020 | January 20, 2022

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
