<#
.SYNOPSIS
    Migrates classic Copilot Studio agents from the current (default) Power
    Platform environment to department-specific target environments, using
    the raw JSON output of Inventory-PowerPlatformAgents.ps1 as its input.

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

    1. Loads the inventory JSON produced by Inventory-PowerPlatformAgents.ps1 (NOT the
       CSV - the JSON preserves precise datetimes/booleans that the CSV's
       locale-formatted values don't).
    2. Loads a department -> target-environment mapping file (see
       department-environment-mapping.example.json for the shape) and resolves each
       target by stable environment ID. Legacy name-only entries are accepted only when
       the display name uniquely identifies one environment.
    3. For each agent, resolves its owning department (the owner's, falling back to the
       creator's if orphaned), looks up the mapped target environment, and builds a
       migration plan - skipping agents with unresolved directory lookups, no
       resolvable department, no mapping entry, a same-as-source target, or
       first-party/Microsoft-managed status.
    4. Prints the plan and writes migration-plan.csv before doing anything else, even
       under -WhatIf, so you can review it first.
    5. For each planned agent, since there's no direct "move" API: creates a dedicated
       unmanaged solution in the source environment, adds the agent (with its
       subcomponents), exports it, and imports it into the target environment. By
       default each agent gets its own solution so failures stay isolated; pass
       -BulkByDepartment to bundle every agent in a department into one
       solution/export/import instead (fewer imports, but one shared failure affects
       the whole department). The source agent is left untouched - this is a copy, not
       a move. The dedicated source-environment solution is left in place afterward
       unless -CleanupSourceSolution is passed, in which case it's deleted once its
       export/import has succeeded.
    6. Dataverse solution import doesn't preserve the bot's owner or record-level
       sharing, so after each successful import this script reassigns ownership
       (matched uniquely by email) and re-grants the same shares (users by email,
       Entra-backed teams by group ID, other teams by name/business unit) in the target
       environment, skipping missing or ambiguous matches with a logged reason.
    7. Supports -WhatIf for a full dry run; without it, each migration still prompts via
       ShouldProcess unless -Confirm:$false is passed.
    8. Writes migration-results.csv and reminds you that connection references and
       environment variables in the imported solution still need manual
       reconfiguration - that part isn't automated (ownership/sharing are).

.NOTES
    Requires pac CLI and the MSAL.PS module (same prerequisites as
    Inventory-PowerPlatformAgents.ps1) - checked automatically on startup, with
    an offer to install whichever is missing for you. Uses the same auth
    profile name by default so it can reuse an existing cached sign-in.

    You must be authenticated to (and this script must be run against) the
    SOURCE environment the inventory JSON was captured from - agents whose
    environmentId in the JSON doesn't match the currently active environment
    are skipped with a warning.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$InventoryJsonPath,

    [Parameter(Mandatory)]
    [string]$MappingPath,

    [string]$ProfileName = 'PPAgentInventory',
    [string]$OutputDir   = ".\PPAgentMigration-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

    # Default: one dedicated solution per agent (create/export/import per agent), so a
    # failure for one agent never affects any other. When set, all agents mapped to the
    # same department are bundled into a SINGLE solution/export/import instead - fewer
    # solutions overall, but if that one import fails, every agent in the department
    # fails together (no per-agent isolation). Owner reassignment and share replication
    # still happen individually per agent either way.
    [switch]$BulkByDepartment,

    # See Inventory-PowerPlatformAgents.ps1 -UseInteractiveBrowser for why device code
    # is the default and this switch exists as an opt-in alternative.
    [switch]$UseInteractiveBrowser,

    # By default the dedicated PPMigration_* solution this script creates in the SOURCE
    # environment is left behind after a successful migration (along with the exported
    # .zip in $OutputDir) - kept around in case you need to inspect or re-export it. Pass
    # this switch to delete that solution from the source environment once its export +
    # import into the target environment has succeeded. A failed import always leaves
    # its source solution in place so you can investigate; post-import remediation
    # warnings do not prevent cleanup because the import itself already completed.
    # Best-effort: a failed delete is logged as a warning, not a script failure.
    [switch]$CleanupSourceSolution
)

$ErrorActionPreference = 'Stop'

# --- Pre-flight: confirm required tooling is installed before doing any real work,
#     offering to install anything missing rather than failing deep into the script. ---
. (Join-Path $PSScriptRoot 'Confirm-ScriptRequirements.ps1')
Assert-ScriptRequirements -RequirePac -RequireMsalPs
# Shared MSAL sign-in fallback + batched first-party/managed-agent detection - kept in
# one place so this script and Inventory-PowerPlatformAgents.ps1 stay in sync.
. (Join-Path $PSScriptRoot 'Common-AgentHelpers.ps1')

# Strip stray leading/trailing quote characters some users end up with when pasting a
# quoted path (e.g. Explorer's "Copy as path") into the interactive parameter prompt -
# PowerShell's prompt-for-mandatory-parameter input is taken literally and does NOT strip
# surrounding quotes the way normal command-line argument parsing does, so a value typed
# as "C:\foo\bar.json" (quotes included) would otherwise be used as-is and never match a
# real file on disk.
$InventoryJsonPath = $InventoryJsonPath.Trim().Trim('"').Trim("'")
$MappingPath = $MappingPath.Trim().Trim('"').Trim("'")

if (-not (Test-Path $InventoryJsonPath)) {
    throw "Inventory JSON not found: $InventoryJsonPath (run Inventory-PowerPlatformAgents.ps1 first, then pass its agents-inventory-<env>.json - or agents-full-inventory-<env>.json if run with -IncludeAgentBuilder - here)."
}
if (-not (Test-Path $MappingPath)) {
    throw "Department -> environment mapping file not found: $MappingPath (see department-environment-mapping.example.json for the expected shape)."
}

# -WhatIf:$false - the output directory and the plan/results reports below are just
# informational; they should always be written, even during a -WhatIf dry run of the
# actual solution create/export/import steps further down.
New-Item -ItemType Directory -Path $OutputDir -Force -WhatIf:$false | Out-Null

# --- Load inputs ---
Write-Host "Loading agent inventory from: $InventoryJsonPath..." -ForegroundColor Cyan
$agentsRaw = Get-Content -Path $InventoryJsonPath -Raw | ConvertFrom-Json
$agents = @($agentsRaw)
if ($agents.Count -eq 0) { throw "Inventory JSON at '$InventoryJsonPath' contained no agents." }
Write-Host "Loaded $($agents.Count) agent(s) from inventory." -ForegroundColor Green

$nonClassic = $agents | Where-Object { $_.createdIn -ne 'Copilot Studio' }
if ($nonClassic.Count -gt 0) {
    Write-Warning "Ignoring $($nonClassic.Count) non-'Copilot Studio' agent(s) found in the inventory JSON (this migration script only handles classic Copilot Studio agents)."
    $agents = @($agents | Where-Object { $_.createdIn -eq 'Copilot Studio' })
}

Write-Host "Loading department -> environment mapping from: $MappingPath..." -ForegroundColor Cyan
$mappingRaw = Get-Content -Path $MappingPath -Raw | ConvertFrom-Json
$mappingRaw = @($mappingRaw)
$validMappingEntries = @(
    $mappingRaw | Where-Object {
        $_.department -and ($_.environmentId -or $_.environmentName)
    }
)
if ($validMappingEntries.Count -eq 0) {
    throw "No usable entries found in the mapping file '$MappingPath' - expected an array of { department, environmentId, environmentName } objects."
}
Write-Host "Loaded $($validMappingEntries.Count) department -> environment mapping entr$(if ($validMappingEntries.Count -eq 1) { 'y' } else { 'ies' })." -ForegroundColor Green

# --- Ensure we're authenticated, and confirm the current (source) environment ---
$authList = pac auth list 2>&1 | Out-String
if ($authList -match [regex]::Escape($ProfileName)) {
    Write-Host "Reusing existing auth profile '$ProfileName'..." -ForegroundColor Cyan
    pac auth select --name $ProfileName | Out-Null
}
else {
    Write-Host "Creating auth profile '$ProfileName' (connects to your tenant's default environment)..." -ForegroundColor Cyan
    pac auth create --name $ProfileName
}

$envWhoJsonRaw = pac env who --json 2>&1 | Out-String
$envWho = $null
try { $envWho = ($envWhoJsonRaw -split "`r?`n" | Where-Object { $_.TrimStart().StartsWith('{') } | Select-Object -First 1) | ConvertFrom-Json }
catch { throw "Could not parse 'pac env who --json' output:`n$envWhoJsonRaw" }

$sourceEnvUrl  = $envWho.OrgUrl.TrimEnd('/')
$sourceEnvName = $envWho.FriendlyName
$sourceEnvId   = ConvertTo-NormalizedEnvironmentId ([string]$envWho.EnvironmentId)
Write-Host "`nSource environment: $sourceEnvName [$sourceEnvId] ($sourceEnvUrl)`n" -ForegroundColor Cyan

# --- Resolve every target environment by stable ID before building the plan. Legacy
#     name-only mappings are supported only when the name is unique across the tenant. ---
Write-Host "Resolving every target environment in the mapping (via 'pac env list')..." -ForegroundColor Cyan
$envList = (pac env list --json 2>&1 | Out-String) | ConvertFrom-Json
$deptMap = @{}
foreach ($mappingEntry in $validMappingEntries) {
    $department = $mappingEntry.department.Trim()
    $departmentKey = $department.ToLowerInvariant()
    if ($deptMap.ContainsKey($departmentKey)) {
        throw "The mapping file contains more than one entry for department '$department'. Keep exactly one target environment per department."
    }

    $requestedEnvironmentId = ConvertTo-NormalizedEnvironmentId ([string]$mappingEntry.environmentId)
    $targetMatches = if ($requestedEnvironmentId) {
        @(
            $envList | Where-Object {
                (ConvertTo-NormalizedEnvironmentId ([string]$_.EnvironmentIdentifier.Id)) -eq $requestedEnvironmentId
            }
        )
    }
    else {
        @($envList | Where-Object { $_.FriendlyName -eq $mappingEntry.environmentName })
    }

    if ($targetMatches.Count -eq 0) {
        $identifier = if ($mappingEntry.environmentId) {
            "ID '$($mappingEntry.environmentId)'"
        }
        else {
            "name '$($mappingEntry.environmentName)'"
        }
        throw "Target environment $identifier for department '$department' was not found via 'pac env list'. Create it or correct the mapping, then re-run."
    }
    if ($targetMatches.Count -gt 1) {
        throw "Target environment name '$($mappingEntry.environmentName)' for department '$department' is ambiguous ($($targetMatches.Count) environments have that display name). Add environmentId to this mapping entry."
    }

    $targetRecord = $targetMatches[0]
    if ($mappingEntry.environmentId -and $mappingEntry.environmentName -and $mappingEntry.environmentName -ne $targetRecord.FriendlyName) {
        Write-Warning "Department '$department' maps to environment ID '$($mappingEntry.environmentId)', whose current display name is '$($targetRecord.FriendlyName)' rather than '$($mappingEntry.environmentName)'. The stable ID is authoritative."
    }
    $deptMap[$departmentKey] = [PSCustomObject]@{
        Name = $targetRecord.FriendlyName
        Id   = ConvertTo-NormalizedEnvironmentId ([string]$targetRecord.EnvironmentIdentifier.Id)
        Url  = $targetRecord.EnvironmentUrl.TrimEnd('/')
    }
}
Write-Host "Resolved $($deptMap.Count) department mapping(s) to $(@($deptMap.Values.Id | Select-Object -Unique).Count) distinct target environment ID(s).`n" -ForegroundColor Green

$missingSourceIds = @($agents | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.environmentId) })
if ($missingSourceIds.Count -gt 0) {
    throw "$($missingSourceIds.Count) inventory agent(s) have no environmentId. Re-run Inventory-PowerPlatformAgents.ps1 with the updated script; display names are not safe routing identifiers."
}
foreach ($agent in $agents) {
    $agent.environmentId = ConvertTo-NormalizedEnvironmentId ([string]$agent.environmentId)
}
$missingLookupStatuses = @(
    $agents | Where-Object {
        $_.PSObject.Properties.Name -notcontains 'ownerDirectoryLookupStatus' -or
        $_.PSObject.Properties.Name -notcontains 'createdByDirectoryLookupStatus'
    }
)
if ($missingLookupStatuses.Count -gt 0) {
    throw "$($missingLookupStatuses.Count) inventory agent(s) have no directory lookup status fields. Re-run Inventory-PowerPlatformAgents.ps1 so transient Microsoft Graph failures cannot silently affect department routing."
}

