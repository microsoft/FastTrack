<#
.SYNOPSIS
    Inventories classic Copilot Studio agents in the default Power Platform
    environment (Microsoft 365 Copilot Agent Builder agents are excluded by
    default - see -IncludeAgentBuilder - and only the current/default
    environment is reported on by default - see -AllEnvironments).

.DESCRIPTION
    1. Creates (or reuses) an auth profile named "PPAgentInventory", connecting to the
       tenant's default environment, then runs `pac env who --json` to identify it.
    2. Queries the Power Platform inventory API directly (the same data source behind
       the "Agents" list in the Power Platform admin center) for every agent in the
       tenant - classic Copilot Studio agents and Microsoft 365 Copilot Agent Builder
       agents alike - joined to environment display names.
    3. Excludes Agent Builder agents (`createdIn` "Copilot Studio Lite" in this tenant)
       by default; pass -IncludeAgentBuilder to include them.
    4. Reports on the current environment only by default; pass -AllEnvironments to
       instead export ONLY a tenant-wide CSV/JSON/breakdown (current-environment output
       is skipped in that case). Output file names reflect what's included: the "full"
       prefix only appears with -IncludeAgentBuilder, and the "-all-environments"
       suffix only appears with -AllEnvironments.
    5. For classic Copilot Studio agents in the current environment, flags first-party
       Microsoft-managed agents (e.g. "Finance in Microsoft 365 Copilot") via Dataverse
       solution components, adding `isFirstPartyManaged`/`firstPartySolutionName`/
       `canMigrate` columns - Migrate-CopilotStudioAgents.ps1 auto-skips these. A blank
       value means "not checked" (agent outside the current environment), not
       "confirmed not first-party".

.NOTES
    Requires pac CLI (install: winget install --id Microsoft.PowerAppsCLI -e ,
    then run `pac install latest` once) and the MSAL.PS module
    (Install-Module MSAL.PS -Scope CurrentUser). This script checks for both
    automatically on startup (via Confirm-ScriptRequirements.ps1) and will
    offer to install whichever is missing for you, with your confirmation,
    before doing any real work. Interactive sign-in will prompt a browser
    window the first time each profile/token is created.

    Viewing the Power Platform inventory requires one of these Microsoft Entra
    roles: Global Administrator, Power Platform Administrator, Dynamics 365
    Administrator, Global Reader, or AI Administrator/AI Reader (scoped to
    AI-related resources). If you can see the "Agents" list in PPAC yourself,
    your account already has sufficient access for this script to use too.
#>

[CmdletBinding()]
param(
    [string]$ProfileName  = 'PPAgentInventory',
    [string]$OutputDir    = ".\PPAgentInventory-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    # By default this script focuses on classic Copilot Studio agents only (createdIn
    # -eq 'Copilot Studio'). Microsoft 365 Copilot Agent Builder agents - which the
    # inventory API currently reports with createdIn "Copilot Studio Lite" rather than
    # the documented "Microsoft 365 Copilot Agent Builder" - are excluded from every
    # output file unless this switch is passed.
    [switch]$IncludeAgentBuilder,
    # By default this script only reports on the current ("default") environment
    # (matched on the friendly name reported by `pac env who`). Pass -AllEnvironments
    # to instead export ONLY a tenant-wide CSV/JSON covering every environment (the
    # current-environment-only files/counts are skipped in that case).
    [switch]$AllEnvironments,
    # By default the Power Platform inventory / Dataverse Web API sign-in uses MSAL's
    # device code flow (open a URL, enter a code) since the embedded-browser -Interactive
    # flow can hang depending on WebView2/broker availability. Pass -UseInteractiveBrowser
    # to try that instead.
    [switch]$UseInteractiveBrowser
)

$ErrorActionPreference = 'Stop'

# --- Pre-flight: confirm required tooling is installed before doing any real work,
#     offering to install anything missing rather than failing deep into the script. ---
. (Join-Path $PSScriptRoot 'Confirm-ScriptRequirements.ps1')
Assert-ScriptRequirements -RequirePac -RequireMsalPs

# Converts a UTC/ISO-8601 datetime string (or a [datetime]) coming back from any of the
# APIs used here into the local machine's timezone, formatted as a short date/time string
# (culture-aware, e.g. "5/6/2026 4:47 PM" under en-US) instead of the raw ISO-8601 value.
function ConvertTo-LocalShortDateTime {
    param($Value)

    if ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value))) { return '' }
    try {
        $dt = if ($Value -is [datetime]) { $Value } else {
            # AdjustToUniversal + AssumeUniversal ensures a bare/'Z'-suffixed timestamp is
            # treated as UTC before converting to local, regardless of Kind on the input.
            [datetime]::Parse(
                $Value, [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal
            )
        }
        return $dt.ToLocalTime().ToString('g')
    }
    catch {
        return $Value
    }
}

