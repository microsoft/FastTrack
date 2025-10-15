# Enhanced Export logs for Copilot Analytics Reporting, including Entra Users, Purview Audit Logs, etc. 
# This script can be used for the Copilot Purview Audit Dashboard, as well as, be used to generate an export of Entra users that can then be used to build an Organizational Data file for Copilot Analytics. 
# Features:
# - Export Entra Users Details including Manager Information (Can be used for Org Data Preparation)
# - Export Copilot Audit Logs (with filtering for Copilot interactions)
# - Export Purview Audit Logs (with Custom Operations filtering)
# - Export Microsoft 365 Copilot Usage Reports
# - Extensible for future export functions
# - Interactive startup menu

# Author: Alejandro Lopez | alejandro.lopez@microsoft.com
# Version: v20250924 

# Global configuration
$script:Config = @{
    DefaultOutputDirectory = $PWD.Path
    LogDirectory = $PWD.Path
    SessionActive = $false
    MGGraphSession = $null
    ExchangeSession = $null
}

# Function to create consistent output path
function Get-OutputPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$Extension = "csv",
        
        [Parameter(Mandatory = $false)]
        [string]$CustomPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateDirectory
    )
    
    # Use custom path if provided, otherwise use default directory
    $outputDir = if ([string]::IsNullOrWhiteSpace($CustomPath)) {
        $script:Config.DefaultOutputDirectory
    } else {
        $CustomPath
    }
    
    # Create directory if it doesn't exist
    if ($CreateDirectory -and -not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Created output directory: $outputDir" -ForegroundColor Green
    }
    
    # Generate filename with timestamp
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $fileName = if ([string]::IsNullOrWhiteSpace($BaseName)) {
        "Export_${timestamp}.${Extension}"
    } else {
        "${BaseName}_${timestamp}.${Extension}"
    }
    
    return Join-Path -Path $outputDir -ChildPath $fileName
}

# Function to get log file path
function Get-LogPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BaseName
    )
    
    return Get-OutputPath -BaseName "${BaseName}_Log" -Extension "log" -CreateDirectory
}

# Function to connect to Microsoft Graph
function Connect-ToMicrosoftGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Check if already connected
    if (-not $Force -and $script:Config.MGGraphSession) {
        Write-Host "Already connected to Microsoft Graph." -ForegroundColor Green
        return $true
    }
    
    try {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        # Added Organization.Read.All scope which is required for license information
        Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All", "Reports.Read.All", "Organization.Read.All" -ErrorAction Stop
        Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
        $script:Config.MGGraphSession = $true
        return $true
    }
    catch {
        Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
        return $false
    }
}

# Function to connect to Exchange Online (for Purview audit logs)
function Connect-ToExchangeOnline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Check if already connected
    if (-not $Force -and $script:Config.ExchangeSession) {
        Write-Host "Already connected to Exchange Online." -ForegroundColor Green
        return $true
    }
    
    try {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null
        Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
        $script:Config.ExchangeSession = $true
        return $true
    }
    catch {
        Write-Host "Error connecting to Exchange Online: $_" -ForegroundColor Red
        return $false
    }
}

# Function to disconnect from all services
function Disconnect-AllServices {
    [CmdletBinding()]
    param()
    
    try {
        if ($script:Config.MGGraphSession) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | out-Null
            $script:Config.MGGraphSession = $null
            Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
        }
        
        if ($script:Config.ExchangeSession) {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | out-Null
            $script:Config.ExchangeSession = $null
            Write-Host "Disconnected from Exchange Online." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "Error during disconnection: $_" -ForegroundColor Yellow
    }
}

