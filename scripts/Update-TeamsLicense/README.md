# Microsoft FastTrack Open Source - Update-TeamsLicense

The purpose of this script is to enable or disable the Teams license and keep existing license configurations. 

## Usage

### Run

1. Copy the script file "Update-TeamsLicense.ps1" to a folder and open a PowerShell command window to that folder
2. Connect to MSOnline - Connect-MsolService
2. Execute the script: 

Examples to run the script:  

`.\Update-TeamsLicense.ps1 -AccountSkuId "CONTOSO:ENTERPRISEPREMIUM" -DisableSubLicenses "TEAMS1" -ImportCSVFile "c:\userslist.csv"`  
`.\Update-TeamsLicense.ps1 -AccountSkuId "CONTOSO:ENTERPRISEPREMIUM" -DisableSubLicenses "TEAMS1","MCOSTANDARD" -ImportCSVFile "c:\userslist.csv"`  
`.\Update-TeamsLicense.ps1 -AccountSkuId "CONTOSO:ENTERPRISEPREMIUM" -EnableSubLicenses "TEAMS1" -ImportCSVFile "c:\userslist.csv"`  
`.\Update-TeamsLicense.ps1 -AccountSkuId "CONTOSO:ENTERPRISEPREMIUM" -EnableSubLicenses "TEAMS1","MCOSTANDARD" -ImportCSVFile "c:\userslist.csv"`    


|Option|Description
|----|--------------------------
|AccountSkuId|Account SKU ID, for example, for Enterprise E3 it is CONTOSO:ENTERPRISEPACK
|ImportCSVFile|Specify a CSV file with list of users to target. Column header must be "UserPrincipalName"
|DisableSubLicenses|Provide the sublicense name to disable. Multiple sublicenses can be included using the format "licenseA","licenseB"
|EnableSubLicenses|Provide the sublicense name to enable. Multiple sublicenses can be included using the format "licenseA","licenseB"

### External Dependencies

MSOnline module : https://docs.microsoft.com/en-us/office365/enterprise/powershell/connect-to-office-365-powershell  

## Applies To

- O365 - Teams   

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|July 24, 2018|
|David Whitney, Microsoft|July 24, 2018|

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


