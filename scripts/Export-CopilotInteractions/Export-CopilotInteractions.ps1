#Requires -Version 5.1
<#
.SYNOPSIS
Exports Microsoft 365 Copilot user-level interaction history for Power BI reporting.

.DESCRIPTION
Enumerates licensed Microsoft 365 users, identifies users with Copilot-related SKU assignments, and exports
user and interaction datasets to CSV files. Interaction data is read from the Microsoft Graph Beta endpoint:
/beta/copilot/users/{id}/interactionHistory/getAllEnterpriseInteractions.

IMPORTANT:
- This script uses Microsoft Graph Beta APIs. Beta APIs are subject to change and are not supported for production use.
- getAllEnterpriseInteractions does NOT include Copilot Studio agent interactions.
- Interaction body content can contain actual user prompts and AI responses. Review privacy, legal, retention,
  and compliance requirements before exporting or sharing the CSV output.
- The SKU-to-tier mapping may need updates as Microsoft changes Copilot licensing SKU part numbers.

Required Microsoft Graph permissions:
- App-only: AiEnterpriseInteraction.Read.All for interaction history.
- User/license enumeration: User.Read.All and Reports.Read.All are commonly required by customers for this report.
  Grant admin consent for application permissions when using client secret or certificate authentication.

.PARAMETER TenantId
Microsoft Entra tenant ID.

.PARAMETER ClientId
Application (client) ID used for app-only auth. Optional for interactive delegated auth.

.PARAMETER ClientSecret
Application client secret as a SecureString. Use Read-Host -AsSecureString to avoid putting secrets in shell history.

.PARAMETER CertificateThumbprint
Certificate thumbprint for app-only certificate authentication.

.PARAMETER Interactive
Use delegated interactive authentication for testing.

.PARAMETER OutputDirectory
Directory where Users.csv, Interactions.csv, UsageByUserAppDay.csv, UsageByAppFeatureDay.csv, and Errors.csv are written. Defaults to the script directory.

.PARAMETER StartDate
Start of the interaction export window. Defaults to the last 30 days.

.PARAMETER EndDate
End of the interaction export window. Defaults to now.

.PARAMETER MaxUsers
Maximum number of Copilot users to process. Use 0 for all users.

.PARAMETER DelayBetweenUserRequestsMilliseconds
Delay between per-user interaction requests to reduce throttling risk. Defaults to 200 milliseconds.

.PARAMETER SkuTierMap
Hashtable mapping SKU part numbers to tier labels such as Basic or Premium.

.PARAMETER IncludeAllUsers
Enumerate all users instead of only users with any assigned license. Useful if the tenant uses non-standard licensing.

.EXAMPLE
$secret = Read-Host 'Client secret' -AsSecureString
.\Export-CopilotInteractions.ps1 -TenantId 'contoso.onmicrosoft.com' -ClientId '<app-id>' -ClientSecret $secret

.EXAMPLE
.\Export-CopilotInteractions.ps1 -TenantId '<tenant-id>' -ClientId '<app-id>' -CertificateThumbprint '<thumbprint>' -OutputDirectory '.\out'

.EXAMPLE
.\Export-CopilotInteractions.ps1 -TenantId '<tenant-id>' -Interactive -StartDate (Get-Date).AddDays(-7) -MaxUsers 10
#>

