<#
.SYNOPSIS
  Checks a tenant's technical readiness for Copilot for Microsoft 365.

.DESCRIPTION
  - Installs required modules if needed (CurrentUser scope).
  - Connects to Microsoft Graph, Exchange Online, Microsoft Teams, and SharePoint Online (best effort).
  - Gathers signals aligned to Microsoft Learn "requirements", "enablement", and "license options".
  - Produces JSON and HTML reports with readiness flags, guidance, and captured errors.

.OUTPUTS
  copilot-readiness.json
  copilot-readiness.html

.REFERENCES
  Requirements: https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements
  Enablement:  https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-enablement-resources
  Licensing:   https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-licensing
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$OutputPath = ".",

  [Parameter()]
  [switch]$SkipModuleInstall,

  [string]$SPOAdminUrl
)
# Increase function capacity before loading any modules
if (Get-Variable -Name MaximumFunctionCount -Scope Global -ErrorAction SilentlyContinue) {
    if ($Global:MaximumFunctionCount -lt 32768) { $Global:MaximumFunctionCount = 32768 }
} else {
    Set-Variable -Name MaximumFunctionCount -Scope Global -Value 32768 -Option AllScope
}

# Check for function capacity warning in previous session
if ($global:FunctionCapacityWarning) {
    Write-Warn "Function capacity exceeded in previous session. Please restart PowerShell and run this script in a fresh session."
}

#region Helpers
function Write-Info($msg){ Write-Host "[INFO ] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Warning $msg }
function Write-Err ($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Ensure-Module {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter()][string]$MinimumVersion = ""
  )
  try {
    $installed = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    $loaded = Get-Module -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    $needInstall = $false
    if (-not $installed) { $needInstall = $true }
    elseif ($MinimumVersion -and ([Version]$installed.Version -lt [Version]$MinimumVersion)) { $needInstall = $true }

    if ($needInstall) {
      if ($loaded) {
        Write-Warn "Module $Name is currently loaded in this session. Please close all PowerShell windows and re-run the script to update or install the module."
        throw "Module $Name is loaded and cannot be updated."
      }
      if ($SkipModuleInstall) { Write-Warn "Module $Name not found or too old. -SkipModuleInstall set; continuing without installing."; return }
      Write-Info "Installing module $Name (scope: CurrentUser)..."
      $params = @{ Name=$Name; Scope='CurrentUser'; Force=$true; AllowClobber=$true }
      if ($MinimumVersion) { $params['MinimumVersion'] = $MinimumVersion }
      Install-Module @params -ErrorAction Stop
    } else {
      Write-Info "Module $Name OK (v$($installed.Version))"
    }
  } catch {
    Write-Err "Failed to ensure module $Name. $($_.Exception.Message)"
    throw
  }
}

function Try-Connect {
  param(
    [Parameter(Mandatory=$true)][scriptblock]$Script,
    [string]$Name
  )
  $result = @{
    Name = $Name
    Success = $false
    Error = $null
  }
  try {
    & $Script
    $result.Success = $true
  } catch {
    $result.Error = $_.Exception.Message
    Write-Warn "$Name connect failed: $($result.Error)"
  }
  return $result
}
#endregion Helpers

$scriptStart = Get-Date
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Ensure-Directory -Path $OutputPath

$errors = @()
$warnings = @()

# Required modules & minimum versions (tune as needed)
$requiredModules = @(
  @{ Name='Microsoft.Graph.Authentication';               MinimumVersion='2.8.0' },
  @{ Name='Microsoft.Graph.Identity.DirectoryManagement'; MinimumVersion='2.8.0' },
  @{ Name='Microsoft.Graph.Search';                      MinimumVersion='2.8.0' },
  @{ Name='ExchangeOnlineManagement';                    MinimumVersion='3.4.0' },
  @{ Name='MicrosoftTeams';                             MinimumVersion='5.6.0' },
  @{ Name='Microsoft.Online.SharePoint.PowerShell';      MinimumVersion='16.0.24908.12000' }
)

foreach ($m in $requiredModules) {
  try {
    Ensure-Module -Name $m.Name -MinimumVersion $m.MinimumVersion
    if ($m.Name -eq 'Microsoft.Online.SharePoint.PowerShell') {
      Import-Module $m.Name -DisableNameChecking -ErrorAction Stop | Out-Null
    } else {
      Import-Module $m.Name -ErrorAction Stop | Out-Null
    }
  } catch {
    $msg = "Module load failed: $($m.Name). $($_.Exception.Message)"
    Write-Warn $msg
    $errors += $msg
  }
  try { Select-MgProfile -Name "v1.0" -ErrorAction SilentlyContinue } catch {}
}

# Connect to services (best effort)
$ctx = [ordered]@{
  Graph   = $false
  EXO     = $false
  Teams   = $false
  SPO     = $false
}

# Initialize these in script scope, not global
$script:org      = $null
$script:skus     = @()
$script:spoAdmin = $null

# Graph connection section
Write-Info "Connecting to Microsoft Graph..."
$graphScopes = @(
    'Organization.Read.All',
    'Directory.Read.All',
    'User.Read.All',
    'ExternalItem.Read.All',
    'Sites.Read.All',
    'ExternalConnection.Read.All',
    'Policy.Read.All'
)
$graphTimeoutSec = 60
$graphStart = Get-Date
$graphConnected = $false
$gError = $null

