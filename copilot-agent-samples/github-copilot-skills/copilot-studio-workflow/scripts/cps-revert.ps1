[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path,
    [switch]$DryRun
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

try {
    $agentFile = Find-AgentFile -StartPath $Path
    if (-not $agentFile) {
        throw "No agent.mcs.yml file found within 6 levels of '$Path'."
    }

    $agentRoot = Split-Path -Parent $agentFile.FullName
    $repoRoot = (& git -C $agentRoot rev-parse --show-toplevel 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($repoRoot)) {
        throw 'Git repository not detected.'
    }

    $modifiedFiles = @(& git -C $repoRoot diff --name-only 2>$null)
    $targets = @($modifiedFiles | Where-Object {
        $_ -and ($_ -match '(^|[\\/])workflows[\\/].+\.json$' -or $_ -match '(^|[\\/])settings\.mcs\.yml$')
    })

    if ($targets.Count -eq 0) {
        Write-Host 'No modified workflow or settings files found.' -ForegroundColor Green
        exit 0
    }

    if ($DryRun) {
        Write-Host 'Files that would be reverted:' -ForegroundColor Yellow
        $targets | ForEach-Object { Write-Host ("  - {0}" -f $_) }
        exit 0
    }

    foreach ($target in $targets) {
        & git -C $repoRoot checkout -- $target | Out-Null
        Write-Host ("Reverted {0}" -f $target) -ForegroundColor Green
    }

    Write-Host ("Reverted {0} file(s)." -f $targets.Count) -ForegroundColor Green
}
catch {
    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
