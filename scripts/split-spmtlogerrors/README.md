# Microsoft FastTrack Open Source - Select-SPMTLogErrors

This script will split consolidated SPMT error logs and output one csv file per unique value found in the specified column.

## Usage

1. Copy the script file "Select-SPMTLogErrors.ps1" to the folder with the consolidated log file
2. Open a PowerShell command window
3. Execute the script using

     `.\Select-SPMTLogErrors.ps1 -file {file name to filter}`

4. Review the output files which will be named "split_" with the column value appended. One file per value

### Additional Examples

Specify the ouput folder where the split files will be written

`.\Select-SPMTLogErrors.ps1 -file {file name to filter} -outFolder ./output`

Specify the column upon whose values we will split the consolidated errors log

`.\Select-SPMTLogErrors.ps1 -file {file name to filter} -splitColumn "Result Category"`

### Additional Options

The script supports several additional options. None are required except for the _file_ parameter.

|Option|Description|Default
|----|--------------------------|--------------------------
|file|Input file to be filtered|**required**
|splitColumn|Column used to split the rows based on unique values|Message
|outFolder|Folder where individual csv files are written|Current Folder

## Applies To

Used against the consolidated error logs from SPMT.

## Author

|Author|Original Publish Date
|----|--------------------------
|Patrick Rodgers, Microsoft|April 27, 2018|

## Issues

Please report any issues you find to the [issues list](../../../issues).

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
