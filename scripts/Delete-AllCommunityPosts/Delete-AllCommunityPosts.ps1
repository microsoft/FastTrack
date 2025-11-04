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

Version:
    1.0 - June 2024 - Initial release
    2.0 - November 2025 - Updated auth
Requirements:

    1. MSAL.PS PowerShell module. Install it from the PowerShell Gallery with the command:
        Install-Module MSAL.PS

    2. An Azure AD App Registration with the following API permissions:
        -Yammer: access_as_user

    2. ID of the group you want to delete all messages from. See the following article for more information on how to get the group ID:
        https://learn.microsoft.com/en-us/viva/engage/manage-communities/manage-communities#find-the-id-of-a-community

.EXAMPLE
.\Delete-AllCommunityPosts.ps1

#>

<############    STUFF YOU NEED TO MODIFY    ############>

# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantId"
$RedirectUri = "https://localhost"

#The ID of the group you want to delete all messages from.
$GroupId = 1111111111111

#Change to $false when you're ready to actually delete the groups. DELETION CAN'T BE UNDONE.
$whatIfMode = $true

#By default, messages are soft-deleted. Set to $true to hard-delete messages. 
#WARNING: Hard-deleted messages can't be recovered in a data export, so think carefully before setting this to $true.
$hardDelete = $false

#Path to save the backup of messages to if you choose to back them up before deletion.
$messageBackupPath = "YammerGroupMessagesBackup{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")

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

$authHeader = Get-YammerAuthHeader

function Get-AllPosts($lastMessageId, $allPosts) {
    if (!$allPosts) {
        $allPosts = New-Object System.Collections.ArrayList($null)
    }

    $urlToCall = "https://www.yammer.com/api/v1/messages/in_group/$GroupId.json"
    
    if ($null -ne $lastMessageId) {
        $urlToCall += "?older_than=" + $lastMessageId
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

Function Read-YesNoChoice {
	Param (
        [Parameter(Mandatory=$true)][String]$Title,
		[Parameter(Mandatory=$true)][String]$Message,
		[Parameter(Mandatory=$false)][Int]$DefaultOption = 1
    )
	
	$No = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'No'
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Yes'
	$Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
	
	return $host.ui.PromptForChoice($Title, $Message, $Options, $DefaultOption)
}

Write-Host "Getting all messages in group $GroupId" -ForegroundColor Green
$groupMessages = Get-AllPosts

Write-Host "`nThere are" $groupMessages.Count "messages in group" $GroupId -ForegroundColor Yellow

#Give the option to back up messages to CSV before deletion
$doBackup = Read-YesNoChoice -Title "THIS IS A DATA DESTRUCTIVE OPERATION. You will not be able to restore these messages to this community" -Message "Would you like to back these messages up to CSV first?"
if ($doBackup -eq 1) {
    Write-Host "`nBacking up messages to CSV file $messageBackupPath" -ForegroundColor Yellow
    $groupMessages | Export-Csv -Path $messageBackupPath -NoTypeInformation
    Write-Host "`nStarting deletion of all messages in group $GroupId.`n" -ForegroundColor Yellow
}
else {
    #Last chance to back out if hard-delete is enabled
    if ($hardDelete) {
        $areYouSure = Read-YesNoChoice -Title "`nAGAIN, THIS IS A DATA DESTRUCTIVE OPERATION, AND YOU'VE ENABLED HARD-DELETE MODE" -Message "You chose not to create a backup. Are you ABSOLUTELY SURE you want to continue?"
        if ($areYouSure -eq 1) {
            #It's your funeral
            Write-Host "`nYes selected, proceeding to hard-delete all messages in group $GroupId without a backup `n" -ForegroundColor Yellow
        }
        else {
            #Whew, that was close
            Write-Host "`nExiting script. No messages in group $GroupId were deleted." -ForegroundColor Green
            exit
        }
    }
    else {
        #Messages can still be recovered in a data export when in a soft-delete state, so no need for the second confirmation
        Write-Host "`nSkipping backup, proceeding with soft-deletion of all messages in group $GroupId `n" -ForegroundColor Yellow
    }
}

$groupMessages | ForEach-Object {
    do {
        $rateLimitHit = $false
        $messageId = $_.id -as [decimal]

        try {
            if($whatIfMode){
                Write-Host "WhatIf mode enabled, would have successfully deleted message $messageId" -ForegroundColor Green
            }
            else{
                if($hardDelete){
                    #Purge messages if hardDelete is set to $true. This is a destructive operation.
                    $deleteMessage = Invoke-WebRequest "https://www.yammer.com/api/v1/messages/$messageId.json?purge=true" -Headers $authHeader -Method DELETE
                    Write-Host "Successfully hard-deleted message $messageId" -ForegroundColor Green
                }
                else{
                    #Soft-delete messages by default, which can be recovered in a data export.
                    $deleteMessage = Invoke-WebRequest "https://www.yammer.com/api/v1/messages/$messageId.json" -Headers $authHeader -Method DELETE
                    Write-Host "Successfully soft-deleted message $messageId" -ForegroundColor Green
                }
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