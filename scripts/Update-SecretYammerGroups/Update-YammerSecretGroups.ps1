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
    -Flips unlsted private groups to listed. Groups will retain their private status.
     
Author:
    Dean Cron

Version:
    1.0

Requirements:

    1. Admin-created bearer token for Yammer app authentication:
        https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

        NOTE - The account this token is created under MUST have private content mode enabled:
        https://learn.microsoft.com/en-us/viva/engage/manage-security-and-compliance/monitor-private-content

    2. CSV containing Yammer group IDs of groups that need to be changed to listed


.EXAMPLE
    .\Update-YammerSecretGroups.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerTokenString"

#Point this to the secretgroups.csv you created as per the requirements.
$groupsToBeUpdatedCSV = 'c:\temp\hiddengroups.csv'

#Change to $false when you're ready to actually update the groups to be visible
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

#Make sure groupsToBeUpdated.csv is where it's supposed to be
try{
    $groupsCsv = Import-Csv $groupsToBeUpdatedCSV -UseCulture
}
catch{
    Write-Host "Unable to open the input CSV file. Ensure it's located at $groupsToBeUpdatedCSV"
    Return
}

# Create header with access token
$headers = @{"Authorization" = "Bearer $YammerAuthToken"; "Content-Type" = "application/json"}

$groupsCsv | ForEach-Object {
    do {
        $rateLimitHit = $false
        $gID = $_.Id -as [decimal]
        
        try
        {
            $getGroupInfo = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers $headers -Method GET
            $fName = (convertfrom-json $getGroupInfo.content).full_name
            Write-Host ""
            Write-Host "Processing Group: " (convertfrom-json $getGroupInfo.content).full_name
            Write-Host "Group ID: $gID"
            Write-Host "Is group currently visible: " (convertfrom-json $getGroupInfo.content).show_in_directory

            #Will it blend?
            if($whatIfMode){
                Write-Host "WhatIf mode enabled, would have updated group $gID" -ForegroundColor Green
            }
            else{
                # Create community payload
                $communityPayload = @{"show_in_directory" = "true"} | ConvertTo-Json

                $updateGroup = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers $headers -Method PUT -Body $communityPayload
                Write-Host "Successfully changed group $gID to visible" -ForegroundColor Green
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
                Write-Host "Failed to update group" $gID  -ForegroundColor Red
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