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
    -07222026: V3 - Replaced the per-user Get-MgUserManager/Get-MgUser calls (2 serial API calls per user)
                     with batched Microsoft Graph $batch requests (20 users per call) plus 429 retry/backoff
                     handling and a progress indicator. This avoids timeouts/throttling on tenants with
                     thousands of licensed users. Also fixed the export filename mismatch (script now writes
                     and reports the same file name).

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

# Resolve each user's manager UPN using the Microsoft Graph $batch endpoint instead of one
# Get-MgUserManager + Get-MgUser call per user. On tenants with thousands of licensed users,
# doing this one user at a time results in tens of thousands of serial HTTP calls, which is
# what causes this script to time out or get throttled. Batching (up to 20 sub-requests per
# call) cuts the number of round-trips by ~20x and includes 429 retry/backoff handling.
function Get-ManagerBatch {
    param(
        [Parameter(Mandatory)][array]$UserChunk,
        [int]$RetriesRemaining = 3
    )

    $requests = @()
    $userById = @{}
    for ($i = 0; $i -lt $UserChunk.Count; $i++) {
        $reqId = "$i"
        $requests += @{ id = $reqId; method = "GET"; url = "/users/$($UserChunk[$i].Id)/manager?`$select=id,userPrincipalName" }
        $userById[$reqId] = $UserChunk[$i]
    }

    $batchBody = @{ requests = $requests } | ConvertTo-Json -Depth 10

    try {
        $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/`$batch" -Body $batchBody -ContentType "application/json"
    }
    catch {
        if ($RetriesRemaining -gt 0) {
            Write-Host "Batch request failed ($($_.Exception.Message)). Retrying in 10s..." -foregroundcolor "DarkYellow"
            Start-Sleep -Seconds 10
            return Get-ManagerBatch -UserChunk $UserChunk -RetriesRemaining ($RetriesRemaining - 1)
        }
        Write-Host "Batch request failed after multiple retries: $($_.Exception.Message)" -foregroundcolor "Red"
        $fallback = @{}
        foreach ($u in $UserChunk) { $fallback[$u.Id] = $null }
        return $fallback
    }

    $managerMap = @{}
    $throttledUsers = @()

    foreach ($resp in $batchResponse.responses) {
        $user = $userById[$resp.id]
        switch ($resp.status) {
            200 { $managerMap[$user.Id] = $resp.body.userPrincipalName }
            404 { $managerMap[$user.Id] = $null }
            429 { $throttledUsers += $user }
            default {
                Write-Host "Manager lookup failed for $($user.Mail): HTTP $($resp.status)" -foregroundcolor "DarkYellow"
                $managerMap[$user.Id] = $null
            }
        }
    }

    # Retry any sub-requests that were individually throttled (429) within the batch.
    if ($throttledUsers.Count -gt 0 -and $RetriesRemaining -gt 0) {
        Start-Sleep -Seconds 10
        $retryMap = Get-ManagerBatch -UserChunk $throttledUsers -RetriesRemaining ($RetriesRemaining - 1)
        foreach ($key in $retryMap.Keys) { $managerMap[$key] = $retryMap[$key] }
    }
    elseif ($throttledUsers.Count -gt 0) {
        foreach ($u in $throttledUsers) {
            Write-Host "Giving up on manager lookup for $($u.Mail) after repeated throttling." -foregroundcolor "DarkYellow"
            $managerMap[$u.Id] = $null
        }
    }

    return $managerMap
}

Write-Host "Resolving manager UPNs for $($users.Count) users in batches of 20. This might take some time..." -foregroundcolor "Yellow"
$managerLookup = @{}
$chunkSize = 20
$totalChunks = [Math]::Ceiling($users.Count / $chunkSize)
$chunkNum = 0

for ($i = 0; $i -lt $users.Count; $i += $chunkSize) {
    $chunkNum++
    $endIndex = [Math]::Min($i + $chunkSize - 1, $users.Count - 1)
    $chunk = $users[$i..$endIndex]

    Write-Progress -Activity "Resolving managers" -Status "Batch $chunkNum of $totalChunks" -PercentComplete (($chunkNum / $totalChunks) * 100)

    $chunkResult = Get-ManagerBatch -UserChunk $chunk
    foreach ($key in $chunkResult.Keys) { $managerLookup[$key] = $chunkResult[$key] }
}
Write-Progress -Activity "Resolving managers" -Completed

# Prepare an array to hold user details
$userDetails = @()

Write-Host "Building user data for $($users.Count) users." -foregroundcolor "Yellow"
foreach ($user in $users) {
    $managerUpn = $managerLookup[$user.Id]
    if (-not $managerUpn) {
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
    $userDetails | Export-Csv -Path "InsightsLicensedUsers.csv" -NoTypeInformation
    Write-Host "Finished processing. See results here: .\InsightsLicensedUsers.csv" -foregroundcolor "Yellow"
}
catch{Write-Host "Encountered an error while exporting results: $($_)"}

# Disconnect from Microsoft Graph
Write-Host "`nDisconnecting from Microsoft Graph..." -foregroundcolor "Yellow"
Disconnect-MgGraph
