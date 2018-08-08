<#
.DESCRIPTION
###############Disclaimer#####################################################
THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
###############Disclaimer#####################################################
Script to copy channels and files from one Team to another. Useful for consolidating teams and reducing team sprawl.
What this script does: 
1. Establish connection to Microsoft Teams and Azure Active Directory in the user's context.
2. Prompt user for source and target teams.
3. Read and report source and target team membership, compare and prompt whether or not to add members missing from target team.
	If current user is owner in target team, add members/owners to target team. 
4. Loop through source channels and either confirm they exist in the target team or create them.
5. Copy the files from each source channel into the corresponding target channel.

CREDIT: 
    Built from the great work of all the individuals who contributed to published code examples.
VERSION:
    v1.20180601
AUTHOR(S): 
    Jayme Bowers - jaymeb@microsoft.com
.EXAMPLE
#Run the script with no switches.
.\Move-Teams.ps1
#>

#REGION FUNCTIONS

Function Set-Mode{
	#Prompt for run mode: REPORT or EXECUTE

    try {
        #initialize variables
	    $runMode = "REPORT"
        $introduction = "============================================================================================================`r`n"
	    $introduction = $introduction + "This script runs in one of two modes: REPORT or EXECUTE.`r`n"
	    $introduction = $introduction + "REPORT mode is a READ-ONLY mode that logs information such as the source and target teams you select,`r`n member list comparisons, channel list comparisons, etc.`r`n"
	    $introduction = $introduction + "EXECUTE mode makes changes to the teams you select, adding members (if you have rights),`r`n adding channels, and copying files.`r`n"
	    $introduction = $introduction + "SELECT EXECUTE MODE ONLY IF YOU ARE READY TO MAKE CHANGES.`r`n"
	    $introduction = $introduction + "============================================================================================================`r`n"
        clear-host
        write-host $introduction
    
        #warn user about Teams UX caveat
        write-host "INFORMATION: Team membership changes occur immediately but may take one or more hours to appear in the Teams app.`r`n" -ForegroundColor Yellow

        #prompt for run mode. if anything other than "1" remain in REPORT mode.
	    $runModeText = "Select run mode:`r`n0: REPORT `r`n1: EXECUTE`r`n"	
        $runModeInput = read-host $runModeText
	    if($runModeInput -eq "1") {
		    $runMode = "EXECUTE"		
	    }
	    $LogEntryText = "RUN MODE: " + $runMode
	    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Yellow
	    return $runMode
    }
    catch {
        $ErrorMessage = $_.Exception.Message
		Write-LogEntry -LogName:$Log -LogEntryText "$ErrorMessage" -foregroundcolor Red
		exit
    }
}

Function Connect-to-Service{
	#get O365 credentials. Use existing creds if available and user confirms.
	try {
		if ($credential -eq $null) {
			$credential = Get-Credential
		}
		else {
			$confirmation = Read-Host "Use existing credentials (y/n)?"
			if ($confirmation -ne 'y' -and $confirmation -ne 'yes') {
				$credential = Get-Credential
			}
		}
		return $credential
	}
	catch {
		$ErrorMessage = $_.Exception.Message
        if($ErrorMessage -eq "" -or $ErrorMessage -eq $null) {
            $ErrorMessage = "One or more errors occurred. Try the following:`r`n"
            $ErrorMessage = $ErrorMessage + "1. Check your network connection.`r`n"
            $ErrorMessage = $ErrorMessage + "2. Re-enter credentials when prompted.`r`n"
            $ErrorMessage = $ErrorMessage + "3. Run the script from a new PowerShell window."
        }
		Write-LogEntry -LogName:$Log -LogEntryText "$ErrorMessage" -foregroundcolor Red
		exit
	}
}

