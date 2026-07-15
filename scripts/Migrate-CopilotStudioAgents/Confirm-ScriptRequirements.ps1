<#
.SYNOPSIS
    Shared pre-flight check for the CopilotStudioAgentScripts toolkit: confirms the 'pac'
    CLI and/or the MSAL.PS PowerShell module are installed BEFORE a script does any real
    work, and offers to install whichever is missing (with the user's explicit
    confirmation) instead of just throwing and leaving the user to go figure out the fix
    themselves.

.DESCRIPTION
    Dot-source this file, then call Assert-ScriptRequirements with -RequirePac and/or
    -RequireMsalPs. For each requirement: checks if it's already present; if not,
    explains what's missing and asks (Y/n) to install it now; on agreement, installs and
    re-checks; on decline or a failed install, throws with manual install instructions so
    the calling script stops cleanly here instead of failing later with a more confusing
    error deep in its own logic.
#>

function Assert-ScriptRequirements {
    [CmdletBinding()]
    param(
        [switch]$RequirePac,
        [switch]$RequireMsalPs
    )

    if ($RequirePac) {
        # Make sure a freshly-installed pac (via winget/MSI) is on PATH even in a fresh
        # session - installers register PATH at the Machine/User level, but the current
        # process won't pick that up until Path is re-read from the environment.
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path', 'User')

        if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
            Write-Host "`nRequired tool 'pac' (Power Platform CLI) was not found on PATH." -ForegroundColor Yellow
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                throw "pac CLI not found, and winget isn't available to install it automatically. Install manually: winget install --id Microsoft.PowerAppsCLI -e, then run 'pac install latest'."
            }
            $answer = Read-Host "Install it now via 'winget install --id Microsoft.PowerAppsCLI -e' (then 'pac install latest')? (Y/n)"
            if ($answer -match '^n') {
                throw "pac CLI is required. Install with: winget install --id Microsoft.PowerAppsCLI -e, then run 'pac install latest'."
            }

            Write-Host "Installing Power Platform CLI via winget..." -ForegroundColor Cyan
            winget install --id Microsoft.PowerAppsCLI -e --accept-package-agreements --accept-source-agreements
            Write-Host "Running 'pac install latest' to fetch the latest pac tooling..." -ForegroundColor Cyan
            & pac install latest

            $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                        [System.Environment]::GetEnvironmentVariable('Path', 'User')
            if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
                throw "pac CLI still isn't found on PATH after installation - you may need to close and reopen your terminal/PowerShell session (so it picks up the updated PATH) and re-run this script."
            }
            Write-Host "pac CLI installed successfully.`n" -ForegroundColor Green
        }
    }

    if ($RequireMsalPs) {
        if (-not (Get-Module -ListAvailable MSAL.PS)) {
            Write-Host "`nRequired PowerShell module 'MSAL.PS' was not found." -ForegroundColor Yellow
            $answer = Read-Host "Install it now via 'Install-Module MSAL.PS -Scope CurrentUser'? (Y/n)"
            if ($answer -match '^n') {
                throw "MSAL.PS module is required. Install with: Install-Module MSAL.PS -Scope CurrentUser"
            }

            Write-Host "Installing MSAL.PS (current user scope)..." -ForegroundColor Cyan
            Install-Module MSAL.PS -Scope CurrentUser -Force -AllowClobber
            if (-not (Get-Module -ListAvailable MSAL.PS)) {
                throw "MSAL.PS still isn't found after the installation attempt - install manually: Install-Module MSAL.PS -Scope CurrentUser"
            }
            Write-Host "MSAL.PS installed successfully.`n" -ForegroundColor Green
        }
    }
}