try {
    while ((New-TimeSpan -Start $graphStart -End (Get-Date)).TotalSeconds -lt $graphTimeoutSec -and -not $graphConnected) {
        Write-host "[INFO ] Attempting Microsoft Graph connection..." -ForegroundColor Cyan
        try {
            Connect-MgGraph -Scopes $graphScopes -ErrorAction Stop | Out-Null
            Write-Info "Getting organization details..."
            $script:org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
            Write-Info "Getting license details..."
            $script:skus = Get-MgSubscribedSku -All -ErrorAction Stop
            $graphConnected = $true
            Write-Info "Graph connection successful. Found $($skus.Count) licenses."
        } catch {
            $gError = $_.Exception.Message
            Write-host "[WARN ] Microsoft Graph connection not yet successful: $gError" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
} catch {
    $gError = "Graph connection loop failed: $($_.Exception.Message)"
}

$ctx.Graph = $graphConnected
if (-not $ctx.Graph) {
    $errors += "Graph connect: $gError"
    Write-Warn "Microsoft Graph connection failed after $graphTimeoutSec seconds. Please check authentication and network connectivity."
}

# Derive SPO Admin URL only if not provided as parameter
if (-not $SPOAdminUrl) {
    Write-Info "No SharePoint Admin URL provided, attempting to derive from tenant details..."
    try {
        # Try to get the initial domain (onmicrosoft.com) instead of custom domains
        $initialDomain = $org.VerifiedDomains | Where-Object { $_.Name -like "*.onmicrosoft.com" } | Select-Object -First 1
        if ($initialDomain) {
            $tenantName = ($initialDomain.Name -split '\.')[0]
            $spoAdminUrl = "https://$tenantName-admin.sharepoint.com"
            Write-Info "Derived SharePoint Admin URL: $spoAdminUrl"
        } else {
            Write-Warn "Could not find initial domain (*.onmicrosoft.com) in verified domains"
        }
    } catch {
        Write-Warn "Failed to derive SharePoint Admin URL: $($_.Exception.Message)"
    }
} else {
    $spoAdminUrl = $SPOAdminUrl
    Write-Info "Using provided SharePoint Admin URL: $spoAdminUrl"
}

# Initialize SharePoint/OneDrive signals before use
$spoInfo = [ordered]@{
    Connected       = $false
    AdminUrl        = $spoAdminUrl  # Set the admin URL here
    TenantProperties= $null
    TotalSites      = 0
    OneDriveSites   = 0
    Notes           = $null
    SharingSettings    = $null
    RacPolicySites     = @()
    RestrictedSites    = @()
}

# SharePoint connection section
Write-Info "Connecting to SharePoint Online..."
if ($spoAdminUrl) {
    # Try modern auth first, then fall back to interactive
    $s = Try-Connect -Name 'SharePoint Online' -Script {
        try {
            Connect-SPOService -Url $spoAdminUrl -ErrorAction Stop
            Write-Info "Connected to SharePoint Online successfully"
            $true  # Return true for success
        } catch {
            Write-Info "Initial connection failed: $($_.Exception.Message)"
            # Don't try interactive - just fail
            throw
        }
    }
    
    if ($s.Success) {
        Write-Info "SharePoint connection successful"
        # Verify connection with a simple command
        try {
            $tenant = Get-SPOTenant -ErrorAction Stop
            if ($tenant) {
                $spoInfo.Connected = $true  # Set connection state here
                $ctx.SPO = $true           # Update context as well
                Write-Info "SharePoint tenant access confirmed"
            }
        } catch {
            $s.Success = $false
            $s.Error = "Connection succeeded but tenant access failed: $($_.Exception.Message)"
        }
    }
    
    if (-not $s.Success) { 
        $errors += "SPO connect: $($s.Error)"
        Write-Warn "SharePoint connection failed. Some checks will be skipped."
    }
} else {
    $msg = "No SharePoint Admin URL available. Please provide -SPOAdminUrl parameter."
    $warnings += $msg
    Write-Warn $msg
}

Write-Info "Connecting to Exchange Online..."
$e = Try-Connect -Name 'Exchange Online' -Script {
  Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null
}
$ctx.EXO = $e.Success
if (-not $ctx.EXO) { $errors += "EXO connect: $($e.Error)" }

Write-Info "Connecting to Microsoft Teams..."
$t = Try-Connect -Name 'Microsoft Teams' -Script {
  Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
}
$ctx.Teams = $t.Success
if (-not $ctx.Teams) { $errors += "Teams connect: $($t.Error)" }

# Data collection
Write-Info "Collecting data..."

# Org
$orgInfo = $null
try {
  if ($ctx.Graph -and $org) {
    $orgInfo = [ordered]@{
      DisplayName        = $org.DisplayName
      Id                 = $org.Id
      DefaultDomain      = $defaultDomain
      VerifiedDomains    = $org.VerifiedDomains | ForEach-Object { $_.Name }
      CountryLetterCode  = $org.CountryLetterCode
      TenantType         = $org.TenantType
    }
  } else {
    Write-Warn "Tenant details could not be retrieved from Microsoft Graph. Check your connection and permissions."
    $orgInfo = [ordered]@{
      DisplayName        = 'Unavailable'
      Id                 = 'Unavailable'
      DefaultDomain      = 'Unavailable'
      VerifiedDomains    = @('Unavailable')
      CountryLetterCode  = 'Unavailable'
      TenantType         = 'Unavailable'
    }
  }
} catch {
  $errors += "Org info: $($_.Exception.Message)"
  Write-Warn "Error retrieving tenant details: $($_.Exception.Message)"
  $orgInfo = [ordered]@{
    DisplayName        = 'Unavailable'
    Id                 = 'Unavailable'
    DefaultDomain      = 'Unavailable'
    VerifiedDomains    = @('Unavailable')
    CountryLetterCode  = 'Unavailable'
    TenantType         = 'Unavailable'
  }
}

# Licensing signals
# Update licensing info to include all relevant SKUs in report
$licensing = [ordered]@{
    CopilotSkuPresent = $false
    CopilotSkus = $null
    SubscribedSkus = $null
    EligibleBaseLicenses = @()
    AllRelevantSkus = @()  # New property to track all relevant SKUs
}

try {
    if ($skus) {
        Write-Info "Processing $($skus.Count) licenses..."
        
        # Known eligible base license patterns
        $baseSkuPatterns = @(
            'MICROSOFT_365_E[35].*',      # Match any M365 E3/E5 variant including (no_Teams)
            'SPE_E[35].*',               # Match any SPE E3/E5 variant
            'ENTERPRISEPACK',            # Office 365 E3
            'ENTERPRISEPREMIUM',         # Office 365 E5
            'O365_E[35].*'              # Match any O365 E3/E5 variant
        )
        
        # Check for base licenses first
        $baseLicenses = $skus | Where-Object {
            $sku = $_
            Write-Info "Checking license: $($sku.SkuPartNumber)"
            $found = $false
            foreach ($pattern in $baseSkuPatterns) {
                if ($sku.SkuPartNumber -match $pattern) {
                    Write-Info "  Found match on pattern '$pattern' with consumed units: $($sku.ConsumedUnits)"
                    $found = $true
                    break
                }
            }
            $found
        }

        # Debug output for base license detection
        if ($baseLicenses) {
            Write-Info "Found eligible base licenses:"
            $baseLicenses | ForEach-Object {
                Write-Info "  $($_.SkuPartNumber) [Consumed: $($_.ConsumedUnits), Enabled: $($_.PrepaidUnits.Enabled)]"
                $licensing.EligibleBaseLicenses = $baseLicenses | Where-Object { $_.ConsumedUnits -gt 0 } | Select-Object SkuPartNumber, ConsumedUnits, @{n='Enabled';e={$_.PrepaidUnits.Enabled}}
                Write-Info "EligibleBaseLicenses count: $($licensing.EligibleBaseLicenses.Count)"
                Write-Info "Consumed licenses present: $([bool]($licensing.EligibleBaseLicenses | Where-Object { $_.ConsumedUnits -gt 0 }))"
            }
        } else {
            Write-Warn "No eligible base licenses found in tenant"
        }

        # Existing Copilot license check
        $knownCopilotPatterns = @(
          'COPILOT',
          'CPI',
          'M365_COPILOT',
          'MICROSOFT_365_COPILOT',
          'COPILOT_MICROSOFT_365'
        )
        
        $copilotSkus = $skus | Where-Object {
          $sku = $_
          Write-Info "Checking SKU: $($sku.SkuPartNumber)"
          
          # More comprehensive matching
          $isMatch = $false
          
          # Check SKU part number against patterns
          foreach ($pattern in $knownCopilotPatterns) {
            if ($sku.SkuPartNumber -match $pattern) {
              Write-Info "  Found match on pattern: $pattern"
              $isMatch = $true
              break
            }
          }
          
          # Check service plans
          if (-not $isMatch) {
            $copilotPlans = $sku.ServicePlans | Where-Object { $_.ServicePlanName -match 'COPILOT|CPI' }
            if ($copilotPlans) {
              Write-Info "  Found Copilot service plans: $($copilotPlans.ServicePlanName -join ', ')"
              $isMatch = $true
            }
          }
          
          $isMatch
        }

        if ($copilotSkus) {
          Write-Info "Found $($copilotSkus.Count) Copilot-related licenses:"
          $copilotSkus | ForEach-Object {
            Write-Info "  $($_.SkuPartNumber): $($_.ConsumedUnits) consumed, $($_.PrepaidUnits.Enabled) enabled"
          }
          
          $licensing.CopilotSkuPresent = $true
          $licensing.CopilotSkus = $copilotSkus | Select-Object `
              SkuPartNumber, 
              SkuId, 
              ConsumedUnits,
              @{n='PrepaidEnabled';e={$_.PrepaidUnits.Enabled}},
              @{n='ServicePlans';e={($_.ServicePlans | Where-Object { $_.ServicePlanName -match 'COPILOT|CPI' }).ServicePlanName -join ', '}}
        }

        # Combine relevant SKUs for reporting
        $licensing.AllRelevantSkus = @()
        if ($baseLicenses) {
            $licensing.AllRelevantSkus += $baseLicenses | Select-Object SkuPartNumber, ConsumedUnits, 
                @{n='PrepaidEnabled';e={$_.PrepaidUnits.Enabled}},
                @{n='Type';e={'Base'}},
                @{n='ServicePlans';e={($_.ServicePlans | Select-Object -First 3).ServicePlanName -join ', '}}
        }
        if ($copilotSkus) {
            $licensing.AllRelevantSkus += $copilotSkus | Select-Object SkuPartNumber, ConsumedUnits,
                @{n='PrepaidEnabled';e={$_.PrepaidUnits.Enabled}},
                @{n='Type';e={'Copilot'}},
                @{n='ServicePlans';e={($_.ServicePlans | Where-Object { $_.ServicePlanName -match 'COPILOT|CPI' }).ServicePlanName -join ', '}}
        }
    } else {
        Write-Warn "No licenses found in tenant"
    }
} catch {
    $msg = "License processing failed: $($_.Exception.Message)"
    $errors += $msg
    Write-Err $msg
}

# Exchange Online signals
$exoInfo = [ordered]@{ Connected=$ctx.EXO; UserMailboxCount=$null; Notes=$null }
try {
  if ($ctx.EXO) {
    $exoInfo.UserMailboxCount = (Get-EXOMailbox -ResultSize 1000 -RecipientTypeDetails UserMailbox -ErrorAction SilentlyContinue).Count
  } else {
    $exoInfo.Notes = "Could not connect to Exchange Online."
  }
} catch {
  $errors += "EXO mailbox query failed: $($_.Exception.Message)"
}

# SharePoint/OneDrive signals
try {
  if ($ctx.SPO) {
    $tenantProps = Get-SPOTenant -ErrorAction Stop
    if ($tenantProps) {
      # Get standard properties
      $spoInfo.TenantProperties = $tenantProps | Select-Object `
        OneDriveStorageQuota, ConditionalAccessPolicy, ExternalUserExpirationRequired,
        SharingCapability, RestrictedAccessControl, ShowAllUsersClaim, EnableAzureADB2BIntegration

      # Get sharing settings
      $spoInfo.SharingSettings = [ordered]@{
        TenantSharingLevel     = @{
            Value = $tenantProps.SharingCapability
            Description = "Tenant-wide sharing level (Disabled, ExternalUserSharingOnly, ExistingExternalUserSharingOnly, ExternalUserAndGuestSharing)"
        }
        DefaultSharingLinkType = @{
            Value = $tenantProps.DefaultSharingLinkType
            Description = "Default sharing link type for new sharing links (None, Direct, Internal, AnonymousAccess)"
        }
        FileAnonymousLinkType  = @{
            Value = $tenantProps.FileAnonymousLinkType
            Description = "Anonymous link permissions for files (None, View, Edit)"
        }
        FolderAnonymousLinkType= @{
            Value = $tenantProps.FolderAnonymousLinkType
            Description = "Anonymous link permissions for folders (None, View, Edit)"
        }
        RequireAnonymousLinksExpireInDays = @{
            Value = $tenantProps.RequireAnonymousLinksExpireInDays
            Description = "Days after which anonymous links expire (0 = no expiration)"
        }
        ExternalUserExpirationRequired = @{
            Value = $tenantProps.ExternalUserExpirationRequired
            Description = "Whether external user invitations must have expiration dates"
        }
        ExternalUserExpireInDays = @{
            Value = $tenantProps.ExternalUserExpireInDays
            Description = "Default expiration period for external user access (days)"
        }
        PreventExternalUsersFromResharing = @{
            Value = $tenantProps.PreventExternalUsersFromResharing
            Description = "Whether external users are prevented from resharing content"
        }
      }

      # Add new sections for Search, Language, Content Type, and Teams settings
      Write-Info "Getting search and language settings..."
      $spoInfo.SearchSettings = [ordered]@{
        AllowEditing = $tenantProps.SearchResolveExactEmailOrUPN
        DisableSearchResults = $tenantProps.DisableCustomizedExperience
        EnableDynamicSort = $tenantProps.EnableAutoNewsDigest
        SearchCenter = $tenantProps.SearchCenterUrl
      }

      $spoInfo.LanguageSettings = [ordered]@{
        DefaultLanguage = $tenantProps.DefaultLanguageTag
        AdditionalLanguages = ($tenantProps.SecondaryLanguages -join ', ')
      }

      Write-Info "Getting content type and Graph connector settings..."
      $spoInfo.ContentTypeSync = [ordered]@{
        HubUrl = if ($tenantProps.ContentTypeSyncSiteUrl) { $tenantProps.ContentTypeSyncSiteUrl } else { "Not configured" }
        SyncEnabled = if ($null -eq $tenantProps.ContentTypeSync) { "Not configured" } else { $tenantProps.ContentTypeSync }
        Status = if ($tenantProps.ContentTypeSync) { "Enabled" } else { "Disabled" }
      }

      # Get Teams integration settings
      Write-Info "Getting Teams integration settings..."
      # Helper function to map link scope enum values
      function Get-ShareLinkScopeText([int]$scope) {
          switch ($scope) {
              0 { "Anyone" }
              1 { "Organization" }
              2 { "Specific People" }
              3 { "Same Site Users" }
              default { "Not configured" }
          }
      }

      # Helper function to map link role enum values  
      function Get-ShareLinkRoleText([int]$role) {
          switch ($role) {
              0 { "Read" }
              1 { "Write" }
              2 { "Embed" }
              default { "Not configured" }
          }
      }

      $spoInfo.TeamsSettings = [ordered]@{
          TeamsClientDefaultShareLinkScope = Get-ShareLinkScopeText $tenantProps.TeamsClientDefaultShareLinkScope
          TeamsClientDefaultShareLinkRole = Get-ShareLinkRoleText $tenantProps.TeamsClientDefaultShareLinkRole 
          DefaultOneDriveMode = if ($tenantProps.OneDriveDefaultToBusinessFeed) { "Business Feed" } else { "My Files" }
          TeamsChannelDefaultShareLinkScope = Get-ShareLinkScopeText $tenantProps.TeamsChannelDefaultShareLinkScope
          TeamsChannelDefaultShareLinkRole = Get-ShareLinkRoleText $tenantProps.TeamsChannelDefaultShareLinkRole
      }

      # Get sites with RAC policies
      Write-Info "Checking for sites with Restricted Access Control..."
      try {
          # Get detailed site properties
          $sites = Get-SPOSite -Limit All | ForEach-Object {
              $siteUrl = $_.Url
              Write-Info "Getting detailed properties for site: $siteUrl"
              Get-SPOSite -Identity $siteUrl -Detailed
          }
          
          Write-Info "Retrieved $($sites.Count) sites for policy checks"
          
          # Check for RAC policies
          $spoInfo.RacPolicySites = $sites | Where-Object { 
              $site = $_
              Write-Info "`nAnalyzing site: $($site.Title) ($($site.Url))"
              Write-Info "  Properties:"
              Write-Info "  - HubSiteId: $($site.HubSiteId)"
              Write-Info "  - LockState: $($site.LockState)"
              Write-Info "  - DisableFlows: $($site.DisableFlows)"
              Write-Info "  - DisableAppViews: $($site.DisableAppViews)"
              Write-Info "  - ConditionalAccessPolicy: $($site.ConditionalAccessPolicy)"
              Write-Info "  - SensitivityLabel: $($site.SensitivityLabel)"
              Write-Info "  - BlockDownloadPolicy: $($site.BlockDownloadPolicy)"
              Write-Info "  - AllowEditing: $($site.AllowEditing)"
              Write-Info "  - RestrictedAccessControl: $($site.RestrictedAccessControl)"
              
              # Site is restricted if any of these conditions are true
              $isRestricted = $false
              $restrictions = @()
              
              if ($site.LockState -ne "Unlock") {
                  $isRestricted = $true
                  $restrictions += "LockState=$($site.LockState)"
              }
              if ($site.RestrictedAccessControl -eq $true) {
                  $isRestricted = $true
                  $restrictions += "RAC"
              }
              if ($site.ConditionalAccessPolicy -in @("BlockAccess", "AuthenticationContext")) {
                  $isRestricted = $true
                  $restrictions += "CAP=$($site.ConditionalAccessPolicy)"
              }
              if ($site.BlockDownloadPolicy -eq $true) {
                  $isRestricted = $true
                  $restrictions += "BlockDownload"
              }
              if ($site.DisableFlows -eq $true -and $site.DisableAppViews -eq $true) {
                  $isRestricted = $true
                  $restrictions += "DisabledAutomation"
              }
              if ($site.AllowEditing -eq $false) {
                  $isRestricted = $true
                  $restrictions += "NoEditing"
              }
              
              if ($isRestricted) {
                  Write-Info "  !!! Access restrictions found: $($restrictions -join ', ')"
                  [PSCustomObject]@{
                      Title = $site.Title
                      Url = $site.Url
                      Restrictions = $restrictions -join ', '
                  }
              }
          }

          # Check for restricted content discovery
          Write-Info "`nChecking for sites with restricted content discovery..."
          $spoInfo.RestrictedSites = $sites | Where-Object { 
              $site = $_
              Write-Info "`nAnalyzing site: $($site.Title) ($($site.Url))"
              
              # Debug output key properties
              Write-Info "  Properties:"
              Write-Info "  - RestrictContentOrgWideSearch: $($site.RestrictContentOrgWideSearch)"
              Write-Info "  - ConditionalAccessPolicy: $($site.ConditionalAccessPolicy)"
              
              # Site has RCD if RestrictContentOrgWideSearch is explicitly enabled
              # This is the specific property that controls whether content is hidden from Copilot
              $isRcdRestricted = $site.RestrictContentOrgWideSearch -eq $true
              
              if ($isRcdRestricted) {
                  Write-Info "  !!! Content discovery restriction detected"
                  [PSCustomObject]@{
                      Title = $site.Title
                      Url = $site.Url
                      Restrictions = "ContentDiscoveryDisabled"
                  }
              } else {
                  Write-Info "  No content discovery restrictions"
                  $null
              }
          } | Where-Object { $_ -ne $null }
          
          Write-Info "`nPolicy check summary:"
          Write-Info "- Found $($spoInfo.RacPolicySites.Count) sites with access restrictions"
          Write-Info "- Found $($spoInfo.RestrictedSites.Count) sites with content discovery restrictions"
        } catch {
          Write-Warn "Error checking site policies: $($_.Exception.Message)"
          Write-Warn $_.Exception.StackTrace
      }
    }

    # Try multiple methods to detect OneDrive sites
    $oneDriveCount = 0
    
    # Method 1: Direct OneDrive site query
    try {
        $personalSites = Get-SPOSite -IncludePersonalSite $true -Filter "Url -like '-my.sharepoint.com/personal/'" -ErrorAction Stop
        $oneDriveCount = ($personalSites | Measure-Object).Count
        Write-Info "Found $oneDriveCount OneDrive sites using direct query"
    } catch {
        Write-Info "Direct OneDrive query failed, trying alternative methods: $($_.Exception.Message)"
    }

    # Method 2: Query all sites and filter if Method 1 failed
    if ($oneDriveCount -eq 0) {
        $allSites = Get-SPOSite -Limit All -ErrorAction Stop
        $spoInfo.TotalSites = $allSites.Count
        
        $oneDriveSites = $allSites | Where-Object { 
            $_.Url -like "*-my.sharepoint.com/personal/*" -or
            $_.Template -eq "SPSPERS" -or
            $_.Template -like "*SPSPERS*"
        }
        $oneDriveCount = ($oneDriveSites | Measure-Object).Count
        Write-Info "Found $oneDriveCount OneDrive sites using filtered query"
    }

    $spoInfo.OneDriveSites = $oneDriveCount
    $spoInfo.TotalSites = (Get-SPOSite -Limit All -ErrorAction SilentlyContinue).Count
    
    Write-Info "Final count: $($spoInfo.TotalSites) total sites, $($spoInfo.OneDriveSites) OneDrive sites"
  } else {
    $spoInfo.Notes = "Could not connect to SharePoint Online."
  }
} catch {
  $errors += "SPO queries failed: $($_.Exception.Message)"
  Write-Warn $_.Exception.Message
}

# Teams signals (connection only)
$teamsInfo = [ordered]@{ Connected=$ctx.Teams }

# Entra ID external sharing and guest settings
# This section collects tenant-level configuration for external sharing, guest users,
# and cross-tenant access policies that may impact Copilot for M365 usage and security
$entraIdInfo = [ordered]@{ 
    Connected = $ctx.Graph
    ExternalSharingSettings = $null
    GuestUserSettings = $null
    AuthorizationPolicy = $null
    Notes = $null
}

try {
    if ($ctx.Graph) {
        Write-Info "Collecting Entra ID external sharing and guest settings..."
        
        # Get Authorization Policy (contains guest invitation settings)
        try {
            $authzPolicy = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/policies/authorizationPolicy" -ErrorAction Stop
            
            $entraIdInfo.AuthorizationPolicy = [ordered]@{
                AllowInvitesFrom = @{
                    Value = $authzPolicy.allowInvitesFrom
                    Description = "Who can invite external users (none, adminsAndGuestInviters, adminsGuestInvitersAndAllMembers, everyone)"
                }
                AllowedToSignUpEmailBasedSubscriptions = @{
                    Value = $authzPolicy.allowedToSignUpEmailBasedSubscriptions
                    Description = "Whether users can sign up for email-based subscriptions"
                }
                AllowedToUseSSPR = @{
                    Value = $authzPolicy.allowedToUseSSPR
                    Description = "Whether users can use Self-Service Password Reset"
                }
                AllowEmailVerifiedUsersToJoinOrganization = @{
                    Value = $authzPolicy.allowEmailVerifiedUsersToJoinOrganization
                    Description = "Whether email-verified users can join the organization without invitation"
                }
                BlockMsolPowerShell = @{
                    Value = $authzPolicy.blockMsolPowerShell
                    Description = "Whether MSOL PowerShell access is blocked for users"
                }
                DefaultUserRolePermissions = [ordered]@{
                    AllowedToCreateApps = @{
                        Value = $authzPolicy.defaultUserRolePermissions.allowedToCreateApps
                        Description = "Whether users can create applications"
                    }
                    AllowedToCreateSecurityGroups = @{
                        Value = $authzPolicy.defaultUserRolePermissions.allowedToCreateSecurityGroups
                        Description = "Whether users can create security groups"
                    }
                    AllowedToCreateTenants = @{
                        Value = $authzPolicy.defaultUserRolePermissions.allowedToCreateTenants
                        Description = "Whether users can create new tenants"
                    }
                    AllowedToReadOtherUsers = @{
                        Value = $authzPolicy.defaultUserRolePermissions.allowedToReadOtherUsers
                        Description = "Whether users can read other users' profiles"
                    }
                    AllowedToReadBitlockerKeysForOwnedDevice = @{
                        Value = $authzPolicy.defaultUserRolePermissions.allowedToReadBitlockerKeysForOwnedDevice
                        Description = "Whether users can read BitLocker recovery keys for their own devices"
                    }
                }
            }
            Write-Info "Retrieved authorization policy settings"
        } catch {
            Write-Warn "Failed to retrieve authorization policy: $($_.Exception.Message)"
            $entraIdInfo.AuthorizationPolicy = "Error retrieving policy"
        }

        # Get External Identities Policy
        try {
            $extIdPolicy = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/policies/externalIdentitiesPolicy" -ErrorAction Stop
            
            $entraIdInfo.ExternalSharingSettings = [ordered]@{
                AllowExternalIdentitiesToLeave = @{
                    Value = $extIdPolicy.allowExternalIdentitiesToLeave
                    Description = "Whether external users can leave the organization on their own"
                }
                AllowDeletedIdentitiesDataRemoval = @{
                    Value = $extIdPolicy.allowDeletedIdentitiesDataRemoval
                    Description = "Whether data is automatically removed when external identities are deleted"
                }
            }
            Write-Info "Retrieved external identities policy settings"
        } catch {
            Write-Info "External identities policy not available in this tenant: $($_.Exception.Message)"
            $entraIdInfo.ExternalSharingSettings = [ordered]@{
                PolicyAvailable = $false
                Note = "External Identities Policy not available - may require specific licensing or tenant configuration"
            }
        }

        # Get Guest User Access Settings from Organization settings
        try {
            if ($org) {
                # Try to get more comprehensive guest and external settings from the organization object
                $entraIdInfo.GuestUserSettings = [ordered]@{
                    GuestUserRoleId = @{
                        Value = if ($org.GuestUserRoleId) { $org.GuestUserRoleId } else { "Not configured" }
                        Description = "Role template ID assigned to guest users (controls their permissions)"
                    }
                }
                
                # Try to get additional organization-level external collaboration settings
                $entraIdInfo.OrganizationSettings = [ordered]@{
                    PrivacyProfile = @{
                        Value = if ($org.PrivacyProfile) { "Configured" } else { "Not configured" }
                        Description = "Whether organization has configured privacy contact information"
                    }
                    MarketingNotificationEmails = @{
                        Value = if ($org.MarketingNotificationEmails) { $org.MarketingNotificationEmails -join ', ' } else { "None specified" }
                        Description = "Email addresses for marketing notifications from Microsoft"
                    }
                    SecurityComplianceNotificationMails = @{
                        Value = if ($org.SecurityComplianceNotificationMails) { $org.SecurityComplianceNotificationMails -join ', ' } else { "None specified" }
                        Description = "Email addresses for security and compliance notifications"
                    }
                    TechnicalNotificationMails = @{
                        Value = if ($org.TechnicalNotificationMails) { $org.TechnicalNotificationMails -join ', ' } else { "None specified" }
                        Description = "Email addresses for technical notifications about the tenant"
                    }
                }
                
                Write-Info "Retrieved guest user and organization settings"
            }
        } catch {
            Write-Warn "Failed to retrieve guest user settings: $($_.Exception.Message)"
            $entraIdInfo.GuestUserSettings = "Error retrieving settings"
        }

        # Try to get Cross-tenant Access Policy (if available)
        try {
            $crossTenantPolicy = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy" -ErrorAction Stop
            
            $entraIdInfo.CrossTenantAccessPolicy = [ordered]@{
                AllowedCloudEndpoints = @{
                    Value = if ($crossTenantPolicy.allowedCloudEndpoints) { $crossTenantPolicy.allowedCloudEndpoints -join ', ' } else { "None specified" }
                    Description = "Cloud endpoints allowed for cross-tenant access"
                }
                IsServiceDefault = @{
                    Value = $crossTenantPolicy.isServiceDefault
                    Description = "Whether this policy uses service defaults (true) or has custom configuration (false)"
                }
            }
            Write-Info "Retrieved cross-tenant access policy"
        } catch {
            Write-Info "Cross-tenant access policy not available: $($_.Exception.Message)"
            $entraIdInfo.CrossTenantAccessPolicy = [ordered]@{
                PolicyAvailable = $false
                Note = "Cross-tenant access policy not available - may not be configured or requires specific permissions"
            }
        }

        # Try to get additional guest and external user statistics
        try {
            Write-Info "Collecting guest user statistics..."
            $guestUsers = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userType eq 'Guest'&`$count=true&`$top=1" -Headers @{ ConsistencyLevel = "eventual" } -ErrorAction Stop
            
            $entraIdInfo.GuestUserStatistics = [ordered]@{
                TotalGuestUsers = @{
                    Value = if ($guestUsers.'@odata.count') { $guestUsers.'@odata.count' } else { 0 }
                    Description = "Number of guest users currently in the tenant"
                }
                Impact = @{
                    Value = if ($guestUsers.'@odata.count' -gt 0) { "External users present" } else { "No external users" }
                    Description = "Potential impact on Copilot data access and security considerations"
                }
            }
            Write-Info "Found $($entraIdInfo.GuestUserStatistics.TotalGuestUsers) guest users"
        } catch {
            Write-Info "Could not retrieve guest user count: $($_.Exception.Message)"
            $entraIdInfo.GuestUserStatistics = [ordered]@{
                TotalGuestUsers = "Unable to retrieve"
                Note = "Requires User.Read.All permission"
            }
        }

    } else {
        $entraIdInfo.Notes = "Could not connect to Microsoft Graph."
    }
} catch {
    $errors += "Entra ID external sharing query failed: $($_.Exception.Message)"
    Write-Warn "Error retrieving Entra ID external sharing settings: $($_.Exception.Message)"
}

# Readiness evaluation (lightweight heuristics)
function ToBoolLabel([bool]$b) { 
    if ($null -eq $b) { return 'Gap' }  # Handle null case
    return $(if ($b) { 'Pass' } else { 'Gap' })
}

# Update readiness evaluation with simplified logic
$readiness = [ordered]@{
    Licensing_CopilotSkuPresent      = ToBoolLabel([bool]$licensing.CopilotSkuPresent)
    Licensing_EligibleBaseLicenses   = ToBoolLabel([bool]($baseLicenses.Count -gt 0 -and ($baseLicenses | Where-Object { $_.ConsumedUnits -gt 0 })))
    EXO_PrimaryMailboxHostedInEXO    = ToBoolLabel([bool]($exoInfo.Connected -and ($exoInfo.UserMailboxCount -as [int]) -ge 1))
    OneDrive_Provisioned             = if ($spoInfo.OneDriveSites -gt 0) { 'Pass' } else { if($spoInfo.Connected){'Gap'} else {'Unknown'} }
    SPO_TenantConnected              = ToBoolLabel([bool]$spoInfo.Connected)
    Teams_ServiceConnected           = ToBoolLabel([bool]$teamsInfo.Connected)
    EntraId_ExternalSharingConfigured = if ($entraIdInfo.Connected) { 
        if ($entraIdInfo.AuthorizationPolicy -and $entraIdInfo.AuthorizationPolicy -ne "Error retrieving policy") { 'Pass' } else { 'Gap' }
    } else { 'Unknown' }
    ManualChecks                     = @(
      [ordered]@{
        Name    = 'Microsoft 365 Apps (channel/version) & network endpoints'
        Status  = 'Manual'
        Guidance= 'Ensure supported update channel (Current Channel or Monthly Enterprise), and app/network requirements are satisfied.'
        Link    = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements'
      },
      [ordered]@{
        Name    = 'App privacy settings & third-party cookies (Web)'
        Status  = 'Manual'
        Guidance= 'Verify privacy controls for connected experiences; enable third-party cookies for Word/Excel/PowerPoint online Copilot.'
        Link    = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements'
      },
      [ordered]@{
        Name    = 'Device-based licensing'
        Status  = 'Manual'
        Guidance= 'Copilot is not available with device-based licensing for Microsoft 365 Apps.'
        Link    = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements'
      }
    )
}

# Build final report object
$report = [ordered]@{
  GeneratedAtUtc     = (Get-Date).ToUniversalTime().ToString("s") + "Z"
  ScriptDurationSec  = (New-TimeSpan -Start $scriptStart -End (Get-Date)).TotalSeconds
  LearnReferences    = @(
    'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements',
    'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-enablement-resources',
    'https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-licensing'
  )
  Connections        = $ctx
  Tenant             = $orgInfo
  Licensing          = $licensing
  Services           = [ordered]@{
    ExchangeOnline   = $exoInfo
    SharePointOnline = $spoInfo
    Teams            = $teamsInfo
    EntraId          = $entraIdInfo
    Graph            = [ordered]@{ Connected=$ctx.Graph; Scopes=$graphScopes }
  }
  Readiness          = $readiness
  Warnings           = $warnings
  Errors             = $errors
}

# Write JSON
$jsonPath = Join-Path $OutputPath 'copilot-readiness.json'
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Info "JSON written: $jsonPath"

# HTML Generation Section - Use simple string concatenation instead of StringBuilder
$htmlPath = Join-Path $OutputPath 'copilot-readiness.html'

# Define CSS and HTML template
$css = @'
<style>
body { font-family: Segoe UI,Arial,sans-serif; margin: 24px; color: #222; }
h1 { font-size: 22px; margin-bottom: 6px }
h2 { font-size: 18px; margin-top: 24px }
table { border-collapse: collapse; width: 100%; margin: 8px 0 16px 0 }
th,td { border: 1px solid #ddd; padding: 8px; font-size: 13px }
th { background: #f3f3f3; text-align: left }
.badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-weight: 600 }
.pass { background: #e6f4ea; color: #137333 }
.gap { background: #fce8e6; color: #c5221f }
.manual { background: #fff8e1; color: #a05a00 }
.unknown { background: #eceff1; color: #546e7a }
.small { color: #555; font-size: 12px }
pre { background: #f7f7f7; padding: 10px; overflow: auto; border: 1px solid #eee }
</style>
'@

function Get-StatusBadge([string]$Status) {
    switch -Regex ($Status) {
        'Pass'    { '<span class="badge pass">Pass</span>' }
        'Gap'     { '<span class="badge gap">Gap</span>' }
        'Manual'  { '<span class="badge manual">Manual</span>' }
        default   { '<span class="badge unknown">Unknown</span>' }
    }
}

# Build HTML content sections
$summaryRows = $null
$summaryRows = @(
    "Copilot add-on license present|$(Get-StatusBadge $report.Readiness.Licensing_CopilotSkuPresent)",
    "Eligible base licenses present|$(Get-StatusBadge $report.Readiness.Licensing_EligibleBaseLicenses)",  # Changed this line
    "Exchange Online (primary mailbox in EXO)|$(Get-StatusBadge $report.Readiness.EXO_PrimaryMailboxHostedInEXO)",
    "OneDrive provisioned (personal sites exist)|$(Get-StatusBadge $report.Readiness.OneDrive_Provisioned)",
    "SharePoint Online tenant connected|$(Get-StatusBadge $report.Readiness.SPO_TenantConnected)",
    "Microsoft Teams connected|$(Get-StatusBadge $report.Readiness.Teams_ServiceConnected)",
    "Entra ID external sharing configured|$(Get-StatusBadge $report.Readiness.EntraId_ExternalSharingConfigured)"
) | ForEach-Object { 
    $cols = $_ -split '\|'
    "<tr><td>$($cols[0])</td><td>$($cols[1])</td></tr>"
}

$manualChecksHtml = foreach ($m in $report.Readiness.ManualChecks) {
    "<tr><td>$($m.Name)</td><td><span class='badge manual'>Manual</span></td><td>$($m.Guidance) <a href='$($m.Link)'>Learn</a></td></tr>"
}

# Combine all HTML parts
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Copilot Readiness Report</title>
$css
</head>
<body>
<h1>Copilot for Microsoft 365 - Tenant Readiness</h1>
<div class="small">Generated: $($report.GeneratedAtUtc) | Duration: $($report.ScriptDurationSec)s</div>

<h2>Summary</h2>
<table>
<tr><th>Check</th><th>Status</th></tr>
$($summaryRows -join "`n")
</table>

<h2>Manual checks (review & remediate)</h2>
<table>
<tr><th>Item</th><th>Status</th><th>Guidance</th></tr>
$($manualChecksHtml -join "`n")
</table>
"@

# Add remaining sections
$htmlContent += @"
<h2>Tenant</h2>
<table>
<tr><th>DisplayName</th><td>$($report.Tenant.DisplayName)</td></tr>
<tr><th>TenantId</th><td>$($report.Tenant.Id)</td></tr>
<tr><th>DefaultDomain</th><td>$($report.Tenant.DefaultDomain)</td></tr>
<tr><th>VerifiedDomains</th><td>$(if ($report.Tenant.VerifiedDomains) {[string]::Join(', ', $report.Tenant.VerifiedDomains)} else {'None'})</td></tr>
<tr><th>Country</th><td>$($report.Tenant.CountryLetterCode)</td></tr>
</table>

<h2>Licensing</h2>
<p>Copilot SKU present: <strong>$($report.Licensing.CopilotSkuPresent)</strong></p>
<table>
<tr><th>Type</th><th>SkuPartNumber</th><th>Consumed</th><th>Prepaid(Enabled)</th><th>ServicePlans</th></tr>
$(if ($report.Licensing.AllRelevantSkus) {
    $report.Licensing.AllRelevantSkus | ForEach-Object {
        "<tr><td>$($_.Type)</td><td>$($_.SkuPartNumber)</td><td>$($_.ConsumedUnits)</td><td>$($_.PrepaidEnabled)</td><td>$($_.ServicePlans)</td></tr>"
    }
} else {
    "<tr><td colspan='5'>No relevant licenses found</td></tr>"
})
</table>

<h2>Services</h2>

<h3>Exchange Online</h3>
<table>
<tr><th>Connected</th><td>$($report.Services.ExchangeOnline.Connected)</td></tr>
<tr><th>User Mailboxes</th><td>$($report.Services.ExchangeOnline.UserMailboxCount)</td></tr>
<tr><th>Notes</th><td>$($report.Services.ExchangeOnline.Notes)</td></tr>
</table>

<h3>SharePoint & OneDrive</h3>
<table>
<tr><th>Connected</th><td>$($report.Services.SharePointOnline.Connected)</td></tr>
<tr><th>Admin URL</th><td>$($report.Services.SharePointOnline.AdminUrl)</td></tr>
<tr><th>Total Sites</th><td>$($report.Services.SharePointOnline.TotalSites)</td></tr>
<tr><th>OneDrive Sites</th><td>$($report.Services.SharePointOnline.OneDriveSites)</td></tr>
</table>

<h4>Sharing Settings</h4>
<p class="small"><strong>Impact on Copilot:</strong> These settings determine how content can be shared externally. 
More permissive sharing may increase the scope of content accessible to Copilot through external collaborations.</p>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.SharePointOnline.SharingSettings) {
        $report.Services.SharePointOnline.SharingSettings.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format - consider updating</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>No sharing settings available</td></tr>"
    }
)
</table>

<h4>Search & Language Settings</h4>
<table>
<tr><th>Setting</th><th>Value</th></tr>
$(
    if ($report.Services.SharePointOnline.SearchSettings) {
        $report.Services.SharePointOnline.SearchSettings.GetEnumerator() | ForEach-Object {
            "<tr><td>$($_.Key)</td><td>$($_.Value)</td></tr>"
        }
        $report.Services.SharePointOnline.LanguageSettings.GetEnumerator() | ForEach-Object {
            "<tr><td>$($_.Key)</td><td>$($_.Value)</td></tr>"
        }
    } else {
        "<tr><td colspan='2'>No search/language settings available</td></tr>"
    }
)
</table>

<h4>Content Type & Graph Connector Status</h4>
<table>
<tr><th>Setting</th><th>Value</th></tr>
$(
    if ($report.Services.SharePointOnline.ContentTypeSync) {
        $report.Services.SharePointOnline.ContentTypeSync.GetEnumerator() | ForEach-Object {
            "<tr><td>$($_.Key)</td><td>$($_.Value)</td></tr>"
        }
    }
)
</table>

<h4>Microsoft Graph Connectors</h4>
<table>
<tr><th>Name</th><th>State</th></tr>
$(
    if ($report.Services.SharePointOnline.GraphConnectors) {
        $report.Services.SharePointOnline.GraphConnectors | ForEach-Object {
            "<tr><td>$($_.Name)</td><td>$($_.State)</td></tr>"
        }
    } else {
        "<tr><td colspan='2'>No Graph connectors found or access denied</td></tr>"
    }
)
</table>

<h4>Teams Integration Settings</h4>
<table>
<tr><th>Setting</th><th>Value</th></tr>
$(
    if ($report.Services.SharePointOnline.TeamsSettings) {
        $report.Services.SharePointOnline.TeamsSettings.GetEnumerator() | ForEach-Object {
            "<tr><td>$($_.Key)</td><td>$($_.Value)</td></tr>"
        }
    } else {
        "<tr><td colspan='2'>No Teams integration settings available</td></tr>"
    }
)
</table>

<h4>Sites with Access Restrictions</h4>
<p class="small">Sites with RAC policies, conditional access, or other restrictions that may affect Copilot.</p>
<table>
<tr><th>Title</th><th>URL</th><th>Applied Restrictions</th></tr>
$(
    if ($report.Services.SharePointOnline.RacPolicySites) {
        $report.Services.SharePointOnline.RacPolicySites | ForEach-Object {
            "<tr><td>$($_.Title)</td><td>$($_.Url)</td><td>$($_.Restrictions)</td></tr>"
        }
    } else {
        "<tr><td colspan='3'>No sites with access restrictions found</td></tr>"
    }
)
</table>

<h4>Sites with Restricted Content Discovery</h4>
<table>
<tr><th>Title</th><th>URL</th><th>Restrictions</th></tr>
$(
    if ($report.Services.SharePointOnline.RestrictedSites) {
        $report.Services.SharePointOnline.RestrictedSites | ForEach-Object {
            "<tr><td>$($_.Title)</td><td>$($_.Url)</td><td>$($_.Restrictions)</td></tr>"
        }
    } else {
        "<tr><td colspan='3'>No sites with restricted content discovery found</td></tr>"
    }
)
</table>

<h3>Entra ID External Sharing & Guest Settings</h3>
<p class="small"><strong>Impact on Copilot:</strong> These settings control how external users can be invited and what permissions they have. 
External users may have access to content that Copilot can surface, so understanding guest access patterns is important for data governance.</p>
<table>
<tr><th>Connected</th><td>$($report.Services.EntraId.Connected)</td></tr>
<tr><th>Notes</th><td>$($report.Services.EntraId.Notes)</td></tr>
</table>

<h4>Authorization Policy (Guest Invitations)</h4>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.AuthorizationPolicy -and $report.Services.EntraId.AuthorizationPolicy -ne "Error retrieving policy") {
        $report.Services.EntraId.AuthorizationPolicy.GetEnumerator() | ForEach-Object {
            if ($_.Key -eq "DefaultUserRolePermissions") {
                $_.Value.GetEnumerator() | ForEach-Object {
                    if ($_.Value.GetType().Name -eq 'Hashtable') {
                        "<tr><td>DefaultUserRole - $($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
                    } else {
                        "<tr><td>DefaultUserRole - $($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
                    }
                }
            } else {
                if ($_.Value.GetType().Name -eq 'Hashtable') {
                    "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
                } else {
                    "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
                }
            }
        }
    } else {
        "<tr><td colspan='3'>$($report.Services.EntraId.AuthorizationPolicy)</td></tr>"
    }
)
</table>

<h4>External Identities Policy</h4>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.ExternalSharingSettings -and $report.Services.EntraId.ExternalSharingSettings -ne "Error retrieving policy") {
        $report.Services.EntraId.ExternalSharingSettings.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>External Identities Policy not available or accessible</td></tr>"
    }
)
</table>

<h4>Guest User Settings</h4>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.GuestUserSettings -and $report.Services.EntraId.GuestUserSettings -ne "Error retrieving settings") {
        $report.Services.EntraId.GuestUserSettings.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>$($report.Services.EntraId.GuestUserSettings)</td></tr>"
    }
)
</table>

<h4>Cross-Tenant Access Policy</h4>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.CrossTenantAccessPolicy -and $report.Services.EntraId.CrossTenantAccessPolicy.GetType().Name -eq 'OrderedDictionary') {
        $report.Services.EntraId.CrossTenantAccessPolicy.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>Cross-tenant access policy not available or not configured</td></tr>"
    }
)
</table>

