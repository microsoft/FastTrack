# Microsoft FastTrack Open Source - Export-YammerPrivateFiles

This sample script exports files attached to private messages for all users prior to native mode migration

## Usage

### Prerequisites

- You must register an app and generate a bearer token (aka Developer Token) in your Yammer network for use with this script, you’ll need itfor the next step below. Detailed instructions on how to generate this can be found in step 2 here: https://support.microsoft.com/en-au/office/export-yammer-group-members-to-a-csv-file-201a78fd-67b8-42c3-9247-79e79f92b535#step2 

- Private content mode needs to be enabled for the verified admin that created the bearer token:https://learn.microsoft.com/en-us/yammer/manage-security-and-compliance/monitor-private-content

- Generate a network data export (uncheck "Include Attachments" and "Include external networks") from your network: https://learn.microsoft.com/en-us/yammer/manage-security-and-compliance/export-yammer-enterprise-data#export-yammer-network-data-by-date-range-and-network

There are 3 variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. $Global:YammerAuthToken = "BearerTokenString"

	  Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

    $Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

2. $messagesCsvPath = 'C:\temp\messages.csv'
  
    Point this to the messages.csv file you obtained from the network data export.
  
3. $rootPath = "C:\Temp"

    Replace the path above with the path you’d like the export data saved to. The script will create separate folders under this root path for each start/end date combination you run it with to try and keep the data 				separate.

### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. To run the script, just pass the startdate and enddate for the time period you want exported files from, like so:

	.\Export-YammerPrivateFiles.ps1

### Notes

This is only for use as a way to back up private message attachments prior to migrating your network to native mode. These files are removed during migration, so nothing will be exported by this script post-migration.

A folder named for the date/time you ran the script will be created under your $rootPath. Under that, the script creates a separate directory for each user and places their files in their folder. 

## Applies To

- Yammer / Viva Engage networks in M365 that are not in native mode yet

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 15th, 2023|

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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.
