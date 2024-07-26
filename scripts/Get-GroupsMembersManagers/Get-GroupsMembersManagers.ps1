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
    -The purpose of this script is to generate a report of Groups their members and their managers from Entra. This can be used to build the Organizational Data file which is later uploaded into M365 or Viva Advanced Insights.

REQUIREMENTS:
    -Microsoft Graph Module: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0

VERSION:
    -07262024: V1

AUTHOR(S): 
    -Alejandro Lopez - Alejanl@Microsoft.com
    -Dean Cron - DeanCron@microsoft.com

.EXAMPLE
    Get members from all groups 
    .\Get-GroupsMembersManagers.ps1
#>

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

#Import the required modules
Write-Host "Connecting to Microsoft Graph"
Import-Module -Name "Microsoft.Graph" -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"

# Get all groups
$groups = Get-MgGroup -All

# Prepare an array to hold user details
$userDetails = @()
$i=1

# Iterate over each group to get members
foreach ($group in $groups) {
    Write-Host "Processed Group: $i of $($Groups.Count)" -foregroundcolor "Yellow"
    
    # Get members of the group
    $members = Get-MgGroupMember -GroupId $group.Id -All

    # For each member, get the required details
    foreach ($memberId in $members.Id) {
        $user = Get-MgUser -UserId $memberId -Property ID,DisplayName,UserPrincipalName,Department -ExpandProperty Manager
        $managerUpn = $null
        try {
            $managerUpn = $user.Manager.AdditionalProperties['userPrincipalName']
        } catch {
            Write-Host "Manager not found for user: $($user.DisplayName)"
        }

        # Add user details to the array
        $userDetails += [PSCustomObject]@{
            GroupName = $group.DisplayName
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            Department = $user.Department
            ManagerUPN = $managerUpn
        }
    }
    $i++
}

# Export the user details to a CSV file
try{
    $userDetails | Export-Csv -Path "EntraGroupMembersExport.csv" -NoTypeInformation
    Write-Host "Finished processing. See results here: .\EntraGroupMembersExport.csv" -foregroundcolor "Yellow"
}
catch{Write-Host "Hit error while exporting results: $($_)"}

# Disconnect from Microsoft Graph
Disconnect-MgGraph