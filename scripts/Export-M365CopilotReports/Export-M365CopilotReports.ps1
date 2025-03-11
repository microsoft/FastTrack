# Enhanced Export logs that can be used for Copilot Analytics Reporting, including Entra Users, Purview Audit Logs, etc. 
# Features:
# - Export Entra Users Details including Manager Information (Can be used for Org Data Preparation)
# - Export Purview Audit Logs for Copilot Interactions (Can be used for Copilot Analytics Reporting)
# - Export Purview Audit Logs for All Interactions 
# - Extensible for future export functions
# - Interactive startup menu

# Author: Alejandro Lopez | alejanl@microsoft.com
# Version: v20250311

# Function to connect to Microsoft Graph
function Connect-ToMicrosoftGraph {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All" -ErrorAction Stop
        Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
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
    param()
    
    try {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ErrorAction Stop
        Write-Host "Successfully connected to Exchange Online." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error connecting to Exchange Online: $_" -ForegroundColor Red
        return $false
    }
}

# Function to export Entra Users details
function Export-EntraUsersDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\EntraUsersExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\EntraUsersExport_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    )
    
    # Start logging
    Start-Transcript -Path $LogPath -Append
    Write-Host "Starting Entra user export process. Log file: $LogPath" -ForegroundColor Cyan
    
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
            UsageLocation, City, Country, PostalCode, State, EmployeeHireDate
        
        Write-Host "Retrieved $($users.Count) users from Entra directory." -ForegroundColor Green
        
        if ($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            Stop-Transcript
            return
        }
        
        # Now we need to get manager information for each user
        Write-Host "Retrieving manager information for each user..." -ForegroundColor Cyan
        
        # Initialize progress bar parameters
        $progressParams = @{
            Activity = "Exporting Entra User Details"
            Status = "Processing users"
            PercentComplete = 0
        }
        
        # Display initial progress bar
        Write-Progress @progressParams
        
        # Create an array to store user details
        $userDetails = @()
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
            
            # Process user details with additional attributes
            $userDetails += [PSCustomObject]@{
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
            }
        }
        
        # Update progress for export phase
        $progressParams.Status = "Exporting data to CSV file"
        $progressParams.PercentComplete = 99
        Write-Progress @progressParams
        
        # Export to CSV
        $userDetails | Export-Csv -Path $OutputPath -NoTypeInformation
        
        # Complete progress bar
        Write-Progress -Activity "Exporting Entra User Details" -Completed
        
        Write-Host "Export completed successfully. File saved to: $OutputPath" -ForegroundColor Green
        Write-Host "Total users exported: $($userDetails.Count)" -ForegroundColor Green
        Write-Host "Users with managers found: $managersFound" -ForegroundColor Green
        Write-Host "Users without managers: $managersNotFound" -ForegroundColor Green
    }
    catch {
        Write-Host "Error exporting Entra users: $_" -ForegroundColor Red
    }
    finally {
        Disconnect-MgGraph
        Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
        Stop-Transcript
    }
}

# Function to export Purview audit logs with filtering options
function Export-PurviewAuditLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\PurviewAuditLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Operations = @("CopilotInteraction"),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = (Get-Date).AddDays(-7),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),
        
        [Parameter(Mandatory = $false)]
        [int]$ResultSize = 5000,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\PurviewAuditLogs_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    )
    
    # Start logging
    Start-Transcript -Path $LogPath -Append
    Write-Host "Starting Purview audit logs export process. Log file: $LogPath" -ForegroundColor Cyan
    
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
        $operationsFilter = if ($Operations.Count -gt 0) {
            $Operations -join ","
        } else {
            $null
        }
        
        $params = @{
            StartDate = $startDateStr
            EndDate = $endDateStr
            ResultSize = $ResultSize
        }
        
        if ($operationsFilter) {
            $params.Operations = $operationsFilter
        }
        
        # Initialize progress bar
        $progressParams = @{
            Activity = "Retrieving Purview Audit Logs"
            Status = "Searching for audit logs..."
            PercentComplete = 10
        }
        Write-Progress @progressParams
        
        # Retrieve audit logs
        Write-Host "Executing Search-UnifiedAuditLog with parameters:" -ForegroundColor Cyan
        $params | Format-Table | Out-String | Write-Host
        
        $auditLogs = Search-UnifiedAuditLog @params
        
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
        $processedLogs = @()
        $processedCount = 0
        $errorCount = 0
        
        foreach ($log in $auditLogs) {
            $processedCount++
            
            # Update progress
            $percentComplete = 30 + (($processedCount / $totalLogs) * 60) # Scale from 30% to 90%
            $progressParams.Status = "Processing log $processedCount of $totalLogs"
            $progressParams.PercentComplete = $percentComplete
            Write-Progress @progressParams
            
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
                
                $processedLogs += $processedLog
            }
            catch {
                $errorCount++
                Write-Host "Error parsing AuditData for record: $($log.Id) - $_" -ForegroundColor Yellow
            }
        }
        
        # Final progress update for export
        $progressParams.Status = "Exporting data to CSV"
        $progressParams.PercentComplete = 95
        Write-Progress @progressParams
        
        # Export the processed data
        $processedLogs | Export-Csv -Path $OutputPath -NoTypeInformation
        
        # Complete progress bar
        Write-Progress -Activity "Retrieving Purview Audit Logs" -Completed
        
        Write-Host "Export completed successfully. File saved to: $OutputPath" -ForegroundColor Green
        Write-Host "Total records exported: $($processedLogs.Count)" -ForegroundColor Green
        if ($errorCount -gt 0) {
            Write-Host "Errors encountered during processing: $errorCount" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error exporting Purview audit logs: $_" -ForegroundColor Red
    }
    finally {
        Disconnect-ExchangeOnline -Confirm:$false
        Write-Host "Disconnected from Exchange Online." -ForegroundColor Cyan
        Stop-Transcript
    }
}