Function Identify-Teams{
	#Identify source and target teams
	
	try {
        #Connect to Microsoft Teams
	    Connect-MicrosoftTeams -Credential $global:credential
	    #get teams of which I'm a member
	    $myTeams = Get-Team

	    # Build menu of available teams and prompt to identify source and target teams.
	    $teamcount = 0
	    $menutext = ""
	    foreach($team in $myTeams) {
		    $menutext = $menutext + $teamcount.ToString() + " " + $team.DisplayName + "`r`n"
		    $teamcount++
	    }
	    #Identify SOURCE team
	    Write-Host "Identify the SOURCE team by number:" -ForegroundColor Cyan
	    $sourceTeamIndex = read-host $menutext
	    $sourceTeam = $myTeams.Get($sourceTeamIndex)
	    write-host "Source team: "$sourceTeam.DisplayName
	    #Identify TARGET team
	    Write-Host "Identify the TARGET team by number:" -ForegroundColor Cyan
	    $targetTeamIndex = read-host $menutext
	    $targetTeam = $myTeams.Get($targetTeamIndex)
	    write-host "Target team: "$targetTeam.DisplayName
	
	    #Confirm source and target are identified correctly
	    $confirmation = Read-Host "Are the source and target teams identified correctly (y/n)?"
			    if ($confirmation -ne 'y' -and $confirmation -ne 'yes') {
				    $LogEntryText = "Source and target teams unconfirmed. Terminating process..."
				    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
				    exit
			    }
			    else {
                    $LogEntryText = "SOURCE team: " + $sourceTeam.DisplayName + " (" + $sourceTeam.GroupId + "). "
                    $LogEntryText = $LogEntryText + "Target team: " + $targetTeam.DisplayName + " (" + $targetTeam.GroupId + ")."
                    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                    #return the selected teams as an array
				    $SourceAndTargetTeams = $sourceTeam, $targetTeam
				    return $SourceAndTargetTeams
			    }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
	    Write-LogEntry -LogName:$Log -LogEntryText "$ErrorMessage" -foregroundcolor Red
	    exit
    }
}

