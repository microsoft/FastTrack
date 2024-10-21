<#
.SYNOPSIS
Deletes all messages in a single Viva Engage community.
THIS IS INTENDED FOR NON-PRODUCTION ENVIRONMENTS ONLY.

.DESCRIPTION
This script deletes all messages in an existing Viva Engage community based on the group ID supplied.

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

Author: Dean Cron - dean.cron@microsoft.com

    1. Admin-created bearer token for Yammer app authentication:
        https://learn.microsoft.com/en-us/rest/api/yammer/app-registration
        https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

    2. ID of the group you want to delete all messages from. See the following article for more information on how to get the group ID:
        https://learn.microsoft.com/en-us/viva/engage/manage-communities/manage-communities#find-the-id-of-a-community

.EXAMPLE
.\Delete-AllCommunityPosts.ps1

#>

<############    STUFF YOU NEED TO MODIFY    ############>

#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerToken"

#The ID of the group you want to delete all messages from.
$GroupId = 1111111111111

#Change to $false when you're ready to actually delete the groups. DELETION CAN'T BE UNDONE.
$whatIfMode = $true

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

function Get-YammerAuthHeader {
    @{ AUTHORIZATION = "Bearer $YammerAuthToken" }
}

$authHeader = Get-YammerAuthHeader

function Get-AllPosts($lastMessageId, $allPosts) {
    if (!$allPosts) {
        $allPosts = New-Object System.Collections.ArrayList($null)
    }

    if ($null -ne $lastMessageId) {
        $urlToCall += "&older_than=" + $lastMessageId;
    }

    $urlToCall = "https://www.yammer.com/api/v1/messages/in_group/$GroupId.json"
    if ($null -ne $lastMessageId) {
        $urlToCall += "?older_than=" + $lastMessageId;
    }

    try{
        $response = Invoke-RestMethod -Uri $urlToCall -Headers $authHeader -Method Get
    }
    catch{
        if($_.Exception.Response.StatusCode.Value__ -eq "404"){
                #Typically thrown when the group isn't found. Exit here.
                Write-Host "Exiting script, API reports 404, typically caused if the group ($GroupId) was not found" -ForegroundColor Red
                exit
            }
        elseif($_.Exception.Response.StatusCode.Value__ -eq "401"){
                #Thrown when the YammerAuthToken is invalid. Exit here.
                Write-Host "Exiting script, API reports ACCESS DENIED. Please ensure a valid developer token is set for the YammerAuthToken variable" -ForegroundColor Red
                exit
        }
        else{  
            $errorMessage = $_
            Write-Host "Failed to get messages from group $GroupId. Error:" $errorMessage -ForegroundColor Red
            exit
        }
    }


    $allPosts.AddRange($response.messages)

    if ($response.meta.older_available) {
        $lastMessageId = $response.messages[-1].id
        Get-AllPosts $lastMessageId $allPosts
    }
    else {
        return $allPosts
    }
}

Write-Host "Getting all messages in group $GroupId" -ForegroundColor Green
$groupMessages = Get-AllPosts

Write-Host "`nThere are" $groupMessages.Count "messages in group $GroupId. Starting deletion.`n" -ForegroundColor Yellow
$groupMessages | ForEach-Object {
    do {
        $rateLimitHit = $false
        $messageId = $_.id -as [decimal]

        try {
            if($whatIfMode){
                Write-Host "WhatIf mode enabled, would have successfully deleted message $messageId" -ForegroundColor Green
            }
            else{
                $deleteMessage = Invoke-WebRequest "https://www.yammer.com/api/v1/messages/$messageId.json" -Headers $authHeader -Method DELETE
                Write-Host "Successfully deleted message $messageId" -ForegroundColor Green
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
            else{
                #Fallback, no idea what happened to get us here.
                $errorMessage = $_
                Write-Host "Failed to delete message $messageId. Error:" $errorMessage -ForegroundColor Red
            }
        }
        if ($rateLimitHit) {
            #429 or 503: Sleep for a bit before retrying
            Write-Host "Rate limit hit, sleeping for 5 seconds before retrying" -ForegroundColor Yellow
            Start-Sleep -Seconds 15
        }

    }while ($rateLimitHit)
}