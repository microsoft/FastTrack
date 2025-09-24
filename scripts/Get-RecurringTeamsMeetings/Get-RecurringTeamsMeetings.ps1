<#
.SYNOPSIS
    Reports on all recurring Teams meetings using a secure App Registration connection.

.DESCRIPTION
    This script connects to Microsoft Graph using Application permissions to find all recurring
    Teams meetings. It prompts for connection details securely. It fetches all calendar events
    for each user, filters them locally, and correctly handles complex attendee lists (e.g.,
    distribution lists, groups) to prevent errors in the final report. The report
    is saved in the same directory as the script.

.NOTES
    Published by: Alejandro Lopez | alejandro.lopez@microsoft.com
    Published on: September 24th, 2025
#>

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

# Step 3: Get all users in the tenant
Write-Host "Fetching users..."
try {
    $allUsers = Get-MgUser -All -ErrorAction Stop
}
catch {
    Write-Host "❌ Error fetching users. Check App Registration permissions." -ForegroundColor Red; return
}

if ($null -eq $allUsers) {
    Write-Host "❌ No users were found. Check permissions." -ForegroundColor Red; return
}
Write-Host "✅ Found $($allUsers.Count) user(s) to process." -ForegroundColor Green

$reportData = [System.Collections.Generic.List[object]]::new()
$processedCount = 0

# Step 4: Loop through each user to check their calendar
foreach ($user in $allUsers) {
    $processedCount++
    Write-Host "($($processedCount)/$($allUsers.Count)) 🔎 Processing calendar for: $($user.UserPrincipalName)"
    try {
        # Get all events for the user (up to 999) and filter them locally.
        $allUserEvents = Get-MgUserEvent -UserId $user.Id -Top 999 -ErrorAction SilentlyContinue

        if ($null -eq $allUserEvents) {
            Write-Host "   -> Calendar is empty or inaccessible for this user." -ForegroundColor Gray
            continue
        }

        # Perform the filtering locally in PowerShell
        $recurringEvents = $allUserEvents | Where-Object { $null -ne $_.Recurrence }

        if ($null -eq $recurringEvents) {
            Write-Host "   -> No recurring calendar items found for this user." -ForegroundColor Gray
            continue
        }

        $recurringEvents = @($recurringEvents)
        Write-Host "   -> Found $($recurringEvents.Count) recurring items. Checking which are Teams meetings..." -ForegroundColor Cyan

        foreach ($event in $recurringEvents) {
            if ($event.IsOnlineMeeting) {
                Write-Host "      ✅ FOUND ONE: '$($event.Subject)'" -ForegroundColor Green
                $recurrencePattern = "$($event.Recurrence.Pattern.Type) every $($event.Recurrence.Pattern.Interval) period(s)"
                
                # --- MODIFIED SECTION ---
                # This new method is more robust for handling different types of attendees.
                # It iterates through each attendee to safely extract their email address.
                $participantList = $event.Attendees | ForEach-Object { $_.EmailAddress.Address }
                $participants = $participantList -join "; "
                # --- END OF MODIFIED SECTION ---

                $participantCount = $event.Attendees.Count
                $reportData.Add([PSCustomObject]@{
                    Organizer           = $user.UserPrincipalName
                    MeetingSubject      = $event.Subject
                    RecurrencePattern   = $recurrencePattern
                    ParticipantCount    = $participantCount
                    InvitedParticipants = $participants
                    CreatedDateTime     = $event.CreatedDateTime
                })
            }
            else {
                 Write-Host "      -> Skipping item '$($event.Subject)' because it's not a Teams meeting." -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "❌ An error occurred processing calendar for $($user.UserPrincipalName): $($_.Exception.Message)" -ForegroundColor Red
    }
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