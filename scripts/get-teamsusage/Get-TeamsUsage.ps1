<#

.SYNOPSIS
  Name: Get-TeamsUsage.ps1
  The purpose of this script is to use the groups usage report graph api to gather usage data
  on teams within a certain period of time

.Requirements
Microsoft.ADAL.PowerShell PowerShell Module
MSOnline PowerShell Module
MicrosoftTeams PowerShell Module

.PARAMETER TenantName
Tenant name in the format contoso.onmicrosoft.com

.PARAMETER ClientID
AppID for the App registered in AzureAD for the purpose of accessing the reporting API

.PARAMETER GroupsReport
This is used with the Groups switch and will allow you to select from a dropdown all
usage reports available with the Graph API

.PARAMETER Period
Time period for the report in days. Allowed values: D7,D30,D90,D180
Period is not supported for reports starting with getOffice365Activations and will be ignored

.PARAMETER redirectUri
Redirect URI specified during application registration

.OUTPUTS
Exports data into a csv named TeamsUsageReport.csv
Returns an system.array object that is a representation of a Microsoft Graph API Report Object

Script derived from Damian Wiese's Get-Office365Report 

.EXAMPLE

 .\TeamsUsageReport.ps1 `
    -TenantName "contoso.onmicrosoft.com" `
    -ClientID "afl724e4-5ac1-1b9c-be7c-917c95fq1w28" `
    -GroupsReport getOffice365GroupsActivityDetail `
    -Period D7 `
    -redirectUri "urn:foo"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $TenantName,

    [Parameter(Mandatory = $true)]
    $ClientID,

    [Parameter(Mandatory = $false, ParameterSetName = "Groups", ValueFromPipeline = $false)]
    [ValidateSet(
        "getOffice365GroupsActivityDetail",
        "getOffice365GroupsActivityCounts",
        "getOffice365GroupsActivityGroupCounts",
        "getOffice365GroupsActivityStorage",
        "getOffice365GroupsActivityFileCounts"
    )]
    $GroupsReport,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "D7",
        "D30",
        "D90",
        "D180")]
    $Period,

    [Parameter(Mandatory = $false)]
    $Date,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$redirectUri,

    [Parameter()]
    [switch]$noExport
)


begin {
    # Bind the parameter to a friendly variable


    $report = $GroupsReport

    try {
        Import-Module Microsoft.ADAL.PowerShell -ErrorAction Stop
        Import-Module MicrosoftTeams -ErrorAction Stop
        Import-Module MSOnline -ErrorAction Stop
    }
    catch {
    
        Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module Microsoft.ADAL.PowerShell -Force -AllowClobber;" -Wait 
        Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module MicrosoftTeams -Force -AllowClobber;" -Wait 
        Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module MSOnline -Force -AllowClobber;" -Wait 
    
        Import-Module Microsoft.ADAL.PowerShell  
        Import-Module MicrosoftTeams
        Import-Module MSOnline 
    }
}

#Start the loading of the rest of the script
process {
    
    $Credential = Get-Credential

    #grabbing toke using Microsoft.ADAL.PowerShell module
   
    #Build REST API header with authorization token

    $token = Get-ADALAccessToken `
        -ForcePromptSignIn   `
        -RedirectUri "$redirectUri" `
        -ClientId "$ClientID" `
        -AuthorityName "$TenantName" `
        -ResourceId "https://graph.microsoft.com" `
                 
    if ($token -eq $null) {
  
        Write-Host "No token was created. Please review all parameters to ensure they are correct" -ForegroundColor Red
        break
    }

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = $token
    }

    #Build Parameter String

    #If period is specified then add that to the parameters unless it is not supported
    if ($period -and $Report -notlike "*Office365Activation*") {
        $str = "period='{0}'," -f $Period
        $parameterset += $str
    }
    
 

    #Trim a trailing comma off the ParameterSet if needed
    if ($parameterset) {
        $parameterset = $parameterset.TrimEnd(",")
    }
    Write-Verbose "Parameter set is: $parameterset"

    #Build the request URL and invoke
    $uri = 'https://graph.microsoft.com/beta/reports/{0}({1})?$format=text/csv' -f $report, $parameterset
    Write-Host $uri
    Write-Host "Retrieving Report $report, please wait" -ForegroundColor Green
    $result = Invoke-WebRequest -Uri $uri –Headers $authHeader –Method Get
               
    
    #Convert the stream result to an array
    $resultarray = ConvertFrom-Csv -InputObject $result 

    $allTeams = @()

    try {

        Connect-MsolService -Credential $Credential -ErrorAction Stop
        Connect-MicrosoftTeams -Credential $Credential -ErrorAction Stop    
    }
    catch {
    
        Write-Host "Connection could not be created: $($_.Exception.Message.ToString())" 
    
    }

    foreach ($team in $resultarray) {

        try {
    
            $id = Get-MsolGroup -SearchString "$($team.'Group Display Name')" -All 
    
            Get-TeamChannel -GroupId "$($id.ObjectID)" -ErrorAction Stop | out-null

            Write-Verbose -Message "Team $($team.'Group Display Name') has been found"

            $allTeams += $team
        }
        catch {
    
            $message = $_.Exception.Message.ToString()

            if ($message -match "AccessDenied") {
                $allTeams += $team
            }
    
        }#endcatch   

    }#endforeach

}

end {
    if (-Not $noExport) {
        $allTeams | Export-Csv -Path "TeamsUsageReport.csv" -NoTypeInformation -Force
    }
    Clear-ADALAccessTokenCache -AuthorityName "$TenantName"
    return $allTeams
}