[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SolutionName,

    [Parameter(Mandatory = $true)]
    [string]$SchemaPattern
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Pac {
    try {
        $version = (& pac --version 2>$null | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($version)) {
            throw 'pac CLI returned no version information.'
        }

        Write-Host ("Using pac CLI {0}" -f $version) -ForegroundColor Green
    }
    catch {
        throw 'pac CLI is required. Install it and ensure `pac --version` succeeds.'
    }
}

function Parse-FetchOutput {
    param([string[]]$Lines)

    $results = @()
    foreach ($line in $Lines) {
        if ($line -match '^[\s\-]+$') { continue }
        if ($line -match 'botcomponentid' -and $line -match 'schemaname') { continue }
        if ($line -match '(?<Id>[0-9a-fA-F-]{36}).*?(?<Schema>auto_[A-Za-z0-9_\.\-]+|[A-Za-z0-9_\.\-]+)') {
            $results += [pscustomobject]@{
                Id = $Matches['Id']
                SchemaName = $Matches['Schema']
                Raw = $line.Trim()
            }
        }
    }

    return $results | Sort-Object SchemaName -Unique
}

try {
    Require-Pac

    $escapedPattern = [System.Security.SecurityElement]::Escape($SchemaPattern)
    $fetchXml = @"
<fetch>
  <entity name='botcomponent'>
    <attribute name='botcomponentid' />
    <attribute name='schemaname' />
    <attribute name='name' />
    <filter>
      <condition attribute='schemaname' operator='like' value='%$escapedPattern%' />
    </filter>
  </entity>
</fetch>
"@

    Write-Host ("Searching botcomponents matching '{0}'..." -f $SchemaPattern) -ForegroundColor Cyan
    $fetchOutput = @(& pac org fetch -x $fetchXml 2>&1)
    $matches = @(Parse-FetchOutput -Lines $fetchOutput)

    if ($matches.Count -eq 0) {
        Write-Host 'No matching botcomponents found.' -ForegroundColor Red
        Write-Host 'Suggestions:' -ForegroundColor Yellow
        Write-Host '  - Check your pac auth connection and environment'
        Write-Host '  - Try a broader schema pattern'
        Write-Host '  - Verify the component was created by pushing from VS Code'
        exit 1
    }

    if ($matches.Count -gt 1) {
        Write-Host 'Multiple matching botcomponents found. Be more specific.' -ForegroundColor Yellow
        $matches | ForEach-Object { Write-Host ("  - {0}  [{1}]" -f $_.SchemaName, $_.Id) }
        exit 1
    }

    $component = $matches[0]
    Write-Host ("Adding {0} to solution {1}..." -f $component.SchemaName, $SolutionName) -ForegroundColor Cyan
    $addOutput = @(& pac solution add-solution-component -sn $SolutionName -c $component.Id -ct botcomponent 2>&1)

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Failed to add solution component.' -ForegroundColor Red
        $addOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    Write-Host ("Added {0} [{1}] to solution {2}." -f $component.SchemaName, $component.Id, $SolutionName) -ForegroundColor Green
}
catch {
    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
