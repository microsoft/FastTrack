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
       department-environment-mapping.example.json for the shape).
    3. For each agent, resolves its owning department (the owner's, falling back to the
       creator's if orphaned), looks up the mapped target environment, and builds a
       migration plan - skipping agents with no resolvable department, no mapping
       entry, a same-as-source target, or first-party/Microsoft-managed status.
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
       (matched by email) and re-grants the same shares (users by email, teams by
       name) in the target environment, skipping anything it can't match with a logged
       reason.
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
    environmentName in the JSON doesn't match the currently active
    environment are skipped with a warning.
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
    # import into the target environment has succeeded. Only ever applies on success -
    # a failed/partial migration always leaves its solution in place so you can
    # investigate. Best-effort: a failed delete is logged as a warning, not a script
    # failure - the migration itself already succeeded by that point.
    [switch]$CleanupSourceSolution
)

$ErrorActionPreference = 'Stop'

# --- Pre-flight: confirm required tooling is installed before doing any real work,
#     offering to install anything missing rather than failing deep into the script. ---
. (Join-Path $PSScriptRoot 'Confirm-ScriptRequirements.ps1')
Assert-ScriptRequirements -RequirePac -RequireMsalPs

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
$deptMap = @{}
foreach ($m in $mappingRaw) {
    if (-not $m.department -or -not $m.environmentName) { continue }
    $deptMap[$m.department.Trim().ToLowerInvariant()] = $m.environmentName
}
if ($deptMap.Count -eq 0) { throw "No usable entries found in the mapping file '$MappingPath' - expected an array of { department, environmentName } objects." }
Write-Host "Loaded $($deptMap.Count) department -> environment mapping(s)." -ForegroundColor Green

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
Write-Host "`nSource environment: $sourceEnvName ($sourceEnvUrl)`n" -ForegroundColor Cyan

$mismatched = @($agents | Where-Object { $_.environmentName -ne $sourceEnvName })
if ($mismatched.Count -gt 0) {
    Write-Warning "Skipping $($mismatched.Count) agent(s) belonging to a different environment than the currently authenticated one ('$sourceEnvName') - sign in to / select the correct source environment first."
    $agents = @($agents | Where-Object { $_.environmentName -eq $sourceEnvName })
}
if ($agents.Count -eq 0) { throw "No agents from the source environment '$sourceEnvName' remain to evaluate." }

# --- Acquire Dataverse access for the source environment early, so the migration plan
#     below can pre-flight-check each agent's solution membership (see
#     Test-IsMicrosoftManagedAgent) before committing to a full export/import cycle. This
#     same MSAL client app and header cache are reused further down for the source
#     environment's publisher/component-type resolution and for each distinct TARGET
#     environment's owner-reassignment/share-replication calls, so nothing here is
#     authenticated to twice. ---
Write-Host "`nAcquiring Dataverse access for the source environment ($sourceEnvUrl)..." -ForegroundColor Cyan
Import-Module MSAL.PS -ErrorAction Stop
$clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
$clientApp = New-MsalClientApplication -ClientId $clientId -TenantId 'organizations'
Enable-MsalTokenCacheOnDisk -PublicClientApplication $clientApp | Out-Null

function Get-DataverseHeaders {
    param([Parameter(Mandatory)][string]$EnvUrl)
    try {
        $token = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$EnvUrl/.default" -Silent -ErrorAction Stop).AccessToken
    }
    catch {
        if ($UseInteractiveBrowser) {
            $token = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$EnvUrl/.default" -Interactive).AccessToken
        }
        else {
            $token = (Get-MsalToken -PublicClientApplication $clientApp -Scopes "$EnvUrl/.default" -DeviceCode).AccessToken
        }
    }
    $bearer = 'Bear' + 'er ' + $token
    return @{
        Authorization      = $bearer
        Accept             = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        'Content-Type'     = 'application/json; charset=utf-8'
    }
}

