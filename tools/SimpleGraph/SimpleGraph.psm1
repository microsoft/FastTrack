<#

SimpleGraph module for PowerShell, using MSAL.PS PowerShell module for Graph authentication | Version 0.9.3

by David.Whitney@microsoft.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

#>

# First ensure Microsoft Authentication Library (MSAL) is installed via MSAL.PS public module
Write-Verbose "Checking for MSAL.PS module"
$MSALModule = Get-Module -Name "MSAL.PS" -ListAvailable
if (-not $MSALModule) {
    $errorstring = "Authentication to Microsoft Graph with SimpleGraph requires installation of the MSAL.PS module. Run the command 'Install-Module MSAL.PS' from an elevated PowerShell session, restart this PowerShell session, then try again."
    $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
    throw $errorreturn
} else {
    if (!(Get-Module -Name "MSAL.PS")) {
        Import-Module -Name "MSAL.PS" -ErrorAction Stop
    }
}

# Setup common module variables
$script:DefaultApiVersion = "v1.0"
$script:GraphBaseUri = "https://graph.microsoft.com"
$script:MsalClientApplication = $null
$script:Scopes = @(".default")

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
    Connect and authenticate to Graph
.DESCRIPTION
    Connect and authenticate to Graph, specifying your Client ID and other authentication details
.EXAMPLE
    Connect-SimpleGraph -ClientId XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -TenantId XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -Scopes "User.Read.All"

    Authenticate to Graph for certain permissions Scopes using a specific Client ID and Tenant ID
.EXAMPLE
    $clientCertThumbprint = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    $clientCertObject = Get-Item "Cert:\CurrentUser\My\$($clientCertThumbprint)"
    Connect-SimpleGraph -ClientID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -TenantId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ClientCertificate $clientCertObject
    
    Authenticate to Graph using a specific Client ID, Tenant ID, and local X.509 Client Certificate from an Azure AD registered application with required Application permissions
.EXAMPLE
    $clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | ConvertTo-SecureString -AsPlainText -Force
    Connect-SimpleGraph -ClientID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -TenantId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ClientSecret $clientSecret

    Authenticate to Graph using a specific Client ID, Tenant ID, and Client Secret as a SecureString from an Azure AD registered application with required Application permissions
