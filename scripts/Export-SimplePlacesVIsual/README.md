# Microsoft FastTrack Open Source - Export-SimplePlacesVisual

Exports a simple visual representation of the Places directory structure, showing the hierarchy of sections, rooms, spaces, and desks. The output is a text-based tree structure that is displayed in the console or can be saved to a file.

## Usage

### Prerequisites

Requires the Places PowerShell Module to be installed and for you to be authenticated to the Places service. See the [Places documentation on connecting](https://learn.microsoft.com/en-us/microsoft-365/places/powershell/connect-microsoftplaces) for more.

### Examples

Export the Places directory structure to the console in a simple text format:

```PowerShell
Export-SimplePlacesVisual.ps1
```

Export the Places directory structure to an text file named "PlacesDirectory.txt" in the current directory, including PlaceId for each object:

```PowerShell
Export-SimplePlacesVisual.ps1 -IncludePlaceId -OutputFileName "PlacesDirectory.txt"
```

Export the Places directory structure starting from the specified ancestor PlaceId "12345", including PlaceId for each object in the output:

```PowerShell
Export-SimplePlacesVisual.ps1 -AncestorId "12345" -IncludePlaceId
```

## Applies To

- Microsoft Places

## Author

|Author|Original Publish Date
|----|--------------------------
|David Whitney|June 12, 2025|

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