# Function to export Entra Users details with license information
function Export-EntraUsersDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    
    # Generate consistent output paths
    $outputFilePath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        Get-OutputPath -BaseName "EntraUsersExport" -CreateDirectory
    } else {
        $OutputPath
    }
    
    $logFilePath = if ([string]::IsNullOrWhiteSpace($LogPath)) {
        Get-LogPath -BaseName "EntraUsersExport"
    } else {
        $LogPath
    }
    
    # Start logging
    Start-Transcript -Path $logFilePath -Append
    Write-Host "Starting Entra user export process. Log file: $logFilePath" -ForegroundColor Cyan
    
    if (-not (Connect-ToMicrosoftGraph)) {
        Write-Host "Cannot proceed with export. Microsoft Graph connection failed." -ForegroundColor Red
        Stop-Transcript
        return
    }
    
    try {
        Write-Host "Retrieving Entra users..." -ForegroundColor Cyan
        # First get all users with basic properties
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department, 
            CompanyName, AccountEnabled, CreatedDateTime, UserType, MobilePhone, OfficeLocation, 
            UsageLocation, City, Country, PostalCode, State, EmployeeHireDate, AssignedLicenses
        
        Write-Host "Retrieved $($users.Count) users from Entra directory." -ForegroundColor Green
        
        if ($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            Stop-Transcript
            return
        }
        
        # Try to get license information differently - use direct API call instead of Get-MgSubscribedSku
        Write-Host "Retrieving license SKU information using direct API call..." -ForegroundColor Cyan
        
        try {
            # Direct API call to get subscribed SKUs - this avoids the issue with Get-MgSubscribedSku
            $licenseSkus = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/subscribedSkus" -ErrorAction Stop
            
            # Create a hashtable for quick SKU lookup
            $skuLookup = @{}
            foreach ($sku in $licenseSkus.value) {
                $skuLookup[$sku.skuId] = $sku.skuPartNumber
            }
            
            Write-Host "Retrieved $($licenseSkus.value.Count) license SKUs." -ForegroundColor Green
        }
        catch {
            Write-Host "Could not retrieve license SKUs. Will proceed with just SKU IDs: $_" -ForegroundColor Yellow
            # Initialize an empty lookup
            $skuLookup = @{}
        }
        
        # Initialize progress bar parameters
        $progressParams = @{
            Activity = "Exporting Entra User Details"
            Status = "Processing users"
            PercentComplete = 0
        }
        
        # Display initial progress bar
        Write-Progress @progressParams
        
        # Create an array to store user details
        $userDetails = [System.Collections.Generic.List[PSObject]]::new()
        $totalUsers = $users.Count
        $processedUsers = 0
        $managersFound = 0
        $managersNotFound = 0
        
        # Process each user and update progress bar
        foreach ($user in $users) {
            # Update progress bar
            $processedUsers++
            $progressParams.PercentComplete = ($processedUsers / $totalUsers) * 100
            $progressParams.Status = "Processing user $processedUsers of $totalUsers"
            Write-Progress @progressParams
            
            # Initialize manager variables
            $managerId = $null
            $managerName = $null
            $managerEmail = $null
            
            # Get manager details using the beta endpoint that returns direct manager
            try {
                $managerEndpoint = "https://graph.microsoft.com/v1.0/users/$($user.Id)/manager"
                $manager = Invoke-MgGraphRequest -Method GET -Uri $managerEndpoint -ErrorAction SilentlyContinue
                
                if ($manager -and $manager.id) {
                    $managerId = $manager.id
                    $managerName = $manager.displayName
                    $managerEmail = $manager.mail
                    $managersFound++
                    Write-Verbose "Found manager for user $($user.UserPrincipalName): $managerName"
                }
                else {
                    $managersNotFound++
                    Write-Verbose "No manager found for user $($user.UserPrincipalName)"
                }
            }
            catch {
                $managersNotFound++
                Write-Verbose "Error retrieving manager for user $($user.UserPrincipalName): $_"
            }
            
            # Process licenses directly from the user object
            $licenseDetails = @()
            if ($user.AssignedLicenses) {
                foreach ($license in $user.AssignedLicenses) {
                    # Convert SKU ID to readable SKU part number using our lookup table
                    $skuFriendlyName = if ($skuLookup.ContainsKey($license.SkuId)) {
                        $skuLookup[$license.SkuId]
                    } else {
                        $license.SkuId  # Fall back to ID if not found in lookup
                    }
                    
                    $licenseDetails += $skuFriendlyName
                }
            }
            
            # Join license details into a semicolon-separated string
            $licensesStr = if ($licenseDetails.Count -gt 0) {
                $licenseDetails -join ";"
            } else {
                ""  # Empty string if no licenses
            }
            
            # Process user details with additional attributes
            $userDetails.Add([PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Email = $user.Mail
                JobTitle = $user.JobTitle
                Department = $user.Department
                Company = $user.CompanyName
                AccountEnabled = $user.AccountEnabled
                CreatedDateTime = $user.CreatedDateTime
                UserType = $user.UserType
                Id = $user.Id
                # Additional attributes
                MobilePhone = $user.MobilePhone
                OfficeLocation = $user.OfficeLocation
                UsageLocation = $user.UsageLocation
                City = $user.City
                Country = $user.Country
                PostalCode = $user.PostalCode
                State = $user.State
                EmployeeHireDate = $user.EmployeeHireDate
                ManagerId = $managerId
                ManagerName = $managerName
                ManagerEmail = $managerEmail
                # License information
                AssignedLicenses = $licensesStr
                LicenseCount = $licenseDetails.Count
            })
        }
        
        # Update progress for export phase
        $progressParams.Status = "Exporting data to CSV file"
        $progressParams.PercentComplete = 99
        Write-Progress @progressParams
        
        # Export to CSV
        $userDetails | Export-Csv -Path $outputFilePath -NoTypeInformation
        
        # Complete progress bar
        Write-Progress -Activity "Exporting Entra User Details" -Completed
        
        Write-Host "Export completed successfully. File saved to: $outputFilePath" -ForegroundColor Green
        Write-Host "Total users exported: $($userDetails.Count)" -ForegroundColor Green
        Write-Host "Users with managers found: $managersFound" -ForegroundColor Green
        Write-Host "Users without managers: $managersNotFound" -ForegroundColor Green
    }
    catch {
        Write-Host "Error exporting Entra users: $_" -ForegroundColor Red
    }
    finally {
        Stop-Transcript
    }
}