$mismatched = @($agents | Where-Object { $_.environmentId -ne $sourceEnvId })
if ($mismatched.Count -gt 0) {
    Write-Warning "Skipping $($mismatched.Count) agent(s) belonging to an environment other than the currently authenticated source '$sourceEnvName' [$sourceEnvId]."
    $agents = @($agents | Where-Object { $_.environmentId -eq $sourceEnvId })
}
if ($agents.Count -eq 0) { throw "No agents from source environment '$sourceEnvName' [$sourceEnvId] remain to evaluate." }

# --- Acquire Dataverse access for the source environment early, so the migration plan
#     below can pre-flight-check agents' solution membership (see
#     Get-MicrosoftManagedAgentIds) before committing to a full export/import cycle. This
#     same MSAL client app and header cache are reused further down for the source
#     environment's publisher/component-type resolution and for each distinct TARGET
#     environment's owner-reassignment/share-replication calls, so nothing here is
#     authenticated to twice. ---
Write-Host "`nAcquiring Dataverse access for the source environment ($sourceEnvUrl)..." -ForegroundColor Cyan
Import-Module MSAL.PS -ErrorAction Stop
$clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
$clientApp = New-MsalClientApplication -ClientId $clientId -TenantId 'organizations'
Enable-MsalTokenCacheOnDisk -PublicClientApplication $clientApp | Out-Null

