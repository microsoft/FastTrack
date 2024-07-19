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
    -Disables HeadSpace in Viva Insights for all users with a Personal Insights service plan
     
Author:
    Dean Cron

Version:
    1.0

Requirements:

    -The script must be run by a user with the appropriate permissions to connect to Exchange Online and Microsoft Graph

.EXAMPLE
    .\Disable-InsightsHeadSpace.ps1
#>

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

#Import the required modules
Write-Host "Connecting to Exchange Online and Microsoft Graph"
Import-Module -Name "Microsoft.Graph.Users" -ErrorAction Stop
Import-Module -Name "ExchangeOnlineManagement" -ErrorAction Stop

#Connect to Exchange Online and Graph
Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome -ContextScope Process
Connect-ExchangeOnline -ShowBanner:$false

#Get all users that have licenses with the EXCHANGE_ANALYTICS or MYANALYTICS_P2 plan
Write-Host "Getting all users with a Personal Insights service plan assigned`n"
$users = Get-MgUser -Filter "assignedPlans/any(x:x/ServicePlanId eq 33c4f319-9bdd-48d6-9c4d-410b750a4a5a) or assignedPlans/any(x:x/ServicePlanId eq 34c0d7a0-a70f-4668-9238-47f9fc208882)" -All -ConsistencyLevel eventual -Count userCount

#Do the work
try
{
    foreach($user in $users)
    {
        #Set the new name by removing the string defined in $namingPolicyString
        Write-Host "Disabling HeadSpace for user" $user.UserPrincipalName -ForegroundColor Yellow

        #Disable HeadSpace for the user
        Set-VivaInsightsSettings -Identity $user.UserPrincipalName -Enabled $false -Feature headspace -ErrorAction Stop

        #Make the output a little cleaner
        Write-Host "`n"
    }

    Write-Host "HeadSpace is disabled for all users with a Personal Insights service plan" -ForegroundColor Green
}
catch
{
    $e = $_.Exception.Response.StatusCode.Value__
    $l = $_.InvocationInfo.ScriptLineNumber
    Write-Host "Failed to disable HeadSpace for all users" -ForegroundColor Red
    Write-Host "error $e on line $l"
}

Disconnect-ExchangeOnline -Confirm:$false

