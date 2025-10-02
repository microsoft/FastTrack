<#
.SYNOPSIS
    Generates a Teams User Activity report for users specified in a CSV file.

.DESCRIPTION
    This script connects to Microsoft Graph API directly using Application credentials
    to retrieve Teams user activity details (meetings organized, meeting duration, etc.)
    for a specific list of users provided via CSV.
    
    The report includes the same columns as Get-MgReportTeamUserActivityUserDetail:
    - Report Refresh Date, User Principal Name, Last Activity Date
    - Team Chat Message Count, Private Chat Message Count, Call Count, Meeting Count
    - Meetings Organized Count, Has Other Action, Report Period
    
.PARAMETER UserCsvPath
    Mandatory. Path to a CSV file with a 'UserPrincipalName' header.

.PARAMETER Period
    Optional. The period of time for the report. Valid values: D7, D30, D90, D180
    Default: D7 (last 7 days)

.NOTES
    Based on script by: Alejandro Lopez | alejandro.lopez@microsoft.com
    Modified: September 29, 2025
    
    Required API Permissions:
    - Reports.Read.All (Application permission)
    
.EXAMPLE
    .\Get-TeamsUserActivityReport.ps1 -UserCsvPath "C:\users.csv" -Period "D30"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Optional. Path to a CSV file with a 'UserPrincipalName' header. If not provided, report includes all users.")]
    [string]$UserCsvPath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Report period: D7, D30, D90, or D180")]
    [ValidateSet("D7", "D30", "D90", "D180")]
    [string]$Period = "D7"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Teams User Activity Report Generator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Prompt for connection details
Write-Host "Please provide your App Registration details:" -ForegroundColor Yellow

$tenantId = Read-Host "Enter your Directory (Tenant) ID"
$appId    = Read-Host "Enter your Application (Client) ID"
$secureClientSecret = Read-Host "Enter your Client Secret" -AsSecureString

if ([string]::IsNullOrWhiteSpace($tenantId) -or [string]::IsNullOrWhiteSpace($appId) -or $secureClientSecret.Length -eq 0) {
    Write-Host "❌ Tenant ID, App ID, and Client Secret cannot be empty." -ForegroundColor Red
    return
}

# Convert secure string to plain text for API call
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureClientSecret)
$clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Step 2: Verify CSV file exists and read user list (if provided)
$targetUsers = $null
$filterMode = "All Users"

if (-not [string]::IsNullOrWhiteSpace($UserCsvPath)) {
    Write-Host "`nReading users from CSV file..." -ForegroundColor Yellow
    
    if (-not (Test-Path -Path $UserCsvPath)) {
        Write-Host "❌ CSV file not found at path: $UserCsvPath" -ForegroundColor Red
        return
    }
    
    try {
        $usersFromCsv = Import-Csv -Path $UserCsvPath
        
        if (-not $usersFromCsv) {
            Write-Host "❌ CSV file is empty or could not be read." -ForegroundColor Red
            return
        }
        
        # Check if UserPrincipalName column exists
        if (-not ($usersFromCsv[0].PSObject.Properties.Name -contains "UserPrincipalName")) {
            Write-Host "❌ CSV file must contain a 'UserPrincipalName' column." -ForegroundColor Red
            return
        }
        
        $targetUsers = $usersFromCsv | Select-Object -ExpandProperty UserPrincipalName
        $filterMode = "Filtered"
        Write-Host "✅ Found $($targetUsers.Count) user(s) in CSV file." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error reading CSV file: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}
else {
    Write-Host "`nNo CSV file provided. Report will include all users in the tenant." -ForegroundColor Cyan
}

# Step 3: Define export path
$exportFileName = if ($filterMode -eq "Filtered") {
    "TeamsUserActivityReport_Filtered_$Period.csv"
} else {
    "TeamsUserActivityReport_AllUsers_$Period.csv"
}
$ExportPath = Join-Path -Path $PSScriptRoot -ChildPath $exportFileName
Write-Host "Report will be saved to: $ExportPath`n"

# Step 4: Authenticate and get access token
Write-Host "Authenticating with Microsoft Graph..." -ForegroundColor Yellow

try {
    $tokenBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $appId
        Client_Secret = $clientSecret
    }
    
    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop
    $accessToken = $tokenResponse.access_token
    
    Write-Host "✅ Successfully authenticated!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease verify:" -ForegroundColor Yellow
    Write-Host "  - Tenant ID is correct" -ForegroundColor Yellow
    Write-Host "  - Application (Client) ID is correct" -ForegroundColor Yellow
    Write-Host "  - Client Secret is correct and not expired" -ForegroundColor Yellow
    return
}

# Step 5: Fetch Teams User Activity Report from Graph API
Write-Host "`nFetching Teams User Activity report for period: $Period..." -ForegroundColor Yellow
Write-Host "This may take a moment..." -ForegroundColor Gray