function Get-DataverseAuthContext {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [switch]$ForceRefresh
    )
    $tokenResult = Get-MsalTokenResultWithFallback -ClientApp $clientApp -Scope "$EnvUrl/.default" `
        -UseInteractiveBrowser:$UseInteractiveBrowser -ForceRefresh:$ForceRefresh -Label "Dataverse ($EnvUrl)"
    $token = $tokenResult.AccessToken
    $bearer = 'Bear' + 'er ' + $token
    $headers = @{
        Authorization      = $bearer
        Accept             = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        'Content-Type'     = 'application/json; charset=utf-8'
    }
    return [PSCustomObject]@{
        Headers   = $headers
        ExpiresOn = $tokenResult.ExpiresOn
    }
}

$dvHeadersCache = @{}
function Get-CachedDataverseHeaders {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [switch]$ForceRefresh
    )
    $key = $EnvUrl.TrimEnd('/')
    $needsRefresh = $ForceRefresh -or -not $dvHeadersCache.ContainsKey($key)
    if (-not $needsRefresh) {
        $expiresOn = $dvHeadersCache[$key].ExpiresOn
        $needsRefresh = -not $expiresOn -or $expiresOn -le [DateTimeOffset]::UtcNow.AddMinutes(5)
    }
    if ($needsRefresh) {
        Write-Host "  Authenticating to Dataverse environment: $key..." -ForegroundColor Cyan
        $dvHeadersCache[$key] = Get-DataverseAuthContext -EnvUrl $key -ForceRefresh:$ForceRefresh
    }
    return $dvHeadersCache[$key].Headers
}

function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [Parameter(Mandatory)][string]$Uri,
        [ValidateSet('Get', 'Post', 'Patch', 'Delete')][string]$Method = 'Get',
        $Body,
        [hashtable]$AdditionalHeaders
    )

    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        $headers = (Get-CachedDataverseHeaders -EnvUrl $EnvUrl -ForceRefresh:($attempt -gt 0)).Clone()
        if ($AdditionalHeaders) {
            foreach ($name in $AdditionalHeaders.Keys) { $headers[$name] = $AdditionalHeaders[$name] }
        }
        $request = @{
            Uri         = $Uri
            Headers     = $headers
            Method      = $Method
            ErrorAction = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('Body')) { $request.Body = $Body }

        try {
            return Invoke-RestMethod @request
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

function Get-DataverseCollection {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [Parameter(Mandatory)][string]$Uri
    )

    $items = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri
    do {
        $response = Invoke-DataverseRequest -EnvUrl $EnvUrl -Uri $nextUri
        if ($response.value) { $items.AddRange(@($response.value)) }
        $nextUri = $response.'@odata.nextLink'
    } while ($nextUri)
    return $items
}

function Get-DataverseSolutionByUniqueName {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [Parameter(Mandatory)][string]$UniqueName
    )

    $filter = "uniquename eq $(ConvertTo-ODataStringLiteral $UniqueName)"
    $uri = "$EnvUrl/api/data/v9.2/solutions?`$filter=$([System.Uri]::EscapeDataString($filter))&`$select=solutionid,uniquename,friendlyname&`$top=2"
    $solutions = @(Get-DataverseCollection -EnvUrl $EnvUrl -Uri $uri)
    if ($solutions.Count -gt 1) {
        throw "Dataverse returned multiple solutions with unique name '$UniqueName' in '$EnvUrl'."
    }
    if ($solutions.Count -eq 0) { return $null }
    return $solutions[0]
}

# Resolves the bot records belonging to the imported target solution. This avoids
# downloading and diffing the target's entire bots table before and after every import.
function Get-BotsInSolution {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [Parameter(Mandatory)][string]$SolutionUniqueName
    )

    $solution = Get-DataverseSolutionByUniqueName -EnvUrl $EnvUrl -UniqueName $SolutionUniqueName
    if (-not $solution) {
        throw "Imported solution '$SolutionUniqueName' could not be found in target environment '$EnvUrl'."
    }

    $componentUri = "$EnvUrl/api/data/v9.2/solutioncomponents?`$filter=_solutionid_value eq $($solution.solutionid)&`$select=objectid"
    $objectIds = @(
        Get-DataverseCollection -EnvUrl $EnvUrl -Uri $componentUri |
            ForEach-Object { [string]$_.objectid } |
            Where-Object { $_ } |
            Select-Object -Unique
    )

    $bots = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $objectIds.Count; $i += 25) {
        $chunkEnd = [Math]::Min($i + 24, $objectIds.Count - 1)
        $validIds = @(
            $objectIds[$i..$chunkEnd] | Where-Object {
                $parsedId = [guid]::Empty
                [guid]::TryParse($_, [ref]$parsedId)
            }
        )
        if ($validIds.Count -eq 0) { continue }
        $filter = '(' + (($validIds | ForEach-Object { "botid eq $_" }) -join ' or ') + ')'
        $botUri = "$EnvUrl/api/data/v9.2/bots?`$filter=$([System.Uri]::EscapeDataString($filter))&`$select=botid,name"
        $bots.AddRange(@(Get-DataverseCollection -EnvUrl $EnvUrl -Uri $botUri))
    }
    return $bots
}

