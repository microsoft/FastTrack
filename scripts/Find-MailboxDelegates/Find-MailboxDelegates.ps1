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

We have developed this script because cross premises permissions are not supported with Exchange Hybrid environments: https://technet.microsoft.com/en-us/library/jj906433(v=exchg.150).aspx.
With this script you can export Exchange 2010/2013 on premises permissions, find their associated delegates, and produce a report of mailboxes with their recommended batch to minimize impact to those users.   

Requirement: Active Directory Module

Steps performed by the script: 
 
    1)Collect permissions 
    2)Find batches based on the output permissions
    3)Create Migration schedule (this is built in the format required by the Microsoft FastTrack Mail Migration team).

*For extra large environments with many mailboxes, you may consider running multiple instances of the script. For example: 
    1)Create multiple csv files that has different emails each. The number of csv files depends on the number of powershell sessions you will have going in parallel.
    2)Spin up multiple powershell sessions and run the script pointed at different InputMailboxesCSV files
    3)Merge the permissions output files from each script into one singular permissions file
    4)Run one of the scripts with the -BatchUsers - this will bypass collecting permissions and jump straight into batching users using the permissinos output in the same directory as the script  

=========================================
Version: 
    12062019: Add Permissions Only switch to skip steps 2 & 3
    08232019: AccountResourceEnv switch add 
    05012019: Update cross domain check
	06262018: Update group enumeration cross domain logic
    06122018: Update group enumeration logic

Authors: 
Alejandro Lopez - alejanl@microsoft.com
Sam Portelli - Sam.Portelli@microsoft.com

Contributors:
Francesco Poli - Francesco.Poli@microsoft.com
=========================================

.PARAMETER InputMailboxesCSV
Use this parameter to specify a list of users to collect permissions for, rather than all mailboxes.
Make sure that the CSV file provided has a header titled "PrimarySMTPAddress"

.PARAMETER ExcludeServiceAcctsCSV
In cases where you have service accounts with permissions to a large number of mailboxes, e.g. Blackberry service accounts, you can use this to exclude those accounts from the batching processing. 
Provide the path to a csv file (no header needed) with each service account primarySMTPaddress on its own line. 
 
*This will slow down processing. 

.PARAMETER FullAccess
Collect Full Access permissions. Keep in mind that "Full Access" permissions are now supported in cross premises scenarios. Not including "Full Access" will speed up processing. 

.PARAMETER SendOnBehalfTo
Collect SendOnBehalfTo permissions

.PARAMETER Calendar
Collect calendar permissions

.PARAMETER SendAs
Collect Send As permissions

.PARAMETER EnumerateGroups
This will enumerate groups that have permissions to mailboxes and include in the batching logic.

*This will slow down processing.

.PARAMETER ExcludeGroupsCSV
Use this to exclude groups that you don't want to enumerate. Provide the path to a csv file (no header needed) with each group name on its own line. 

.PARAMETER ExchServerFQDN
Connect to a specific Exchange Server

.PARAMETER Resume
Use this to resume the script in case of a failure while running the script on a large number of users. This way you don't have to start all over.
The way this works is that it will look for the progress xml file where it keeps track of mailboxes that are pending processing.
Make sure not to use in conjunction with the InputMailboxesCSV switch.

.PARAMETER BatchUsers
Use this if you want to skip collecting permissions and only run Step 2 and Step 3. 
Make sure you have the permissions output file in the same directory (Find-MailboxDelegates-Permissions.csv).

.PARAMETER BatchUsersOnly
Use this if you want to skip collecting permissions (step1) and creating a migration schedule (step 3). This won't require an active exchange session, but make sure you have the permissions output file in the same directory (Find-MailboxDelegates-Permissions.csv).

.PARAMETER GetPermissionsOnly
Use this switch to run Step 1 only (Get Permissions). This will skip steps 2&3 which does the spider web batching and creates a migration schedule. 

.PARAMETER AccountResourceEnv
Switch to run the script taking into account an Account/Resource environment

.EXAMPLE
#Export only SendOnBehalfTo and Send As permissions and Enumerate Groups for all mailboxes.  
.\Find-MailboxDelegates.ps1 -SendOnBehalfTo -SendAs -EnumerateGroups

.EXAMPLE
#Export only Full Access and Send As permissions and Enumerate Groups for the provided user list. Make sure to use "PrimarySMTPAddress" as header. 
.\Find-MailboxDelegates.ps1 -InputMailboxesCSV "C:\Users\administrator\Desktop\userlist.csv" -FullAccess -SendAs -EnumerateGroups

.EXAMPLE
#Resume the script after a script interruption and failure to pick up on where it left off. Make sure to include the same switches as before EXCEPT the InputMailboxesCSV otherwise it'll yell at you
.\Find-MailboxDelegates.ps1 -FullAccess -SendAs -EnumerateGroups -Resume

.EXAMPLE
#Export all permissions and enumerate groups for all mailboxes
.\Find-MailboxDelegates.ps1 -FullAccess -SendOnBehalfTo -SendAs -Calendar -EnumerateGroups 

.EXAMPLE
#Export all permissions but don't enumerate groups for all mailboxes
.\Find-MailboxDelegates.ps1 -FullAccess -SendOnBehalfTo -SendAs -Calendar

.EXAMPLE
#Export all permissions and exclude service accounts for all mailboxes
.\Find-MailboxDelegates.ps1 -FullAccess -SendOnBehalfTo -SendAs -Calendar -ExcludeServiceAcctsCSV "c:\serviceaccts.csv" 

.EXAMPLE
#Export all permissions and exclude service accounts for all mailboxes
.\Find-MailboxDelegates.ps1 -FullAccess -SendOnBehalfTo -SendAs -Calendar -ExcludeServiceAcctsCSV "c:\serviceaccts.csv" -ExcludeGroupsCSV "c:\groups.csv"

.EXAMPLE
#Skip collect permissions (assumes you already have a permissions output file) and only run Step 2 to batch users

.\Find-MailboxDelegates.ps1 -BatchUsersOnly

.EXAMPLE
#Skip collect permissions (assumes you already have a permissions output file) and only run Step 2 and 3 to batch users and creation migration schedule file
.\Find-MailboxDelegates.ps1 -BatchUsers

#>

