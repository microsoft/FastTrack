#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $script:ExporterPath = (Resolve-Path (Join-Path $PSScriptRoot '..\Export-CopilotInteractions.ps1')).Path
    $parseErrors = $null
    $script:ExporterAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:ExporterPath, [ref]$null, [ref]$parseErrors
    )
    if ($parseErrors.Count -gt 0) {
        throw ($parseErrors | Out-String)
    }

    foreach ($definition in $script:ExporterAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false)) {
        . ([scriptblock]::Create($definition.Extent.Text))
    }

    $script:DefaultServicePlans = ($script:ExporterAst.ParamBlock.Parameters |
        Where-Object { $_.Name.VariablePath.UserPath -eq 'CopilotServicePlans' }).DefaultValue.SafeGetValue()
    $script:DefaultTierMap = ($script:ExporterAst.ParamBlock.Parameters |
        Where-Object { $_.Name.VariablePath.UserPath -eq 'SkuTierMap' }).DefaultValue.SafeGetValue()
    $script:CopilotPlanId = '3f30311c-6b1e-48a4-ab79-725b469da960'
    $script:OtherPlanId = '00000000-0000-0000-0000-000000000001'

    function New-TestSku {
        param(
            [string]$Id,
            [string]$PartNumber,
            [string]$PlanId = $script:CopilotPlanId,
            [string]$PlanName = 'M365_COPILOT_BUSINESS_CHAT',
            [switch]$WithoutPlanMetadata
        )

        $plans = @()
        if (-not $WithoutPlanMetadata) {
            $plans = @([pscustomobject]@{
                servicePlanId = $PlanId
                servicePlanName = $PlanName
                provisioningStatus = 'Success'
            })
        }

        [pscustomobject]@{
            skuId = $Id
            skuPartNumber = $PartNumber
            servicePlans = $plans
        }
    }

    function New-TestUser {
        param(
            [string]$Id = 'paid-user',
            [string]$SkuId = 'paid',
            [string]$PlanId = $script:CopilotPlanId,
            [string]$PlanStatus = 'Enabled',
            [string[]]$DisabledPlans = @(),
            [switch]$WithoutLicenses
        )

        $licenses = @()
        if (-not $WithoutLicenses) {
            $licenses = @([pscustomobject]@{ skuId = $SkuId; disabledPlans = $DisabledPlans })
        }

        [pscustomobject]@{
            id = $Id
            displayName = $Id
            userPrincipalName = "$Id@example.invalid"
            assignedLicenses = $licenses
            assignedPlans = @([pscustomobject]@{
                servicePlanId = $PlanId
                capabilityStatus = $PlanStatus
            })
        }
    }

    $script:SkuCatalog = @{
        paid = New-TestSku -Id 'paid' -PartNumber 'Microsoft_365_Copilot'
        bundle = New-TestSku -Id 'bundle' -PartNumber 'TEST_COPILOT_BUNDLE'
        office = New-TestSku -Id 'office' -PartNumber 'TEST_OFFICE' -PlanId $script:OtherPlanId -PlanName 'TEST_OFFICE_PLAN'
        studio = New-TestSku -Id 'studio' -PartNumber 'TEST_COPILOT_STUDIO' -PlanId $script:OtherPlanId -PlanName 'TEST_STUDIO_PLAN'
        fallback = New-TestSku -Id 'fallback' -PartNumber 'M365_Copilot' -WithoutPlanMetadata
    }
    $script:LicenseParameters = @{
        TierMap = $script:DefaultTierMap
        ServicePlans = $script:DefaultServicePlans
        SkuDetailsById = $script:SkuCatalog
    }

    function Connect-MgGraph {
        param(
            $TenantId, $ClientId, $ClientSecretCredential, $CertificateThumbprint,
            $ContextScope, [switch]$NoWelcome
        )
        throw 'Authentication must be mocked in offline tests.'
    }

    function Invoke-MgGraphRequest {
        param($Method, $Uri, $OutputType, $Headers)
        throw 'Graph requests must be mocked in offline tests.'
    }
}

