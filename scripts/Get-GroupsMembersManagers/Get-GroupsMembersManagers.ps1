<#
.SYNOPSIS
    Generates a report of Microsoft Entra group members and their managers.

.DESCRIPTION
    ###############Disclaimer#####################################################
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
    ###############Disclaimer#####################################################

    PURPOSE:
        Queries Microsoft Entra (via Microsoft Graph) to collect user profile details,
        manager information, and group membership context. The resulting CSV output is
        intended as a source file for Organizational Data uploads in Microsoft 365 or
        Viva Advanced Insights.

    INPUT MODES:
        1. All users from all Entra groups.
        2. Members of a single group searched by display name.
        3. Users listed in a CSV file (requires a column named 'UPN').

    OUTPUT FILE:
        EntraGroupMembersExport.csv (saved in the current working directory).

    EXPORTED COLUMNS:
        GroupName, DisplayName, JobTitle, Department, OfficeLocation, CompanyName,
        UsageLocation, PreferredLanguage, StreetAddress, City, State, Country,
        PostalCode, UserPrincipalName, ManagerUPN

    REQUIREMENTS:
        - Microsoft Graph PowerShell Module
          https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
        - Required Graph API scopes: Group.Read.All, User.Read.All

    VERSION HISTORY:
        - 07/26/2024: V1 - Initial release (Alejandro Lopez, Dean Cron)
        - 04/22/2026: V2 - Interactive menu, extended properties, performance improvements (J.G. Parra, Alejandro Lopez)

    AUTHOR(S):
        - Alejandro Lopez - Alejanl@Microsoft.com
        - Dean Cron - DeanCron@microsoft.com
        - J.G. Parra - Contributor

.EXAMPLE
    .\Get-GroupsMembersManagers.ps1

.EXAMPLE
    Prepare a CSV file with a column named UPN, then run:
    .\Get-GroupsMembersManagers.ps1
#>

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

function Read-MenuOption {
    <#
    .SYNOPSIS
        Displays the input mode menu and returns the selected option.
    #>
    while ($true) {
        Write-Host ""
        Write-Host "Select source option:" -ForegroundColor Yellow
        Write-Host "  1) All users from all groups"
        Write-Host "  2) Members from one group (search by display name)"
        Write-Host "  3) Users from CSV (required column: UPN)"
        Write-Host "  4) Exit"

        $selectedOption = Read-Host "Enter your option (1-4)"
        if ($selectedOption -match '^[1-4]$') {
            return [int]$selectedOption
        }

        Write-Host "Invalid option. Please select 1, 2, 3, or 4." -ForegroundColor Red
    }
}

function Test-CtrlCPressed {
    <#
    .SYNOPSIS
        Detects Ctrl+C when the current host supports TreatControlCAsInput.
    #>
    try {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control)) {
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Add-GroupMembersToWorkItems {
    <#
    .SYNOPSIS
        Adds group membership records to the work item queue.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Group,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$WorkItems
    )

    $members = Get-MgGroupMember -GroupId $Group.Id -All
    foreach ($member in $members) {
        [void]$WorkItems.Add(
            [PSCustomObject]@{
                GroupName  = $Group.DisplayName
                UserLookup = $member.Id
            }
        )
    }
}

$menuOption = Read-MenuOption
if ($menuOption -eq 4) {
    Write-Host "Exit selected. No data exported." -ForegroundColor Yellow
    return
}

$interrupted = $false
$processedUsers = 0
$successfulUsers = 0
$failedUsers = 0

$userDetails = New-Object System.Collections.ArrayList
$workItems = New-Object System.Collections.ArrayList

$outputPath = Join-Path -Path (Get-Location) -ChildPath "EntraGroupMembersExport.csv"
$propertyList = "Id,DisplayName,UserPrincipalName,Department,JobTitle,OfficeLocation,CompanyName,UsageLocation,PreferredLanguage,StreetAddress,City,State,Country,PostalCode"

$originalTreatControlCAsInput = $false

try {
    $originalTreatControlCAsInput = [Console]::TreatControlCAsInput
    [Console]::TreatControlCAsInput = $true
}
catch {
    Write-Host "Warning: Ctrl+C custom handling is not available in this host." -ForegroundColor Yellow
}