param(
    [string]$InputMailboxesCSV,
    [switch]$FullAccess,
    [switch]$SendOnBehalfTo,
    [switch]$Calendar,
    [switch]$SendAs,
    [switch]$EnumerateGroups,
    [string]$ExcludeServiceAcctsCSV,
    [string]$ExcludeGroupsCSV,
    [string]$ExchServerFQDN,
    [switch]$Resume,
    [switch]$BatchUsers, 
    [switch]$BatchUsersOnly,
    [switch]$GetPermissionsOnly, 
    [switch]$AccountResourceEnv
)

Begin{
    try{

        #region functions
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

        <# Get-RecipientCustom
            Perform a fail safe Get-Recipient to handle resource forest model where the users permissions are assigned to domain\user in the account
            forest, that is not resolvable in the Resource domain. Upon get-recipient failure it will try to find a mailbox with the linkedMasterAccount
            associate, and use it as reference for batch grouping
        #>
        Function Get-RecipientCustom{
            param(
                [string]$recipient
            )
            $error.Clear()
            try
            { 
                $del=Get-Recipient -Identity $recipient -ErrorAction stop
            }
            catch 
            {
                if ( $error[0].Exception.ToString() -like "*The operation couldn't be performed because object*couldn't be found on*")
                {
                   $external = $Script:mailboxesLookup | where {$_.linkedmasteraccount -eq $recipient}

                   if ($external) {
                        $del = Get-Recipient -Identity $external.identity.tostring() -ErrorAction silentlyContinue
                        if ($del) 
                        {
                            $error.Clear()
                            return $del
                        }
                        else 
                        { 
                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found external linked account $recipient associated to $($external.identity) mailbox, but cannot get the Recipient property"
                            return $null
                        }
                   }
                   Else
                   {
                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Unable to find Mailbox with LinkedMasterAccount associated to $recipient" 
                        return $null
                   }
                }
        
            }
            return $del
        }

        Function Get-GroupCustom{
            param(
                [string]$Identity
            )
            $error.Clear()
            try
            { 
                #$del=Get-Group -Identity $group -ErrorAction stop
                $group = Get-Group -identity $Identity -ErrorAction SilentlyContinue
            }
            catch 
            {
                if ( $error[0].Exception.ToString() -like "*The operation couldn't be performed because object*couldn't be found on*")
                {
                    $domain = $Identity.split("\")[0]
                    $remoteDC = Get-ADDomainController -discover -domain $domain 
                    try{
                        $group = get-group -identity $Identity -DomainController $remoteDC.hostname -erroraction silentlyContinue
                        return $group
                    }
                    catch{
                        return $null
                    }
                }
            }
            return $group
        }

        Function Get-Permissions(){
	            param(
                    [string]$UserEmail,
                    [bool]$gatherfullaccess,
                    [bool]$gatherSendOnBehalfTo,
                    [bool]$gathercalendar,
                    [bool]$gathersendas,
                    [bool]$EnumerateGroups,
                    [string[]]$ExcludedGroups,
                    [string[]]$ExcludedServiceAccts
                )

                try{
                    

                    #Variables
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Get Permissions for: $($UserEmail)"
                    $CollectPermissions = New-Object System.Collections.Generic.List[System.Object] 
                    $Error.Clear()
                    $Mailbox = Get-mailbox $UserEmail -EA SilentlyContinue
                    If(!$Mailbox){
                        throw "Problem getting mailbox for $($UserEmail) : $($error)" 
                    }
                    $globalCatalog = ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().GlobalCatalogs | Select-Object -First 1 -ExpandProperty Name) + ":3268"

                    #Enumerate Groups/Send As - moving this part outside of the function for faster processing
                    <#
                    If(($EnumerateGroups -eq $true) -or ($gathersendas -eq $true)){
                        $dse = [ADSI]"LDAP://Rootdse"
                        $ext = [ADSI]("LDAP://CN=Extended-Rights," + $dse.ConfigurationNamingContext)
                        $dn = [ADSI]"LDAP://$($dse.DefaultNamingContext)"
                        $dsLookFor = new-object System.DirectoryServices.DirectorySearcher($dn)

                        $permission = "Send As"
                        $right = $ext.psbase.Children | ? { $_.DisplayName -eq $permission }
                    }
                    #>
            
                    If($gathercalendar -eq $true){
                        $Error.Clear()
	                    $CalendarPermission = Get-MailboxFolderPermission -Identity ($Mailbox.alias + ':\Calendar') -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ?{$_.User -notlike "Anonymous" -and $_.User -notlike "Default"} | Select User, AccessRights
	                    if (!$CalendarPermission){
                            $Calendar = (($Mailbox.PrimarySmtpAddress.ToString())+ ":\" + (Get-MailboxFolderStatistics -Identity $Mailbox.DistinguishedName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | where-object {$_.FolderType -eq "Calendar"} | Select-Object -First 1).Name)
                            $CalendarPermission = Get-MailboxFolderPermission -Identity $Calendar -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | ?{$_.User -notlike "Anonymous" -and $_.User -notlike "Default"} | Select User, AccessRights
	                    }
            
                        If($CalendarPermission){
                            Foreach($perm in $CalendarPermission){
                                #$ifGroup = Get-Group -identity $perm.user.tostring() -ErrorAction SilentlyContinue
                                $ifGroup = Get-GroupCustom -identity $perm.user.tostring() -ErrorAction SilentlyContinue
                                If($ifGroup){
                                    If($EnumerateGroups -eq $true){
				                        If(-not ($excludedGroups -contains $ifGroup.Name)){
                                            $groupDomainName = $ifgroup.identity.tostring().split("/")[0]
                                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : Calendar : Enumerate Group $($ifGroup.distinguishedName) Domain Name: $groupDomainName"
                                            #$lstUsr = Get-AdGroup -identity $ifGroup.Name -Server $groupDomainName | Get-ADGroupMember -Recursive | Get-ADUser -Properties Mail
                                            $lstUsr = Get-ADGroupMember -identity $ifGroup.distinguishedName -server $groupDomainName -Recursive | Get-ADUser -Properties Mail | ?{$_.Mail}

	                                        foreach ($usrTmp in $lstUsr) {
                                                $usrTmpEmail = $usrTmp.Mail
                                                If($ExcludedServiceAccts){
                                                    if(-not ($ExcludedServiceAccts -contains $usrTmpEmail -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : CalendarFolder : $($usrTmpEmail)"
                                                        $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Calendar Folder"})
                                                    }
                                                }
                                                Else{
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : CalendarFolder : $($usrTmpEmail)"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Calendar Folder"})
                                                }
	                                        }
				                        }
                                    }
                                }
                                Else{
                                    If($perm.user.adrecipient.primarysmtpaddress -ne $null){                               
                                        $delegate = Get-RecipientCustom $perm.user.adrecipient.primarysmtpaddress.tostring().replace(":\Calendar","")

                                        If($mailbox.primarySMTPAddress -and $delegate.primarySMTPAddress){
                                            If(-not ($mailbox.primarySMTPAddress.ToString() -eq $delegate.primarySMTPAddress.ToString())){
                                                If($ExcludedServiceAccts){
                                                    if(-not ($ExcludedServiceAccts -contains $delegate.primarySMTPAddress.tostring() -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : CalendarFolder : $($delegate.primarySMTPAddress.ToString())"
                                                        $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Calendar Folder"})
                                                    }
                                                }
                                                Else{
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : CalendarFolder : $($delegate.primarySMTPAddress.ToString())"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Calendar Folder"})
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        If($Error){
                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "MBX=$($Mailbox.PrimarySMTPAddress) PERM=CalendarFolder ERROR=$($error[0].ToString()) POSITION=$($error[0].InvocationInfo.PositionMessage)"
                        }
                    }

                    If($gatherfullaccess -eq $true){
                        $Error.Clear()
                        $FullAccessPermissions = Get-MailboxPermission -Identity ($Mailbox.PrimarySMTPAddress).tostring() | ? {($_.AccessRights -like “*FullAccess*”) -and ($_.IsInherited -eq $false) -and ($_.User -notlike “NT AUTHORITY\SELF”) -and ($_.User -notlike "S-1-5*") -and ($_.User -notlike $Mailbox.PrimarySMTPAddress)}
                
                        If($FullAccessPermissions){
                            Foreach($perm in $FullAccessPermissions){
                                #$ifGroup = Get-Group -identity $perm.user.tostring() -ErrorAction SilentlyContinue 
                                $ifGroup = Get-GroupCustom -identity $perm.user.tostring() -ErrorAction SilentlyContinue
                                If($ifGroup){
                                    If($EnumerateGroups -eq $true){
				                        If(-not ($excludedGroups -contains $ifGroup.Name)){
                                            $groupDomainName = $ifgroup.identity.tostring().split("/")[0]
                                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : FullAccess : Enumerate Group $($ifGroup.distinguishedName) Domain Name: $groupDomainName"
                                            #$lstUsr = Get-AdGroup -identity $ifGroup.distinguishedName | Get-ADGroupMember -Recursive | Get-ADUser -Properties Mail $globalCatalog
                                            $lstUsr = Get-ADGroupMember -identity $ifGroup.distinguishedName -server $groupDomainName -Recursive | Get-ADUser -Properties Mail | ?{$_.Mail}

	                                        foreach ($usrTmp in $lstUsr) {
                                                $usrTmpEmail = $usrTmp.Mail
                                                If($ExcludedServiceAccts){
                                                    if(-not ($ExcludedServiceAccts -contains $usrTmpEmail -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : FullAccess : $($usrTmpEmail)"
                                                        $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Full Access"})
                                                    }
                                                }
                                                Else{
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : FullAccess : $($usrTmpEmail)"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Full Access"})
                                                }
	                                        }
				                        }
                                    }
                                }
                                Else{
                                    #$delegate = Get-Recipient -Identity $perm.user.tostring() -ErrorAction SilentlyContinue
                                    $delegate = Get-RecipientCustom $perm.user.tostring()
                        
                                    If($mailbox.primarySMTPAddress -and $delegate.primarySMTPAddress){
							            If(-not ($mailbox.primarySMTPAddress.ToString() -eq $delegate.primarySMTPAddress.ToString())){
                                            If($ExcludedServiceAccts){
                                                if(-not ($ExcludedServiceAccts -contains $delegate.primarySMTPAddress.tostring() -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : FullAccess : $($delegate.primarySMTPAddress.ToString())"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Full Access"})
                                                }
                                            }
                                            Else{
                                                Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : FullAccess : $($delegate.primarySMTPAddress.ToString())"
                                                $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Full Access"})
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        If($Error){
                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "MBX=$($Mailbox.PrimarySMTPAddress) PERM=FullAccess ERROR=$($error[0].ToString()) POSITION=$($error[0].InvocationInfo.PositionMessage)"
                        }
                    }

                    If($gathersendas -eq $true){
                        $Error.Clear()
                        #$SendAsPermissions = Get-ADPermission $Mailbox.DistinguishedName | ?{($_.ExtendedRights -like "*send-as*") -and ($_.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY\SELF") }
                
                        $SendAsPermissions = New-Object System.Collections.Generic.List[System.Object] 
                        $userDN = [ADSI]("LDAP://$($mailbox.DistinguishedName)")
                        $userDN.psbase.ObjectSecurity.Access | ? { ($_.ObjectType -eq [GUID]$right.RightsGuid.Value) -and ($_.IsInherited -eq $false) } | select -ExpandProperty identityreference | %{
				            If(-not ($_ -like "NT AUTHORITY\SELF")){
					            $SendAsPermissions.add($_)
				            }
			            }
                

                        If($SendAsPermissions){
                            Foreach($perm in $SendAsPermissions){
                                #$ifGroup = Get-Group -identity $perm.tostring() -ErrorAction SilentlyContinue
                                $ifGroup = Get-GroupCustom -identity $perm.tostring() -ErrorAction SilentlyContinue
                                If($ifGroup){
                                    If($EnumerateGroups -eq $true){
				                        If(-not ($ExcludedGroups -contains $ifGroup.Name)){
                                            $groupDomainName = $ifgroup.identity.tostring().split("/")[0]
                                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendAs : Enumerate Group $($ifGroup.distinguishedName) Domain Name: $groupDomainName"
                                            #$lstUsr = Get-AdGroup -identity $ifGroup.distinguishedName -Server $groupDomainName | Get-ADGroupMember -Recursive | Get-ADUser -Properties Mail -server $globalCatalog
                                            $lstUsr = Get-ADGroupMember -identity $ifGroup.distinguishedName -server $groupDomainName -Recursive | Get-ADUser -Properties Mail | ?{$_.Mail}

	                                        foreach ($usrTmp in $lstUsr) {
                                                $usrTmpEmail = $usrTmp.Mail
                                                If($ExcludedServiceAccts){
                                                    if(-not ($ExcludedServiceAccts -contains $usrTmpEmail -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendAs : $($usrTmpEmail)"
                                                        $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Send As"})
                                                    }
                                                }
                                                Else{
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendAs : $($usrTmpEmail)"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $usrTmpEmail; AccessRights = "Send As"})
                                                }
	                                        }
				                        }
                                    }
                                }
                                Else{
                                    #$delegate = Get-Recipient -Identity $perm.tostring() -ErrorAction SilentlyContinue
                                    $delegate = Get-RecipientCustom $perm.tostring()
                        
                                    If($mailbox.primarySMTPAddress -and $delegate.primarySMTPAddress){
							            If(-not ($mailbox.primarySMTPAddress.ToString() -eq $delegate.primarySMTPAddress.ToString())){
								            If($ExcludedServiceAccts){
                                                if(-not ($ExcludedServiceAccts -contains $delegate.primarySMTPAddress.tostring() -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendAs : $($delegate.primarySMTPAddress.ToString())"
                                                    $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Send As"})
                                                }
                                            }
                                            Else{
                                                Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendAs : $($delegate.primarySMTPAddress.ToString())"
                                                $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "Send As"})
                                            }
                                        }
                                    }
                                }
                            }    
                        }

                        If($Error){
                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "MBX=$($Mailbox.PrimarySMTPAddress) PERM=SendAs ERROR=$($error[0].ToString()) POSITION=$($error[0].InvocationInfo.PositionMessage)"
                        }
                    }

                    If($gatherSendOnBehalfTo -eq $true){
                        $Error.Clear()
                        $GrantSendOnBehalfToPermissions = $Mailbox.grantsendonbehalfto.ToArray()

                        If($GrantSendOnBehalfToPermissions){
                            Foreach($perm in $GrantSendOnBehalfToPermissions){
                                #$delegate = Get-Recipient -Identity $perm.tostring() -ErrorAction SilentlyContinue
                                $delegate = Get-RecipientCustom $perm.tostring()
                        
                                If($mailbox.primarySMTPAddress -and $delegate.primarySMTPAddress){
							        If(-not ($mailbox.primarySMTPAddress.ToString() -eq $delegate.primarySMTPAddress.ToString())){
                                        If($ExcludedServiceAccts){
                                            if(-not ($ExcludedServiceAccts -contains $delegate.primarySMTPAddress.tostring() -or $ExcludedServiceAccts -contains $mailbox.primarySMTPAddress.ToString())){
                                                Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendOnBehalfTo : $($delegate.primarySMTPAddress.ToString())"
                                                $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "SendOnBehalfTo"})
                                            }
                                        }
                                        Else{
                                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Found permission : SendOnBehalfTo : $($delegate.primarySMTPAddress.ToString())"
                                            $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = $delegate.primarySMTPAddress.ToString(); AccessRights = "SendOnBehalfTo"})
                                        }
                                    }
                                }
                            }
                        }
                        
                        If($Error){
                            Write-LogEntry -LogName:$Script:LogFile -LogEntryText "MBX=$($Mailbox.PrimarySMTPAddress) PERM=SendOnBehalfTo ERROR=$($error[0].ToString()) POSITION=$($error[0].InvocationInfo.PositionMessage)"
                        }
                    }
                    
                    
                    
                    If($CollectPermissions.Count -eq 0){
                        #write progress to xml file
                        $updateXML = [System.Xml.XmlDocument](Get-Content $ProgressXMLFile)
                        $node = $updateXML.Mailboxes.Mailbox | ?{$_.Name -eq $Mailbox.PrimarySMTPAddress}
                        If($node -ne $null){
                            $node.Progress = "Completed"
                        }
                        $updateXML.save($ProgressXMLFile)
                        $CollectPermissions.add([pscustomobject]@{Mailbox = $Mailbox.PrimarySMTPAddress; User = "None"; AccessRights = "None"})
                        Return $CollectPermissions
                    }
                    else{
                        #write progress to xml file
                        $updateXML = [System.Xml.XmlDocument](Get-Content $ProgressXMLFile)
                        $node = $updateXML.Mailboxes.Mailbox | ?{$_.Name -eq $Mailbox.PrimarySMTPAddress}
                        If($node -ne $null){
                            $node.Progress = "Completed"
                        }
                        $updateXML.save($ProgressXMLFile)
                        Return $CollectPermissions
                    }
                }
                catch{
                    $updateXML = [System.Xml.XmlDocument](Get-Content $ProgressXMLFile)
                    $node = $updateXML.Mailboxes.Mailbox | ?{$_.Name -eq $UserEmail}
                    If($node -ne $null){
                        $node.Progress = "Failed"
                    }
                    $updateXML.save($ProgressXMLFile)
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "MBX=$($UserEmail) ERROR=$($_.exception.message) POSITION=$($_.InvocationInfo.Line) $($_.InvocationInfo.PositionMessage)"
                }
            }

        Function ConnectTo-Exchange ($ExchServerFQDN) {
            #Connect to Exchange
            if (Test-Path $env:ExchangeInstallPath\bin\RemoteExchange.ps1){
	            . $env:ExchangeInstallPath\bin\RemoteExchange.ps1 | out-null
                
	            If(!$ExchServerFQDN){
                    Connect-ExchangeServer -auto -AllowClobber | Out-Null
                }
                Else{
                    Connect-ExchangeServer -serverfqdn $ExchServerFQDN -AllowClobber | Out-Null
                }
            }
            else{
                Write-LogEntry -LogName:$LogFile -LogEntryText "Exchange Server management tools are not installed on this computer." -ForegroundColor Red 
                EXIT
            }

            #Method #2 to connect using remote powershell
            <#
                If($ExchServerFQDN){
                    try{
                        ""
                        #If want to save creds without having to enter password into Get-Credential every time
                        #$password = "Password" | ConvertTo-SecureString -asPlainText -Force
                        #$username = "administrator@contoso.com" 
                        #$Creds = New-Object System.Management.Automation.PSCredential($username,$password)

                        #$ExchServerFQDN = "$env:computername.$env:userdnsdomain"
	                    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServerFQDN/PowerShell/ -Authentication Kerberos -WarningAction 'SilentlyContinue' -ErrorAction SilentlyContinue
                        If(!$session){
                            $Creds = Get-Credential -Message "Unable to connect using current credentials. Enter account credentials that has permissions to connect to Exchange"
                            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServerFQDN/PowerShell/ -Authentication Kerberos -Credential $Creds -WarningAction 'SilentlyContinue' 
                            If(!$session){
                                throw
                            }
                        }
	                    $Connect = Import-Module (Import-PSSession $Session -AllowClobber -WarningAction 'SilentlyContinue' -DisableNameChecking) -Global -WarningAction 'SilentlyContinue'
                    }
                    catch{
                        throw "Unable to establish a session with the Exchange Server: $($ExchServerFQDN)"
                        exit
                    }
                }
                Else{
                    #check if a session already exists
                    $error.clear()
                    get-command get-mailbox -ErrorAction SilentlyContinue | out-null
                    If($error){
                        try{
                            ""
                            #If want to save creds without having to enter password into Get-Credential every time
                            #$password = "Password" | ConvertTo-SecureString -asPlainText -Force
                            #$username = "administrator@contoso.com" 
                            #$Creds = New-Object System.Management.Automation.PSCredential($username,$password)

                            $ExchServerFQDN = "$env:computername.$env:userdnsdomain"
	                        $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServerFQDN/PowerShell/ -Authentication Kerberos -WarningAction 'SilentlyContinue' -ErrorAction SilentlyContinue
                            If(!$session){
                                $ExchServerFQDN = Read-host "Type in the FQDN of the Exchange Server to connect to"
                                $Creds = Get-Credential -Message "Enter credentials to connect to exchange on premises"
                                $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServerFQDN/PowerShell/ -Authentication Kerberos -Credential $Creds -WarningAction 'SilentlyContinue' 
                                If(!$session){
                                    throw
                                }
                            }
	                        $Connect = Import-Module (Import-PSSession $Session -AllowClobber -WarningAction 'SilentlyContinue' -DisableNameChecking) -Global -WarningAction 'SilentlyContinue'
                        }
                        catch{
                            throw "Unable to establish a session with the Exchange Server: $($ExchServerFQDN)"
                            exit
                        }
                    }
                }

            #>

        }
        
        Function Create-Batches(){
                param(
                    [string]$InputPermissionsFile
                )
		
                #Variables
                If(-not (Test-Path $InputPermissionsFile)){
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "$($InputPermissionsFile) file not found. Check the log file for more info: $LogFile" -ForegroundColor Red
                    exit 
                }
                If((get-childitem $InputPermissionsFile).length -eq 0 ){
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "The permissions file is empty. Check the log file for more info: $LogFile" -ForegroundColor Red
                    exit 
                }
                Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Run function: Create-Batches" -ForegroundColor White 
    
                $data = import-csv $InputPermissionsFile
                $hashData = $data | Group Mailbox -AsHashTable -AsString
	            $hashDataByDelegate = $data | Group user -AsHashTable -AsString
	            $usersWithNoDependents = New-Object System.Collections.ArrayList
                $batch = @{}
                $batchNum = 0
                $hashDataSize = $hashData.Count
                $yyyyMMdd = Get-Date -Format 'yyyyMMdd'
	
                try{
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Build ArrayList for users with no dependents"
                    If($hashDataByDelegate["None"].count -gt 0){
		                $hashDataByDelegate["None"] | %{$_.Mailbox} | %{[void]$usersWithNoDependents.Add($_)}
	                }	    

                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Identify users with no permissions on them, nor them have perms on another" 
	                If($usersWithNoDependents.count -gt 0){
		                $($usersWithNoDependents) | %{
			                if($hashDataByDelegate.ContainsKey($_)){
				                $usersWithNoDependents.Remove($_)
			                }	
		                }
            
                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Remove users with no dependents from hash" 
		                $usersWithNoDependents | %{$hashData.Remove($_)}
		                #Clean out hashData of users in hash data with no delegates, otherwise they'll get batched
                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Clean out hashData of users in hash with no delegates"  
		                foreach($key in $($hashData.keys)){
                                if(($hashData[$key] | select -expandproperty user ) -eq "None"){
				                $hashData.Remove($key)
			                }
		                }
	                }
                    #Execute batch functions
                    If(($hashData.count -ne 0) -or ($usersWithNoDependents.count -ne 0)){
                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Run function: Find-Links" -ForegroundColor White  
                        while($hashData.count -ne 0){Find-Links $hashData | out-null} 
                        Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Run function: Create-BatchFile" -ForegroundColor White
                        Create-BatchFile $batch $usersWithNoDependents
                    }
                }
                catch {
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Error: $_"
                }
            }

        Function Find-Links($hashData){
                try{
                    $nextInHash = $hashData.Keys | select -first 1
                    $batch.Add($nextInHash,$hashData[$nextInHash])
	
	                Do{
		                $checkForMatches = $false
		                foreach($key in $($hashData.keys)){
			                Write-Progress -Activity "Step 2 of 3: Analyze Delegates" -status "Items remaining: $($hashData.Count)" -percentComplete (($hashDataSize-$hashData.Count) / $hashDataSize*100)
			
	                        #Checks
			                $usersHashData = $($hashData[$key]) | %{$_.mailbox}
                            $usersBatch = $($batch[$nextInHash]) | %{$_.mailbox}
                            $delegatesHashData = $($hashData[$key]) | %{$_.user} 
			                $delegatesBatch = $($batch[$nextInHash]) | %{$_.user}

			                $ifMatchesHashUserToBatchUser = [bool]($usersHashData | ?{$usersBatch -contains $_})
			                $ifMatchesHashDelegToBatchDeleg = [bool]($delegatesHashData | ?{$delegatesBatch -contains $_})
			                $ifMatchesHashUserToBatchDelegate = [bool]($usersHashData | ?{$delegatesBatch -contains $_})
			                $ifMatchesHashDelegToBatchUser = [bool]($delegatesHashData | ?{$usersBatch -contains $_})
			
			                If($ifMatchesHashDelegToBatchDeleg -OR $ifMatchesHashDelegToBatchUser -OR $ifMatchesHashUserToBatchUser -OR $ifMatchesHashUserToBatchDelegate){
	                            if(($key -ne $nextInHash)){ 
					                $batch[$nextInHash] += $hashData[$key]
					                $checkForMatches = $true
	                            }
	                            $hashData.Remove($key)
	                        }
	                    }
	                } Until ($checkForMatches -eq $false)
        
                    return $hashData
	            }
	            catch{
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Error: $_" -ForegroundColor Red 
                }
            }

        Function Create-BatchFile($batchResults,$usersWithNoDepsResults){
	            try{
                     "Batch,User" > $Script:BatchesFile
	                 foreach($key in $batchResults.keys){
                        $batchNum++
                        $batchName = "BATCH-$batchNum"
		                $output = New-Object System.Collections.ArrayList
		                $($batch[$key]) | %{$output.add($_.mailbox) | out-null}
		                $($batch[$key]) | %{$output.add($_.user) | out-null}
		                $output | select -Unique | % {
                           "$batchName"+","+$_ >> $Script:BatchesFile
		                }
                     }
	                 If($usersWithNoDepsResults.count -gt 0){
		                 $batchNum++
		                 foreach($user in $usersWithNoDepsResults){
		 	                #$batchName = "BATCH-$batchNum"
                            $batchName = "BATCH-NoDependencies"
			                "$batchName"+","+$user >> $Script:BatchesFile
		                 }
	                 }
                 }
                 catch{
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Error: $_" -ForegroundColor Red  
                 }
            } 

        Function Create-MigrationSchedule(){
                param(
                    [string]$InputBatchesFile 
                )
	            try{
                    If(-not (Test-Path $InputBatchesFile)){
                        throw [System.IO.FileNotFoundException] "$($InputBatchesFile) file not found."
                    }
                    $usersFromBatch = import-csv $InputBatchesFile
                    "Migration Date(MM/dd/yyyy),Migration Window,Migration Group,PrimarySMTPAddress,SuggestedBatch,MailboxSize(MB),Notes" > $Script:MigrationScheduleFile
                    $userInfo = New-Object System.Text.StringBuilder
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Number of users in the migration schedule: $($usersFromBatch.Count)" -ForegroundColor White

                    $usersFromBatchCounter = 0
                    foreach($item in $usersFromBatch){
                        $usersFromBatchCounter++
                        $usersFromBatchRemaining = $usersFromBatch.count - $usersFromBatchCounter
                        Write-Progress -Activity "Step 3 of 3: Creating migration schedule" -status "Items remaining: $($usersFromBatchRemaining)" -percentComplete (($usersFromBatchCounter / $usersFromBatch.count)*100)

                       #Check if using UseImportCSVFile and if yes, check if the user was part of that file, otherwise mark 
                       $isUserPartOfInitialCSVFile = ""
                       If($Script:InputMailboxesCSV -ne ""){
                        If(-not ($Script:ListOfMailboxes.PrimarySMTPAddress -contains $item.user)){
                            $isUserPartOfInitialCSVFile = "User was not part of initial csv file"
                        }
                       }

                       $user = get-user $item.user #-erroraction SilentlyContinue
		   
                       If(![string]::IsNullOrEmpty($user.WindowsEmailAddress)){
			             If($user.recipienttype -eq "UserMailbox"){ 
                          $mbStats = Get-MailboxStatistics $user.WindowsEmailAddress.tostring() | select totalitemsize
			                If($mbStats.totalitemsize.value)
                            {
                                #if connecting through remote pshell, and not using Exo server shell, the data comes as 
                                #TypeName: Deserialized.Microsoft.Exchange.Data.ByteQuantifiedSize
                                if ( ($mbStats.TotalItemSize.Value.GetType()).name.ToString() -eq "ByteQuantifiedSize")
                                {
                                    $mailboxSize =  $mbStats.totalitemsize.value.ToMb()
                                }
                                else
                                {
                                    $mailboxSize =  $mbStats.TotalItemSize.Value.ToString().split("(")[1].split(" ")[0].replace(",","")/1024/1024
                                }
                                
			                }
			                Else{
                                $mailboxSize = 0
                            }

                           $userInfo.AppendLine(",,,$($user.WindowsEmailAddress),$($item.Batch),$($mailboxSize),$isUserPartOfInitialCSVFile") | Out-Null
                         }
                       }
		               Else{ #there was an error either getting the user from Get-User or the user doesn't have an email address
					       $userInfo.AppendLine(",,,$($item.user),$($item.Batch),n/a,,User not found or doesn't have an email address") | Out-Null
		               }
                    }
                    $userInfo.ToString().TrimEnd() >> $Script:MigrationScheduleFile
                }
                catch{
                    Write-LogEntry -LogName:$Script:LogFile -LogEntryText "Error: $($_) at $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
                }
            }

        Function CleanUp-PreviousRun() {
            try{
                If(test-path $PermsOutputFile){Remove-item -path $PermsOutputFile}
                If(test-path $BatchesFile){Remove-item -path $BatchesFile} 
                If(test-path $MigrationScheduleFile){Remove-item -path $MigrationScheduleFile}
                #$ProgressXMLFile doesn't have to be wiped since this is recreated every time
                Write-LogEntry -LogName:$LogFile -LogEntryText "Successfully cleaned up previous run results."
            }
            catch{
                Write-LogEntry -LogName:$LogFile -LogEntryText "Unable to clean up csv outputs from previous run. This needs to be done to avoid mixed results. ERROR=$($_) " -ForegroundColor Red
                exit
            }
        }
        #endregion functions

        #Script Variables
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $scriptPath = $PSScriptRoot
        $yyyyMMdd = Get-Date -Format 'yyyyMMdd'
        $LogFile = "$scriptPath\Find-MailboxDelegates-$yyyyMMdd.log"
        $PermsOutputFile = "$scriptPath\Find-MailboxDelegates-Permissions.csv"
        $BatchesFile = "$scriptPath\Find-MailboxDelegates-Batches.csv"
        $MigrationScheduleFile = "$scriptPath\Find-MailboxDelegates-Schedule.csv"
        $ProgressXMLFile = "$scriptPath\Find-MailboxDelegates-Progress.xml"
        $Version = "12062019"
        $computer = $env:COMPUTERNAME
        $user = $env:USERNAME

        $WarningPreference = "SilentlyContinue"
        $ErrorActionPreference = "SilentlyContinue"

        ""
        Write-LogEntry -LogName:$LogFile -LogEntryText "User: $user Computer: $computer ScriptVersion: $Version PowershellVersion: $($PSVersionTable.PSVersion.Major)" -foregroundcolor Yellow
        ""
        Write-LogEntry -LogName:$LogFile -LogEntryText "Script parameters passed: $($PSBoundParameters.GetEnumerator())" 
        ""
        Write-LogEntry -LogName:$LogFile -LogEntryText "Pre-flight Check" -ForegroundColor Green 
        
        #Requirement is Powershell V3 in order to use PSCustomObjets which are data structures
        If($PSVersionTable.PSVersion.Major -lt 3){
            throw "Powershell V3+ is required. If you're running from Exchange Shell, it may be defaulting to PS2.0. Run 'powershell -version 3' and re-run the script."
        }

        #Run only the batch users step if the switch BatchUsersOnly switch has been added
        If($BatchUsersOnly -and $GetPermissionsOnly){
            Throw "Can't have both 'BatchUsersOnly' and 'GetPermissionsOnly' switches. Please use one or the other. "
            exit   
        }
        ElseIf($BatchUsersOnly){
            Write-LogEntry -LogName:$LogFile -LogEntryText "Running only Step #2: Batch Users..." -ForegroundColor Yellow
            Create-Batches -InputPermissionsFile $PermsOutputFile
            exit     
        }

        #Check switches provided are acceptable
        If($BatchUsers -and ($FullAccess -or $SendOnBehalfTo -or $Calendar -or $SendAs -or $InputMailboxesCSV -or $EnumerateGroups -or $ExcludeServiceAccts -or $ExcludeGroups -or $Resume -or $AccountResourceEnv)){
            throw "BatchUsers can't be combined with these other switches."
        }
        If(!$FullAccess -and !$SendOnBehalfTo -and !$Calendar -and !$SendAs -and !$BatchUsers -and !$BatchUsersOnly){
            throw "Include the switches for the permissions you want to query on. Check the read me file for more details."
        }

        $testSession = get-command get-mailbox -ErrorAction SilentlyContinue
        If(!$testSession){
            Write-LogEntry -LogName:$LogFile -LogEntryText "Didn't find an active exchange session. Initiating..." -ForegroundColor Gray 
            ConnectTo-Exchange $ExchServerFQDN | Out-Null
            ""
        }
        $exchserversession = get-pssession | ?{$_.configurationname -eq "Microsoft.Exchange"} | select -expandproperty computername 
        $exchangeversion = get-exchangeserver $exchserversession | select -expandproperty AdminDisplayVersion
        Write-LogEntry -LogName:$LogFile -LogEntryText "ExchangeServerName: $($exchserversession) ExchangeServerVersion: $($exchangeversion)" 
        ""

        #Open connection to AD - this will be used to enumerate groups and collect Send As permissions
        $checkADModule = get-module -listavailable activedirectory
        If($checkADModule -eq $null){
            throw "Please install the Active Direcotry Module: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd378937(v=ws.10) "
        }
        Import-Module -Name ActiveDirectory

        If(($EnumerateGroups -eq $true) -or ($SendAs -eq $true)){ 
            $dse = [ADSI]"LDAP://Rootdse"
            $ext = [ADSI]("LDAP://CN=Extended-Rights," + $dse.ConfigurationNamingContext)
            $dn = [ADSI]"LDAP://$($dse.DefaultNamingContext)"
            $dsLookFor = new-object System.DirectoryServices.DirectorySearcher($dn)

            $permission = "Send As"
            $right = $ext.psbase.Children | ? { $_.DisplayName -eq $permission }
        }

        #Check if re-running the script without resume. Clean outputs from previous run to prevent data corruption
        If((!$Resume) -and (test-path $PermsOutputFile) -and (!$BatchUsers) -and (!$BatchUsersOnly)){
            Write-LogEntry -LogName:$LogFile -LogEntryText "Clean up previous run to avoid mixed results" -ForegroundColor Yellow
            CleanUp-PreviousRun
        }

        #Set scope to find objects in other domains
        Set-AdServerSettings -ViewEntireForest $True

        #Used for Acccount/Resource models
        If($AccountResourceEnv){
            Write-LogEntry -LogName:$LogFile -LogEntryText "Creating Mailboxes lookup table for Account/Resource Environment" -ForegroundColor Gray 
            $Script:mailboxesLookup = Get-Mailbox -ResultSize Unlimited
        }

        #Get Mailboxes
        If($Resume){
            If(!$InputMailboxesCSV){
                If(test-path $ProgressXMLFile){
                    $xmlDoc = [System.Xml.XmlDocument](Get-Content $ProgressXMLFile)
                    $ListOfMailboxes = $xmlDoc.mailboxes.mailbox | ?{$_.Progress -eq "Pending"} | select @{N="PrimarySMTPAddress";E={$_.name}} #-expandproperty name               
                }
                else{
                    throw "Unable to resume due to missing progress file: $($ProgressXMLFile)"
                    exit
                }
            }
            Else{
            throw "Can't have both 'Resume' and 'InputMailboxesCSV' at the same time. Choose 'Resume' if you want to pick up on where you left off from a previous run."
            exit
            }        
        }
        ElseIf(!$Batchusers){
            If($InputMailboxesCSV -ne ""){
                $ListOfMailboxes = Import-Csv $InputMailboxesCSV
                if($ListOfMailboxes.PrimarySMTPAddress -eq $null){
                    throw "Make sure the input csv file header is: PrimarySMTPAddress"
                    exit
                }

                #write to xml for progress tracking
                [xml]$xmlDoc = New-Object System.Xml.XmlDocument
                $dec = $xmlDoc.CreateXmlDeclaration("1.0","UTF-8",$null)
                $xmlDoc.AppendChild($dec) | Out-Null
                $root = $xmlDoc.CreateNode("element","Mailboxes",$null)
                foreach($entry in $ListOfMailboxes.PrimarySMTPAddress){
                    $mbx = $xmlDoc.CreateNode("element","Mailbox",$null)
                    $mbx.SetAttribute("Name",$entry)
                    $mbx.SetAttribute("Progress","Pending")
                    $root.AppendChild($mbx) | Out-Null
                }

                #add root to the document
                $xmlDoc.AppendChild($root) | Out-Null

                #save file
                $xmlDoc.save($ProgressXMLFile)
            }
            Else{
                If($mailboxesLookup){
                    $ListOfMailboxes = $mailboxesLookup | select PrimarySMTPAddress
                }
                Else{
                    $ListOfMailboxes = Get-Mailbox -ResultSize Unlimited | select PrimarySMTPAddress
                }

                #write to xml for progress tracking
                [xml]$xmlDoc = New-Object System.Xml.XmlDocument
                $dec = $xmlDoc.CreateXmlDeclaration("1.0","UTF-8",$null)
                $xmlDoc.AppendChild($dec) | Out-Null
                $root = $xmlDoc.CreateNode("element","Mailboxes",$null)
                foreach($entry in $ListOfMailboxes.PrimarySMTPAddress){
                    $mbx = $xmlDoc.CreateNode("element","Mailbox",$null)
                    $mbx.SetAttribute("Name",$entry)
                    $mbx.SetAttribute("Progress","Pending")
                    $root.AppendChild($mbx) | Out-Null
                }

                #add root to the document
                $xmlDoc.AppendChild($root) | Out-Null

                #save file
                $xmlDoc.save($ProgressXMLFile)
            }
        }

        #Get excluded groups
        If($ExcludeGroupsCSV){
         If(test-path $ExcludeGroupsCSV){
            $ExcludeGroups = get-content $ExcludeGroupsCSV
         }
         Else{
            throw "Unable to find the CSV file for excluded groups. Confirm this is the right directory: $($ExcludeGroupsCSV)"
            exit
         }   
        }

        #Get excluded service accts
        If($ExcludeServiceAcctsCSV){
         If(test-path $ExcludeServiceAcctsCSV){
            $ExcludeServiceAccts = get-content $ExcludeServiceAcctsCSV
         }
         Else{
            throw "Unable to find the CSV file for excluded service accounts. Confirm this is the right directory: $($ExcludeServiceAcctsCSV)"
            exit
         }   
        }

        Write-LogEntry -LogName:$LogFile -LogEntryText "Pre-flight Completed" -ForegroundColor Green 
        ""
    }

    catch{
        Write-LogEntry -LogName:$LogFile -LogEntryText "Pre-flight Failed: $_" -ForegroundColor Red 
        If($session){
            Remove-PSSession $Session
        }
        ""
		exit
	}
}
Process{
    ""
    If(!$BatchUsers){
        If($GetPermissionsOnly){
            Write-LogEntry -LogName:$LogFile -LogEntryText "Running Step #1 Only: Get Permissions..." -ForegroundColor Yellow
            If($Resume){Write-LogEntry -LogName:$LogFile -LogEntryText "Resume collect permissions based on xml file" -ForegroundColor White}
            Write-LogEntry -LogName:$LogFile -LogEntryText "Mailbox count: $($ListOfMailboxes.Count)" -ForegroundColor White
            $mailboxCounter = 0
            Foreach($mailbox in $ListOfMailboxes.PrimarySMTPAddress){
                $mailboxCounter++
                Write-Progress -Activity "Gathering Permissions" -status "Items processed: $($mailboxCounter) of $($ListOfMailboxes.Count)" -percentComplete (($mailboxCounter / $ListOfMailboxes.Count)*100)
                Get-Permissions -UserEmail $mailbox -gatherfullaccess $FullAccess -gatherSendOnBehalfTo $SendOnBehalfTo -gathercalendar $Calendar -gathersendas $SendAs -EnumerateGroups $EnumerateGroups -ExcludedGroups $ExcludeGroups -ExcludedServiceAccts $ExcludeServiceAccts | export-csv -path $PermsOutputFile -notypeinformation -Append
            }
            exit
        }
        Else{
            Write-LogEntry -LogName:$LogFile -LogEntryText "STEP 1 of 3: Collect Permissions..." -ForegroundColor Yellow
            If($Resume){Write-LogEntry -LogName:$LogFile -LogEntryText "Resume collect permissions based on xml file" -ForegroundColor White}
            Write-LogEntry -LogName:$LogFile -LogEntryText "Mailbox count: $($ListOfMailboxes.Count)" -ForegroundColor White
            $mailboxCounter = 0
            Foreach($mailbox in $ListOfMailboxes.PrimarySMTPAddress){
                $mailboxCounter++
                Write-Progress -Activity "Step 1 of 3: Gathering Permissions" -status "Items processed: $($mailboxCounter) of $($ListOfMailboxes.Count)" -percentComplete (($mailboxCounter / $ListOfMailboxes.Count)*100)
                Get-Permissions -UserEmail $mailbox -gatherfullaccess $FullAccess -gatherSendOnBehalfTo $SendOnBehalfTo -gathercalendar $Calendar -gathersendas $SendAs -EnumerateGroups $EnumerateGroups -ExcludedGroups $ExcludeGroups -ExcludedServiceAccts $ExcludeServiceAccts | export-csv -path $PermsOutputFile -notypeinformation -Append
            }
        }
    }
    ""
    Write-LogEntry -LogName:$LogFile -LogEntryText "STEP 2 of 3: Analyze Delegates..." -ForegroundColor Yellow
    Create-Batches -InputPermissionsFile $PermsOutputFile
    ""
    Write-LogEntry -LogName:$LogFile -LogEntryText "STEP 3 of 3: Create schedule..." -ForegroundColor Yellow
    Create-MigrationSchedule -InputBatchesFile $BatchesFile
    ""
}
End{
    #Cleanup PSSession
    If($session){
        Remove-PSSession $Session
    }
    Write-LogEntry -LogName:$LogFile -LogEntryText "Results: $($scriptPath)"  -ForegroundColor Green
    Write-LogEntry -LogName:$LogFile -LogEntryText "Total Elapsed Time: $($elapsed.Elapsed.ToString())"  -ForegroundColor Green
}