[CmdletBinding(DefaultParameterSetName = 'ClientSecret')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Interactive')]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Interactive')]
    [ValidateNotNullOrEmpty()]
    [string]$ClientId,

    [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
    [ValidateNotNull()]
    [securestring]$ClientSecret,

    [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
    [ValidateNotNullOrEmpty()]
    [string]$CertificateThumbprint,

    [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
    [switch]$Interactive,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = $PSScriptRoot,

    [Parameter()]
    [datetime]$StartDate = (Get-Date).ToUniversalTime().AddDays(-30),

    [Parameter()]
    [datetime]$EndDate = (Get-Date).ToUniversalTime(),

    [Parameter()]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$MaxUsers = 0,

    [Parameter()]
    [ValidateRange(0, 60000)]
    [int]$DelayBetweenUserRequestsMilliseconds = 200,

    [Parameter()]
    [hashtable]$SkuTierMap = @{
        'Microsoft_365_Copilot' = 'Premium'
        'Microsoft_Copilot_for_Microsoft365' = 'Premium'
        'M365_Copilot' = 'Premium'
        'Microsoft_365_Copilot_Chat' = 'Basic'
        'Microsoft_Copilot' = 'Basic'
        'Copilot_Chat' = 'Basic'
    },

    [Parameter()]
    [switch]$IncludeAllUsers
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-GraphAuthenticationModule {
    if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph.Authentication')) {
        throw "The Microsoft.Graph.Authentication module is required. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
}

function Connect-CopilotGraph {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ClientSecret', 'Certificate', 'Interactive')]
        [string]$AuthenticationMode
    )

    $commonParameters = @{
        NoWelcome = $true
    }

    if ($TenantId) {
        $commonParameters['TenantId'] = $TenantId
    }

    switch ($AuthenticationMode) {
        'ClientSecret' {
            $credential = [pscredential]::new($ClientId, $ClientSecret)
            $connectParameters = $commonParameters.Clone()
            $connectParameters['ClientSecretCredential'] = $credential
            Connect-MgGraph @connectParameters | Out-Null
        }
        'Certificate' {
            $connectParameters = $commonParameters.Clone()
            $connectParameters['ClientId'] = $ClientId
            $connectParameters['CertificateThumbprint'] = $CertificateThumbprint
            Connect-MgGraph @connectParameters | Out-Null
        }
        'Interactive' {
            $connectParameters = $commonParameters.Clone()
            $connectParameters['Scopes'] = @(
                'User.Read.All',
                'Reports.Read.All',
                'AiEnterpriseInteraction.Read.All'
            )
            if ($ClientId) {
                $connectParameters['ClientId'] = $ClientId
            }
            Connect-MgGraph @connectParameters | Out-Null
        }
    }
}

function Get-ResponseRetryAfterSeconds {
    param(
        [Parameter(Mandatory = $false)]
        [object]$Response,

        [Parameter(Mandatory = $false)]
        [object]$ResponseHeaders
    )

    $headers = $ResponseHeaders
    if (-not $headers -and $Response) {
        $headersProperty = $Response.PSObject.Properties['Headers']
        if ($headersProperty) {
            $headers = $headersProperty.Value
        }
    }

    if (-not $headers) {
        return $null
    }

    try {
        $retryAfter = $headers['Retry-After']
        if ($retryAfter) {
            $retryAfterText = ($retryAfter | Select-Object -First 1).ToString()
            $retryAfterSeconds = 0
            if ([int]::TryParse($retryAfterText, [ref]$retryAfterSeconds)) {
                return [Math]::Max(1, $retryAfterSeconds)
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-ResponseStatusCode {
    param(
        [Parameter(Mandatory = $false)]
        [object]$Response,

        [Parameter(Mandatory = $false)]
        [object]$Exception
    )

    if ($Response) {
        $statusCodeProperty = $Response.PSObject.Properties['StatusCode']
        if ($statusCodeProperty) {
            try {
                return [int]$statusCodeProperty.Value
            }
            catch {
                return $null
            }
        }
    }

    if ($Exception) {
        foreach ($propertyName in @('ResponseStatusCode', 'StatusCode')) {
            $property = $Exception.PSObject.Properties[$propertyName]
            if ($property -and $null -ne $property.Value) {
                try {
                    return [int]$property.Value
                }
                catch {
                    continue
                }
            }
        }
    }

    return $null
}

function Invoke-GraphRequestWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [int]$MaximumRetryCount = 6
    )

    $attempt = 0
    while ($true) {
        try {
            $requestParameters = @{
                Method = $Method
                Uri = $Uri
                OutputType = 'PSObject'
            }
            if ($Headers) {
                $requestParameters['Headers'] = $Headers
            }

            return Invoke-MgGraphRequest @requestParameters
        }
        catch {
            $attempt++
            $response = $null
            $responseProperty = $_.Exception.PSObject.Properties['Response']
            if ($responseProperty) {
                $response = $responseProperty.Value
            }

            $responseHeaders = $null
            $responseHeadersProperty = $_.Exception.PSObject.Properties['ResponseHeaders']
            if ($responseHeadersProperty) {
                $responseHeaders = $responseHeadersProperty.Value
            }

            $statusCode = Get-ResponseStatusCode -Response $response -Exception $_.Exception
            $isTransient = $statusCode -in @(429, 500, 502, 503, 504)

            if ((-not $isTransient) -or ($attempt -gt $MaximumRetryCount)) {
                throw
            }

            $retryAfterSeconds = Get-ResponseRetryAfterSeconds -Response $response -ResponseHeaders $responseHeaders
            if (-not $retryAfterSeconds) {
                $retryAfterSeconds = [Math]::Min(60, [Math]::Pow(2, $attempt)) + (Get-Random -Minimum 0 -Maximum 3)
            }

            Write-Warning ("Graph request returned HTTP {0}. Retrying attempt {1}/{2} after {3} second(s)." -f $statusCode, $attempt, $MaximumRetryCount, $retryAfterSeconds)
            Start-Sleep -Seconds $retryAfterSeconds
        }
    }
}

function Get-ObjectPropertyValue {
    param(
        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if (-not $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($property) {
        return $property.Value
    }

    return $null
}

function Get-FirstObjectPropertyValue {
    param(
        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$PropertyNames
    )

    foreach ($propertyName in $PropertyNames) {
        $value = Get-ObjectPropertyValue -InputObject $InputObject -PropertyName $propertyName
        if ($null -ne $value) {
            return $value
        }
    }

    return $null
}

function Get-GraphCollection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter()]
        [hashtable]$Headers
    )

    $items = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri

    while ($nextUri) {
        $response = Invoke-GraphRequestWithRetry -Method 'GET' -Uri $nextUri -Headers $Headers
        $valueProperty = $response.PSObject.Properties['value']

        if ($valueProperty) {
            foreach ($item in $valueProperty.Value) {
                $items.Add($item)
            }
        }
        else {
            $items.Add($response)
        }

        $nextUri = Get-ObjectPropertyValue -InputObject $response -PropertyName '@odata.nextLink'
    }

    return $items.ToArray()
}

function ConvertTo-DelimitedText {
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Values,

        [Parameter()]
        [string]$Delimiter = ';'
    )

    $cleanValues = [System.Collections.Generic.List[string]]::new()
    foreach ($value in $Values) {
        if ($null -eq $value) {
            continue
        }

        $text = $value.ToString().Trim()
        if ($text.Length -gt 0 -and -not $cleanValues.Contains($text)) {
            $cleanValues.Add($text)
        }
    }

    return ($cleanValues | Sort-Object) -join $Delimiter
}

function ConvertTo-CsvSafeSnippet {
    param(
        [Parameter(Mandatory = $false)]
        [object]$Text,

        [Parameter()]
        [int]$MaximumLength = 500
    )

    if ($null -eq $Text) {
        return ''
    }

    $sanitized = $Text.ToString()
    $sanitized = $sanitized -replace '[\r\n]+', ' '
    $sanitized = $sanitized -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ' '
    $sanitized = $sanitized -replace ',', ';'
    $sanitized = $sanitized -replace '\s{2,}', ' '
    $sanitized = $sanitized.Trim()

    if ($sanitized.Length -gt $MaximumLength) {
        return $sanitized.Substring(0, $MaximumLength)
    }

    return $sanitized
}

function Export-CsvRows {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Rows,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Columns
    )

    if ($Rows -and $Rows.Count -gt 0) {
        $Rows | Select-Object -Property $Columns | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        return
    }

    # Write header-only CSV when no rows
    $header = ($Columns | ForEach-Object { '"' + ($_ -replace '"', '""') + '"' }) -join ','
    Set-Content -Path $Path -Value $header -Encoding UTF8
}

function Get-PropertyValuesFromItems {
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Items,

        [Parameter(Mandatory = $true)]
        [string[]]$PropertyNames
    )

    $values = [System.Collections.Generic.List[object]]::new()

    foreach ($item in $Items) {
        if ($null -eq $item) {
            continue
        }

        if ($item -is [string] -or $item.GetType().IsValueType) {
            $values.Add($item)
            continue
        }

        foreach ($propertyName in $PropertyNames) {
            $propertyValue = Get-ObjectPropertyValue -InputObject $item -PropertyName $propertyName
            if ($null -ne $propertyValue) {
                if ($propertyValue -is [System.Array]) {
                    foreach ($innerValue in $propertyValue) {
                        $values.Add($innerValue)
                    }
                }
                else {
                    $values.Add($propertyValue)
                }
            }
        }
    }

    return $values.ToArray()
}