# Produces a copy of an agent object with its datetime fields reformatted to a local short
# date/time string for the human-readable CSV, while leaving the original object (used for
# the raw JSON export) untouched with its precise, unambiguous ISO-8601/UTC values.
function ConvertTo-DisplayAgent {
    param($Agent)

    $display = $Agent | Select-Object -Property *
    $display.createdAt = ConvertTo-LocalShortDateTime $Agent.createdAt
    $display.lastPublishedAt = ConvertTo-LocalShortDateTime $Agent.lastPublishedAt
    $display.lastUsedAt = ConvertTo-LocalShortDateTime $Agent.lastUsedAt
    return $display
}

# Given a classic Copilot Studio agent's Dataverse bot ID, determines whether it belongs to
# any MANAGED solution matching a known Microsoft first-party prefix/publisher (msdyn, mscrm,
# msa, adx, mspp, msft) - e.g. "Finance in Microsoft 365 Copilot" belongs to the managed
# solution 'msdyn_FinancialReconciliationAgent'. These are Microsoft-authored prebuilt agents
# with no customizable content, so Migrate-CopilotStudioAgents.ps1 pre-flight-skips them; this
# function lets the inventory flag them here too, before a migration is even attempted. This
# heuristic prefix list is not exhaustive - it's confirmed against the one live example found
# in this tenant (msdyn_) but may miss other first-party solutions.
function Test-IsMicrosoftManagedAgent {
    param(
        [Parameter(Mandatory)][string]$InstanceUrl,
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][string]$AgentId
    )
    $managedPrefixes = @('msdyn', 'mscrm', 'msa', 'adx', 'mspp', 'msft')
    $resp = Invoke-RestMethod -Uri "$InstanceUrl/api/data/v9.2/solutioncomponents?`$filter=objectid eq $AgentId&`$select=componenttype&`$expand=solutionid(`$select=uniquename,ismanaged;`$expand=publisherid(`$select=customizationprefix))" -Headers $Headers -Method Get
    foreach ($c in $resp.value) {
        $sol = $c.solutionid
        if (-not $sol -or -not $sol.ismanaged) { continue }
        $prefix = $sol.publisherid.customizationprefix
        $isMicrosoftPattern = ($managedPrefixes | Where-Object { $sol.uniquename -like "$_*" -or $prefix -eq $_ }).Count -gt 0
        if ($isMicrosoftPattern) {
            return [PSCustomObject]@{ IsManaged = $true; SolutionUniqueName = $sol.uniquename }
        }
    }
    return [PSCustomObject]@{ IsManaged = $false; SolutionUniqueName = $null }
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# --- Ensure we're authenticated to the default environment ---
$authList = pac auth list 2>&1 | Out-String
if ($authList -match [regex]::Escape($ProfileName)) {
    Write-Host "Reusing existing auth profile '$ProfileName'..." -ForegroundColor Cyan
    pac auth select --name $ProfileName | Out-Null
}
else {
    Write-Host "Creating auth profile '$ProfileName' (connects to your tenant's default environment)..." -ForegroundColor Cyan
    Write-Host "A browser sign-in window will open." -ForegroundColor Yellow
    # No --environment => pac connects to the default environment (per Microsoft docs).
    pac auth create --name $ProfileName
}

# --- Confirm which environment we're targeting ---
$envWhoJsonRaw = pac env who --json 2>&1 | Out-String
$envWhoJsonRaw | Out-File -FilePath (Join-Path $OutputDir 'env-who.json') -Encoding UTF8

$envWho = $null
try { $envWho = ($envWhoJsonRaw -split "`r?`n" | Where-Object { $_.TrimStart().StartsWith('{') } | Select-Object -First 1) | ConvertFrom-Json }
catch { throw "Could not parse 'pac env who --json' output:`n$envWhoJsonRaw" }

Write-Host "`nEnvironment: $($envWho.FriendlyName)"
Write-Host "Org URL:     $($envWho.OrgUrl)"
Write-Host "Signed in as: $($envWho.UserEmail)`n"

$instanceUrl = $envWho.OrgUrl.TrimEnd('/')

