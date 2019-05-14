# Microsoft FastTrack Open Source - Get-GroupsTeamsSites.ps1

The purpose of this script is to generate a report(s) that joins details from O365 Groups, Teams, and SPO Sites.

## Dependencies

- [Azureadpreview Module 2.0.0.137+](https://www.powershellgallery.com/packages/AzureADPreview/)
- [Teams Module 1.0](https://www.powershellgallery.com/packages/MicrosoftTeams/)
- [PNP Module](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps)
- [EXO Module](https://docs.microsoft.com/en-us/powershell/exchange/office-365-scc/connect-to-scc-powershell/mfa-connect-to-scc-powershell?view=exchange-ps)  

## Usage

### Parameters

|Parameter|Description|Default
|----|--------------------------|--------------------------
|InputCSV|Use this if you want to run the report against a list of Groups in a CSV file (Use PrimarySMTPAddress as column header) |false
|Properties|Specify which properties you want to retrieve. [List of available properties](#PropertyList) |false

### Ouput

|File Name|Description
|----|--------------------------
|GroupsTeamsAndSites-AllColumns.csv| This report will include ALL columns and will be the most verbose.
|GroupsTeamsAndSites-SimpleColumns.csv | This report will include properties that customers typically request.
|GroupsTeamsAndSites-CustomColumns.csv| This report will include only the properties you specify when using the -Properties switch.  


### Run Examples

#### How can I export the properties for only certain groups/teams

`Get-GroupsTeamsSites.ps1 -InputCSV ".\ListOfGroupsToQuery.csv"`

*CSV file should have PrimarySMTPAddress header.  

#### Get report of Teams that have been archived

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_Archived"`

#### Get report of Groups/Teams that are Public vs Private

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_Visibility"`

#### Get report of Groups/Teams/Sites Classification

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","Classification"`

#### Get report of Groups/Teams/Sites with guest access

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","AllowAddGuests"`

#### Get report of Groups/Teams that has a SharePoint Site with external access

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_SharingCapability"`

#### Get report of Groups/Teams/Sites that are expiring

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","ExpirationTime"`

#### Get report of Groups/Teams/Sites that were soft deleted

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","WhenSoftDeleted"`

#### Get report of Groups/Teams/Sites that are allowed to use 3rd Party Connectors

```
Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","ConnectorsEnabled","TEAMS_DisplayName","TEAMS_AllowCreateUpdateRemoveConnectors","SPO_Url"
```

#### Get report of Groups/Teams/Sites and their number of members and guests

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","GroupMemberCount","GroupExternalMemberCount"`

#### Get report of modern SPO Sites that have a Team connected

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url"`

#### Get report of Groups/Teams and their current SPO storage usage

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_StorageUsage"`

#### Get report of Groups/Teams/Sites and who they are managed by

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","ManagedBy"`

#### Get report of Groups/Teams/Sites that are Active/Inactive

```
Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_LastContentModifiedDate","WhenCreatedUTC","WhenChangedUTC"
```

#### Get report of Groups/Teams and their SharePoint Site's Conditional Access Policy (if any)

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_ConditionalAccessPolicy"`

#### Get report of Groups/Teams and their SharePoint Site's Allowed/Blocked Sharing Domain list

```
Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_SharingAllowedDomainList","SPO_SharingBlockedDomainList"
```

#### Get report of Groups/Teams and their SharePoint Site's Restricted Region? Useful for GDPR scenarios

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_RestrictedToRegion"`

#### Get report of Groups/Teams and their SharePoint Site's Time Zone Id? [Time Zone Id](https://docs.microsoft.com/en-us/previous-versions/office/sharepoint-server/ms453853(v=office.15))

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_TimeZoneId"`

#### Get report of Groups/Teams and their SharePoint Site's ability to customize via custom scripting? [Allow/Prevent Custom Scripting](https://docs.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script)

`Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_DenyAddAndCustomizePages"`

## Applies To

- O365 Groups
- Microsoft Teams
- SharePoint Online

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez|05/14/2019|

## References

- Join-Object function from [http://ramblingcookiemonster.github.io/Join-Object/](http://ramblingcookiemonster.github.io/Join-Object/ )

## Issues

Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

The script assumes you're using an account that's not MFA enabled. If you need to use an account that has MFA enabled, connect to the individual services in your powershell session then execute the script which will reuse those connections.

## PropertyList

```
Property
PSComputerName
RunspaceId
PSShowComputerName
AccessType
AuditLogAgeLimit
AutoSubscribeNewMembers
AlwaysSubscribeMembersToCalendarEvents
CalendarMemberReadOnly
CalendarUrl
Database
ExchangeGuid
FileNotificationsSettings
GroupSKU
HiddenGroupMembershipEnabled
InboxUrl
IsExternalResourcesPublished
IsMailboxConfigured
Language
MailboxProvisioningConstraint
ManagedByDetails
Notes
PeopleUrl
PhotoUrl
ServerName
SharePointSiteUrl
SharePointDocumentsUrl
SharePointNotebookUrl
SubscriptionEnabled
WelcomeMessageEnabled
ConnectorsEnabled
IsMembershipDynamic
Classification
GroupPersonification
YammerEmailAddress
GroupMemberCount
MailboxRegion
GroupExternalMemberCount
AllowAddGuests
WhenSoftDeleted
HiddenFromExchangeClientsEnabled
ExpirationTime
DataEncryptionPolicy
EmailAddresses
PrimarySmtpAddress
Name
DisplayName
RequireSenderAuthenticationEnabled
ModerationEnabled
SendModerationNotifications
SendOofMessageToOriginatorEnabled
BypassModerationFromSendersOrMembers
ModeratedBy
GroupType
IsDirSynced
ManagedBy
MigrationToUnifiedGroupInProgress
ExpansionServer
ReportToManagerEnabled
ReportToOriginatorEnabled
AcceptMessagesOnlyFrom
AcceptMessagesOnlyFromDLMembers
AcceptMessagesOnlyFromSendersOrMembers
AddressListMembership
AdministrativeUnits
Alias
OrganizationalUnit
CustomAttribute1
CustomAttribute10
CustomAttribute11
CustomAttribute12
CustomAttribute13
CustomAttribute14
CustomAttribute15
CustomAttribute2
CustomAttribute3
CustomAttribute4
CustomAttribute5
CustomAttribute6
CustomAttribute7
CustomAttribute8
CustomAttribute9
ExtensionCustomAttribute1
ExtensionCustomAttribute2
ExtensionCustomAttribute3
ExtensionCustomAttribute4
ExtensionCustomAttribute5
GrantSendOnBehalfTo
ExternalDirectoryObjectId
HiddenFromAddressListsEnabled
LastExchangeChangedTime
LegacyExchangeDN
MaxSendSize
MaxReceiveSize
PoliciesIncluded
PoliciesExcluded
EmailAddressPolicyEnabled
RecipientType
RecipientTypeDetails
RejectMessagesFrom
RejectMessagesFromDLMembers
RejectMessagesFromSendersOrMembers
MailTip
MailTipTranslations
Identity
Id
IsValid
ExchangeVersion
DistinguishedName
ObjectCategory
ObjectClass
WhenChanged
WhenCreated
WhenChangedUTC
WhenCreatedUTC
ExchangeObjectId
OrganizationId
Guid
OriginatingServer
ObjectState
TEAMS_GroupId
TEAMS_DisplayName
TEAMS_Description
TEAMS_Visibility
TEAMS_MailNickName
TEAMS_Classification
TEAMS_Archived
TEAMS_AllowGiphy
TEAMS_GiphyContentRating
TEAMS_AllowStickersAndMemes
TEAMS_AllowCustomMemes
TEAMS_AllowGuestCreateUpdateChannels
TEAMS_AllowGuestDeleteChannels
TEAMS_AllowCreateUpdateChannels
TEAMS_AllowDeleteChannels
TEAMS_AllowAddRemoveApps
TEAMS_AllowCreateUpdateRemoveTabs
TEAMS_AllowCreateUpdateRemoveConnectors
TEAMS_AllowUserEditMessages
TEAMS_AllowUserDeleteMessages
TEAMS_AllowOwnerDeleteMessages
TEAMS_AllowTeamMentions
TEAMS_AllowChannelMentions
SPO_AllowDownloadingNonWebViewableFiles
SPO_AllowEditing
SPO_AllowSelfServiceUpgrade
SPO_AverageResourceUsage
SPO_CommentsOnSitePagesDisabled
SPO_CompatibilityLevel
SPO_ConditionalAccessPolicy
SPO_CurrentResourceUsage
SPO_DefaultLinkPermission
SPO_DefaultSharingLinkType
SPO_DenyAddAndCustomizePages
SPO_DisableAppViews
SPO_DisableCompanyWideSharingLinks
SPO_DisableFlows
SPO_HasHolds
SPO_HubSiteId
SPO_IsHubSite
SPO_LastContentModifiedDate
SPO_Lcid
SPO_LimitedAccessFileType
SPO_LockIssue
SPO_LockState
SPO_NewUrl
SPO_Owner
SPO_OwnerEmail
SPO_OwnerName
SPO_PWAEnabled
SPO_RestrictedToRegion
SPO_SandboxedCodeActivationCapability
SPO_SensitivityLabel
SPO_SetOwnerWithoutUpdatingSecondaryAdmin
SPO_SharingAllowedDomainList
SPO_SharingBlockedDomainList
SPO_SharingCapability
SPO_SharingDomainRestrictionMode
SPO_ShowPeoplePickerSuggestionsForGuestUsers
SPO_SiteDefinedSharingCapability
SPO_SocialBarOnSitePagesDisabled
SPO_Status
SPO_StorageMaximumLevel
SPO_StorageQuotaType
SPO_StorageUsage
SPO_StorageWarningLevel
SPO_Template
SPO_TimeZoneId
SPO_Title
SPO_Url
SPO_UserCodeMaximumLevel
SPO_UserCodeWarningLevel
SPO_WebsCount
SPO_Context
SPO_Tag
SPO_Path
SPO_ObjectVersion
SPO_ServerObjectIsNull
SPO_TypedObject
```

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
