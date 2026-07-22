# Microsoft FastTrack Open Source - Add-EngageGroupAdmins

This sample script will allow an admin to bulk-add admins (owners) to Viva Engage communities using the Microsoft Graph API.

**Version 3.0 note:** This script was migrated off the deprecated legacy Yammer REST API to the Microsoft Graph [group owners API](https://learn.microsoft.com/en-us/graph/api/group-post-owners), since the legacy endpoint is undocumented, unsupported, and at risk of being turned off without notice. A Viva Engage community admin is simply an owner of the community's underlying Microsoft 365 group, so this uses `/groups/{groupId}/owners/$ref` rather than a community-specific endpoint. **The ID format has changed as part of this migration** — see below.

## Usage

### Prerequisites

- You must create a new app registration in Microsoft Entra ID. This app should be configured to grant the following **application** permission, with admin consent granted:
  ```
  Microsoft Graph
   -Group.ReadWrite.All
  ```

- You'll need to create a CSV file containing two columns:
	- **GroupID**. This will contain the Microsoft 365 group ID (a GUID) backing the community you want to add a new admin to.
	- **Email**. This will contain the email address (UPN) of the user you want to assign as admin of the community represented by the GroupID value next to it.

  > ⚠️ **This is not the same ID as the legacy numeric Yammer group ID used by earlier versions of this script.** Graph requires the underlying Microsoft 365 group's GUID.

You can get the Microsoft 365 group ID for a community in one of two ways:

1. `GET https://graph.microsoft.com/beta/employeeExperience/communities/{communityId}` — the response includes a `groupId` field with the Microsoft 365 group ID.
2. `GET https://graph.microsoft.com/beta/employeeExperience/communities` and match communities by `displayName` to find the corresponding `groupId`.
       
There are 4 variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$groupadminsCsvPath = 'C:\temp\groupadmins.csv'**

    Point this to the groupadmins.csv file you created as mentioned above.

2. **$ClientId = "ClientIDString"**

	  >Replace ClientIDString with the Client ID of the app registration you created in the prerequisites.

3. **$TenantId = "TenantIDString"**
  
     >Replace TenantIDString with the Tenant ID of the app registration you created in the prerequisites.

4. **$ClientSecret = "ClientSecretString"**
  
     >Replace ClientSecretString with the client secret value of the app registration you created in the prerequisites.
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:

	.\Add-EngageGroupAdmins.ps1

### Notes

**This sample now uses the Microsoft Graph group-owners API (`/v1.0/groups/{groupId}/owners/$ref`), which is officially documented and supported, unlike the earlier version of this script.**

## Applies To

- Viva Engage communities in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 23th, 2023|
-> Updated to v2|October 2nd, 2025
-> Updated to v3, migrated to Microsoft Graph|July 22nd, 2026

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
