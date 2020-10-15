<#

SimpleGraph module for PowerShell, using SharePoint Online PnP PowerShell module| Version 0.9

by David.Whitney@microsoft.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

#>

# First ensure SharePoint Online PnP PowerShell module is available
Write-Verbose "Checking for SharePoint Online PnP module"
$PnPModule = Get-Module -Name "SharePointPnPPowerShellOnline" -ListAvailable
if (-not $PnPModule) {
    $errorstring = "Authentication to Microsoft Graph with SimpleGraph requires installation of SharePoint Online PnP PowerShell module - use 'Install-Module SharePointPnPPowerShellOnline' from an elevated PowerShell session, restart this PowerShell session, then try again."
    $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
    throw $errorreturn
}
Import-Module SharePointPnPPowerShellOnline -WarningAction SilentlyContinue -ErrorAction Stop

$script:DefaultApiVersion = "v1.0"
$script:GraphBaseUri = "https://graph.microsoft.com"

function Get-SimpleGraphAuthToken {
    try {
        Get-PnPGraphAccessToken
    } catch {
        $e = $_
        if ($e.Exception -like "*Connect-PnPOnline*") {
            Write-Debug ("{0}" -f $e.Exception)
            $errorstring = ("Please run Connect-PnPOnline to authenticate with Microsoft Graph before using SimpleGraph")
            $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
            $PSCmdlet.ThrowTerminatingError($errorreturn)
        }
    }
}

# https://stackoverflow.com/questions/18771424/how-to-get-powershell-invoke-restmethod-to-return-body-of-http-500-code-response
function ParseErrorForResponseBody($RestError) {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ($Error.Exception.Response) {
            $Reader = New-Object System.IO.StreamReader($RestError.Exception.Response.GetResponseStream())
            $Reader.BaseStream.Position = 0
            $Reader.DiscardBufferedData()
            $ResponseBody = $Reader.ReadToEnd()
            if ($ResponseBody.StartsWith('{')) {
                $ResponseBody = $ResponseBody | ConvertFrom-Json
            }
            return $ResponseBody
        }
    }
    else {
        return $RestError.ErrorDetails.Message
    }
}

<#
.Synopsis
    Invoke a simple Graph request
.DESCRIPTION
    Invoke a simple Graph request either by complete Uri or with just the request path
.EXAMPLE
    Invoke-SimpleGraphRequest me

    Get your own profile
.EXAMPLE
    Invoke-SimpleGraphRequest users/janedoe@contoso.com/manager

    Get a user's manager
.EXAMPLE
    Invoke-SimpleGraphRequest -Uri https://graph.microsoft.com/v1.0/groups

    Get a list of all groups, specifying the full Uri