Function Process-Membership{
	param(
		[object[]]$SourceAndTargetTeams
	)
	#Read source and target team membership and - based on user input - add members/owners missing from target team.
	#NOTE: Current user must be an owner in the target team in order to add members.
	#Otherwise, REPORT additions needed.
    #*** TEAM MEMBERSHIP CHANGES ARE NOT REFLECTED IN MICROSOFT TEAMS IMMEDIATELY ***
	
    try {
	    $LogEntryText = "Processing team memership...`r`nListing source and target team membership..."
	    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Cyan

        #
        #// BEGIN List the source and target team memberships...
        #
        #get the ID of the source team
        $sourceTeamID = [string]$SourceAndTargetTeams.Get(0).GroupId
        #get the member list of the source team
	    $sourceTeamUsers = Get-TeamUser -GroupId $sourceTeamId
	    $LogEntryText = "`r`nSource team members:"
        #build an array of source team members [DisplayName, UPN, Role]...
	    $teamUserArray = @(
		    foreach($teamuser in $sourceTeamUsers) {
			    New-Object PSObject -Property @{Name = $teamuser.Name; User = $teamuser.User; Role = $teamuser.Role}
			    $LogEntryText = $LogEntryText + "`r`n" + $teamuser.Name + "(" + $teamuser.user + "), " + $teamuser.Role
		    }
	    )
        #get the ID of the target team
        $targetTeamID = $SourceAndTargetTeams.Get(1).GroupId.ToString()
        #get the member list of the target team
	    $targetTeamUsers = Get-TeamUser -GroupId $targetTeamId
	    $LogEntryText = $LogEntryText + "`r`n`r`n" + "Target team members:"
        #build an array of target team members [DisplayName, UPN, Role]...
	    foreach($teamuser in $targetTeamUsers) {
		    $LogEntryText = $LogEntryText + "`r`n" + $teamuser.Name + "(" + $teamuser.user + "), " + $teamuser.Role
	    }
        $LogEntryText = $LogEntryText + "`r`n"	
        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
        #
        #// END List the source and target team memberships.
        #
        #// BEGIN Update target membership list. EXECUTE mode only, if user is owner.
        #
        if($runmode -eq "EXECUTE") {
            #keep track of the number of members added to the team
            [int]$membersAddedCount = 0
            #prompt whether or not to add members/owners to target team.
            $AddMembers = $false
            $AddMembersInput = read-host "`r`nDo you want to add members of the source team to the target team (y/n)?"
		    if ($AddMembersInput -eq 'y' -or $AddMembersInput -eq 'yes') {
			    $AddMembers = $true
		    }
            else { 
                #if not, then exit function
                return 
            }
            #prompt whether or not to add users as owners if they are owners in the source team.
            $AddOwners = $false
            $AddOwnersInput = read-host "`r`nDo you want owners of the SOURCE team to be added as owners to the TARGET team, if they are not already present (y/n)?"
		    if ($AddOwnersInput -eq 'y' -or $AddOwnersInput -eq 'yes') {
			    $AddOwners = $true
		    }
            #loop through source membership, check for user in target membership, add if not present
            foreach($sourceTeamUser in $sourceTeamUsers) {
                $sourceUserFound = $false
                foreach($targetTeamUser in $targetTeamUsers) {
                    if($sourceTeamUser.User -eq $targetTeamUser.User) {
                        $sourceUserFound = $true
                        $LogEntryText = "Found in target: " + $targetTeamUser.Name + "(" + $targetTeamUser.User + ")"
                        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                        break
                    }
                }
                #if user not found in target member list, add the user
                if($sourceUserFound -eq $false) {
                    if($AddOwners -eq $false) {
                        #NOTE: The -Role param of Add-TeamUser doesn't yet accept Guest as an option, as of this script's creation date.
                        #      So, we must account for this.
                        if($sourceTeamUser.Role -eq "guest") {
                            $LogEntryText = $sourceTeamUser.Name + "(" + $sourceTeamUser.User + ") couldn't be added. Guests must be added manually."
                        }
                        else {
                            #add new users as members, based on user input
                            Add-TeamUser -GroupId $targetTeamID -User $sourceTeamUser.User -Role Member
                            $LogEntryText = "Added: " + $sourceTeamUser.Name + "(" + $sourceTeamUser.User + "), member"
                        }
                    }
                    else {
                        #based on user input, add new users as owners if they are owners in the source team; otherwise, add as members.
                        if($sourceTeamUser.Role -eq "owner") {
                            Add-TeamUser -GroupId $targetTeamID -User $sourceTeamUser.User -Role Owner
                            $membersAddedCount++
                            $LogEntryText = "Added: " + $sourceTeamUser.Name + "(" + $sourceTeamUser.User + "), " + $sourceTeamUser.Role
                        }
                        elseif($sourceTeamUser.Role -eq "member") {
                            Add-TeamUser -GroupId $targetTeamID -User $sourceTeamUser.User -Role Member
                            $membersAddedCount++
                            $LogEntryText = "Added: " + $sourceTeamUser.Name + "(" + $sourceTeamUser.User + "), " + $sourceTeamUser.Role
                        }
                        elseif($sourceTeamUser.Role -eq "guest") {
                            #NOTE: The -Role param of Add-TeamUser doesn't yet accept Guest as an option, as of this script's creation date.
                            $LogEntryText = $sourceTeamUser.Name + "(" + $sourceTeamUser.User + ") couldn't be added. Guests must be added manually."
                        }
                    }
                    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                }
            }
            $LogEntryText = $membersAddedCount.ToString() + " member(s) added."
            Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
        }
        #
        #// END Update target membership list. EXECUTE mode only, if user is owner.
        #
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-LogEntry -LogName:$Log -LogEntryText $ErrorMessage -ForegroundColor White
    }
}