$dvHeadersCache = @{}
function Get-CachedDataverseHeaders {
    param([Parameter(Mandatory)][string]$EnvUrl)
    $key = $EnvUrl.TrimEnd('/')
    if (-not $dvHeadersCache.ContainsKey($key)) {
        Write-Host "  Authenticating to Dataverse environment: $key..." -ForegroundColor Cyan
        $dvHeadersCache[$key] = Get-DataverseHeaders -EnvUrl $key
    }
    return $dvHeadersCache[$key]
}

$dvHeaders = Get-CachedDataverseHeaders -EnvUrl $sourceEnvUrl

# --- Detects whether an agent's underlying bot record is owned by a Microsoft-published,
#     MANAGED first-party solution (e.g. a prebuilt Microsoft 365 Copilot agent like
#     "Finance in Microsoft 365 Copilot", which lives in msdyn_FinancialReconciliationAgent)
#     rather than being authored by a real person in this tenant. Confirmed live: such
#     agents CAN be added to a custom unmanaged solution and export/import without error,
#     but produce no actual new bot record in the target (there's no real customizable
#     content to copy) - so they're better skipped upfront with a clear reason than run
#     through a full, silently-no-op export/import cycle. Detection: the agent belongs to
#     at least one MANAGED solution whose uniquename or publisher customization prefix
#     matches a well-known Microsoft first-party pattern. ---
$microsoftManagedPrefixes = @('msdyn', 'mscrm', 'msa', 'adx', 'mspp', 'msft')
function Test-IsMicrosoftManagedAgent {
    param([Parameter(Mandatory)][string]$AgentId)

    $resp = Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/solutioncomponents?`$filter=objectid eq $AgentId&`$select=componenttype&`$expand=solutionid(`$select=uniquename,ismanaged;`$expand=publisherid(`$select=customizationprefix))" -Headers $dvHeaders -Method Get
    foreach ($c in $resp.value) {
        $sol = $c.solutionid
        if (-not $sol -or -not $sol.ismanaged) { continue }
        $prefix = $sol.publisherid.customizationprefix
        $isMicrosoftPattern = ($microsoftManagedPrefixes | Where-Object { $sol.uniquename -like "$_*" -or $prefix -eq $_ }).Count -gt 0
        if ($isMicrosoftPattern) {
            return [PSCustomObject]@{ IsManaged = $true; SolutionUniqueName = $sol.uniquename }
        }
    }
    return [PSCustomObject]@{ IsManaged = $false; SolutionUniqueName = $null }
}

