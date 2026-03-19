<#
.SYNOPSIS
    Provisions the PowerClaw-Workspace SharePoint site with required lists, including the PowerClaw Tasks list, and constitution files.
.DESCRIPTION
    This script sets up the backend infrastructure for the PowerClaw agent.
    It creates:
    1. 'Memory Log' list for tracking agent activities.
    2. 'Settings' list for configuration flags.
    3. 'PowerClaw Memory' list for long-term knowledge storage.
    4. 'PowerClaw Tasks' list for task intake, review, and completion tracking.
    5. Constitution files in 'Shared Documents' with default templates (soul.md, user.md, agents.md, tools.md, memory-journal.md).
.PARAMETER SiteUrl
    The full URL to the target SharePoint site (e.g., https://contoso.sharepoint.com/sites/PowerClaw-Workspace).
.PARAMETER AdminEmail
    Email address for administrative alerts (e.g., rate limits).
.PARAMETER ClientId
    Entra ID App Registration Client ID for PnP PowerShell authentication.
    Register one with: Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PowerClaw Setup" -Tenant yourtenant.onmicrosoft.com -DeviceLogin
.EXAMPLE
    .\Setup-PowerClaw.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/PowerClaw-Workspace" -AdminEmail "admin@contoso.com" -ClientId "your-client-id"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$AdminEmail,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $false)]
    [string]$AgentName = "PowerClaw"
)

# Configuration
$ErrorActionPreference = "Stop"
$libraryName = "Shared Documents"

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param($Message)
    Write-Host "ℹ️ $Message" -ForegroundColor Cyan
}

# Check for PnP.PowerShell module
Write-Info "Checking for PnP.PowerShell module..."
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    $confirmation = Read-Host "PnP.PowerShell module is not installed. Install now? (Y/N)"
    if ($confirmation -eq 'Y') {
        Write-Info "Installing PnP.PowerShell..."
        Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
        Write-Success "Module installed."
    } else {
        Write-ErrorMsg "PnP.PowerShell is required to run this script. Exiting."
        exit 1
    }
} else {
    Write-Success "PnP.PowerShell module found."
}

# Connect to SharePoint
try {
    Write-Info "Connecting to $SiteUrl..."
    Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
    Write-Success "Connected to SharePoint."
} catch {
    Write-ErrorMsg "Failed to connect to SharePoint: $_"
    Write-Info "If you don't have an Entra ID App Registration, create one with:"
    Write-Info "  Register-PnPEntraIDAppForInteractiveLogin -ApplicationName 'PowerClaw Setup' -Tenant yourtenant.onmicrosoft.com -DeviceLogin -SharePointDelegatePermissions AllSites.Manage"
    exit 1
}

# 1. Provision Memory Log List
try {
    $listName = "Memory Log"
    $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

    if (-not $list) {
        Write-Info "Creating '$listName' list..."
        $list = New-PnPList -Title $listName -Template GenericList
        
        # Add columns
        Add-PnPField -List $listName -DisplayName "EventType" -InternalName "EventType" -Type Choice -Choices "Heartbeat","HeartbeatSkipped","MemoryUpdate","Error","DailyDigest","WeeklyRecap","TaskAction" -AddToDefaultView
        Add-PnPField -List $listName -DisplayName "Summary" -InternalName "Summary" -Type Text -AddToDefaultView
        Add-PnPField -List $listName -DisplayName "FullContextJSON" -InternalName "FullContextJSON" -Type Note
        Add-PnPField -List $listName -DisplayName "Timestamp" -InternalName "Timestamp" -Type DateTime -AddToDefaultView
        
        # Set Timestamp default to Now (handled by flow usually, but good practice)
        # Note: Setting default value for DateTime via PnP is complex, skipping for simplicity as Flow handles it.

        Write-Success "'$listName' list created."
    } else {
        Write-Info "'$listName' list already exists. Skipping creation."
    }
} catch {
    Write-ErrorMsg "Failed to provision '$listName': $_"
}

