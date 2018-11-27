# Microsoft FastTrack Open Source - Select-SPMTLogErrors

This script will split consolidated SPMT error logs and output one csv file per unique value found in the specified column.

## Usage

### Split Mode

1. Copy the script file "Split-SPMTLogErrors.ps1" to the folder with the consolidated log file
2. Open a PowerShell command window
3. Execute the script using

     `.\Split-SPMTLogErrors.ps1 -file {file name to filter}`

4. Review the output files which will be named "split_" with the column value appended. One file per value

**Specify the output folder where the split files will be written**

```PowerShell
.\Split-SPMTLogErrors.ps1 -file {file name to filter} -outFolder ./output
```

**Specify the column upon whose values we will split the consolidated errors log**

```PowerShell
.\Split-SPMTLogErrors.ps1 -file {file name to filter} -splitColumn "Result Category"
```

### Report Mode

You can use the tool to quickly view occurrence counts for a given column's unique values. This is done using the "getColumnReport" flag. It will output an ordered table of values with their occurrence counts. This can serve as a guide to see what errors may be of the most interest or easy to filter. Can also be used as a check to ensure filter mode is producing results as expected.

```PowerShell
.\Split-SPMTLogErrors.ps1 -file {file name to filter} -getColumnReport
```

### Filter Mode

Another way to use the script is to select only those rows with certain values for a given column and output those row into a new csv. 

1. Run the script with "getSelectFile" flag to generate a list of all the unique values found in the specified column. This file will be output as "selects.txt". 
2. Edit the "selects.txt" file leaving only the values you want to keep, one per line. 
3. Run the script with the "selectFile" parameter specified. This will produce a file with the name "filtered.csv" containing only those rows whose select column value is found in the input file. This process is shown below.

```PowerShell
.\Split-SPMTLogErrors.ps1 -file {file name to filter}  -getSelectFile

# Edit selects.txt to include those values to KEEP in the output csv

.\Split-SPMTLogErrors.ps1 -file {file name to filter}  -selectFile "selects.txt"

# Review filtered.csv file that is output
```
You can also specify a different column than the default using the "splitColumn" parameter

```PowerShell
.\Split-SPMTLogErrors.ps1 -file {file name to filter} -splitColumn "Content Type" -getSelectFile

# Edit selects.txt to include those values to KEEP in the output csv

.\Split-SPMTLogErrors.ps1 -file {file name to filter} -splitColumn "Content Type" -selectFile "selects.txt"

# Review filtered.csv file that is output
```

### All Options

The script supports several additional options. None are required except for the _file_ parameter.

|Option|Description|Default
|----|--------------------------|--------------------------
|file|Input file to be filtered|**required**
|splitColumn|Column whose data is used by this script|Message
|outFolder|Folder where individual csv files are written in Split Mode|Current Folder
|outFile|Used only with getSelectFile and selectFile parameters|"selects.txt" or "filtered.csv"
|getSelectFile|When specified a file will be generated listing all the unique values for the given splitColumn|none
|selectFile|Specifies the file to use when filtering the error log|none, presence triggers filter mode
|getColumnReport|If specified writes a report of the unique values for the given column with counts|none


## Applies To

Used against the consolidated error log file from SPMT.

## Author

|Author|Original Publish Date
|----|--------------------------
|Patrick Rodgers, Microsoft|April 27, 2018|

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
