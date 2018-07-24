# Microsoft FastTrack Open Source - Manage-Teams

The purpose of this script is to generate Teams reports

## Usage

### Run

**Run the script with no switches and it will provide you a menu of what reports to run**

`.\Manage-Teams.ps1`

```
0) Check Script Pre-requisites
1) Connect to O365
2) Get Teams
    Properties: "GroupId","GroupName","TeamsEnabled","Provider","ManagedBy","WhenCreated","PrimarySMTPAddress","GroupGuestSetting","GroupAccessType","GroupClassification","GroupMemberCount","GroupExtMemberCount","SPOSiteUrl","SPOStorageUsed","SPOtorageQuota","SPOSharingSetting"
3) Get Teams Membership
    Properties: "GroupID","GroupName","TeamsEnabled","Member","Name","RecipientType","Membership"
4) Get Teams That Are Not Active
    Properties: "GroupID","Name","TeamsEnabled","PrimarySMTPAddress","MailboxStatus","LastConversationDate","NumOfConversations","SPOStatus","LastContentModified","StorageUsageCurrent"
5) Get Users That Are Allowed To Create Teams
    Properties: "ObjectID","DisplayName","UserPrincipalName","UserType" 
6) Get Teams Tenant Settings
    Settings captured: Azure AD Group Settings, Who's Allowed to Create Teams, Guest Access, Expiration Policy
7) Get Groups/Teams Without Owner(s)
    Properties: "GroupID","GroupName","HasOwners","ManagedBy"
8) Get All Above Reports
9) Get Teams By User
    Properties: "User","GroupId","GroupName","TeamsEnabled","IsOwner"
10) Exit Script
```

### External Dependencies

Powershell v3+ 
[Azureadpreview Module](https://www.powershellgallery.com/packages/AzureADPreview/2.0.0.17)
[Teams module](https://www.powershellgallery.com/packages/MicrosoftTeams/0.9.0)
[SPO module](https://www.microsoft.com/en-us/download/details.aspx?id=35588) 
[SFBO module](https://www.microsoft.com/en-us/download/details.aspx?id=39366)
[EXO/SCC Click Once App for MFA](https://docs.microsoft.com/en-us/powershell/exchange/office-365-scc/connect-to-scc-powershell/mfa-connect-to-scc-powershell?view=exchange-ps)
[PNP Module](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps)

## Applies To

- Microsoft Teams

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|July 24, 2018|

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


