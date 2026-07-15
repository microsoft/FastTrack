<#
.SYNOPSIS
    Discovers every department in the tenant (from Entra ID user profiles) and every
    non-default Power Platform environment, then (re)generates
    department-environment-mapping.json - a single file mapping each department to a
    randomly-assigned non-default environment plus a short naming-convention code -
    ready for use by Migrate-CopilotStudioAgents.ps1.

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

    1. Signs in via MSAL.PS and pages through Microsoft Graph's /users endpoint,
       collecting every distinct, non-blank 'department' value in the tenant.
    2. Runs 'pac env list --json' and keeps only non-default environments.
    3. Randomly assigns each department to a non-default environment (environments are
       reused if there are more departments than environments).
    4. Derives a short code for any new department (multi-word -> initials, e.g. "Human
       Resources" -> "HR"; single-word -> first 3 letters, e.g. "Legal" -> "LEG"),
       preserving existing codes so manual overrides survive re-runs.
    5. Writes department-environment-mapping.json, backing up any existing file to
       department-environment-mapping.json.bak-<timestamp> first.

.NOTES
    Environment-sharing note: if there are more departments than non-default
    environments, some environments will be randomly assigned to more than one
    department. This is expected and harmless for Migrate-CopilotStudioAgents.ps1 (which
    looks up department -> environment, so multiple departments simply share the same
    migration target) - it only matters if some other tool in your solution builds a
    reverse environment -> department lookup and expects a 1:1 mapping.

    Requires the MSAL.PS module (Install-Module MSAL.PS -Scope CurrentUser) and the
    Power Platform CLI ('pac', already authenticated or authenticatable via
    'pac auth create') - both are checked automatically on startup, with an offer to
    install whichever is missing for you.
#>

[CmdletBinding()]
param(
    [string]$MappingPath = (Join-Path $PSScriptRoot 'department-environment-mapping.json'),
    [string]$ProfileName = 'PPAgentInventory',
    # By default sign-in uses MSAL's device code flow (open a URL, enter a code) since the
    # embedded-browser -Interactive flow can hang depending on WebView2/broker availability.
    # Pass -UseInteractiveBrowser to try that instead.
    [switch]$UseInteractiveBrowser
)

$ErrorActionPreference = 'Stop'

# --- Pre-flight: confirm required tooling is installed before doing any real work,
#     offering to install anything missing rather than failing deep into the script. ---
. (Join-Path $PSScriptRoot 'Confirm-ScriptRequirements.ps1')
Assert-ScriptRequirements -RequirePac -RequireMsalPs
# Shared MSAL sign-in fallback used by every script in this toolkit that authenticates.
. (Join-Path $PSScriptRoot 'Common-AgentHelpers.ps1')

# --- Derives a department code from a department name (same rule as
#     Inventory-PowerPlatformAgents.ps1, kept in sync so both scripts agree). --------------
function Get-DerivedDepartmentCode {
    param([string]$Department)

    # Force an array even when only one word matches - otherwise PowerShell unwraps a
    # single-element pipeline result to a scalar string, and indexing a string with [0]
    # returns a [char] (breaking the .Substring call below) instead of the word itself.
    $words = @(($Department.Trim() -split '\s+') | Where-Object { $_ -ne '' })
    if ($words.Count -gt 1) {
        return (($words | ForEach-Object { $_.Substring(0, 1).ToUpperInvariant() }) -join '')
    }
    $word = $words[0]
    $len = [Math]::Min(3, $word.Length)
    return $word.Substring(0, $len).ToUpperInvariant()
}

# --- Authenticate via MSAL.PS and discover every distinct department from Entra ID -------
Import-Module MSAL.PS -ErrorAction Stop

# Well-known "Microsoft Azure PowerShell" multi-tenant public client - broadly pre-consented,
# so no app registration is required for delegated access.
$clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
$clientApp = New-MsalClientApplication -ClientId $clientId -TenantId 'organizations'
Enable-MsalTokenCacheOnDisk -PublicClientApplication $clientApp | Out-Null
$graphScope = 'https://graph.microsoft.com/User.Read.All'

Write-Host "Signing in for Microsoft Graph access (User.Read.All)..." -ForegroundColor Cyan
$graphToken = Get-MsalAccessTokenWithFallback -ClientApp $clientApp -Scope $graphScope -UseInteractiveBrowser:$UseInteractiveBrowser -Label 'Microsoft Graph'
$graphHeaders = @{ Authorization = "Bearer $graphToken" }

Write-Host "`nPaging through Microsoft Graph users to collect distinct 'department' values..." -ForegroundColor Cyan
$departmentSet = [System.Collections.Generic.HashSet[string]]::new()
$userCount = 0
$uri = 'https://graph.microsoft.com/v1.0/users?$select=id,department&$top=999'
do {
    $resp = Invoke-RestMethod -Uri $uri -Headers $graphHeaders -Method Get
    foreach ($u in $resp.value) {
        $userCount++
        if ($u.department -and $u.department.Trim() -ne '') { [void]$departmentSet.Add($u.department.Trim()) }
    }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

$departments = @($departmentSet | Sort-Object)
Write-Host "Scanned $userCount user(s); found $($departments.Count) distinct department(s):" -ForegroundColor Green
$departments | ForEach-Object { Write-Host "  - $_" }
if ($departments.Count -eq 0) { throw "No non-blank 'department' values found on any user - nothing to map." }

# --- Discover every non-default Power Platform environment via pac env list --------------
$authList = pac auth list 2>&1 | Out-String
if ($authList -match [regex]::Escape($ProfileName)) {
    Write-Host "`nReusing existing auth profile '$ProfileName'..." -ForegroundColor Cyan
    pac auth select --name $ProfileName | Out-Null
}
else {
    Write-Host "`nCreating auth profile '$ProfileName' (connects to your tenant's default environment)..." -ForegroundColor Cyan
    pac auth create --name $ProfileName
}

$envListRaw = (pac env list --json 2>&1 | Out-String)
$envList = $null
try { $envList = $envListRaw | ConvertFrom-Json }
catch { throw "Could not parse 'pac env list --json' output:`n$envListRaw" }

$nonDefaultEnvs = @($envList | Where-Object { -not $_.EnvironmentIdentifier.IsDefault } | ForEach-Object { $_.FriendlyName } | Sort-Object)
Write-Host "Found $($nonDefaultEnvs.Count) non-default environment(s):" -ForegroundColor Green
$nonDefaultEnvs | ForEach-Object { Write-Host "  - $_" }
if ($nonDefaultEnvs.Count -eq 0) { throw "No non-default environments found - nothing to map departments to." }

if ($departments.Count -gt $nonDefaultEnvs.Count) {
    Write-Warning "$($departments.Count) department(s) but only $($nonDefaultEnvs.Count) non-default environment(s) - some environments will be randomly assigned to more than one department. This is fine for Migrate-CopilotStudioAgents.ps1 (multiple departments will simply share the same migration target environment)."
}

# --- Preserve existing codes (and any existing environment assignments left untouched by
#     re-runs would be overwritten below, since environments are always re-randomized) from
#     the current file, so manual code overrides survive across re-runs. ------------------
$departmentToCode = @{}
if (Test-Path $MappingPath) {
    $existingMapping = @(Get-Content -Path $MappingPath -Raw | ConvertFrom-Json)
    foreach ($entry in $existingMapping) {
        if ($entry.department -and $entry.code) { $departmentToCode[$entry.department] = $entry.code }
    }
}
foreach ($department in $departments) {
    if (-not $departmentToCode.ContainsKey($department)) {
        $departmentToCode[$department] = Get-DerivedDepartmentCode -Department $department
    }
}

# --- Randomly assign each department to a non-default environment ------------------------
$assignments = foreach ($department in $departments) {
    $environmentName = Get-Random -InputObject $nonDefaultEnvs
    [PSCustomObject]@{ department = $department; environmentName = $environmentName; code = $departmentToCode[$department] }
}

Write-Host "`nRandom department -> environment assignment:" -ForegroundColor Cyan
$assignments | ForEach-Object { Write-Host ("  {0,-25} -> {1,-10} (code: {2}_)" -f $_.department, $_.environmentName, $_.code) }

if (Test-Path $MappingPath) {
    $backupPath = "$MappingPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $MappingPath -Destination $backupPath -Force
    Write-Host "`nBacked up existing mapping to: $backupPath" -ForegroundColor Yellow
}
$assignments | ConvertTo-Json -Depth 3 | Out-File -FilePath $MappingPath -Encoding UTF8
Write-Host "Wrote department-environment-code mapping: $MappingPath" -ForegroundColor Green
