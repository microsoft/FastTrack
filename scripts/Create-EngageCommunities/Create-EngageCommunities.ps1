
<#
.SYNOPSIS
Creates multiple communities in Viva Engage using the Microsoft Graph API.
THIS IS INTENDED FOR NON-PRODUCTION ENVIRONMENTS ONLY.

.DESCRIPTION
This script creates a specified number of communities in Viva Engage using the Microsoft Graph API. 
It retrieves an access token, randomizes the list of communities, and then creates the specified
number of communities with the given display name and description.

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

Author: Dean Cron - dean.cron@microsoft.com

.PARAMETER InputFile (Required)
Specifies the path to the JSON file containing the list of communities to create.

.PARAMETER NumberofCommunities (Optional)
Specifies the number of communities to create. Must be an integer between 1 and 50.

.PARAMETER AssignedOwner (Optional)
If supplied, the script will assign the specified user as the owner of all the communities created. Requires valid account in UPN format.
If not supplied, random users will be assigned as the owners of the new communities.

.EXAMPLE
Creates 25 sample communities in Viva Engage with the owners set to user@domain.com:
.\Create-EngageCommunities.ps1 -InputFile C:\Temp\communities.json -NumberofCommunities 25 -AssignedOwner "user@domain.com"

#>

#region Input Parameters

param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-Not ($_ | Test-Path)) {
            throw "File `$_` does not exist."
        } elseif ((Get-Item $_).Extension -ne '.json') {
            throw "File `$_` is not a JSON file."
        }
        return $true
    })]
    [string]$InputFile,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1,50)]
    [int]$NumberofCommunities = 50,

    [Parameter(Mandatory = $false)]
    [ValidateScript(
    {
        If ($_ -match "^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$") {
            $True
          }
          else {
            Throw "AssignedOwner $_ is in the wrong format. Must be a valid user UPN."
          }
    })]
    [string]$AssignedOwner
)

#endregion

#region Functions

function New-Community {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken, 
        [Parameter(Mandatory = $true)]
        [string]$DisplayName, 
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Privacy,
        [Parameter(Mandatory = $false)]
        [string]$Owner
    )

    # Headers for the API request.
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = "application/json"
    }

    # Body of the API request.
    $reqBody = New-Object System.Collections.Specialized.OrderedDictionary
    
    $reqBody.Add('displayName',$DisplayName)
    $reqBody.Add('description',$Description)
    $reqBody.Add('privacy',$Privacy)
    $reqBody.Add('owners@odata.bind',@($userUrl+$Owner))

    $createComplete = $false

    # Send the API request to create a new community.
    try {
        Write-Host "Creating community:" $DisplayName
        $response = Invoke-WebRequest -Uri $CommunityUrl -Method Post -Headers $headers -Body ($reqBody | ConvertTo-Json)

        $responseHeaders = $response.Headers
        $statusUri = $responseHeaders.location.ToString()
        
        # Check community creation status.
        # https://learn.microsoft.com/en-us/graph/api/engagementasyncoperation-get?view=graph-rest-beta
        Do{
            Start-Sleep -Seconds 2
            $operationInfo = Invoke-RestMethod -Uri $statusUri -Headers $headers -Method Get
            if ($operationInfo.status -eq "succeeded") {
                $createComplete = $true
            }
            elseif ($operationInfo.status -eq "failed" -or $operationInfo.status -eq "skipped") {
                # Graph indicates creation failed or was skipped. Return the error and move on.
                # https://learn.microsoft.com/en-us/graph/api/resources/engagementasyncoperation?view=graph-rest-beta
                Write-Host "Failed to create community:" $DisplayName -ForegroundColor Red
                Write-Host "Info returned from Graph: $($operationInfo.statusDetail)" -ForegroundColor Red
                return
            }
        } While (-not $createComplete)

        Write-Host "Successfully created community:" $DisplayName -ForegroundColor Green
    }
    catch {
        if($_.Exception.Response.StatusCode.Value__ -eq "409"){
            #Thrown when the community already exists.
            Write-Host "Community already exists:" $DisplayName -ForegroundColor Red
            return
        }
        else{
            # Fallback, report error and move on to next community.
            Write-Host "Error occurred while creating community:" $DisplayName -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Failed on line:" $_.InvocationInfo.ScriptLineNumber -ForegroundColor Red
            return
        }
    }
}