function Get-CollectionPropertyValues {
    param(
        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$PropertyNames
    )

    $values = [System.Collections.Generic.List[object]]::new()
    foreach ($propertyName in $PropertyNames) {
        $propertyValue = Get-ObjectPropertyValue -InputObject $InputObject -PropertyName $propertyName
        if ($null -eq $propertyValue) {
            continue
        }

        if ($propertyValue -is [System.Array]) {
            foreach ($value in $propertyValue) {
                $values.Add($value)
            }
        }
        else {
            $values.Add($propertyValue)
        }
    }

    return $values.ToArray()
}

function Get-CopilotLicenseInfo {
    param(
        [Parameter(Mandatory = $true)]
        [object]$User,

        [Parameter(Mandatory = $true)]
        [hashtable]$TierMap
    )

    $userId = Get-ObjectPropertyValue -InputObject $User -PropertyName 'id'
    $licenseUri = "https://graph.microsoft.com/beta/users/$([System.Uri]::EscapeDataString($userId))/licenseDetails?`$select=skuId,skuPartNumber"
    $licenseDetails = @(Get-GraphCollection -Uri $licenseUri)
    $skuPartNumbers = @($licenseDetails | ForEach-Object { Get-ObjectPropertyValue -InputObject $_ -PropertyName 'skuPartNumber' } | Where-Object { $_ })
    $copilotSkuPartNumbers = [System.Collections.Generic.List[string]]::new()
    $tierCandidates = [System.Collections.Generic.List[string]]::new()

    foreach ($skuPartNumber in $skuPartNumbers) {
        if ($TierMap.ContainsKey($skuPartNumber)) {
            $copilotSkuPartNumbers.Add($skuPartNumber)
            $tierCandidates.Add($TierMap[$skuPartNumber])
        }
        elseif ($skuPartNumber -match '(?i)copilot') {
            $copilotSkuPartNumbers.Add($skuPartNumber)
            $tierCandidates.Add('Unknown')
        }
    }

    if ($copilotSkuPartNumbers.Count -eq 0) {
        return $null
    }

    $tier = 'Unknown'
    if ($tierCandidates -contains 'Premium') {
        $tier = 'Premium'
    }
    elseif ($tierCandidates -contains 'Basic') {
        $tier = 'Basic'
    }

    return [pscustomobject]@{
        Tier = $tier
        Licenses = (ConvertTo-DelimitedText -Values $copilotSkuPartNumbers.ToArray())
        AllLicenses = (ConvertTo-DelimitedText -Values $skuPartNumbers)
    }
}

