# Microsoft FastTrack Open Source - Yammer script to get Private Content Mode Admins

## Usage

Script to list Yammer verified Admins that have promoted themselves to Private Content Mode.

A Yammer developer token is required and can be created at the following site : https://www.yammer.com/client_applications
 
    .EXAMPLE
        To list all users whether or not they are verified admins:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly $False

    .EXAMPLE
        To list only verified admins and whether they have Private Content Mode enabled:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly $True
    
    .EXAMPLE
        To export the list as a CSV file:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly [$True | $False]| Export-CSv -Path "C:\scripts\YammerPrivateContentModeAdmins.csv" -NoTypeInformation

## Applies To
-Yammer

## Author

|Author|Original Publish Date
|----|--------------------------
|Brian Baldock|2020-09-29|

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