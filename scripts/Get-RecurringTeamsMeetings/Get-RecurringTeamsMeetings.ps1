<#
.SYNOPSIS
    Reports on recurring Teams meetings for either all users or a targeted list from a CSV.

.DESCRIPTION
    This script connects to Microsoft Graph using Application permissions to find recurring Teams meetings.
    It can run against all users in the tenant or a specific list of users provided via the -UserCsvPath parameter.
    It prompts for connection details securely and saves the report in the same directory as the script.
.NOTES
    Published by: Alejandro Lopez | alejandro.lopez@microsoft.com
    Published on: September 24th, 2025
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Optional. Path to a CSV file with a 'UserPrincipalName' header to scan only specific users.")]
    [string]$UserCsvPath
)

# Step 1: Prompt for connection details and connect to Microsoft Graph
Write-Host "Please provide your App Registration details to connect." -ForegroundColor Yellow

try {
    $tenantId = Read-Host "Enter your Directory (Tenant) ID"
    $appId    = Read-Host "Enter your Application (Client) ID"
    $secureClientSecret = Read-Host "Enter your Client Secret" -AsSecureString
    if ([string]::IsNullOrWhiteSpace($tenantId) -or [string]::IsNullOrWhiteSpace($appId) -or $secureClientSecret.Length -eq 0) {
        Write-Host "❌ Tenant ID, App ID, and Client Secret cannot be empty." -ForegroundColor Red; return
    }
    $credential = New-Object System.Management.Automation.PSCredential($appId, $secureClientSecret)
    Write-Host "Connecting to Microsoft Graph..."
    Connect-MgGraph -TenantId $tenantId -Credential $credential -ErrorAction Stop
}
catch {
    Write-Host "❌ Connection Failed. Please verify your connection details." -ForegroundColor Red; return
}

$context = Get-MgContext
Write-Host "✅ Successfully connected using App '$($context.ClientId)' on tenant '$($context.TenantId)'" -ForegroundColor Green

# Step 2: Define where to save the report
$ExportPath = Join-Path -Path $PSScriptRoot -ChildPath "RecurringMeetingsReport.csv"
Write-Host "Report will be saved to $($ExportPath)"

# Step 3: Get the list of users to process
$allUsers = $null
if (-not [string]::IsNullOrWhiteSpace($UserCsvPath)) {
    # --- Logic for processing a specific list of users from a CSV ---
    Write-Host "✅ A user CSV was provided. Reading users from '$UserCsvPath'..." -ForegroundColor Green
    try {
        if (-not (Test-Path -Path $UserCsvPath)) {
            throw "File not found at specified path."
        }
        $usersFromCsv = Import-Csv -Path $UserCsvPath
        $userList = [System.Collections.Generic.List[object]]::new()
        foreach ($csvUser in $usersFromCsv) {
            $upn = $csvUser.UserPrincipalName
            Write-Host "   -> Fetching user object for '$upn'..."
            $mgUser = Get-MgUser -UserId $upn -ErrorAction Stop
            if ($mgUser) {
                $userList.Add($mgUser)
            }
        }
        $allUsers = $userList
    }
    catch {
        Write-Host "❌ Failed to process the CSV file. Make sure the path is correct and the file contains a 'UserPrincipalName' header." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }
}
else {
    # --- Original logic to get all users in the tenant ---
    Write-Host "Fetching all users in the tenant..."
    try {
        $allUsers = Get-MgUser -All -ErrorAction Stop
    }
    catch {
        Write-Host "❌ Error fetching users. Check App Registration permissions." -ForegroundColor Red; return
    }
}


if ($null -eq $allUsers -or $allUsers.Count -eq 0) {
    Write-Host "❌ No users were found to process. Please check the CSV file or your permissions." -ForegroundColor Red; return
}
Write-Host "✅ Found $($allUsers.Count) user(s) to process." -ForegroundColor Green

$reportData = [System.Collections.Generic.List[object]]::new()
$processedCount = 0

# Step 4: Loop through each user to check their calendar
# (The rest of the script from here remains the same)
foreach ($user in $allUsers) {
    $processedCount++
    Write-Host "($($processedCount)/$($allUsers.Count)) 🔎 Processing calendar for: $($user.UserPrincipalName)"
    try {
        $allUserEvents = Get-MgUserEvent -UserId $user.Id -Top 999 -ErrorAction SilentlyContinue
        if ($null -eq $allUserEvents) { Write-Host "   -> Calendar is empty or inaccessible." -ForegroundColor Gray; continue }
        $recurringEvents = $allUserEvents | Where-Object { $null -ne $_.Recurrence }
        if ($null -eq $recurringEvents) { Write-Host "   -> No recurring items found." -ForegroundColor Gray; continue }
        
        $recurringEvents = @($recurringEvents)
        Write-Host "   -> Found $($recurringEvents.Count) recurring items. Checking which are Teams meetings..." -ForegroundColor Cyan

        foreach ($event in $recurringEvents) {
            if ($event.IsOnlineMeeting) {
                Write-Host "      ✅ FOUND ONE: '$($event.Subject)'" -ForegroundColor Green
                $recurrencePattern = "$($event.Recurrence.Pattern.Type) every $($event.Recurrence.Pattern.Interval) period(s)"
                $participantList = $event.Attendees | ForEach-Object { $_.EmailAddress.Address }
                $participants = $participantList -join "; "
                $participantCount = $event.Attendees.Count
                $reportData.Add([PSCustomObject]@{
                    Organizer           = $user.UserPrincipalName
                    MeetingSubject      = $event.Subject
                    RecurrencePattern   = $recurrencePattern
                    ParticipantCount    = $participantCount
                    InvitedParticipants = $participants
                    CreatedDateTime     = $event.CreatedDateTime
                })
            } else { Write-Host "      -> Skipping '$($event.Subject)' (not a Teams meeting)." -ForegroundColor Gray }
        }
    }
    catch { Write-Host "❌ An error occurred processing calendar for $($user.UserPrincipalName): $($_.Exception.Message)" -ForegroundColor Red }
}

# Step 5: Export the collected data
if ($reportData.Count -gt 0) {
    Write-Host "✅ Processing complete. Exporting $($reportData.Count) records to CSV..." -ForegroundColor Green
    $reportData | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Report successfully saved!" -ForegroundColor Green
}
else {
    Write-Host "⚠️ Script finished, but no recurring Teams meetings were found." -ForegroundColor Yellow
}

# Step 6: Disconnect from Microsoft Graph
Disconnect-MgGraph