# Enhanced Export logs that can be used for Copilot Analytics Reporting, including Entra Users, Purview Audit Logs, etc. 
# Features:
# - Export Entra Users Details including Manager Information (Can be used for Org Data Preparation)
# - Export Purview Audit Logs (with filtering for Copilot interactions)
# - Export Purview Audit Logs (with Custom Operations filtering)
# - Export Microsoft 365 Copilot Usage Reports
# - Extensible for future export functions
# - Interactive startup menu

# Author: Alejandro Lopez | alejandro.lopez@microsoft.com
# Version: v20250320

# Function to connect to Microsoft Graph
function Connect-ToMicrosoftGraph {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All", "Reports.Read.All" -ErrorAction Stop
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
# Function to export Entra Users details with license information
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
        
        # Get license SKU information to later resolve SKU IDs to readable names
        Write-Host "Retrieving license SKU information..." -ForegroundColor Cyan
        $licenseSkus = Get-MgSubscribedSku -All
        
        # Create a hashtable for quick SKU lookup
        $skuLookup = @{}
        foreach ($sku in $licenseSkus) {
            $skuLookup[$sku.SkuId] = $sku.SkuPartNumber
        }
        
        Write-Host "Retrieved $($licenseSkus.Count) license SKUs." -ForegroundColor Green
        
        # Now we need to get manager information for each user
        Write-Host "Retrieving manager information and license details for each user..." -ForegroundColor Cyan
        
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
            
            # Get user license information
            $licenseDetails = @()
            try {
                $userLicenses = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
                
                if ($userLicenses) {
                    foreach ($license in $userLicenses) {
                        # Convert SKU ID to readable SKU part number using our lookup table
                        $skuFriendlyName = if ($skuLookup.ContainsKey($license.SkuId)) {
                            $skuLookup[$license.SkuId]
                        } else {
                            $license.SkuId  # Fall back to ID if not found in lookup
                        }
                        
                        $licenseDetails += $skuFriendlyName
                    }
                }
            }
            catch {
                Write-Verbose "Error retrieving license details for user $($user.UserPrincipalName): $_"
            }
            
            # Join license details into a semicolon-separated string
            $licensesStr = if ($licenseDetails.Count -gt 0) {
                $licenseDetails -join ";"
            } else {
                ""  # Empty string if no licenses
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
                # License information
                AssignedLicenses = $licensesStr
                LicenseCount = $licenseDetails.Count
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
        [string[]]$Operations = @(),
        
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
        $processedLogs = @()
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
                
                $processedLogs += $processedLog
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
        $processedLogs | Export-Csv -Path $OutputPath -NoTypeInformation
        
        # Update progress to 100% before completing
        $progressParams.Status = "Export complete!"
        $progressParams.PercentComplete = 100
        Write-Progress @progressParams
        
        # Complete progress bar - use the same activity name as initialized
        Write-Progress -Activity $progressParams.Activity -Completed
        
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

# Function to export Microsoft 365 Copilot usage reports
function Export-CopilotUsageReports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\CopilotReports_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("D7", "D30", "D90", "D180")]
        [string]$Period = "D30",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\CopilotUsageReports_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    )
    
    # Start logging
    Start-Transcript -Path $LogPath -Append
    Write-Host "Starting Microsoft 365 Copilot usage reports export. Log file: $LogPath" -ForegroundColor Cyan
    
    # Get mydocuments path for output
    $mydocumentsPath = [System.Environment]::GetFolderPath('MyDocuments')
    Write-Host "Output will be saved to: $mydocumentsPath" -ForegroundColor Cyan
    
    try {
        # Connect to Microsoft Graph with appropriate scopes
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        if (-not (Connect-ToMicrosoftGraph)) {
            Write-Host "Cannot proceed with export. Microsoft Graph connection failed." -ForegroundColor Red
            Stop-Transcript
            return
        }
        Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green
        
        # Get Copilot user usage details using direct REST API call
        Write-Host "Retrieving Copilot usage details for period: $Period..." -ForegroundColor Yellow
        Write-Host "This may take some time depending on the amount of data..." -ForegroundColor Yellow
        
        $uri = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')"
        Write-Host "API URI: $uri" -ForegroundColor Gray
        
        # Use Invoke-MgGraphRequest directly instead of module-specific cmdlets
        $CopilotUsageDetails = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        
        if ($null -eq $CopilotUsageDetails -or $null -eq $CopilotUsageDetails.value) {
            Write-Host "No Copilot usage data was returned. The response may be empty." -ForegroundColor Red
            Write-Host "Response content:" -ForegroundColor Yellow
            $CopilotUsageDetails | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
            Stop-Transcript
            return
        }
        
        Write-Host "Retrieved data for $($CopilotUsageDetails.value.Count) users." -ForegroundColor Green
        
        # Create an array to store the usage data
        $UsageData = @()
        
        #get Date and Time and format as string
        $DateTime = Get-Date
        $formattedDateTime = $DateTime.ToString("yyyyMMdd_HHmmss")
        
        # Initialize the progress bar
        $totalUsers = $CopilotUsageDetails.value.Count
        $currentUser = 0
        $progressParams = @{
            Activity = "Processing Copilot Usage Data"
            Status = "Processing user data"
            PercentComplete = 0
        }
        
        Write-Host "Processing data for $totalUsers users..." -ForegroundColor Yellow
        # Display initial progress bar
        Write-Progress @progressParams
        
        # Loop through each user and extract the usage details
        foreach ($User in $CopilotUsageDetails.value) {
            # Update progress bar
            $currentUser++
            $progressParams.PercentComplete = ($currentUser / $totalUsers) * 100
            $progressParams.Status = "Processing user $currentUser of $totalUsers"
            Write-Progress @progressParams
            
            $UsageData += [PSCustomObject]@{
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
            }
        }
        
        # Complete the progress bar
        Write-Progress -Activity "Processing Copilot Usage Data" -Completed
        
        Write-Host ("{0} usage data records processed" -f $UsageData.count) -ForegroundColor Green
        
        # Create the file path
        $outputFilePath = Join-Path -Path $mydocumentsPath -ChildPath "$formattedDateTime`_cpusrdetails.csv"
        Write-Host "Exporting data to: $outputFilePath" -ForegroundColor Yellow
        
        # Export the usage data to a CSV file
        $UsageData | Export-Csv -Path $outputFilePath -NoTypeInformation
        
        Write-Host "Copilot user usage details have been exported to: $outputFilePath" -ForegroundColor Green
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
        # Ensure we disconnect from Graph
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
        }
        catch {
            Write-Host "Note: Could not properly disconnect from Microsoft Graph: $_" -ForegroundColor Yellow
        }
        
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
    Write-Host "3. Export Purview Audit Logs (Custom Operations)" -ForegroundColor White
    Write-Host "4. Export Microsoft 365 Copilot Usage Reports (Beta endpoints)" -ForegroundColor White
    Write-Host "5. Exit" -ForegroundColor White
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
            $outputPath = Read-Host "Enter output path (leave blank for default)"
            
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
            
            Write-Host "Filtering for Copilot Interactions only." -ForegroundColor Yellow
            
            $params = @{
                StartDate = $startDate
                EndDate = $endDate
                Operations = @("CopilotInteraction") # Explicitly set for Copilot interactions
                ResultSize = $resultSize
            }
            
            if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
                $params.OutputPath = $outputPath
            }
            
            Export-PurviewAuditLogs @params
            
            Pause
            Show-MainMenu
        }
        "3" {
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
        "4" {
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
        "5" {
            # Exit
            Clear-Host
            Write-Host "Exiting Microsoft 365 Copilot Analytics Reporting Tool." -ForegroundColor Cyan
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
    # Add a banner and version info
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "    Microsoft 365 Copilot Analytics Reporting Tool v3" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if required modules are installed
    if (-not (Test-RequiredModules)) {
        return
    }
    
    # Display the main menu
    Show-MainMenu
}

# Execute the main function
Start-CopilotReportingTool