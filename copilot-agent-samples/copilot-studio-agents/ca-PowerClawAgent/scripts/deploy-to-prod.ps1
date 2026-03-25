<#
.SYNOPSIS
    Deploys PowerClaw flows to the Prod environment with correct URLs.

.DESCRIPTION
    Automates the full pipeline: Export → Unpack → Inject (with Prod values) → Pack → Import.
    Replaces placeholder URLs (contoso.sharepoint.com) with actual Prod values.
    Optionally rebuilds the distributable PowerClaw_Solution.zip with placeholders.

.PARAMETER SiteUrl
    The SharePoint site URL for the target environment.
    Default: https://m365cpi23966391.sharepoint.com/sites/PowerClaw-Workspace

.PARAMETER AdminEmail
    The admin email for the target environment.
    Default: admin@M365CPI23966391.onmicrosoft.com

.PARAMETER RebuildZip
    Also rebuild PowerClaw_Solution.zip with placeholder URLs for distribution.

.EXAMPLE
    .\scripts\deploy-to-prod.ps1
    .\scripts\deploy-to-prod.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/PowerClaw" -AdminEmail "admin@contoso.com"
    .\scripts\deploy-to-prod.ps1 -RebuildZip
#>
param(
    [string]$SiteUrl = "https://m365cpi23966391.sharepoint.com/sites/PowerClaw-Workspace",
    [string]$AdminEmail = "admin@M365CPI23966391.onmicrosoft.com",
    [switch]$RebuildZip
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = (Get-Item $scriptDir).Parent.FullName
$placeholderUrl = "https://contoso.sharepoint.com/sites/PowerClaw-Workspace"
$placeholderEmail = "admin@contoso.com"

$flows = @(
    @{ local = "HeartbeatFlow-04cf2235-af1c-f111-88b1-6045bd0079f1"; unpacked = "HeartbeatFlow-04CF2235-AF1C-F111-88B1-6045BD0079F1" },
    @{ local = "GetContext-ff84c862-c7f6-819b-5ec6-7201f9389c85"; unpacked = "GetContext-FF84C862-C7F6-819B-5EC6-7201F9389C85" },
    @{ local = "Housekeeping-fca80a5d-72c0-fb6b-dbc9-eb8b74fdba44"; unpacked = "Housekeeping-FCA80A5D-72C0-FB6B-DBC9-EB8B74FDBA44" }
)

Write-Host "`n🦀 PowerClaw Deploy-to-Prod" -ForegroundColor Cyan
Write-Host "   Site: $SiteUrl"
Write-Host "   Email: $AdminEmail"
Write-Host ""

# Step 1: Export
Write-Host "📦 Exporting solution..." -ForegroundColor Yellow
pac solution export --name PowerClaw --path "$base\PowerClaw_export.zip" --overwrite 2>&1 | Out-Null
if (-not (Test-Path "$base\PowerClaw_export.zip")) { throw "Export failed" }
Write-Host "   ✅ Exported" -ForegroundColor Green

# Step 2: Unpack
Write-Host "📂 Unpacking..." -ForegroundColor Yellow
if (Test-Path "$base\PowerClaw_unpacked") { Remove-Item "$base\PowerClaw_unpacked" -Recurse -Force }
pac solution unpack -z "$base\PowerClaw_export.zip" -f "$base\PowerClaw_unpacked" --allowWrite --allowDelete --clobber 2>&1 | Out-Null
Write-Host "   ✅ Unpacked" -ForegroundColor Green

# Step 3: Inject flows with Prod values
Write-Host "💉 Injecting flows with Prod values..." -ForegroundColor Yellow
foreach ($flow in $flows) {
    $localPath = "$base\PowerClaw\workflows\$($flow.local)\workflow.json"
    if (-not (Test-Path $localPath)) {
        Write-Host "   ⏭️  Skipping $($flow.local) (not found locally)" -ForegroundColor DarkYellow
        continue
    }

    $localContent = Get-Content $localPath -Raw -Encoding UTF8
    $prodContent = $localContent -replace [regex]::Escape($placeholderUrl), $SiteUrl
    $prodContent = $prodContent -replace [regex]::Escape($placeholderEmail), $AdminEmail
    $prodJson = $prodContent | ConvertFrom-Json
    $unpackedPath = "$base\PowerClaw_unpacked\Workflows\$($flow.unpacked).json"
    $unpackedJson = Get-Content $unpackedPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $unpackedJson.properties.definition = $prodJson.properties.definition
    $unpackedJson | ConvertTo-Json -Depth 100 | Set-Content $unpackedPath -Encoding UTF8

    # Verify no placeholders remain
    $check = Get-Content $unpackedPath -Raw
    $remaining = ([regex]::Matches($check, 'contoso\.sharepoint\.com')).Count
    if ($remaining -gt 0) { Write-Host "   ⚠️  WARNING: $remaining placeholder URLs remain in $($flow.local)" -ForegroundColor Red }
    else { Write-Host "   ✅ $($flow.local)" -ForegroundColor Green }
}

# Step 3b: Inject Bootstrap flow
Write-Host "💉 Injecting Bootstrap flow..." -ForegroundColor Yellow
python "$scriptDir\build-bootstrap-flow.py" "$base\PowerClaw_unpacked" --flow-name "Bootstrap" 2>&1 | Out-Null
# Fallback: direct injection if script can't find the flow
$bsPath = "$base\PowerClaw_unpacked\Workflows\Bootstrap-B927E94B-4651-DFE8-00EB-A2E34D3EE199.json"
if (Test-Path $bsPath) {
    python -c "
import json, importlib.util, pathlib
spec = importlib.util.spec_from_file_location('bbf', r'$scriptDir\build-bootstrap-flow.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
with open(r'$bsPath', encoding='utf-8-sig') as f:
    wf = json.load(f)
wf['properties']['definition'] = mod.BOOTSTRAP_DEFINITION
mod.ensure_sharepoint_connection_reference(wf, pathlib.Path(r'$base\PowerClaw'))
with open(r'$bsPath', 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>&1 | Out-Null
    Write-Host "   ✅ Bootstrap" -ForegroundColor Green
}

# Step 4: Pack
Write-Host "📦 Packing solution..." -ForegroundColor Yellow
Remove-Item "$base\PowerClaw_updated.zip" -Force -ErrorAction SilentlyContinue
pac solution pack -z "$base\PowerClaw_updated.zip" -f "$base\PowerClaw_unpacked" -p Unmanaged 2>&1 | Out-Null
Write-Host "   ✅ Packed" -ForegroundColor Green

# Step 5: Import
Write-Host "🚀 Importing to Power Platform..." -ForegroundColor Yellow
pac solution import -p "$base\PowerClaw_updated.zip" -f -pc 2>&1 | ForEach-Object {
    if ($_ -match "error|fail") { Write-Host "   ❌ $_" -ForegroundColor Red }
    elseif ($_ -match "success|Published") { Write-Host "   ✅ $_" -ForegroundColor Green }
}

# Step 6: Optionally rebuild distributable zip
if ($RebuildZip) {
    Write-Host "`n📦 Rebuilding PowerClaw_Solution.zip (with placeholders)..." -ForegroundColor Yellow
    # Re-inject with placeholder URLs
    foreach ($flow in $flows) {
        $localPath = "$base\PowerClaw\workflows\$($flow.local)\workflow.json"
        if (-not (Test-Path $localPath)) { continue }
        $localContent = Get-Content $localPath -Raw -Encoding UTF8
        $localJson = $localContent | ConvertFrom-Json
        $unpackedPath = "$base\PowerClaw_unpacked\Workflows\$($flow.unpacked).json"
        $unpackedJson = Get-Content $unpackedPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $unpackedJson.properties.definition = $localJson.properties.definition
        $unpackedJson | ConvertTo-Json -Depth 100 | Set-Content $unpackedPath -Encoding UTF8
    }
    Remove-Item "$base\PowerClaw_Solution.zip" -Force -ErrorAction SilentlyContinue
    pac solution pack -z "$base\PowerClaw_Solution.zip" -f "$base\PowerClaw_unpacked" -p Unmanaged 2>&1 | Out-Null
    $size = [math]::Round((Get-Item "$base\PowerClaw_Solution.zip").Length / 1KB, 1)
    Write-Host "   ✅ PowerClaw_Solution.zip (${size} KB)" -ForegroundColor Green
}

# Cleanup
Remove-Item "$base\PowerClaw_updated.zip", "$base\PowerClaw_export.zip" -Force -ErrorAction SilentlyContinue

Write-Host "`n🦀 Deploy complete! Turn on your flows in Power Automate." -ForegroundColor Cyan
Write-Host ""