# Function to export Purview audit logs with filtering options
function Export-PurviewAuditLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Operations = @(),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = (Get-Date).AddDays(-7),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),
        
        [Parameter(Mandatory = $false)]
        [int]$ResultSize = 5000,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    
    # Generate consistent output paths
    $outputFilePath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        Get-OutputPath -BaseName "PurviewAuditLogs" -CreateDirectory
    } else {
        $OutputPath
    }
    
    $logFilePath = if ([string]::IsNullOrWhiteSpace($LogPath)) {
        Get-LogPath -BaseName "PurviewAuditLogs"
    } else {
        $LogPath
    }
    
    # Start logging
    Start-Transcript -Path $logFilePath -Append
    Write-Host "Starting Purview audit logs export process. Log file: $logFilePath" -ForegroundColor Cyan
    
    if (-not (Connect-ToExchangeOnline)) {
        Write-Host "Cannot proceed with export. Exchange Online connection failed." -ForegroundColor Red
        Stop-Transcript
        return
    }
    
    try {
        # Format dates for the Search-UnifiedAuditLog cmdlet
        $startDateStr = $StartDate.ToString("MM/dd/yyyy")
        $endDateStr = $EndDate.ToString("MM/dd/yyyy")
        
        Write-Host "Retrieving Purview audit logs for operations: $($Operations -join ', ')" -ForegroundColor Cyan
        Write-Host "Time range: $startDateStr to $endDateStr" -ForegroundColor Cyan
        
        # Build operations filter if specified
        $params = @{
            StartDate = $startDateStr
            EndDate = $endDateStr
            ResultSize = $ResultSize
        }
        
        # Only add Operations parameter if operations were explicitly specified
        # This is critical: if Operations is an empty array, we want ALL operations
        # Adding an empty Operations parameter will incorrectly filter the results
        if ($Operations.Count -gt 0) {
            $operationsFilter = $Operations -join ","
            $params.Operations = $operationsFilter
            Write-Host "Filtering for specific operations: $operationsFilter" -ForegroundColor Yellow
        }
        else {
            Write-Host "No operations filter applied - will retrieve ALL operations" -ForegroundColor Yellow
        }
        
        # Initialize progress bar with more descriptive activity
        $operationDescription = if ($Operations.Count -gt 0) {
            "for $($Operations -join ', ')"
        } else {
            "for ALL operations"
        }
        
        $progressParams = @{
            Activity = "Retrieving Purview Audit Logs $operationDescription"
            Status = "Initializing search..."
            PercentComplete = 5
        }
        Write-Progress @progressParams
        
        # Retrieve audit logs
        Write-Host "Executing Search-UnifiedAuditLog with parameters:" -ForegroundColor Cyan
        $params | Format-Table | Out-String | Write-Host
        
        # Update progress for search phase
        $progressParams.Status = "Searching for audit logs... (this may take a while for ALL operations)"
        $progressParams.PercentComplete = 10
        Write-Progress @progressParams
        
        # Start time measurement for the search
        $searchStartTime = Get-Date
        
        # Execute the search
        $auditLogs = Search-UnifiedAuditLog @params
        
        # Calculate and display search duration
        $searchDuration = (Get-Date) - $searchStartTime
        Write-Host "Search completed in $($searchDuration.TotalSeconds.ToString("0.00")) seconds." -ForegroundColor Cyan
        
        if ($null -eq $auditLogs -or $auditLogs.Count -eq 0) {
            Write-Host "No audit logs found for the specified criteria." -ForegroundColor Yellow
            Stop-Transcript
            return
        }
        
        Write-Host "Retrieved $($auditLogs.Count) audit log entries." -ForegroundColor Green
        
        # Update progress for processing phase
        $progressParams.Status = "Processing audit logs"
        $progressParams.PercentComplete = 30
        Write-Progress @progressParams
        
        Write-Host "Processing $($auditLogs.Count) audit log entries..." -ForegroundColor Cyan
        
        # Process and expand the audit data
        $totalLogs = $auditLogs.Count
        $processedLogs = [System.Collections.Generic.List[PSObject]]::new($totalLogs)
        $processedCount = 0
        $errorCount = 0
        
        foreach ($log in $auditLogs) {
            $processedCount++
            
            # Update progress - adapt frequency based on total number of logs
            # For larger datasets, update less frequently to improve performance
            $updateFrequency = [Math]::Max(1, [Math]::Min(100, [Math]::Floor($totalLogs / 100)))
            
            if ($processedCount % $updateFrequency -eq 0 || $processedCount -eq 1 || $processedCount -eq $totalLogs) {
                $percentComplete = 30 + (($processedCount / $totalLogs) * 60) # Scale from 30% to 90%
                $progressParams.Status = "Processing log $processedCount of $totalLogs [$('{0:P1}' -f ($processedCount/$totalLogs))]"
                $progressParams.PercentComplete = $percentComplete
                Write-Progress @progressParams
            }
            
            $auditData = $null
            try {
                $auditData = $log.AuditData | ConvertFrom-Json
                
                # Create a custom object with the relevant properties
                $processedLog = [PSCustomObject]@{
                    CreationDate = $log.CreationDate
                    UserIds = $log.UserIds
                    Operations = $log.Operations
                    RecordType = $log.RecordType
                    Id = $log.Id
                    Workload = $auditData.Workload
                    ObjectId = $auditData.ObjectId
                    UserId = $auditData.UserId
                    ClientIP = $auditData.ClientIP
                    UserAgent = $auditData.UserAgent
                    Operation = $auditData.Operation
                    ResultStatus = $auditData.ResultStatus
                    # For Copilot interactions, include specific fields if available
                    CopilotPrompt = if ($auditData.Operation -eq "CopilotInteraction") { $auditData.CopilotPrompt } else { $null }
                    CopilotResponse = if ($auditData.Operation -eq "CopilotInteraction") { $auditData.CopilotResponse } else { $null }
                    CopilotContext = if ($auditData.Operation -eq "CopilotInteraction") { $auditData.CopilotContext } else { $null }
                    Application = $auditData.Application
                    AuditData = $log.AuditData # Include the full JSON for reference
                }
                
                $processedLogs.Add($processedLog)
            }
            catch {
                $errorCount++
                Write-Host "Error parsing AuditData for record: $($log.Id) - $_" -ForegroundColor Yellow
            }
        }
        
        # Final progress update for export
        $progressParams.Status = "Exporting $($processedLogs.Count) records to CSV..."
        $progressParams.PercentComplete = 95
        Write-Progress @progressParams
        
        # Export the processed data
        $processedLogs | Export-Csv -Path $outputFilePath -NoTypeInformation
        
        # Update progress to 100% before completing
        $progressParams.Status = "Export complete!"
        $progressParams.PercentComplete = 100
        Write-Progress @progressParams
        
        # Complete progress bar - use the same activity name as initialized
        Write-Progress -Activity $progressParams.Activity -Completed
        
        Write-Host "Export completed successfully. File saved to: $outputFilePath" -ForegroundColor Green
        Write-Host "Total records exported: $($processedLogs.Count)" -ForegroundColor Green
        if ($errorCount -gt 0) {
            Write-Host "Errors encountered during processing: $errorCount" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error exporting Purview audit logs: $_" -ForegroundColor Red
    }
    finally {
        Stop-Transcript
    }
}

