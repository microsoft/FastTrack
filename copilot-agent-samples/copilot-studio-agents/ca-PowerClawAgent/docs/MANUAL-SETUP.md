# PowerClaw Manual Setup Guide

> Use this guide if you cannot use the Bootstrap flow or the PowerShell script.
> This is the universal, browser-only fallback and creates the same SharePoint workspace manually.
> Estimated time: ~15 minutes.

## Prerequisites
- A Microsoft 365 account with permission to create SharePoint sites
- SharePoint site owner permissions

## Step 1: Create the SharePoint Site
1. Go to `sharepoint.com` → **Create site** → **Team site** (or **Communication site**)
2. Name it `PowerClaw-Workspace` (or your preferred name)
3. Note the URL — for example: `https://contoso.sharepoint.com/sites/PowerClaw-Workspace`

## Step 2: Create Lists

### List 1: PowerClaw_Memory_Log
1. **Site contents** → **New** → **List** → **Blank list**
2. Name: `PowerClaw_Memory_Log`
3. Add columns:

| Column Name | Type |
|---|---|
| EventType | Choice (`Heartbeat`, `HeartbeatSkipped`, `MemoryUpdate`, `Error`, `DailyDigest`, `WeeklyRecap`, `TaskAction`) |
| Summary | Single line of text |
| FullContextJSON | Multiple lines of text |
| Timestamp | Date and time |

### List 2: PowerClaw_Config
1. **New** → **List** → **Blank list**
2. Name: `PowerClaw_Config`
3. Add columns:

| Column Name | Type |
|---|---|
| SettingName | Single line of text |
| SettingValue | Single line of text |

4. Add these items (use **Edit in grid view** or **New**):

| Title | SettingName | SettingValue |
|---|---|---|
| KillSwitch | KillSwitch | false |
| IsRunning | IsRunning | false |
| MaxActionsPerHour | MaxActionsPerHour | 20 |
| AdminEmail | AdminEmail | admin@contoso.com |

> Do **not** add any other config items.

### List 3: PowerClaw_Memory
1. **New** → **List** → **Blank list**
2. Name: `PowerClaw_Memory`
3. Add columns:

| Column Name | Type |
|---|---|
| MemoryType | Choice (`Preference`, `Person`, `Project`, `Pattern`, `Commitment`, `Insight`) |
| ScopeKey | Single line of text |
| CanonicalFact | Multiple lines of text |
| Confidence | Number |
| Status | Choice (`Active`, `Tentative`, `Superseded`, `Expired`, `Archived`) |
| Importance | Choice (`Low`, `Med`, `High`, `Critical`) |
| FirstLearnedAt | Date and time |
| LastConfirmedAt | Date and time |
| ReviewAfter | Date and time |
| ExpiresAt | Date and time |
| EvidenceSummary | Multiple lines of text |
| UsageCount | Number |

### List 4: PowerClaw_Tasks
1. **New** → **List** → **Blank list**
2. Name: `PowerClaw_Tasks`
3. Add columns:

| Column Name | Type |
|---|---|
| TaskStatus | Choice (`To Do`, `Human Review`, `Done`) — default `To Do` |
| TaskDescription | Multiple lines of text |
| Priority | Choice (`Low`, `Medium`, `High`, `Critical`) |
| Source | Choice (`Calendar`, `Manual`, `Heartbeat`) |
| DueDate | Date and time |
| Notes | Multiple lines of text |
| LastActionDate | Date and time |
| CompletedDate | Date and time |

4. **Make Title optional:**
   - **List settings** → click the **Title** column → change **Require that this column contains information** to **No** → **Save**

## Step 3: Create Constitution Files
1. Go to **Documents** (or **Shared Documents**)
2. Upload or create these 5 files:
   - `soul.md`
   - `user.md`
   - `agents.md`
   - `tools.md`
   - `memory-journal.md`

> **Tip:** Copy the default file content from `scripts/Setup-PowerClaw.ps1` in this repo if you need starter templates.

## Step 4: Import the Solution
1. Go to `make.powerapps.com`
2. **Solutions** → **Import** → upload `PowerClaw_Solution.zip`
3. Configure connection references when prompted
4. Enable the **HeartbeatFlow**, **GetContext**, and **Housekeeping** flows
5. Update the `Compose:_Config_SiteURL` action in each flow with your site URL (for example: `https://contoso.sharepoint.com/sites/PowerClaw-Workspace`)

## Done!
Your PowerClaw workspace is ready. Test by sending a message to the agent in Teams.
