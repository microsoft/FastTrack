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
    -Bulk-removes users from a Viva Engage community using the Microsoft Graph API.
     A Viva Engage community's membership is just the membership of its underlying
     Microsoft 365 group, so this uses the group members API:
     https://learn.microsoft.com/en-us/graph/api/group-delete-member
     https://learn.microsoft.com/en-us/graph/api/resources/engagement-api-overview#community-membership-management

     NOTE: This does NOT delete the user's account or identity, and does not remove them
     from every community/group they belong to - only from the specific group(s) listed in
     the input CSV. There is no Graph (or supported) API to delete a "Yammer user" as a
     standalone concept; the legacy Yammer REST API's DELETE /users/{id}.json endpoint
     deleted/deactivated the underlying account entirely, which has no direct Graph
     equivalent. If you need to fully remove someone's access across every community, either
     run this script once per group they belong to, or deprovision/disable their Entra ID
     account instead (which is the modern equivalent of deactivating a user tenant-wide).

Author:
    Dean Cron

Version:
    1.0 - Initial Release 2023 (legacy Yammer REST API - deleted the user's Yammer account)
    2.0 - Updated to v2 November 2025 (legacy Yammer REST API)
    3.0 - July 2026 - Migrated off the deprecated Yammer REST API to the Microsoft Graph
          group-members API. This is a change in scope, not just a like-for-like swap: the
          old version deleted the user's Yammer account entirely (removing them from every
          group/community). This version only removes the user from the specific group listed
          for them in the input CSV. See the README for details and options if you need
          broader removal.

Requirements:

    1. An Azure AD (Entra ID) App Registration with the following Microsoft Graph
       **application** permission, with admin consent granted:
        -Group.ReadWrite.All

    2. CSV containing group IDs and users to remove from each. See the README for more
       information on how to create this and how to find the group ID for a community:
        https://github.com/microsoft/FastTrack/tree/master/scripts/Delete-EngageUsers/README.md


.EXAMPLE
    .\Delete-EngageUsers.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Point this to the userstobedeleted.csv you created as per the requirements.
$usersToBeDeletedCSV = 'C:\temp\userstobedeleted.csv'

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantid"
$ClientSecret = "clientsecret"

#Change to $false when you're ready to actually remove the users. THIS CAN'T BE UNDONE.
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

#Make sure userstobedeleted.csv is where it's supposed to be
try {
    $usersCsv = Import-Csv $usersToBeDeletedCSV -UseCulture
}
catch {
    Write-Host "Unable to open the input CSV file. Ensure it's located at $usersToBeDeletedCSV"
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
$authHeader = @{ Authorization = "******" }

Write-Host "Starting to remove users from groups..." -ForegroundColor Cyan

$usersCsv | ForEach-Object {
    do {
        $rateLimitHit = $false

        $gID = $_.GroupID
        $mail = $_.Email

        try {
            #Resolve the user's directory object ID from their email/UPN. The group-members
            #removal endpoint requires the object ID, not the UPN.
            #https://learn.microsoft.com/en-us/graph/api/user-get
            $user = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$mail`?`$select=id" -Headers $authHeader -Method GET
            $userId = $user.id

            if ($whatIfMode) {
                Write-Host "WhatIf mode enabled, would have successfully removed $mail (userID $userId) from group $gID" -ForegroundColor Green
            }
            else {
                #Remove the user from the group. This removes their access to the associated
                #Viva Engage community, but does NOT delete their account or remove them from
                #any other groups/communities.
                #https://learn.microsoft.com/en-us/graph/api/group-delete-member
                Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$gID/members/$userId/`$ref" -Headers $authHeader -Method DELETE | Out-Null
                Write-Host "Successfully removed $mail from group $gID" -ForegroundColor Green
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
                #Thrown when the access token is invalid or lacks Group.ReadWrite.All
                Write-Host "Exiting script, Graph API reports ACCESS DENIED. Ensure the app registration has Group.ReadWrite.All (application) permission with admin consent." -ForegroundColor Red
                exit
            }
            elseif ($statusCode -eq "404") {
                #Typically thrown when either the user, group, or membership isn't found
                Write-Host "Graph API reports 404, typically caused when the user ($mail), group ($gID) was not found, or the user isn't a member of that group" -ForegroundColor Red
            }
            else {
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to remove" $mail "from group" $gID -ForegroundColor Red
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
