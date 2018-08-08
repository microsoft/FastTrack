# Microsoft FastTrack Open Source - move-team script

## Usage

move-team.ps1 is a PowerShell script used to consolidate teams by copying one team's members, owners, channels, and files to another team. Useful for consolidating teams and reducing team sprawl.

What this script does:  
1. Establish connection to Microsoft Teams and Azure Active Directory in the user's context.  
2. Prompt user for source and target teams.  
3. Read and report source and target team membership, compare and prompt whether or not to add members missing from target team. If current user is owner in target team, add members/owners to target team.  
4. Loop through source channels and either confirm they exist in the target team or create them.  
5. Copy the files from each source channel into the corresponding target channel.  

EXAMPLE  
Run the script with no switches. Menus and prompts are presented at run time.  
.\move-teams.ps1

## Applies To

- Microsoft Teams

## Author

|Author|Original Publish Date
|----|--------------------------
|Jayme Bowers|07/06/2018|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

KNOWN ISSUES:  
- Tabs and Connectors. As of the time of this script's creation, the ability to create tabs and connectors in the target team is not supported.

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