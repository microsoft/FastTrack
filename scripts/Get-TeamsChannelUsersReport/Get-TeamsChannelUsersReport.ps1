<#

Get-TeamsChannelUsersReport.ps1 PowerShell script | Version 1.2

by David.Whitney@microsoft.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

#>

<#
.SYNOPSIS
    Generate a report of channel user roles across teams
.DESCRIPTION
    Create a CSV file output that contains a row for each user that has a role in each channel of each or specified teams
.EXAMPLE
    .\Get-TeamsChannelUsersReport.ps1 -ExportCSVFilePath "C:\path\to\export.csv"

    Report on all teams
.EXAMPLE
    .\Get-TeamsChannelUsersReport.ps1 -GroupId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ExportCSVFilePath C:\path\to\export.csv

    Report on a specific team by its group ID
.EXAMPLE
    .\Get-TeamsChannelUsersReport.ps1 -UserId "user@domain.com" -ExportCSVFilePath C:\path\to\export.csv

    Report on teams that the specified user is a member or owner of
.EXAMPLE
    .\Get-TeamsChannelUsersReport.ps1 -ExportCSVFilePath "C:\path\to\export.csv" -IncludeIncomingSharedChannelsInReport

    Report on all teams, and include incoming shared channels - shared channels that have been shared from other teams into a given team.

    Warning: The -IncludeIncomingSharedChannelsInReport option may add significant time to generating the report depending on shared channel team sharing usage.
.OUTPUTS
    Writes out a CSV file report with columns:
    - Team Name
    - Group ID
    - Team Description
    - Team Privacy
    - Team Is Archived
    - Team Classification
    - Team Sensitivity Label
    - Channel Name
    - Channel Membership Type
    - Channel Description
    - Channel Member Name
    - Channel Member Role
    - Channel Member User ID
    - Channel Member Email
    - Shared Channel Shared Team ID
    - Shared Channel Shared Team Name
    
    - Incoming Shared Channel Host Team ID**
    - Incoming Shared Channel Host Tenant ID**

    **Only if `-IncludeIncomingSharedChannelsInReport` is specified in parameters while running script
#>
[CmdletBinding()]
param (
    # Path to where to save the report export CSV file
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [System.IO.FileInfo]
    $ExportCSVFilePath,

    # Provide specific group ID to only report on that team
    [Parameter(Mandatory = $false)]
    [Alias("TeamID")]
    [string]
    $GroupID,

    # Provide specific user ID to only report on the teams that user is a member or owner of
    [Parameter(Mandatory = $false)]
    [string]
    $UserID,

    # Optionally report on Shared channels that are "incoming" to a given team - those Shared channels that were shared to that team. WARNING: this may significantly increase report generation time.
    [Parameter(Mandatory = $false)]
    [switch]
    $IncludeIncomingSharedChannelsInReport
)

if ($GroupID -and $UserID) {
    Write-Warning "Group ID and User ID both provided - ignoring User ID"
}

# check for minimum required set of Microsoft Graph SDK for PowerShell sub-modules, and also avoid importing all the sub-modules
$MgModuleAuth  = Get-Module -Name "Microsoft.Graph.Authentication" -ListAvailable
$MgModuleGroup = Get-Module -Name "Microsoft.Graph.Groups"         -ListAvailable
$MgModuleUsers = Get-Module -Name "Microsoft.Graph.Users"          -ListAvailable
$MgModuleTeams = Get-Module -Name "Microsoft.Graph.Teams"          -ListAvailable
if (-not ($MgModuleGroup -and $MgModuleUsers -and $MgModuleTeams -and $MgModuleAuth)) {
    throw "This script requires the Microsoft.Graph (PowerShell SDK for Graph) module - use 'Install-Module Microsoft.Graph' from an elevated PowerShell session, restart this PowerShell session, then try again."
}
Import-Module Microsoft.Graph.Authentication -WarningAction SilentlyContinue -ErrorAction Stop
Import-Module Microsoft.Graph.Groups         -WarningAction SilentlyContinue -ErrorAction Stop
Import-Module Microsoft.Graph.Users          -WarningAction SilentlyContinue -ErrorAction Stop
Import-Module Microsoft.Graph.Teams          -WarningAction SilentlyContinue -ErrorAction Stop

