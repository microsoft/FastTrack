<#
.DESCRIPTION
###############Disclaimer#####################################################
The sample scripts are not supported under any Microsoft standard support 
program or service. The sample scripts are provided AS IS without warranty  
of any kind. Microsoft further disclaims all implied warranties including,  
without limitation, any implied warranties of merchantability or of fitness for 
a particular purpose. The entire risk arising out of the use or performance of  
the sample scripts and documentation remains with you. In no event shall 
Microsoft, its authors, or anyone else involved in the creation, production, or 
delivery of the scripts be liable for any damages whatsoever (including, 
without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use 
of or inability to use the sample scripts or documentation, even if Microsoft 
has been advised of the possibility of such damages.
###############Disclaimer#####################################################

The purpose of this script is to generate a report(s) that joins details from O365 Groups, Teams, and SPO Sites.

REQUIREMENTS:
    -Azureadpreview Module - https://www.powershellgallery.com/packages/AzureADPreview/
        Need at least version 2.0.0.137 to get *-AzureADMSGroupLifecyclePolicy cmdlets
    -Teams module (GA version) - https://www.powershellgallery.com/packages/MicrosoftTeams/
        Need at least version 0.9.6 which retrieves all Teams in the organization
    -PNP Module - https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps
    -EXO Module - https://docs.microsoft.com/en-us/powershell/exchange/office-365-scc/connect-to-scc-powershell/mfa-connect-to-scc-powershell?view=exchange-ps 

VERSION:
    20190514: V1

AUTHOR(S): 
    Alejandro Lopez - Alejanl@Microsoft.com

.PARAMETER InputCSV
Use this to specify a list of Groups to query for instead of retrieving ALL Groups in the tenant which can take time. Use "PrimarySMTPAddress" as your header. 

.PARAMETER Properties
Use this if you want a report with only the columns you choose. This will generate a CustomColumns CSV report.  

Note that by default the following reports will get generated: 

All Columns Report will include these properties:  
"PSComputerName","RunspaceId","PSShowComputerName","AccessType","AuditLogAgeLimit","AutoSubscribeNewMembers","AlwaysSubscribeMembersToCalendarEvents","CalendarMemberReadOnly","CalendarUrl","Database","ExchangeGuid","FileNotificationsSettings","GroupSKU","HiddenGroupMembershipEnabled","InboxUrl","IsExternalResourcesPublished","IsMailboxConfigured","Language","MailboxProvisioningConstraint","ManagedByDetails","Notes","PeopleUrl","PhotoUrl","ServerName","SharePointSiteUrl","SharePointDocumentsUrl","SharePointNotebookUrl","SubscriptionEnabled","WelcomeMessageEnabled","ConnectorsEnabled","IsMembershipDynamic","Classification","GroupPersonification","YammerEmailAddress","GroupMemberCount","MailboxRegion","GroupExternalMemberCount","AllowAddGuests","WhenSoftDeleted","HiddenFromExchangeClientsEnabled","ExpirationTime","DataEncryptionPolicy","EmailAddresses","PrimarySmtpAddress","Name","DisplayName","RequireSenderAuthenticationEnabled","ModerationEnabled","SendModerationNotifications","SendOofMessageToOriginatorEnabled","BypassModerationFromSendersOrMembers","ModeratedBy","GroupType","IsDirSynced","ManagedBy","MigrationToUnifiedGroupInProgress","ExpansionServer","ReportToManagerEnabled","ReportToOriginatorEnabled","AcceptMessagesOnlyFrom","AcceptMessagesOnlyFromDLMembers","AcceptMessagesOnlyFromSendersOrMembers","AddressListMembership","AdministrativeUnits","Alias","OrganizationalUnit","CustomAttribute1","CustomAttribute10","CustomAttribute11","CustomAttribute12","CustomAttribute13","CustomAttribute14","CustomAttribute15","CustomAttribute2","CustomAttribute3","CustomAttribute4","CustomAttribute5","CustomAttribute6","CustomAttribute7","CustomAttribute8","CustomAttribute9","ExtensionCustomAttribute1","ExtensionCustomAttribute2","ExtensionCustomAttribute3","ExtensionCustomAttribute4","ExtensionCustomAttribute5","GrantSendOnBehalfTo","ExternalDirectoryObjectId","HiddenFromAddressListsEnabled","LastExchangeChangedTime","LegacyExchangeDN","MaxSendSize","MaxReceiveSize","PoliciesIncluded","PoliciesExcluded","EmailAddressPolicyEnabled","RecipientType","RecipientTypeDetails","RejectMessagesFrom","RejectMessagesFromDLMembers","RejectMessagesFromSendersOrMembers","MailTip","MailTipTranslations","Identity","Id","IsValid","ExchangeVersion","DistinguishedName","ObjectCategory","ObjectClass","WhenChanged","WhenCreated","WhenChangedUTC","WhenCreatedUTC","ExchangeObjectId","OrganizationId","Guid","OriginatingServer","ObjectState","TEAMS_GroupId","TEAMS_DisplayName","TEAMS_Description","TEAMS_Visibility","TEAMS_MailNickName","TEAMS_Classification","TEAMS_Archived","TEAMS_AllowGiphy","TEAMS_GiphyContentRating","TEAMS_AllowStickersAndMemes","TEAMS_AllowCustomMemes","TEAMS_AllowGuestCreateUpdateChannels","TEAMS_AllowGuestDeleteChannels","TEAMS_AllowCreateUpdateChannels","TEAMS_AllowDeleteChannels","TEAMS_AllowAddRemoveApps","TEAMS_AllowCreateUpdateRemoveTabs","TEAMS_AllowCreateUpdateRemoveConnectors","TEAMS_AllowUserEditMessages","TEAMS_AllowUserDeleteMessages","TEAMS_AllowOwnerDeleteMessages","TEAMS_AllowTeamMentions","TEAMS_AllowChannelMentions","SPO_AllowDownloadingNonWebViewableFiles","SPO_AllowEditing","SPO_AllowSelfServiceUpgrade","SPO_AverageResourceUsage","SPO_CommentsOnSitePagesDisabled","SPO_CompatibilityLevel","SPO_ConditionalAccessPolicy","SPO_CurrentResourceUsage","SPO_DefaultLinkPermission","SPO_DefaultSharingLinkType","SPO_DenyAddAndCustomizePages","SPO_DisableAppViews","SPO_DisableCompanyWideSharingLinks","SPO_DisableFlows","SPO_HasHolds","SPO_HubSiteId","SPO_IsHubSite","SPO_LastContentModifiedDate","SPO_Lcid","SPO_LimitedAccessFileType","SPO_LockIssue","SPO_LockState","SPO_NewUrl","SPO_Owner","SPO_OwnerEmail","SPO_OwnerName","SPO_PWAEnabled","SPO_RestrictedToRegion","SPO_SandboxedCodeActivationCapability","SPO_SensitivityLabel","SPO_SetOwnerWithoutUpdatingSecondaryAdmin","SPO_SharingAllowedDomainList","SPO_SharingBlockedDomainList","SPO_SharingCapability","SPO_SharingDomainRestrictionMode","SPO_ShowPeoplePickerSuggestionsForGuestUsers","SPO_SiteDefinedSharingCapability","SPO_SocialBarOnSitePagesDisabled","SPO_Status","SPO_StorageMaximumLevel","SPO_StorageQuotaType","SPO_StorageUsage","SPO_StorageWarningLevel","SPO_Template","SPO_TimeZoneId","SPO_Title","SPO_Url","SPO_UserCodeMaximumLevel","SPO_UserCodeWarningLevel","SPO_WebsCount","SPO_Context","SPO_Tag","SPO_Path","SPO_ObjectVersion","SPO_ServerObjectIsNull","SPO_TypedObject"

Simple Columns Report will include the following properties: 
"ExternalDirectoryObjectId","PrimarySmtpAddress","Name","DisplayName","AccessType","GroupSKU","ModeratedBy","ManagedBy","WhenCreatedUTC","WhenChangedUTC","HiddenFromAddressListsEnabled","HiddenGroupMembershipEnabled","Language","ManagedByDetails","SharePointSiteUrl","ConnectorsEnabled","IsMembershipDynamic","Classification","GroupMemberCount","GroupExternalMemberCount","AllowAddGuests","WhenSoftDeleted","HiddenFromExchangeClientsEnabled","ExpirationTime","TEAMS_DisplayName","TEAMS_Archived","TEAMS_AllowAddRemoveApps","SPO_Owner","SPO_OwnerEmail","SPO_SensitivityLabel","SPO_SharingAllowedDomainList","SPO_SharingBlockedDomainList","SPO_SharingCapability","SPO_ConditionalAccessPolicy","SPO_ShowPeoplePickerSuggestionsForGuestUsers","SPO_StorageMaximumLevel","SPO_StorageUsage","SPO_Template","SPO_TimeZoneId"

.EXAMPLE: How can I export the properties for only certain groups/teams? 
    Get-GroupsTeamsSites.ps1 -InputCSV ".\ListOfGroupsToQuery.csv"

    *CSV file should have PrimarySMTPAddress header. 

.EXAMPLE: Get report of Teams that have been archived? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_Archived"

.EXAMPLE: Get report of Groups/Teams that are Public vs Private? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_Visibility"
    
.EXAMPLE: Get report of Groups/Teams/Sites Classification? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","Classification"

.EXAMPLE: Get report of Groups/Teams/Sites with guest access? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","AllowAddGuests"

.EXAMPLE: Get report of Groups/Teams that has a SharePoint Site with external access? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_SharingCapability"

.EXAMPLE: Get report of Groups/Teams/Sites that are expiring? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","ExpirationTime"

.EXAMPLE: Get report of Groups/Teams/Sites that were soft deleted? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","WhenSoftDeleted"

.EXAMPLE: Get report of Groups/Teams/Sites that are allowed to use 3rd Party Connectors? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","ConnectorsEnabled","TEAMS_DisplayName","TEAMS_AllowCreateUpdateRemoveConnectors","SPO_Url"

.EXAMPLE: Get report of Groups/Teams/Sites and their number of members and guests? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","GroupMemberCount","GroupExternalMemberCount"

.EXAMPLE: Get report of modern SPO Sites that have a Team connected? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url"

.EXAMPLE: Get report of Groups/Teams and their current SPO storage usage? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_StorageUsage"

.EXAMPLE: Get report of Groups/Teams/Sites and who they are managed by? 
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","ManagedBy"

.EXAMPLE: Get report of Groups/Teams/Sites that are Active/Inactive?   
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_LastContentModifiedDate","WhenCreatedUTC","WhenChangedUTC"

.EXAMPLE: Get report of Groups/Teams and their SharePoint Site's Conditional Access Policy (if any)?   
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_ConditionalAccessPolicy"

.EXAMPLE: Get report of Groups/Teams and their SharePoint Site's Allowed/Blocked Sharing Domain list?   
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_SharingAllowedDomainList","SPO_SharingBlockedDomainList"

.EXAMPLE: Get report of Groups/Teams and their SharePoint Site's Restricted Region? Useful for GDPR scenarios.    
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_RestrictedToRegion"

.EXAMPLE: Get report of Groups/Teams and their SharePoint Site's Time Zone Id? For explanation of what the time zone id maps to: https://docs.microsoft.com/en-us/previous-versions/office/sharepoint-server/ms453853(v=office.15)     
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_TimeZoneId"

.EXAMPLE: Get report of Groups/Teams and their SharePoint Site's ability to customize via custom scripting? See impact of allowing/preventing custom scripting: https://docs.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script
    Get-GroupsTeamsSites.ps1 -Properties "PrimarySmtpAddress","TEAMS_DisplayName","SPO_Url","SPO_DenyAddAndCustomizePages"

#>

param(
    [string]$InputCSV,
    [switch]$IncludeMembership,
    [string[]]$Properties
)

Begin{

    #Functions

    Function Write-LogEntry {
        param(
            [string] $LogName ,
            [string] $LogEntryText,
            [string] $ForegroundColor
        )
        if ($LogName -NotLike $Null) {
            # log the date and time in the text file along with the data passed
            "$([DateTime]::Now.ToShortDateString()) $([DateTime]::Now.ToShortTimeString()) : $LogEntryText" | Out-File -FilePath $LogName -append;
            if ($ForeGroundColor -NotLike $null) {
                # for testing i pass the ForegroundColor parameter to act as a switch to also write to the shell console
                write-host $LogEntryText -ForegroundColor $ForeGroundColor
            }
        }
    }

    Function Run-Preflight{
        $gotError = $false
        Write-LogEntry -LogName:$Log -LogEntryText "Preflight check" -ForegroundColor Yellow

        #AZUREADPREVIEW
        If( -not((Get-Module -ListAvailable AzureADPreview).Version -ge "2.0.0.137") ) {
            Write-LogEntry -LogName:$Log -LogEntryText "Need AzureADPreview module 2.0.0.137 or higher. Install from: https://www.powershellgallery.com/packages/AzureADPreview " -ForegroundColor Yellow
            $gotError = $true  
        }
        #TEAMS
        If( -not((Get-Module -ListAvailable MicrosoftTeams).Version -ge "1.0.0") ) {
            Write-LogEntry -LogName:$Log -LogEntryText "Need MicrosoftTeams module 1.0 or higher. Install from: https://www.powershellgallery.com/packages/MicrosoftTeams/ " -ForegroundColor Yellow
            $gotError = $true 
        }
        
        #PNP
        If(!(get-module -listavailable SharePointPnPPowerShellOnline)){
            Write-LogEntry -LogName:$Log -LogEntryText "Need SharePoint PNP Module. Install instructions: https://github.com/SharePoint/PnP-PowerShell" -ForegroundColor Yellow
            $gotError = $true
        }
        
        If($gotError){
            exit
        }
        Else{
            Write-LogEntry -LogName:$Log -LogEntryText "Preflight done" -ForegroundColor Yellow
        }
    }

    Function Logon-ToServices{
        $gotError = $false
        If(!$Credential){
            $Global:Credential = get-credential -Credential $null
        }

        #EXO
        $session = Get-PSSession | where {($_.ComputerName -eq "outlook.office365.com") -and ($_.State -eq "Opened")}
        If ($session -ne $null) {
            Write-LogEntry -LogName:$Log -LogEntryText "Connected to Exchange Online" -ForegroundColor Yellow
        }
        Else{
            try{
                $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication Basic -AllowRedirection -WarningAction SilentlyContinue 
                Import-Module (Import-PSSession $exchangeSession -DisableNameChecking -AllowClobber) -Global -DisableNameChecking | out-null
                Write-LogEntry -LogName:$Log -LogEntryText "Connected to Exchange Online" -ForegroundColor Yellow
            }
            catch{
                Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to Exchange Online: $_" -ForegroundColor Red
                $gotError = $true 
            }
        }

        #TEAMS
        try{
            $checkTeamConnection = get-team -User "TestConnnection" #Hack test since Get-Team would run but it's an expensive operation just to test
            
        } 
        catch [Microsoft.Open.Teams.CommonLibrary.AadNeedAuthenticationException] {
            try{
                Connect-MicrosoftTeams -Credential $Credential | out-null
                Write-LogEntry -LogName:$Log -LogEntryText "Connected to Microsoft Teams" -ForegroundColor Yellow
            }
            catch{
                Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to Microsoft Teams: $_" -ForegroundColor Red
                $gotError = $true 
            }
        }
        catch{
            If($_.Exception.ToString() -like "*Code: Request_ResourceNotFound*"){
                Write-LogEntry -LogName:$Log -LogEntryText "Connected to Microsoft Teams" -ForegroundColor Yellow
            }
            Else{
                Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to Microsoft Teams: $_" -ForegroundColor Red
                $gotError = $true 
            }
        }

        #AZUREAD
        try{
            $AzureADConnection = Get-AzureADCurrentSessionInfo -erroraction silentlycontinue
            Write-LogEntry -LogName:$Log -LogEntryText "Connected to Azure AD" -ForegroundColor Yellow
        }
        catch{
            try{
                Connect-AzureAD -Credential $Credential | out-null
                $AzureADConnection = Get-AzureADCurrentSessionInfo -erroraction silentlycontinue
                Write-LogEntry -LogName:$Log -LogEntryText "Connected to Azure AD" -ForegroundColor Yellow
            }
            catch{
                Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to Azure AD: $_" -ForegroundColor Red
                $gotError = $true
            }
        }

        #PNP - need to logon after Azure AD connection since we need the domain name to connect
        try{
            $error.clear()
            try{$checkPNPConnection = Get-PnPTenantSite -ErrorAction SilentlyContinue}catch{}
            If(!$error){
                Write-LogEntry -LogName:$Log -LogEntryText "Connected to SharePoint PNP" -ForegroundColor Yellow
            }
            Else{
                try{
                    If($AzureADConnection){
                        $AzureADDomainInfo = Get-AzureADDomain -erroraction silentlycontinue
                        $tenant = $AzureADDomainInfo | ?{$_.IsInitial -eq "True"} | Select-Object -ExpandProperty Name 
                        $tenantName = $tenant.split(".")[0]
                        Connect-PnPOnline -Url "https://$tenantName-admin.sharepoint.com" -Credentials $Credential | out-null
                        Write-LogEntry -LogName:$Log -LogEntryText "Connected to SharePoint PNP" -ForegroundColor Yellow
                    }
                    Else{
                        Write-LogEntry -LogName:$Log -LogEntryText "Need Azure AD Connection in order to connect to PNP" -ForegroundColor Red
                        $gotError = $true 
                    }
                }
                catch{
                    Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to PNP: $_ . Try running the following and re-run the script: Connect-PNPOnline -Url https://contoso-admin.sharepoint.com -UseWeblogin " -ForegroundColor Red
                    $gotError = $true 
                }
            }
        } 
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "Unable to connect to PNP: $_. Try running the following and re-run the script: Connect-PNPOnline -Url https://contoso-admin.sharepoint.com -UseWeblogin " -ForegroundColor Red
            $gotError = $true 
        }

        ""
        If($gotError -eq $true){
            exit
        }
    }

    function Reset-DirectoryToNew {
        param (
            [Parameter(Mandatory = $true)]
            $Path
        ) 

        process {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
            Get-ChildItem -Path $Path -Include *.* -File -Recurse | ForEach-Object { $_.Delete()}
        }
    }

    #Join-Object function from Warren F: http://ramblingcookiemonster.github.io/Join-Object/ 
    function Join-Object {
        <#
        .SYNOPSIS
            Join data from two sets of objects based on a common value

        .DESCRIPTION
            Join data from two sets of objects based on a common value

            For more details, see the accompanying blog post:
                http://ramblingcookiemonster.github.io/Join-Object/

            For even more details,  see the original code and discussions that this borrows from:
                Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections
                Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

        .PARAMETER Left
            'Left' collection of objects to join.  You can use the pipeline for Left.

            The objects in this collection should be consistent.
            We look at the properties on the first object for a baseline.
        
        .PARAMETER Right
            'Right' collection of objects to join.

            The objects in this collection should be consistent.
            We look at the properties on the first object for a baseline.

        .PARAMETER LeftJoinProperty
            Property on Left collection objects that we match up with RightJoinProperty on the Right collection

        .PARAMETER RightJoinProperty
            Property on Right collection objects that we match up with LeftJoinProperty on the Left collection

        .PARAMETER LeftProperties
            One or more properties to keep from Left.  Default is to keep all Left properties (*).

            Each property can:
                - Be a plain property name like "Name"
                - Contain wildcards like "*"
                - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                    Name is the output property name
                    Expression is the property value ($_ as the current object)
                    
                    Alternatively, use the Suffix or Prefix parameter to avoid collisions
                    Each property using this hashtable syntax will be excluded from suffixes and prefixes

        .PARAMETER RightProperties
            One or more properties to keep from Right.  Default is to keep all Right properties (*).

            Each property can:
                - Be a plain property name like "Name"
                - Contain wildcards like "*"
                - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                    Name is the output property name
                    Expression is the property value ($_ as the current object)
                    
                    Alternatively, use the Suffix or Prefix parameter to avoid collisions
                    Each property using this hashtable syntax will be excluded from suffixes and prefixes

        .PARAMETER Prefix
            If specified, prepend Right object property names with this prefix to avoid collisions

            Example:
                Property Name                   = 'Name'
                Suffix                          = 'j_'
                Resulting Joined Property Name  = 'j_Name'

        .PARAMETER Suffix
            If specified, append Right object property names with this suffix to avoid collisions

            Example:
                Property Name                   = 'Name'
                Suffix                          = '_j'
                Resulting Joined Property Name  = 'Name_j'

        .PARAMETER Type
            Type of join.  Default is AllInLeft.

            AllInLeft will have all elements from Left at least once in the output, and might appear more than once
            if the where clause is true for more than one element in right, Left elements with matches in Right are
            preceded by elements with no matches.
            SQL equivalent: outer left join (or simply left join)

            AllInRight is similar to AllInLeft.
            
            OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
            match in Right.
            SQL equivalent: inner join (or simply join)
            
            AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
            in right with at least one match in left, followed by all entries in Right with no matches in left, 
            followed by all entries in Left with no matches in Right.
            SQL equivalent: full join

        .EXAMPLE
            #
            #Define some input data.

            $l = 1..5 | Foreach-Object {
                [pscustomobject]@{
                    Name = "jsmith$_"
                    Birthday = (Get-Date).adddays(-1)
                }
            }

            $r = 4..7 | Foreach-Object{
                [pscustomobject]@{
                    Department = "Department $_"
                    Name = "Department $_"
                    Manager = "jsmith$_"
                }
            }

            #We have a name and Birthday for each manager, how do we find their department, using an inner join?
            Join-Object -Left $l -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type OnlyIfInBoth -RightProperties Department


                # Name    Birthday             Department  
                # ----    --------             ----------  
                # jsmith4 4/14/2015 3:27:22 PM Department 4
                # jsmith5 4/14/2015 3:27:22 PM Department 5

        .EXAMPLE  
            #
            #Define some input data.

            $l = 1..5 | Foreach-Object {
                [pscustomobject]@{
                    Name = "jsmith$_"
                    Birthday = (Get-Date).adddays(-1)
                }
            }

            $r = 4..7 | Foreach-Object{
                [pscustomobject]@{
                    Department = "Department $_"
                    Name = "Department $_"
                    Manager = "jsmith$_"
                }
            }

            #We have a name and Birthday for each manager, how do we find all related department data, even if there are conflicting properties?
            $l | Join-Object -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type AllInLeft -Prefix j_

                # Name    Birthday             j_Department j_Name       j_Manager
                # ----    --------             ------------ ------       ---------
                # jsmith1 4/14/2015 3:27:22 PM                                    
                # jsmith2 4/14/2015 3:27:22 PM                                    
                # jsmith3 4/14/2015 3:27:22 PM                                    
                # jsmith4 4/14/2015 3:27:22 PM Department 4 Department 4 jsmith4  
                # jsmith5 4/14/2015 3:27:22 PM Department 5 Department 5 jsmith5  

        .EXAMPLE
            #
            #Hey!  You know how to script right?  Can you merge these two CSVs, where Path1's IP is equal to Path2's IP_ADDRESS?
            
            #Get CSV data
            $s1 = Import-CSV $Path1
            $s2 = Import-CSV $Path2

            #Merge the data, using a full outer join to avoid omitting anything, and export it
            Join-Object -Left $s1 -Right $s2 -LeftJoinProperty IP_ADDRESS -RightJoinProperty IP -Prefix 'j_' -Type AllInBoth |
                Export-CSV $MergePath -NoTypeInformation

        .EXAMPLE
            #
            # "Hey Warren, we need to match up SSNs to Active Directory users, and check if they are enabled or not.
            #  I'll e-mail you an unencrypted CSV with all the SSNs from gmail, what could go wrong?"
            
            # Import some SSNs. 
            $SSNs = Import-CSV -Path D:\SSNs.csv

            #Get AD users, and match up by a common value, samaccountname in this case:
            Get-ADUser -Filter "samaccountname -like 'wframe*'" |
                Join-Object -LeftJoinProperty samaccountname -Right $SSNs `
                            -RightJoinProperty samaccountname -RightProperties ssn `
                            -LeftProperties samaccountname, enabled, objectclass

        .NOTES
            This borrows from:
                Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections/
                Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

            Changes:
                Always display full set of properties
                Display properties in order (left first, right second)
                If specified, add suffix or prefix to right object property names to avoid collisions
                Use a hashtable rather than ordereddictionary (avoid case sensitivity)

        .LINK
            http://ramblingcookiemonster.github.io/Join-Object/

        .FUNCTIONALITY
            PowerShell Language

        #>
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true)]
            [object[]] $Left,

            # List to join with $Left
            [Parameter(Mandatory=$true)]
            [object[]] $Right,

            [Parameter(Mandatory = $true)]
            [string] $LeftJoinProperty,

            [Parameter(Mandatory = $true)]
            [string] $RightJoinProperty,

            [object[]]$LeftProperties = '*',

            # Properties from $Right we want in the output.
            # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
            [object[]]$RightProperties = '*',

            [validateset( 'AllInLeft', 'OnlyIfInBoth', 'AllInBoth', 'AllInRight')]
            [Parameter(Mandatory=$false)]
            [string]$Type = 'AllInLeft',

            [string]$Prefix,
            [string]$Suffix
        )
        Begin
        {
            function AddItemProperties($item, $properties, $hash)
            {
                if ($null -eq $item)
                {
                    return
                }

                foreach($property in $properties)
                {
                    $propertyHash = $property -as [hashtable]
                    if($null -ne $propertyHash)
                    {
                        $hashName = $propertyHash["name"] -as [string]         
                        $expression = $propertyHash["expression"] -as [scriptblock]

                        $expressionValue = $expression.Invoke($item)[0]
                
                        $hash[$hashName] = $expressionValue
                    }
                    else
                    {
                        foreach($itemProperty in $item.psobject.Properties)
                        {
                            if ($itemProperty.Name -like $property)
                            {
                                $hash[$itemProperty.Name] = $itemProperty.Value
                            }
                        }
                    }
                }
            }

            function TranslateProperties
            {
                [cmdletbinding()]
                param(
                    [object[]]$Properties,
                    [psobject]$RealObject,
                    [string]$Side)

                foreach($Prop in $Properties)
                {
                    $propertyHash = $Prop -as [hashtable]
                    if($null -ne $propertyHash)
                    {
                        $hashName = $propertyHash["name"] -as [string]         
                        $expression = $propertyHash["expression"] -as [scriptblock]

                        $ScriptString = $expression.tostring()
                        if($ScriptString -notmatch 'param\(')
                        {
                            Write-Verbose "Property '$HashName'`: Adding param(`$_) to scriptblock '$ScriptString'"
                            $Expression = [ScriptBlock]::Create("param(`$_)`n $ScriptString")
                        }
                    
                        $Output = @{Name =$HashName; Expression = $Expression }
                        Write-Verbose "Found $Side property hash with name $($Output.Name), expression:`n$($Output.Expression | out-string)"
                        $Output
                    }
                    else
                    {
                        foreach($ThisProp in $RealObject.psobject.Properties)
                        {
                            if ($ThisProp.Name -like $Prop)
                            {
                                Write-Verbose "Found $Side property '$($ThisProp.Name)'"
                                $ThisProp.Name
                            }
                        }
                    }
                }
            }

            function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties)
            {
                $properties = @{}

                AddItemProperties $leftItem $leftProperties $properties
                AddItemProperties $rightItem $rightProperties $properties

                New-Object psobject -Property $properties
            }

            #Translate variations on calculated properties.  Doing this once shouldn't affect perf too much.
            foreach($Prop in @($LeftProperties + $RightProperties))
            {
                if($Prop -as [hashtable])
                {
                    foreach($variation in ('n','label','l'))
                    {
                        if(-not $Prop.ContainsKey('Name') )
                        {
                            if($Prop.ContainsKey($variation) )
                            {
                                $Prop.Add('Name',$Prop[$Variation])
                            }
                        }
                    }
                    if(-not $Prop.ContainsKey('Name') -or $Prop['Name'] -like $null )
                    {
                        Throw "Property is missing a name`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                    }


                    if(-not $Prop.ContainsKey('Expression') )
                    {
                        if($Prop.ContainsKey('E') )
                        {
                            $Prop.Add('Expression',$Prop['E'])
                        }
                    }
                
                    if(-not $Prop.ContainsKey('Expression') -or $Prop['Expression'] -like $null )
                    {
                        Throw "Property is missing an expression`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                    }
                }        
            }

            $leftHash = @{}
            $rightHash = @{}

            # Hashtable keys can't be null; we'll use any old object reference as a placeholder if needed.
            $nullKey = New-Object psobject
            
            $bound = $PSBoundParameters.keys -contains "InputObject"
            if(-not $bound)
            {
                [System.Collections.ArrayList]$LeftData = @()
            }
        }
        Process
        {
            #We pull all the data for comparison later, no streaming
            if($bound)
            {
                $LeftData = $Left
            }
            Else
            {
                foreach($Object in $Left)
                {
                    [void]$LeftData.add($Object)
                }
            }
        }
        End
        {
            foreach ($item in $Right)
            {
                $key = $item.$RightJoinProperty

                if ($null -eq $key)
                {
                    $key = $nullKey
                }

                $bucket = $rightHash[$key]

                if ($null -eq $bucket)
                {
                    $bucket = New-Object System.Collections.ArrayList
                    $rightHash.Add($key, $bucket)
                }

                $null = $bucket.Add($item)
            }

            foreach ($item in $LeftData)
            {
                $key = $item.$LeftJoinProperty

                if ($null -eq $key)
                {
                    $key = $nullKey
                }

                $bucket = $leftHash[$key]

                if ($null -eq $bucket)
                {
                    $bucket = New-Object System.Collections.ArrayList
                    $leftHash.Add($key, $bucket)
                }

                $null = $bucket.Add($item)
            }

            $LeftProperties = TranslateProperties -Properties $LeftProperties -Side 'Left' -RealObject $LeftData[0]
            $RightProperties = TranslateProperties -Properties $RightProperties -Side 'Right' -RealObject $Right[0]

            #I prefer ordered output. Left properties first.
            [string[]]$AllProps = $LeftProperties

            #Handle prefixes, suffixes, and building AllProps with Name only
            $RightProperties = foreach($RightProp in $RightProperties)
            {
                if(-not ($RightProp -as [Hashtable]))
                {
                    Write-Verbose "Transforming property $RightProp to $Prefix$RightProp$Suffix"
                    @{
                        Name="$Prefix$RightProp$Suffix"
                        Expression=[scriptblock]::create("param(`$_) `$_.'$RightProp'")
                    }
                    $AllProps += "$Prefix$RightProp$Suffix"
                }
                else
                {
                    Write-Verbose "Skipping transformation of calculated property with name $($RightProp.Name), expression:`n$($RightProp.Expression | out-string)"
                    $AllProps += [string]$RightProp["Name"]
                    $RightProp
                }
            }

            $AllProps = $AllProps | Select -Unique

            Write-Verbose "Combined set of properties: $($AllProps -join ', ')"

            foreach ( $entry in $leftHash.GetEnumerator() )
            {
                $key = $entry.Key
                $leftBucket = $entry.Value

                $rightBucket = $rightHash[$key]

                if ($null -eq $rightBucket)
                {
                    if ($Type -eq 'AllInLeft' -or $Type -eq 'AllInBoth')
                    {
                        foreach ($leftItem in $leftBucket)
                        {
                            WriteJoinObjectOutput $leftItem $null $LeftProperties $RightProperties | Select $AllProps
                        }
                    }
                }
                else
                {
                    foreach ($leftItem in $leftBucket)
                    {
                        foreach ($rightItem in $rightBucket)
                        {
                            WriteJoinObjectOutput $leftItem $rightItem $LeftProperties $RightProperties | Select $AllProps
                        }
                    }
                }
            }

            if ($Type -eq 'AllInRight' -or $Type -eq 'AllInBoth')
            {
                foreach ($entry in $rightHash.GetEnumerator())
                {
                    $key = $entry.Key
                    $rightBucket = $entry.Value

                    $leftBucket = $leftHash[$key]

                    if ($null -eq $leftBucket)
                    {
                        foreach ($rightItem in $rightBucket)
                        {
                            WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties | Select $AllProps
                        }
                    }
                }
            }
        }
    }

    Function Export-OwnersMembersGuests(){
        param(
            $ListOfGroupsTeams
        )

        $count = $ListOfGroupsTeams.count
        $i = 0
        Write-LogEntry -LogName:$Log -LogEntryText "Getting Membership Report..." -ForegroundColor Yellow
        foreach ($group in $ListOfGroupsTeams){
            $i++
            if (($i % $Batch) -eq 0) {
                Write-Progress -Activity "Getting Membership..." -Status "Processed $i of $count " -PercentComplete ($i/$count*100)
            }

            $membership = New-Object System.Collections.ArrayList
            try{
                $owners = (Get-UnifiedGroupLinks -Identity $group.ExternalDirectoryObjectId -LinkType Owners | select -ExpandProperty PrimarySMTPAddress) -join "; " 
                $members = (Get-UnifiedGroupLinks -Identity $group.ExternalDirectoryObjectId -LinkType Members | ?{$_.Name -notlike "*#EXT#*"} | select -ExpandProperty PrimarySMTPAddress) -join "; " 
                $guests = (Get-UnifiedGroupLinks -Identity $group.ExternalDirectoryObjectId -LinkType Members | ?{$_.Name -like "*#EXT#*"} | select -ExpandProperty PrimarySMTPAddress) -join "; " 
                $record = [pscustomobject]@{GroupID = $group.ExternalDirectoryObjectId;
                        GroupName = $group.DisplayName;
                        TeamsEnabled = ($group.TEAMS_GroupId -ne "");
                        GroupEmail = $group.PrimarySMTPAddress;
                        GroupTotalMemberCount = $group.GroupMemberCount;
                        GroupEXTMemberCount = $group.GroupExtMemberCount;
                        Owners = $owners;
                        Members = $members;
                        Guests = $guests}
                $membership.add($record) | out-null
            }
            catch{
                Write-LogEntry -LogName:$Log -LogEntryText "Membership report error with: $group : $_" 
            }
    
            #Export membership to CSV
            $membership | Export-CSV -Path $TeamsMemberGuestCSV -append -NoTypeInformation
        }    
    }


    Clear-Host
    ""
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    $yyyyMMdd = Get-Date -Format 'yyyyMMdd'
    $computer = $env:COMPUTERNAME
    $user = $env:USERNAME
    $version = "20190514"
    $Log = "$PSScriptRoot\Get-GroupsTeamsSites-$yyyyMMdd.log"
    $Output = "$PSScriptRoot\Output"
    $tempDirectory = $env:TEMP + "\Get-GroupsTeamsSites"
    $TeamsCSV = "$($tempDirectory)\Teams.csv"
    $GroupsCSV = "$($tempDirectory)\Groups.csv"
    $SitesCSV = "$($tempDirectory)\SPOSites.csv"
    $TeamsGroupsCSV = "$($tempDirectory)\GroupsAndTeams.csv"
    $TeamsGroupsSitesCSV = "$($output)\GroupsTeamsAndSites-AllColumns.csv"
    $TeamsGroupsSitesCSV_Simple = "$($output)\GroupsTeamsAndSites-SimpleColumns.csv"
    $TeamsGroupsSitesCSV_Custom = "$($output)\GroupsTeamsAndSites-CustomColumns.csv"
    $TeamsMemberGuestCSV = "$($output)\MembershipReport.csv"
    $Batch = 5
    $SimpleColumns = ("ExternalDirectoryObjectId","PrimarySmtpAddress","Name","DisplayName","AccessType","GroupSKU","ModeratedBy","ManagedBy","WhenCreatedUTC","WhenChangedUTC","HiddenFromAddressListsEnabled","HiddenGroupMembershipEnabled","Language","ManagedByDetails","SharePointSiteUrl","ConnectorsEnabled","IsMembershipDynamic","Classification","GroupMemberCount","GroupExternalMemberCount","AllowAddGuests","WhenSoftDeleted","HiddenFromExchangeClientsEnabled","ExpirationTime","TEAMS_DisplayName","TEAMS_Archived","TEAMS_AllowAddRemoveApps","SPO_Owner","SPO_OwnerEmail","SPO_SensitivityLabel","SPO_SharingAllowedDomainList","SPO_SharingBlockedDomainList","SPO_SharingCapability","SPO_ConditionalAccessPolicy","SPO_ShowPeoplePickerSuggestionsForGuestUsers","SPO_StorageMaximumLevel","SPO_StorageUsage","SPO_Template","SPO_TimeZoneId")

    Write-LogEntry -LogName:$Log -LogEntryText "User: $user Computer: $computer Version: $version" -foregroundcolor Yellow
    ""
    Write-LogEntry -LogName:$Log -LogEntryText "Script parameters passed: $($PSBoundParameters.GetEnumerator())" 
    Run-Preflight
    Logon-ToServices
    Write-LogEntry -LogName:$Log -LogEntryText "Clean up previous runs..." -foregroundcolor Yellow
    Reset-DirectoryToNew -Path $Output #cleanup previous run, create new folder if needed
    Reset-DirectoryToNew -Path $tempDirectory #cleanup previous run, create new folder if needed

}
Process{
    If($InputCSV){
        #Get the groups and teams based on the provided CSV file
        Write-LogEntry -LogName:$Log -LogEntryText "Getting Groups, Teams and Sites based on CSV File..." -ForegroundColor Yellow
        $GroupsToQuery = Import-Csv -Path $InputCSV | Select-Object -expandproperty PrimarySMTPAddress
        $GroupsToQuery | %{Get-UnifiedGroup -Identity $_ } | Export-CSV -Path $GroupsCSV -NoTypeInformation -Append
        $GroupsToQuery | %{Get-Team -MailNickName $_.split("@")[0]} | Export-CSV -Path $TeamsCSV -NoTypeInformation -Append
        $GroupsToQuery | %{Get-PnPTenantSite -url ((Get-UnifiedGroup -Identity $_).SharePointSiteUrl)} | Export-CSV -Path $SitesCSV -NoTypeInformation -Append

        #Join Groups Properties with Teams Properties 
        $ListOfGroups = Import-Csv -Path $GroupsCSV
        $ListOfTeams = Import-Csv -Path $TeamsCSV
        Join-Object -Left $ListOfGroups -Right $ListOfTeams -LeftJoinProperty ExternalDirectoryObjectId -RightJoinProperty GroupId -Prefix 'TEAMS_' -Type AllInLeft | Export-CSV $TeamsGroupsCSV -NoTypeInformation
        
        #Join Groups/Teams Properties with Sites Properties
        $ListOfGroupsTeams = Import-Csv -Path $TeamsGroupsCSV
        $ListOfSites = Import-Csv -Path $SitesCSV
        Join-Object -Left $ListOfGroupsTeams -Right $ListOfSites -LeftJoinProperty SharePointSiteUrl -RightJoinProperty Url -Prefix 'SPO_' -Type AllInLeft | Export-CSV $TeamsGroupsSitesCSV -NoTypeInformation

        #Simple export with only some properties
        $ListOfGroupsTeamsSites = Import-Csv $TeamsGroupsSitesCSV | Select-Object $SimpleColumns
        $ListOfGroupsTeamsSites | Export-CSV -Path $TeamsGroupsSitesCSV_Simple -NoTypeInformation -Append

        #Custom columns report
        If($Properties){
            $ListOfGroupsTeamsSites = Import-Csv $TeamsGroupsSitesCSV | Select-Object $Properties
            $ListOfGroupsTeamsSites | Export-CSV -Path $TeamsGroupsSitesCSV_Custom -NoTypeInformation -Append
        }

        #Export membership
        If($IncludeMembership){
            Export-OwnersMembersGuests $ListOfGroupsTeams 
        }
    }
    Else{
        #Get All Groups and Teams and Export to CSV
        Write-LogEntry -LogName:$Log -LogEntryText "Getting All Groups, Teams, and Sites. This can take some time..." -ForegroundColor Yellow
        Get-Team | Export-CSV -Path $TeamsCSV -NoTypeInformation -Append
        Get-UnifiedGroup -ResultSize Unlimited | Export-CSV -Path $GroupsCSV -NoTypeInformation -Append
        Get-PNPTenantSite | Export-CSV -Path $SitesCSV -NoTypeInformation -Append

        #Join Groups Properties with Teams Properties 
        $ListOfGroups = Import-Csv -Path $GroupsCSV
        $ListOfTeams = Import-Csv -Path $TeamsCSV
        Join-Object -Left $ListOfGroups -Right $ListOfTeams -LeftJoinProperty ExternalDirectoryObjectId -RightJoinProperty GroupId -Prefix 'TEAMS_' -Type AllInLeft | Export-CSV $TeamsGroupsCSV -NoTypeInformation
        
        #Join Groups/Teams Properties with Sites Properties
        $ListOfGroupsTeams = Import-Csv -Path $TeamsGroupsCSV
        $ListOfSites = Import-Csv -Path $SitesCSV
        Join-Object -Left $ListOfGroupsTeams -Right $ListOfSites -LeftJoinProperty SharePointSiteUrl -RightJoinProperty Url -Prefix 'SPO_' -Type AllInLeft | Export-CSV $TeamsGroupsSitesCSV -NoTypeInformation

        #Simple export with only some properties
        $ListOfGroupsTeamsSites = Import-Csv $TeamsGroupsSitesCSV | Select-Object $SimpleColumns
        $ListOfGroupsTeamsSites | Export-CSV -Path $TeamsGroupsSitesCSV_Simple -NoTypeInformation -Append

        #Custom columns report
        If($Properties){
            $ListOfGroupsTeamsSites = Import-Csv $TeamsGroupsSitesCSV | Select-Object $Properties
            $ListOfGroupsTeamsSites | Export-CSV -Path $TeamsGroupsSitesCSV_Custom -NoTypeInformation -Append
        }

        #Export membership
        If($IncludeMembership){
            Export-OwnersMembersGuests $ListOfGroupsTeams 
        }
    }
}

End{
    #Complete run
    ""
    Reset-DirectoryToNew -Path $tempDirectory #cleanup temp directory files
    Write-LogEntry -LogName:$Log -LogEntryText "Results: $($output)"  -ForegroundColor Green
    Write-LogEntry -LogName:$Log -LogEntryText "Total Elapsed Time: $($elapsed.Elapsed.ToString())"  -ForegroundColor Green
}


