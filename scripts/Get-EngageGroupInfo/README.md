# Microsoft FastTrack Open Source - Get-EngageGroupInfo

This sample script gets key information about every Viva Engage community in your tenant using the Microsoft Graph API, including community/group ID, name, member count, and community admins.

## Usage

### Prerequisites

- You must create a new Azure AD (Entra ID) App Registration with the following Microsoft Graph **application** permissions, with admin consent granted:
  ```
  Community.Read.All (or Community.ReadWrite.All)
  GroupMember.Read.All (or Group.Read.All / Group.ReadWrite.All)
  ```

There are a few variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$ClientId = "clientid"**

	  >Replace with the Client ID of the app registration you created in the prerequisites.

2. **$TenantId = "tenantid"**
  
     >Replace with your tenant ID.

3. **$ClientSecret = "clientsecret"**
  
     >Replace with the client secret value of the app registration you created in the prerequisites.

4. **$ReportOutput = "C:\Temp\YammerGroupInfo{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")**

    If you'd like the report generated in a specific location, change the path above to reflect your target.

### Parameters

None

### Execution

Once you’ve made and saved those changes, you’re ready to go. Run the script like so:

	.\Get-EngageGroupInfo.ps1

### Notes

**Breaking change (July 2026):** This script was migrated from the legacy Yammer REST API to Microsoft Graph. The output CSV's `GroupId` column is now the Microsoft 365 group ID (a GUID) that backs the community, not the legacy numeric Yammer group ID produced by earlier versions of this script. There's also a new `CommunityId` column with the Graph community ID.

The `LastMessageAt` column has been removed. Viva Engage conversation/message activity isn't exposed via Microsoft Graph today - the communities API only covers CRUD and membership, not messaging stats - so there's no Graph equivalent for this field.

## Applies To

- Viva Engage communities in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|December 13th, 2023|
|Dean Cron, Microsoft|July 22nd, 2026|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.
