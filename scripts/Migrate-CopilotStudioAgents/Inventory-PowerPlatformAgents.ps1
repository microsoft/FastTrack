<#
.SYNOPSIS
    Inventories classic Copilot Studio agents in the default Power Platform
    environment (Microsoft 365 Copilot Agent Builder agents are excluded by
    default - see -IncludeAgentBuilder - and only the current/default
    environment is reported on by default - see -AllEnvironments).

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
# Shared MSAL sign-in fallback + batched first-party/managed-agent detection - kept in
# one place so this script and Migrate-CopilotStudioAgents.ps1 stay in sync.
. (Join-Path $PSScriptRoot 'Common-AgentHelpers.ps1')

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

# Resolves Entra user IDs through Microsoft Graph's batch endpoint. Failed 429/5xx
# subrequests are retried individually; permanent failures remain explicit so the
# migration script can avoid routing an agent using fallback data after a transient
# owner lookup failure.
function Resolve-GraphUsersById {
    param(
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$UserIds,
        [int]$MaxAttempts = 4
    )

    $users = @{}
    $statuses = @{}
    if (-not $UserIds -or $UserIds.Count -eq 0) {
        return [PSCustomObject]@{ Users = $users; Statuses = $statuses }
    }

    for ($i = 0; $i -lt $UserIds.Count; $i += 20) {
        $chunkEnd = [Math]::Min($i + 19, $UserIds.Count - 1)
        $pendingIds = @($UserIds[$i..$chunkEnd])

        for ($attempt = 1; $attempt -le $MaxAttempts -and $pendingIds.Count -gt 0; $attempt++) {
            $requestIds = @($pendingIds)
            $requests = for ($j = 0; $j -lt $requestIds.Count; $j++) {
                @{ id = "$j"; method = 'GET'; url = "/users/$($requestIds[$j])?`$select=displayName,mail,userPrincipalName,department" }
            }
            $batchBody = @{ requests = @($requests) } | ConvertTo-Json -Depth 5

            try {
                $batchResp = Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/$batch' -Headers $Headers -Method Post -Body $batchBody
            }
            catch {
                if ($attempt -lt $MaxAttempts) {
                    Start-Sleep -Seconds ([Math]::Min([Math]::Pow(2, $attempt), 30))
                    continue
                }
                foreach ($id in $requestIds) { $statuses[$id] = 'Failed' }
                Write-Warning "Microsoft Graph batch lookup failed after $MaxAttempts attempt(s): $($_.Exception.Message)"
                break
            }

            $responsesById = @{}
            foreach ($response in @($batchResp.responses)) {
                $responsesById[[string]$response.id] = $response
            }

            $retryIds = [System.Collections.Generic.List[string]]::new()
            $retryAfterSeconds = 0
            for ($j = 0; $j -lt $requestIds.Count; $j++) {
                $userId = $requestIds[$j]
                $response = $responsesById["$j"]
                if (-not $response) {
                    if ($attempt -lt $MaxAttempts) { $retryIds.Add($userId) }
                    else { $statuses[$userId] = 'Failed' }
                    continue
                }

                $statusCode = [int]$response.status
                if ($statusCode -eq 200) {
                    $users[$userId] = [PSCustomObject]@{
                        DisplayName = $response.body.displayName
                        Email       = if ($response.body.mail) { $response.body.mail } else { $response.body.userPrincipalName }
                        Department  = $response.body.department
                    }
                    $statuses[$userId] = 'Resolved'
                    continue
                }
                if ($statusCode -eq 404) {
                    $statuses[$userId] = 'NotFound'
                    continue
                }

                if (($statusCode -eq 429 -or $statusCode -ge 500) -and $attempt -lt $MaxAttempts) {
                    $retryIds.Add($userId)
                    $retryAfter = 0
                    if ($response.headers -and [int]::TryParse([string]$response.headers.'Retry-After', [ref]$retryAfter)) {
                        $retryAfterSeconds = [Math]::Max($retryAfterSeconds, $retryAfter)
                    }
                    continue
                }

                $statuses[$userId] = 'Failed'
                Write-Warning "Microsoft Graph could not resolve user ID '$userId' (HTTP $statusCode)."
            }

            $pendingIds = @($retryIds)
            if ($pendingIds.Count -gt 0) {
                $delay = if ($retryAfterSeconds -gt 0) { $retryAfterSeconds } else { [Math]::Min([Math]::Pow(2, $attempt), 30) }
                Start-Sleep -Seconds $delay
            }
        }
    }

    return [PSCustomObject]@{ Users = $users; Statuses = $statuses }
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

$script:inventoryDataverseAuthContext = $null
function Get-InventoryDataverseHeaders {
    param([switch]$ForceRefresh)

    $needsRefresh = $ForceRefresh -or -not $script:inventoryDataverseAuthContext
    if (-not $needsRefresh) {
        $needsRefresh = -not $script:inventoryDataverseAuthContext.ExpiresOn -or
            $script:inventoryDataverseAuthContext.ExpiresOn -le [DateTimeOffset]::UtcNow.AddMinutes(5)
    }
    if ($needsRefresh) {
        $tokenResult = Get-MsalTokenResultWithFallback -ClientApp $clientApp -Scope "$instanceUrl/.default" `
            -UseInteractiveBrowser:$UseInteractiveBrowser -ForceRefresh:$ForceRefresh -Label 'Dataverse'
        $script:inventoryDataverseAuthContext = [PSCustomObject]@{
            Headers = @{
                Authorization      = 'Bear' + 'er ' + $tokenResult.AccessToken
                Accept             = 'application/json'
                'OData-MaxVersion' = '4.0'
                'OData-Version'    = '4.0'
            }
            ExpiresOn = $tokenResult.ExpiresOn
        }
    }
    return $script:inventoryDataverseAuthContext.Headers
}

function Invoke-InventoryDataverseRequest {
    param([Parameter(Mandatory)][string]$Uri)

    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        $headers = Get-InventoryDataverseHeaders -ForceRefresh:($attempt -gt 0)
        try {
            return Invoke-RestMethod -Uri $Uri -Headers $headers -Method Get -ErrorAction Stop
        }
        catch {
            $statusCode = if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                [int]$_.Exception.Response.StatusCode
            }
            else {
                $null
            }
            if ($statusCode -eq 401 -and $attempt -eq 0) { continue }
            throw
        }
    }
}

Write-Host "Signing in for Power Platform inventory API access..." -ForegroundColor Cyan
$token = Get-MsalAccessTokenWithFallback -ClientApp $clientApp -Scope "$ppApiBase/.default" -UseInteractiveBrowser:$UseInteractiveBrowser -Label 'the Power Platform inventory API'

$headers = @{
    Authorization  = "Bearer $token"
    'Content-Type' = 'application/json'
}

# Query every microsoft.copilotstudio/agents resource in the tenant, left-joined to
# environment display names. The agent resource's environmentId remains the
# authoritative key when filtering to the current environment because display names
# are not unique.
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

$currentEnvironmentId = ConvertTo-NormalizedEnvironmentId $envWho.EnvironmentId
foreach ($agent in $allAgents) {
    $agent.environmentId = ConvertTo-NormalizedEnvironmentId ([string]$agent.environmentId)
}

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
    $creatorIds = @(
        $allAgents | ForEach-Object { $_.createdByGUID; $_.ownerId } |
            Where-Object { $_ -and $_ -ne '00000000-0000-0000-0000-000000000000' } |
            Select-Object -Unique
    )
    $creatorInfo = @{}
    $directoryLookupStatus = @{}
    if ($creatorIds.Count -gt 0) {
        $graphToken = Get-MsalAccessTokenWithFallback -ClientApp $clientApp -Scope 'https://graph.microsoft.com/User.Read.All' -UseInteractiveBrowser:$UseInteractiveBrowser -Label 'Microsoft Graph'
        $graphHeaders = @{ Authorization = "Bearer $graphToken"; 'Content-Type' = 'application/json' }

        $directoryResult = Resolve-GraphUsersById -Headers $graphHeaders -UserIds $creatorIds
        $creatorInfo = $directoryResult.Users
        $directoryLookupStatus = $directoryResult.Statuses
    }

    foreach ($agent in $allAgents) {
        $isSystemCreated = $agent.createdByGUID -eq '00000000-0000-0000-0000-000000000000'
        $info = if ($agent.createdByGUID -and $creatorInfo.ContainsKey($agent.createdByGUID)) { $creatorInfo[$agent.createdByGUID] } else { $null }
        $ownerInfo = if ($agent.ownerId -and $creatorInfo.ContainsKey($agent.ownerId)) { $creatorInfo[$agent.ownerId] } else { $null }
        # No ownerId (or the all-zero system placeholder) means no real owner is
        # assigned - flag it as orphaned rather than treating a non-user GUID as an
        # unresolved directory lookup.
        $isOrphaned = [string]::IsNullOrWhiteSpace($agent.ownerId) -or
            $agent.ownerId -eq '00000000-0000-0000-0000-000000000000'
        # One Add-Member call with -NotePropertyMembers (vs. separate calls) does a
        # single reflection/property-attach pass per object instead of several.
        $agent | Add-Member -NotePropertyMembers @{
            # The all-zero GUID means the agent was created by the system (not a real
            # user), so Microsoft Graph would never resolve it - label it explicitly.
            createdByName           = if ($isSystemCreated) { 'SYSTEM' } elseif ($info) { $info.DisplayName } else { '' }
            createdByEmail          = if ($info) { $info.Email } else { '' }
            createdByUserDepartment = if ($info) { $info.Department } else { '' }
            createdByDirectoryLookupStatus = if ($isSystemCreated) {
                'System'
            }
            elseif ($agent.createdByGUID -and $directoryLookupStatus.ContainsKey($agent.createdByGUID)) {
                $directoryLookupStatus[$agent.createdByGUID]
            }
            else {
                'NotRequested'
            }
            ownerName               = if ($isOrphaned) { 'ORPHANED - no owner assigned' } elseif ($ownerInfo) { $ownerInfo.DisplayName } else { '' }
            ownerEmail              = if ($ownerInfo) { $ownerInfo.Email } else { '' }
            ownerUserDepartment     = if ($ownerInfo) { $ownerInfo.Department } else { '' }
            ownerDirectoryLookupStatus = if ($isOrphaned) {
                'NotRequested'
            }
            elseif ($directoryLookupStatus.ContainsKey($agent.ownerId)) {
                $directoryLookupStatus[$agent.ownerId]
            }
            else {
                'NotRequested'
            }
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
    $currentEnvClassicAgentIds = @(
        $allAgents |
            Where-Object { $_.environmentId -eq $currentEnvironmentId -and $_.createdIn -eq 'Copilot Studio' } |
            ForEach-Object { $_.agentId }
    )
    $lastUsedByAgent = @{}
    $firstPartyByAgent = @{}
    if ($currentEnvClassicAgentIds.Count -gt 0) {
        Write-Host "`nResolving last-used dates for classic Copilot Studio agents via Dataverse conversation transcripts..." -ForegroundColor Cyan
        [void](Get-InventoryDataverseHeaders)
        # Two bounded top-1 queries per agent avoid downloading transcript history and
        # avoid Dataverse's 50,000-input-row aggregate limit. The second query preserves
        # the original per-row fallback to createdon when conversationstarttime is null.
        $lastUsedFailures = 0
        foreach ($agentId in $currentEnvClassicAgentIds) {
            $parsedId = [guid]::Empty
            if (-not [guid]::TryParse($agentId, [ref]$parsedId)) {
                Write-Warning "Skipping last-used lookup for invalid agent ID '$agentId'."
                $lastUsedFailures++
                continue
            }

            try {
                $startedFilter = "_bot_conversationtranscriptid_value eq $parsedId and conversationstarttime ne null"
                $startedUri = "$instanceUrl/api/data/v9.2/conversationtranscripts?`$filter=$([System.Uri]::EscapeDataString($startedFilter))&`$select=conversationstarttime&`$orderby=conversationstarttime desc&`$top=1"
                $startedResp = Invoke-InventoryDataverseRequest -Uri $startedUri

                $fallbackFilter = "_bot_conversationtranscriptid_value eq $parsedId and conversationstarttime eq null"
                $fallbackUri = "$instanceUrl/api/data/v9.2/conversationtranscripts?`$filter=$([System.Uri]::EscapeDataString($fallbackFilter))&`$select=createdon&`$orderby=createdon desc&`$top=1"
                $fallbackResp = Invoke-InventoryDataverseRequest -Uri $fallbackUri

                $timestamps = @()
                if ($startedResp.value.Count -gt 0 -and $startedResp.value[0].conversationstarttime) {
                    $timestamps += [datetime]$startedResp.value[0].conversationstarttime
                }
                if ($fallbackResp.value.Count -gt 0 -and $fallbackResp.value[0].createdon) {
                    $timestamps += [datetime]$fallbackResp.value[0].createdon
                }
                if ($timestamps.Count -gt 0) {
                    $lastUsedByAgent[$agentId] = $timestamps | Sort-Object -Descending | Select-Object -First 1
                }
            }
            catch {
                $lastUsedFailures++
                Write-Warning "Could not resolve last-used date for agent '$agentId': $($_.Exception.Message)"
            }
        }
        Write-Host "Resolved last-used date for $($lastUsedByAgent.Count) of $($currentEnvClassicAgentIds.Count) classic Copilot Studio agent(s) in the current environment." -ForegroundColor Green
        if ($lastUsedFailures -gt 0) { Write-Warning "Last-used lookup failed for $lastUsedFailures agent(s); their lastUsedAt value is blank." }

        # Flag first-party Microsoft-managed agents (e.g. "Finance in Microsoft 365
        # Copilot") so it's obvious from the inventory alone which agents
        # Migrate-CopilotStudioAgents.ps1 will pre-flight-skip - reuses the same
        # Dataverse token/headers acquired above for the conversation-transcript lookup.
        # Get-MicrosoftManagedAgentIds does this in a small, fixed number of Dataverse
        # calls (proportional to the number of Microsoft-managed solutions present) -
        # NOT one call per candidate agent.
        Write-Host "`nChecking for first-party Microsoft-managed agents (auto-skipped by Migrate-CopilotStudioAgents.ps1) via Dataverse solution components..." -ForegroundColor Cyan
        try {
            $managedAgentMap = Get-MicrosoftManagedAgentIds -InstanceUrl $instanceUrl -AgentIds $currentEnvClassicAgentIds `
                -RequestInvoker { param($uri) Invoke-InventoryDataverseRequest -Uri $uri }
            foreach ($agentId in $currentEnvClassicAgentIds) {
                $isManaged = $managedAgentMap.ContainsKey($agentId)
                $firstPartyByAgent[$agentId] = [PSCustomObject]@{
                    IsManaged          = $isManaged
                    SolutionUniqueName = if ($isManaged) { $managedAgentMap[$agentId] } else { $null }
                }
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
        'createdAt', 'createdByGUID', 'createdByDirectoryLookupStatus',
        'createdByName', 'createdByEmail', 'createdByUserDepartment',
        'ownerId', 'ownerDirectoryLookupStatus', 'ownerName', 'ownerEmail', 'ownerUserDepartment', 'isOrphaned',
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
                $excludedCurrentEnv = ($excluded | Where-Object { $_.environmentId -eq $currentEnvironmentId }).Count
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

    # Narrow to the current environment by its stable environment ID. Display names are
    # not unique and must never be used as routing identifiers.
    # This whole section - files, breakdown, and first-party summary - is skipped
    # entirely when -AllEnvironments was passed: that switch means "I want the
    # tenant-wide picture", not "tenant-wide PLUS a redundant single-environment copy".
    if (-not $AllEnvironments) {
        $currentEnvAgents = @($allAgents | Where-Object { $_.environmentId -eq $currentEnvironmentId })
        if ($currentEnvAgents.Count -eq 0) {
            throw "Could not match any inventory agents to current environment ID '$currentEnvironmentId' ('$($envWho.FriendlyName)'). No current-environment file was written; use -AllEnvironments only if you intentionally want tenant-wide output."
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
