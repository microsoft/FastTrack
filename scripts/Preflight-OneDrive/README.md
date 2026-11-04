---
title: Preflight-OneDrive
type: script
category: PowerShell
summary: >-
  Archived OneDrive preflight scanner retained for reference. Use current OneDrive limits and Migration Manager assessment instead.
author: Alejandro Lopez
version: 1.0.1
published: "2019-08-02"
updated: "2026-11-04"
tags:
  - onedrive
  - migration
format: ps1
status: archived
whatItIs: >-
  An archived PowerShell preflight scanner retained for historical reference. Its embedded checker
  defaults to a 15 GB file-size limit that no longer reflects current OneDrive limits.
whyUseIt:
  - Find problematic paths before deploying the OneDrive sync client.
  - Review results in the console or an optional HTML report.
howToUse: |-
  Do not use this archived scanner for current readiness decisions. Review the
  [current OneDrive and SharePoint limits](https://learn.microsoft.com/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-limits#service-limits-for-all-plans).
  For file-share migration assessment, use
  [Migration Manager scan and assessment reports](https://learn.microsoft.com/sharepointmigration/mm-fileshare-scan-assess).
prerequisites:
  - EnhancedHTML2 module
  - Test-OneDrivePath function
  - Read access to the folder being scanned
---

# Microsoft FastTrack Open Source - Preflight-OneDrive

> **Archived (2026-11-04):** This script is retained for historical reference. Its embedded checker defaults to a 15 GB file-size limit, while the [current OneDrive and SharePoint individual-file limit is 250 GB](https://learn.microsoft.com/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-limits#service-limits-for-all-plans). Do not rely on its results for current readiness decisions. For file-share migration assessment, use [Migration Manager scan and assessment reports](https://learn.microsoft.com/sharepointmigration/mm-fileshare-scan-assess). The original script and instructions remain below for reference.

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

