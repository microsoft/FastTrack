# Microsoft FastTrack Open Source - Update-YammerSecretGroups

This sample script will change hidden (secret) Yammer communities to visible. They will still be private, just visible in the directory.

**This script is only intended for use with external Yammer networks. Those are the only ones that should still have any hidden/secret groups.**

## Usage

### Prerequisites

- You must register an app and generate a bearer token (aka Developer Token) in the **external network** you want this script to target. Detailed instructions on how to generate this can be found here: https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058
  
- The account that creates the developer token in the step above MUST have private content mode enabled:
https://learn.microsoft.com/en-us/viva/engage/manage-security-and-compliance/monitor-private-content

There are 2 variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$Global:YammerAuthToken = "BearerTokenString"**

	  Replace BearerTokenString with the token you created via the instructions in the prerequisites. The line should look something like this:

    $Global:YammerAuthToken = "21737620380-GFy6awIxfYGULlgZvf43A"

2. **$whatIfMode = $true**

   The script runs in a WhatIf mode by default because it makes a change that can’t be undone, so it’ll only loop through the communities in your network and tell you which ones it *would* have changed to visible, it doesn’t actually take hard action. When you’re ready to have it actually make the change, change the value to $false
  
### Parameters

None

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:

	.\Update-SecretYammerGroups.ps1

## Applies To

- Yammer / Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|December 12th, 2023|

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

