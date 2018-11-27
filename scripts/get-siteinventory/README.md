# Microsoft FastTrack Open Source - Get-SiteInventory

The purpose of this script is to gather a site inventory for a SharePoint Online site collection.

## Usage

### Setup

1. Copy all scripts "Lib folder", "Get-Inventory.ps1", and "Get-WebInventory.ps1" to a folder on a computer with internet access
2. Ensure you install any needed [dependencies listed](#external-dependencies).

### Run

1. Open a PowerShell command window
2. Navigate to the folder where you placed the script files during setup
3. Execute the following command, or adjust based on the desired parameters (listed below)

`powershell -mta .\Get-Inventory.ps1 -url <Absolute Url to web> -processSubWebs`

4. If required, authenticate to the site using the pop-up. If already authenticated you will notice a pop-up appear and close
5. The script will execute, processing each of the webs. It is normal to see multiple login prompts pop-up, but they should not require interaction
6. Once the script is complete all the temp files are gathered into a single workbook

### All Options

The script supports additional options, none are required except for the _Url_ parameter.

|Option|Description|Default
|----|--------------------------|--------------------------
|Url|Absolute url of the SharePoint web to inventory|**required**
|ProcessSubWebs|Flag indicating if all subwebs should be inventories|false
|TempFolder|Folder where csv files are output by sub-processes|./temp
|OutputFolder|Folder where the final report will be written|./output
|PoolSize|The number of concurrent processes to run|NumberOfLogicalProcessors
|NoWorkbook|Is supplied the excel workbook generation is skipped (files can be found individually in the temp folder)|false
|NoQuery|Is supplied only the excel workbook generation is done|false
|Timeout|Wait time for all sub-tasks to complete (default is indefinitely)|-1
|DeleteTemp|If supplied the temp folder will be deleted once complete|false


```
There is no advantage to setting a poolSize above the number of available processors. Setting it to a lower value will reduce load on the servers and machine executing the script.
```

```
The NoQuery flag allows you to regenerate a workbook from existing files without re-querying SharePoint. The files are expected to exist in the specified TempFolder.
```

### External Dependencies

- PowerShell Version >= 5
- [SharePointPnPPowerShellOnline](https://github.com/SharePoint/PnP-PowerShell) Module
  - For SharePoint online you can use the command `Install-Module SharePointPnPPowerShellOnline`
- Microsoft Excel needs to be present on the executing machine or use the -NoWorkbook flag to skip

## Applies To

- SharePoint Online

## Author

|Author|Original Publish Date
|----|--------------------------
|Patrick Rodgers, Microsoft|June 22, 2018|

## References

- Runspace pattern from [http://www.nivot.org/post/2009/01/22/CTP3TheRunspaceFactoryAndPowerShellAccelerators](http://www.nivot.org/post/2009/01/22/CTP3TheRunspaceFactoryAndPowerShellAccelerators)

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
