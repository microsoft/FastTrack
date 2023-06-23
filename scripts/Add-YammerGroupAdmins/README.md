# Microsoft FastTrack Open Source - Add-YammerGroupAdmins

This sample script adds new admins to Yammer groups in bulk

NOTE: This sample calls an undocumented endpoint in the Yammer REST APIs, and as such has no official support provided for it, and may stop working without warning.

## Usage

### Prerequisites

- You must register an app and generate a bearer token (aka Developer Token) in your Yammer network for use with this script, you’ll need itfor the next step below. Detailed instructions on how to generate this can be found here: https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

- You'll need to create a CSV file containing two columns:
    1. GroupID. This will contain the IDs of the groups you want to add a new admin to.
    2. Email. This will contain the email address of the user you want to assign as admin of the group represented by the GroupID value next to it.
       
There are 2 variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. $Global:YammerAuthToken = "BearerTokenString"

	  Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

    $Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

2. $groupadminsCsvPath = 'C:\temp\groupadmins.csv'
  
    Point this to the groupadmins.csv file you created as mentioned above.
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. To run the script, just pass the startdate and enddate for the time period you want exported files from, like so:

	.\Add-YammerGroupAdmins.ps1

### Notes

This is only for use as a way to back up private message attachments prior to migrating your network to native mode. These files are removed during migration, so nothing will be exported by this script post-migration.

A folder named for the date/time you ran the script will be created under your $rootPath. Under that, the script creates a separate directory for each user and places their files in their folder. 

## Applies To

- Yammer / Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|June 23th, 2023|

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