.OUTPUTS
    Response from Graph as a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function Invoke-SimpleGraphRequest {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (
        # Specify which Rest method this Graph request will be
        [Parameter()]
        [ValidateSet("GET","PATCH","POST","DELETE")]
        [string]
        $Method = "GET",

        # Specify the Graph request Uri without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/
        [Parameter(
            ParameterSetName = "Path",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Path,

        # Used with Path to specify which ApiVersion to use in Graph request. Not needed if Path contains ApiVersion in the path string.
        [Parameter(
            ParameterSetName = "Path")]
        [string]
        $ApiVersion,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [ValidateScript({
            if (($_ -like "https://graph.microsoft.com/*") -or ($_ -like "https://graph.microsoft.us/*")) {
                $true
            } else {
                $errorstring = "Uri must start with https://graph.microsoft.com/"
                $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
                $PSCmdlet.ThrowTerminatingError($errorreturn)        
            }})]
        [string]
        $Uri,

        # Specify the contents of the body for this Graph request, can be a JSON string or a Hashtable
        [Parameter()]
        [ValidateScript({
            if ($_.GetType().Name -in "String","Hashtable") {
                $true
            } else {
                $errorstring = "Body must be a string or hashtable"
                $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
                $PSCmdlet.ThrowTerminatingError($errorreturn)
            }})]
        $Body,

        # Pass a filter parameter to the Graph request (see https://docs.microsoft.com/en-us/graph/query-parameters#filter-parameter)
        [Parameter(
            ParameterSetName = "Path"
        )]
        [string]
        $Filter,

        # Don't try to massage output from Graph (e.g. don't remove @odata fields, don't collect all data from paginated responses)
        [Parameter()]
        [switch]
        $Raw,

        # Ignore prompt to confirm deletion
        [Parameter()]
        [switch]
        $Force,

        # Access Token string to use as authorization bearer token for Graph API call
        [Parameter()]
        [string]
        $AccessToken
    )

    # Get access token and build header for request
    if (!$AccessToken) {
        $AccessToken = Get-SimpleGraphAuthToken
    }
    $headers = @{
        Authorization = ("Bearer {0}" -f $AccessToken)
    }

    # Build full URI that request will use
    if ($Path) {
        if (!$ApiVersion) {
            # check if API Version was specified in request path
            $apiversionmatch = [regex]::Match($Path,"\/?(beta|v\d\.\d)\/(.*)")
            if ($apiversionmatch.Groups[1].Success) {
                $ApiVersion = $apiversionmatch.Groups[1].value
                $Path = $apiversionmatch.Groups[2].value
                Write-Verbose ("Detected API Version in request path: {0}" -f $ApiVersion)
            } else {
                # Default to coded default API Version for more complete info
                $ApiVersion = $script:DefaultApiVersion
                Write-Verbose ("No API Version specified or detected, defaulting to: {0}" -f $DefaultApiVersion)
            }
        } elseif ($ApiVersion -match "^\d\.\d$") {
            $ApiVersion = "v" + $ApiVersion
        }
        if ($Filter -and $Method -eq "GET") {
            $Uri = ("{0}/{1}/{2}?`$filter={3}" -f $script:GraphBaseUri, ($ApiVersion.Trim('/')), ($Path.Trim('/')), $Filter)
        } else {
            $Uri = ("{0}/{1}/{2}" -f $script:GraphBaseUri, ($ApiVersion.Trim('/')), ($Path.Trim('/')))
        }
        Write-Verbose ("Constructed Request Uri: {0}" -f $Uri)
    }

    # Convert body to JSON string if given as hashtable
    if ($Body -and $Body.GetType().Name -eq "Hashtable") {
        Write-Debug "Converting Body as Hashtable to JSON string"
        $Body = $Body | ConvertTo-Json
        Write-Debug $Body
        Write-Verbose ("Converted Body request:`n{0}" -f $Body)
    }

    Write-Debug ("Uri: {0}" -f $Uri)
    Write-Debug ("Method: {0}" -f $Method)
    if ($Body) {
        Write-Debug ("Body: {0}" -f $Body)
    }
    Write-Debug ("Headers: Content-Type={0}; Authorization={1}; ExpiresOn={2}" -f $headers['Content-Type'], $headers['Authorization'], $headers['ExpiresOn'])

    # Confirm deletion before moving on
    if (($Method -like "DELETE") -and -not ($Force -or $PSCmdlet.ShouldProcess($Uri, "DELETE object"))) {
        $errorstring = "DELETE action canceled by user"
        $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
        $PSCmdlet.ThrowTerminatingError($errorreturn)
    }
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -Body $Body -ContentType "application/json" -Verbose:$DebugPreference
        } else {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -ContentType "application/json" -Verbose:$DebugPreference
        }
    } catch {
        $responsemessage = (ParseErrorForResponseBody $_).Error.Message
        if ($Body) {
            $errorstring = ("{0} {1}`nBody: {2}`n{3}`nMessage: {4}" -f $Method, $Uri, $Body, $_.Exception.Message, $responsemessage)
        } else {
            $errorstring = ("{0} {1}`n{2}`nMessage: {3}" -f $Method, $Uri, $_.Exception.Message, $responsemessage)
        }
        $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
        $PSCmdlet.ThrowTerminatingError($errorreturn)
    }
    
    if ($response) {
        if ($Raw) {
            return $response
        }
        if ($response.'@odata.type') {
            # strip Graph context properties for simplicity
            $response.PSObject.Properties.Remove('@odata.type')
        }
        # if the @odata.context property has $entity at the end, this is a single item so return as is, otherwise return the value property
        if ($response.'@odata.context' -like "*`$entity") {
            # strip Graph context properties for simplicity
            $response.PSObject.Properties.Remove('@odata.context')
            return $response
        } elseif ($response.'@odata.nextLink' -and $Uri -notlike "*`$top=*") {
            # multiple pages of data, invoke a request to get the next page as long as it wasn't explicitly called with a $top URL
            # this allows return to include all data in the asked for collection when the server automatically paginates the response
            $response.value
            Write-Verbose "Response has been paginated, retrieving next page of data"
            Write-Progress -Id 1 -Activity "Results paginated" -Status "Retrieving next page of data"
            return (Invoke-SimpleGraphRequest -Method $Method -Uri $response.'@odata.nextLink')
            Write-Progress -Id 1 -Completed
        } else {
            return $response.value
        }
    } else {
        Write-Verbose ("{0} request successful, Graph gave no response" -f $Method)
    }
}
Export-ModuleMember -Function Invoke-SimpleGraphRequest