#>
function Connect-SimpleGraph {
    [CmdletBinding(
        DefaultParameterSetName = "Delegation"
    )]
    param(
        # Specify the Client ID that will be used to authorize the connection to Graph
        [Parameter(
            Mandatory = $true
        )]
        [Alias("ApplicationId")]
        [string]
        $ClientId,

        # List of permissions to request access to in Graph with this connection
        [Parameter(
            ParameterSetName = "Delegation",
            Mandatory = $true
        )]
        [string[]]
        $Scopes,

        # Supply the Client Secret as a SecureString when authenticating as a confidential application
        [Parameter(
            ParameterSetName = "Secret",
            Mandatory = $true
        )]
        [Alias("ClientPassword","ApplicationSecret","ApplicationPassword")]
        [System.Security.SecureString]
        $ClientSecret,

        # Specify an X.509 certificate to use for authenticating to Graph as an application
        [Parameter(
            ParameterSetName = "Certificate",
            Mandatory = $true
        )]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $ClientCertificate,

        # Specify the Tenant ID to authorize against when authenticating with a certificate
        [Parameter(
            ParameterSetName = "Delegation",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName = "Certificate",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = "Secret",
            Mandatory = $true
        )]
        [string]
        $TenantId,

        # Specify a custom RedirectUri for Delegated auth. If not specified, the default nativeclient redirect will be used
        [Parameter(
            ParameterSetName = "Delegation",
            Mandatory = $false
        )]
        [string]
        $RedirectUri,

        # Choose a Graph environment for national clouds like US Government (aka GCC High)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet("Global","USGov","USGovDoD","Germany","China")]
        [Alias("GraphEnvironmentName", "EnvironmentName")]
        [string]
        $Environment = "Global"
    )

    # Update Graph endpoint for web calls and login instance name for Get-MsalToken
    switch ($GraphEnvironmentName) {
        ("Global") {
            $script:GraphBaseUri = "https://graph.microsoft.com"
            $AzureCloudInstance = "AzurePublic"
        }
        ("USGov") {
            $script:GraphBaseUri = "https://graph.microsoft.us"
            $AzureCloudInstance = "AzureUsGovernment"
        }
        ("USGovDoD") {
            $script:GraphBaseUri = "https://dod-graph.microsoft.us"
            $AzureCloudInstance = "AzureUsGovernment"
        }
        ("Germany") {
            $script:GraphBaseUri = "https://graph.microsoft.de"
            $AzureCloudInstance = "AzureGermany"
        }
        ("China") {
            $script:GraphBaseUri = "https://microsoftgraph.chinacloudapi.cn"
            $AzureCloudInstance = "AzureChina"
        }
        default {
            $script:GraphBaseUri = "https://graph.microsoft.com"
            $AzureCloudInstance = "AzurePublic"
        }
    }

    # Create a MsalClientApplication instance and save Scopes to use with Get-MsalToken based on what kind of auth is being used
    # Start to build arguments to pass to New-MsalClientApplication 
    $NewMsalClientApplication_Args = @{
        "ClientId" = $ClientId;
        "AzureCloudInstance" = $AzureCloudInstance
    }
    switch ($PSCmdlet.ParameterSetName) {
        ("Delegation") {
            # Add relevant arguments based on what has been supplied to Connect-SimpleGraph
            if ($TenantId) {
                $NewMsalClientApplication_Args.Add(
                    "TenantId", $TenantId
                )
            }
            if ($RedirectUri) {
                $NewMsalClientApplication_Args.Add(
                    "RedirectUri", $RedirectUri
                )
            }
            
            # Delegation auth expects a custom permission scope has been provided
            $script:Scopes = $Scopes
        }
        ("Secret") {
            $NewMsalClientApplication_Args.Add(
                "ClientSecret", $ClientSecret
            )
            $NewMsalClientApplication_Args.Add(
                "TenantId", $TenantId
            )
            $script:Scopes = ".default"
        }
        ("Certificate") {
            $NewMsalClientApplication_Args.Add(
                "ClientCertificate", $ClientCertificate
            )
            $NewMsalClientApplication_Args.Add(
                "TenantId", $TenantId
            )
            $script:Scopes = ".default"
        }
    }

    # Use splat of args to pass what has been supplied via Connect-SimpleGraph on to New-MsalClientApplication
    $script:MsalClientApplication = New-MsalClientApplication @NewMsalClientApplication_Args

    try {
        $MsalToken = $script:MsalClientApplication | Get-MsalToken -Scopes $script:Scopes
    } catch {
        # TODO - catch Windows PowerShell error related to certs, see https://github.com/AzureAD/MSAL.PS/issues/15
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
    Write-Debug ("SimpleGraph auth token obtained (Current Date: {0}, auth token ExpiresOn: {1})" -f (Get-Date).ToLocalTime(), $MsalToken.ExpiresOn.ToLocalTime())
}
Export-ModuleMember -Function Connect-SimpleGraph

<#
.Synopsis
    Disconnect from Graph
.DESCRIPTION
    Disconnect from Graph by removing the current client application authentication context from the session
.EXAMPLE
    Disconnect-SimpleGraph

    Disconnect from Graph and remove current session auth context
#>
function Disconnect-SimpleGraph {
    [CmdletBinding()]
    param()
    $script:MsalClientApplication = $null
    $script:Scopes = @(".default")
}
Export-ModuleMember -Function Disconnect-SimpleGraph

# TODO - Implement a Get-SimpleGraphContext function?

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
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "Path"
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
            $UriInput = $_
            $validGraphEndpoints = @("https://graph.microsoft.com/*",
                                     "https://graph.microsoft.us/*",
                                     "https://dod-graph.microsoft.us/*",
                                     "https://dod-graph.microsoft.us/*",
                                     "https://graph.microsoft.de/*",
                                     "https://microsoftgraph.chinacloudapi.cn/*")
            if ([System.String]::IsNullOrEmpty($UriInput) -or ($validGraphEndpoints | Where-Object {$UriInput -like $_})) {
                $true
            } else {
                $errorstring = "Uri base endpoint must be a Graph endpoint such as https://graph.microsoft.com/"
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

    if (!$AccessToken) {
        if (!$script:MsalClientApplication) {
            $errorstring = "Run Connect-SimpleGraph with appropriate parameters to authenticate to Graph before invoking a request"
            $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
            $PSCmdlet.ThrowTerminatingError($errorreturn)
        }
        try {
            $MsalAuthToken = $script:MsalClientApplication | Get-MsalToken -Scopes $script:Scopes
        } catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
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
            # ----
            # TODO: More parsing to know if a filter has already been supplied in the Path and either throw an error or add on to existing filter
            # ----
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

    # Confirm deletion before moving on
    if (($Method -like "DELETE") -and -not ($Force -or $PSCmdlet.ShouldProcess($Uri, "DELETE object"))) {
        $errorstring = "DELETE action canceled by user"
        $errorreturn = New-Object System.Management.Automation.ErrorRecord($errorstring, $null, 'NotSpecified', $null)
        $PSCmdlet.ThrowTerminatingError($errorreturn)
    }

    if ($Uri -like "*/reports/*") {
        Write-Debug "Detected that request is a report via Uri, will treat return as CSV"
        $ResponseIsCSV = $true
    } else {
        $ResponseIsCSV = $false
    }

    # Create header for web request that includes Authorization bearer either directly supplied or via MsalAuth token
    if ($AccessToken) {
        $headers = @{
            Authorization = ("Bearer {0}" -f $AccessToken)
        }
     } else {
         $headers = @{
             Authorization = $MsalAuthToken.CreateAuthorizationHeader()
         }
     }

    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -Body $Body
        } else {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
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
        
        # Graph API Reports calls download a CSV file (redirects to a CSV file location), so need convert from straight CSV to PS Objects
        if ($ResponseIsCsv) {
            Write-Debug ("Assuming response is CSV, cleaning and converting to object return")
            # For some reason, return from Report download includes some apparent garbage characters in front which mess up the CSV conversion
            # Coded as character Unicode values to avoid encoding issues, characters are: 'ï','»','¿'
            # This is needed as of Jan 18, 2022 against v1.0 and beta APIs
            $cleanResponse = $response.ToString().TrimStart([char]0xef,[char]0xbb,[char]0xbf)
            $output = $cleanResponse | ConvertFrom-Csv
            return $output
        }

        if ($response.'@odata.type') {
            # strip Graph context properties for simplicity
            Write-Debug ("Removing @odata.type = {0}" -f $response.'@odata.type')
            $response.PSObject.Properties.Remove('@odata.type')
        }
        # if the @odata.context property has $entity at the end, this is a single item so return as is, otherwise return the value property
        if ($response.'@odata.context' -like "*`$entity") {
            # strip Graph context properties for simplicity
            Write-Debug ("Removing @odata.context = {0}" -f $response.'@odata.context')
            $response.PSObject.Properties.Remove('@odata.context')
            $output = $response
        } elseif ($response.'@odata.nextLink' -and $Uri -notlike "*`$top=*") {
            # multiple pages of data, invoke a request to get the next page as long as it wasn't explicitly called with a $top URL
            # this allows return to include all data in the asked for collection when the server automatically paginates the response
            $output = $response.value
            Write-Verbose "Response has been paginated, retrieving next page of data"
            Write-Progress -Id 1 -Activity "Results paginated" -Status "Retrieving next page of data"
            $output += (Invoke-SimpleGraphRequest -Method $Method -Uri $response.'@odata.nextLink')
            Write-Progress -Id 1 -Activity "Results paginated" -Completed
        } else {
            # return from Invoke-MgGraphRequest is a hashtable, so cast each return value to PS Object
            Write-Debug ("Assuming response has a value parameter to return")
            $output = $response.value
        }

        return $output

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
    [CmdletBinding(
        DefaultParameterSetName = "Path"
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

    Get a usage report that saves to the current folder as a CSV file.
.OUTPUTS
    Response from Graph as a PowerShell Custom Object (System.Management.Automation.PSCustomObject)#>
function Get-SimpleGraphReport {
    [CmdletBinding(
        DefaultParameterSetName = "Name"
    )]
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
            $Path = ("reports/{0}(period='D{1}')" -f $Name, $Days)
            Write-Debug ("Constructed Graph request path: {0}" -f $Path)
            Invoke-SimpleGraphRequest -Method GET -ApiVersion $ApiVersion -Path $Path
        } else {
            Invoke-SimpleGraphRequest -Method GET -Uri $Uri
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Export-ModuleMember -Function Get-SimpleGraphReport