# --- Full inventory (Copilot Studio + Agent Builder), via the Power Platform inventory API ---
# This is the same Azure-Resource-Graph-backed source that drives PPAC's Manage >
# Copilot Studio > Agents grid, so counts here should match what you see there -
# unlike the classic Dataverse "bot" table above, which never includes Agent
# Builder agents at all.
Write-Host "`nQuerying the Power Platform inventory API (microsoft.copilotstudio/agents) - this is what PPAC's Agents grid itself uses..." -ForegroundColor Cyan

# MSAL.PS presence/installation was already confirmed (and installed if needed) by
# Assert-ScriptRequirements at the top of this script.
Import-Module MSAL.PS -ErrorAction Stop
# Well-known "Microsoft Azure PowerShell" multi-tenant public client - broadly
# pre-consented, so no app registration is required for delegated access.
$clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
$ppApiBase = 'https://api.powerplatform.com'
# MSAL.PS 4.x has no -TokenCache path parameter on Get-MsalToken; instead you create a
# client application object and opt it into MSAL.NET's persistent on-disk cache via
# Enable-MsalTokenCacheOnDisk. That cache file (under %LOCALAPPDATA%, DPAPI-protected)
# is shared by any process using the same ClientId/TenantId, so repeated runs of this
# script (and pwsh processes, since each starts fresh) can reuse/refresh a token
# silently instead of prompting a new device code sign-in every time.
$clientApp = New-MsalClientApplication -ClientId $clientId -TenantId 'organizations'
Enable-MsalTokenCacheOnDisk -PublicClientApplication $clientApp | Out-Null
$msalCommonParams = @{
    PublicClientApplication = $clientApp
    Scopes                  = "$ppApiBase/.default"
}

Write-Host "Signing in for Power Platform inventory API access..." -ForegroundColor Cyan
try {
    # Try the cache first (silently refreshes an expired-but-not-revoked token too) -
    # avoids re-prompting for a device code / browser sign-in on every run.
    $token = (Get-MsalToken @msalCommonParams -Silent -ErrorAction Stop).AccessToken
    Write-Host "Reused cached sign-in (no prompt needed)." -ForegroundColor Green
}
catch {
    if ($UseInteractiveBrowser) {
        $token = (Get-MsalToken @msalCommonParams -Interactive).AccessToken
    }
    else {
        Write-Host "No valid cached token found - using device code flow (no browser popup to hang)." -ForegroundColor Yellow
        $token = (Get-MsalToken @msalCommonParams -DeviceCode).AccessToken
    }
}

$headers = @{
    Authorization  = "Bearer $token"
    'Content-Type' = 'application/json'
}

# Query every microsoft.copilotstudio/agents resource in the tenant, left-joined to
# environment display names, so we can filter down to the current environment by its
# friendly name (the one thing we know for certain matches what's shown in PPAC/pac).
#
# IMPORTANT: every clause hashtable below MUST be [ordered] with '$type' listed FIRST.
# Regular @{} hashtables have no guaranteed key order, so ConvertTo-Json can (and did,
# when this was discovered) emit '$type' anywhere in the object. The inventory API's
# polymorphic clause parser apparently requires '$type' to be the first property in
# each clause object to correctly dispatch it - otherwise it returns a 400 with a
# generic/misleading "KQLOM format is wrong or it cannot be null" error, even though
# the query is otherwise valid (confirmed by sending byte-identical JSON with '$type'
# moved to the front, which succeeds).
$queryBody = [ordered]@{
    TableName = 'PowerPlatformResources'
    Clauses   = @(
        [ordered]@{ '$type' = 'where'; FieldName = 'type'; Operator = '=='; Values = @("'microsoft.copilotstudio/agents'") }
        [ordered]@{
            '$type'         = 'extend'
            FieldName       = 'joinKey'
            Expression      = 'tolower(tostring(properties.environmentId))'
        }
        [ordered]@{
            '$type'         = 'join'
            JoinKind        = 'leftouter'
            LeftColumnName  = 'joinKey'
            RightColumnName = 'joinKey'
            RightTable      = [ordered]@{
                TableName = 'PowerPlatformResources'
                Clauses   = @(
                    [ordered]@{ '$type' = 'where'; FieldName = 'type'; Operator = '=='; Values = @("'microsoft.powerplatform/environments'") }
                    [ordered]@{ '$type' = 'project'; FieldList = @('joinKey = tolower(name)', 'environmentName = properties.displayName') }
                )
            }
        }
        [ordered]@{
            '$type'   = 'project'
            FieldList = @(
                'agentId = name'
                'agentName = properties.displayName'
                'createdIn = properties.createdIn'
                'createdAt = properties.createdAt'
                'createdByGUID = properties.createdBy'
                'ownerId = properties.ownerId'
                'lastPublishedAt = properties.lastPublishedAt'
                'environmentId = properties.environmentId'
                'environmentName'
            )
        }
    )
    Options   = [ordered]@{ Top = 500 }
}