function Export-CopilotAuditLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$DaysToSearch = 180,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFileName,

        [Parameter(Mandatory = $false)]
        [int]$IntervalDays = 1
    )
    
    # Generate consistent output paths with a sensible default
    $outputDir = if ([string]::IsNullOrWhiteSpace($OutputFolder)) {
        $PSScriptRoot # Default to the script's current directory
    } else {
        $OutputFolder
    }
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Created output folder: $outputDir" -ForegroundColor Green
    }
    
    # Generate output filename
    $outputFile = if ([string]::IsNullOrWhiteSpace($OutputFileName)) {
        Join-Path -Path $outputDir -ChildPath "Copilot_Activities_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    } else {
        Join-Path -Path $outputDir -ChildPath $OutputFileName
    }
    
    $logFile = Join-Path -Path $outputDir -ChildPath "CopilotAuditLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    # Helper function to handle error messages
    function Write-ErrorDetails {
        param ([System.Management.Automation.ErrorRecord]$ErrorRecord)
        $message = "Error occurred: $($ErrorRecord.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        Write-Host "ScriptStackTrace: $($ErrorRecord.ScriptStackTrace)" -ForegroundColor Red
        Write-LogFile $message
    }
    
    # Helper function to write to the log file
    function Write-LogFile ([String]$Message) {
        $final = [DateTime]::Now.ToUniversalTime().ToString("s") + ":" + $Message
        $final | Out-File $logFile -Append
    }
    
    # Helper function to determine Copilot application and location
    function Get-CopilotAppAndLocation {
        param ([PSCustomObject]$AuditData)
        
        $CopilotApp = 'Copilot for M365'
        $CopilotLocation = $null
        
        # Refine app type based on specific AppHost values first
        switch ($AuditData.CopilotEventData.AppHost) {
            "bizchat"       { $CopilotApp = "Copilot for M365 Chat"; break }
            "Outlook"       { $CopilotApp = "Outlook"; break }
            "Copilot Studio"{ $CopilotApp = "Copilot Studio Agent"; break }
            "Word"          { $CopilotApp = "Word"; break }
            "Excel"         { $CopilotApp = "Excel"; break }
            "PowerPoint"    { $CopilotApp = "PowerPoint"; break }
            "Teams"         { $CopilotApp = "Teams"; break }
            "Bing"          { $CopilotApp = "Bing"; break }
        }

        # Use context type as a fallback or for additional detail
        if ($AuditData.copiloteventdata.contexts.type) {
             switch ($AuditData.copiloteventdata.contexts.type) {
                "TeamsMeeting" { $CopilotLocation = "Teams meeting" }
                "StreamVideo"  { $CopilotApp = "Stream"; $CopilotLocation = "Stream video player" }
             }
        }
       
        if ($AuditData.AppIdentity -like "*Copilot.Studio*") {
            $CopilotApp = "Copilot Studio Agent"
        }
        
        # Determine location from context ID
        if ($AuditData.copiloteventdata.contexts.id -like "*/sites/*") {
            $CopilotLocation = "SharePoint Online"
        } elseif ($AuditData.copiloteventdata.contexts.id -like "*https://teams.microsoft.com/*") {
            $CopilotLocation = if ($AuditData.copiloteventdata.contexts.id -like "*ctx=channel*") { "Teams Channel" } else { "Teams Chat" }
        } elseif ($AuditData.copiloteventdata.contexts.id -like "*/personal/*") {
            $CopilotLocation = "OneDrive for Business"
        }
        
        # Extract agent name from AppIdentity (legacy approach)
        $AgentNameLegacy = ""
        if ($CopilotApp -eq "Copilot Studio Agent" -and $AuditData.AppIdentity -match '.*[_-](.+?)$') {
            $AgentNameLegacy = $Matches[1]
        }
        
        return @{ App = $CopilotApp; Location = $CopilotLocation; AgentNameLegacy = $AgentNameLegacy }
    }
    
    # Helper function to convert JSON AuditData to a flattened object
    function Convert-AuditDataToObject {
        param ([string]$AuditDataJson, [string]$UserID, [datetime]$CreationTime)
        
        try {
            # Helper scriptblock to sanitize strings for CSV export
            $Sanitizer = {
                param($InputString)
                if ($null -eq $InputString) { return $null }
                # Replace one or more newline/carriage return characters with a single space
                $cleaned = $InputString -replace "[\r\n]+", " "
                # Truncate if the string is excessively long
                if ($cleaned.Length -gt 500) {
                    return $cleaned.Substring(0, 497) + "..."
                }
                return $cleaned
            }

            $auditDataObj = $AuditDataJson | ConvertFrom-Json
            $copilotData = $auditDataObj.CopilotEventData
            $appInfo = Get-CopilotAppAndLocation -AuditData $auditDataObj
            
            $Context = $auditDataObj.copiloteventdata.contexts.id ?? $auditDataObj.copiloteventdata.threadid
            
            # Defensively access potentially null properties
            $accessedResources = $copilotData.AccessedResources ?? @()
            $messages = $copilotData.Messages ?? @()
            $contexts = $copilotData.Contexts ?? @()
            $plugins = $copilotData.AISystemPlugin ?? @()
            $models = $copilotData.ModelTransparencyDetails ?? @()

            # Extract declarative agent details from the audit data
            $AgentId = $auditDataObj.AgentId ?? ""
            $AgentName = $auditDataObj.AgentName ?? ""
            $AgentVersion = $auditDataObj.AgentVersion ?? ""
            
            # Determine agent category based on AgentId format
            $AgentCategory = ""
            if ($AgentId) {
                if ($AgentId -like "CopilotStudio.Declarative.*") {
                    $AgentCategory = "Declarative Agent"
                } elseif ($AgentId -like "CopilotStudio.CustomEngine.*") {
                    $AgentCategory = "Custom Engine Agent"
                } elseif ($AgentId -like "P_*") {
                    $AgentCategory = "Declarative Agent (Purview)"
                } else {
                    $AgentCategory = "Other Agent"
                }
            }
            
            # Fallback to legacy agent name extraction if new fields are empty
            if ([string]::IsNullOrWhiteSpace($AgentName) -and -not [string]::IsNullOrWhiteSpace($appInfo.AgentNameLegacy)) {
                $AgentName = $appInfo.AgentNameLegacy
            }

            # Create a custom object with flattened properties
            return [PSCustomObject][Ordered]@{
                TimeStamp                 = (Get-Date $CreationTime -format "yyyy-MM-dd HH:mm:ss")
                RecordID                  = $auditDataObj.Id
                User                      = $UserID
                ClientRegion              = $auditDataObj.ClientRegion
                App                       = $appInfo.App
                AgentName                 = $AgentName
                AgentId                   = $AgentId
                AgentVersion              = $AgentVersion
                AgentCategory             = $AgentCategory
                Location                  = $appInfo.Location
                AppHost                   = $copilotData.AppHost
                AppIdentity               = $auditDataObj.AppIdentity
                AppContext                = $Context
                ThreadId                  = $copilotData.ThreadId
                AISystemPlugins           = ($plugins | ForEach-Object { "$($_.Id):$($_.Name)" }) -join '; '
                ModelDetails              = ($models.ModelName) -join '; '
                ContextTypes              = ($contexts.Type) -join '; '
                HasPrompt                 = @($messages.isPrompt).Contains($true)
                HasResponse               = @($messages.isPrompt).Contains($false)
                MessageCount              = $messages.Count
                AccessedResourceCount     = $accessedResources.Count
                AccessedResourceNames     = (($accessedResources.Name | Sort-Object -Unique | ForEach-Object { & $Sanitizer $_ }) -join ", ")
                AccessedResourceLocations = (($accessedResources.id | Sort-Object -Unique) -join ", ")
                AccessedResourceUrls      = (($accessedResources.SiteUrl | Sort-Object -Unique) -join ", ")
                AccessedResourceTypes     = (($accessedResources.Type | Sort-Object -Unique) -join ", ")
                AccessedResourceActions   = (($accessedResources.action | Sort-Object -Unique | ForEach-Object { & $Sanitizer $_ }) -join ", ")
                Workload                  = $auditDataObj.Workload
                OrganizationId            = $auditDataObj.OrganizationId
                CopilotLogVersion         = $auditDataObj.CopilotLogVersion
                IsCopilotStudio           = $appInfo.App -eq "Copilot Studio Agent"
                IsCustomAgent             = ($appInfo.App -eq "Copilot Studio Agent") -and ($AgentName -ne "")
                IsSPOAgent                = $copilotData.AppHost -eq "SharePoint"
                IsDeclarativeAgent        = ($AgentCategory -like "*Declarative*")
                AuditDataJson             = & $Sanitizer $AuditDataJson
            }
        } catch { Write-ErrorDetails -ErrorRecord $_; return $null }
    }
    
    # This variable will hold the connection status for the finally block
    $isConnected = $false
    # This variable will hold the final results to be returned
    $functionResults = $null

    try {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null
        $isConnected = $true
        Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
        Write-LogFile "Successfully connected to Exchange Online."
        
        $endDate = (Get-Date).ToUniversalTime().Date.AddDays(1).AddSeconds(-1)
        $startDate = (Get-Date).ToUniversalTime().Date.AddDays(-$DaysToSearch)
        
        $allResults = [System.Collections.Generic.List[Object]]::new()
        $batchSize = 5000

        Write-LogFile "BEGIN: Retrieving audit records from $startDate to $endDate"
        Write-Host "Searching audit logs for Copilot interactions from $startDate to $endDate" -ForegroundColor Yellow
        Write-Host "Using $IntervalDays-day intervals for reliability." -ForegroundColor Yellow
        
        $progressParams = @{ Activity = "Retrieving Copilot Audit Logs"; Status = "Initializing..." }
        Write-Progress @progressParams

        $totalIntervals = [math]::Ceiling(($endDate - $startDate).TotalDays / $IntervalDays)
        $intervalCounter = 0
        $currentStart = $startDate

        while ($currentStart -le $endDate) {
            $intervalCounter++
            $currentEnd = ($currentStart.AddDays($IntervalDays)).AddSeconds(-1)
            if ($currentEnd -gt $endDate) { $currentEnd = $endDate }
            
            $progressParams.Status = "Interval $intervalCounter of $totalIntervals : $($currentStart.ToString('yyyy-MM-dd'))"
            Write-Progress @progressParams -PercentComplete (($intervalCounter / $totalIntervals) * 50)
            
            Write-Host "`nProcessing interval: $currentStart to $currentEnd" -ForegroundColor Cyan
            
            $sessionID = [Guid]::NewGuid().ToString() + "_CopilotAudit"
            $intervalResults = [System.Collections.Generic.List[Object]]::new()
            $hasMoreRecords, $isFirstRequest = $true, $true
            $pageCount, $retryCount, $maxRetries = 0, 0, 3
            
            # ✅ FIX: Track if we've hit the 50,000 limit
            $maxResultsPerSession = 50000
            
            while ($hasMoreRecords -and $retryCount -lt $maxRetries) {
                $pageCount++
                Write-Host "  Fetching page $pageCount..." -ForegroundColor Gray
                try {
                    $searchParams = @{ 
                        SessionId = $sessionID
                        StartDate = $currentStart
                        EndDate = $currentEnd
                        ErrorAction = "Stop"
                        SessionCommand = "ReturnLargeSet"
                    }
                    
                    # Only add RecordType and ResultSize on the FIRST request
                    if ($isFirstRequest) {
                        $searchParams.RecordType = "CopilotInteraction"
                        $searchParams.ResultSize = $batchSize
                    }
                    
                    $batchResults = @(Search-UnifiedAuditLog @searchParams)
                    $isFirstRequest = $false
                    
                    if ($null -ne $batchResults -and $batchResults.Count -gt 0) {
                        $intervalResults.AddRange($batchResults)
                        Write-Host "    Retrieved $($batchResults.Count) records. Interval total: $($intervalResults.Count)"
                        
                        # ✅ FIX: Use proper pagination logic instead of relying on ResultCount
                        # Stop when we receive fewer results than the batch size OR hit the 50,000 limit
                        if ($batchResults.Count -lt $batchSize) {
                            $hasMoreRecords = $false
                            Write-Host "    Received fewer results than batch size. All available records retrieved." -ForegroundColor Green
                        } elseif ($intervalResults.Count -ge $maxResultsPerSession) {
                            $hasMoreRecords = $false
                            Write-Host "    ⚠️  Hit the 50,000 record limit for this interval!" -ForegroundColor Yellow
                            Write-Host "    Consider using smaller time intervals to capture all data." -ForegroundColor Yellow
                        }
                        
                        $retryCount = 0
                    } else { 
                        $hasMoreRecords = $false
                        Write-Host "    No more records found for this interval."
                    }
                } catch {
                    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
                    $retryCount++
                    if ($retryCount -ge $maxRetries) {
                        Write-Host "    Max retries reached. Moving on..." -ForegroundColor Yellow
                        $hasMoreRecords = $false
                    } else {
                        $delay = if ($_.Exception.Message -like "*throttl*") { 60 } else { 30 }
                        Write-Host "    Waiting $delay seconds before retrying (Attempt $retryCount of $maxRetries)..." -ForegroundColor Yellow
                        Start-Sleep -Seconds $delay
                    }
                }
            }
            
            Write-Host "  Interval complete: Retrieved $($intervalResults.Count) total records" -ForegroundColor $(if ($intervalResults.Count -ge $maxResultsPerSession) { 'Yellow' } else { 'Green' })
            $allResults.AddRange($intervalResults)
            $currentStart = $currentEnd.AddSeconds(1).Date
        }

        if ($allResults.Count -eq 0) { 
            Write-Host "No audit log entries found." -ForegroundColor Yellow
            Write-LogFile "No audit log entries found."
            return 
        }

        # Deduplicate the raw results first before the expensive conversion process
        Write-Host "`nDeduplicating $($allResults.Count) raw records..." -ForegroundColor Cyan
        $uniqueRawResults = $allResults | Group-Object { 
            ($_.AuditData | ConvertFrom-Json).Id 
        } | ForEach-Object { $_.Group[0] }
        $dupCount = $allResults.Count - $uniqueRawResults.Count
        if ($dupCount -gt 0) { 
            Write-Host "Removed $dupCount duplicate raw records before processing." -ForegroundColor Yellow 
        }
        
        Write-Host "Processing $($uniqueRawResults.Count) unique records..." -ForegroundColor Cyan
        $progressParams.Activity = "Processing Records"
        $processedResults = [System.Collections.Generic.List[Object]]::new()
        $counter = 0

        foreach ($entry in $uniqueRawResults) {
            $counter++
            $progressParams.Status = "Record $counter of $($uniqueRawResults.Count)"
            Write-Progress @progressParams -PercentComplete (50 + (($counter / $uniqueRawResults.Count) * 50))
            $processedResult = Convert-AuditDataToObject -AuditDataJson $entry.AuditData -UserID $entry.UserIds -CreationTime $entry.CreationDate
            if ($processedResult) { $processedResults.Add($processedResult) }
        }

        Write-Progress @progressParams -Completed
        
        if ($processedResults.Count -gt 0) {
            Write-Host "`nExporting $($processedResults.Count) unique records to $outputFile..." -ForegroundColor Cyan
            $processedResults | Export-Csv -Path $outputFile -NoTypeInformation
            Write-Host "✅ Export completed successfully!" -ForegroundColor Green
            Write-LogFile "END: Exported $($processedResults.Count) records to $outputFile."
            
            # Display summary statistics
            Write-Host "`n📊 Summary Statistics:" -ForegroundColor Cyan
            Write-Host "   Total interactions: $($processedResults.Count)" -ForegroundColor Green
            
            $agentStats = $processedResults | Where-Object { $_.IsDeclarativeAgent } | Measure-Object
            if ($agentStats.Count -gt 0) {
                Write-Host "`n📊 Declarative Agent Summary:" -ForegroundColor Cyan
                Write-Host "   Total declarative agent interactions: $($agentStats.Count)" -ForegroundColor Green
                $uniqueAgents = $processedResults | Where-Object { $_.IsDeclarativeAgent -and $_.AgentName } | Select-Object -ExpandProperty AgentName -Unique
                Write-Host "   Unique agents found: $($uniqueAgents.Count)" -ForegroundColor Green
                if ($uniqueAgents.Count -gt 0 -and $uniqueAgents.Count -le 10) {
                    Write-Host "   Agent names: $($uniqueAgents -join ', ')" -ForegroundColor Gray
                }
            }
        } else { 
            Write-Host "No processed records available to export." -ForegroundColor Yellow 
        }
        
        # Assign the clean data to the variable that will be returned
        $functionResults = $processedResults
    }
    catch {
        Write-ErrorDetails -ErrorRecord $_
    }
    finally {
        if ($isConnected) {
            Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
            Get-PSSession | ForEach-Object { Disconnect-ExchangeOnline -PSSession $_ -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
        }
    }

    return $functionResults
}

