#requires -Version 7.0
<#
.SYNOPSIS
    Gather Microsoft 365 Copilot interaction history for a tenant and build a
    self-contained HTML usage dashboard.

.DESCRIPTION
    Thin orchestrator over the CopilotAnalytics module. It authenticates to
    Microsoft Graph app-only (client secret OR certificate), exports each
    Copilot-licensed user's enterprise interaction history to JSON, and then
    renders a single HTML report.

    The Entra app registration used must hold these Graph APPLICATION
    permissions (with admin consent granted):
        AiEnterpriseInteraction.Read.All
        User.Read.All
        Organization.Read.All

    Requires PowerShell 7+.

.PARAMETER TenantId
    Directory (tenant) ID. Falls back to $env:AZURE_TENANT_ID.

.PARAMETER ClientId
    Application (client) ID of the app registration. Falls back to
    $env:AZURE_CLIENT_ID.

.PARAMETER ClientSecret
    Client secret value. Falls back to $env:AZURE_CLIENT_SECRET. Use this OR a
    certificate, not both.

.PARAMETER CertificatePath
    Path to a .pfx certificate file (app-only certificate auth).

.PARAMETER CertificatePassword
    SecureString password for the .pfx in -CertificatePath (if protected).

.PARAMETER CertificateThumbprint
    Thumbprint of a certificate already installed in the CurrentUser or
    LocalMachine "My" store.

.PARAMETER SkuId
    License SKU id to enumerate. Defaults to Microsoft 365 Copilot
    (639dec6b-bb19-468b-871c-c5c441c4b0cb). Find others with /v1.0/subscribedSkus.

.PARAMETER SinceDays
    Only include interactions newer than this many days. Default 7. Use 0 for
    no date filter.

.PARAMETER MaxUsers
    Cap the number of users exported (handy for a quick test). 0 = all.

.PARAMETER DataDir
    Directory for the per-user JSON export. Default .\data\interactions.

.PARAMETER OutputPath
    Path of the HTML report to write. Default .\copilot-report.html.

.PARAMETER SkipExport
    Skip the Graph export and rebuild the HTML report from JSON already in
    -DataDir.

.EXAMPLE
    # Client-secret auth, last 30 days
    .\New-CopilotInteractionReport.ps1 -TenantId <tid> -ClientId <cid> `
        -ClientSecret <secret> -SinceDays 30

.EXAMPLE
    # Certificate (from the Windows cert store), all licensed users
    .\New-CopilotInteractionReport.ps1 -TenantId <tid> -ClientId <cid> `
        -CertificateThumbprint A1B2C3... -SinceDays 30

.EXAMPLE
    # Rebuild the report only, from a previous export
    .\New-CopilotInteractionReport.ps1 -SkipExport -DataDir .\data\interactions
#>
[CmdletBinding(DefaultParameterSetName = 'Secret')]
param(
    [string]$TenantId = $env:AZURE_TENANT_ID,
    [string]$ClientId = $env:AZURE_CLIENT_ID,

    [Parameter(ParameterSetName = 'Secret')]
    [string]$ClientSecret = $env:AZURE_CLIENT_SECRET,

    [Parameter(Mandatory, ParameterSetName = 'CertFile')]
    [string]$CertificatePath,
    [Parameter(ParameterSetName = 'CertFile')]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory, ParameterSetName = 'CertStore')]
    [string]$CertificateThumbprint,

    [string]$SkuId = '639dec6b-bb19-468b-871c-c5c441c4b0cb',
    [int]$SinceDays = 7,
    [int]$MaxUsers = 0,
    [string]$DataDir = (Join-Path '.' 'data\interactions'),
    [string]$OutputPath = (Join-Path '.' 'copilot-report.html'),
    [switch]$SkipExport
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CopilotAnalytics.psm1') -Force

if (-not $SkipExport) {
    if (-not $TenantId) { throw 'TenantId is required (parameter or $env:AZURE_TENANT_ID).' }
    if (-not $ClientId) { throw 'ClientId is required (parameter or $env:AZURE_CLIENT_ID).' }

    $cert = $null
    switch ($PSCmdlet.ParameterSetName) {
        'CertFile' {
            if (-not (Test-Path $CertificatePath)) { throw "Certificate file not found: $CertificatePath" }
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                (Resolve-Path $CertificatePath).Path, $CertificatePassword)
        }
        'CertStore' {
            $cert = Get-ChildItem -Path Cert:\CurrentUser\My, Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
                Where-Object { $_.Thumbprint -eq $CertificateThumbprint.Replace(' ', '') } | Select-Object -First 1
            if (-not $cert) { throw "No certificate with thumbprint $CertificateThumbprint in CurrentUser/LocalMachine My store." }
        }
        default {
            if (-not $ClientSecret) { throw 'Provide -ClientSecret (or $env:AZURE_CLIENT_SECRET), or use a certificate parameter set.' }
        }
    }

    if ($cert) {
        $ctx = New-GraphContext -TenantId $TenantId -ClientId $ClientId -Certificate $cert
    }
    else {
        $ctx = New-GraphContext -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    }

    $exp = Export-CopilotInteractions -Context $ctx -OutDir $DataDir -SinceDays $SinceDays -SkuId $SkuId -MaxUsers $MaxUsers
    Write-Host "Exported $($exp.Files) file(s) for $($exp.Users) user(s) to $($exp.OutDir)." -ForegroundColor Green
}
else {
    Write-Host "Skipping export; building report from $DataDir." -ForegroundColor Yellow
}

$res = Build-CopilotReport -InputDir $DataDir -OutHtml $OutputPath
Write-Host ""
Write-Host "Report written: $($res.Out)" -ForegroundColor Green
Write-Host ("  {0} users  |  {1} active  |  {2} interactions  |  {3} sessions" -f `
    $res.Users, $res.Active, $res.Interactions, $res.Sessions)