function Get-AppAndFeatureFromAppClass {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$AppClass,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$ConversationType
    )

    $app = 'Unknown'
    $feature = 'Unknown'
    $agentId = ''
    $appClassText = ''
    $conversationTypeText = ''

    if (-not [string]::IsNullOrWhiteSpace($AppClass)) {
        $appClassText = $AppClass.Trim()
        $lastSegment = @($appClassText -split '\.')[-1]
        if (-not [string]::IsNullOrWhiteSpace($lastSegment)) {
            $feature = $lastSegment
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ConversationType)) {
        $conversationTypeText = $ConversationType.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($appClassText)) {
        return [pscustomobject]@{
            App = $app
            Feature = $feature
            AgentId = $agentId
        }
    }

    if ($appClassText -match '(?i)(^|\.)ConnectedAIApp\.Entra\.([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[^.]+)$') {
        return [pscustomobject]@{
            App = 'Connected AI Agent'
            Feature = 'Connected Agent'
            AgentId = $Matches[2]
        }
    }

    if ($appClassText -match '(?i)(^|\.)Copilot\.ThirdPartyCopilot$') {
        return [pscustomobject]@{
            App = 'Third-Party Agent'
            Feature = 'Third-Party Copilot'
            AgentId = ''
        }
    }

    if ($appClassText -match '(?i)(^|\.)Copilot\.BizChat$') {
        $bizChatFeature = 'Copilot Chat (Work)'
        if ($conversationTypeText -match '(?i)web') {
            $bizChatFeature = 'Copilot Chat (Web)'
        }
        elseif ($conversationTypeText -match '(?i)(work|biz)') {
            $bizChatFeature = 'Copilot Chat (Work)'
        }

        return [pscustomobject]@{
            App = 'Copilot Chat'
            Feature = $bizChatFeature
            AgentId = ''
        }
    }

    if ($appClassText -match '(?i)(^|\.)Copilot\.Teams$') {
        $teamsFeature = 'Teams Copilot'
        if ($conversationTypeText -match '(?i)meeting') {
            $teamsFeature = 'Teams Meeting'
        }
        elseif ($conversationTypeText -match '(?i)(appchat|chat)') {
            $teamsFeature = 'Teams Chat'
        }

        return [pscustomobject]@{
            App = 'Teams'
            Feature = $teamsFeature
            AgentId = ''
        }
    }

    $copilotAppMap = @{
        'Outlook' = 'Outlook'
        'Word' = 'Word'
        'Excel' = 'Excel'
        'PowerPoint' = 'PowerPoint'
        'OneNote' = 'OneNote'
        'Loop' = 'Loop'
        'Whiteboard' = 'Whiteboard'
    }

    foreach ($suffix in $copilotAppMap.Keys) {
        if ($appClassText -match ("(?i)(^|\.)Copilot\.{0}$" -f [regex]::Escape($suffix))) {
            $friendlyApp = $copilotAppMap[$suffix]
            return [pscustomobject]@{
                App = $friendlyApp
                Feature = "$friendlyApp Copilot"
                AgentId = ''
            }
        }
    }

    return [pscustomobject]@{
        App = $app
        Feature = $feature
        AgentId = $agentId
    }
}

