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
    -Bulk-adds admins (owners) to Viva Engage communities using the Microsoft Graph API.
     A Viva Engage community admin is simply an owner of the community's underlying
     Microsoft 365 group, so this uses the group owners API:
     https://learn.microsoft.com/en-us/graph/api/group-post-owners
     https://learn.microsoft.com/en-us/graph/api/resources/engagement-api-overview#community-membership-management
     
Author:
    Dean Cron

Version:
    1.0 - Initial Release 2023 (legacy Yammer REST API)
    2.0 - Updated to v2 October 2025 (legacy Yammer REST API)
    3.0 - July 2026 - Migrated off the deprecated Yammer REST API to the Microsoft Graph
          group-owners API. NOTE: the GroupID column now needs the Microsoft 365 group ID
          (a GUID) that backs the community, NOT the legacy numeric Yammer group ID used
          by earlier versions of this script. See the README for how to get this ID.

Requirements:

    1. An Azure AD (Entra ID) App Registration with the following Microsoft Graph
       **application** permission, with admin consent granted:
        -Group.ReadWrite.All

    2. CSV containing group IDs and admins to add to each. See the README for more information
       on how to create this and how to find the group ID for a community:
        https://github.com/microsoft/FastTrack/tree/master/scripts/Add-EngageGroupAdmins/README.md


.EXAMPLE
    .\Add-EngageGroupAdmins.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Point this to the groupadmins.csv you created as per the requirements.
$groupadminsCsvPath = 'C:\temp\groupadmins.csv'

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantid"
$ClientSecret = "clientsecret"

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

#Make sure groupadmins.csv is where it's supposed to be
try {
    $groupadminsCsv = Import-Csv $groupadminsCsvPath
}
catch {
    Write-Host "Unable to open the input CSV file. Ensure it's located at $groupadminsCsvPath"
    Return
}

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
$authHeader = @{ Authorization = "Bearer $accessToken"; 'Content-Type' = 'application/json' }

Write-Host "Starting to add group admins..." -ForegroundColor Cyan

$groupadminsCsv | ForEach-Object {
    do {
        $rateLimitHit = $false

        $gID = $_.GroupID
        $mail = $_.Email

        try {
            #Add the user as an owner of the group. Group owners are automatically treated as
            #admins of the associated Viva Engage community.
            $requestBody = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/users/$mail" } | ConvertTo-Json
            Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$gID/owners/`$ref" -Headers $authHeader -Method POST -Body $requestBody | Out-Null

            Write-Host "Successfully added admin $mail to group $gID" -ForegroundColor Green
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if ($statusCode -eq "429" -or $statusCode -eq "503") {
                #Deal with rate limiting
                #https://learn.microsoft.com/en-us/graph/throttling
                $rateLimitHit = $true
            }
            elseif ($statusCode -eq "401" -or $statusCode -eq "403") {
                #Thrown when the access token is invalid or lacks Group.ReadWrite.All
                Write-Host "Exiting script, Graph API reports ACCESS DENIED. Ensure the app registration has Group.ReadWrite.All (application) permission with admin consent." -ForegroundColor Red
                exit
            }
            elseif ($statusCode -eq "404") {
                #Typically thrown when either the group or user isn't found. 
                Write-Host "Exiting script, Graph API reports 404, typically caused when either the user ($mail) or group ($gID) was not found" -ForegroundColor Red
                exit
            }
            elseif ($statusCode -eq "400") {
                #Typically thrown when the user is already an owner of the group
                Write-Host "Failed to add" $mail "to group" $gID "- Graph API reports 400, the user may already be an owner" -ForegroundColor Red
            }
            else {
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to add" $mail "to group" $gID -ForegroundColor Red
                Write-Host "error $statusCode on line $l" 
            }
        }
        if ($rateLimitHit) {
            #429 or 503: Sleep for a bit before retrying
            Write-Host "Rate limit hit, sleeping for 15 seconds"
            Start-Sleep -Seconds 15
        }
    } while ($rateLimitHit)
}

Write-Host "All done!" -ForegroundColor Cyan
