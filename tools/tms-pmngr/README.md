# Microsoft FastTrack Open Source - TMS-PMNGR
A tool to manage Teams profiles on Windows.

![TMS-PMNGR logo](https://i.postimg.cc/GpSb3nXV/Frame-7-2.png)

## Requirements
- Windows OS

## Usage
1. Run the executable (or script)
> If the executable crashes, run the script with the console open to look for errors.
2. Opon first launch, no profile will be available.
3. Insert a profile name, typically one that recognizes the user and/or tenant, and select *Create*. The tool will create a new Teams profile with the given name and launch it. Proceed to sign in and use Teams as you normally would.
![TMS-PMNGR create profile](https://i.postimg.cc/RFXKZFk9/7-C6-ISFy-I4h.png)
> If you're on a machine that is connected to a corporate account, you might need to [skip UPN prefill](https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/authentication/teams-defaults-to-domain-joined-account).
4. Once the profile is created, select it and click *Start* to launch it
![TMS-PMNGR start profile](https://i.postimg.cc/vTX4vNYs/lftd-B8bhg5.png)

## Functionality
- **Create**: creates a new profile with the given name
- **Start**: launches the selected profile
- **Cache**: clears cache for the selected profile
> If Outlook is open, it will close it to clear the meeting add-in cache.
- **Location**: launches the selected profile location in File Explorer
- **Delete**: deletes the selected profile
- **DEV**: enables the developer context menu in the system tray, which is off by default
- **AUTH**: change the auth stack from WAM (default) to ADAL
- **RING**: change the deployment ring from General (default) to another ring (I.e. 3.6)
> DEV, AUTH, and RING work with the hooks.json file stored in %appdata%\microsoft\teams per profile. If you delete this file or clear the cache for the profile, the settings will return to their defaults.

## Example running 4 Teams profiles
![TMS-PMNGR example](https://i.postimg.cc/PJxQkZF1/Vp-Q1icr-Dka.png)

## Other
- The tool was built using PowerShell and compiled with [PS2EXE](https://www.powershellgallery.com/packages/ps2exe/1.0.4)
- The script is based on this [CMD version](https://gist.github.com/DanielSmon/cc3fa072857f0272257a5fd451768c3a)

## Applies To
- Teams for Windows

## Author
| Author         | Date     |
|--------------|-----------|
| Mihai Filip | 01/05/2023      |

## Issues
Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

## Support
> The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices
Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.