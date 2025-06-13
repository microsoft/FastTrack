<#
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

Purpose: 
    -The purpose of this script is to generate a report of all users and their managers from Entra. 
     This can be used to build the Organizational Data file which is later uploaded into M365 or Viva Advanced Insights.

     -Similar to Get-GroupsMembersManagers.ps1, but this script focuses on users rather than groups.

REQUIREMENTS:
    -Microsoft Graph Module: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0

VERSION:
    -03132025: V1

AUTHOR(S): 
    -Dean Cron - DeanCron@microsoft.com
    -Alejandro Lopez - Alejanl@Microsoft.com

EXAMPLE
    Get all users from Entra
    .\Get-AllEntraUsers.ps1
#>

# Set the execution policy to allow the script to run
# This is necessary if the script is being run for the first time or if the execution policy is set to a more restrictive setting.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Connect to Microsoft Graph with minimum rights required to read users
Write-Host "`nConnecting to Microsoft Graph..." -foregroundcolor "Yellow"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# Load all users from Entra
# Note: The Manager property is expanded to get the manager's details
Write-Host "Loading All Users. This might take some time..." -foregroundcolor "Yellow"
$users = Get-MgUser -All -Property ID,DisplayName,UserPrincipalName,Department -ExpandProperty Manager

# Prepare an array to hold user details
$userDetails = @()

# For each user, get the required details including their manager's UPN
Write-Host "Building user data for $($users.Count) users." -foregroundcolor "Yellow"
foreach ($user in $users) {
    $managerUpn = $null
    try {
        $managerUpn = $user.Manager.AdditionalProperties['userPrincipalName']
    } catch {
        Write-Host "Manager not found for user: $($user.DisplayName)"
    }
    
    # Add user details to the array
    $userDetails += [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        Department = $user.Department
        ManagerUPN = $managerUpn
    }
}

# Export the user details to a CSV file
try{
    $userDetails | Export-Csv -Path "EntraUsersExport.csv" -NoTypeInformation
    Write-Host "Finished processing. See results here: .\EntraUsersExport.csv" -foregroundcolor "Yellow"
}
catch{Write-Host "Hit error while exporting results: $($_)"}

# Disconnect from Microsoft Graph
Write-Host "`nDisconnecting from Microsoft Graph..." -foregroundcolor "Yellow"
Disconnect-MgGraph