# Microsoft FastTrack Open Source - Delete-YammerUsers

This sample script will allow a Yammer admin to bulk-delete Yammer users

## Usage

### Prerequisites

- You must create a new Yammer app registration in Microsoft Entra ID. This app should be configured to grant the following **delegated** permission:
  ```
  Yammer
   -access_as_user
  ```

- You'll need to create a CSV file containing one column:
	- **UserID**. This will contain the IDs of the users you want to delete.
 
  The CSV should look similar to this:

  ![CSV format](UserIDSample.png?raw=true "Title")

  You can get the user ID of the users you want to delete in one of two ways:

    1. Run a user export of all users. Settings-> Edit Network Admin Settings -> Export Users -> Export All Users. Grad the IDs of the users you want to delete from here and crearte a new CSV, placing those IDs in a column named UserID.
    2. If you're doing this pre-native mode migration, you can get the user IDs from the alignment report you're basing your cleanup on.

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

5. **$Global:YammerAuthToken = "BearerTokenString"**

	  Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

    $Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

6. **$usersToBeDeletedCSV = 'C:\temp\userstobedeleted.csv'**
  
    Point this to the userstobedeleted.csv file you created as mentioned above.

7. **$whatIfMode = $true**

   The script runs in a WhatIf mode by default since user deletion can’t be undone, so it’ll only loop through the CSV and tell you which users it *would* have deleted, it doesn’t actually take hard action. When you’re ready to have it actually delete users, change the value to $false
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:

	.\Delete-YammerUsers.ps1

## Applies To

- Yammer / Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|November 28th, 2023|
|Dean Cron, Microsoft|November 4th, 2025|

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