function Get-ActivityDateString {
    param(
        [Parameter(Mandatory = $false)]
        [object]$CreatedDateTime
    )

    if ($null -eq $CreatedDateTime -or [string]::IsNullOrWhiteSpace($CreatedDateTime.ToString())) {
        return ''
    }

    try {
        return ([datetime]::Parse($CreatedDateTime.ToString()).ToUniversalTime()).ToString('yyyy-MM-dd')
    }
    catch {
        return ''
    }
}

function New-InteractionRow {
    param(
        [Parameter(Mandatory = $true)]
        [object]$User,

        [Parameter(Mandatory = $true)]
        [object]$Interaction,

        [Parameter(Mandatory = $true)]
        [object]$LicenseInfo
    )

    $body = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'body'
    if ($body -is [string]) {
        $bodyContent = $body
        $bodyContentType = ''
    }
    else {
        $bodyContent = Get-ObjectPropertyValue -InputObject $body -PropertyName 'content'
        $bodyContentType = Get-ObjectPropertyValue -InputObject $body -PropertyName 'contentType'
    }

    $contextItems = Get-CollectionPropertyValues -InputObject $Interaction -PropertyNames @(
        'contexts',
        'context',
        'inputContexts',
        'contextReferences',
        'referencedResources'
    )
    $linkItems = Get-CollectionPropertyValues -InputObject $Interaction -PropertyNames @(
        'links',
        'link',
        'citations',
        'references',
        'referencedLinks'
    )

    $directContextTypes = Get-CollectionPropertyValues -InputObject $Interaction -PropertyNames @('contextTypes')
    $contextTypes = @($directContextTypes) + @(Get-PropertyValuesFromItems -Items $contextItems -PropertyNames @('type', 'contextType', 'contextTypeName'))
    $contextNames = Get-PropertyValuesFromItems -Items $contextItems -PropertyNames @('name', 'displayName', 'title', 'fileName', 'resourceName')
    $linkTypes = Get-PropertyValuesFromItems -Items $linkItems -PropertyNames @('type', 'linkType', 'referenceType')
    $appClass = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'appClass'
    $conversationType = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'conversationType'
    $createdDateTime = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'createdDateTime'
    $appFeature = Get-AppAndFeatureFromAppClass -AppClass $appClass -ConversationType $conversationType

    return [pscustomobject]@{
        userId = Get-ObjectPropertyValue -InputObject $User -PropertyName 'id'
        userPrincipalName = Get-ObjectPropertyValue -InputObject $User -PropertyName 'userPrincipalName'
        displayName = Get-ObjectPropertyValue -InputObject $User -PropertyName 'displayName'
        interactionId = Get-FirstObjectPropertyValue -InputObject $Interaction -PropertyNames @('id', 'interactionId')
        sessionId = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'sessionId'
        appClass = $appClass
        app = $appFeature.App
        feature = $appFeature.Feature
        agentId = $appFeature.AgentId
        interactionType = Get-ObjectPropertyValue -InputObject $Interaction -PropertyName 'interactionType'
        conversationType = $conversationType
        createdDateTime = $createdDateTime
        activityDate = Get-ActivityDateString -CreatedDateTime $createdDateTime
        copilotTier = $LicenseInfo.Tier
        contextTypes = ConvertTo-DelimitedText -Values $contextTypes
        contextNames = ConvertTo-DelimitedText -Values $contextNames
        linkTypes = ConvertTo-DelimitedText -Values $linkTypes
        bodyContentType = $bodyContentType
        bodySnippet = ConvertTo-CsvSafeSnippet -Text $bodyContent -MaximumLength 500
    }
}

function Get-EnterpriseInteractionsForUser {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $false)]
        [datetime]$FromDate,

        [Parameter(Mandatory = $false)]
        [datetime]$ToDate
    )

    # NOTE: The docs only show $filter support for appClass, not createdDateTime.
    # We first try without a date filter. Client-side date filtering is applied after retrieval.
    $escapedUserId = [System.Uri]::EscapeDataString($UserId)
    $uri = "https://graph.microsoft.com/beta/copilot/users/$escapedUserId/interactionHistory/getAllEnterpriseInteractions?`$top=100"

    $allInteractions = @(Get-GraphCollection -Uri $uri)

    # Client-side date filtering if date range was specified
    if ($FromDate -or $ToDate) {
        $filtered = [System.Collections.Generic.List[object]]::new()
        foreach ($interaction in $allInteractions) {
            $createdStr = Get-ObjectPropertyValue -InputObject $interaction -PropertyName 'createdDateTime'
            if (-not $createdStr) {
                $filtered.Add($interaction)
                continue
            }
            try {
                $createdDt = [datetime]::Parse($createdStr).ToUniversalTime()
                $inRange = $true
                if ($FromDate -and $createdDt -lt $FromDate.ToUniversalTime()) { $inRange = $false }
                if ($ToDate -and $createdDt -gt $ToDate.ToUniversalTime()) { $inRange = $false }
                if ($inRange) { $filtered.Add($interaction) }
            }
            catch {
                $filtered.Add($interaction)
            }
        }
        return $filtered.ToArray()
    }

    return $allInteractions
}

