[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-AgentFile {
    param([string]$StartPath)

    $resolved = (Resolve-Path -LiteralPath $StartPath).Path
    Get-ChildItem -Path $resolved -Recurse -File -Filter 'agent.mcs.yml' -Depth 6 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
        Sort-Object FullName |
        Select-Object -First 1
}

function Write-Check {
    param(
        [bool]$Passed,
        [string]$SuccessMessage,
        [string]$FailureMessage
    )

    if ($Passed) {
        Write-Host ("✅ {0}" -f $SuccessMessage) -ForegroundColor Green
    }
    else {
        Write-Host ("⚠️  {0}" -f $FailureMessage) -ForegroundColor Yellow
    }
}

try {
    $allPassed = $true
    $agentFile = Find-AgentFile -StartPath $Path
    $agentExists = $null -ne $agentFile
    Write-Check -Passed $agentExists -SuccessMessage ("Found agent file: {0}" -f $agentFile.FullName) -FailureMessage 'No agent.mcs.yml found.'
    if (-not $agentExists) {
        exit 1
    }

    $agentRoot = Split-Path -Parent $agentFile.FullName
    $repoRoot = $null
    try {
        $repoRoot = (& git -C $agentRoot rev-parse --show-toplevel 2>$null).Trim()
    }
    catch {
        $repoRoot = $null
    }

    if ($repoRoot) {
        $statusLines = @(& git -C $repoRoot status --porcelain 2>$null)
        $dirtyWorkflowFiles = @($statusLines |
            ForEach-Object { if ($_ -match '^..\s+(?<Path>.+)$') { $Matches['Path'].Trim() } } |
            Where-Object { $_ -and ($_ -match '(^|[\\/])workflows[\\/].+\.json$' -or $_ -match '(^|[\\/])settings\.mcs\.yml$') })

        $workflowClean = $dirtyWorkflowFiles.Count -eq 0
        Write-Check -Passed $workflowClean -SuccessMessage 'Workflow files are clean.' -FailureMessage ("Environment-specific workflow files are dirty: {0}" -f ($dirtyWorkflowFiles -join ', '))
        if (-not $workflowClean) { $allPassed = $false }

        $hasUncommittedChanges = $statusLines.Count -gt 0
        Write-Check -Passed (-not $hasUncommittedChanges) -SuccessMessage 'Git working tree is clean.' -FailureMessage ("Git working tree has {0} modified item(s)." -f $statusLines.Count)
        if ($hasUncommittedChanges) { $allPassed = $false }
    }
    else {
        Write-Check -Passed $false -SuccessMessage '' -FailureMessage 'Git repository not detected.'
        $allPassed = $false
    }

    $agentContent = Get-Content -LiteralPath $agentFile.FullName -Raw
    $variableReferences = [regex]::Matches($agentContent, '\{Global\.([A-Za-z0-9_]+)\}') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique

    $variablesPath = Join-Path $agentRoot 'variables'
    $definedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path -LiteralPath $variablesPath) {
        foreach ($variableFile in Get-ChildItem -Path $variablesPath -Recurse -File -Filter '*.mcs.yml' -ErrorAction SilentlyContinue) {
            [void]$definedNames.Add([System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($variableFile.Name)))
            $nameMatch = Get-Content -LiteralPath $variableFile.FullName | Select-String -Pattern '^\s*name\s*:\s*"?(?<Value>.+?)"?\s*$' | Select-Object -First 1
            if ($nameMatch) {
                [void]$definedNames.Add($nameMatch.Matches[0].Groups['Value'].Value.Trim())
            }
        }
    }

    $missingVariables = @()
    foreach ($reference in $variableReferences) {
        if (-not $definedNames.Contains($reference)) {
            $missingVariables += $reference
        }
    }

    $variablesOk = $missingVariables.Count -eq 0
    if ($variableReferences.Count -eq 0) {
        Write-Check -Passed $true -SuccessMessage 'No {Global.*} references found in agent.mcs.yml.' -FailureMessage ''
    }
    else {
        Write-Check -Passed $variablesOk -SuccessMessage 'All referenced global variables have YAML definitions.' -FailureMessage ("Missing variable definitions: {0}" -f ($missingVariables -join ', '))
        if (-not $variablesOk) { $allPassed = $false }
    }

    if ($allPassed) {
        Write-Host ''
        Write-Host 'Preflight passed.' -ForegroundColor Green
        exit 0
    }

    Write-Host ''
    Write-Host 'Preflight completed with warnings.' -ForegroundColor Yellow
    exit 1
}
catch {
    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