Describe 'Copilot license eligibility' {
    It 'defaults to the documented Graph-grounded chat service plan and Premium-only SKU mappings' {
        $script:DefaultServicePlans | Should -Contain $script:CopilotPlanId
        $script:DefaultServicePlans | Should -Contain 'M365_COPILOT_BUSINESS_CHAT'
        @($script:DefaultTierMap.Values | Where-Object { $_ -ne 'Premium' }).Count | Should -Be 0
    }

    It 'recognizes an available standalone Copilot license' {
        $result = Get-CopilotLicenseInfo -User (New-TestUser) @script:LicenseParameters
        $result.Tier | Should -Be 'Premium'
        $result.Licenses | Should -Be 'Microsoft_365_Copilot'
    }

    It 'recognizes a qualifying bundle without a Copilot SKU name or mapping' {
        $result = Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'bundle') @script:LicenseParameters
        $result.Licenses | Should -Be 'TEST_COPILOT_BUNDLE'
    }

    It 'supports matching the configured service plan by name' {
        $parameters = $script:LicenseParameters.Clone()
        $parameters.ServicePlans = @('m365_copilot_business_chat')
        (Get-CopilotLicenseInfo -User (New-TestUser) @parameters).Tier | Should -Be 'Premium'
    }

    It 'allows a Warning capability because the plan remains available during its grace period' {
        (Get-CopilotLicenseInfo -User (New-TestUser -PlanStatus 'Warning') @script:LicenseParameters).Tier |
            Should -Be 'Premium'
    }

    It 'excludes unavailable or unknown capability status <Status>' -TestCases @(
        @{ Status = 'Suspended' }, @{ Status = 'LockedOut' }, @{ Status = 'Deleted' },
        @{ Status = '' }, @{ Status = 'UnexpectedStatus' }
    ) {
        param($Status)
        Get-CopilotLicenseInfo -User (New-TestUser -PlanStatus $Status) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'excludes a disabled plan even if the SKU is mapped to Premium and assignedPlans says Enabled' {
        Get-CopilotLicenseInfo -User (New-TestUser -DisabledPlans @($script:CopilotPlanId)) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'recognizes an available plan from another assigned license when one license disables it' {
        $user = New-TestUser -DisabledPlans @($script:CopilotPlanId)
        $user.assignedLicenses += [pscustomobject]@{ skuId = 'bundle'; disabledPlans = @() }
        (Get-CopilotLicenseInfo -User $user @script:LicenseParameters).Licenses |
            Should -Be 'TEST_COPILOT_BUNDLE'
    }

    It 'does not infer eligibility from a license SKU alone when the user has no available Copilot plan' {
        Get-CopilotLicenseInfo -User (New-TestUser -PlanId $script:OtherPlanId) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'excludes users with only ordinary Office or Copilot Studio licenses' -TestCases @(
        @{ Sku = 'office' }, @{ Sku = 'studio' }
    ) {
        param($Sku)
        Get-CopilotLicenseInfo -User (New-TestUser -SkuId $Sku -PlanId $script:OtherPlanId) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'excludes an old available plan when no current license is assigned' {
        Get-CopilotLicenseInfo -User (New-TestUser -WithoutLicenses) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'uses the Premium SKU fallback only with an available configured plan ID' {
        (Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'fallback') @script:LicenseParameters).Tier |
            Should -Be 'Premium'
    }

    It 'does not let the fallback bypass a disabled plan' {
        Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'fallback' -DisabledPlans @($script:CopilotPlanId)) @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'does not let the fallback bypass an unavailable plan' {
        Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'fallback' -PlanStatus 'Suspended') @script:LicenseParameters |
            Should -BeNullOrEmpty
    }

    It 'ignores Basic fallback mappings' {
        $parameters = $script:LicenseParameters.Clone()
        $parameters.TierMap = @{ M365_Copilot = 'Basic' }
        Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'fallback') @parameters | Should -BeNullOrEmpty
    }

    It 'reports missing subscribed SKU metadata instead of treating it as an unlicensed user' {
        { Get-CopilotLicenseInfo -User (New-TestUser -SkuId 'missing') @script:LicenseParameters } |
            Should -Throw '*subscribed SKU metadata*'
    }

    It 'reports missing selected user properties' {
        { Get-CopilotLicenseInfo -User ([pscustomobject]@{ id = 'incomplete' }) @script:LicenseParameters } |
            Should -Throw '*assignedLicenses and assignedPlans*'
    }
}

Describe 'Usage output compatibility' {
    It 'counts distinct licensed users and interactions without a basicUsers column' {
        $rows = @(
            [pscustomobject]@{ activityDate = '2026-10-28'; userId = 'one'; copilotTier = 'Premium'; app = 'Copilot Chat'; feature = 'Copilot Chat (Web)'; agentId = ''; interactionType = 'userPrompt' },
            [pscustomobject]@{ activityDate = '2026-10-28'; userId = 'one'; copilotTier = 'Premium'; app = 'Copilot Chat'; feature = 'Copilot Chat (Web)'; agentId = ''; interactionType = 'aiResponse' },
            [pscustomobject]@{ activityDate = '2026-10-28'; userId = 'two'; copilotTier = 'Premium'; app = 'Copilot Chat'; feature = 'Copilot Chat (Web)'; agentId = ''; interactionType = 'userPrompt' }
        )
        $result = @(New-UsageByAppFeatureDayRows -InteractionRows $rows)
        $result.Count | Should -Be 1
        $result[0].uniqueUsers | Should -Be 2
        $result[0].premiumUsers | Should -Be 2
        $result[0].promptCount | Should -Be 2
        $result[0].responseCount | Should -Be 1
        $result[0].totalInteractions | Should -Be 3
        $result[0].PSObject.Properties.Name | Should -Not -Contain 'basicUsers'
    }

    It 'writes headers for empty output' {
        $path = Join-Path $TestDrive 'empty.csv'
        Export-CsvRows -Rows @() -Path $path -Columns @('uniqueUsers', 'premiumUsers')
        (Get-Content $path) | Should -Be '"uniqueUsers","premiumUsers"'
    }

    It 'rejects the removed Interactive parameter without starting authentication' {
        $script:ExporterAst.ParamBlock.Parameters.Name.VariablePath.UserPath | Should -Not -Contain 'Interactive'
        { & $script:ExporterPath -Interactive } | Should -Throw '*Interactive*'
    }
}

Describe 'Offline app-only exporter' {
    BeforeEach {
        $script:DirectoryUsers = @(
            (New-TestUser -Id 'paid-user'),
            (New-TestUser -Id 'basic-user' -SkuId 'office' -PlanId $script:OtherPlanId),
            (New-TestUser -Id 'disabled-user' -DisabledPlans @($script:CopilotPlanId)),
            (New-TestUser -Id 'bundle-user' -SkuId 'bundle'),
            (New-TestUser -Id 'studio-user' -SkuId 'studio' -PlanId $script:OtherPlanId),
            (New-TestUser -Id 'suspended-user' -PlanStatus 'Suspended'),
            (New-TestUser -Id 'failed-user')
        )
        $script:GraphState = @{
            SkuCatalog = $script:SkuCatalog
            DirectoryUsers = $script:DirectoryUsers
            DirectoryPageSize = $script:DirectoryUsers.Count
        }
        $graphState = $script:GraphState
        $script:ExportParameters = @{
            TenantId = 'offline-tenant'
            ClientId = 'offline-app'
            ClientSecret = (ConvertTo-SecureString 'offline-test-placeholder' -AsPlainText -Force)
            OutputDirectory = (Join-Path $TestDrive 'export')
            StartDate = [datetime]'2026-10-28T00:00:00Z'
            EndDate = [datetime]'2026-10-29T00:00:00Z'
            DelayBetweenUserRequestsMilliseconds = 0
            WarningAction = 'SilentlyContinue'
        }

        Mock Get-Module { [pscustomobject]@{ Name = 'Microsoft.Graph.Authentication' } } -ParameterFilter {
            $ListAvailable -and $Name -eq 'Microsoft.Graph.Authentication'
        }
        Mock Import-Module {} -ParameterFilter { $Name -eq 'Microsoft.Graph.Authentication' }
        Mock Connect-MgGraph {}
        $graphMock = {
            param($Method, $Uri, $OutputType, $Headers)

            if ($Uri -like 'https://graph.microsoft.com/v1.0/subscribedSkus?*') {
                return [pscustomobject]@{ value = @($graphState.SkuCatalog.Values) }
            }
            if ($Uri -eq 'https://graph.microsoft.com/v1.0/users?$skiptoken=offline-next') {
                return [pscustomobject]@{ value = @($graphState.DirectoryUsers | Select-Object -Skip $graphState.DirectoryPageSize) }
            }
            if ($Uri -like 'https://graph.microsoft.com/v1.0/users?*') {
                $response = [pscustomobject]@{ value = @($graphState.DirectoryUsers | Select-Object -First $graphState.DirectoryPageSize) }
                if ($graphState.DirectoryUsers.Count -gt $graphState.DirectoryPageSize) {
                    $response | Add-Member -NotePropertyName '@odata.nextLink' -NotePropertyValue 'https://graph.microsoft.com/v1.0/users?$skiptoken=offline-next'
                }
                return $response
            }
            if ($Uri -match '/copilot/users/([^/]+)/interactionHistory/getAllEnterpriseInteractions') {
                if ($Matches[1] -eq 'failed-user') {
                    throw 'Synthetic interaction export failure.'
                }
                return [pscustomobject]@{ value = @(
                    [pscustomobject]@{
                        id = 'prompt'; sessionId = 'session'; appClass = 'IPM.SkypeTeams.Message.Copilot.BizChat'
                        conversationType = 'bizchat'; createdDateTime = '2026-10-28T12:00:00Z'; interactionType = 'userPrompt'
                        body = [pscustomobject]@{ contentType = 'text'; content = 'Synthetic offline test prompt.' }
                    },
                    [pscustomobject]@{
                        id = 'response'; sessionId = 'session'; appClass = 'IPM.SkypeTeams.Message.Copilot.BizChat'
                        conversationType = 'bizchat'; createdDateTime = '2026-10-28T12:00:01Z'; interactionType = 'aiResponse'
                        body = [pscustomobject]@{ contentType = 'text'; content = 'Synthetic offline test response.' }
                    }
                ) }
            }
            throw "Unexpected Graph request in offline test: $Uri"
        }.GetNewClosure()
        Mock Invoke-MgGraphRequest -MockWith $graphMock
    }

    It 'exports only eligible users, counts skips, preserves failures, and aggregates the CSVs' {
        $summary = & $script:ExporterPath @script:ExportParameters | Out-String
        $users = @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'Users.csv'))
        $interactions = @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'Interactions.csv'))
        $usage = @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'UsageByAppFeatureDay.csv'))
        $errors = @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'Errors.csv'))

        $users.Count | Should -Be 3
        @($users | Where-Object { $_.copilotTier -ne 'Premium' }).Count | Should -Be 0
        $interactions.Count | Should -Be 4
        $interactions.userId | Should -Not -Contain 'basic-user'
        $interactions.userId | Should -Not -Contain 'disabled-user'
        $usage.Count | Should -Be 1
        $usage[0].uniqueUsers | Should -Be '2'
        $usage[0].premiumUsers | Should -Be '2'
        $usage[0].PSObject.Properties.Name | Should -Not -Contain 'basicUsers'
        $errors.Count | Should -Be 1
        $errors[0].userId | Should -Be 'failed-user'
        $summary | Should -Match 'UsersSkippedWithoutCopilotLicense\s*:\s*4'
        $summary | Should -Match 'Errors\s*:\s*1'
        Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter {
            $ContextScope -eq 'Process' -and $null -ne $ClientSecretCredential
        }
        Should -Invoke Invoke-MgGraphRequest -Times 3 -Exactly -ParameterFilter {
            $Uri -like '*/interactionHistory/getAllEnterpriseInteractions?*'
        }
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*/licenseDetails*' }
    }

    It 'keeps eligibility filtering when IncludeAllUsers is selected' {
        $null = & $script:ExporterPath @script:ExportParameters -IncludeAllUsers
        @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'Users.csv')).Count | Should -Be 3
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -like 'https://graph.microsoft.com/v1.0/users?*' -and $Uri -notmatch '\$filter='
        }
    }

    It 'uses app-only certificate authentication' {
        $parameters = $script:ExportParameters.Clone()
        $parameters.Remove('ClientSecret')
        $parameters.CertificateThumbprint = 'OFFLINE-TEST-THUMBPRINT'
        $null = & $script:ExporterPath @parameters -MaxUsers 1
        Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter {
            $ClientId -eq 'offline-app' -and $CertificateThumbprint -eq 'OFFLINE-TEST-THUMBPRINT' -and $ContextScope -eq 'Process'
        }
    }

    It 'enforces MaxUsers even when an eligible user export fails' {
        $script:GraphState.DirectoryUsers = @((New-TestUser -Id 'failed-user'), (New-TestUser -Id 'paid-user'))
        $summary = & $script:ExporterPath @script:ExportParameters -MaxUsers 1 | Out-String
        $summary | Should -Match 'CopilotUsersProcessed\s*:\s*1'
        $summary | Should -Match 'UsersExamined\s*:\s*1'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -like '*/interactionHistory/getAllEnterpriseInteractions?*'
        }
    }

    It 'records missing SKU metadata as an error rather than a skipped unlicensed user' {
        $script:GraphState.DirectoryUsers = @((New-TestUser -SkuId 'missing'))
        $summary = & $script:ExporterPath @script:ExportParameters | Out-String
        $summary | Should -Match 'UsersSkippedWithoutCopilotLicense\s*:\s*0'
        $errors = @(Import-Csv (Join-Path $script:ExportParameters.OutputDirectory 'Errors.csv'))
        $errors.Count | Should -Be 1
        $errors[0].errorMessage | Should -Match 'subscribed SKU metadata'
    }

    It 'writes all five header-only CSVs when the directory is empty' {
        $script:GraphState.DirectoryUsers = @()
        $summary = & $script:ExporterPath @script:ExportParameters | Out-String
        foreach ($name in @('Users', 'Interactions', 'UsageByUserAppDay', 'UsageByAppFeatureDay', 'Errors')) {
            $path = Join-Path $script:ExportParameters.OutputDirectory "$name.csv"
            Test-Path $path | Should -BeTrue
            @(Get-Content $path).Count | Should -Be 1
            @(Import-Csv $path).Count | Should -Be 0
        }
        $summary | Should -Match 'UsersExamined\s*:\s*0'
    }

    It 'pages directory users before applying eligibility checks' {
        $script:GraphState.DirectoryPageSize = 3
        $summary = & $script:ExporterPath @script:ExportParameters | Out-String
        $summary | Should -Match 'UsersExamined\s*:\s*7'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://graph.microsoft.com/v1.0/users?$skiptoken=offline-next'
        }
    }
}
