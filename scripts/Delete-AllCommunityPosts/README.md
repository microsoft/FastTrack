# Microsoft FastTrack Open Source - Delete-AllCommunityPosts

This sample script will allow a Viva Engage admin to delete all messages in an existing Engage group.

DELETION CAN'T BE UNDONE.

## Usage

### Prerequisites

- You must create a new Yammer app registration in Microsoft Entra ID. This app should be configured to grant the following **delegated** permission:
  ```
  Yammer
   -access_as_user
  ```

- You'll need to get the ID of the group you want to delete messages from. You can find instructions for getting the group ID here: https://learn.microsoft.com/en-us/viva/engage/manage-communities/manage-communities#find-the-id-of-a-community


### Variables

There are a few variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$ClientId = "ClientIDString"**

	  >Replace ClientIDString with the Client ID of the app registration you created in the prerequisites.

2. **$TenantId = "TenantIDString"**
  
     >Replace TenantIDString with the Client ID of the app registration you created in the prerequisites.

3. **$ClientSecret = "ClientSecretString"**
  
     >Replace ClientSecretString with the client secret value of the app registration you created in the prerequisites.
     
4. **$RedirectUri = "https://localhost"**
   	 >Replace this with the redirect Url you set in your app registration (if not set to https://localhost)

5. **$GroupId = 1111111111111**
  
    The ID of the group you want to delete all messages from. See prerequisites for info on how to get that ID.

6. **$whatIfMode = $true**

   The script runs in a WhatIf mode by default since the group deletion can’t be undone, so it’ll only loop through the CSV and tell you which groups it *would* have deleted, it doesn’t actually take hard action. When you’re ready to have it actually delete groups, change the value to $false. DELETION CAN'T BE UNDONE.

7. **$hardDelete = $false**

   The script soft-deletes messages by default, set this to true if you want them hard-deleted. If you do, be aware that this is UNRECOVERABLE. Any data export run after this will show the message redacted, so unless you back the messages up first, you have no way of going back to any record of them. Think carefully before setting this to $true.

8. **$messageBackupPath**

   Path to save the backup of messages to if you choose to back them up before deletion.
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:

	.\Delete-AllCommunityPosts.ps1

### Notes

**This script deletes all messages in the target community. I can't say this enough: DELETION CAN'T BE UNDONE.**

## Applies To

- Viva Engage networks in M365

## Author

|Author|Original Publish Date|Version
|----|--------------------------|--------------
|Dean Cron, Microsoft|October 18, 2024| Version 1.0| 
|Dean Cron, Microsoft|November 20th, 2024| Version 1.925|
|Dean Cron, Microsoft|November 4th, 2025| Version 2.0|

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