function Join-UsageGroupKey {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Values
    )

    return ($Values | ForEach-Object {
        if ($null -eq $_) {
            ''
        }
        else {
            $_
        }
    }) -join ([char]31)
}

function Get-RowStringValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Row,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $value = Get-ObjectPropertyValue -InputObject $Row -PropertyName $PropertyName
    if ($null -eq $value) {
        return ''
    }

    return $value.ToString()
}

function New-UsageByUserAppDayRows {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$InteractionRows
    )

    $groups = @{}

    foreach ($row in $InteractionRows) {
        $activityDate = Get-RowStringValue -Row $row -PropertyName 'activityDate'
        $userId = Get-RowStringValue -Row $row -PropertyName 'userId'
        $userPrincipalName = Get-RowStringValue -Row $row -PropertyName 'userPrincipalName'
        $displayName = Get-RowStringValue -Row $row -PropertyName 'displayName'
        $copilotTier = Get-RowStringValue -Row $row -PropertyName 'copilotTier'
        $app = Get-RowStringValue -Row $row -PropertyName 'app'
        $feature = Get-RowStringValue -Row $row -PropertyName 'feature'
        $agentId = Get-RowStringValue -Row $row -PropertyName 'agentId'
        $key = Join-UsageGroupKey -Values @($activityDate, $userId, $app, $feature, $agentId)

        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = [pscustomobject]@{
                activityDate = $activityDate
                userId = $userId
                userPrincipalName = $userPrincipalName
                displayName = $displayName
                copilotTier = $copilotTier
                app = $app
                feature = $feature
                agentId = $agentId
                promptCount = 0
                responseCount = 0
                totalInteractions = 0
                sessionIds = @{}
            }
        }

        $group = $groups[$key]
        $interactionType = Get-RowStringValue -Row $row -PropertyName 'interactionType'
        if ($interactionType -ieq 'userPrompt') {
            $group.promptCount++
        }
        elseif ($interactionType -ieq 'aiResponse') {
            $group.responseCount++
        }

        $group.totalInteractions++
        $sessionId = Get-RowStringValue -Row $row -PropertyName 'sessionId'
        if (-not [string]::IsNullOrWhiteSpace($sessionId)) {
            $group.sessionIds[$sessionId] = $true
        }
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($group in $groups.Values) {
        $rows.Add([pscustomobject]@{
            activityDate = $group.activityDate
            userId = $group.userId
            userPrincipalName = $group.userPrincipalName
            displayName = $group.displayName
            copilotTier = $group.copilotTier
            app = $group.app
            feature = $group.feature
            agentId = $group.agentId
            promptCount = $group.promptCount
            responseCount = $group.responseCount
            totalInteractions = $group.totalInteractions
            uniqueSessions = $group.sessionIds.Keys.Count
        })
    }

    return $rows.ToArray()
}