function Get-OwnerIds {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [string]$DefaultUser
    )

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    if ($PSBoundParameters.ContainsKey('DefaultUser')) {
        $url = ($userUrl+$DefaultUser)
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $ownerIds = @($response.id)
    }
    else{
        $response = Invoke-RestMethod -Uri $userUrl -Headers $headers -Method Get
        $ownerIds = @()

        # Get all users with either an E5 or E3 license.
        # Also checking for VIVAENGAGE_CORE or YAMMERENTERPRISE service plan enablement just in case Engage requires licensed users.
        foreach ($user in $response.value) {
            if (($user.assignedLicenses.skuId -contains "c7df2760-2c81-4ef7-b578-5b5392b571df" -or $user.assignedLicenses.skuId -contains "6fd2c87f-b296-42f0-b197-1e91e994b900") -and 
                ($user.assignedPlans.servicePlanId -contains "a82fbf69-b4d7-49f4-83a6-915b2cf354f4" -or $user.assignedPlans.servicePlanId -contains "7547a3fe-08ee-4ccb-b430-5077c5041653")) {
                    $ownerIds += $user.id
            }
        }

        # Get 10 random users
        $ownerIds = $ownerIds | Get-Random -Count 10
    }

    return $ownerIds
}

function Connect-ToGraph {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $authBody =  @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $ClientId
        Client_Secret = $ClientSecret
    }

    $Connection = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method POST -Body $authBody

    $accessToken = $Connection.access_token
    return $accessToken
}

#endregion

#region Variables

# Change these to match your environment. Instructions:
# https://github.com/microsoft/FastTrack/tree/master/scripts/Create-EngageCommunities/README.md
$ClientId = "clientid"
$TenantId = "tenantid"
$ClientSecret = "clientsecret"

# Do not change these.
$Global:CommunityUrl = "https://graph.microsoft.com/beta/employeeExperience/communities"
$Global:userUrl = "https://graph.microsoft.com/beta/users/"
$accessToken = Connect-ToGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret

#endregion

#region Main

# Prompt for confirmation.
Write-Host "This script will create $NumberofCommunities new communities in your Viva Engage network."
$confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirmation -ne "Y") {
    Write-Host "Script execution cancelled."
    return
}

# If $AssignedOwner is specified, get their user ID.
# If the $AssignedOwner parameter is not set, get 10 random users with the required license and service plan.
if ($PSBoundParameters.ContainsKey('AssignedOwner')) {
    $communityOwners = Get-OwnerIds -AccessToken $accessToken -DefaultUser $AssignedOwner
} else {

    # Get 10 random licensed users.
    $communityOwners = Get-OwnerIds -AccessToken $accessToken

    if (($communityOwners | Measure-Object).Count -eq 0) {
        $defaultOwner = Read-Host "No users with the required license and service plan were found.'
         Please input the UPN of one user to be the owner of all new groups"
        $communityOwners = Get-OwnerIds -AccessToken $accessToken -DefaultUser $defaultOwner
    }
}

# Get communities from $communityList, randomize the results.
$communityList = Get-Content -Path $InputFile | ConvertFrom-Json
$communityList = $communityList.communities | Get-Random -Count $communityList.communities.Count 

# Do the work.
for ($i = 0; $i -lt $NumberofCommunities; $i++) {
    $community = $communityList[$i]
    
    # Randomizing whether the new community is public or private.
    $privacy = "public", "private" | Get-Random

    # Randomizing the owner (if $AssignedOwner wasn't specified) and creating the community.
    $user = $communityOwners | Get-Random -Count 1
    New-Community -AccessToken $accessToken -DisplayName $community.name -Description $community.description -Privacy $privacy -Owner $user
}

#endregion