Function Process-Channels{
	param(
		[object[]]$SourceAndTargetTeams
	)
    try {
	    #Create corresponding channels in the target team
	    $LogEntryText = "Processing channels..."
	    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Cyan

	    #get source and target channels
        $sourceTeamChannels = Get-TeamChannel -GroupId $SourceAndTargetTeams.Get(0).GroupId
	    $targetTeamChannels = Get-TeamChannel -GroupId $SourceAndTargetTeams.Get(1).GroupId

	    #loop through source channels, creating corresponding target channels (if in EXECUTE run mode); skip if already present
	    $found = $false
	    foreach($sourceTeamChannel in $sourceTeamChannels) {
		    write-host
		    $LogEntryText = "Processing channel:" + $sourceTeamChannel.DisplayName
		    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
		    foreach($targetTeamChannel in $targetTeamChannels) {
			    if($sourceTeamChannel.DisplayName -eq $targetTeamChannel.DisplayName) {
				    $found = $true
				    $LogEntryText = $sourceTeamChannel.DisplayName + " channel already exists. Do not create."
				    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
			    }
		    }
		    if($found -eq $false) {
                if($runmode -eq "EXECUTE") {
			        $LogEntryText = "Attempt to create channel: " + $sourceTeamChannel.DisplayName
			        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
			        try {
                        $targetTeamID = $SourceAndTargetTeams.Get(1).GroupId
				        $newTargetTeamChannel = New-TeamChannel -GroupId $targetTeamID -DisplayName $sourceTeamChannel.DisplayName -Description $sourceTeamChannel.Description
				        $LogEntryText = "Channel created."
				        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
			        }
			        catch {
				        $ErrorMessage = $_.Exception.Message
				        if($ErrorMessage -match "NameAlreadyExists") {
					        $LogEntryText = "Channel could not be created. The name already exists in the target team indicating it may have been recently deleted. Check for deleted channels under Manage Team > Channels > Deleted."
				        }
				        else {
					        $LogEntryText = $ErrorMessage
				        }
					    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
			        }
                }
                else {
                    #REPORT mode...
                    $LogEntryText = $sourceTeamChannel.DisplayName + " channel not found in target team. Running the script in EXECUTE mode would attempt to create it."
                    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                }
		    }
		    $found = $false
	    }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-LogEntry -LogName:$Log -LogEntryText $ErrorMessage -ForegroundColor White
    }
}

