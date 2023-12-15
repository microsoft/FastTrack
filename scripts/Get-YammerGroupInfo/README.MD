# Microsoft FastTrack Open Source - Get-YammerGroupInfo

This sample script gets key information about every group in your Yammer network, including group ID, name, member count, last message date, and group admins.

## Usage

### Prerequisites

- You must register an app and generate a bearer token (aka Developer Token) in your Yammer network for use with this script, you’ll need it for the next step below.
  Detailed instructions on how to generate this can be found in step 2 here: https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

- The account that creates the developer token in the step above MUST have private content mode enabled:
  https://learn.microsoft.com/en-us/viva/engage/manage-security-and-compliance/monitor-private-content


There are only 2 variables you may need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$Global:YammerAuthToken = "BearerTokenString"**

	Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

    $Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

2. **$ReportOutput = "C:\Temp\YammerGroupInfo{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")**

    If you'd like the script to be generated in a specific location, change the path above to reflect your target.

### Parameters

None

### Execution

Once you’ve made and saved those changes, you’re ready to go. Run the script like so:

	.\Get-YammerGroupInfo.ps1

## Applies To

- Yammer / Viva Engage networks in M365, including external networks

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|December 13th, 2023|

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
