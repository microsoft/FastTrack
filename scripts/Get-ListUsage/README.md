# Microsoft FastTrack Open Source - Get-ListUsage

This script takes a List instance and return a csv report of the usage information for all of the items/documents in the list.

## Usage

### Setup

1. Install [SharePointPnPPowerShellOnline](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps#powershell-gallery) module
2. Copy the Get-ListUsage.ps1 file to a folder
3. Open a PowerShell command prompt and cd to the folder from step 2

### Execution

```PowerShell
# Connect to SPO
Connect-PnPOnline -Url https://yoursite.sharepoint.com -UseWebLogin

# Get the List and Pipe it to Get-ListUsage
Get‑PnPList {List Title} | ./Get-ListUsage

# Output results to csv
Get‑PnPList {List Title} | ./Get-ListUsage | Export-CSV "{filename}.csv" -NoTypeInformation

# Specify the months to get
Get‑PnPList {List Title} | ./Get-ListUsage -months 12 | Export-CSV "{filename}.csv" -NoTypeInformation
```

### Options

|Name|Type|Description|
|--|--|--|
|months|optional|Number of months of data to retrieve. Valid range 1-12
|query|optional|Query to determine what items to process

**Default Query**
```XML
<View Scope='RecursiveAll'><ViewFields><FieldRef Name='ID'/><FieldRef Name='FileLeafRef'/></ViewFields><Query></Query><RowLimit>20</RowLimit></View>
```

> If you specify a custom query the script requires that you include "ID" and "FileLeafRef" for the items to be processed.

## Issues

Please report any issues you find to the [issues list](../../../../issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other official support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, but there is no support SLA associated with these tools.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.