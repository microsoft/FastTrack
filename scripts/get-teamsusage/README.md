# Microsoft FastTrack Open Source - Get-TeamsUsage

The purpose of this script is to use the groups usage report graph api to gather usage data on teams within a certain period of time

## Usage

### Setup

This script requires that you register an Azure AD Application, which can be done by following the below steps.

1. Login to Portal.Azure.Com
2. Navigate to "Azure Active Directory" > "App Registrations"
3. Click "New Application Registration"
4. Give your application a friendly name, Select application type "native", and enter a redirect URL in the format "urn:foo" and click create
5. Click on the App > Required Permissions
6. Click Add and select the "Microsoft Graph" API
7. Grant the App the "Read All Usage Reports" permission
8. Record the Application ID and use that for ClientID parameter in this script

### Run

1. Copy the script file "Get-TeamsUsage.ps1" to a folder and open a PowerShell command window to that folder
2. Execute the script using:

`.\Get-TeamsUsage.ps1 -tenantName "contoso.onmicrosoft.com" -ClientID "{your app id}" -GroupsReport getOffice365GroupsActivityDetail -Period D7 -redirectUri "urn:foo"`

(You may be prompted to install the nuget provider and several other libraries. This is expected so the dependencies can be auto-installed.)

3. Review the produced csv file, or optionally you can pipe the array results to other commands such as Format-Table

`.\Get-TeamsUsage.ps1 -tenantName "contoso.onmicrosoft.com" -ClientID "{your app id}" -GroupsReport getOffice365GroupsActivityDetail -Period D7 -redirectUri "urn:foo" | Format-Table`

|Option|Description|Default
|----|--------------------------|--------------------------
|TenantName|Tenant name in the format contoso.onmicrosoft.com|**required**
|ClientID|AppID for the App registered in AzureAD for the purpose of accessing the reporting API|**required**
|GroupsReport|This is used with the Groups switch and will allow you to select from a dropdown all usage reports available with the Graph API|none
|Period|Time period for the report in days. Allowed values: D7,D30,D90,D180. Period is not supported for reports starting with getOffice365Activations and will be ignored|none
|Date|If specified will gather logs from just this date|none
|redirectUri|Redirect URI specified during application registration|**required**
|noExport|If specified no file will be exported but the output will be left on the pipe|$false


### External Dependencies

Microsoft.ADAL.PowerShell PowerShell Module
MSOnline PowerShell Module
MicrosoftTeams PowerShell Module

## Applies To

- SharePoint Online

## Author

|Author|Original Publish Date
|----|--------------------------
|Nicholas Switzer, Microsoft|May 2, 2018|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other official support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, but there is no support SLA associated with these tools.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
