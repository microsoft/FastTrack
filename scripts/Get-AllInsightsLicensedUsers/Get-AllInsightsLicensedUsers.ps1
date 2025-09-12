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
    -This script pulls users specifically assigned the WORKPLACE_ANALYTICS_INSIGHTS_USER service plan.
    -Use this to generate an organizational data file for upload in Viva Insights or the M365 Admin Center.
    -If you want to pull all users, remove the -Filter parameter from the Get-MgUser command.

REQUIREMENTS:
    -Microsoft Graph Module: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0

VERSION:
    -03132025: V1
    -09042025: V2 - Rewrote to filter users by service plan in the initial Get-MgUser call.

AUTHOR(S): 
    -Dean Cron - DeanCron@microsoft.com
    -Alejandro Lopez - Alejanl@Microsoft.com

EXAMPLE
    Get all users from Entra
    .\Get-AllInsightsLicensedUsers.ps1
#>

# Set the execution policy to allow the script to run
# This is necessary if the script is being run for the first time or if the execution policy is set to a more restrictive setting.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Connect to Microsoft Graph with minimum rights required to read users
Write-Host "`nConnecting to Microsoft Graph..." -foregroundcolor "Yellow"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
    
# Load all users assigned the WORKPLACE_ANALYTICS_INSIGHTS_USER service plan from Entra
# If you want to return more properties, add them to the -Property parameter.
Write-Host "Loading All Users with the WORKPLACE_ANALYTICS_INSIGHTS_USER service plan. This might take some time..." -foregroundcolor "Yellow"
$users = Get-MgUser -Filter "assignedPlans/any(c:c/servicePlanId eq b622badb-1b45-48d5-920f-4b27a2c0996c and c/capabilityStatus eq 'Enabled')" -All -ConsistencyLevel eventual -CountVariable count -Property "Id","Mail","Department"

# Prepare an array to hold user details
$userDetails = @()

# For each user, get the required details including their manager's UPN
Write-Host "Building user data for $($users.Count) users." -foregroundcolor "Yellow"
foreach ($user in $users) {
    $managerUpn = $null
    $managerId = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue

    if ($managerId) {
        $manager = Get-MgUser -UserId $managerId.Id -Property UserPrincipalName
        $managerUpn = $manager.UserPrincipalName
    }
    else{
        Write-Host "No manager found for user: $($user.Mail)" -foregroundcolor "DarkYellow"
    }

    # Add user details to the array
    $userDetails += [PSCustomObject]@{
        PersonId = $user.Mail
        ManagerId = $managerUpn
        Department = $user.Department

        # Add any other attributes you want to capture here, and update the -Properties value on Get-MgUser (line 50). List of available attributes returned from Mg-User:
        # https://learn.microsoft.com/en-us/dotnet/api/microsoft.azure.powershell.cmdlets.resources.msgraph.models.apiv10.imicrosoftgraphuser?view=az-ps-latest
    }
}

# Export the user details to a CSV file
try{
    $userDetails | Export-Csv -Path "EntraUsersExport.csv" -NoTypeInformation
    Write-Host "Finished processing. See results here: .\InsightsLicensedUsers.csv" -foregroundcolor "Yellow"
}
catch{Write-Host "Encountered an error while exporting results: $($_)"}

# Disconnect from Microsoft Graph
Write-Host "`nDisconnecting from Microsoft Graph..." -foregroundcolor "Yellow"
Disconnect-MgGraph