# connect to Graph interactively (delegated permissions) with minimum required Read permission scopes
Connect-Graph -Scopes "Group.Read.All", "User.Read.All", "TeamMember.Read.All", "Channel.ReadBasic.All", "ChannelMember.Read.All", "Directory.AccessAsUser.All"

if ((Get-MgProfile).Name -ne "beta"){
    # if running script in a session where Select-MgProfile had been previously not set to beta, throw up a warning 
    #   that we are going to switch to beta which will affect the session even after script finishes
    Write-Warning "Switching current Graph SDK for PowerShell session from '$((Get-MgProfile).Name)' to 'beta'. Revert after this script finishes by running: Select-MgProfile `"$((Get-MgProfile).Name)`""
    Select-MgProfile -Name "beta" -ErrorAction Stop
}

$HomeTenantId = (Get-MgContext).TenantId
$HomeTenantName = (Get-MgOrganization -Property DisplayName).DisplayName
$ExternalTenantNameList = @{}

Write-Output "Gathering Teams data..."

if ($GroupID) {
    ## Get the specified group and check it is Teams-enabled ##
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting group ID $GroupID"
    # ask for assignedLabels in this call for the requested group since we can't ask for it when calling for the team
    $M365GroupIdWithProvisioning = Get-MgGroup -GroupId $GroupID -Property Id, DisplayName, Mail, resourceProvisioningOptions, assignedLabels -ErrorAction Stop
    if ($M365GroupIdWithProvisioning) {
        # note that the non-beta profile of Graph SDK for Get-MgGroup has resourceProvisioningOptions under AdditionalProperties
        # $M365GroupThatIsTeam = $M365GroupIdWithProvisioning | Where-Object {$_.AdditionalProperties.resourceProvisioningOptions -contains "Team"}
        $M365GroupThatIsTeam = $M365GroupIdWithProvisioning | Where-Object {$_.resourceProvisioningOptions -contains "Team"}

        if ($M365GroupThatIsTeam) {
            Write-Output "Found team $($M365GroupThatIsTeam.DisplayName) ($GroupID)"
            $M365GroupsThatAreTeams = @($M365GroupThatIsTeam)
        } else {
            throw "Group $($M365GroupIdWithProvisioning.DisplayName) ($GroupID) is not a Teams-enabled group"
        }
    }
} elseif ($UserID) {
    ## Get all groups the specified user is a member of that are Teams-enabled ##
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting groups for user ID $UserID"
    $User = Get-MgUser -UserId $UserID -ErrorAction Stop
    Write-Output "Found user $($User.DisplayName) ($UserID)"
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting groups for user ID $UserID - $($User.DisplayName)"
    if ($User) {
        $UserMemberOfIdsWithProvisioning = Get-MgUserMemberOf -UserId $UserID -Property displayName, Id, resourceProvisioningOptions, assignedLabels
        # MemberOf call returns directory roles as well (e.g. Teams Administrator), need to filter to just groups
        $UserGroupIdsWithProvisioning = $UserMemberOfIdsWithProvisioning | Where-Object {$_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.group"}
        $M365GroupsThatAreTeams = @($UserGroupIdsWithProvisioning | Where-Object {$_.AdditionalProperties.resourceProvisioningOptions -contains "Team"})
        # Add displayname to root of object as return from member of sticks displayName into the AdditionalProperties, where normal Get-MgGroup has it at root of return object
        $M365GroupsThatAreTeams | ForEach-Object {$_ | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $_.AdditionalProperties.displayName}
        if (!$M365GroupsThatAreTeams) {
            Write-Warning "User $($User.DisplayName) ($UserID) is not a member of any teams"
            Write-Progress -Id 1 -Activity "Gathering Teams Data" -Completed
            exit
        }
        Write-Output "Found $($M365GroupsThatAreTeams.count) teams user is a member of"
    }
} else {
    ## Get all groups that are Teams-enabled ##
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting list of M365 Groups"
    #ask for assignedLabels in this call for groups since we can't ask for it when calling for the team
    $M365GroupIdsWithProvisioning = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -Property Id, DisplayName, Mail, resourceProvisioningOptions, assignedLabels
    $M365GroupsThatAreTeams = $M365GroupIdsWithProvisioning | Where-Object {$_.resourceProvisioningOptions -contains "Team"}
    Write-Output "Found $($M365GroupsThatAreTeams.count) teams"
}

Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting Teams properties"
$currentTeamNum = 1
$totalTeamCount = $M365GroupsThatAreTeams.count
$ReportOutput = foreach ($group in $M365GroupsThatAreTeams) {

    ## Get team object ##
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting team properties" -CurrentOperation "$currentTeamNum of $totalTeamCount - $($group.DisplayName)" -PercentComplete (100 * $currentTeamNum / $totalTeamCount)
    $team = Get-MgTeam -TeamId $group.Id -Property Id, DisplayName, Description, Visibility, IsArchived, Classification
    # strip out unneeded fields in Get-MgTeam return so that we can add our own Channels and Members properties, since the return doesn't include that data
    $team = $team | Select-Object Id, DisplayName, Description, Visibility, IsArchived, Classification
    # add sensitivity label that we got from first call to get M365 Groups, since asking for assignedLabels is not supported for getting the team
    if ($group.AssignedLabels) {
        $team | Add-Member -NotePropertyName "AssignedLabel" -NotePropertyValue $group.AssignedLabels[0].DisplayName
    } else {
        $team | Add-Member -NotePropertyName "AssignedLabel" -NotePropertyValue ""
    }

    ## Get team members ##
    $teamMembers = Get-MgTeamMember -TeamId $team.Id
    [PSCustomObject[]]$teamMembersReturn = foreach ($member in $teamMembers) {
        [PSCustomObject]@{
            "Role" = if ($member.Roles) {$member.Roles -join ","} else {"member"};
            "DisplayName" = $member.DisplayName;
            "Mail" = $member.AdditionalProperties.email;
            "UserId" = $member.AdditionalProperties.userId;
            "TenantId" = $member.AdditionalProperties.tenantId;
        }
    }
    $team | Add-Member -NotePropertyName "Members" -NotePropertyValue $teamMembersReturn

    ## Get team channels and channel members if non-standard channel ##
    Write-Progress -Id 2 -ParentId 1 -Activity "Gathering Channel Data" -Status "Getting channels"

    # at least in beta, Get-MgTeamChannel will return all channels, including incoming channels, so we have to filter those out by comparing to explicit retrieve of incoming channels
    $allChannelsList = Get-MgTeamChannel -TeamId $team.Id -Property Id, DisplayName, Description, MembershipType    
    $incomingSharedChannelsList = Get-MgTeamIncomingChannel -TeamId $team.Id

    $channelsList = $allChannelsList | Where-Object {$incomingSharedChannelsList.Id -notcontains $_.Id}

    # strip out unneeded fields in Get-MgTeamChannel return so that we can add our own Members property, since the return doesn't include that data
    $channelsList = $channelsList | Select-Object Id, DisplayName, Description, MembershipType
    $incomingSharedChannelsList = $incomingSharedChannelsList | Select-Object Id, DisplayName, Description, MembershipType, AdditionalProperties
    
    Write-Progress -Id 2 -ParentId 1 -Activity "Gathering Channel Data" -Status "Getting channel members"
    $currentChannelNum = 1
    if ($IncludeIncomingSharedChannelsInReport) {
        $totalChannelCount = $allChannelsList.count
    } else {
        $totalChannelCount = $channelsList.count
    }
    
    [PSCustomObject[]]$channelsReturn = foreach ($channel in $channelsList) {

        ## Get team channel members ##
        Write-Progress -Id 2 -ParentId 1 -Activity "Gathering Channel Data" -Status "Getting channel members" -CurrentOperation "$currentChannelNum of $totalChannelCount - $($channel.DisplayName) ($($channel.MembershipType))" -PercentComplete (100 * $currentChannelNum / $totalChannelCount)

        # start with non-standard channels
        if (($channel.MembershipType -ne "standard")) {

            # if a private or shared channel, get channel members directly assigned to that channel
            $nonStandardChannelMembers = Get-MgTeamChannelMember -TeamId $team.Id -ChannelId $channel.Id
            [PSCustomObject[]]$nonStandardChannelMembersObject = foreach ($member in $nonStandardChannelMembers) {
                [PSCustomObject]@{
                    "Role" = if ($member.Roles) {$member.Roles -join ","} else {"member"};
                    "DisplayName" = $member.DisplayName;
                    "Mail" = $member.AdditionalProperties.email;
                    "UserId" = $member.AdditionalProperties.userId;
                    "TenantId" = $member.AdditionalProperties.tenantId;
                    "SharedChannelSharedTeamId" = $null;
                    "SharedChannelSharedTeamDisplayName" = $null;
                    "SharedChannelSharedTeamTenantId" = $null;
                    "IncomingSharedChannelHostTeamId" = $null;
                    "IncomingSharedChannelHostTenantId" = $null;
                }
            }

            ## If Shared channel, get shared with teams and transitive list of members ##
            if ($channel.MembershipType -eq "shared") {
                $sharedChannelSharedTeams = Get-MgTeamChannelShared -TeamId $team.Id -ChannelId $channel.Id -ErrorAction SilentlyContinue
                foreach ($sharedchannelSharedTeam in $sharedChannelSharedTeams) {
                    $sharedChannelSharedTeamMembers = Get-MgTeamChannelSharedWithTeamAllowedMember -TeamId $team.Id -ChannelId $channel.Id -SharedWithChannelTeamInfoId $sharedchannelSharedTeam.Id
                    [PSCustomObject[]]$sharedChannelSharedTeamMembersObject = foreach ($sharedChannelSharedTeamMember in $sharedChannelSharedTeamMembers) {
                        [PSCustomObject]@{
                            # transitive Shared channel permissions can only be Member - must be a directly assigned channel member to be a Shared channel Owner
                            "Role" = "member";
                            "DisplayName" = $sharedChannelSharedTeamMember.DisplayName;
                            "Mail" = $sharedChannelSharedTeamMember.AdditionalProperties.email;
                            "UserId" = $sharedChannelSharedTeamMember.AdditionalProperties.userId;
                            "TenantId" = $sharedChannelSharedTeamMember.AdditionalProperties.tenantId;
                            "SharedChannelSharedTeamId" = $sharedchannelSharedTeam.Id;
                            "SharedChannelSharedTeamDisplayName" = $sharedchannelSharedTeam.DisplayName;
                            "SharedChannelSharedTeamTenantId" = $sharedchannelSharedTeam.TenantId;
                            "IncomingSharedChannelHostTeamId" = $null;
                            "IncomingSharedChannelHostTenantId" = $null;
                        }
                    }
                    # add shared channel shared team members to the directly assigned channel members
                    if ($sharedChannelSharedTeamMembersObject) {
                        $nonStandardChannelMembersObject += $sharedChannelSharedTeamMembersObject
                    }
                }
                

            }
            $channel | Add-Member -NotePropertyName "Members" -NotePropertyValue $nonStandardChannelMembersObject
        } else {
            # standard channels do not have specific membership, would be same as parent team membership so not saving members here
            $channel | Add-Member -NotePropertyName "Members" -NotePropertyValue $null
        }
        $currentChannelNum++

        $channel
    }

    # incoming channels processing
    if ($IncludeIncomingSharedChannelsInReport) {
        [PSCustomObject[]]$incomingSharedChannelsReturn = foreach ($incomingSharedChannel in $incomingSharedChannelsList) {

            # update membership type to reflect incoming channel
            $incomingSharedChannel.MembershipType = "incoming shared"
            
            Write-Progress -Id 2 -ParentId 1 -Activity "Gathering Channel Data" -Status "Getting channel members" -CurrentOperation "$currentChannelNum of $totalChannelCount - $($incomingSharedChannel.DisplayName) ($($incomingSharedChannel.MembershipType))" -PercentComplete (100 * $currentChannelNum / $totalChannelCount)

            # extract host team and tenant data from incoming channel's graph "@odata.id" property
            $channelOdataIdExtractPattern = '^https\:\/\/graph\.microsoft\.com\/(beta|v1\.0)\/tenants\/(.+)\/teams\/(.+)\/channels\/(.+)$'
            $incomingSharedChannelOdataIdExtract = [regex]::Match($incomingSharedChannel.AdditionalProperties."@odata.id", $channelOdataIdExtractPattern)
            $incomingSharedChannelOdataIdExtractObject = [PSCustomObject]@{
                TenantId =  $incomingSharedChannelOdataIdExtract.Groups[2].Value;
                TeamId =    $incomingSharedChannelOdataIdExtract.Groups[3].Value;
                ChannelId = $incomingSharedChannelOdataIdExtract.Groups[4].Value;
            }

            if ($incomingSharedChannelOdataIdExtractObject.TenantId -eq $HomeTenantId) {
                
                $incomingSharedChannelMembers = Get-MgTeamChannelMember -TeamId $team.Id -ChannelId $incomingSharedChannel.Id
                [PSCustomObject[]]$incomingSharedChannelMembersObject = foreach ($incomingSharedChannelMember in $incomingSharedChannelMembers) {
                    [PSCustomObject]@{
                        "Role" = if ($member.Roles) {$member.Roles -join ","} else {"member"};
                        "DisplayName" = $incomingSharedChannelMember.DisplayName;
                        "Mail" = $incomingSharedChannelMember.AdditionalProperties.email;
                        "UserId" = $incomingSharedChannelMember.AdditionalProperties.userId;
                        "TenantId" = $incomingSharedChannelMember.AdditionalProperties.tenantId;
                        "SharedChannelSharedTeamId" = $null;
                        "SharedChannelSharedTeamDisplayName" = $null;
                        "SharedChannelSharedTeamTenantId" = $null;
                        "IncomingSharedChannelHostTeamId" = $incomingSharedChannelOdataIdExtractObject.TeamId;
                        "IncomingSharedChannelHostTenantId" = $incomingSharedChannelOdataIdExtractObject.TenantId;
                    }
                }

                $incomingSharedChannelSharedTeams = Get-MgTeamChannelShared -TeamId $incomingSharedChannelOdataIdExtractObject.TeamId -ChannelId $incomingSharedChannel.Id -ErrorAction SilentlyContinue

                foreach ($incomingSharedChannelSharedTeam in $incomingSharedChannelSharedTeams) {
                    $incomingSharedChannelSharedTeamMembers = Get-MgTeamChannelSharedWithTeamAllowedMember -TeamId $incomingSharedChannelOdataIdExtractObject.TeamId -ChannelId $incomingSharedChannel.Id -SharedWithChannelTeamInfoId $incomingSharedChannelSharedTeam.Id
                    [PSCustomObject[]]$incomingSharedChannelSharedTeamMembersObject = foreach ($incomingSharedChannelSharedTeamMember in $incomingSharedChannelSharedTeamMembers) {
                        [PSCustomObject]@{
                            # transitive Shared channel permissions can only be Member - must be a directly assigned channel member to be a Shared channel Owner
                            "Role" = "member";
                            "DisplayName" = $incomingSharedChannelSharedTeamMember.DisplayName;
                            "Mail" = $incomingSharedChannelSharedTeamMember.AdditionalProperties.email;
                            "UserId" = $incomingSharedChannelSharedTeamMember.AdditionalProperties.userId;
                            "TenantId" = $incomingSharedChannelSharedTeamMember.AdditionalProperties.tenantId;
                            "SharedChannelSharedTeamId" = $incomingSharedChannelSharedTeam.Id;
                            "SharedChannelSharedTeamDisplayName" = $incomingSharedChannelSharedTeam.DisplayName;
                            "SharedChannelSharedTeamTenantId" = $incomingSharedChannelSharedTeam.TenantId;
                            "IncomingSharedChannelHostTeamId" = $incomingSharedChannelOdataIdExtractObject.TeamId;
                            "IncomingSharedChannelHostTenantId" = $incomingSharedChannelOdataIdExtractObject.TenantId;
                        }
                    }
                    # add incoming shared channel shared team members to the directly assigned incoming shared channel members
                    if ($incomingSharedChannelSharedTeamMembersObject) {
                        $incomingSharedChannelMembersObject += $incomingSharedChannelSharedTeamMembersObject
                    }
                }
            } else {
                # if incoming Shared channel is external, cannot get any user data from the channel
                [PSCustomObject[]]$incomingSharedChannelMembersObject = @([PSCustomObject]@{
                    "Role" = $null;
                    "DisplayName" = $null;
                    "Mail" = $null;
                    "UserId" = $null;
                    "TenantId" = $null;
                    "SharedChannelSharedTeamId" = $null;
                    "SharedChannelSharedTeamDisplayName" = $null;
                    "SharedChannelSharedTeamTenantId" = $null;
                    "IncomingSharedChannelHostTeamId" = $incomingSharedChannelOdataIdExtractObject.TeamId;
                    "IncomingSharedChannelHostTenantId" = $incomingSharedChannelOdataIdExtractObject.TenantId;
                })
            }
            $incomingSharedChannel | Add-Member -NotePropertyName "Members" -NotePropertyValue $incomingSharedChannelMembersObject

            $currentChannelNum++

            $incomingSharedChannel
        }

        $channelsReturn += $incomingSharedChannelsReturn
        Write-Progress -Id 2 -ParentId 1 -Activity "Gathering Channel Data" -Completed
    }

    $team | Add-Member -NotePropertyName "Channels" -NotePropertyValue $channelsReturn -Force

    ## Build and return object of results, one object per channel per member of channel (team membership for standard channels) ##
    $teamName = $team.DisplayName
    $groupID = $team.Id
    $teamDescription = $team.Description
    $teamPrivacy = $team.Visibility
    $teamIsArchived = $team.IsArchived
    $teamClassification = $team.Classification
    $teamSensitivityLabel = $team.AssignedLabel
    foreach ($channel in $team.Channels) {
        $channelName = $channel.DisplayName
        $channelMembershipType = $channel.MembershipType
        $channelDescription = $channel.Description

        if ($channel.MembershipType -ne "standard") {
            $channelMembersList = $channel.Members
        } else {
            # standard channels are visible and permissioned the same as the host team, so just reference team members
            $channelMembersList = $team.Members
        }
        foreach ($channelMember in $channelMembersList) {
            $channelMemberName = $channelMember.DisplayName
            $channelMemberUserId = $channelMember.UserId
            $channelMemberMail = $channelMember.Mail
            $channelMemberTenantId = $channelMember.TenantId
            $channelMemberTenantName = $null
            $sharedChannelSharedTeamId = $null
            $sharedChannelSharedTeamName = $null
            $sharedChannelSharedTeamTenantId = $null
            $sharedChannelSharedTeamTenantName = $null

            if ($IncludeIncomingSharedChannelsInReport) {
                $incomingSharedChannelHostTeamId = $null
                $incomingSharedChannelHostTenantId = $null
                $incomingSharedChannelHostTenantName = $null
            }

            # build member role string based on directly assigned or via shared team (Shared channel only), and if external (Shared channels only)
            switch ($channel.MembershipType) {
                {"standard" -or "private"} {
                    $channelMemberRole = ($channelMember.Role -join ",").ToLower()
                }
                "shared" {
                    if ($channelMember.SharedChannelSharedTeamId) {
                        # Shared channel membership was granted via a shared team
                        $sharedChannelSharedTeamId = $channelMember.SharedChannelSharedTeamId
                        $sharedChannelSharedTeamName = $channelMember.SharedChannelSharedTeamDisplayName
                        $sharedChannelSharedTeamTenantId = $channelMember.SharedChannelSharedTeamTenantId
                        
                        if ($channelMember.SharedChannelSharedTeamTenantId -ne $HomeTenantId) {
                            $channelMemberRole = "external shared team member"
                            $channelMemberName = $channelMemberName + " (External)"
                            $sharedChannelSharedTeamName = $sharedChannelSharedTeamName + " (External)"
                        } elseif ($channelmember.SharedChannelSharedTeamId -eq $team.Id) {
                            $channelMemberRole = "shared host team member"
                        } else {
                            $channelMemberRole = "shared team member"
                        }
                    } else {
                        # Shared channel memerbship was granted directly
                        if ($channelMember.TenantId -ne $HomeTenantId) {
                            $channelMemberRole = "external member"
                            $channelMemberName = $channelMemberName + " (External)"
                        } else {
                            $channelMemberRole = $channelMember.Role.ToLower()
                        }
                    }
                }
                "incoming shared" {
                    if ($IncludeIncomingSharedChannelsInReport) {
                        $incomingSharedChannelHostTeamId = $channelMember.IncomingSharedChannelHostTeamId
                        $incomingSharedChannelHostTenantId = $channelMember.IncomingSharedChannelHostTenantId
                        
                        # add external to channel type and channel displayname if it is an incoming channel from another tenant
                        if ($incomingSharedChannelHostTenantId -ne $HomeTenantId) {
                            $channelMembershipType = "external incoming Shared"
                            $channelName = $channelName + " (External)"
                        }
                    }
                }
                Default {
                    $channelMemberRole = $channelMember.Role.ToLower()
                }
            }

            # get friendly tenant names for guests and external shared channel members/shared channel shared teams/incoming shared channels
            if ($channelMemberTenantId) {
                if ($channelMemberTenantId -eq $HomeTenantId) {
                    $channelMemberTenantName = $HomeTenantName
                } elseif ($ExternalTenantNameList[$channelMemberTenantId]) {
                    $channelMemberTenantName = $ExternalTenantNameList[$channelMemberTenantId]
                } else {
                    $tenantInfoRequestUri = "https://graph.microsoft.com/beta/tenantRelationships/findTenantInformationByTenantId(tenantId='$channelMemberTenantId')"
                    $tenantInfoReturn = Invoke-MgGraphRequest -Method GET -Uri $tenantInfoRequestUri
                    $channelMemberTenantName = $tenantInfoReturn.displayName
                    $ExternalTenantNameList.Add($channelMemberTenantId,$channelMemberTenantName)
                }
            }
            if ($sharedChannelSharedTeamTenantId) {
                if ($sharedChannelSharedTeamTenantId -eq $HomeTenantId) {
                    $sharedChannelSharedTeamTenantName = $HomeTenantName
                } elseif ($ExternalTenantNameList[$sharedChannelSharedTeamTenantId]) {
                    $sharedChannelSharedTeamTenantName = $ExternalTenantNameList[$sharedChannelSharedTeamTenantId]
                } else {
                    $tenantInfoRequestUri = "https://graph.microsoft.com/beta/tenantRelationships/findTenantInformationByTenantId(tenantId='$sharedChannelSharedTeamTenantId')"
                    $tenantInfoReturn = Invoke-MgGraphRequest -Method GET -Uri $tenantInfoRequestUri
                    $sharedChannelSharedTeamTenantName = $tenantInfoReturn.displayName
                    $ExternalTenantNameList.Add($sharedChannelSharedTeamTenantId,$sharedChannelSharedTeamTenantName)
                }
            }
            if ($incomingSharedChannelHostTenantId) {
                if ($incomingSharedChannelHostTenantId -eq $HomeTenantId) {
                    $incomingSharedChannelHostTenantName = $HomeTenantName
                } elseif ($ExternalTenantNameList[$incomingSharedChannelHostTenantId]) {
                    $incomingSharedChannelHostTenantName = $ExternalTenantNameList[$incomingSharedChannelHostTenantId]
                } else {
                    $tenantInfoRequestUri = "https://graph.microsoft.com/beta/tenantRelationships/findTenantInformationByTenantId(tenantId='$incomingSharedChannelHostTenantId')"
                    $tenantInfoReturn = Invoke-MgGraphRequest -Method GET -Uri $tenantInfoRequestUri
                    $incomingSharedChannelHostTenantName = $tenantInfoReturn.displayName
                    $ExternalTenantNameList.Add($incomingSharedChannelHostTenantId,$incomingSharedChannelHostTenantName)
                }
            }

            $teamChannelUsersReturn = [PSCustomObject]@{
                "Team Name" = $teamName;
                "Group ID" = $groupID;
                "Team Description" = $teamDescription;
                "Team Privacy" = $teamPrivacy;
                "Team Is Archived" = $teamIsArchived;
                "Team Classification" = $teamClassification;
                "Team Sensitivity Label" = $teamSensitivityLabel;
                "Channel Name" = $channelName;
                "Channel Membership Type" = $channelMembershipType;
                "Channel Description" = $channelDescription;
                "Channel Member Name" = $channelMemberName;
                "Channel Member Role" = $channelMemberRole;
                "Channel Member User ID" = $channelMemberUserId;
                "Channel Member Email" = $channelMemberMail;
                "Channel Member Organization" = $channelMemberTenantName;
                "Shared Channel Shared Team ID" = $sharedChannelSharedTeamId;
                "Shared Channel Shared Team Name" = $sharedChannelSharedTeamName;
                "Shared Channel Shared Team Tenant ID" = $sharedChannelSharedTeamTenantId;
                "Shared Channel Shared Team Organization" = $sharedChannelSharedTeamTenantName;
            }

            if ($IncludeIncomingSharedChannelsInReport) {
                $teamChannelUsersReturn | Add-Member -NotePropertyName "Incoming Shared Channel Host Team ID" -NotePropertyValue $incomingSharedChannelHostTeamId
                $teamChannelUsersReturn | Add-Member -NotePropertyName "Incoming Shared Channel Host Tenant ID" -NotePropertyValue $incomingSharedChannelHostTenantId
                $teamChannelUsersReturn | Add-Member -NotePropertyName "Incoming Shared Channel Host Organization" -NotePropertyValue $incomingSharedChannelHostTenantName
            }
            $teamChannelUsersReturn
        }
    }

    $currentTeamNum++
}

Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Saving report: $ExportCSVFilePath"
$ReportOutput | Export-Csv -Path $ExportCSVFilePath -NoTypeInformation -ErrorAction Stop
$outputfile = Get-ChildItem $ExportCSVFilePath
Write-Output "Report saved to: $($outputfile.FullName)"
Write-Progress -Id 1 -Activity "Gathering Teams Data" -Completed