<#
.Synopsis
    Get a simple response from Graph
.DESCRIPTION
    Invoke a request from Graph with a simpler command that will always only use GET method
.EXAMPLE
    Get-SimpleGraphObject me

    Get your own profile
.EXAMPLE
    Get-SimpleGraphObject users/janedoe@contoso.com/manager

    Get a user's manager
.EXAMPLE
    Get-SimpleGraphObject users -Filter "displayName eq 'Jane Doe'"

    Get all users who's displayName is Jane Doe
.EXAMPLE
    Get-SimpleGraphObject groups -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')"

    Get all teams-enabled groups (this filter is in beta endpoint only as of 11/28/2018)
.EXAMPLE
    Get-SimpleGraphObject https://graph.microsoft.com/v1.0/groups

    Get a list of all groups, specifying the full Uri
.OUTPUTS
    Response from Graph as a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function Get-SimpleGraphObject {
    [CmdletBinding()]
    param(
        # Specify the Graph request Uri without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/
        [Parameter(
            ParameterSetName = "Path",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Path,

        # Used with Path to specify which ApiVersion to use in Graph request. Not needed if Path contains ApiVersion in the path string.
        [Parameter(
            ParameterSetName = "Path")]
        [string]
        $ApiVersion,

        # Pass a filter parameter to the Graph request (see https://docs.microsoft.com/en-us/graph/query-parameters#filter-parameter)
        [Parameter(
            ParameterSetName = "Path"
        )]
        [string]
        $Filter,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [string]
        $Uri
    )
    try {
        if ($Path) {
            Invoke-SimpleGraphRequest -Method GET -ApiVersion $ApiVersion -Path $Path -Filter $Filter
        } else {
            Invoke-SimpleGraphRequest -Method GET -Uri $Uri
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Export-ModuleMember -Function Get-SimpleGraphObject

<#
.Synopsis
    Update an object in Graph
.DESCRIPTION
    Invoke a request from Graph with a simpler command that will always only use PATCH method
.EXAMPLE
    Set-SimpleGraphObject users/user@contoso.com -Body '{"displayName":"displayName-value"}

    Update a user's profile
.OUTPUTS
    Response from Graph is usually null, otherwise returnes a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function Set-SimpleGraphObject {
    [CmdletBinding()]
    param(
        # Specify the Graph request Uri without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/
        [Parameter(
            ParameterSetName = "Path",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Path,

        # Used with Path to specify which ApiVersion to use in Graph request. Not needed if Path contains ApiVersion in the path string.
        [Parameter(
            ParameterSetName = "Path")]
        [string]
        $ApiVersion,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [string]
        $Uri,

        # Body of the Graph request containing the properties to be set, can be JSON string or Hashtable
        [Parameter(Mandatory = $true)]
        $Body
    )
    try {

        if ($Path) {
            Invoke-SimpleGraphRequest -Method PATCH -ApiVersion $ApiVersion -Path $Path -Body $Body
        } else {
            Invoke-SimpleGraphRequest -Method PATCH -Uri $Uri -Body $Body
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
New-Alias Update-SimpleGraphObject Set-SimpleGraphObject
Export-ModuleMember -Function Set-SimpleGraphObject -Alias Update-SimpleGraphObject

<#
.Synopsis
    Create an object in Graph
.DESCRIPTION
    Invoke a request from Graph with a simpler command that will always only use POST method
.EXAMPLE
    $NewOffice365Group = @{
        displayName =  "Sample New Group";
        description = "Sample New Group description"
        mailNickname = "SampleNewGroup";
        mailEnabled = $true;
        groupTypes = @("Unified");
        securityEnabled = $false
    }

    New-SimpleGraphObject groups -Body $NewOffice365Group

    Create a new Office 365 Group
.OUTPUTS
    Response from Graph as a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function New-SimpleGraphObject {
    [CmdletBinding()]
    param(
        # Specify the Graph request Uri without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/
        [Parameter(
            ParameterSetName = "Path",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Path,

        # Used with Path to specify which ApiVersion to use in Graph request. Not needed if Path contains ApiVersion in the path string.
        [Parameter(
            ParameterSetName = "Path")]
        [string]
        $ApiVersion,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [string]
        $Uri,

        # Body of the Graph request containing the properties to be set, can be JSON string or Hashtable
        [Parameter(Mandatory = $true)]
        $Body
    )
    try {
        if ($Path) {
            Invoke-SimpleGraphRequest -Method POST -ApiVersion $ApiVersion -Path $Path -Body $Body
        } else {
            Invoke-SimpleGraphRequest -Method POST -Uri $Uri -Body $Body
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Set-Alias Add-SimpleGraphObject New-SimpleGraphObject
Export-ModuleMember -Function New-SimpleGraphObject -Alias Add-SimpleGraphObject

<#
.Synopsis
    Remove an object in Graph
.DESCRIPTION
    Invoke a request from Graph with a simpler command that will always only use DELETE method
.EXAMPLE
    Remove-SimpleGraphObject groups/group-id

    Remove a group
.OUTPUTS
    Response from Graph is usually null, otherwise returnes a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function Remove-SimpleGraphObject {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        # Specify the Graph request Uri without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/
        [Parameter(
            ParameterSetName = "Path",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Path,

        # Used with Path to specify which ApiVersion to use in Graph request. Not needed if Path contains ApiVersion in the path string.
        [Parameter(
            ParameterSetName = "Path")]
        [string]
        $ApiVersion,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [string]
        $Uri,

        # Ignore prompt to confirm deletion
        [Parameter()]
        [switch]
        $Force
    )
    if ($Force) {
        $PSBoundParameters.Confirm = $false
    }
    try {
        if ($Path) {
            Invoke-SimpleGraphRequest -Method DELETE -ApiVersion $ApiVersion -Path $Path -Confirm:$PSBoundParameters.Confirm
        } else {
            Invoke-SimpleGraphRequest -Method DELETE -Uri $Uri -Confirm:$PSBoundParameters.Confirm
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Export-ModuleMember -Function Remove-SimpleGraphObject

<#
.Synopsis
    Get a report from Graph
.DESCRIPTION
    Invoke a request from Graph to get a report, with simpler period request and always returning as PS object (via JSON) instead of csv
    Report names can be seen here: https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/resources/report
.EXAMPLE
    Get-SimpleGraphReport getOffice365ActiveUserDetail -Days 7

    Get a usage report
.OUTPUTS
    Response from Graph as a PowerShell Custom Object (System.Management.Automation.PSCustomObject)
#>
function Get-SimpleGraphReport {
    [CmdletBinding()]
    param(
        # Specify the Graph report to get, without needing to specify the base Uri of https://graph.microsoft.com/{ApiVersion}/reports/
        [Parameter(
            ParameterSetName = "Name",
            Mandatory = $true,
            Position = 0)]
        [string]
        $Name,

        # Used with Name to specify which ApiVersion to use in Graph report request
        [Parameter(
            ParameterSetName = "Name")]
        [string]
        $ApiVersion,

        # Fully specify the Graph request Uri including base Uri, API version, and Graph report request path
        [Parameter(
            ParameterSetName = "Uri",
            Mandatory = $true)]
        [string]
        $Uri,

        # Days back to pull report data (report period)
        [Parameter(
            ParameterSetName = "Name"
        )]
        [ValidateSet("7","30","90","180")]
        [string]
        $Days = "7"
    )
    try {
        if ($Name) {
            $Path = ("reports/{0}(period='D{1}')?`$format=application/json" -f $Name, $Days)
            Write-Debug ("Constructed Graph request path: {0}" -f $Path)
            Invoke-SimpleGraphRequest -Method GET -ApiVersion $ApiVersion -Path $Path
        } else {
            # if Uri didn't specify the format, do so as JSON
            if (($Uri -notlike "*`$format=*")) {$Uri + "`$format=application/json"}
            Invoke-SimpleGraphRequest -Method GET -Uri $Uri
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Export-ModuleMember -Function Get-SimpleGraphReport