function New-UsageByAppFeatureDayRows {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$InteractionRows
    )

    $groups = @{}

    foreach ($row in $InteractionRows) {
        $activityDate = Get-RowStringValue -Row $row -PropertyName 'activityDate'
        $app = Get-RowStringValue -Row $row -PropertyName 'app'
        $feature = Get-RowStringValue -Row $row -PropertyName 'feature'
        $agentId = Get-RowStringValue -Row $row -PropertyName 'agentId'
        $key = Join-UsageGroupKey -Values @($activityDate, $app, $feature, $agentId)

        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = [pscustomobject]@{
                activityDate = $activityDate
                app = $app
                feature = $feature
                agentId = $agentId
                promptCount = 0
                responseCount = 0
                totalInteractions = 0
                userIds = @{}
                premiumUserIds = @{}
                basicUserIds = @{}
            }
        }

        $group = $groups[$key]
        $interactionType = Get-RowStringValue -Row $row -PropertyName 'interactionType'
        if ($interactionType -ieq 'userPrompt') {
            $group.promptCount++
        }
        elseif ($interactionType -ieq 'aiResponse') {
            $group.responseCount++
        }

        $group.totalInteractions++

        $userKey = Get-RowStringValue -Row $row -PropertyName 'userId'
        if ([string]::IsNullOrWhiteSpace($userKey)) {
            $userKey = Get-RowStringValue -Row $row -PropertyName 'userPrincipalName'
        }

        if (-not [string]::IsNullOrWhiteSpace($userKey)) {
            $group.userIds[$userKey] = $true
            $copilotTier = Get-RowStringValue -Row $row -PropertyName 'copilotTier'
            if ($copilotTier -ieq 'Premium') {
                $group.premiumUserIds[$userKey] = $true
            }
            elseif ($copilotTier -ieq 'Basic') {
                $group.basicUserIds[$userKey] = $true
            }
        }
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($group in $groups.Values) {
        $rows.Add([pscustomobject]@{
            activityDate = $group.activityDate
            app = $group.app
            feature = $group.feature
            agentId = $group.agentId
            uniqueUsers = $group.userIds.Keys.Count
            promptCount = $group.promptCount
            responseCount = $group.responseCount
            totalInteractions = $group.totalInteractions
            premiumUsers = $group.premiumUserIds.Keys.Count
            basicUsers = $group.basicUserIds.Keys.Count
        })
    }

    return $rows.ToArray()
}

if ($EndDate -lt $StartDate) {
    throw 'EndDate must be greater than or equal to StartDate.'
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = $PSScriptRoot
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = (Get-Location).Path
}

New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null

$usersPath = Join-Path -Path $OutputDirectory -ChildPath 'Users.csv'
$interactionsPath = Join-Path -Path $OutputDirectory -ChildPath 'Interactions.csv'
$usageByUserAppDayPath = Join-Path -Path $OutputDirectory -ChildPath 'UsageByUserAppDay.csv'
$usageByAppFeatureDayPath = Join-Path -Path $OutputDirectory -ChildPath 'UsageByAppFeatureDay.csv'
$errorsPath = Join-Path -Path $OutputDirectory -ChildPath 'Errors.csv'

Assert-GraphAuthenticationModule
Connect-CopilotGraph -AuthenticationMode $PSCmdlet.ParameterSetName

$headers = $null
$userQuery = "`$select=id,displayName,userPrincipalName&`$top=999"
if (-not $IncludeAllUsers) {
    $headers = @{ ConsistencyLevel = 'eventual' }
    $assignedLicenseFilter = [System.Uri]::EscapeDataString('assignedLicenses/$count ne 0')
    $userQuery = "$userQuery&`$count=true&`$filter=$assignedLicenseFilter"
}

$directoryUsersUri = "https://graph.microsoft.com/beta/users?$userQuery"
Write-Host 'Retrieving candidate users from Microsoft Graph...'
$directoryUsers = @(Get-GraphCollection -Uri $directoryUsersUri -Headers $headers)

$userRows = [System.Collections.Generic.List[object]]::new()
$interactionRows = [System.Collections.Generic.List[object]]::new()
$errorRows = [System.Collections.Generic.List[object]]::new()
$processedCopilotUsers = 0
$examinedUsers = 0

foreach ($user in $directoryUsers) {
    $examinedUsers++
    $userId = Get-ObjectPropertyValue -InputObject $user -PropertyName 'id'
    $userPrincipalName = Get-ObjectPropertyValue -InputObject $user -PropertyName 'userPrincipalName'

    Write-Progress -Activity 'Exporting Microsoft 365 Copilot interactions' -Status "Checking licenses for $userPrincipalName" -PercentComplete (($examinedUsers / [Math]::Max(1, $directoryUsers.Count)) * 100)

    try {
        $licenseInfo = Get-CopilotLicenseInfo -User $user -TierMap $SkuTierMap
        if (-not $licenseInfo) {
            continue
        }

        $processedCopilotUsers++
        $userRows.Add([pscustomobject]@{
            userId = $userId
            displayName = Get-ObjectPropertyValue -InputObject $user -PropertyName 'displayName'
            userPrincipalName = $userPrincipalName
            copilotTier = $licenseInfo.Tier
            licenses = $licenseInfo.Licenses
        })

        Write-Progress -Activity 'Exporting Microsoft 365 Copilot interactions' -Status "Exporting interactions for $userPrincipalName" -PercentComplete (($examinedUsers / [Math]::Max(1, $directoryUsers.Count)) * 100)

        $interactions = @(Get-EnterpriseInteractionsForUser -UserId $userId -FromDate $StartDate -ToDate $EndDate)
        foreach ($interaction in $interactions) {
            $interactionRows.Add((New-InteractionRow -User $user -Interaction $interaction -LicenseInfo $licenseInfo))
        }

        if ($DelayBetweenUserRequestsMilliseconds -gt 0) {
            Start-Sleep -Milliseconds $DelayBetweenUserRequestsMilliseconds
        }

        if ($MaxUsers -gt 0 -and $processedCopilotUsers -ge $MaxUsers) {
            break
        }
    }
    catch {
        # Try to extract the Graph error response body for better diagnostics
        $detailedError = $_.Exception.Message
        try {
            $responseBody = $null
            if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = [System.IO.StreamReader]::new($stream)
                    $responseBody = $reader.ReadToEnd()
                    $reader.Dispose()
                }
            }
            if (-not $responseBody -and $_.ErrorDetails -and $_.ErrorDetails.Message) {
                $responseBody = $_.ErrorDetails.Message
            }
            if ($responseBody) {
                $detailedError = "$detailedError | Response: $responseBody"
            }
        }
        catch { }

        $errorRows.Add([pscustomobject]@{
            userId = $userId
            userPrincipalName = $userPrincipalName
            errorMessage = $detailedError
            timestampUtc = (Get-Date).ToUniversalTime().ToString('o')
        })
        Write-Warning ("Failed to export data for {0}: {1}" -f $userPrincipalName, $detailedError)
        continue
    }
}

