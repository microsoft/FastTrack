# Microsoft FastTrack Open Source - Get-AgentCQFinder

This Script function will help IT PROs find the Call Queues to which an specific Agent belongs.
The only needed details is the “User Principal Name” (UPN) of the Agent.

Once you run the script, you will have to enter the UPN of the Agent, the outcome will give you the following details:
- How many Call Queues the users belongs;
- The details of the user (UPN/SIP/Phone)
- The details of the Call Queue (QQ Name/QQ ID) 
You can read the outcome of report on the screen/shell or you view it in a CSV file.

## Usage

####  1. Open PowerShell and run the following cmdlet: "Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
####  2. Install/Update Microsoft Teams Powershell Module: 
- Install: Open PowerShell and run the following cmdlet: "Install-Module -Name MicrosoftTeams"
- Update: Open PowerShell and run the following cmdlet: "Update-Module MicrosoftTeams"
-
- Module Source: https://www.powershellgallery.com/packages/MicrosoftTeams
####  3. You will need Office 365 tenant admin rights to access Call Queues details;
####  4. Once the above steps are completed, you can execute the script. Open a Powershell and execute scrip. Example: ".\Get-AgentCQFinder -AgentID tiago@contoso.com"
####  
- Once you execute the script, you will be prompt to enter your Office 365 credentials;
- The credentials will be used to obtain all the details from the Call Queues;
- This script will only list data, won't do any change;
#### ----> Always use the most recent version of the Script <----
#### Tool:
![Tool](https://github.com/tiagoroxo/FastTrack/blob/master/scripts/Get-AgentCQFinder/tool.JPG?raw=true)

## Applies To

- Microsoft Teams

## Author

|Author|Original Publish Date
|----|--------------------------
|_Tiago Roxo_|_15/05/2022_|

## Issues

Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).


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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
