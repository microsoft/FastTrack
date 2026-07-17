<#
.SYNOPSIS
    Shared helper functions used by the CopilotStudioAgentScripts toolkit: an MSAL
    sign-in fallback (silent -> interactive/device-code) and an efficient, batched
    Microsoft-first-party/managed-agent detector, kept in one place so all three
    scripts stay in sync instead of carrying their own copies.

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

    Dot-source this file, then call Get-MsalAccessTokenWithFallback,
    Get-MsalTokenResultWithFallback, ConvertTo-NormalizedEnvironmentId,
    ConvertTo-ODataStringLiteral, and/or Get-MicrosoftManagedAgentIds.
#>

# Acquires the full MSAL token result so callers that cache authorization headers can
# retain ExpiresOn and refresh before the token becomes invalid.
function Get-MsalTokenResultWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$ClientApp,
        [Parameter(Mandatory)][string]$Scope,
        [switch]$UseInteractiveBrowser,
        [switch]$ForceRefresh,
        # Short label used only in the console messages below, e.g. "Dataverse" or
        # "Microsoft Graph" - purely cosmetic, doesn't affect the token request itself.
        [string]$Label = 'access'
    )
    try {
        $silentParams = @{
            PublicClientApplication = $ClientApp
            Scopes                  = $Scope
            Silent                  = $true
            ErrorAction             = 'Stop'
        }
        if ($ForceRefresh) { $silentParams.ForceRefresh = $true }
        $tokenResult = Get-MsalToken @silentParams
        if ($ForceRefresh) {
            Write-Host "Refreshed sign-in for $Label (no prompt needed)." -ForegroundColor Green
        }
        else {
            Write-Host "Reused cached sign-in for $Label (no prompt needed)." -ForegroundColor Green
        }
    }
    catch {
        if ($UseInteractiveBrowser) {
            $tokenResult = Get-MsalToken -PublicClientApplication $ClientApp -Scopes $Scope -Interactive
        }
        else {
            Write-Host "No valid cached token found for $Label - using device code flow (no browser popup to hang)." -ForegroundColor Yellow
            $tokenResult = Get-MsalToken -PublicClientApplication $ClientApp -Scopes $Scope -DeviceCode
        }
    }
    return $tokenResult
}

# Convenience wrapper for callers that only need the bearer-token string.
function Get-MsalAccessTokenWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$ClientApp,
        [Parameter(Mandatory)][string]$Scope,
        [switch]$UseInteractiveBrowser,
        [switch]$ForceRefresh,
        [string]$Label = 'access'
    )
    $tokenResult = Get-MsalTokenResultWithFallback -ClientApp $ClientApp -Scope $Scope `
        -UseInteractiveBrowser:$UseInteractiveBrowser -ForceRefresh:$ForceRefresh -Label $Label
    return $tokenResult.AccessToken
}

# Produces a valid OData string literal. The completed $filter expression should still
# be URI-encoded before it is added to a request URL.
function ConvertTo-ODataStringLiteral {
    param([AllowEmptyString()][string]$Value)

    return "'" + $Value.Replace("'", "''") + "'"
}

# pac env who and the Power Platform inventory API can represent the default
# environment as "Default-<guid>", while pac env list returns only "<guid>".
function ConvertTo-NormalizedEnvironmentId {
    param([AllowEmptyString()][string]$EnvironmentId)

    if ([string]::IsNullOrWhiteSpace($EnvironmentId)) { return '' }
    return $EnvironmentId.Trim() -replace '^(?i:Default-)', ''
}

# Given a set of candidate Dataverse bot (agent) IDs, returns a hashtable of
# agentId -> managed solution uniquename for only the ones that belong to a MANAGED
# solution matching a known Microsoft first-party prefix/publisher (msdyn, mscrm, msa,
# adx, mspp, msft) - e.g. "Finance in Microsoft 365 Copilot" belongs to the managed
# solution 'msdyn_FinancialReconciliationAgent'. Agents not present as a key in the
# returned hashtable are not first-party/managed (or weren't in the candidate list).
#
# Chunks the candidate agent IDs into OR'd objectid filters (a handful of Dataverse
# calls total, bounded regardless of environment size) instead of one call PER agent -
# still only ever asks about the specific agents we care about, rather than trying to
# enumerate every component of every Microsoft-pattern solution in the environment
# first: a real Dataverse org ships with MANY system-managed solutions matching these
# prefixes (confirmed live), some with thousands of components, so listing them
# wholesale turned out to be far slower than the naive per-agent version it was meant
# to replace. This heuristic prefix list is not exhaustive - confirmed against live
# examples in one tenant (msdyn_) but may miss other first-party solutions.
function Get-MicrosoftManagedAgentIds {
    param(
        [Parameter(Mandatory)][string]$InstanceUrl,
        [hashtable]$Headers,
        [scriptblock]$RequestInvoker,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$AgentIds
    )
    $managedPrefixes = @('msdyn', 'mscrm', 'msa', 'adx', 'mspp', 'msft')
    $result = @{}
    if (-not $AgentIds -or $AgentIds.Count -eq 0) { return $result }
    if (-not $RequestInvoker -and -not $Headers) {
        throw 'Get-MicrosoftManagedAgentIds requires either -Headers or -RequestInvoker.'
    }

    # Chunk size kept modest since each OR'd clause here also carries a nested $expand -
    # a large combined filter+expand URL is more likely to hit Dataverse's URL length
    # limit than the simpler filters used elsewhere in this toolkit.
    $chunkSize = 15
    for ($i = 0; $i -lt $AgentIds.Count; $i += $chunkSize) {
        $chunkEnd = [Math]::Min($i + $chunkSize - 1, $AgentIds.Count - 1)
        $chunk = @($AgentIds[$i..$chunkEnd])
        $objectFilter = ($chunk | ForEach-Object { "objectid eq $_" }) -join ' or '
        $compUri = "$InstanceUrl/api/data/v9.2/solutioncomponents?`$filter=($objectFilter)&`$select=objectid&`$expand=solutionid(`$select=uniquename,ismanaged;`$expand=publisherid(`$select=customizationprefix))"
        do {
            $compResp = if ($RequestInvoker) {
                & $RequestInvoker $compUri
            }
            else {
                Invoke-RestMethod -Uri $compUri -Headers $Headers -Method Get
            }
            foreach ($c in $compResp.value) {
                $objectId = [string]$c.objectid
                if ($result.ContainsKey($objectId)) { continue }
                $sol = $c.solutionid
                if (-not $sol -or -not $sol.ismanaged) { continue }
                $prefix = $sol.publisherid.customizationprefix
                $isMicrosoftPattern = ($managedPrefixes | Where-Object { $sol.uniquename -like "$_*" -or $prefix -eq $_ }).Count -gt 0
                if ($isMicrosoftPattern) { $result[$objectId] = $sol.uniquename }
            }
            $compUri = $compResp.'@odata.nextLink'
        } while ($compUri)
    }
    return $result
}
