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
    -Allows a Yammer admin to bulk-add group owners to groups in their network. 
     
Author:
    Dean Cron

Version:
    2.0

Requirements:

    1. MSAL.PS PowerShell module. Install it from the PowerShell Gallery with the command:
        Install-Module MSAL.PS

    2. An Azure AD App Registration with the following API permissions:
        -Yammer: access_as_user

    2. CSV containing group IDs and admins to add to each. See the README for more information on how to create this:
        https://github.com/microsoft/FastTrack/tree/master/scripts/Add-YammerGroupAdmins/README.md


.EXAMPLE
    .\Add-YammerGroupAdmins.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Point this to the groupadmins.csv you created as per the requirements.
$groupadminsCsvPath = 'C:\temp\groupadmins.csv'

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantId"
$RedirectUri = "https://localhost"

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

$Scopes = @("https://api.yammer.com/.default")

#Check to see if MSAL.PS is installed, if not exit with instructions
if(-not (Get-Module -ListAvailable -Name MSAL.PS)){
    Write-Host "MSAL.PS module not found, please install it from the PowerShell Gallery with the command:" -ForegroundColor Red
    Write-Host "Install-Module MSAL.PS" -ForegroundColor Yellow
    Return
}

#Make sure groupadmins.csv is where it's supposed to be
try{
    $groupadminsCsv = Import-Csv $groupadminsCsvPath
}
catch{
    Write-Host "Unable to open the input CSV file. Ensure it's located at $groupadminsCsvPath"
    Return
}

function Get-YammerAuthHeader {
    $authToken = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -RedirectUri $RedirectUri -Scopes $Scopes -Interactive
    if (-not $authToken) {
        Write-Host "Failed to acquire Yammer Auth Token. Please ensure the ClientID, TenantID, and ClientSecret are correct." -ForegroundColor Red
        Return
    }
    else {
        return $authToken.AccessToken
    }
    
}

$YammerAuthToken = Get-YammerAuthHeader

Write-Host "Starting to add group admins..." -ForegroundColor Cyan

$groupadminsCsv | ForEach-Object {
    do {
        $rateLimitHit = $false

        $gID = $_.GroupID -as [decimal]
        $mail = $_.Email
        
        try
        {
            $gFullName = $null
            
            # Add Admin to Group
            $requestBody = @{ group_id=$gID; email=$mail }
            $addAdmin = Invoke-WebRequest "https://www.yammer.com/api/v1/group_memberships.json" -Headers @{ AUTHORIZATION = "Bearer $YammerAuthToken" } -Method POST -Body $requestBody
            $adminID = (convertfrom-json $addAdmin.content).user_id

            #We have the user ID and have added them as a member, now make them an admin of this group
            $injectAdmin = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID/make_admin?user_id=$adminID" -Headers @{ AUTHORIZATION = "Bearer $YammerAuthToken" } -UseBasicParsing -Method POST

            #Comment the next line if you'd like to speed this script up slightly. Cosmetic only, used to output group name instead of group ID
            $getGroupName = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers @{ AUTHORIZATION = "Bearer $YammerAuthToken" } -Method GET

            if($getGroupName){
                $gFullName = (convertfrom-json $getGroupName.content).full_name
            }
            else{
                $gFullName = $gID
            }

            Write-Host "Successfully added admin $mail to group $gFullName" -ForegroundColor Green
        }
        catch {
            if( $_.Exception.Response.StatusCode.Value__ -eq "429" -or $_.Exception.Response.StatusCode.Value__ -eq "503" )
            {
                #Deal with rate limiting
                #https://learn.microsoft.com/en-us/rest/api/yammer/rest-api-rate-limits#yammer-api-rate-limts
                $rateLimitHit = $true
            }
            elseif($_.Exception.Response.StatusCode.Value__ -eq "401"){
                #Thrown when the YammerAuthToken is invalid for the network in question
                Write-Host "Exiting script, API reports 401 ACCESS DENIED." -ForegroundColor Red
                exit
            }
            elseif($_.Exception.Response.StatusCode.Value__ -eq "404"){
                #Typically thrown when either the group or user isn't found. 
                Write-Host "Exiting script, API reports 404, typically caused when either the user ($mail) or group ($gID) was not found" -ForegroundColor Red
                exit
            }
            else{
                $e = $_.Exception.Response.StatusCode.Value__
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to add" $mail "to group" $gID  -ForegroundColor Red
                Write-Host "error $e on line $l" 
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

