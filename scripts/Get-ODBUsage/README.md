# Microsoft FastTrack Open Source - Get-ODBUsage

The purpose of this script is to enumerate OneDrive for Business Sites along with their data usage and date created.

## Usage

### Run

1. Copy the script file "Get-ODBUsage.ps1" to a folder and open a PowerShell command window to that folder
2. Execute the script using:

`.\Get-ODBUsage.ps1 -AdminSiteUrl https://domain-admin.sharepoint.com -GlobalAdminUPN admin@domain.onmicrosoft.com -AdminPassword Password -MySiteHostURL https://domain-my.sharepoint.com -ImportCSVFile "c:\userslist.csv"`

Another example:

`.\Get-ODBUsage.ps1 -AdminSiteUrl https://domain-admin.sharepoint.com -GlobalAdminUPN admin@domain.onmicrosoft.com -AdminPassword Password -MySiteHostURL https://domain-my.sharepoint.com -ExcelFilePath c:\dailyreport -FileName OneDriveUsage.csv `

|Option|Description
|----|--------------------------
|AdminSiteUrl|Specifies the URL of the SharePoint Online Administration Center site
|GlobalAdminUPN|Specifies the username of the SharePoint Online global administrator that will be added to the personal sites collection administrators
|AdminPassword|Specifies the password of the SharePoint Online global administrator that will be added to the personal sites collection administrators
|MySiteHostURL|Specifies the location at which the personal sites are created
|ImportCSVFile|Specify a CSV file with list of users to query for their ODB sites and get their storage. The CSV file needs to have "LoginName" as the column header
|ExcelFilePath|Specifies the path which the report will be stored in. If this parameter is empty, the report will be stored in current directory
|FileName|Specifies the file name which the report will be. If this parameter is empty, the default name is OneDriveUsage.csv

### External Dependencies

MSOnline PowerShell Module

## Applies To

- SharePoint Online

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|July 24, 2018|

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


