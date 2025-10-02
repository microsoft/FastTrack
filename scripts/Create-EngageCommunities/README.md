# Microsoft FastTrack Open Source - Create-EngageCommunities

This sample script will demonstrate how to use PowerShell to bulk-create Viva Engage communities using the Create Community Graph API:

https://learn.microsoft.com/en-us/graph/api/employeeexperience-post-communities

https://techcommunity.microsoft.com/t5/viva-engage-blog/introducing-the-community-creation-api-for-viva-engage-on/ba-p/4011966

**NOTE - NOT INTENDED FOR PRODUCTION USE, SAMPLE ONLY. This script will create up to 50 sample communities.**

## Usage

### Prerequisites

- You must create a new Mirosoft Graph app registration in Microsoft Entra ID. This app should be configured to grant the following two **application** permissions:
  ```
  Community.ReadWrite.All
  User.Read.All
  ```

- You'll need a JSON file containing at least 50 community name and description pairs. You can find a properly formatted sample [right here](communities.json).
       
There are 3 variables you need to change in the script itself. You may have already done this while following the [video linked earlier](https://youtu.be/fY-KYJZHpdk). These are located in the 'variables' section and are the only ones you should change:

1. **$ClientId = "ClientIDString"**

	  >Replace ClientIDString with the Client ID of the app registration you created in the prerequisites.

2. **$TenantId = "TenantIDString"**
  
     >Replace TenantIDString with the Client ID of the app registration you created in the prerequisites.

3. **$ClientSecret = "ClientSecretString"**
  
     >Replace ClientSecretString with the client secret value of the app registration you created in the prerequisites.
  
### Parameters

**-InputFile 'path to JSON file'**

>REQUIRED: Specifies the path to the JSON file containing the list of communities to create.

**-NumberofCommunities 'number to create'**

>OPTIONAL: Specifies the number of communities to create. Must be an integer between 1 and 50. 
>NOTE: If not specified, the script defaults to creating 50 communities.

**-AssignedOwner "user UPN"**

>OPTIONAL: If supplied, the script will assign the specified user as the owner of all the communities created. Requires valid account in UPN format.
>NOTE: If not supplied, random users will be assigned as the owners of the new communities.

### Execution

Once you’ve completed the pre-reqs, you’re ready to go. Run the script like so:
```
Creates 25 sample communities in Viva Engage with the owners set to user@domain.com:
.\Create-EngageCommunities.ps1 -InputFile C:\Temp\communities.json -NumberofCommunities 25 -AssignedOwner "user@domain.com"

Creates 50 sample communities in Viva Engage with random owners:
.\Create-EngageCommunities.ps1 -InputFile C:\Temp\communities.json
```

## Applies To

- Viva Engage networks in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|December 22nd, 2023|

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

