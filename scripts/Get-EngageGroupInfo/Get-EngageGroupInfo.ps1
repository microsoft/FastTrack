<#
.DESCRIPTION
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

Purpose: 
    -Gets information on each Viva Engage community in your tenant using the Microsoft Graph API:
     https://learn.microsoft.com/en-us/graph/api/resources/engagement-api-overview
     
Author:
    Dean Cron

Version:
    1.0 - Initial Release 2023 (legacy Yammer REST API)
    2.0 - Updated to use MSAL.PS for authentication Nov 2025 (legacy Yammer REST API)
    3.0 - July 2026 - Migrated off the deprecated Yammer REST API to the Microsoft Graph
          communities/groups APIs. The LastMessageAt column has been removed - Viva Engage
          conversation/message activity isn't exposed via Graph (the communities API only
          covers CRUD and membership, not messaging stats), so there's no Graph equivalent.
          NOTE: GroupID in the output is now the Microsoft 365 group ID (a GUID) that backs
          the community, NOT the legacy numeric Yammer group ID produced by earlier versions
          of this script.

Requirements:

    1. An Azure AD (Entra ID) App Registration with the following Microsoft Graph
       **application** permissions, with admin consent granted:
        -Community.Read.All (or Community.ReadWrite.All)
        -GroupMember.Read.All (or Group.Read.All / Group.ReadWrite.All)

.EXAMPLE
    .\Get-EngageGroupInfo.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantid"
$ClientSecret = "clientsecret"

$ReportOutput = "C:\Temp\YammerGroupInfo{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

function Connect-ToGraph {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $authBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $ClientId
        Client_Secret = $ClientSecret
    }

    $Connection = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method POST -Body $authBody
    return $Connection.access_token
}

$accessToken = Connect-ToGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret
$authHeader = @{ Authorization = "******" }
$countHeader = @{ Authorization = "******"; ConsistencyLevel = 'eventual' }

#Function to get all communities, following @odata.nextLink for paging
Function Get-EngageCommunities($uri, $allCommunities) {
    if (!$allCommunities) {
        $allCommunities = New-Object System.Collections.ArrayList($null)
    }

    Write-Host "Retrieving communities page..." -Foreground Yellow
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $authHeader
    $allCommunities.AddRange($response.value)

    if ($response.'@odata.nextLink') {
        return Get-EngageCommunities $response.'@odata.nextLink' $allCommunities
    }
    else {
        return $allCommunities
    }
}

$communities = Get-EngageCommunities "https://graph.microsoft.com/beta/employeeExperience/communities"

#Array to store Result
$ResultSet = @()

$communities | ForEach-Object {

    $communityId = $_.id
    $groupId = $_.groupId
    Write-Host "Processing Community:" $_.displayName -f Yellow

    do {
        $rateLimitHit = $false
        try {
            $Result = New-Object PSObject
            $Result | Add-Member -MemberType NoteProperty -Name "CommunityId" -Value $communityId
            $Result | Add-Member -MemberType NoteProperty -Name "GroupId" -Value $groupId
            $Result | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $_.displayName

            #Get the group's member count
            #https://learn.microsoft.com/en-us/graph/api/group-list-members
            $memberCount = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$count" -Headers $countHeader -Method GET
            $Result | Add-Member -MemberType NoteProperty -Name "MemberCount" -Value $memberCount

            #Get the group's owners. Group owners are automatically treated as admins of the
            #associated Viva Engage community.
            #https://learn.microsoft.com/en-us/graph/api/group-list-owners
            $owners = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/owners" -Headers $authHeader -Method GET

            $admins = $null
            if ($owners.value.Count -gt 0) {
                $owners.value | ForEach-Object {
                    $admins += $_.displayName + " " + $_.userPrincipalName + ";"
                }
                $Result | Add-Member -MemberType NoteProperty -Name "GroupAdmins" -Value $admins
            }
            else {
                $Result | Add-Member -MemberType NoteProperty -Name "GroupAdmins" -Value "No Admins"
            }

            $ResultSet += $Result
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if ($statusCode -eq "429" -or $statusCode -eq "503") {
                #Deal with rate limiting
                #https://learn.microsoft.com/en-us/graph/throttling
                $rateLimitHit = $true
            }
            elseif ($statusCode -eq "401" -or $statusCode -eq "403") {
                #Thrown when the access token is invalid or lacks the required permissions
                Write-Host "Graph API reports ACCESS DENIED for community" $_.displayName "- ensure the app registration has Community.Read.All and GroupMember.Read.All (application) permissions with admin consent." -ForegroundColor Red
            }
            elseif ($statusCode -eq "404") {
                #Typically thrown when the underlying group isn't found
                Write-Host "Graph API reports 404 for community" $_.displayName "- the underlying group may have been deleted." -ForegroundColor Red
            }
            else {
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to get info for community" $_.displayName -ForegroundColor Red
                Write-Host "error $statusCode on line $l"
            }

            if ($rateLimitHit) {
                #429 or 503: Sleep for a bit before retrying
                Write-Host "Rate limit hit, sleeping for 10 seconds before retrying community" $_.displayName -ForegroundColor Yellow
                Start-Sleep -Seconds 10
            }
        }
    } while ($rateLimitHit)
}

#Export Result to csv file
$ResultSet | Export-Csv $ReportOutput -NoTypeInformation

Write-Host "Report created successfully. See $ReportOutput" -f Green