Write-Progress -Activity 'Exporting Microsoft 365 Copilot interactions' -Completed

$usageByUserAppDayRows = @(New-UsageByUserAppDayRows -InteractionRows ($interactionRows.ToArray()) | Sort-Object -Property @{ Expression = 'activityDate'; Descending = $true }, @{ Expression = 'userPrincipalName'; Ascending = $true }, @{ Expression = 'app'; Ascending = $true }, @{ Expression = 'feature'; Ascending = $true })
$usageByAppFeatureDayRows = @(New-UsageByAppFeatureDayRows -InteractionRows ($interactionRows.ToArray()) | Sort-Object -Property @{ Expression = 'activityDate'; Descending = $true }, @{ Expression = 'app'; Ascending = $true }, @{ Expression = 'feature'; Ascending = $true })

Export-CsvRows -Rows ($userRows.ToArray()) -Path $usersPath -Columns @(
    'userId',
    'displayName',
    'userPrincipalName',
    'copilotTier',
    'licenses'
)
Export-CsvRows -Rows ($interactionRows.ToArray()) -Path $interactionsPath -Columns @(
    'userId',
    'userPrincipalName',
    'interactionId',
    'sessionId',
    'appClass',
    'app',
    'feature',
    'agentId',
    'interactionType',
    'conversationType',
    'createdDateTime',
    'activityDate',
    'copilotTier',
    'contextTypes',
    'contextNames',
    'linkTypes',
    'bodyContentType',
    'bodySnippet'
)
Export-CsvRows -Rows $usageByUserAppDayRows -Path $usageByUserAppDayPath -Columns @(
    'activityDate',
    'userId',
    'userPrincipalName',
    'displayName',
    'copilotTier',
    'app',
    'feature',
    'agentId',
    'promptCount',
    'responseCount',
    'totalInteractions',
    'uniqueSessions'
)
Export-CsvRows -Rows $usageByAppFeatureDayRows -Path $usageByAppFeatureDayPath -Columns @(
    'activityDate',
    'app',
    'feature',
    'agentId',
    'uniqueUsers',
    'promptCount',
    'responseCount',
    'totalInteractions',
    'premiumUsers',
    'basicUsers'
)
Export-CsvRows -Rows ($errorRows.ToArray()) -Path $errorsPath -Columns @(
    'userId',
    'userPrincipalName',
    'errorMessage',
    'timestampUtc'
)

[pscustomobject]@{
    OutputDirectory = (Resolve-Path -Path $OutputDirectory).Path
    UsersExamined = $examinedUsers
    CopilotUsersProcessed = $processedCopilotUsers
    InteractionsExported = $interactionRows.Count
    Errors = $errorRows.Count
    UsersCsv = $usersPath
    UsersCsvRows = $userRows.Count
    InteractionsCsv = $interactionsPath
    InteractionsCsvRows = $interactionRows.Count
    UsageByUserAppDayCsv = $usageByUserAppDayPath
    UsageByUserAppDayCsvRows = $usageByUserAppDayRows.Count
    UsageByAppFeatureDayCsv = $usageByAppFeatureDayPath
    UsageByAppFeatureDayCsvRows = $usageByAppFeatureDayRows.Count
    ErrorsCsv = $errorsPath
    ErrorsCsvRows = $errorRows.Count
} | Format-List