# 2. Provision Settings List
try {
    $settingsListName = "Settings"
    $settingsList = Get-PnPList -Identity $settingsListName -ErrorAction SilentlyContinue

    if (-not $settingsList) {
        Write-Info "Creating '$settingsListName' list..."
        $settingsList = New-PnPList -Title $settingsListName -Template GenericList
        
        # Add columns
        Add-PnPField -List $settingsListName -DisplayName "SettingName" -InternalName "SettingName" -Type Text -AddToDefaultView
        Add-PnPField -List $settingsListName -DisplayName "SettingValue" -InternalName "SettingValue" -Type Text -AddToDefaultView
        
        # Add default items
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "KillSwitch"; "SettingName" = "KillSwitch"; "SettingValue" = "false"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "IsRunning"; "SettingName" = "IsRunning"; "SettingValue" = "false"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "MaxActionsPerHour"; "SettingName" = "MaxActionsPerHour"; "SettingValue" = "10"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "DigestEnabled"; "SettingName" = "DigestEnabled"; "SettingValue" = "true"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "DigestTimeUTC"; "SettingName" = "DigestTimeUTC"; "SettingValue" = "08:00"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "WeeklyRecapDay"; "SettingName" = "WeeklyRecapDay"; "SettingValue" = "Friday"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "QuietHoursStart"; "SettingName" = "QuietHoursStart"; "SettingValue" = "22"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "QuietHoursEnd"; "SettingName" = "QuietHoursEnd"; "SettingValue" = "07"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "TeamsMessageMode"; "SettingName" = "TeamsMessageMode"; "SettingValue" = "direct_chat_only"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "MemoryConsolidationEnabled"; "SettingName" = "MemoryConsolidationEnabled"; "SettingValue" = "true"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "MemoryMaxActiveItems"; "SettingName" = "MemoryMaxActiveItems"; "SettingValue" = "100"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "LastHousekeepingDate"; "SettingName" = "LastHousekeepingDate"; "SettingValue" = "2000-01-01"} | Out-Null
        Add-PnPListItem -List $settingsListName -Values @{"Title" = "AgentName"; "SettingName" = "AgentName"; "SettingValue" = $AgentName} | Out-Null
        
        Write-Success "'$settingsListName' list created and populated."
    } else {
        Write-Info "'$settingsListName' list already exists. Checking for missing settings..."
        # Backfill AgentName setting if missing
        $existingItems = Get-PnPListItem -List $settingsListName -Fields "SettingName" | Where-Object { $_["SettingName"] -eq "AgentName" }
        if (-not $existingItems) {
            Add-PnPListItem -List $settingsListName -Values @{"Title" = "AgentName"; "SettingName" = "AgentName"; "SettingValue" = $AgentName} | Out-Null
            Write-Success "Backfilled 'AgentName' setting with value '$AgentName'."
        } else {
            Write-Info "'AgentName' setting already exists. Skipping."
        }
    }
} catch {
    Write-ErrorMsg "Failed to provision '$settingsListName': $_"
}

