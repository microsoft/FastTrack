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
    -Flips unlisted private groups to listed. Groups will retain their private status.
     
Author:
    Dean Cron

Version:
    1.0

Requirements:

    1. Admin-created bearer token for Yammer authentication:
        https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

        NOTE - The account this token is created under MUST have private content mode enabled:
        https://learn.microsoft.com/en-us/viva/engage/manage-security-and-compliance/monitor-private-content


.EXAMPLE
    .\Update-SecretYammerGroups.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerTokenString"

#Change to $false when you're ready to actually update the groups to be visible
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

#Create header with access token
$Global:headers = @{"Authorization" = "Bearer $YammerAuthToken"; "Content-Type" = "application/json"}

#Function to get all groups
Function Get-YammerGroups($page, $allGroups) {
    if (!$page) {
        $page = 1
    }

    if (!$allGroups) {
        $allGroups = New-Object System.Collections.ArrayList($null)
    }

    $urlToCall = "https://www.yammer.com/api/v1/groups.json"
    $urlToCall += "?page=" + $page;

    #API only returns 50 results per page, so we need to loop through all pages
    Write-Host "Retrieving page $page of groups list" -Foreground Yellow
    $webRequest = Invoke-WebRequest -Uri $urlToCall -Method Get -Headers $headers

    if ($webRequest.StatusCode -eq 200) {
        $results = $webRequest.Content | ConvertFrom-Json

        if ($results.Length -eq 0) {
            return $allGroups
        }
        $allGroups.AddRange($results)
    }

    if ($allGroups.Count % 50 -eq 0) {
        $page = $page + 1
        return Get-YammerGroups $page $allGroups
    }
    else {
        return $allGroups
    }
}

$results = Get-YammerGroups
$groupList = $results | Where-Object {$_.show_in_directory -eq "false"}

$resultCount = ($groupList | Measure-Object).Count

if($resultCount -eq 0)
{
    Write-Host "No hidden groups found, exiting script" -Foreground Green
    Exit
}
else
{
    if($whatIfMode)
    {
        Write-Host "Found" $resultCount "hidden group(s). WhatIf mode is enabled, groups below will NOT be set to listed." -Foreground Yellow
    }
    else
    {
        Write-Host "Found" $resultCount "hidden group(s), changing from hidden to listed." -Foreground Yellow
    }
}

#Change hidden groups to visible groups. These groups will still be private.
 $groupList | ForEach-Object {
    
     $gID = $_.Id -as [decimal]

     try
     {
         #Get the group properties.
         #This is more of a test to ensure we can see it, but also allows display of some info for each group.
         $getGroupInfo = (Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers $headers -Method GET).content | ConvertFrom-Json
         Write-Host ""
         Write-Host "Processing Group: " $getGroupInfo.full_name
         Write-Host "Group ID: $gID"
         if($getGroupInfo.stats.last_message_at -ne $null)
         {
             Write-Host "Last Message Date: "$getGroupInfo.stats.last_message_at
         }
         else
         {
            Write-Host "Last Message Date: No messages in group" 
         }
        
         Write-Host "Is group currently visible: "$getGroupInfo.show_in_directory

         #Make the change
         if($whatIfMode){
             Write-Host "WhatIf mode enabled, no changes were made to group $gID." -ForegroundColor Yellow
         }
         else{
             #Create payload, set to visible
             $communityPayload = @{"show_in_directory" = "true"} | ConvertTo-Json
             $updateGroup = Invoke-WebRequest "https://www.yammer.com/api/v1/groups/$gID.json" -Headers $headers -Method PUT -Body $communityPayload
             Write-Host "Successfully changed group $gID to visible" -ForegroundColor Green
         }
     }
     catch {
         if($_.Exception.Response.StatusCode.Value__ -eq "401"){
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
 }