# Function to export Microsoft 365 Copilot usage reports
function Export-CopilotUsageReports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("D7", "D30", "D90", "D180")]
        [string]$Period = "D30",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    
    # Generate consistent output paths
    $outputDir = if ([string]::IsNullOrWhiteSpace($OutputFolder)) {
        $script:Config.DefaultOutputDirectory
    } else {
        $OutputFolder
    }
    
    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Created output directory: $outputDir" -ForegroundColor Green
    }
    
    $logFilePath = if ([string]::IsNullOrWhiteSpace($LogPath)) {
        Get-LogPath -BaseName "CopilotUsageReports"
    } else {
        $LogPath
    }
    
    # Start logging
    Start-Transcript -Path $logFilePath -Append
    Write-Host "Starting Microsoft 365 Copilot usage reports export. Log file: $logFilePath" -ForegroundColor Cyan
    
    try {
        # Connect to Microsoft Graph with appropriate scopes - use our fixed connect function
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        if (-not (Connect-ToMicrosoftGraph)) {
            Write-Host "Cannot proceed with export. Microsoft Graph connection failed." -ForegroundColor Red
            Stop-Transcript
            return
        }
        Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
        Stop-Transcript
        return
    }
    
    try {
        
        # Get Copilot user usage details using direct REST API call
        Write-Host "Retrieving Copilot usage details for period: $Period..." -ForegroundColor Yellow
        Write-Host "This may take some time depending on the amount of data..." -ForegroundColor Yellow
        
        $uri = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')"
        Write-Host "API URI: $uri" -ForegroundColor Gray
        
        # Initialize progress bar parameters
        $progressParams = @{
            Activity = "Retrieving Copilot Usage Data"
            Status = "Fetching data from Microsoft Graph..."
            PercentComplete = 10
        }
        
        # Display initial progress bar
        Write-Progress @progressParams
        
        # Use Invoke-MgGraphRequest directly instead of module-specific cmdlets
        $CopilotUsageDetails = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        
        # Update progress for processing phase
        $progressParams.Status = "Processing data..."
        $progressParams.PercentComplete = 50
        Write-Progress @progressParams
        
        if ($null -eq $CopilotUsageDetails -or $null -eq $CopilotUsageDetails.value) {
            Write-Host "No Copilot usage data was returned. The response may be empty." -ForegroundColor Red
            Write-Host "Response content:" -ForegroundColor Yellow
            $CopilotUsageDetails | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
            Stop-Transcript
            return
        }
        
        Write-Host "Retrieved data for $($CopilotUsageDetails.value.Count) users." -ForegroundColor Green
        
        # Create an array to store the usage data
        $UsageData = [System.Collections.Generic.List[PSObject]]::new($CopilotUsageDetails.value.Count)
        
        #get Date and Time and format as string
        $formattedDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Initialize the progress bar
        $totalUsers = $CopilotUsageDetails.value.Count
        $currentUser = 0
        
        Write-Host "Processing data for $totalUsers users..." -ForegroundColor Yellow
        
        # Loop through each user and extract the usage details
        foreach ($User in $CopilotUsageDetails.value) {
            # Update progress bar
            $currentUser++
            $progressParams.PercentComplete = 50 + (($currentUser / $totalUsers) * 50)
            $progressParams.Status = "Processing user $currentUser of $totalUsers"
            
            if ($currentUser % 100 -eq 0 || $currentUser -eq 1 || $currentUser -eq $totalUsers) {
                Write-Progress @progressParams
            }
            
            $UsageData.Add([PSCustomObject]@{
                reportRefreshDate = $User.reportRefreshDate
                UserPrincipalName = $User.UserPrincipalName
                DisplayName = $User.DisplayName
                LastActivityDate = $User.LastActivityDate
                copilotChatLastActivityDate = $User.copilotChatLastActivityDate
                microsoftTeamsCopilotLastActivityDate = $user.microsoftTeamsCopilotLastActivityDate
                wordCopilotLastActivityDate = $user.wordCopilotLastActivityDate
                excelCopilotLastActivityDate = $user.excelCopilotLastActivityDate
                powerPointCopilotLastActivityDate = $user.powerPointCopilotLastActivityDate
                outlookCopilotLastActivityDate = $user.outlookCopilotLastActivityDate
                oneNoteCopilotLastActivityDate = $user.oneNoteCopilotLastActivityDate
                loopCopilotLastActivityDate = $user.loopCopilotLastActivityDate   
            })
        }
        
        # Complete the progress bar
        Write-Progress -Activity "Retrieving Copilot Usage Data" -Completed
        
        Write-Host "$($UsageData.Count) usage data records processed" -ForegroundColor Green
        
        # Create the file path
        $outputFilePath = Join-Path -Path $outputDir -ChildPath "CopilotUsageDetails_${formattedDateTime}.csv"
        Write-Host "Exporting data to: $outputFilePath" -ForegroundColor Yellow
        
        # Export the usage data to a CSV file
        $UsageData | Export-Csv -Path $outputFilePath -NoTypeInformation
        
        Write-Host "Copilot user usage details have been exported to: $outputFilePath" -ForegroundColor Green
        
        # Return the data for further processing if needed
        #$null = return $UsageData
    }
    catch {
        Write-Host "Error in Export-CopilotUsageReports: $_" -ForegroundColor Red
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $_.Exception -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Host "Status code: $statusCode" -ForegroundColor Red
            
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $errorContent = $reader.ReadToEnd()
                Write-Host "Error response content: $errorContent" -ForegroundColor Red
            }
            catch {
                Write-Host "Could not read error response: $_" -ForegroundColor Red
            }
        }
    }
    finally {
        Stop-Transcript
    }
}