function Find-DataverseTeamMatch {
    param(
        [Parameter(Mandatory)][string]$SourceEnvUrl,
        [Parameter(Mandatory)][string]$TargetEnvUrl,
        [Parameter(Mandatory)][string]$SourceTeamId,
        [string]$ExcludedSourceTeamName
    )

    $sourceTeamUri = "$SourceEnvUrl/api/data/v9.2/teams($SourceTeamId)?`$select=name,azureactivedirectoryobjectid,_businessunitid_value"
    $sourceTeam = Invoke-DataverseRequest -EnvUrl $SourceEnvUrl -Uri $sourceTeamUri
    $sourceTeamName = [string]$sourceTeam.name
    if ($ExcludedSourceTeamName -and $sourceTeamName -eq $ExcludedSourceTeamName) {
        return [PSCustomObject]@{ SourceName = $sourceTeamName; TargetId = $null; Reason = 'ExcludedAutomaticTeam' }
    }
    $entraGroupId = [string]$sourceTeam.azureactivedirectoryobjectid

    if (-not [string]::IsNullOrWhiteSpace($entraGroupId)) {
        $filter = "azureactivedirectoryobjectid eq $entraGroupId"
        $targetTeamUri = "$TargetEnvUrl/api/data/v9.2/teams?`$filter=$([System.Uri]::EscapeDataString($filter))&`$select=teamid,name&`$top=2"
        $matches = @(Get-DataverseCollection -EnvUrl $TargetEnvUrl -Uri $targetTeamUri)
        if ($matches.Count -eq 1) {
            return [PSCustomObject]@{ SourceName = $sourceTeamName; TargetId = $matches[0].teamid; Reason = '' }
        }
        $reason = if ($matches.Count -eq 0) {
            "no team backed by Entra group '$entraGroupId' was found in target"
        }
        else {
            "multiple target teams are backed by Entra group '$entraGroupId'"
        }
        return [PSCustomObject]@{ SourceName = $sourceTeamName; TargetId = $null; Reason = $reason }
    }

    $sourceBusinessUnitName = $null
    if ($sourceTeam.'_businessunitid_value') {
        $sourceBusinessUnit = Invoke-DataverseRequest -EnvUrl $SourceEnvUrl `
            -Uri "$SourceEnvUrl/api/data/v9.2/businessunits($($sourceTeam.'_businessunitid_value'))?`$select=name"
        $sourceBusinessUnitName = [string]$sourceBusinessUnit.name
    }

    $nameFilter = "name eq $(ConvertTo-ODataStringLiteral $sourceTeamName)"
    $targetTeamUri = "$TargetEnvUrl/api/data/v9.2/teams?`$filter=$([System.Uri]::EscapeDataString($nameFilter))&`$select=teamid,name,_businessunitid_value&`$expand=businessunitid(`$select=name)"
    $nameMatches = @(Get-DataverseCollection -EnvUrl $TargetEnvUrl -Uri $targetTeamUri)
    $matches = if ($sourceBusinessUnitName) {
        @($nameMatches | Where-Object { $_.businessunitid.name -eq $sourceBusinessUnitName })
    }
    else {
        $nameMatches
    }

    if ($matches.Count -eq 1) {
        return [PSCustomObject]@{ SourceName = $sourceTeamName; TargetId = $matches[0].teamid; Reason = '' }
    }
    $reason = if ($matches.Count -eq 0) {
        if ($sourceBusinessUnitName) {
            "no team named '$sourceTeamName' in business unit '$sourceBusinessUnitName' was found in target"
        }
        else {
            "no team named '$sourceTeamName' was found in target"
        }
    }
    else {
        "team name '$sourceTeamName' is ambiguous in target; $($matches.Count) matching teams were found"
    }
    return [PSCustomObject]@{ SourceName = $sourceTeamName; TargetId = $null; Reason = $reason }
}

[void](Get-CachedDataverseHeaders -EnvUrl $sourceEnvUrl)

# --- Build the migration plan ---
Write-Host "`nBuilding migration plan for $($agents.Count) agent(s)..." -ForegroundColor Cyan

# Pass 1: resolve department/mapping/target-environment status per agent - no Dataverse
# calls yet, so the (potentially expensive) managed-agent check below only ever runs
# against agents that would otherwise actually proceed.
$planDraft = foreach ($agent in $agents) {
    $dept = $null
    $ownerLookupStatus = if ($agent.PSObject.Properties.Name -contains 'ownerDirectoryLookupStatus') {
        [string]$agent.ownerDirectoryLookupStatus
    }
    else {
        'LegacyInventory'
    }
    $creatorLookupStatus = if ($agent.PSObject.Properties.Name -contains 'createdByDirectoryLookupStatus') {
        [string]$agent.createdByDirectoryLookupStatus
    }
    else {
        'LegacyInventory'
    }

    $status = 'Planned'
    if (-not $agent.isOrphaned -and $ownerLookupStatus -in @('Failed', 'NotRequested')) {
        $status = "Skipped - owner directory lookup status is '$ownerLookupStatus'; rerun inventory before routing this agent"
    }
    elseif (-not $agent.isOrphaned -and $agent.ownerUserDepartment) {
        $dept = $agent.ownerUserDepartment
    }
    elseif ($creatorLookupStatus -eq 'Failed') {
        $status = "Skipped - creator directory lookup failed and is needed as the department fallback; rerun inventory"
    }
    elseif ($agent.createdByUserDepartment) {
        $dept = $agent.createdByUserDepartment
    }

    # Same owner-first/creator-fallback rule as department, so the post-import owner
    # reassignment step (below) targets the same person the plan's department came from.
    $ownerEmail = $null
    if (-not $agent.isOrphaned -and $agent.ownerEmail) { $ownerEmail = $agent.ownerEmail }
    elseif ($agent.createdByEmail) { $ownerEmail = $agent.createdByEmail }

    $targetEnvName = $null
    $targetEnvId = $null
    $targetEnvUrl = $null
    if ($status -ne 'Planned') {
        # Preserve the explicit directory-lookup failure above.
    }
    elseif (-not $dept) {
        $status = 'Skipped - no owner/creator department found'
    }
    else {
        $key = $dept.Trim().ToLowerInvariant()
        if (-not $deptMap.ContainsKey($key)) {
            $status = "Skipped - no environment mapping for department '$dept'"
        }
        else {
            $targetEnvironment = $deptMap[$key]
            $targetEnvName = $targetEnvironment.Name
            $targetEnvId = $targetEnvironment.Id
            $targetEnvUrl = $targetEnvironment.Url
            if ($targetEnvId -eq $sourceEnvId) { $status = 'Skipped - target environment same as source' }
        }
    }

    [PSCustomObject]@{
        agentId               = $agent.agentId
        agentName             = $agent.agentName
        departmentUsed        = $dept
        ownerEmailUsed        = $ownerEmail
        sourceEnvironment     = $sourceEnvName
        targetEnvironmentName = $targetEnvName
        targetEnvironmentId   = $targetEnvId
        TargetEnvironmentUrl  = $targetEnvUrl
        status                = $status
    }
}