Function Process-Files {
	param(
		[object[]]$SourceAndTargetTeams
	)
	#Copy files and folders from the source channel to the target channel
    try {
	    $LogEntryText = "Processing files and folders..."
	    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Cyan

        #get the source and target team URLs
        $sourceTeamSite = [string]$SourceAndTargetTeams.Get(0).DisplayName
        $sourceTeamSite = $sourceTeamSite.Replace(" ", "")
        $sourceBaseURL = "/sites/$sourceTeamSite/Shared%20Documents"
        $targetTeamSite = [string]$SourceAndTargetTeams.Get(1).DisplayName
        $targetTeamSite = $targetTeamSite.Replace(" ", "")
        $targetBaseURL = "/sites/$targetTeamSite"
        #get base URL for the SPO connection
        $AAD = Connect-AzureAD -Credential $credential
        $tenantDomain = $AAD.TenantDomain
        $domainHost = $tenantDomain -replace $tenantDomain.Substring($tenantDomain.Length-16), ""
        $baseURL = "https://" + $domainHost + ".sharepoint.com"
        #connect to SPO
        $pnpConnection = Connect-PnPOnline -Url $baseURL -Credentials $credential -ReturnConnection:$true
        if($pnpConnection.ConnectionType -ne "O365") {
            $LogEntryText = "Unable to establish Sharepoint Online connection."
            Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Yellow
            exit
        }
        #copy files and folders
        #Copy-PnPFile -SourceUrl /sites/SourceTeam/Shared%20Documents -TargetUrl /sites/DestinationTeam
	    #get source and target channels
        $sourceTeamChannels = Get-TeamChannel -GroupId $SourceAndTargetTeams.Get(0).GroupId
	    $targetTeamChannels = Get-TeamChannel -GroupId $SourceAndTargetTeams.Get(1).GroupId
        #loop through source channels, find each target channel, and copy files
	    $found = $false
	    foreach($sourceTeamChannel in $sourceTeamChannels) {
		    write-host
		    $LogEntryText = "Processing file copy for channel:" + $sourceTeamChannel.DisplayName
		    Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
		    foreach($targetTeamChannel in $targetTeamChannels) {
			    if($sourceTeamChannel.DisplayName -eq $targetTeamChannel.DisplayName) {
				    $found = $true
                    break
			    }
		    }
            #if there is a matching channel in the target team, copy files
            if($found -eq $true) {
                #Copy-PnPFile -SourceUrl /sites/SourceTeam/Shared%20Documents -TargetUrl /sites/DestinationTeam
                $sourceChannelName = [string]$sourceTeamChannel.DisplayName
                $sourceChannelName = $sourceChannelName.Replace(" ", "%20")
			    $sourceURL = $sourceBaseURL + "/" + $sourceChannelName
                $targetChannelName = [string]$targetTeamChannel.DisplayName
                $targetChannelName = $targetChannelName.Replace(" ", "%20")
                $targetURL = $targetBaseURL + "/Shared%20Documents"
                if($runmode -eq "EXECUTE") {
                    $LogEntryText = "Copying files for channel: " + $sourceTeamChannel.DisplayName + ".`r`nFrom " + $sourceURL + " to " + $targetURL
			        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                    Copy-PnPFile -SourceUrl $sourceURL -TargetUrl $targetURL -OverwriteIfAlreadyExists
                }
                else {
                    #REPORT mode...
                    $LogEntryText = "Files to copy for channel: " + $sourceTeamChannel.DisplayName + ".`r`nFrom " + $sourceURL + " to " + $targetURL
			        Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor White
                }
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        if($ErrorMessage -match "Forbidden") {
            $LogEntryText = $ErrorMessage + "`r`nTry re-entering credentials."
            Write-LogEntry -LogName:$Log -LogEntryText $LogEntryText -ForegroundColor Cyan
        }
        else {
            Write-LogEntry -LogName:$Log -LogEntryText $ErrorMessage -ForegroundColor Cyan
        }
    }
}

Function Write-LogEntry {
#CREDIT: Phil Braniff
    param(
        [string] $LogName,
        [string] $LogEntryText,
		[string] $ForegroundColor
    )
    try {
        if ($LogName -NotLike $null) {
            # log the date and time in the text file along with the data passed
            "$([DateTime]::Now.ToShortDateString()) $([DateTime]::Now.ToShortTimeString()) : $LogEntryText" | Out-File -FilePath $LogName -append;
            if ($ForeGroundColor -NotLike $null) {
                # write to the shell window using ForegroundColor specified
                write-host $LogEntryText -ForegroundColor $ForeGroundColor
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-LogEntry -LogName:$Log -LogEntryText $ErrorMessage -ForegroundColor Cyan
    }
}
#END REGION FUNCTIONS

#REGION MAIN

#initialize variables
$yyyymmdd = Get-Date -Format 'yyyymmdd'
$Log = "$PSScriptRoot\Move-Team-$yyyymmdd.log"
$user = $env:USERNAME
Write-LogEntry -LogName:$Log -LogEntryText "User: $user" -foregroundcolor White

#set the run mode
$global:runmode = Set-Mode

#connect to Microsoft Teams
$global:credential = Connect-to-Service

#identify the source and target teams
$SourceAndTargetTeams = Identify-Teams
#remove extraneous elements so the returned array only contains the source and target teams
$SourceAndTargetTeams = $SourceAndTargetTeams | where{$_.GroupId -ne $null}

Process-Membership $SourceAndTargetTeams
Process-Channels $SourceAndTargetTeams
Process-Files $SourceAndTargetTeams

#END REGION MAIN
