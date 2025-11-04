# Microsoft FastTrack Open Source - Export-YammerNetworkData

This sample script calls the Yammer Network Data Export API to export messages and (optionally) files from your Yammer network for the date range specified in the command. 

## Usage

### Prerequisites

- You must create a new Yammer app registration in Microsoft Entra ID. This app should be configured to grant the following **delegated** permission:
  ```
  Yammer
   -access_as_user
  ```

There are a few variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$ClientId = "ClientIDString"**

	  >Replace ClientIDString with the Client ID of the app registration you created in the prerequisites.

2. **$TenantId = "TenantIDString"**
  
     >Replace TenantIDString with the Client ID of the app registration you created in the prerequisites.

3. **$ClientSecret = "ClientSecretString"**
  
     >Replace ClientSecretString with the client secret value of the app registration you created in the prerequisites.
     
4. **$RedirectUri = "https://localhost"**
   	 >Replace this with the redirect Url you set in your app registration (if not set to https://localhost)

5. $Global:YammerAuthToken = "BearerTokenString"

	Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

	$Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

6. $rootPath = "C:\Temp"

	Replace the path above with the path you’d like the export data saved to. The script will create separate folders under this root path for each start/end date combination you run it with to try and keep the data separate.
  
### Parameters

**StartDate YYYY-MM-DD**
	
	REQUIRED. Sets the start date for the target date range of the export
**EndDate YYYY-MM-DD**
	
	OPTIONAL. Sets the end date for the target date range of the export. 
	NOTE: We recommend including this and setting a reasonable range to avoid timeouts.
**IncludeFiles all/csv** (Default: CSV)
	
	OPTIONAL. Set this to ‘all’ to include messages and file attachments, or ‘csv’ for messages only.
**IncludeExternalNetworks true/false** (Default: False)
	
	OPTIONAL. Set this to ‘true’ to include CSVs and/or file attachments for the primary network and all associated external networks.
	NOTE: This is unnecessary for native mode migration, as migration doesn’t touch external networks 
  
### Execution
  
Once you’ve made and saved those changes, you’re ready to go. To run the script, pass the start date for the export and any of the three optional parameters shown above. For example, if I wanted to export all data from the main network only (not any of the associated external networks), I'd run the script like so:

	.\Export-YammerNetworkData.ps1 -startdate 2023-01-14 -enddate 2023-01-31 -IncludeFiles All

Reminder - The StartDate and EndDate parameters need to be in the YYYY-MM-DD format as shown above. Once complete, the console output will tell you where to find the result, which should be a date-named folder underneath your $rootPath set above.

### Notes

Even though you can download files/attachments using this API, we recommend only using this script to download messages if you need a large timeframe and/or have a large number of files in the network. This API starts the download as soon as you execute it, downloading each file one by one, and if there are a lot of files it can result in failure. Generally we recommend using the Files Export API for file downloads, as that packages up all files into one or more zip files on the back-end, and then it downloads the resulting zip(s). This tends to be more reliable. See my Yammer-FilesExport script in this repository to download files from your network.
  
Console output is minimal. This is more of a ‘fire and go get a cup of coffee’ type thing based on how the API works, so detailed logging is sent to a logfile that will be created in the same folder the export data is saved to. If there are errors during script execution relating to issues making calls to the API, detailed info will be logged to that script log, along with various pieces of key information along the way. The console output will only give basic info on what step it’s on, and in the event of API call failure, just let you know it failed and point you to that log for more information.

Each time you run this, it will create a new folder under the $rootPath you specify that will be named for the export timeframe you specified. In that folder you'll find one or more files for the file downloads, along with the detailed script log showing each execution step. The console output from each script run will point you to the specific folder for that run.

If your network is in native mode, no files will be downloaded. Included among the CSV files that do get downloaded, you'll see files.csv, which contains information on each file in the network, including the SPO/OneDrive of each. Actual files are only exported from pre-native mode networks where the files are still in Yammer's file store, not ones that exist in SharePoint.

## Applies To

- Yammer / Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 15th, 2023|
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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