# Pass 2: one batched Dataverse lookup for every still-"Planned" agent's first-party/
# Microsoft-managed status, instead of a separate round-trip per agent - see
# Get-MicrosoftManagedAgentIds in Common-AgentHelpers.ps1.
$candidateAgentIds = @($planDraft | Where-Object { $_.status -eq 'Planned' } | ForEach-Object { $_.agentId })
$managedAgentMap = Get-MicrosoftManagedAgentIds -InstanceUrl $sourceEnvUrl -AgentIds $candidateAgentIds `
    -RequestInvoker { param($uri) Invoke-DataverseRequest -EnvUrl $sourceEnvUrl -Uri $uri }

$plan = foreach ($item in $planDraft) {
    if ($item.status -eq 'Planned' -and $managedAgentMap.ContainsKey($item.agentId)) {
        $item.status = "Skipped - first-party Microsoft-managed agent (belongs to managed solution '$($managedAgentMap[$item.agentId])') - no customizable content to migrate"
    }
    $item
}

Write-Host "Migration plan:" -ForegroundColor Cyan
$plan | Format-Table -AutoSize | Out-String | Write-Host
$planCsvPath = Join-Path $OutputDir 'migration-plan.csv'
$plan | Export-Csv -Path $planCsvPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
Write-Host "Plan exported to: $planCsvPath`n" -ForegroundColor Green

$toMigrate = @($plan | Where-Object { $_.status -eq 'Planned' })
if ($toMigrate.Count -eq 0) {
    Write-Host "No agents to migrate - nothing further to do." -ForegroundColor Yellow
    return
}

Write-Host "$($toMigrate.Count) agent(s) resolved and ready to migrate." -ForegroundColor Green

# Reuse the source environment's own Default-solution publisher for every new dedicated
# solution, rather than creating a new publisher - keeps this non-invasive. Dataverse
# authentication was already acquired above and is reused through the refresh-aware
# request wrapper.
Write-Host "Resolving the source environment's Default-solution publisher..." -ForegroundColor Cyan
$pubResp = Invoke-DataverseRequest -EnvUrl $sourceEnvUrl -Uri "$sourceEnvUrl/api/data/v9.2/solutions?`$filter=uniquename eq 'Default'&`$select=uniquename&`$expand=publisherid(`$select=publisherid)"
$publisherId = $pubResp.value[0].publisherid.publisherid
if (-not $publisherId) { throw "Could not resolve the source environment's Default solution publisher." }
Write-Host "Resolved publisher: $publisherId" -ForegroundColor Green

# The "Bot" solution-component type is a custom-table object type code, which Dataverse
# assigns per-org (NOT a fixed global constant) - Microsoft's published solution-component-
# type reference doesn't list a value for Bot either. Resolve it dynamically here by
# looking at an existing bot's own solutioncomponent row in the SOURCE org, rather than
# hardcoding a number that could be wrong if this script is ever pointed at a different
# source environment - the same logical component type can resolve to a different numeric
# code in different environments/tenants (e.g. 10163 in one org vs. 10212 in another).
Write-Host "Resolving the Bot solution-component type for this source environment..." -ForegroundColor Cyan
$sampleBotId = $toMigrate[0].agentId
$typeResp = Invoke-DataverseRequest -EnvUrl $sourceEnvUrl -Uri "$sourceEnvUrl/api/data/v9.2/solutioncomponents?`$filter=objectid eq $sampleBotId&`$select=componenttype&`$top=1"
if ($typeResp.value.Count -eq 0) { throw "Could not resolve the Bot solution-component type from '$sampleBotId' - is it a member of any solution in the source environment?" }
$BOT_COMPONENT_TYPE = $typeResp.value[0].componenttype
Write-Host "Resolved Bot solution-component type for this source environment: $BOT_COMPONENT_TYPE" -ForegroundColor Cyan

# Looks up a Dataverse systemuser by email (checking both domainname and
# internalemailaddress, since either can hold it depending on how the user was
# provisioned) and returns their systemuserid, or $null if no match is found. Shared by
# both the owner-reassignment and share-replication steps below, which otherwise
# duplicated this exact lookup.
function Find-DataverseUserIdByEmail {
    param(
        [Parameter(Mandatory)][string]$EnvUrl,
        [Parameter(Mandatory)][string]$Email
    )
    $emailLiteral = ConvertTo-ODataStringLiteral $Email
    $userFilter = "domainname eq $emailLiteral or internalemailaddress eq $emailLiteral"
    $userUri = "$EnvUrl/api/data/v9.2/systemusers?`$filter=$([System.Uri]::EscapeDataString($userFilter))&`$select=systemuserid&`$top=2"
    $userIds = @(
        Get-DataverseCollection -EnvUrl $EnvUrl -Uri $userUri |
            ForEach-Object { $_.systemuserid } |
            Select-Object -Unique
    )
    if ($userIds.Count -eq 0) { return $null }
    if ($userIds.Count -gt 1) {
        throw "Multiple Dataverse users matched email '$Email' in '$EnvUrl'; ownership/share replication was skipped rather than selecting one arbitrarily."
    }
    return $userIds[0]
}

