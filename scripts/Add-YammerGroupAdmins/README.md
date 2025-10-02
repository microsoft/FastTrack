# Microsoft FastTrack Open Source - Add-YammerGroupAdmins

This sample script will allow a Yammer admin to bulk-add group owners to groups in their network.

## Usage

### Prerequisites

- You must create a new Yammer app registration in Microsoft Entra ID. This app should be configured to grant the following **delegated** permission:
  ```
  Yammer
   -access_as_user
  ```

- You'll need to create a CSV file containing two columns:
	- **GroupID**. This will contain the IDs of the groups you want to add a new admin to.
	- **Email**. This will contain the email address of the user you want to assign as admin of the group represented by the GroupID value next to it.
 
The CSV should look similar to this:

![CSV format](groupadminssample.jpg?raw=true "Title")

You can get the group ID of the groups you need to add the admins to in one of two ways:

1. Grab the group ID from the group's URL and use a BASE64 decoder on the string at the end as described here: https://support.microsoft.com/en-us/office/how-do-i-find-a-community-s-group-feed-id-in-yammer-9372ab6f-bcc2-4283-bb6a-abf42dec970f
2. Run a network data export going back as far as possible (do not export attachments) and get the group ID from the groups.csv file generated: https://learn.microsoft.com/en-us/rest/api/yammer/network-data-export
       
There are 4 variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$ClientId = "ClientIDString"**

	  >Replace ClientIDString with the Client ID of the app registration you created in the prerequisites.

2. **$TenantId = "TenantIDString"**
  
     >Replace TenantIDString with the Client ID of the app registration you created in the prerequisites.

3. **$ClientSecret = "ClientSecretString"**
  
     >Replace ClientSecretString with the client secret value of the app registration you created in the prerequisites.
     
4. $RedirectUri = "https://localhost"
   	 >Replace this with the redirect Url you set in your app registration (if not set to https://localhost)

4. **$groupadminsCsvPath = 'C:\temp\groupadmins.csv'**
  
    Point this to the groupadmins.csv file you created as mentioned above.
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:

	.\Add-YammerGroupAdmins.ps1

### Notes

**If you encounter the following error: 'Get-MsalToken : Error creating window handle.', set your PowerShell window's default terminal application to 'Windows Console Host'. This is due to a [known bug in MSAL](https://github.com/AzureAD/MSAL.PS/issues/58)**

**This sample calls an undocumented endpoint in the Yammer REST APIs, and as such has no official support provided for it, and may stop working without warning.**

## Applies To

- Yammer / Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 23th, 2023|
-> Updated to v2|October 2nd, 2025

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
