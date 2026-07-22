<#
.DESCRIPTION
    The sample scripts are not supported under any Microsoft standard support 
    program or service. The sample scripts are provided AS IS without warranty  
    of any kind. Microsoft further disclaims all implied warranties including,  
    without limitation, any implied warranties of merchantability or of fitness for 
    a particular purpose. The entire risk arising out of the use or performance of  
    the sample scripts and documentation remains with you. In no event shall 
    Microsoft, its authors, or anyone else involved in the creation, production, or 
    delivery of the scripts be liable for any damages whatsoever (including, 
    without limitation, damages for loss of business profits, business interruption, 
    loss of business information, or other pecuniary loss) arising out of the use 
    of or inability to use the sample scripts or documentation, even if Microsoft 
    has been advised of the possibility of such damages.

Purpose: 
    -Exports files and messages from a Yammer network for specific date ranges using the Network Data Export API:
     https://learn.microsoft.com/en-us/rest/api/yammer/network-data-export
     
Author:
    Dean Cron

Version:
    1.0 - June 2024 - Initial release
    2.0 - November 2025 - Updated authentication
    2.1 - July 2026 - Reviewed against current Microsoft documentation (still the current,
          supported endpoint as of this review). Added a runtime warning for the -IncludeFiles
          parameter, which Microsoft's docs confirm only applies to legacy (pre-native mode)
          networks. See MC1230453 for the related March 13, 2026 retirement of the equivalent
          admin center option.
    2.2 - July 2026 - Removed the -IncludeExternalNetworks parameter/option. External network
          export is not supported for native-mode networks (which don't touch external
          networks during migration), and Microsoft is retiring the equivalent admin center
          option March 13, 2026 (MC1230453).

Requirements: 
    1. MSAL.PS PowerShell module. Install it from the PowerShell Gallery with the command:
        Install-Module MSAL.PS

    2. An Azure AD App Registration with the following API permissions:
        -Yammer: access_as_user

.PARAMETER StartDate YYYY-MM-DD
    REQUIRED. Sets the start date for the target date range of the export
.PARAMETER EndDate YYYY-MM-DD
    OPTIONAL. Sets the end date for the target date range of the export. We recommend including this to set a reasonable range to avoid timeouts.
.PARAMETER IncludeFiles <all/csv>
    OPTIONAL. Set this to ‘all’ for CSVs (including messages) and all file attachments, or ‘csv’ for CSVs only (including messages), no file attachments.

.EXAMPLE
    .\Export-EngageNetworkData.ps1 -startdate 2023-01-14 -enddate 2023-01-31
#>

Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript(
    {
        try{
            [datetime]::ParseExact($psitem ,'yyyy-MM-dd' ,[System.Globalization.CultureInfo](Get-Culture))
        }
        catch{
            throw "StartDate is in the wrong format. Use format: YYYY-MM-DD"
            exit
        }    
    })]
    [string]$StartDate,

    [Parameter(Mandatory = $false)]
    [ValidateScript(
    {
        try{
            [datetime]::ParseExact($psitem ,'yyyy-MM-dd' ,[System.Globalization.CultureInfo](Get-Culture))
        }
        catch{
            throw "EndDate is in the wrong format. Use format: YYYY-MM-DD"
            exit
        }
    })]
    [string]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Csv', 'All')]
    [string]$IncludeFiles
)

<############    STUFF YOU NEED TO MODIFY    ############>
# Change these to match your environment. Instructions:
# https://learn.microsoft.com/en-us/graph/auth-v2-service?view=graph-rest-1.0
$ClientId = "clientid"
$TenantId = "tenantId"
$RedirectUri = "https://localhost"

#Change the folder path to an existing target location you want the output and log saved to
$rootPath = "C:\Temp"

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

$Scopes = @("https://api.yammer.com/.default")
#Check to see if MSAL.PS is installed, if not exit with instructions
if(-not (Get-Module -ListAvailable -Name MSAL.PS)){
    Write-Host "MSAL.PS module not found, please install it from the PowerShell Gallery with the command:" -ForegroundColor Red
    Write-Host "Install-Module MSAL.PS" -ForegroundColor Yellow
    Return
}   
function Get-YammerAuthHeader {
    $authToken = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -RedirectUri $RedirectUri -Scopes $Scopes -Interactive
    if (-not $authToken) {
        Write-Host "Failed to acquire Yammer Auth Token. Please ensure the ClientID, TenantID, and ClientSecret are correct." -ForegroundColor Red
        Return
    }
    else {
        return @{ AUTHORIZATION = "Bearer $($authToken.AccessToken)" }
    }
}

Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If($logfile) {
        if(!(Test-Path -Path $logfile )){
            $null = New-Item -Path $logfile -ItemType "file" -Force
        }
        Add-Content $logfile -Value $Line -Force
    }
    Else {
        Write-Output $Line
    }
}