# Function to display the main menu and handle user choices
function Show-MainMenu {
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "    Microsoft 365 Copilot Analytics Reporting Tool" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Export Entra Users Details" -ForegroundColor White
    Write-Host "2. Export Purview Audit Logs (Copilot Interactions Only)" -ForegroundColor White
    Write-Host "3. Export Microsoft 365 Copilot Usage Reports (Beta endpoints)" -ForegroundColor White
    Write-Host "4. Exit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your selection (1-5)"
    
    switch ($choice) {
        "1" {
            # Entra Users Export
            Clear-Host
            Write-Host "Entra Users Export:" -ForegroundColor Cyan
            $outputPath = Read-Host "Enter output path (leave blank for default)"
            
            if ([string]::IsNullOrWhiteSpace($outputPath)) {
                Export-EntraUsersDetails
            }
            else {
                Export-EntraUsersDetails -OutputPath $outputPath
            }
            
            Pause
            Show-MainMenu
        }
        "2" {
            # Purview Audit Logs Export - Copilot Interactions Only
            Clear-Host
            Write-Host "Purview Audit Logs Export (Copilot Interactions Only):" -ForegroundColor Cyan
            $outputPath = Read-Host "Enter output folder path (leave blank for default)"

            $defaultDays = 7
            $daysInput = Read-Host "Enter number of days to look back (default: $defaultDays)"
            if ([string]::IsNullOrWhiteSpace($daysInput)) {
                $days = $defaultDays
            }
            else {
                $days = [int]$daysInput
            }

            # Setup parameters for the Export-CopilotAuditLogs function
            $params = @{
                DaysToSearch = $days
            }

            # Add output folder if specified
            if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
                $params.OutputFolder = $outputPath
            }

            # Get a custom filename if wanted
            $customFileName = Read-Host "Enter custom output filename (leave blank for default)"
            if (-not [string]::IsNullOrWhiteSpace($customFileName)) {
                $params.OutputFileName = $customFileName
            }

            Write-Host "Exporting Copilot Interactions..." -ForegroundColor Yellow
            Write-Host "This will retrieve audit logs for the past $days days" -ForegroundColor Yellow

            # Call the new function with parameters
            $results = Export-CopilotAuditLogs @params

            Pause
            Show-MainMenu
        }
        "Future" {
            # Purview Audit Logs Export - Custom Operations
            Clear-Host
            Write-Host "Purview Audit Logs Export (Custom Operations):" -ForegroundColor Cyan
            $outputPath = Read-Host "Enter output path (leave blank for default)"
            
            $operationsInput = Read-Host "Enter operations to filter by (comma-separated, leave blank for ALL operations)"
            $operations = @()
            if (-not [string]::IsNullOrWhiteSpace($operationsInput)) {
                $operations = $operationsInput -split "," | ForEach-Object { $_.Trim() }
            }
            
            $defaultDays = 7
            $daysInput = Read-Host "Enter number of days to look back (default: $defaultDays)"
            if ([string]::IsNullOrWhiteSpace($daysInput)) {
                $days = $defaultDays
            }
            else {
                $days = [int]$daysInput
            }
            
            $startDate = (Get-Date).AddDays(-$days)
            $endDate = Get-Date
            
            $resultSize = 5000
            $resultSizeInput = Read-Host "Enter maximum number of results to retrieve (default: $resultSize)"
            if (-not [string]::IsNullOrWhiteSpace($resultSizeInput)) {
                $resultSize = [int]$resultSizeInput
            }
            
            $params = @{
                StartDate = $startDate
                EndDate = $endDate
                ResultSize = $resultSize
            }
            
            if ($operations.Count -gt 0) {
                $params.Operations = $operations
                Write-Host "Using operations filter: $($operations -join ', ')" -ForegroundColor Yellow
            }
            else {
                Write-Host "No operations filter specified. Retrieving ALL operations." -ForegroundColor Yellow
                # Important: Do NOT add an Operations parameter when we want ALL operations
                # The Search-UnifiedAuditLog cmdlet will return all operations when no Operations parameter is specified
            }
            
            if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
                $params.OutputPath = $outputPath
            }
            
            Export-PurviewAuditLogs @params
            
            Pause
            Show-MainMenu
        }
        "3" {
            # Copilot Usage Reports Export
            Clear-Host
            Write-Host "Microsoft 365 Copilot Usage Reports Export:" -ForegroundColor Cyan
            $outputFolder = Read-Host "Enter output folder path (leave blank for default)"
            
            $periods = @("D7", "D30", "D90", "D180")
            Write-Host "Available time periods:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $periods.Count; $i++) {
                Write-Host "$($i+1). $($periods[$i])" -ForegroundColor White
            }
            
            $periodChoice = Read-Host "Select time period (1-4, default is D30)"
            $period = "D30"
            
            if (-not [string]::IsNullOrWhiteSpace($periodChoice) -and $periodChoice -match "^[1-4]$") {
                $period = $periods[[int]$periodChoice - 1]
            }
            
            $params = @{
                Period = $period
            }
            
            if (-not [string]::IsNullOrWhiteSpace($outputFolder)) {
                $params.OutputFolder = $outputFolder
            }
            
            Export-CopilotUsageReports @params
            
            Pause
            Show-MainMenu
        }
        "4" {
            # Exit
            Clear-Host
            Write-Host "Exiting Microsoft 365 Copilot Analytics Reporting Tool." -ForegroundColor Cyan
            # Make sure to disconnect all services before exiting
            Disconnect-AllServices
            return
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Show-MainMenu
        }
    }
}