# 3. Provision PowerClaw Memory List (Long-Term Knowledge Store)
try {
    $memoryListName = "PowerClaw Memory"
    $memoryList = Get-PnPList -Identity $memoryListName -ErrorAction SilentlyContinue

    if (-not $memoryList) {
        Write-Info "Creating '$memoryListName' list..."
        $memoryList = New-PnPList -Title $memoryListName -Template GenericList
        
        # Categorization
        Add-PnPField -List $memoryListName -DisplayName "MemoryType" -InternalName "MemoryType" -Type Choice -Choices "Preference","Person","Project","Pattern","Commitment","Insight" -AddToDefaultView
        Add-PnPField -List $memoryListName -DisplayName "ScopeKey" -InternalName "ScopeKey" -Type Text -AddToDefaultView
        Add-PnPField -List $memoryListName -DisplayName "CanonicalFact" -InternalName "CanonicalFact" -Type Note -AddToDefaultView
        
        # Confidence & Status
        Add-PnPField -List $memoryListName -DisplayName "Confidence" -InternalName "Confidence" -Type Number -AddToDefaultView
        Add-PnPField -List $memoryListName -DisplayName "Status" -InternalName "Status" -Type Choice -Choices "Active","Tentative","Superseded","Expired","Archived" -AddToDefaultView
        Add-PnPField -List $memoryListName -DisplayName "Importance" -InternalName "Importance" -Type Choice -Choices "Low","Med","High","Critical" -AddToDefaultView
        
        # Lifecycle dates
        Add-PnPField -List $memoryListName -DisplayName "FirstLearnedAt" -InternalName "FirstLearnedAt" -Type DateTime
        Add-PnPField -List $memoryListName -DisplayName "LastConfirmedAt" -InternalName "LastConfirmedAt" -Type DateTime -AddToDefaultView
        Add-PnPField -List $memoryListName -DisplayName "ReviewAfter" -InternalName "ReviewAfter" -Type DateTime
        Add-PnPField -List $memoryListName -DisplayName "ExpiresAt" -InternalName "ExpiresAt" -Type DateTime
        
        # Provenance
        Add-PnPField -List $memoryListName -DisplayName "EvidenceSummary" -InternalName "EvidenceSummary" -Type Note
        Add-PnPField -List $memoryListName -DisplayName "UsageCount" -InternalName "UsageCount" -Type Number
        
        Write-Success "'$memoryListName' list created."
    } else {
        Write-Info "'$memoryListName' list already exists. Skipping creation."
    }
} catch {
    Write-ErrorMsg "Failed to provision '$memoryListName': $_"
}

# 4. Provision PowerClaw Tasks List
try {
    $tasksListName = "PowerClaw Tasks"
    $tasksList = Get-PnPList -Identity $tasksListName -ErrorAction SilentlyContinue

    if (-not $tasksList) {
        Write-Info "Creating '$tasksListName' list..."
        $tasksList = New-PnPList -Title $tasksListName -Template GenericList

        $taskStatusXml = '<Field Type="Choice" DisplayName="TaskStatus" Name="TaskStatus" Required="FALSE"><Default>To Do</Default><CHOICES><CHOICE>To Do</CHOICE><CHOICE>Human Review</CHOICE><CHOICE>Done</CHOICE></CHOICES></Field>'
        Add-PnPFieldFromXml -List $tasksListName -FieldXml $taskStatusXml | Out-Null
        $taskStatusField = Get-PnPField -List $tasksListName -Identity "TaskStatus"
        $defaultView = Get-PnPView -List $tasksListName -Identity "All Items"
        $viewFields = @($defaultView.ViewFields) + "TaskStatus"
        Set-PnPView -List $tasksListName -Identity "All Items" -Fields $viewFields | Out-Null
        Add-PnPField -List $tasksListName -DisplayName "TaskDescription" -InternalName "TaskDescription" -Type Note
        Add-PnPField -List $tasksListName -DisplayName "Priority" -InternalName "Priority" -Type Choice -Choices "Low","Medium","High","Critical" -AddToDefaultView
        Add-PnPField -List $tasksListName -DisplayName "Source" -InternalName "Source" -Type Choice -Choices "Calendar","Manual","Heartbeat" -AddToDefaultView
        Add-PnPField -List $tasksListName -DisplayName "DueDate" -InternalName "DueDate" -Type DateTime -AddToDefaultView
        Add-PnPField -List $tasksListName -DisplayName "Notes" -InternalName "Notes" -Type Note
        Add-PnPField -List $tasksListName -DisplayName "LastActionDate" -InternalName "LastActionDate" -Type DateTime
        Add-PnPField -List $tasksListName -DisplayName "CompletedDate" -InternalName "CompletedDate" -Type DateTime

        # Make Title not required — PatchItem (task status updates) only changes status/notes,
        # and the SharePoint connector rejects PatchItem without Title when it's required
        $titleField = Get-PnPField -List $tasksListName -Identity "Title"
        $titleField.Required = $false
        $titleField.Update()
        Invoke-PnPQuery

        Write-Success "'$tasksListName' list created."
    } else {
        Write-Info "'$tasksListName' list already exists. Skipping creation."
    }
} catch {
    Write-ErrorMsg "Failed to provision '$tasksListName': $_"
}

