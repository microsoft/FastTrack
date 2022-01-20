# Microsoft FastTrack Open Source - AAD PowerShell - Get a list of current license usage versus avaliable licenses

## Dependencies
- Azure Active Directory PowerShell for Graph

## Usage
.DESCRIPTION
        This is just a one liner script to see your current usage versus available subscriptions in Azure AD.
         
        The sample scripts are not supported under any Microsoft standard support 
        program or service. The sample scripts are provided AS IS without warranty  
        of any kind. Microsoft further disclaims all implied warranties including,  
        without limitation, any implied warranties of merchantability or of fitness for 
        a particular purpose. The entire risk arising out of the use or performance of  
        the sample scripts and documentation remains with you. In no event shall 
        Microsoft, its authors, or anyone else involved in the creation, production, or 
        delivery of the scripts be liable for any damages whatsoever (including, 
        without limitation, damages for loss of business profits, business interruption, 
        loss of business information, or other pecuniary loss) arising out of the use 
        of or inability to use the sample scripts or documentation, even if Microsoft 
        has been advised of the possibility of such damages.

        Author: Brian Baldock - brian.baldock@microsoft.com

        Requirements: 
            Have the Azure AD PowerShell module installed by following the instructions at this link: https://aka.ms/AAau56t"
    
    .PARAMETER Admin
        Madatory Parameter - Admin account utilized for accessing the Microsoft 365 platform
    
    .PARAMETER All
        This is the default parameter and will get all SKUs and their current usage vs total available

    .PARAMETER SubscriptionName
        If you are just looking for the current usage or total available licenses for a specific SKU you can enter the name here

    .EXAMPLE
        To get all the avalable SKUs and their current usage to available
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com -All

        To get a specific SKUs current usage to available
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com -SubscriptionName SPE_E5

        To export this to a csv file
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com | Export-Csv MyLicenses.csv -NoTypeInformation

## Applies To
- Azure Active Directory

## Author

| Author        | Original Publish Date |
|---------------|-----------------------|
| Brian Baldock | 2022-01-19            |
|               |                       |

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