# --- Post-import owner reassignment + share replication ---
# Dataverse solution import does NOT preserve the bot's record GUID, its owner, or its
# record-level sharing (confirmed live against this tenant): the imported bot becomes
# owned by whoever ran the import, and any explicit shares are simply gone. This function
# restores both, given the already-identified NEW bot record in the target environment.
function Copy-BotOwnerAndShares {
    param(
        [Parameter(Mandatory)][string]$SourceEnvUrl,
        [Parameter(Mandatory)][string]$TargetEnvUrl,
        [Parameter(Mandatory)][string]$SourceBotId,
        [Parameter(Mandatory)][string]$TargetBotId,
        [string]$OwnerEmail
    )

    $result = [PSCustomObject]@{
        ownerReassignmentStatus = 'Not attempted'
        shareReplicationStatus  = 'Completed'
        sharesGranted           = 0
        sharesSkipped           = 0
        shareDetails            = ''
    }
    $shareDetailsList = [System.Collections.Generic.List[string]]::new()

    # --- Owner reassignment: match the source owner/creator by email to a user in the
    #     target environment. Skip (rather than fail) if no matching user is found there. ---
    if ([string]::IsNullOrWhiteSpace($OwnerEmail)) {
        $result.ownerReassignmentStatus = 'Skipped - no owner/creator email on record'
    }
    else {
        try {
            $targetUserId = Find-DataverseUserIdByEmail -EnvUrl $TargetEnvUrl -Email $OwnerEmail
            if (-not $targetUserId) {
                $result.ownerReassignmentStatus = "Skipped - no user matching '$OwnerEmail' found in target environment"
            }
            else {
                $ownerBody = @{ 'ownerid@odata.bind' = "/systemusers($targetUserId)" } | ConvertTo-Json
                Invoke-DataverseRequest -EnvUrl $TargetEnvUrl -Uri "$TargetEnvUrl/api/data/v9.2/bots($TargetBotId)" -Method Patch -Body $ownerBody | Out-Null
                $result.ownerReassignmentStatus = "Reassigned to '$OwnerEmail'"
            }
        }
        catch {
            # Non-fatal: e.g. the matched target user has no security role/privilege on
            # bots in that environment yet. The core copy already succeeded - don't let
            # this best-effort step fail the whole migration, just report it clearly.
            $result.ownerReassignmentStatus = "Failed - could not reassign owner to '$OwnerEmail': $($_.Exception.Message)"
        }
    }

    # --- Share replication: read every principal the source agent was explicitly shared
    #     with, and re-grant the same access on the new bot in the target environment.
    #     Copilot Studio auto-creates a dedicated per-agent access team named
    #     "<botGuidNoDashes>_1" for every bot - that's an implementation detail, not a
    #     user-created share, and the new bot gets its own equivalent, so it's excluded. ---
    $autoTeamName = ($SourceBotId -replace '-', '') + '_1'
    $targetRefJson = "{`"@odata.id`":`"bots($SourceBotId)`"}"
    $encodedTargetRef = [System.Uri]::EscapeDataString($targetRefJson)
    try {
        $sharesResp = Invoke-DataverseRequest -EnvUrl $SourceEnvUrl -Uri "$SourceEnvUrl/api/data/v9.2/RetrieveSharedPrincipalsAndAccess(Target=@tp)?@tp=$encodedTargetRef"

        foreach ($pa in @($sharesResp.PrincipalAccesses)) {
            $principalType = $pa.Principal.'@odata.type' -replace '^#Microsoft\.Dynamics\.CRM\.', ''
            $principalId = $pa.Principal.ownerid
            $accessMask = $pa.AccessMask
            $targetPrincipalId = $null
            $principalOdataType = $null
            $principalKey = $null
            $label = $null

            try {
                if ($principalType -eq 'team') {
                    $teamMatch = Find-DataverseTeamMatch -SourceEnvUrl $SourceEnvUrl -TargetEnvUrl $TargetEnvUrl `
                        -SourceTeamId $principalId -ExcludedSourceTeamName $autoTeamName
                    if ($teamMatch.Reason -eq 'ExcludedAutomaticTeam') { continue }

                    $label = "team '$($teamMatch.SourceName)'"
                    if (-not $teamMatch.TargetId) {
                        $result.sharesSkipped++
                        $shareDetailsList.Add("Skipped $label - $($teamMatch.Reason)")
                        continue
                    }
                    $targetPrincipalId = $teamMatch.TargetId
                    $principalOdataType = 'Microsoft.Dynamics.CRM.team'
                    $principalKey = 'teamid'
                }
                elseif ($principalType -eq 'systemuser') {
                    $userResp2 = Invoke-DataverseRequest -EnvUrl $SourceEnvUrl -Uri "$SourceEnvUrl/api/data/v9.2/systemusers($principalId)?`$select=domainname,internalemailaddress,fullname"
                    $email = if ($userResp2.internalemailaddress) { $userResp2.internalemailaddress } else { $userResp2.domainname }
                    $label = "user '$email'"
                    if ([string]::IsNullOrWhiteSpace($email)) {
                        $result.sharesSkipped++
                        $shareDetailsList.Add("Skipped user '$($userResp2.fullname)' - no resolvable email")
                        continue
                    }
                    $targetPrincipalId = Find-DataverseUserIdByEmail -EnvUrl $TargetEnvUrl -Email $email
                    if (-not $targetPrincipalId) {
                        $result.sharesSkipped++
                        $shareDetailsList.Add("Skipped $label - no matching user found in target")
                        continue
                    }
                    $principalOdataType = 'Microsoft.Dynamics.CRM.systemuser'
                    $principalKey = 'systemuserid'
                }
                else {
                    $result.sharesSkipped++
                    $shareDetailsList.Add("Skipped unsupported shared principal type '$principalType' ($principalId)")
                    continue
                }

                $principalObj = @{ '@odata.type' = $principalOdataType }
                $principalObj[$principalKey] = $targetPrincipalId
                $grantBody = @{
                    Target          = @{ '@odata.type' = 'Microsoft.Dynamics.CRM.bot'; botid = $TargetBotId }
                    PrincipalAccess = @{
                        Principal  = $principalObj
                        AccessMask = $accessMask
                    }
                } | ConvertTo-Json -Depth 5
                Invoke-DataverseRequest -EnvUrl $TargetEnvUrl -Uri "$TargetEnvUrl/api/data/v9.2/GrantAccess" -Method Post -Body $grantBody | Out-Null
                $result.sharesGranted++
                $shareDetailsList.Add("Granted $label ($accessMask)")
            }
            catch {
                $result.sharesSkipped++
                $principalLabel = if ($label) { $label } else { "$principalType '$principalId'" }
                $shareDetailsList.Add("Failed to replicate share for $principalLabel`: $($_.Exception.Message)")
            }
        }
    }
    catch {
        # Non-fatal: e.g. the source agent has no shares at all, or the target environment
        # rejected a lookup call. The core copy already succeeded - report this clearly
        # rather than failing the whole migration over a best-effort remediation step.
        $result.shareReplicationStatus = 'Failed'
        $shareDetailsList.Add("Share replication could not be completed: $($_.Exception.Message)")
    }

    $result.shareDetails = $shareDetailsList -join '; '
    return $result
}

$results = [System.Collections.Generic.List[object]]::new()

# --- Group planned agents into migration batches: one agent per solution/export/import
#     by default, or all agents sharing a department bundled into a single
#     solution/export/import when -BulkByDepartment is used (see param block / .DESCRIPTION
#     for the failure-isolation tradeoff). Owner reassignment and share replication always
#     happen individually per agent, regardless of batching mode. ---
if ($BulkByDepartment) {
    $batches = @($toMigrate | Group-Object -Property departmentUsed | ForEach-Object {
        [PSCustomObject]@{ Key = $_.Name; Items = @($_.Group) }
    })
}
else {
    $batches = @($toMigrate | ForEach-Object { [PSCustomObject]@{ Key = $_.agentName; Items = @($_) } })
}
Write-Host "`nGrouped into $($batches.Count) migration batch(es); starting migration...`n" -ForegroundColor Cyan