# A List<object> + AddRange avoids the O(n^2) array-copy cost of += on every page (each
# microsoft.copilotstudio/agents page can return up to 500 rows via Options.Top).
$allAgents = [System.Collections.Generic.List[object]]::new()
$skipToken = $null
do {
    if ($skipToken) { $queryBody.Options.SkipToken = $skipToken }
    $bodyJson = $queryBody | ConvertTo-Json -Depth 10
    try {
        $resp = Invoke-RestMethod -Uri "$ppApiBase/resourcequery/resources/query?api-version=2024-10-01" -Headers $headers -Method Post -Body $bodyJson
    }
    catch {
        # Surface the API's actual JSON error body (ErrorDetails.Message isn't always
        # populated depending on PowerShell edition/version) instead of just the bare
        # "400 Bad Request" exception message, which hides the real cause.
        $responseBody = $null
        if ($_.ErrorDetails) { $responseBody = $_.ErrorDetails.Message }
        elseif ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $responseBody = (New-Object System.IO.StreamReader($stream)).ReadToEnd()
        }
        if ($responseBody) { Write-Host "API error response: $responseBody" -ForegroundColor Red }
        throw
    }
    # Wrap in @(...) because ConvertFrom-Json/Invoke-RestMethod collapses a JSON array
    # containing exactly one element down to a lone PSCustomObject instead of a
    # 1-item array, which would otherwise break AddRange on a single-result page.
    if ($resp.data) { $allAgents.AddRange(@($resp.data)) }
    $skipToken = $resp.skipToken
} while ($skipToken)