# --- Build the migration plan ---
Write-Host "`nBuilding migration plan for $($agents.Count) agent(s)..." -ForegroundColor Cyan
$plan = foreach ($agent in $agents) {
    $dept = $null
    if (-not $agent.isOrphaned -and $agent.ownerUserDepartment) { $dept = $agent.ownerUserDepartment }
    elseif ($agent.createdByUserDepartment) { $dept = $agent.createdByUserDepartment }

    # Same owner-first/creator-fallback rule as department, so the post-import owner
    # reassignment step (below) targets the same person the plan's department came from.
    $ownerEmail = $null
    if (-not $agent.isOrphaned -and $agent.ownerEmail) { $ownerEmail = $agent.ownerEmail }
    elseif ($agent.createdByEmail) { $ownerEmail = $agent.createdByEmail }

    $status = 'Planned'
    $targetEnvName = $null
    if (-not $dept) {
        $status = 'Skipped - no owner/creator department found'
    }
    else {
        $key = $dept.Trim().ToLowerInvariant()
        if (-not $deptMap.ContainsKey($key)) {
            $status = "Skipped - no environment mapping for department '$dept'"
        }
        else {
            $targetEnvName = $deptMap[$key]
            if ($targetEnvName -eq $sourceEnvName) { $status = 'Skipped - target environment same as source' }
        }
    }

    # Only bother with the extra Dataverse round-trip if the agent would otherwise proceed.
    if ($status -eq 'Planned') {
        $managedCheck = Test-IsMicrosoftManagedAgent -AgentId $agent.agentId
        if ($managedCheck.IsManaged) {
            $status = "Skipped - first-party Microsoft-managed agent (belongs to managed solution '$($managedCheck.SolutionUniqueName)') - no customizable content to migrate"
        }
    }

    [PSCustomObject]@{
        agentId               = $agent.agentId
        agentName             = $agent.agentName
        departmentUsed        = $dept
        ownerEmailUsed        = $ownerEmail
        sourceEnvironment     = $sourceEnvName
        targetEnvironmentName = $targetEnvName
        status                = $status
    }
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

# --- Resolve target environment URLs via pac env list ---
Write-Host "Resolving target environment URL(s) for $($toMigrate.Count) planned migration(s) via 'pac env list'..." -ForegroundColor Cyan
$envList = (pac env list --json 2>&1 | Out-String) | ConvertFrom-Json
foreach ($item in $toMigrate) {
    $targetRecord = $envList | Where-Object { $_.FriendlyName -eq $item.targetEnvironmentName } | Select-Object -First 1
    if (-not $targetRecord) {
        $item.status = "Skipped - target environment '$($item.targetEnvironmentName)' not found via pac env list"
    }
    else {
        $item | Add-Member -NotePropertyName TargetEnvironmentUrl -NotePropertyValue $targetRecord.EnvironmentUrl -Force
    }
}
$unresolved = @($toMigrate | Where-Object { $_.status -ne 'Planned' })
if ($unresolved.Count -gt 0) {
    Write-Warning "$($unresolved.Count) planned migration(s) could not be resolved to a real environment and will be skipped:"
    $unresolved | Format-Table agentName, targetEnvironmentName, status -AutoSize | Out-String | Write-Host
}
$toMigrate = @($toMigrate | Where-Object { $_.status -eq 'Planned' })
if ($toMigrate.Count -eq 0) {
    Write-Host "No agents left to migrate after environment resolution." -ForegroundColor Yellow
    return
}
Write-Host "$($toMigrate.Count) agent(s) resolved and ready to migrate." -ForegroundColor Green

# Reuse the source environment's own Default-solution publisher for every new dedicated
# solution, rather than creating a new publisher - keeps this non-invasive. ($dvHeaders was
# already acquired above, before the plan was built, so it can power the pre-flight
# Test-IsMicrosoftManagedAgent check on each candidate agent.)
Write-Host "Resolving the source environment's Default-solution publisher..." -ForegroundColor Cyan
$pubResp = Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/solutions?`$filter=uniquename eq 'Default'&`$select=uniquename&`$expand=publisherid(`$select=publisherid)" -Headers $dvHeaders -Method Get
$publisherId = $pubResp.value[0].publisherid.publisherid
if (-not $publisherId) { throw "Could not resolve the source environment's Default solution publisher." }
Write-Host "Resolved publisher: $publisherId" -ForegroundColor Green

