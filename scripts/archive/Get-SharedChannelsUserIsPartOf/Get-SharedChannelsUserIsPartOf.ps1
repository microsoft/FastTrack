# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# AUTHOR: Mihai Filip
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# DEPENDENCIES: Connect-MicrosoftTeams
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# USAGE: 
# Connect-MicrosoftTeams
# .\Get-SharedChannelsUserIsPartOf.ps1 -UserPrincipalName user@contoso.com
# .\Get-SharedChannelsUserIsPartOf.ps1 -UserPrincipalName user@contoso.com -CSV $true
# .\Get-SharedChannelsUserIsPartOf.ps1 -UserPrincipalName user@contoso.com -Owner $true
# .\Get-SharedChannelsUserIsPartOf.ps1 -UserPrincipalName user@contoso.com -Owner $true -CSV $true
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]
    $UserPrincipalName,
    [Parameter(Mandatory = $false)]
    [String]
    $Owner,
    [Parameter(Mandatory = $false)]
    [String]
    $CSV
)

$user = $UserPrincipalName
$teams = (Get-Team)
$sharedChannelsUserIsPartOf = @()

foreach ($team in $teams) {
    $sharedChannelsInTeam = (Get-TeamChannel -GroupId $team.GroupId -MembershipType Shared)
    if ($sharedChannelsInTeam) {
        if ($Owner) {
            foreach ($sharedChannelInTeam in $sharedChannelsInTeam) {
                $isUserOwner = (Get-TeamChannelUser -GroupId $team.GroupId -DisplayName $sharedChannelInTeam.DisplayName -Role Owner | Where-Object { $_.User -eq $user }).User
                if ($isUserOwner) {
                    $sharedChannelsUserIsPartOf += New-Object PSObject -Property @{team = $team.DisplayName; channel = $sharedChannelInTeam.DisplayName }
                }
            }
        }
        else {
            foreach ($sharedChannelInTeam in $sharedChannelsInTeam) {
                $isUserMember = (Get-TeamChannelUser -GroupId $team.GroupId -DisplayName $sharedChannelInTeam.DisplayName | Where-Object { $_.User -eq $user }).User
                if ($isUserMember) {
                    $sharedChannelsUserIsPartOf += New-Object PSObject -Property @{team = $team.DisplayName; channel = $sharedChannelInTeam.DisplayName }
                }
            }
        }
    }
}

if ($Owner) {
    if ($CSV) {
        $sharedChannelsUserIsPartOf | Export-Csv ".\SharedChannelsUserIsOwnerOf-$($user).csv" -NoTypeInformation
        Write-Host "CSV exported in $($PWD)"
    }
    else {
        Write-Host "Shared channels $($user) is owner of:"
        Write-Host "-----------------------------------------------"
        $sharedChannelsUserIsPartOf
    }
}
else {
    if ($CSV) {
        $sharedChannelsUserIsPartOf | Export-Csv ".\SharedChannelsUserIsMemberOf-$($user).csv" -NoTypeInformation
        Write-Host "CSV exported in $($PWD)"
    }
    else {
        Write-Host "Shared channels $($user) is member of:"
        Write-Host "-----------------------------------------------"
        $sharedChannelsUserIsPartOf
    }
}