try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"

    switch ($menuOption) {
        1 {
            Write-Host "Collecting users from all groups. This might take some time..." -ForegroundColor Yellow
            $groups = Get-MgGroup -All
            $groupIndex = 1

            foreach ($group in $groups) {
                if (Test-CtrlCPressed) {
                    Write-Host "`n`nCapture interrupted by user (Ctrl+C)." -ForegroundColor Yellow
                    Write-Host "Continuing with data collected so far..." -ForegroundColor Yellow
                    $interrupted = $true
                    break
                }

                Write-Host "Processed Group: $groupIndex of $($groups.Count)" -ForegroundColor Yellow
                Add-GroupMembersToWorkItems -Group $group -WorkItems $workItems
                $groupIndex++
            }
        }

        2 {
            $groupName = Read-Host "Enter group display name"
            if ([string]::IsNullOrWhiteSpace($groupName)) {
                throw "Group display name is required."
            }

            $escapedGroupName = $groupName.Replace("'", "''")
            $matchingGroups = @(Get-MgGroup -Filter "DisplayName eq '$escapedGroupName'" -All)

            if ($matchingGroups.Count -eq 0) {
                throw "No group found with display name '$groupName'."
            }

            if ($matchingGroups.Count -gt 1) {
                Write-Host "More than one group matched '$groupName'. The first match will be used." -ForegroundColor Yellow
            }

            $targetGroup = $matchingGroups[0]
            if ($null -eq $targetGroup -or [string]::IsNullOrWhiteSpace($targetGroup.Id)) {
                throw "Unable to resolve a valid group object for '$groupName'."
            }

            Write-Host "Using group: $($targetGroup.DisplayName) ($($targetGroup.Id))" -ForegroundColor Yellow
            Add-GroupMembersToWorkItems -Group $targetGroup -WorkItems $workItems
        }

        3 {
            Write-Host "CSV mode selected. Required input format: CSV file with column name 'UPN'." -ForegroundColor Yellow
            $csvPath = Read-Host "Enter full path of CSV file"

            if (-not (Test-Path -Path $csvPath)) {
                throw "CSV file does not exist: $csvPath"
            }

            $csvRows = Import-Csv -Path $csvPath
            if (-not $csvRows) {
                throw "CSV file is empty."
            }

            if (-not ($csvRows[0].PSObject.Properties.Name -contains "UPN")) {
                throw "CSV must contain a column named 'UPN'."
            }

            foreach ($row in $csvRows) {
                if ([string]::IsNullOrWhiteSpace($row.UPN)) {
                    continue
                }

                [void]$workItems.Add(
                    [PSCustomObject]@{
                        GroupName  = ""
                        UserLookup = $row.UPN
                    }
                )
            }
        }
    }

    if ($workItems.Count -eq 0) {
        Write-Host "No users found to process. Empty file will be exported." -ForegroundColor Yellow
    }

    $totalUsers = $workItems.Count
    Write-Host "Total users to export: $totalUsers" -ForegroundColor Yellow

    foreach ($workItem in $workItems) {
        if (Test-CtrlCPressed) {
            Write-Host "`n`nCapture interrupted by user (Ctrl+C)." -ForegroundColor Yellow
            Write-Host "Continuing with data collected so far..." -ForegroundColor Yellow
            $interrupted = $true
            break
        }

        $processedUsers++
        $percentComplete = 0
        if ($totalUsers -gt 0) {
            $percentComplete = [Math]::Round(($processedUsers / $totalUsers) * 100, 2)
        }

        Write-Progress -Activity "Collecting user profile data" -Status "Processed $processedUsers of $totalUsers" -PercentComplete $percentComplete

        try {
            $user = Get-MgUser -UserId $workItem.UserLookup -Property $propertyList -ExpandProperty Manager
            $managerUpn = $null

            if ($null -ne $user.Manager) {
                $managerUpn = $user.Manager.AdditionalProperties['userPrincipalName']
            }

            [void]$userDetails.Add(
                [PSCustomObject]@{
                    GroupName         = $workItem.GroupName
                    DisplayName       = $user.DisplayName
                    JobTitle          = $user.JobTitle
                    Department        = $user.Department
                    OfficeLocation    = $user.OfficeLocation
                    CompanyName       = $user.CompanyName
                    UsageLocation     = $user.UsageLocation
                    PreferredLanguage = $user.PreferredLanguage
                    StreetAddress     = $user.StreetAddress
                    City              = $user.City
                    State             = $user.State
                    Country           = $user.Country
                    PostalCode        = $user.PostalCode
                    UserPrincipalName = $user.UserPrincipalName
                    ManagerUPN        = $managerUpn
                }
            )

            $successfulUsers++
        }
        catch {
            $failedUsers++
            Write-Host "Unable to get details for this account: $($workItem.UserLookup)" -ForegroundColor Yellow
        }
    }

    Write-Progress -Activity "Collecting user profile data" -Completed

    try {
        $userDetails | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

        if ($interrupted) {
            Write-Host "Partial export completed due to user interruption." -ForegroundColor Yellow
        }
        else {
            Write-Host "Finished processing." -ForegroundColor Yellow
        }

        Write-Host "Results exported to: $outputPath" -ForegroundColor Yellow
        Write-Host "Summary -> Total work items: $totalUsers | Processed: $processedUsers | Success: $successfulUsers | Failed: $failedUsers | Exported rows: $($userDetails.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Hit error while exporting results: $($_)" -ForegroundColor Red
    }
}
catch {
    Write-Host "Execution failed: $($_)" -ForegroundColor Red
}
finally {
    try {
        [Console]::TreatControlCAsInput = $originalTreatControlCAsInput
    }
    catch {
    }

    Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Yellow
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