<h4>Organization Settings</h4>
<table>
<tr><th>Setting</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.OrganizationSettings) {
        $report.Services.EntraId.OrganizationSettings.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>No organization settings available</td></tr>"
    }
)
</table>

<h4>Guest User Statistics</h4>
<table>
<tr><th>Metric</th><th>Value</th><th>Description</th></tr>
$(
    if ($report.Services.EntraId.GuestUserStatistics) {
        $report.Services.EntraId.GuestUserStatistics.GetEnumerator() | ForEach-Object {
            if ($_.Value.GetType().Name -eq 'Hashtable') {
                "<tr><td>$($_.Key)</td><td>$($_.Value.Value)</td><td>$($_.Value.Description)</td></tr>"
            } else {
                "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>Legacy format</td></tr>"
            }
        }
    } else {
        "<tr><td colspan='3'>No guest user statistics available</td></tr>"
    }
)
</table>

<h2>References (Microsoft Learn)</h2>
<ul>
$(($report.LearnReferences | ForEach-Object { "<li><a href='$_'>$_</a></li>" }) -join "`n")
</ul>

<h2>Warnings</h2>
<pre>$([System.Web.HttpUtility]::HtmlEncode(($report.Warnings -join "`n")))</pre>

<h2>Errors</h2>
<pre>$([System.Web.HttpUtility]::HtmlEncode(($report.Errors -join "`n")))</pre>

</body>
</html>
"@

# Write the HTML file
$htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
Write-Info "HTML written: $htmlPath"

# Clean up sessions (best effort)
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
try { Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue | Out-Null } catch {}
try { Disconnect-SPOService -ErrorAction SilentlyContinue } catch {}
try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {}

Write-host "`nDone."