if ($allAgents.Count -eq 0) {
    Write-Warning "No agents returned from the Power Platform inventory API. Confirm your account has one of: Global Administrator, Power Platform Administrator, Dynamics 365 Administrator, Global Reader, AI Administrator/AI Reader."
}
else {
    # The inventory API only returns 'createdByGUID'/'ownerId' as raw Microsoft Entra
    # object IDs (GUIDs), with no display name/email/department of their own. Resolve
    # those IDs via Microsoft Graph's $batch endpoint (up to 20 sub-requests per call)
    # hitting /users/{id}?$select=... for each - directoryObjects/getByIds is cheaper
    # per-call (up to 1000 IDs) but only returns a fixed property set that does NOT
    # include department, so it can't be used here.
    Write-Host "`nResolving 'createdByGUID'/'ownerId' user IDs to display name/email/department via Microsoft Graph..." -ForegroundColor Cyan
    $creatorIds = $allAgents | ForEach-Object { $_.createdByGUID; $_.ownerId } |
        Where-Object { $_ -and $_ -ne '00000000-0000-0000-0000-000000000000' } | Select-Object -Unique
    $creatorInfo = @{}
    if ($creatorIds.Count -gt 0) {
        try {
            $graphToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes 'https://graph.microsoft.com/User.Read.All' -Silent -ErrorAction Stop).AccessToken
        }
        catch {
            if ($UseInteractiveBrowser) {
                $graphToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes 'https://graph.microsoft.com/User.Read.All' -Interactive).AccessToken
            }
            else {
                $graphToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes 'https://graph.microsoft.com/User.Read.All' -DeviceCode).AccessToken
            }
        }
        $graphHeaders = @{ Authorization = "Bearer $graphToken"; 'Content-Type' = 'application/json' }

        # $batch accepts up to 20 sub-requests per call.
        for ($i = 0; $i -lt $creatorIds.Count; $i += 20) {
            $batchIds = @($creatorIds[$i..([Math]::Min($i + 19, $creatorIds.Count - 1))])
            $requests = for ($j = 0; $j -lt $batchIds.Count; $j++) {
                @{ id = "$j"; method = 'GET'; url = "/users/$($batchIds[$j])?`$select=displayName,mail,userPrincipalName,department" }
            }
            $batchBody = @{ requests = @($requests) } | ConvertTo-Json -Depth 5
            try {
                $batchResp = Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/$batch' -Headers $graphHeaders -Method Post -Body $batchBody
                foreach ($r in $batchResp.responses) {
                    if ($r.status -eq 200) {
                        $creatorId = $batchIds[[int]$r.id]
                        $creatorInfo[$creatorId] = [PSCustomObject]@{
                            DisplayName = $r.body.displayName
                            # Guest/external users often have no 'mail' - fall back to UPN.
                            Email       = if ($r.body.mail) { $r.body.mail } else { $r.body.userPrincipalName }
                            Department  = $r.body.department
                        }
                    }
                }
            }
            catch {
                Write-Warning "Could not resolve a batch of createdByGUID/ownerId user IDs via Microsoft Graph (need at least User.Read.All / delegated directory read access): $($_.Exception.Message)"
            }
        }
    }

    foreach ($agent in $allAgents) {
        $isSystemCreated = $agent.createdByGUID -eq '00000000-0000-0000-0000-000000000000'
        $info = if ($agent.createdByGUID -and $creatorInfo.ContainsKey($agent.createdByGUID)) { $creatorInfo[$agent.createdByGUID] } else { $null }
        $ownerInfo = if ($agent.ownerId -and $creatorInfo.ContainsKey($agent.ownerId)) { $creatorInfo[$agent.ownerId] } else { $null }
        # No ownerId at all means the agent has no owner assigned - flag it as orphaned
        # rather than just leaving the owner columns blank, so it's easy to filter on.
        $isOrphaned = [string]::IsNullOrWhiteSpace($agent.ownerId)
        # One Add-Member call with -NotePropertyMembers (vs. separate calls) does a
        # single reflection/property-attach pass per object instead of several.
        $agent | Add-Member -NotePropertyMembers @{
            # The all-zero GUID means the agent was created by the system (not a real
            # user), so Microsoft Graph would never resolve it - label it explicitly.
            createdByName           = if ($isSystemCreated) { 'SYSTEM' } elseif ($info) { $info.DisplayName } else { '' }
            createdByEmail          = if ($info) { $info.Email } else { '' }
            createdByUserDepartment = if ($info) { $info.Department } else { '' }
            ownerName               = if ($isOrphaned) { 'ORPHANED - no owner assigned' } elseif ($ownerInfo) { $ownerInfo.DisplayName } else { '' }
            ownerEmail              = if ($ownerInfo) { $ownerInfo.Email } else { '' }
            ownerUserDepartment     = if ($ownerInfo) { $ownerInfo.Department } else { '' }
            isOrphaned              = $isOrphaned
        } -Force
    }
    Write-Host "Resolved $($creatorInfo.Count) of $($creatorIds.Count) distinct user ID(s) via Microsoft Graph." -ForegroundColor Green

    # Resolve last-used date for classic Copilot Studio agents in the CURRENT
    # environment only, via the Dataverse 'conversationtranscript' table (only
    # published-channel conversations are logged there - the Copilot Studio test
    # canvas does NOT log to this table). This requires a Dataverse Web API token
    # scoped to the current environment's own instance URL, so it can't cover agents
    # in other environments even when -AllEnvironments is used - those are left blank.
    $currentEnvClassicAgentIds = $allAgents |
        Where-Object { $_.environmentId -eq $envWho.EnvironmentId -and $_.createdIn -eq 'Copilot Studio' } |
        ForEach-Object { $_.agentId }
    $lastUsedByAgent = @{}
    $firstPartyByAgent = @{}
    if ($currentEnvClassicAgentIds.Count -gt 0) {
        Write-Host "`nResolving last-used dates for classic Copilot Studio agents via Dataverse conversation transcripts..." -ForegroundColor Cyan
        try {
            $dvToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$instanceUrl/.default" -Silent -ErrorAction Stop).AccessToken
        }
        catch {
            if ($UseInteractiveBrowser) {
                $dvToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$instanceUrl/.default" -Interactive).AccessToken
            }
            else {
                $dvToken = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$instanceUrl/.default" -DeviceCode).AccessToken
            }
        }
        $dvHeaders = @{
            Authorization    = "Bearer $dvToken"
            Accept           = 'application/json'
            'OData-MaxVersion' = '4.0'
            'OData-Version'    = '4.0'
        }
        try {
            # One tenant-wide-per-environment scan (with paging via @odata.nextLink)
            # instead of one call per agent - conversationstarttime is preferred over
            # createdon since it reflects when the conversation actually happened.
            $transcriptUri = "$instanceUrl/api/data/v9.2/conversationtranscripts?" +
                '$select=_bot_conversationtranscriptid_value,conversationstarttime,createdon'
            do {
                $tResp = Invoke-RestMethod -Uri $transcriptUri -Headers $dvHeaders -Method Get
                foreach ($t in $tResp.value) {
                    $botId = $t.'_bot_conversationtranscriptid_value'
                    if (-not $botId) { continue }
                    $ts = if ($t.conversationstarttime) { [datetime]$t.conversationstarttime } else { [datetime]$t.createdon }
                    if (-not $lastUsedByAgent.ContainsKey($botId) -or $ts -gt $lastUsedByAgent[$botId]) {
                        $lastUsedByAgent[$botId] = $ts
                    }
                }
                $transcriptUri = $tResp.'@odata.nextLink'
            } while ($transcriptUri)
            Write-Host "Resolved last-used date for $($lastUsedByAgent.Count) of $($currentEnvClassicAgentIds.Count) classic Copilot Studio agent(s) in the current environment." -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not resolve last-used dates via Dataverse conversation transcripts: $($_.Exception.Message)"
        }

        # Flag first-party Microsoft-managed agents (e.g. "Finance in Microsoft 365
        # Copilot") so it's obvious from the inventory alone which agents
        # Migrate-CopilotStudioAgents.ps1 will pre-flight-skip - reuses the same
        # Dataverse token/headers acquired above for the conversation-transcript lookup.
        Write-Host "`nChecking for first-party Microsoft-managed agents (auto-skipped by Migrate-CopilotStudioAgents.ps1) via Dataverse solution components..." -ForegroundColor Cyan
        try {
            foreach ($agentId in $currentEnvClassicAgentIds) {
                $firstPartyByAgent[$agentId] = Test-IsMicrosoftManagedAgent -InstanceUrl $instanceUrl -Headers $dvHeaders -AgentId $agentId
            }
            $firstPartyCount = ($firstPartyByAgent.Values | Where-Object { $_.IsManaged }).Count
            Write-Host "Found $firstPartyCount first-party Microsoft-managed agent(s) among $($currentEnvClassicAgentIds.Count) classic Copilot Studio agent(s) in the current environment." -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not determine first-party/managed status via Dataverse solution components: $($_.Exception.Message)"
        }
    }
    foreach ($agent in $allAgents) {
        # Store the raw UTC ISO-8601 value here (not the local short-format string) so
        # this field stays precise/unambiguous for the JSON export; formatting for the
        # CSV happens separately via ConvertTo-DisplayAgent at export time.
        $lastUsedAt = if ($lastUsedByAgent.ContainsKey($agent.agentId)) { $lastUsedByAgent[$agent.agentId].ToUniversalTime().ToString('o') } else { '' }
        # Blank (not $false) means this agent wasn't checked at all - i.e. it's in a
        # different environment than the current one, or isn't a classic Copilot Studio
        # agent - rather than a confirmed "not first-party" result.
        $managedInfo = if ($firstPartyByAgent.ContainsKey($agent.agentId)) { $firstPartyByAgent[$agent.agentId] } else { $null }
        # canMigrate reflects ONLY the first-party check above (blank if not checked,
        # $false if first-party/Microsoft-managed, $true otherwise) - it does NOT
        # account for the other reasons Migrate-CopilotStudioAgents.ps1 might still skip
        # an agent (e.g. no owner/creator department mapping, same source/target env).
        $agent | Add-Member -NotePropertyMembers @{
            lastUsedAt             = $lastUsedAt
            isFirstPartyManaged    = if ($null -eq $managedInfo) { '' } else { $managedInfo.IsManaged }
            firstPartySolutionName = if ($managedInfo -and $managedInfo.IsManaged) { $managedInfo.SolutionUniqueName } else { '' }
            canMigrate             = if ($null -eq $managedInfo) { '' } else { -not $managedInfo.IsManaged }
        } -Force
    }

    # Add-Member always appends new properties after existing ones, so the loops above
    # leave the creator/owner/lastUsedAt fields trailing at the very end. Re-project
    # each object into the desired column order (creator fields grouped right after
    # createdByGUID, owner fields grouped right after ownerId) before export.
    $columnOrder = @(
        'agentId', 'agentName', 'createdIn', 'isFirstPartyManaged', 'firstPartySolutionName', 'canMigrate',
        'createdAt', 'createdByGUID',
        'createdByName', 'createdByEmail', 'createdByUserDepartment',
        'ownerId', 'ownerName', 'ownerEmail', 'ownerUserDepartment', 'isOrphaned',
        'lastPublishedAt', 'lastUsedAt', 'environmentId', 'environmentName'
    )
    $allAgents = [System.Collections.Generic.List[object]]::new([object[]]($allAgents | Select-Object -Property $columnOrder))

    # Focus on classic Copilot Studio agents by default - exclude Microsoft 365
    # Copilot Agent Builder agents (createdIn "Copilot Studio Lite" in this tenant)
    # from every output file unless -IncludeAgentBuilder was passed.
    if (-not $IncludeAgentBuilder) {
        $excluded = $allAgents | Where-Object { $_.createdIn -ne 'Copilot Studio' }
        if ($excluded.Count -gt 0) {
            $allAgents = [System.Collections.Generic.List[object]]::new([object[]]($allAgents | Where-Object { $_.createdIn -eq 'Copilot Studio' }))
            # Only report the TENANT-WIDE exclusion count when -AllEnvironments was
            # passed - otherwise this message would be tenant-wide detail leaking out
            # even for a current-environment-only run, so scope it down to match.
            if ($AllEnvironments) {
                Write-Host "Excluded $($excluded.Count) Microsoft 365 Copilot Agent Builder agent(s) tenant-wide (pass -IncludeAgentBuilder to include them)." -ForegroundColor Yellow
            }
            else {
                $excludedCurrentEnv = ($excluded | Where-Object { $_.environmentName -eq $envWho.FriendlyName }).Count
                Write-Host "Excluded $excludedCurrentEnv Microsoft 365 Copilot Agent Builder agent(s) in '$($envWho.FriendlyName)' (pass -IncludeAgentBuilder to include them)." -ForegroundColor Yellow
            }
        }
    }
}
if ($allAgents.Count -gt 0) {
    # File names should reflect what's actually IN them: "full" only belongs in the
    # name when Agent Builder agents are actually included (-IncludeAgentBuilder), and
    # "all-environments" only when the export is actually tenant-wide
    # (-AllEnvironments) - so the two combined ("agents-full-inventory-all-environments")
    # only appears when both switches were used.
    $baseName = if ($IncludeAgentBuilder) { 'agents-full-inventory' } else { 'agents-inventory' }

    if ($AllEnvironments) {
        $allCsvPath = Join-Path $OutputDir "$baseName-all-environments.csv"
        $allAgents | ForEach-Object { ConvertTo-DisplayAgent $_ } | Export-Csv -Path $allCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Full tenant-wide inventory ($($allAgents.Count) agent(s), all environments) exported to: $allCsvPath" -ForegroundColor Green

        # Raw (unformatted, precise ISO-8601 datetimes/real booleans) companion export -
        # intended for other scripts (e.g. a future migration script) to consume, since
        # the CSV's locale-formatted datetime strings are lossy/ambiguous to parse back.
        $allJsonPath = Join-Path $OutputDir "$baseName-all-environments.json"
        $allAgents | ConvertTo-Json -Depth 5 | Out-File -FilePath $allJsonPath -Encoding UTF8
        Write-Host "Raw tenant-wide inventory JSON exported to: $allJsonPath" -ForegroundColor Green

        # -AllEnvironments means the caller cares about the tenant-wide picture, not just
        # the current environment - so show tenant-wide breakdowns on-screen too (these
        # were previously only ever computed against $currentEnvAgents, which was easy to
        # mistake for tenant-wide totals when this switch was used).
        $allCreatedInBreakdown = $allAgents | Group-Object -Property { if ($_.createdIn) { $_.createdIn } else { '(blank)' } } |
            Sort-Object Count -Descending | Select-Object Name, Count
        $allCreatedInBreakdownText = $allCreatedInBreakdown | Format-Table -AutoSize | Out-String
        $allCreatedInBreakdownText | Out-File -FilePath (Join-Path $OutputDir 'createdIn-breakdown-all-environments.txt') -Encoding UTF8
        Write-Host "`nAgent count by createdIn (authoring tool) - ALL environments ($($allAgents.Count) agent(s) total):" -ForegroundColor Cyan
        Write-Host $allCreatedInBreakdownText

        $envBreakdown = $allAgents | Group-Object -Property { if ($_.environmentName) { $_.environmentName } else { '(blank)' } } |
            Sort-Object Count -Descending | Select-Object Name, Count
        $envBreakdownText = $envBreakdown | Format-Table -AutoSize | Out-String
        $envBreakdownText | Out-File -FilePath (Join-Path $OutputDir 'agent-count-by-environment.txt') -Encoding UTF8
        Write-Host "Agent count by environment - ALL environments:" -ForegroundColor Cyan
        Write-Host $envBreakdownText

        # The first-party/managed check further below only queries Dataverse for agents
        # in the CURRENT environment (it needs a Dataverse token scoped to that
        # environment's own instance URL) - so a tenant-wide count here would silently
        # under-report agents in other environments as "not first-party" when really they
        # just weren't checked. Say so explicitly instead of implying a full tenant scan.
        $allFirstPartyAgents = $allAgents | Where-Object { $_.isFirstPartyManaged -eq $true }
        if ($allFirstPartyAgents.Count -gt 0) {
            Write-Host "First-party Microsoft-managed agent(s) found tenant-wide (NOTE: only agents in the current environment '$($envWho.FriendlyName)' were actually checked - agents in other environments show a blank isFirstPartyManaged/canMigrate rather than a confirmed 'False'):" -ForegroundColor Yellow
            $allFirstPartyAgents | ForEach-Object {
                Write-Host "  - $($_.agentName) [$($_.environmentName)] (belongs to managed solution '$($_.firstPartySolutionName)')" -ForegroundColor Yellow
            }
        }
    }

    # Narrow to the current environment, matched by the friendly name pac reported.
    # This whole section - files, breakdown, and first-party summary - is skipped
    # entirely when -AllEnvironments was passed: that switch means "I want the
    # tenant-wide picture", not "tenant-wide PLUS a redundant single-environment copy".
    if (-not $AllEnvironments) {
        $currentEnvAgents = $allAgents | Where-Object { $_.environmentName -eq $envWho.FriendlyName }
        if ($currentEnvAgents.Count -eq 0) {
            Write-Warning "Could not match any agents to environment name '$($envWho.FriendlyName)'. Showing the tenant-wide list instead - check the 'environmentName'/'environmentId' columns to filter manually (or pass -AllEnvironments to export the full tenant-wide CSV instead)."
            $currentEnvAgents = $allAgents
        }

        $envSlug = ($envWho.FriendlyName -replace '[^A-Za-z0-9]+', '-').Trim('-')
        $envCsvPath = Join-Path $OutputDir "$baseName-$envSlug.csv"
        $currentEnvAgents | ForEach-Object { ConvertTo-DisplayAgent $_ } | Export-Csv -Path $envCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Inventory for '$($envWho.FriendlyName)' ($($currentEnvAgents.Count) agent(s)) exported to: $envCsvPath" -ForegroundColor Green

        # Raw JSON companion for the current environment too - this is the file the planned
        # migration script will consume (precise createdByGUID/ownerId/timestamps, real
        # booleans) rather than parsing the human-formatted CSV.
        $envJsonPath = Join-Path $OutputDir "$baseName-$envSlug.json"
        $currentEnvAgents | ConvertTo-Json -Depth 5 | Out-File -FilePath $envJsonPath -Encoding UTF8
        Write-Host "Raw inventory JSON for '$($envWho.FriendlyName)' exported to: $envJsonPath" -ForegroundColor Green

        $breakdown = $currentEnvAgents | Group-Object -Property { if ($_.createdIn) { $_.createdIn } else { '(blank)' } } |
            Sort-Object Count -Descending | Select-Object Name, Count
        $breakdownText = $breakdown | Format-Table -AutoSize | Out-String
        $breakdownText | Out-File -FilePath (Join-Path $OutputDir "createdIn-breakdown-$envSlug.txt") -Encoding UTF8
        Write-Host "`nAgent count by createdIn (authoring tool) for '$($envWho.FriendlyName)' ($($currentEnvAgents.Count) agent(s)):" -ForegroundColor Cyan
        Write-Host $breakdownText

        $firstPartyAgents = $currentEnvAgents | Where-Object { $_.isFirstPartyManaged -eq $true }
        if ($firstPartyAgents.Count -gt 0) {
            Write-Host "First-party Microsoft-managed agent(s) in '$($envWho.FriendlyName)' (auto-skipped by Migrate-CopilotStudioAgents.ps1):" -ForegroundColor Yellow
            $firstPartyAgents | ForEach-Object {
                Write-Host "  - $($_.agentName) (belongs to managed solution '$($_.firstPartySolutionName)')" -ForegroundColor Yellow
            }
        }
    }
}
Write-Host "`nAll output saved under: $OutputDir" -ForegroundColor Green
