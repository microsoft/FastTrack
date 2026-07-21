<#

Get-MgUserVoicemailReport.ps1 PowerShell script | Version 0.1

by David.Whitney@microsoft.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

#>

[CmdletBinding()]
param (
    # Optional user to report VMs for. If blank, will report on all users in Azure Active Directory
    [Parameter(Mandatory = $false)]
    [string]
    $User,

    # Earliest day to filter report on, for example "2022-01-01"
    [Parameter(Mandatory = $false)]
    [DateTime]
    $ReceivedDateTimeStart,

    # Latest day to filter report on, for example "2022-01-31"
    [Parameter(Mandatory = $false)]
    [DateTime]
    $ReceivedDateTimeEnd,

    # CSV file to save report results to, for example "C:\Users\me\Downloads\VMUserReport.csv"
    [Parameter(Mandatory = $false)]
    [System.IO.FileInfo]
    $ExportCSvFilePath
)

# Reference Graph API call:
# https://graph.microsoft.com/v1.0/users/testuser@dawhitne.net/messages?`$select=id,receivedDateTime,subject,from&`$filter=singleValueExtendedProperties/any(ep:ep/id eq 'String 0x001A' and startswith(ep/value, 'IPM.Note.Microsoft.Voicemail.UM'))&`$orderby=receivedDateTime DESC
# https://graph.microsoft.com/v1.0/users/testuser@dawhitne.net/messages?
#    `$select=id,receivedDateTime,subject,from&
#    `$filter=singleValueExtendedProperties/any(ep:ep/id eq 'String 0x001A' and startswith(ep/value, 'IPM.Note.Microsoft.Voicemail.UM')) and receivedDateTime ge 2022-01-01 and receivedDateTime le 2022-03-01&
#    `$orderby=receivedDateTime DESC

$MgModule  = Get-Module -Name "Microsoft.Graph.Authentication" -ListAvailable
if (-not ($MgModule)) {
    throw "This script requires the Microsoft.Graph (PowerShell SDK for Graph) module - use 'Install-Module Microsoft.Graph' from an elevated PowerShell session, restart this PowerShell session, then try again."
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$MgContext = Get-MgContext
if (-not (($MgContext) -and ($MgContext.AuthType -eq "AppOnly") -and ($MgContext.Scopes -contains "Mail.Read" -or $MgContext.Scopes -contains "Mail.ReadWrite"))) {
    throw "Please connect to Graph with Connect-MgGraph before running this script. It requires Application permissions with Mail.Read or Mail.ReadWrite scope to read user mail."
}

if (-not $ExportCSvFilePath) {
    $ExportCSvFilePath = ".\UserVoicemailReport-$(Get-Date -Format FileDateTime).csv"
}

$GraphUriBase = "https://graph.microsoft.com/v1.0"
$SelectString = "id,receivedDateTime,subject,from"
$OrderByString = "receivedDateTime DESC"
$VoicemailFilterString = "singleValueExtendedProperties/any(ep:ep/id eq 'String 0x001A' and startswith(ep/value, 'IPM.Note.Microsoft.Voicemail.UM'))"
# https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagmessageclass-canonical-property
# https://docs.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxoum/102b3a8b-1aad-4f29-90a3-998262d9fa26

$FullFilterSring = $VoicemailFilterString
if ($ReceivedDateTimeStart) {
    $FullFilterSring += " and receivedDateTime ge $($ReceivedDateTimeStart.ToString("yyyy-MM-dd"))"
}
if ($ReceivedDateTimeEnd) {
    $FullFilterSring += " and receivedDateTime le $($ReceivedDateTimeEnd.ToString("yyyy-MM-dd"))"
}

# Get the requested user from AAD, or all AAD users if not specified
# Users must have an email address to receive VMs so filtering on that

if ($User) {
    $SingleUserReturn = Invoke-MgGraphRequest -Uri "$($GraphUriBase)/Users/$($User)?`$select=userPrincipalName,mail" -ErrorAction Stop
    if ($SingleUserReturn.mail) {
        $UserList = $SingleUserReturn
    } else {
        throw "$($User) - Specified user does not have an email address (UPN: $($SingleUserReturn.value.userPrincipalName))"
    }
} else {
    Write-Progress -Id 1 -Activity "Pulling list of all users" -Status "Reading..."
    $AllUserReturn = Invoke-MgGraphRequest -Uri "$($GraphUriBase)/Users?`$select=userPrincipalName,mail&`$filter=userType eq 'Member'" -ErrorAction Stop
    $UserList = $AllUserReturn.value | Where-Object {$_.mail}
    while ($AllUserReturn."@odata.nextLink") {
        $AllUserReturn = Invoke-MgGraphRequest -Uri $AllUserReturn."@odata.nextLink"
        $UserList += $AllUserReturn.value | Where-Object {$_.mail}
    }
}

$AllUserVoicemails = @()
$UserCounter = 1
$UserTotal = $UserList.count
foreach ($UserEntry in $UserList) {
    Write-Progress -Id 1 -Activity "Pulling list of voicemails" -Status "Reading user $($UserEntry.mail)" -PercentComplete ($UserCounter / $UserTotal * 100)
    $GraphRequest = "$($GraphUriBase)/users/$($UserEntry.userPrincipalName)/messages?`$filter=$($FullFilterSring)&`$select=$($SelectString)&`$orderBy=$($OrderByString)"
    try {
        $GraphReturn = Invoke-MgGraphRequest -Method GET -Uri $GraphRequest
    } catch {
        #Write-Verbose "$($UserEntry.mail) - mailbox not found or not accessible"
    }
    if ($GraphReturn) {
        $UserVoicemailList = $GraphReturn.value | ForEach-Object {[PSCustomObject]$_}
        while ($GraphReturn."@odata.nextLink") {
            $GraphReturn = Invoke-MgGraphRequest -Uri $GraphReturn."@odata.nextLink"
            $UserVoicemailList += $GraphReturn.value | ForEach-Object {[PsCustomObject]$_}
        }

        # Add current username and mail to user voicemail list
        $UserVoicemailList | ForEach-Object {
            $_ | Add-Member -NotePropertyName "userPrincipalName" -NotePropertyValue $UserEntry.userPrincipalName
            $_ | Add-Member -NotePropertyName "mail" -NotePropertyValue $UserEntry.mail
        }

        # Expand from field to show from name and from address
        $UserVoicemailList | ForEach-Object {
            $_ | Add-Member -NotePropertyName "fromName" -NotePropertyValue $_.from.emailAddress.name
            $_ | Add-Member -NotePropertyName "fromAddress" -NotePropertyValue $_.from.emailAddress.address
        }

        $AllUserVoicemails += $UserVoicemailList | Select-Object UserPrincipalName, Mail, ReceivedDateTime, FromName, FromAddress, Subject, Id
    }
    $UserCounter++
}
Write-Progress -Id 1 -Activity "Pulling list of voicemails" -Completed

$AllUserVoicemails | Export-Csv $ExportCSvFilePath -NoTypeInformation
Write-Output "CSV Export saved to $(Resolve-Path $ExportCSVFilePath)"