foreach ($batch in $batches) {
    $batchItems = $batch.Items
    $targetEnvironmentName = $batchItems[0].targetEnvironmentName
    $targetEnvironmentUrl  = $batchItems[0].TargetEnvironmentUrl

    $safeName = if ($BulkByDepartment) { $batch.Key -replace '[^A-Za-z0-9]', '' } else { $batchItems[0].agentName -replace '[^A-Za-z0-9]', '' }
    if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = if ($BulkByDepartment) { 'Department' } else { 'Agent' } }
    # Dataverse requires solution uniquename to be under 50 characters. Fixed overhead here
    # is "PPMigration_" (12) + "_" + the 8-char hash suffix (21 chars total), so safeName
    # must be capped at 28 chars to keep the full uniquename at 49 chars or less. (A 40-char
    # cap here previously let long agent/department names produce a >50-char uniquename,
    # which Dataverse rejected outright with a 400 "UniqueName must contain less than 50
    # characters" error before anything else in the batch could run.)
    if ($safeName.Length -gt 28) { $safeName = $safeName.Substring(0, 28) }

    # Deterministic short hash derived from the sorted set of agent IDs in this batch, so
    # re-running against the exact same agent(s) fails clearly on a duplicate solution
    # name (retry-safety), while a changed batch composition (e.g. a new agent added to
    # the department) gets a fresh name instead of silently reusing a stale one.
    $sortedIds = ($batchItems.agentId | Sort-Object) -join ''
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sortedIds))
    $shortHash = -join ($hashBytes[0..3] | ForEach-Object { $_.ToString('x2') })
    $solutionUniqueName = "PPMigration_${safeName}_$shortHash"
    $zipPath = Join-Path $OutputDir "$solutionUniqueName.zip"

    $target = if ($BulkByDepartment) {
        $agentList = ($batchItems | ForEach-Object { $_.agentName }) -join ', '
        "department '$($batch.Key)' ($($batchItems.Count) agent(s): $agentList): $sourceEnvName -> $targetEnvironmentName"
    }
    else {
        "agent '$($batchItems[0].agentName)' ($($batchItems[0].agentId)): $sourceEnvName -> $targetEnvironmentName"
    }

    $batchStatus = 'Not attempted'
    $batchError = ''
    $perAgentOutcome = @{}
    $solutionId = $null

    if ($PSCmdlet.ShouldProcess($target, 'Create dedicated solution, export, and import into target environment')) {
        Write-Host "`nMigrating $target..." -ForegroundColor Cyan

        # Core migration phase. Only failures before solution import completes classify
        # the migration itself as Failed.
        try {
            Write-Host "  Checking source and target for an existing migration solution..."
            if (Get-DataverseSolutionByUniqueName -EnvUrl $targetEnvironmentUrl -UniqueName $solutionUniqueName) {
                throw "Target environment '$targetEnvironmentName' already contains solution '$solutionUniqueName'. This batch appears to have been imported previously; refusing to overwrite it. Review the existing target solution before retrying."
            }
            if (Get-DataverseSolutionByUniqueName -EnvUrl $sourceEnvUrl -UniqueName $solutionUniqueName) {
                throw "Source environment '$sourceEnvName' already contains solution '$solutionUniqueName' from an earlier attempt. Review or remove that solution before retrying."
            }

            Write-Host "  Creating dedicated solution '$solutionUniqueName'..."
            $solutionBody = @{
                uniquename               = $solutionUniqueName
                friendlyname             = if ($BulkByDepartment) { "Migration - $($batch.Key)" } else { "Migration - $($batchItems[0].agentName)" }
                version                  = '1.0.0.0'
                'publisherid@odata.bind' = "/publishers($publisherId)"
            } | ConvertTo-Json
            # 'Prefer: return=representation' asks Dataverse to hand back the created
            # entity's body (including its solutionid) instead of the default 204 No
            # Content - needed so -CleanupSourceSolution can delete this exact solution
            # by ID later, without a separate lookup-by-uniquename round-trip.
            $solutionCreateResp = Invoke-DataverseRequest -EnvUrl $sourceEnvUrl `
                -Uri "$sourceEnvUrl/api/data/v9.2/solutions" -Method Post -Body $solutionBody `
                -AdditionalHeaders @{ Prefer = 'return=representation' }
            $solutionId = $solutionCreateResp.solutionid

            foreach ($agentItem in $batchItems) {
                Write-Host "  Adding agent '$($agentItem.agentName)' as a solution component (with subcomponents)..."
                $addBody = @{
                    ComponentId               = $agentItem.agentId
                    ComponentType             = $BOT_COMPONENT_TYPE
                    SolutionUniqueName        = $solutionUniqueName
                    AddRequiredComponents     = $true
                    DoNotIncludeSubcomponents = $false
                } | ConvertTo-Json
                Invoke-DataverseRequest -EnvUrl $sourceEnvUrl -Uri "$sourceEnvUrl/api/data/v9.2/AddSolutionComponent" -Method Post -Body $addBody | Out-Null
            }

            Write-Host "  Exporting unmanaged solution to $zipPath..."
            $exportOutput = pac solution export --environment $sourceEnvUrl --name $solutionUniqueName --path $zipPath --overwrite 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw "pac solution export failed:`n$exportOutput" }

            Write-Host "  Importing into '$targetEnvironmentName'..."
            $importOutput = pac solution import --environment $targetEnvironmentUrl --path $zipPath --publish-changes 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw "pac solution import failed:`n$importOutput" }

            $batchStatus = 'Success'
            Write-Host "  Import completed." -ForegroundColor Green
        }
        catch {
            $batchStatus = 'Failed'
            # Invoke-RestMethod's default Exception.Message is a generic "(400) Bad Request"
            # style summary that hides the actual reason. Dataverse's Web API returns the
            # real cause in the response body, so prefer $_.ErrorDetails.Message (the raw
            # body PowerShell captures for non-success HTTP responses) when available.
            $batchError = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
            Write-Warning "  Migration failed for $target`: $batchError"
        }

        # Post-import remediation phase. Failures here do not turn a completed import
        # into a Failed migration or prevent other agents in a bulk batch from being
        # remediated.
        if ($batchStatus -eq 'Success') {
            $importedBots = @()
            try {
                Write-Host "  Resolving imported bot record(s) from target solution '$solutionUniqueName'..."
                $importedBots = @(Get-BotsInSolution -EnvUrl $targetEnvironmentUrl -SolutionUniqueName $solutionUniqueName)
                if ($importedBots.Count -eq 0) {
                    throw "The imported solution contains no bot records."
                }
            }
            catch {
                $resolutionError = "Imported successfully, but target bot records could not be resolved: $($_.Exception.Message)"
                Write-Warning "  $resolutionError"
                foreach ($agentItem in $batchItems) {
                    $perAgentOutcome[$agentItem.agentId] = @{
                        importedAgentId = ''
                        ownerReassignmentStatus = 'Skipped - imported bot record could not be resolved'
                        shareReplicationStatus = 'Skipped'
                        sharesGranted = 0
                        sharesSkipped = 0
                        shareDetails = ''
                        status = 'ImportedWithWarnings'
                        error = $resolutionError
                    }
                }
            }

            if ($importedBots.Count -gt 0) {
                foreach ($agentItem in $batchItems) {
                    $outcome = @{
                        importedAgentId = ''
                        ownerReassignmentStatus = ''
                        shareReplicationStatus = 'Not attempted'
                        sharesGranted = 0
                        sharesSkipped = 0
                        shareDetails = ''
                        status = 'Success'
                        error = ''
                    }
                    $candidates = @($importedBots | Where-Object { $_.name -eq $agentItem.agentName })

                    if ($candidates.Count -ne 1) {
                        $outcome.status = 'ImportedWithWarnings'
                        $outcome.ownerReassignmentStatus = "Skipped - could not uniquely identify the imported bot for '$($agentItem.agentName)' in target solution '$solutionUniqueName' (found $($candidates.Count) candidate(s))"
                        $outcome.error = $outcome.ownerReassignmentStatus
                        Write-Warning "  $($outcome.ownerReassignmentStatus)"
                        $perAgentOutcome[$agentItem.agentId] = $outcome
                        continue
                    }

                    $importedAgentId = $candidates[0].botid
                    $outcome.importedAgentId = $importedAgentId
                    Write-Host "  Imported bot for '$($agentItem.agentName)' identified: $importedAgentId"
                    Write-Host "  Reassigning owner and replicating shares for '$($agentItem.agentName)'..."

                    try {
                        $ownerShareResult = Copy-BotOwnerAndShares -SourceEnvUrl $sourceEnvUrl `
                            -TargetEnvUrl $targetEnvironmentUrl -SourceBotId $agentItem.agentId `
                            -TargetBotId $importedAgentId -OwnerEmail $agentItem.ownerEmailUsed
                        $outcome.ownerReassignmentStatus = $ownerShareResult.ownerReassignmentStatus
                        $outcome.shareReplicationStatus = $ownerShareResult.shareReplicationStatus
                        $outcome.sharesGranted = $ownerShareResult.sharesGranted
                        $outcome.sharesSkipped = $ownerShareResult.sharesSkipped
                        $outcome.shareDetails = $ownerShareResult.shareDetails

                        $remediationWarnings = [System.Collections.Generic.List[string]]::new()
                        if ($outcome.ownerReassignmentStatus -notlike 'Reassigned*') {
                            $remediationWarnings.Add($outcome.ownerReassignmentStatus)
                        }
                        if ($outcome.sharesSkipped -gt 0) {
                            $remediationWarnings.Add("$($outcome.sharesSkipped) share(s) could not be replicated")
                        }
                        if ($outcome.shareReplicationStatus -eq 'Failed') {
                            $remediationWarnings.Add('Share replication could not be completed')
                        }
                        if ($remediationWarnings.Count -gt 0) {
                            $outcome.status = 'ImportedWithWarnings'
                            $outcome.error = $remediationWarnings -join '; '
                        }
                        Write-Host "  Owner: $($outcome.ownerReassignmentStatus)"
                        Write-Host "  Shares: $($outcome.sharesGranted) granted, $($outcome.sharesSkipped) skipped"
                    }
                    catch {
                        $outcome.status = 'ImportedWithWarnings'
                        $outcome.error = "Owner/share remediation failed: $($_.Exception.Message)"
                        $outcome.ownerReassignmentStatus = 'Failed - see error column'
                        $outcome.shareReplicationStatus = 'Failed'
                        Write-Warning "  $($outcome.error)"
                    }
                    $perAgentOutcome[$agentItem.agentId] = $outcome
                }
            }

            if ($CleanupSourceSolution -and $solutionId) {
                Write-Host "  Cleaning up dedicated solution '$solutionUniqueName' from the source environment..."
                try {
                    Invoke-DataverseRequest -EnvUrl $sourceEnvUrl -Uri "$sourceEnvUrl/api/data/v9.2/solutions($solutionId)" -Method Delete | Out-Null
                    Write-Host "  Deleted source solution '$solutionUniqueName'." -ForegroundColor Green
                }
                catch {
                    Write-Warning "  Could not delete source solution '$solutionUniqueName' (solutionid: $solutionId): $($_.Exception.Message) - remove it manually if desired."
                }
            }
        }
    }
    else {
        $batchStatus = 'WhatIf - not executed'
    }

    foreach ($agentItem in $batchItems) {
        $outcome = $perAgentOutcome[$agentItem.agentId]
        $results.Add([PSCustomObject]@{
            agentId                 = $agentItem.agentId
            agentName               = $agentItem.agentName
            departmentUsed          = $agentItem.departmentUsed
            sourceEnvironment       = $sourceEnvName
            targetEnvironmentName   = $targetEnvironmentName
            solutionUniqueName      = $solutionUniqueName
            importedAgentId         = if ($outcome) { $outcome.importedAgentId } else { '' }
            ownerReassignmentStatus = if ($outcome) { $outcome.ownerReassignmentStatus } else { '' }
            shareReplicationStatus  = if ($outcome) { $outcome.shareReplicationStatus } else { '' }
            sharesGranted           = if ($outcome) { $outcome.sharesGranted } else { 0 }
            sharesSkipped           = if ($outcome) { $outcome.sharesSkipped } else { 0 }
            shareDetails            = if ($outcome) { $outcome.shareDetails } else { '' }
            status                  = if ($outcome -and $outcome.status) { $outcome.status } else { $batchStatus }
            error                   = if ($outcome -and $outcome.error) { $outcome.error } else { $batchError }
        })
    }
}

$resultsCsvPath = Join-Path $OutputDir 'migration-results.csv'
$results | Export-Csv -Path $resultsCsvPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
Write-Host "`nMigration results exported to: $resultsCsvPath" -ForegroundColor Green

if (@($results | Where-Object { $_.status -in @('Success', 'ImportedWithWarnings') }).Count -gt 0) {
    Write-Host "`nOwnership and record-level sharing were automatically reassigned/replicated in the target environment where a matching user or team could be found there - see the ownerReassignmentStatus/shareReplicationStatus/sharesGranted/sharesSkipped/shareDetails columns in migration-results.csv for the outcome of each agent." -ForegroundColor Cyan
    Write-Host "`nMANUAL FOLLOW-UP STILL REQUIRED: for each successfully migrated agent, review and reconfigure its connection references and environment variables in the TARGET environment - they still point at the source environment's connections and are not automatically repointed by this script." -ForegroundColor Yellow
}