#If EndDate wasn't specifid, set it to today for logging/path purposes since that's what the export will default to
if (!($PSBoundParameters.ContainsKey('EndDate'))){
    $EndDate = [DateTime]::Now.ToString("yyyy-MM-dd")
}

Write-Host "Starting export for date range $StartDate to $EndDate" -ForegroundColor Green

#Populating key vars
$activityLogName = "ScriptLog{0}.txt" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")
$activityLog = $rootPath + "\Export" +(Get-Date -Date $StartDate -format "yyyyMMdd") +"to" +(Get-Date -Date $EndDate -format "yyyyMMdd" ) +"\" +$activityLogName
$authHeader = Get-YammerAuthHeader

#Create a separate folder in $rootPath for the output of each export run
$exportPath = $rootPath +"\Export" +(Get-Date -Date $StartDate -format "yyyyMMdd") +"to" +(Get-Date -Date $EndDate -format "yyyyMMdd" )

if(!(Test-Path -Path $exportPath)){
    New-Item -ItemType directory -Path $exportPath | Out-Null
}
Write-Log -Level "INFO" -Message "Created output directory $exportPath" -logFile $activityLog

#Build the export request URL
$Uri = "https://www.yammer.com/api/v1/export?since=" +$(Get-Date -Date $StartDate -Format s)

#Optional params, only add what's populated to $Uri
if ($PSBoundParameters.ContainsKey('EndDate')) {
    $Uri += "&until=$(Get-Date -Date $EndDate -Format s)"
}

if ($PSBoundParameters.ContainsKey('IncludeFiles')) {
    $Uri += "&include=$IncludeFiles"
    if ($IncludeFiles -eq 'All') {
        $filesWarning = "-IncludeFiles All was specified, but per Microsoft's documentation this only applies to legacy (pre-native mode) Yammer networks. Native-mode Viva Engage networks will NOT return file attachments regardless of this setting - you'll only get SharePoint links in files.csv. See MC1230453 (retiring the equivalent admin center options March 13, 2026) and https://learn.microsoft.com/en-us/rest/api/yammer/network-data-export"
        Write-Host $filesWarning -ForegroundColor Yellow
        Write-Log -Level "WARN" -Message $filesWarning -logFile $activityLog
    }
}

#Send the network data export request
#Details: https://learn.microsoft.com/en-us/rest/api/yammer/network-data-export#how-this-api-works
try{
    Write-Log -Level "INFO" -Message "Sending network data export request. Uri: $Uri" -logFile $activityLog
    Write-Host "Sending export request"
    $dlOutputFile = $exportPath.ToString() +"\YammerFilesExport{0}.zip" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")
    Invoke-RestMethod -uri $Uri  -OutFile $dlOutputFile -Headers $authHeader
    Write-Log -Level "INFO" -Message "Export request successful, files downloaded to $dlOutputFile" -logFile $activityLog
    Write-Host "Export complete, the script log and export can be found in $exportPath" -ForegroundColor Green
}
catch{
    $e = $error[0]
    $l = $_.InvocationInfo.ScriptLineNumber

    if($_.Exception.Response.StatusCode.Value__ -eq "401")
    {
        $err401 = "Export api reported ACCESS DENIED. Please ensrure you're using a valid developer token for the YammerAuthToken variable."
        Write-Log -Level "ERROR" -Message "Export request failed on line $l, exiting script." -logFile $activityLog
        Write-Log -Level "ERROR" -Message $err401 -logFile $activityLog
        Write-Host $err401 "`nExiting script. See $activityLog for more information" -ForegroundColor Red
    }
    else{
        Write-Log -Level "ERROR" -Message "Export request failed on line $l, ending script" -logFile $activityLog
        Write-Log -Level "ERROR" -Message "Error Message: $($e.Exception.Message)" -logFile $activityLog
        Write-Log -Level "ERROR" -Message "Inner exception: $($e.ErrorDetails.Message)" -logFile $activityLog
        Write-Host "Failed while sending network data export request, see $activityLog for more information" -ForegroundColor Red
    }
    exit
}