try {
    $uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserDetail(period='$Period')"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }
    
    # Download the report - it returns CSV data as bytes
    $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
    
    # Convert bytes to string using UTF-8 encoding
    $rawContent = [System.Text.Encoding]::UTF8.GetString($response.Content)
    
    # Convert CSV content to PowerShell objects
    $reportData = $rawContent | ConvertFrom-Csv
    
    if (-not $reportData -or $reportData.Count -eq 0) {
        Write-Host "⚠️ No data returned from the API. This could mean:" -ForegroundColor Yellow
        Write-Host "   - No Teams activity in the specified period" -ForegroundColor Yellow
        Write-Host "   - The App Registration lacks 'Reports.Read.All' permission" -ForegroundColor Yellow
        Write-Host "   - Admin consent has not been granted" -ForegroundColor Yellow
        return
    }
    
    Write-Host "✅ Retrieved $($reportData.Count) total activity records from API." -ForegroundColor Green
    
}
catch {
    Write-Host "❌ Error fetching report from Graph API: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "`n⚠️ Access Denied (403). Please ensure:" -ForegroundColor Yellow
        Write-Host "   1. The App Registration has 'Reports.Read.All' Application permission" -ForegroundColor Yellow
        Write-Host "   2. Admin consent has been granted for this permission" -ForegroundColor Yellow
        Write-Host "   3. Wait a few minutes after granting permissions before running the script" -ForegroundColor Yellow
    }
    elseif ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "`n⚠️ Unauthorized (401). Please verify your credentials." -ForegroundColor Yellow
    }
    
    return
}

# Step 6: Identify the UPN column and filter report data (if CSV provided)
if ($targetUsers) {
    Write-Host "`nFiltering report data for users in CSV..." -ForegroundColor Yellow
    
    # Get all column names
    $reportColumns = $reportData[0].PSObject.Properties.Name
    
    # Find the UPN column
    $upnColumn = $reportColumns | Where-Object { 
        $_ -like "*User Principal Name*" -or 
        $_ -like "*UPN*" -or 
        $_ -eq "UserPrincipalName" -or
        $_ -like "*User*Principal*"
    }
    
    if (-not $upnColumn) {
        Write-Host "❌ Could not identify the User Principal Name column in the report." -ForegroundColor Red
        Write-Host "   Available columns: $($reportColumns -join ', ')" -ForegroundColor Gray
        return
    }
    
    if ($upnColumn -is [array]) {
        $upnColumn = $upnColumn[0]
    }
    
    # Filter using case-insensitive comparison
    $filteredData = $reportData | Where-Object { 
        $currentUpn = $_.$upnColumn
        $targetUsers | Where-Object { $_.ToLower() -eq $currentUpn.ToLower() }
    }
    
    if ($filteredData.Count -eq 0) {
        Write-Host "⚠️ No matching users found in the report." -ForegroundColor Yellow
        Write-Host "   The users in your CSV may have no Teams activity in the last $Period days." -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ Found activity data for $($filteredData.Count) user(s) from your CSV list." -ForegroundColor Green
    }
}
else {
    # No filtering - use all data
    Write-Host "`nIncluding all users in the report..." -ForegroundColor Yellow
    $filteredData = $reportData
    Write-Host "✅ Report contains activity data for $($filteredData.Count) user(s)." -ForegroundColor Green
}

# Step 7: Display summary of users with/without data (only for filtered mode)
if ($targetUsers -and $filteredData.Count -gt 0) {
    $reportColumns = $reportData[0].PSObject.Properties.Name
    $upnColumn = $reportColumns | Where-Object { 
        $_ -like "*User Principal Name*" -or 
        $_ -like "*UPN*" -or 
        $_ -eq "UserPrincipalName" -or
        $_ -like "*User*Principal*"
    }
    
    if ($upnColumn -is [array]) {
        $upnColumn = $upnColumn[0]
    }
    
    $usersWithData = $filteredData | Select-Object -ExpandProperty $upnColumn
    $usersWithoutData = $targetUsers | Where-Object { 
        $upn = $_
        -not ($usersWithData | Where-Object { $_.ToLower() -eq $upn.ToLower() })
    }
    
    if ($usersWithoutData) {
        Write-Host "`n⚠️ The following $($usersWithoutData.Count) user(s) from CSV have no activity data:" -ForegroundColor Yellow
        $usersWithoutData | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    }
}

# Step 8: Export the filtered data
if ($filteredData.Count -gt 0) {
    Write-Host "`nExporting report to CSV..." -ForegroundColor Yellow
    
    try {
        $filteredData | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✅ Report successfully saved!" -ForegroundColor Green
        Write-Host "   Location: $ExportPath" -ForegroundColor Cyan
        Write-Host "   Records: $($filteredData.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Error exporting report: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "`n⚠️ No data to export." -ForegroundColor Yellow
}

Write-Host "`n✅ Script completed!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan