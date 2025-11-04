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
    -Bulk deletes Yammer groups
     
Author:
    Dean Cron

Version:
    1.0 - Initial Release 2023
    2.0 - Updated to use MSAL.PS for authentication Nov 2025

Requirements:

    1. MSAL.PS PowerShell module. Install it from the PowerShell Gallery with the command:
        Install-Module MSAL.PS

    2. An Azure AD App Registration with the following API permissions:
        -Yammer: access_as_user       

    2. CSV containing Yammer group IDs of groups you want deleted. 


.EXAMPLE
    .\Delete-YammerGroups.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantId"
$RedirectUri = "https://localhost"

#Point this to the groupstobedeleted.csv you created as per the requirements.
$groupsToBeDeletedCSV = 'C:\temp\groupstobedeleted.csv'

#Change to $false when you're ready to actually delete the groups. DELETION CAN'T BE UNDONE.
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

$Scopes = @("https://api.yammer.com/.default")

#Check to see if MSAL.PS is installed, if not exit with instructions
if(-not (Get-Module -ListAvailable -Name MSAL.PS)){
    Write-Host "MSAL.PS module not found, please install it from the PowerShell Gallery with the command:" -ForegroundColor Red
    Write-Host "Install-Module MSAL.PS" -ForegroundColor Yellow
    Return
}
function Get-YammerAuthHeader {
    $authToken = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -RedirectUri $RedirectUri -Scopes $Scopes -Interactive
    if (-not $authToken) {
        Write-Host "Failed to acquire Yammer Auth Token. Please ensure the ClientID, TenantID, and ClientSecret are correct." -ForegroundColor Red
        Return
    }
    else {
        return @{ AUTHORIZATION = "Bearer $($authToken.AccessToken)" }
    }
}

#Make sure groupstobedeleted.csv is where it's supposed to be
try{
    $groupsCsv = Import-Csv $groupsToBeDeletedCSV -UseCulture
}
catch{
    Write-Host "Unable to open the input CSV file. Ensure it's located at $groupsToBeDeletedCSV"
    Return
}

$authHeader = Get-YammerAuthHeader

$groupsCsv | ForEach-Object {
    do {
        $rateLimitHit = $false
        $gID = $_.GroupID -as [decimal]
        
        try
        {
            #Will it blend?
            if($whatIfMode){
                Write-Host "WhatIf mode enabled, would have successfully deleted group $gID" -ForegroundColor Green
            }
            else{
                $deleteGroup = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers $authHeader -Method DELETE
                Write-Host "Successfully deleted group $gID" -ForegroundColor Green
            }
        }
        catch {
            if( $_.Exception.Response.StatusCode.Value__ -eq "429" -or $_.Exception.Response.StatusCode.Value__ -eq "503" )
            {
                #Deal with rate limiting
                #https://learn.microsoft.com/en-us/rest/api/yammer/rest-api-rate-limits#yammer-api-rate-limts
                $rateLimitHit = $true
            }
            elseif($_.Exception.Response.StatusCode.Value__ -eq "401"){
                #Thrown when the YammerAuthToken is invalid. Exit here.
                Write-Host "Exiting script, API reports ACCESS DENIED. Please ensure a valid developer token is set for the YammerAuthToken variable" -ForegroundColor Red
                exit
            }
            elseif($_.Exception.Response.StatusCode.Value__ -eq "404"){
                #Typically thrown when the group isn't found. No exit, try next group.
                Write-Host "Exiting script, API reports 404, typically caused if the group ($gID) was not found" -ForegroundColor Red
            }
            else{
                #Fallback, no idea what happened to get us here.
                $e = $_.Exception.Response.StatusCode.Value__
                $l = $_.InvocationInfo.ScriptLineNumber
                Write-Host "Failed to delete group" $gID  -ForegroundColor Red
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