# 5. Create Constitution Files
try {
    Write-Info "Provisioning constitution files in '$libraryName'..."
    
    # Define file contents
    $soulContent = @"
# $AgentName Soul
You are $AgentName, your user's AI copilot — an intelligent enterprise assistant running on Microsoft 365 and powered by the PowerClaw framework.
Your primary goal is to assist the user by autonomously managing tasks, summarizing information, and providing actionable insights.

## Identity
- Your name is **$AgentName**. You respond to this name in conversations.
- When appropriate, sign off messages with your name to establish your identity (e.g., "— $AgentName").
- You are powered by the PowerClaw autonomous agent framework, but your persona is $AgentName.
- Email subjects still use "PowerClaw:" prefix (product branding, not your name).
- Calendar routines still use [PowerClaw routine] tags (operational convention).

## Core Values
1. **Proactive**: Don't wait to be asked. If you see meeting conflicts or an urgent email, flag it.
2. **Secure**: Never expose sensitive data outside the tenant. Respect privacy.
3. **Concise**: The user is busy. Be brief. Use bullet points.
4. **Transparent**: Always log your actions to the Memory Log.
"@

    $userContent = @"
# User Profile
**Name**: [User Name]
**Role**: [Job Title]
**Department**: [Department]
**Organization**: [Organization Name]

## Preferences
- **Communication Style**: Direct and professional.
- **Meeting Hours**: 9:00 AM - 5:00 PM [Timezone]
- **Focus Time**: No interruptions between 2:00 PM - 4:00 PM.

## Team
- **Direct Reports**: [Name 1], [Name 2]
- **Manager**: [Manager Name]
"@

    $agentsContent = @"
# Operating Rules

## Heartbeat Behavior
On each heartbeat, evaluate what actions to take based on the current time and context.

### Calendar Monitoring
- Check for meetings in the next 2 hours
- Flag any double-bookings or conflicts
- If a meeting starts within 15 minutes, prepare a brief: attendees, agenda, relevant recent emails/docs

### Email Triage
- Check for unread emails from VIPs (Manager, Direct Reports listed in user.md)
- Flag emails with "urgent", "ASAP", or "action required" in subject
- Summarize key emails that need attention

### Task Management (PowerClaw Tasks List)
- Tasks are managed via the "PowerClaw Tasks" SharePoint list on this workspace site
- 3 statuses: To Do → Human Review → Done
- On heartbeat: check for "To Do" tasks, pick up new ones, send analysis via email
- Move completed work to "Human Review" for user approval
- User marks tasks "Done" when satisfied
- Create tasks from calendar events, emails, or user requests
- Always check memory before acting on a task to avoid duplicates

### Daily Digest (Morning Brief)
- Send between 07:00-09:00 UTC (adjustable via DigestTimeUTC setting)
- Only send ONCE per day — check memory log for existing DailyDigest entry today
- Include: today's calendar, overdue tasks, tasks due today, urgent emails, any conflicts
- Send via Teams message

### Weekly Recap (Friday)
- Send on Fridays between 15:00-17:00 UTC (adjustable via WeeklyRecapDay setting)
- Summarize: meetings attended, tasks completed, key decisions, upcoming Monday priorities
- Only send ONCE per week

### Quiet Hours
- Between QuietHoursStart and QuietHoursEnd (default 22:00-07:00 UTC), do NOT send proactive notifications
- Still perform checks and log to memory, just don't message the user
- Exception: if something is flagged truly urgent, notify anyway

### Notification Rules
- ALWAYS send proactive messages to the user's 1:1 direct chat ONLY — NEVER to group chats or channels
- If you cannot identify the correct 1:1 chat, fall back to email instead
- Only post to group chats or channels if the user explicitly asks you to in an interactive conversation
- Be concise — use bullet points
- Always log what you did to the Memory Log with appropriate EventType
"@

    $toolsContent = @"
# Available Tools

## WorkIQ MCP Capabilities
You have access to Microsoft 365 through WorkIQ MCP servers:

### Calendar (WorkIQ Calendar MCP)
- Read calendar events, check free/busy, find conflicts
- Look ahead for upcoming meetings

### Mail (WorkIQ Mail MCP)  
- Read emails, search inbox, check unread
- Send emails when instructed

### Teams (WorkIQ Teams MCP + Teams Connector)
- Send messages to chats and channels
- Read recent messages for context

### Task Management (SharePoint Lists MCP)
- Read and manage tasks in the "PowerClaw Tasks" SharePoint list
- Create new tasks with Title, TaskStatus, Priority, Source, DueDate, TaskDescription
- Update task status: To Do → Human Review → Done
- Add notes and deliverables to tasks via the Notes column
- No Plan ID discovery needed — tasks are in a simple SharePoint list on this workspace site

### User Profile (WorkIQ User MCP)
- Look up user details, org chart, reporting structure

### Documents (WorkIQ Word MCP + SharePoint Lists MCP)
- Read and search documents in SharePoint/OneDrive
- Access SharePoint list data

### Copilot Search (WorkIQ Copilot MCP)
- Search across M365 for relevant content
- Find documents, emails, and conversations by topic

## Usage Guidelines
- Prefer WorkIQ MCP tools for read operations
- Use connector actions (Teams Post, Outlook Send) for write operations
- Always check memory log before sending digests to avoid duplicates
- Log all actions to the Memory Log for audit trail
"@

    # Helper to create file if not exists
    function Create-FileIfNotExists {
        param($FileName, $Content)
        $fileUrl = "/$libraryName/$FileName"
        # Check if file exists is tricky with PnP, simpler to try Get-PnPFile
        try {
            $null = Get-PnPFile -Url $fileUrl -ErrorAction Stop
            Write-Info "File '$FileName' already exists. Skipping."
        } catch {
            # File likely doesn't exist, create it
            # We need a temp file to upload
            $tempPath = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempPath -Value $Content
            Add-PnPFile -Path $tempPath -Folder $libraryName -NewFileName $FileName | Out-Null
            Remove-Item $tempPath
            Write-Success "Created '$FileName'."
        }
    }

    $journalContent = @"
# PowerClaw Memory Journal

## Today
_No entries yet. PowerClaw will append observations, patterns, and insights here._

## Emerging Patterns
_Recurring behaviors and trends will be noted here as they develop._

## Open Loops
_Follow-ups, pending items, and commitments tracked here._

## Weekly Synthesis
_End-of-week summaries consolidating the week's learnings._
"@

    Create-FileIfNotExists -FileName "soul.md" -Content $soulContent
    Create-FileIfNotExists -FileName "user.md" -Content $userContent
    Create-FileIfNotExists -FileName "agents.md" -Content $agentsContent
    Create-FileIfNotExists -FileName "tools.md" -Content $toolsContent
    Create-FileIfNotExists -FileName "memory-journal.md" -Content $journalContent

} catch {
    Write-ErrorMsg "Failed to create constitution files: $_"
}

# Summary
Write-Host "`n==========================================" -ForegroundColor White
Write-Host "       PowerClaw Provisioning Complete      " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor White
Write-Success "SharePoint site '$SiteUrl' is ready."
Write-Info "Next Steps:"
Write-Info "1. Import the PowerClaw Solution in Power Apps (make.powerapps.com)."
Write-Info "2. Update the 'user.md' file in 'Shared Documents' with your details."
Write-Info "3. Verify the connection references in the imported solution."
Write-Host "==========================================" -ForegroundColor White
