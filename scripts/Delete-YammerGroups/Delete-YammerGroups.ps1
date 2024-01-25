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
    1.0

Requirements:

    1. Admin-created bearer token for Yammer app authentication following the instructions in step 2 here:
        https://support.microsoft.com/en-au/office/export-yammer-group-members-to-a-csv-file-201a78fd-67b8-42c3-9247-79e79f92b535#step2        

    2. CSV containing Yammer group IDs of groups you want deleted. 


.EXAMPLE
    .\Delete-YammerGroups.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerTokenString"

#Point this to the groupstobedeleted.csv you created as per the requirements.
$groupsToBeDeletedCSV = 'C:\temp\groupstobedeleted.csv'

#Change to $false when you're ready to actually delete the groups. DELETION CAN'T BE UNDONE.
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

function Get-YammerAuthHeader {
    @{ AUTHORIZATION = "Bearer $YammerAuthToken" }
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
                $rateLimitHit = $false
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
