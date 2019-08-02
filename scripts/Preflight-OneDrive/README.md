# Microsoft FastTrack Open Source - Preflight-OneDrive

Script to generate a report (within console or HTML report) from a directory (local folder or UNC path) of potential sync issues before deploying the OneDrive for Business sync client.

## Usage

### Run

**Example**

`.\Preflight-OneDrive.ps1 -Path "\\dc.contoso.com\smb" -GenerateHTMLReport`

**Parameters**
```
[string]$Path 
[switch]$GenerateHTMLReport   
```

### External Dependencies

[EnhancedHTML2 Module](https://www.powershellgallery.com/packages/EnhancedHTML2/2.0)  
[Test-OneDrivePath Function](https://github.com/OTvedt/Scripts-For-Sharing/blob/master/OneDrive/Test-OneDrivePath.ps1)

### Screenshots of Results

**Console Screenshot**  
![Console screenshot](screenshots/ConsoleScreenshot.jpg?raw=true "Console Screenshot")  

**HTML Report screenshot**
![HTML screenshot](screenshots/HTMLReportScreenshot.jpg?raw=true "HTML Screenshot")

## Applies To

- SharePoint Online / OneDrive for Business

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|August 2nd, 2019|

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