# The "Bot" solution-component type is a custom-table object type code, which Dataverse
# assigns per-org (NOT a fixed global constant) - Microsoft's published solution-component-
# type reference doesn't list a value for Bot either. Resolve it dynamically here by
# looking at an existing bot's own solutioncomponent row in the SOURCE org, rather than
# hardcoding a number that could be wrong if this script is ever pointed at a different
# source environment (confirmed live: the same logical component type can resolve to a
# different numeric code in different environments/tenants - e.g. 10163 in one org vs.
# 10212 in another after import).
Write-Host "Resolving the Bot solution-component type for this source environment..." -ForegroundColor Cyan
$sampleBotId = $toMigrate[0].agentId
$typeResp = Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/solutioncomponents?`$filter=objectid eq $sampleBotId&`$select=componenttype&`$top=1" -Headers $dvHeaders -Method Get
if ($typeResp.value.Count -eq 0) { throw "Could not resolve the Bot solution-component type from '$sampleBotId' - is it a member of any solution in the source environment?" }
$BOT_COMPONENT_TYPE = $typeResp.value[0].componenttype
Write-Host "Resolved Bot solution-component type for this source environment: $BOT_COMPONENT_TYPE" -ForegroundColor Cyan

# --- Post-import owner reassignment + share replication ---
# Dataverse solution import does NOT preserve the bot's record GUID, its owner, or its
# record-level sharing (confirmed live against this tenant): the imported bot becomes
# owned by whoever ran the import, and any explicit shares are simply gone. This function
# restores both, given the already-identified NEW bot record in the target environment.
function Copy-BotOwnerAndShares {
    param(
        [Parameter(Mandatory)][string]$SourceEnvUrl,
        [Parameter(Mandatory)][hashtable]$SourceHeaders,
        [Parameter(Mandatory)][string]$TargetEnvUrl,
        [Parameter(Mandatory)][hashtable]$TargetHeaders,
        [Parameter(Mandatory)][string]$SourceBotId,
        [Parameter(Mandatory)][string]$TargetBotId,
        [string]$OwnerEmail
    )

    $result = [PSCustomObject]@{
        ownerReassignmentStatus = 'Not attempted'
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
        $userFilter = "domainname eq '$OwnerEmail' or internalemailaddress eq '$OwnerEmail'"
        $userResp = Invoke-RestMethod -Uri "$TargetEnvUrl/api/data/v9.2/systemusers?`$filter=$userFilter&`$select=systemuserid&`$top=1" -Headers $TargetHeaders -Method Get
        if ($userResp.value.Count -eq 0) {
            $result.ownerReassignmentStatus = "Skipped - no user matching '$OwnerEmail' found in target environment"
        }
        else {
            $targetUserId = $userResp.value[0].systemuserid
            $ownerBody = @{ 'ownerid@odata.bind' = "/systemusers($targetUserId)" } | ConvertTo-Json
            try {
                Invoke-RestMethod -Uri "$TargetEnvUrl/api/data/v9.2/bots($TargetBotId)" -Headers $TargetHeaders -Method Patch -Body $ownerBody | Out-Null
                $result.ownerReassignmentStatus = "Reassigned to '$OwnerEmail'"
            }
            catch {
                # Non-fatal: e.g. the matched target user has no security role/privilege on
                # bots in that environment yet. The core copy already succeeded - don't let
                # this best-effort step fail the whole migration, just report it clearly.
                $result.ownerReassignmentStatus = "Failed - matched user '$OwnerEmail' in target but could not reassign owner: $($_.Exception.Message)"
            }
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
        $sharesResp = Invoke-RestMethod -Uri "$SourceEnvUrl/api/data/v9.2/RetrieveSharedPrincipalsAndAccess(Target=@tp)?@tp=$encodedTargetRef" -Headers $SourceHeaders -Method Get

        foreach ($pa in @($sharesResp.PrincipalAccesses)) {
            $principalType = $pa.Principal.'@odata.type' -replace '^#Microsoft\.Dynamics\.CRM\.', ''
            $principalId = $pa.Principal.ownerid
            $accessMask = $pa.AccessMask
            $targetPrincipalId = $null
            $principalOdataType = $null
            $principalKey = $null
            $label = $null

            if ($principalType -eq 'team') {
                $teamResp = Invoke-RestMethod -Uri "$SourceEnvUrl/api/data/v9.2/teams($principalId)?`$select=name" -Headers $SourceHeaders -Method Get
                $teamName = $teamResp.name
                if ($teamName -eq $autoTeamName) { continue }

                $label = "team '$teamName'"
                $targetTeamResp = Invoke-RestMethod -Uri "$TargetEnvUrl/api/data/v9.2/teams?`$filter=name eq '$teamName'&`$select=teamid&`$top=1" -Headers $TargetHeaders -Method Get
                if ($targetTeamResp.value.Count -eq 0) {
                    $result.sharesSkipped++
                    $shareDetailsList.Add("Skipped $label - no matching team found in target")
                    continue
                }
                $targetPrincipalId = $targetTeamResp.value[0].teamid
                $principalOdataType = 'Microsoft.Dynamics.CRM.team'
                $principalKey = 'teamid'
            }
            else {
                $userResp2 = Invoke-RestMethod -Uri "$SourceEnvUrl/api/data/v9.2/systemusers($principalId)?`$select=domainname,internalemailaddress,fullname" -Headers $SourceHeaders -Method Get
                $email = if ($userResp2.internalemailaddress) { $userResp2.internalemailaddress } else { $userResp2.domainname }
                $label = "user '$email'"
                if ([string]::IsNullOrWhiteSpace($email)) {
                    $result.sharesSkipped++
                    $shareDetailsList.Add("Skipped user '$($userResp2.fullname)' - no resolvable email")
                    continue
                }
                $userFilter2 = "domainname eq '$email' or internalemailaddress eq '$email'"
                $targetUserResp = Invoke-RestMethod -Uri "$TargetEnvUrl/api/data/v9.2/systemusers?`$filter=$userFilter2&`$select=systemuserid&`$top=1" -Headers $TargetHeaders -Method Get
                if ($targetUserResp.value.Count -eq 0) {
                    $result.sharesSkipped++
                    $shareDetailsList.Add("Skipped $label - no matching user found in target")
                    continue
                }
                $targetPrincipalId = $targetUserResp.value[0].systemuserid
                $principalOdataType = 'Microsoft.Dynamics.CRM.systemuser'
                $principalKey = 'systemuserid'
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
            try {
                Invoke-RestMethod -Uri "$TargetEnvUrl/api/data/v9.2/GrantAccess" -Headers $TargetHeaders -Method Post -Body $grantBody | Out-Null
                $result.sharesGranted++
                $shareDetailsList.Add("Granted $label ($accessMask)")
            }
            catch {
                $result.sharesSkipped++
                $shareDetailsList.Add("Failed to grant $label`: $($_.Exception.Message)")
            }
        }
    }
    catch {
        # Non-fatal: e.g. the source agent has no shares at all, or the target environment
        # rejected a lookup call. The core copy already succeeded - report this clearly
        # rather than failing the whole migration over a best-effort remediation step.
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

    if ($PSCmdlet.ShouldProcess($target, 'Create dedicated solution, export, and import into target environment')) {
        try {
            Write-Host "`nMigrating $target..." -ForegroundColor Cyan

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
            $createHeaders = $dvHeaders.Clone()
            $createHeaders['Prefer'] = 'return=representation'
            $solutionCreateResp = Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/solutions" -Headers $createHeaders -Method Post -Body $solutionBody
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
                Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/AddSolutionComponent" -Headers $dvHeaders -Method Post -Body $addBody | Out-Null
            }

            Write-Host "  Exporting unmanaged solution to $zipPath..."
            $exportOutput = pac solution export --environment $sourceEnvUrl --name $solutionUniqueName --path $zipPath --overwrite 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw "pac solution export failed:`n$exportOutput" }

            $targetHeaders = Get-CachedDataverseHeaders -EnvUrl $targetEnvironmentUrl
            Write-Host "  Snapshotting target bots before import..."
            $beforeBotIds = @((Invoke-RestMethod -Uri "$targetEnvironmentUrl/api/data/v9.2/bots?`$select=botid" -Headers $targetHeaders -Method Get).value | ForEach-Object { $_.botid })

            Write-Host "  Importing into '$targetEnvironmentName'..."
            $importOutput = pac solution import --environment $targetEnvironmentUrl --path $zipPath --publish-changes 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw "pac solution import failed:`n$importOutput" }

            $batchStatus = 'Success'
            Write-Host "  Done." -ForegroundColor Green

            # --- Identify each batch member's new bot record by diffing the target's bots
            #     table before/after import (solution import does NOT preserve the bot's
            #     record GUID), matching each candidate back to its agent by name. ---
            Write-Host "  Identifying new bot record(s) in the target environment..."
            $afterBots = @((Invoke-RestMethod -Uri "$targetEnvironmentUrl/api/data/v9.2/bots?`$select=botid,name" -Headers $targetHeaders -Method Get).value)
            $newBots = @($afterBots | Where-Object { $beforeBotIds -notcontains $_.botid })

            foreach ($agentItem in $batchItems) {
                $candidates = @($newBots | Where-Object { $_.name -eq $agentItem.agentName })
                $outcome = @{ importedAgentId = ''; ownerReassignmentStatus = ''; sharesGranted = 0; sharesSkipped = 0; shareDetails = '' }

                if ($candidates.Count -eq 1) {
                    $importedAgentId = $candidates[0].botid
                    $outcome.importedAgentId = $importedAgentId
                    Write-Host "  New bot for '$($agentItem.agentName)' identified: $importedAgentId"

                    Write-Host "  Reassigning owner and replicating shares for '$($agentItem.agentName)'..."
                    $ownerShareResult = Copy-BotOwnerAndShares -SourceEnvUrl $sourceEnvUrl -SourceHeaders $dvHeaders `
                        -TargetEnvUrl $targetEnvironmentUrl -TargetHeaders $targetHeaders `
                        -SourceBotId $agentItem.agentId -TargetBotId $importedAgentId -OwnerEmail $agentItem.ownerEmailUsed
                    $outcome.ownerReassignmentStatus = $ownerShareResult.ownerReassignmentStatus
                    $outcome.sharesGranted = $ownerShareResult.sharesGranted
                    $outcome.sharesSkipped = $ownerShareResult.sharesSkipped
                    $outcome.shareDetails = $ownerShareResult.shareDetails
                    Write-Host "  Owner: $($outcome.ownerReassignmentStatus)"
                    Write-Host "  Shares: $($outcome.sharesGranted) granted, $($outcome.sharesSkipped) skipped"
                }
                else {
                    $outcome.ownerReassignmentStatus = "Skipped - could not uniquely identify the new bot for '$($agentItem.agentName)' in the target (found $($candidates.Count) candidate(s))"
                    Write-Warning "  $($outcome.ownerReassignmentStatus) - owner reassignment and share replication were skipped for this agent."
                }
                $perAgentOutcome[$agentItem.agentId] = $outcome
            }

            if ($CleanupSourceSolution) {
                Write-Host "  Cleaning up dedicated solution '$solutionUniqueName' from the source environment..."
                try {
                    Invoke-RestMethod -Uri "$sourceEnvUrl/api/data/v9.2/solutions($solutionId)" -Headers $dvHeaders -Method Delete | Out-Null
                    Write-Host "  Deleted source solution '$solutionUniqueName'." -ForegroundColor Green
                }
                catch {
                    # Best-effort, like owner reassignment/share replication above - the
                    # migration itself already succeeded by this point, so a failed delete
                    # is logged rather than treated as a migration failure.
                    Write-Warning "  Could not delete source solution '$solutionUniqueName' (solutionid: $solutionId): $($_.Exception.Message) - remove it manually if desired."
                }
            }
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
            sharesGranted           = if ($outcome) { $outcome.sharesGranted } else { 0 }
            sharesSkipped           = if ($outcome) { $outcome.sharesSkipped } else { 0 }
            shareDetails            = if ($outcome) { $outcome.shareDetails } else { '' }
            status                  = $batchStatus
            error                   = $batchError
        })
    }
}

$resultsCsvPath = Join-Path $OutputDir 'migration-results.csv'
$results | Export-Csv -Path $resultsCsvPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
Write-Host "`nMigration results exported to: $resultsCsvPath" -ForegroundColor Green

if (@($results | Where-Object { $_.status -eq 'Success' }).Count -gt 0) {
    Write-Host "`nOwnership and record-level sharing were automatically reassigned/replicated in the target environment where a matching user or team could be found there - see the ownerReassignmentStatus/sharesGranted/sharesSkipped/shareDetails columns in migration-results.csv for the outcome of each agent." -ForegroundColor Cyan
    Write-Host "`nMANUAL FOLLOW-UP STILL REQUIRED: for each successfully migrated agent, review and reconfigure its connection references and environment variables in the TARGET environment - they still point at the source environment's connections and are not automatically repointed by this script." -ForegroundColor Yellow
}
