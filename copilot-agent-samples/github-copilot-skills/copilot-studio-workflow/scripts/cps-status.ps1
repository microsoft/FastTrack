[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

function Find-AgentFile {
    param([string]$StartPath)

    $resolved = (Resolve-Path -LiteralPath $StartPath).Path
    Get-ChildItem -Path $resolved -Recurse -File -Filter 'agent.mcs.yml' -Depth 6 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
        Sort-Object FullName |
        Select-Object -First 1
}

function Get-AgentName {
    param([string]$AgentFile)

    $content = Get-Content -LiteralPath $AgentFile
    $displayMatch = $content | Select-String -Pattern '^\s*displayName\s*:\s*"?(?<Value>.+?)"?\s*$' | Select-Object -First 1
    if ($displayMatch) {
        return $displayMatch.Matches[0].Groups['Value'].Value.Trim()
    }

    $nameMatch = $content | Select-String -Pattern '^\s*name\s*:\s*"?(?<Value>.+?)"?\s*$' | Select-Object -First 1
    if ($nameMatch) {
        return $nameMatch.Matches[0].Groups['Value'].Value.Trim()
    }

    return '(name not found)'
}

function Get-Count {
    param(
        [string]$Root,
        [string]$RelativePath,
        [string]$Filter
    )

    $target = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $target)) {
        return 0
    }

    return (Get-ChildItem -Path $target -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue).Count
}

try {
    $agentFile = Find-AgentFile -StartPath $Path
    if (-not $agentFile) {
        throw "No agent.mcs.yml file found within 6 levels of '$Path'."
    }

    $agentRoot = Split-Path -Parent $agentFile.FullName
    $agentName = Get-AgentName -AgentFile $agentFile.FullName
    $topicCount = Get-Count -Root $agentRoot -RelativePath 'topics' -Filter '*.mcs.yml'
    $actionCount = Get-Count -Root $agentRoot -RelativePath 'actions' -Filter '*.mcs.yml'
    $variableCount = Get-Count -Root $agentRoot -RelativePath 'variables' -Filter '*.mcs.yml'
    $workflowCount = Get-Count -Root $agentRoot -RelativePath 'workflows' -Filter '*.json'

    $repoRoot = $null
    try {
        $repoRoot = (& git -C $agentRoot rev-parse --show-toplevel 2>$null).Trim()
    }
    catch {
        $repoRoot = $null
    }

    $gitStatus = @()
    $dirtyWorkflowFiles = @()
    if ($repoRoot) {
        $gitStatus = @(& git -C $repoRoot status --porcelain 2>$null)
        $dirtyWorkflowFiles = @($gitStatus |
            ForEach-Object { if ($_ -match '^..\s+(?<Path>.+)$') { $Matches['Path'].Trim() } } |
            Where-Object { $_ -and ($_ -match '(^|[\\/])workflows[\\/].+\.json$' -or $_ -match '(^|[\\/])settings\.mcs\.yml$') })
    }

    $pacVersion = $null
    try {
        $pacOutput = @(& pac --version 2>$null)
        $pacVersionLine = $pacOutput | Where-Object { $_ -match '^Version:\s*' } | Select-Object -First 1
        if ($pacVersionLine -match '^Version:\s*(?<Value>.+)$') {
            $pacVersion = $Matches['Value'].Trim()
        }
        elseif ($pacOutput.Count -gt 0) {
            $pacVersion = $pacOutput[0].Trim()
        }

        if ([string]::IsNullOrWhiteSpace($pacVersion)) {
            $pacVersion = $null
        }
    }
    catch {
        $pacVersion = $null
    }

    $gitVersion = $null
    try {
        $gitVersion = (& git --version 2>$null | Select-Object -First 1)
        if ($gitVersion -match '^git version\s+(?<Value>.+)$') {
            $gitVersion = $Matches['Value'].Trim()
        }
        if ([string]::IsNullOrWhiteSpace($gitVersion)) {
            $gitVersion = $null
        }
    }
    catch {
        $gitVersion = $null
    }

    $vsCodeVersion = $null
    try {
        $vsCodeVersion = (& code --version 2>$null | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($vsCodeVersion)) {
            $vsCodeVersion = $null
        }
    }
    catch {
        $vsCodeVersion = $null
    }

    $powerShellVersion = $PSVersionTable.PSVersion.ToString()

    Write-Host 'Copilot Studio Project Status' -ForegroundColor Green
    Write-Host '-----------------------------' -ForegroundColor Green
    Write-Host ("Agent Name      : {0}" -f $agentName)
    Write-Host ("Agent Root      : {0}" -f $agentRoot)
    Write-Host ("Agent File      : {0}" -f $agentFile.FullName)

    Write-Section 'Counts'
    Write-Host ("Topics          : {0}" -f $topicCount)
    Write-Host ("Actions         : {0}" -f $actionCount)
    Write-Host ("Variables       : {0}" -f $variableCount)
    Write-Host ("Workflows       : {0}" -f $workflowCount)

    Write-Section 'Git'
    if ($repoRoot) {
        Write-Host ("Repository Root : {0}" -f $repoRoot)
        Write-Host ("Modified Files  : {0}" -f $gitStatus.Count)
        if ($dirtyWorkflowFiles.Count -gt 0) {
            Write-Host 'Dirty workflow files detected:' -ForegroundColor Yellow
            $dirtyWorkflowFiles | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
        }
        else {
            Write-Host 'Dirty workflow files: none' -ForegroundColor Green
        }
    }
    else {
        Write-Host 'Git repository  : not detected' -ForegroundColor Yellow
    }

    Write-Section 'Tooling'
    if ($pacVersion) {
        Write-Host ("pac CLI         : {0}" -f $pacVersion) -ForegroundColor Green
    }
    else {
        Write-Host 'pac CLI         : not installed or not on PATH' -ForegroundColor Yellow
    }

    Write-Section 'Dependencies'
    if ($gitVersion) {
        Write-Host ("Git             : {0}" -f $gitVersion) -ForegroundColor Green
    }
    else {
        Write-Host 'Git             : not installed or not on PATH' -ForegroundColor Yellow
    }

    if ($vsCodeVersion) {
        Write-Host ("VS Code         : {0}" -f $vsCodeVersion) -ForegroundColor Green
    }
    else {
        Write-Host 'VS Code         : not on PATH' -ForegroundColor Yellow
    }

    Write-Host ("PowerShell      : {0}" -f $powerShellVersion) -ForegroundColor Green

    if ($pacVersion) {
        Write-Host ("pac CLI         : {0}" -f $pacVersion) -ForegroundColor Green
    }
    else {
        Write-Host 'pac CLI         : not installed' -ForegroundColor Yellow
    }
}
catch {
    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
