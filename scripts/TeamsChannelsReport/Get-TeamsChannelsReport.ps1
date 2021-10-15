<#

Get-TeamsChannelReport PowerShell script | Version 0.1

by David.Whitney@microsoft.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

#>

<#
$MgModule = Get-Module -Name "Microsoft.Graph" -ListAvailable
if (-not $MgModule) {
    throw "This script requires the Microsoft.Graph (PowerShell SDK for Graph) module - use 'Install-Module Microsoft.Graph' from an elevated PowerShell session, restart this PowerShell session, then try again."
}
Import-Module Microsoft.Graph -WarningAction SilentlyContinue -ErrorAction Stop
#>

Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting list of M365 Groups"
$M365GroupIdsWithProvisioning = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -Property Id, DisplayName, resourceProvisioningOptions
$M365GroupsThatAreTeams = $M365GroupIdsWithProvisioning | where {$_.AdditionalProperties.resourceProvisioningOptions -contains "Team"}

Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting Teams properties"
$Teams = @()
$n = 0
$total = $M365GroupsThatAreTeams.count
foreach ($M365GroupThatIsATeam in $M365GroupsThatAreTeams) {
    Write-Progress -Id 1 -Activity "Gathering Teams Data" -Status "Getting Teams properties" -CurrentOperation $M365GroupThatIsATeam.DisplayName -PercentComplete (100 * $n / $total)
    $Teams += Get-MgTeam -TeamId $M365GroupThatIsATeam.Id -Property Id, DisplayName, Description, Vsibility, IsArchived
    $n++
}
#$Teams = $M365GroupsThatAreTeams | foreach {Get-MgTeam -TeamId $_.Id}

foreach ($team in $Teams) {
    #team name
    #group ID
    #team description
    #team privacy
    #team sensitivity label (from group?)
    #team is archived
    #-- foreach channel--
        #channel name
        #channel description
        #-- foreach member (group owner+member for standard, pull channel users for private) --
            #member name
            #member UPN
            #member role (group role for standard, pull channel role for private [account for guest users])

    $teamName = $team.DisplayName
    $groupID = $team.Id
    $teamDescription = $team.Description
    $teamPrivacy = $team.Visibility
    $teamIsArchived = $team.IsArchived
    #$teamSensitivityLabel
}