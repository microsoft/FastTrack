# ==================================================================
# Microsoft provides programming examples for illustration only, without warranty either expressed or
# implied, including, but not limited to, the implied warranties of merchantability and/or fitness 
# for a particular purpose.
# 
# This sample assumes that you are familiar with the programming language being demonstrated and the 
# tools used to create and debug procedures. Microsoft support professionals can help explain the 
# functionality of a particular procedure, but they will not modify these examples to provide added 
# functionality or construct procedures to meet your specific needs. if you have limited programming 
# experience, you may want to contact a Microsoft Certified Partner or the Microsoft fee-based consulting 
# line at (800) 936-5200.
#
# For more information about Microsoft Certified Partners, please # visit the following Microsoft Web site:
# https://partner.microsoft.com
# -------------------------------------------------------------------
#
# Purpose: Exports files and messages from a Yammer network for specific date ranges
# https://learn.microsoft.com/en-us/rest/api/yammer/network-data-export
#
# Requirements: Admin-created bearer token for Yammer app authentication:
# https://learn.microsoft.com/en-us/rest/api/yammer/app-registration
# https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058
#
# ===================================================================
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
    [string]$IncludeFiles,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('true', 'false')]
    [string]$IncludeExternalNetworks
)

<############    STUFF YOU NEED TO MODIFY    ############>
#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerTokenString"

#Change the folder path to an existing target location you want the output and log saved to
$rootPath = "C:\Temp"

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>
function Get-YammerAuthHeader {
    @{ AUTHORIZATION = "Bearer $YammerAuthToken" }
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
}

if ($PSBoundParameters.ContainsKey('IncludeExternalNetworks')) {
    $Uri += "&include_ens=$IncludeExternalNetworks"
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