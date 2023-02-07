# Microsoft FastTrack Open Source - TMS-PHONE
A tool with Teams Phone diagnostics.

![TMS-PHONE logo](https://i.postimg.cc/PJ1NDD1D/Frame-7.png)

## Requirements
- Windows OS
- Set-ExecutionPolicy RemoteSigned/Unrestricted
- [Teams PowerShell module](https://learn.microsoft.com/en-us/microsoftteams/teams-powershell-install)
> Supported MicrosoftTeams modules: '4.0.0', '4.1.0', '4.2.0', '4.3.0', '4.4.1', '4.5.0', '4.6.0', '4.7.0', '4.8.0', '4.9.0', '4.9.1', '4.9.3'

## Usage
1. Run the executable (or script)
2. Sign in with a Microsoft 365 admin account (the application will use these credentials to sign in to Teams PowerShell). It can take up to 10-15 seconds to sign in.
3. Run a diagnostic
    - **Dial Pad**: runs the dial pad diagnostic for the provided user to validate if the requirements are met
    - **Forwarding**: runs the forwarding diagnostic for the provided user to ensure forwarding is enabled and set to forward to the provided phone number
    - **Resource Account**: validates the resource account backing an auto attendant or a call queue (valid only for directly callable voice apps, not nested ones)
    - **Dynamic Caller ID**: validates user, call queue, and resource accont for Dynamic Caller ID
    - **User Validation Errors**: checks the directory and returns user that have validation errors
> If the executable crashes, comment out line 16 in the script and run it to look for errors.

## Other
- The tool was built using PowerShell and compiled with [PS2EXE](https://www.powershellgallery.com/packages/ps2exe/1.0.4)
- For more diagnostics, see [Self-Help diagnostics for Teams Admins](https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/teams-administration/admin-self-help-diagnostics)

## Sign in
![Sign in example](https://i.postimg.cc/fy72rHxR/Il51t-I5-Jv-Y.png)

## Dial Pad
Enter the UPN of the user you want to validate for Dial Pad, and select *Run*. The tool will validate Dial Pad configuration as described [here](https://learn.microsoft.com/en-us/microsoftteams/dial-pad-configuration).

If the error reported by the tool does not solve the problem, please use the self-help [Dial Pad diagnostic](https://aka.ms/TeamsDialPadMissingDiag).
![Dial Pad diagnostic](https://i.postimg.cc/s2szK5CQ/rgnzrc-DJ3p.png)

## Forwarding
Enter the UPN of the user you want to validate and the phone number the user *should be configured* to forward to, then select *Run*.

If the error reported by the diagnostic does not solve the problem, please use the self-help [Forwarding diagnostic](https://aka.ms/TeamsCallForwardingDiag).
![Forwarding diagnostic](https://i.postimg.cc/T1qFK4ht/tgfaso-Zh-MU.png)

## Resource Account
Enter the UPN of the resource account backing up the auto attendant or the call queue, then select *Run*. The diagnostic will validate that the resource account is correctly configured. This diagnostic will only be useful for voice apps that are assigned a phone number, and not for nested ones.

If the error reported by the diagnostic does not solve the problem, please use the self-help [Auto Attendant diagnostic](https://aka.ms/TeamsAADiag) or [Call Queue diagnostic](https://aka.ms/TeamsCallQueueDiag).
![Resource Account diagnostic](https://i.postimg.cc/BQnM56zS/a-STEWr-XPCf.png) 

## Dynamic Caller ID
Enter the UPN of the user (agent of call queue using dynamic caller id), the name of the call queue, and the UPN of the resource account the user will be calling on behalf of, then select *Run*. The diagnostic will validate that the user, the call queue and the resource account are properly set for dynamic caller id to work.
If the error reported by the diagnostic does not solve the problem, please refer to the [feature prerequisites](https://learn.microsoft.com/en-us/microsoftteams/plan-auto-attendant-call-queue#prerequisites).
![Dynamic Caller ID diagnostic](https://i.postimg.cc/XYTh7mry/i-UIt-J4-O3-FK.png) 


## User Validation Errors
Select *Run* to run the diagnostic and return a list of users with validation errors. To export a CSV, select *CSV* and then select *Run*. The diagnostic will export a CSV of users with validation errors to the working directory and output the path.

![User Validation Errors diagnostic](https://i.postimg.cc/nLGDwKs6/y-Ordr34-Mml.png) 

## Applies To
- Microsoft Teams

## Author
| Author         | Date     |
|--------------|-----------|
| Mihai Filip | 01/13/2023      |

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