# Function to display the main menu
function Show-MainMenu {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "       Microsoft 365 Export Utility Menu       " -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Export Entra Users Details" -ForegroundColor Yellow
    Write-Host "  2. Export Purview Audit Logs (Copilot Interactions)" -ForegroundColor Yellow
    Write-Host "  3. Export Purview Audit Logs (Custom Operations)" -ForegroundColor Yellow
    Write-Host "  4. Exit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan

    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" {
            $outputPath = Read-Host "Enter output path (press Enter for default)"
            $logPath = Read-Host "Enter log file path (press Enter for default)"
            
            if ([string]::IsNullOrWhiteSpace($outputPath) -and [string]::IsNullOrWhiteSpace($logPath)) {
                Export-EntraUsersDetails
            }
            elseif ([string]::IsNullOrWhiteSpace($logPath)) {
                Export-EntraUsersDetails -OutputPath $outputPath
            }
            elseif ([string]::IsNullOrWhiteSpace($outputPath)) {
                Export-EntraUsersDetails -LogPath $logPath
            }
            else {
                Export-EntraUsersDetails -OutputPath $outputPath -LogPath $logPath
            }
        }
        "2" {
            $outputPath = Read-Host "Enter output path (press Enter for default)"
            $logPath = Read-Host "Enter log file path (press Enter for default)"
            $startDays = Read-Host "Enter number of days to look back (default: 7)"
            
            if ([string]::IsNullOrWhiteSpace($startDays) -or -not [int]::TryParse($startDays, [ref]$null)) {
                $startDays = 7
            }
            
            $startDate = (Get-Date).AddDays(-[int]$startDays)
            
            $params = @{
                Operations = @("CopilotInteraction")
                StartDate = $startDate
            }
            
            if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
                $params.OutputPath = $outputPath
            }
            
            if (-not [string]::IsNullOrWhiteSpace($logPath)) {
                $params.LogPath = $logPath
            }
            
            Export-PurviewAuditLogs @params
        }
        "3" {
            $outputPath = Read-Host "Enter output path (press Enter for default)"
            $logPath = Read-Host "Enter log file path (press Enter for default)"
            $operations = Read-Host "Enter operations to filter (comma-separated, press Enter for all operations)"
            $startDays = Read-Host "Enter number of days to look back (default: 7)"
            
            if ([string]::IsNullOrWhiteSpace($startDays) -or -not [int]::TryParse($startDays, [ref]$null)) {
                $startDays = 7
            }
            
            $startDate = (Get-Date).AddDays(-[int]$startDays)
            
            $operationsArray = if ([string]::IsNullOrWhiteSpace($operations)) {
                @()
            }
            else {
                $operations -split ',' | ForEach-Object { $_.Trim() }
            }
            
            $params = @{
                Operations = $operationsArray
                StartDate = $startDate
            }
            
            if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
                $params.OutputPath = $outputPath
            }
            
            if (-not [string]::IsNullOrWhiteSpace($logPath)) {
                $params.LogPath = $logPath
            }
            
            Export-PurviewAuditLogs @params
        }
        "4" {
            Write-Host "Exiting program. Goodbye!" -ForegroundColor Green
            return
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Show-MainMenu
        }
    }
    
    # After completing the selected option, ask if the user wants to return to the menu
    $returnToMenu = Read-Host "Return to main menu? (Y/N)"
    if ($returnToMenu -eq "Y" -or $returnToMenu -eq "y") {
        Show-MainMenu
    }
    else {
        Write-Host "Exiting program. Goodbye!" -ForegroundColor Green
    }
}

# Required modules check and installation
function Ensure-RequiredModules {
    [CmdletBinding()]
    param()
    
    $requiredModules = @("Microsoft.Graph", "ExchangeOnlineManagement")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Host "The following required modules are missing: $($missingModules -join ', ')" -ForegroundColor Yellow
        $installConfirm = Read-Host "Do you want to install these modules? (Y/N)"
        
        if ($installConfirm -eq "Y" -or $installConfirm -eq "y") {
            foreach ($module in $missingModules) {
                try {
                    Write-Host "Installing module: $module" -ForegroundColor Cyan
                    Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
                    Write-Host "Successfully installed module: $module" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error installing module $module : $_" -ForegroundColor Red
                    return $false
                }
            }
        }
        else {
            Write-Host "Module installation skipped. The script may not function correctly." -ForegroundColor Yellow
            return $false
        }
    }
    
    return $true
}

# Main script execution
try {
    # Check for required modules
    if (Ensure-RequiredModules) {
        # Display the main menu
        Show-MainMenu
    }
    else {
        Write-Host "Required modules are missing. Please install them before running this script." -ForegroundColor Red
    }
}
catch {
    Write-Host "An error occurred in the main script: $_" -ForegroundColor Red
}