# Function to verify required modules are installed
function Test-RequiredModules {
    $requiredModules = @("Microsoft.Graph", "ExchangeOnlineManagement")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Host "The following required modules are missing:" -ForegroundColor Red
        foreach ($module in $missingModules) {
            Write-Host "- $module" -ForegroundColor Yellow
        }
        
        $install = Read-Host "Do you want to install these modules now? (Y/N)"
        if ($install -eq "Y" -or $install -eq "y") {
            foreach ($module in $missingModules) {
                try {
                    Write-Host "Installing module: $module..." -ForegroundColor Cyan
                    Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                    Write-Host "Successfully installed $module." -ForegroundColor Green
                }
                catch {
                    Write-Host "Error installing $module : $_" -ForegroundColor Red
                    return $false
                }
            }
            return $true
        }
        else {
            Write-Host "Cannot proceed without required modules. Exiting..." -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

# Main script execution starts here
function Start-CopilotReportingTool {
    # Check if required modules are installed
    if (-not (Test-RequiredModules)) {
        return
    }
    
    # Display the main menu
    Show-MainMenu
}

# Register the cleanup handler for script termination
try {
    # Register script exit handler to ensure we disconnect from services
    Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action {
        Disconnect-AllServices
    } -ErrorAction SilentlyContinue
} catch {
    Write-Host "Could not register exit handler: $_" -ForegroundColor Yellow
}

# Execute the main function
Start-CopilotReportingTool