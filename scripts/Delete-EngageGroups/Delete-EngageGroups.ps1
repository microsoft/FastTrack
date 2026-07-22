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
    -Bulk deletes Viva Engage communities using the Microsoft Graph API:
     https://learn.microsoft.com/en-us/graph/api/community-delete?view=graph-rest-beta
     
Author:
    Dean Cron

Version:
    1.0 - Initial Release 2023 (legacy Yammer REST API)
    2.0 - Updated to use MSAL.PS for authentication Nov 2025 (legacy Yammer REST API)
    3.0 - July 2026 - Migrated off the deprecated Yammer REST API to the Microsoft Graph
          community API. NOTE: community IDs are NOT the same as the legacy numeric
          Yammer group IDs used by earlier versions of this script. See the README for
          how to get the correct IDs for your input CSV.

Requirements:

    1. An Azure AD (Entra ID) App Registration with the following Microsoft Graph
       **application** permission, with admin consent granted:
        -Community.ReadWrite.All

    2. CSV containing the Viva Engage community IDs of the communities you want deleted.
       See the README for how to obtain these IDs.

.EXAMPLE
    .\Delete-EngageGroups.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantid"
$ClientSecret = "clientsecret"

#Point this to the groupstobedeleted.csv you created as per the requirements.
#The CSV must contain a single column named CommunityId with Viva Engage community IDs (not legacy numeric Yammer group IDs).
$groupsToBeDeletedCSV = 'C:\temp\groupstobedeleted.csv'

#Change to $false when you're ready to actually delete the communities. DELETION CAN'T BE UNDONE.
$whatIfMode = $true

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

#Make sure groupstobedeleted.csv is where it's supposed to be
try {
    $groupsCsv = Import-Csv $groupsToBeDeletedCSV -UseCulture
}
catch {
    Write-Host "Unable to open the input CSV file. Ensure it's located at $groupsToBeDeletedCSV"
    Return
}

$accessToken = Connect-ToGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret
$authHeader = @{ Authorization = "Bearer $accessToken" }

$groupsCsv | ForEach-Object {
    do {
        $rateLimitHit = $false
        $communityId = $_.CommunityId

        try {
            #Will it blend?
            if ($whatIfMode) {
                Write-Host "WhatIf mode enabled, would have successfully deleted community $communityId" -ForegroundColor Green
            }
            else {
                Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/employeeExperience/communities/$communityId" -Headers $authHeader -Method DELETE | Out-Null
                Write-Host "Successfully deleted community $communityId" -ForegroundColor Green
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if ($statusCode -eq "429" -or $statusCode -eq "503") {
                #Deal with rate limiting
                #https://learn.microsoft.com/en-us/graph/throttling
                $rateLimitHit = $true
            }
            elseif ($statusCode -eq "401" -or $statusCode -eq "403") {
                #Thrown when the access token is invalid or lacks Community.ReadWrite.All. Exit here.
                Write-Host "Exiting script, Graph API reports ACCESS DENIED. Ensure the app registration has Community.ReadWrite.All (application) permission with admin consent." -ForegroundColor Red
                exit
            }
            elseif ($statusCode -eq "404") {
                #Typically thrown when the community isn't found. No exit, try next community.
                Write-Host "Graph API reports 404, typically caused if the community ($communityId) was not found" -ForegroundColor Red
            }
            else {
                #Fallback, no idea what happened to get us here.
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to delete community" $communityId -ForegroundColor Red
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
