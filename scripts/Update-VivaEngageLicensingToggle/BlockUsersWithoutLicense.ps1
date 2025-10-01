#!/usr/bin/env pwsh
#requires -Version 7.0
<#
Usage:
  ./license.ps1 enforce_user_license "<AAD_ACCESS_TOKEN>"   # POST  /api/v1/networks/enforce_user_license
  ./license.ps1 fetch_current_license_state "<AAD_ACCESS_TOKEN>"   # GET /api/v1/networks/fetch_current_enforce_license_state
#>

param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('enforce_user_license','fetch_current_license_state')]
  [string]$Api,

  [Parameter(Mandatory=$true)]
  [string]$Token
)

# --- Config ---
$BaseUrl = 'http://localhost:9010'
$Paths = @{
  'enforce_user_license'    = '/api/v1/networks/enforce_user_license'                # POST
  'fetch_current_license_state' = '/api/v1/networks/fetch_current_enforce_license_state' # GET
}
$Methods = @{
  'enforce_user_license' = 'POST'
  'fetch_current_license_state' = 'GET'
}
$TimeoutSec = 60

# --- Build request ---
if ([string]::IsNullOrWhiteSpace($Token)) {
  Write-Error "Token was empty."
  exit 2
}
$Url    = $BaseUrl + $Paths[$Api]
$Method = $Methods[$Api]
$Headers = @{
  Authorization = "Bearer $Token"
  Accept        = 'application/json'
}
# For POST-with-no-body, send empty string to ensure Content-Length: 0
$Body = if ($Method -eq 'POST') { '' } else { $null }

try {
  $resp = Invoke-WebRequest -Uri $Url -Method $Method -Headers $Headers `
          -ContentType 'application/json' -Body $Body -TimeoutSec $TimeoutSec `
          -ErrorAction Stop

  if ($resp.Content) {
    $resp.Content | Write-Output
  } else {
    Write-Output ("{{""status"":{0}}}" -f [int]$resp.StatusCode)
  }
  exit 0
}
catch {
  $ex = $_.Exception
  $status  = $null
  $desc    = $null
  $body    = $null
  $headers = @{}

  try {
    if ($ex.Response) {
      try {
        if ($ex.Response.StatusCode) { $status = [int]$ex.Response.StatusCode }
        if ($ex.Response.StatusDescription) { $desc = $ex.Response.StatusDescription }
      } catch {}
      if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        $body = $_.ErrorDetails.Message
      } else {
        try {
          $stream = $ex.Response.GetResponseStream()
          if ($stream) {
            $reader = [System.IO.StreamReader]::new($stream)
            $body = $reader.ReadToEnd()
          }
        } catch {}
      }
    }
  } catch {}

  $errObj = [ordered]@{
    method             = $Method
    url                = $Url
    status             = $status
    status_description = $desc
    www_authenticate   = $headers['WWW-Authenticate']
    response_headers   = $headers
    response_body      = $body
    exception_type     = $ex.GetType().FullName
    exception_message  = $ex.Message
    stack              = $ex.StackTrace
  }

  Write-Host "❌ HTTP call failed:" -ForegroundColor Red
  $errJson = $errObj | ConvertTo-Json -Depth 10
  Write-Host $errJson

  if ($status) {
    Write-Error ("Request failed (HTTP {0} {1})" -f $status, $desc)
  } else {
    Write-Error "Request failed (no HTTP response received)"
  }
  exit 1
}
