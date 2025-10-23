<#
.SYNOPSIS
    SharePoint Permissions Risk Analysis Tool
    
.DESCRIPTION
    Analyzes SharePoint permissions data from CSV export and generates a prioritized risk assessment report.
    
.PARAMETER CsvPath
    Path to the SharePoint permissions CSV file
    
.PARAMETER OutputPath
    Path for the output HTML report (optional - defaults to same directory as input)
    
.EXAMPLE
    .\Analyze-SharePointRisk.ps1 -CsvPath ".\report.csv"
    
.EXAMPLE
    .\Analyze-SharePointRisk.ps1 -CsvPath ".\report.csv" -OutputPath ".\custom-report.html"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Default scoring configuration
$DefaultScoring = @{
    HighEEEUPermissions = 4          # High EEEU permissions (threshold-based)
    PrivateSiteWithEEEU = 3          # Private site with EEEU permissions
    PublicSiteWithSensitiveTitle = 5 # Public site with sensitive keywords in title
    EveryonePermissions = 3          # Everyone permissions (still risky)
    AnyoneLinks = 2                  # Anyone links (external sharing)
    NoSensitivityLabel = 1           # Reduced - not inherently risky
    HighUniquePermissions = 3        # Many unique permissions with broad access
    EEEUPermissionThreshold = 10     # Threshold for "high" EEEU permissions
    UniquePermissionThreshold = 50   # Threshold for "many" unique permissions
}

# Risk level definitions
$RiskLevels = @{
    Critical = @{ Min = 10; Max = 999; Color = "#dc3545"; Label = "Critical Risk" }
    High = @{ Min = 7; Max = 9; Color = "#fd7e14"; Label = "High Risk" }
    Medium = @{ Min = 4; Max = 6; Color = "#ffc107"; Label = "Medium Risk" }
    Low = @{ Min = 1; Max = 3; Color = "#17a2b8"; Label = "Low Risk" }
    NoRisk = @{ Min = 0; Max = 0; Color = "#28a745"; Label = "No Risk" }
}

function Get-ScoringPreference {
    <#
    .SYNOPSIS
    Asks user if they want to use custom scoring
    #>
    
    Write-Host "`nScoring Configuration" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Default scoring weights:" -ForegroundColor Yellow
    Write-Host "- High EEEU Permissions ($($DefaultScoring.EEEUPermissionThreshold)+): +$($DefaultScoring.HighEEEUPermissions) points" -ForegroundColor White
    Write-Host "- Private Site with EEEU: +$($DefaultScoring.PrivateSiteWithEEEU) points" -ForegroundColor White
    Write-Host "- Public Site with Sensitive Title: +$($DefaultScoring.PublicSiteWithSensitiveTitle) points" -ForegroundColor White
    Write-Host "- Everyone Permissions: +$($DefaultScoring.EveryonePermissions) points" -ForegroundColor White
    Write-Host "- Anyone Links: +$($DefaultScoring.AnyoneLinks) points" -ForegroundColor White
    Write-Host "- High Unique Permissions ($($DefaultScoring.UniquePermissionThreshold)+): +$($DefaultScoring.HighUniquePermissions) points" -ForegroundColor White
    Write-Host "- No Sensitivity Label: +$($DefaultScoring.NoSensitivityLabel) points" -ForegroundColor White
    
    do {
        $response = Read-Host "`nWould you like to customize these scoring weights? (y/N)"
        $response = $response.Trim().ToLower()
        if ($response -eq '' -or $response -eq 'n' -or $response -eq 'no') {
            return $false
        } elseif ($response -eq 'y' -or $response -eq 'yes') {
            return $true
        } else {
            Write-Host "Please enter 'y' for yes or 'n' for no (or press Enter for default)." -ForegroundColor Red
        }
    } while ($true)
}

function Get-CustomScoring {
    <#
    .SYNOPSIS
    Prompts user for custom scoring configuration
    #>
    
    Write-Host "`n=== Custom Scoring Configuration ===" -ForegroundColor Cyan
    Write-Host "Enter custom scores for each risk factor (press Enter to keep default):" -ForegroundColor Yellow
    
    $customScoring = $DefaultScoring.Clone()
    
    $prompt = "High EEEU Permissions (default: $($DefaultScoring.HighEEEUPermissions)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.HighEEEUPermissions = [int]$userInput }
    
    $prompt = "Private Site with EEEU (default: $($DefaultScoring.PrivateSiteWithEEEU)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.PrivateSiteWithEEEU = [int]$userInput }
    
    $prompt = "Public Site with Sensitive Title (default: $($DefaultScoring.PublicSiteWithSensitiveTitle)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.PublicSiteWithSensitiveTitle = [int]$userInput }
    
    $prompt = "Everyone Permissions Present (default: $($DefaultScoring.EveryonePermissions)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.EveryonePermissions = [int]$userInput }
    
    $prompt = "Anyone Links Present (default: $($DefaultScoring.AnyoneLinks)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.AnyoneLinks = [int]$userInput }
    
    $prompt = "High Unique Permissions (default: $($DefaultScoring.HighUniquePermissions)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.HighUniquePermissions = [int]$userInput }
    
    $prompt = "No Sensitivity Label (default: $($DefaultScoring.NoSensitivityLabel)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.NoSensitivityLabel = [int]$userInput }
    
    $prompt = "EEEU Permission Threshold (default: $($DefaultScoring.EEEUPermissionThreshold)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.EEEUPermissionThreshold = [int]$userInput }
    
    $prompt = "Unique Permission Threshold (default: $($DefaultScoring.UniquePermissionThreshold)): "
    $userInput = Read-Host $prompt
    if ($userInput -and $userInput -match '^\d+$') { $customScoring.UniquePermissionThreshold = [int]$userInput }
    
    Write-Host "`nCustom scoring configuration applied!" -ForegroundColor Green
    return $customScoring
}

function Calculate-RiskScore {
    <#
    .SYNOPSIS
    Calculates risk score for a SharePoint site based on refined risk criteria
    #>
    param(
        [PSCustomObject]$Site,
        [hashtable]$ScoringConfig,
        [hashtable]$ColumnMap
    )
    
    $score = 0
    $reasons = @()
    
    # Define sensitive keywords for site titles/names
    $sensitiveKeywords = @(
        'HR', 'Human Resources', 'Payroll', 'Salary', 'Tax', 'Finance', 'Financial',
        'Legal', 'Confidential', 'Private', 'Executive', 'Board', 'Research',
        'Development', 'Strategy', 'Merger', 'Acquisition', 'Patent', 'Secret',
        'Personal', 'Employee', 'Medical', 'Health', 'Compliance', 'Audit',
        'Security', 'Admin', 'Internal', 'Restricted'
    )
    
    $siteName = Get-SafePropertyValue -Object $Site -StandardName 'Site name' -ColumnMap $ColumnMap
    $siteUrl = Get-SafePropertyValue -Object $Site -StandardName 'Site URL' -ColumnMap $ColumnMap
    $sitePrivacy = Get-SafePropertyValue -Object $Site -StandardName 'Site privacy' -ColumnMap $ColumnMap
    $eeeuCountRaw = Get-SafePropertyValue -Object $Site -StandardName 'EEEU permission count' -ColumnMap $ColumnMap
    $everyoneCountRaw = Get-SafePropertyValue -Object $Site -StandardName 'Everyone permission count' -ColumnMap $ColumnMap
    $anyoneLinksRaw = Get-SafePropertyValue -Object $Site -StandardName 'Anyone link count' -ColumnMap $ColumnMap
    $totalUsersRaw = Get-SafePropertyValue -Object $Site -StandardName 'Number of users having access' -ColumnMap $ColumnMap
    $siteSensitivity = Get-SafePropertyValue -Object $Site -StandardName 'Site sensitivity' -ColumnMap $ColumnMap
    
    # Convert to integers, handling null/empty values
    $eeeuCount = if ($eeeuCountRaw) { [int]($eeeuCountRaw -replace '[^\d]', '') } else { 0 }
    $everyoneCount = if ($everyoneCountRaw) { [int]($everyoneCountRaw -replace '[^\d]', '') } else { 0 }
    $anyoneLinks = if ($anyoneLinksRaw) { [int]($anyoneLinksRaw -replace '[^\d]', '') } else { 0 }
    $totalUsers = if ($totalUsersRaw) { [int]($totalUsersRaw -replace '[^\d]', '') } else { 0 }
    
    # Get unique permissions count if available (this might need to be added to CSV export)
    # For now, we'll use the total user count as a proxy for unique permissions complexity
    
    # 1. High EEEU Permissions - Sites with many EEEU permissions are risky
    if ($eeeuCount -ge $ScoringConfig.EEEUPermissionThreshold) {
        $score += $ScoringConfig.HighEEEUPermissions
        $reasons += "High EEEU permissions ($eeeuCount) (+$($ScoringConfig.HighEEEUPermissions))"
    }
    
    # 2. Private Sites with EEEU and/or External Sharing - Private sites shouldn't have broad access
    if ($sitePrivacy -eq 'Private' -and ($eeeuCount -gt 0 -or $anyoneLinks -gt 0)) {
        $score += $ScoringConfig.PrivateSiteWithEEEU
        $riskFactors = @()
        if ($eeeuCount -gt 0) { $riskFactors += "EEEU permissions ($eeeuCount)" }
        if ($anyoneLinks -gt 0) { $riskFactors += "external sharing ($anyoneLinks anyone links)" }
        $reasons += "Private site with broad access: $($riskFactors -join ', ') (+$($ScoringConfig.PrivateSiteWithEEEU))"
    }
    
    # 3. Public Sites with Sensitive Titles - Public sites with sensitive content
    if ($sitePrivacy -eq 'Public') {
        $hasSensitiveTitle = $false
        foreach ($keyword in $sensitiveKeywords) {
            if (($siteName -and $siteName -match $keyword) -or ($siteUrl -and $siteUrl -match $keyword)) {
                $hasSensitiveTitle = $true
                break
            }
        }
        if ($hasSensitiveTitle) {
            $score += $ScoringConfig.PublicSiteWithSensitiveTitle
            $reasons += "Public site with sensitive title/URL (+$($ScoringConfig.PublicSiteWithSensitiveTitle))"
        }
    }
    
    # 4. Everyone Permissions - Still risky regardless of site type
    if ($everyoneCount -gt 0) {
        $score += $ScoringConfig.EveryonePermissions
        $reasons += "Everyone permissions ($everyoneCount) (+$($ScoringConfig.EveryonePermissions))"
    }
    
    # 5. Anyone Links - External sharing risk
    if ($anyoneLinks -gt 0) {
        $score += $ScoringConfig.AnyoneLinks
        $reasons += "Anyone links ($anyoneLinks) (+$($ScoringConfig.AnyoneLinks))"
    }
    
    # 6. Sites with Many Unique Permissions and Broad Access
    # High user count + EEEU permissions suggests complex permission structure with broad access
    if ($totalUsers -ge $ScoringConfig.UniquePermissionThreshold -and $eeeuCount -gt 0) {
        $score += $ScoringConfig.HighUniquePermissions
        $reasons += "High user count ($totalUsers) with EEEU permissions (+$($ScoringConfig.HighUniquePermissions))"
    }
    
    # 7. No Sensitivity Label - Reduced weight as it's more of a compliance issue
    if ([string]::IsNullOrWhiteSpace($siteSensitivity)) {
        $score += $ScoringConfig.NoSensitivityLabel
        $reasons += "No sensitivity label (+$($ScoringConfig.NoSensitivityLabel))"
    }
    
    return @{
        Score = $score
        Reasons = $reasons -join '; '
    }
}

function Get-RiskCategory {
    <#
    .SYNOPSIS
    Determines risk category based on score
    #>
    param([int]$Score)
    
    foreach ($level in $RiskLevels.GetEnumerator()) {
        if ($Score -ge $level.Value.Min -and $Score -le $level.Value.Max) {
            return @{
                Category = $level.Key
                Label = $level.Value.Label
                Color = $level.Value.Color
            }
        }
    }
    
    # Default to Critical if score is very high
    return @{
        Category = "Critical"
        Label = "Critical Risk"
        Color = "#dc3545"
    }
}

function Generate-HtmlReport {
    <#
    .SYNOPSIS
    Generates HTML report with risk analysis
    #>
    param(
        [array]$AnalyzedSites,
        [hashtable]$ScoringConfig,
        [hashtable]$Statistics,
        [string]$OutputPath,
        [hashtable]$ColumnMap
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SharePoint Risk Analysis Report</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f8f9fa; 
        }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 10px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.1); 
            padding: 30px; 
        }
        h1 { 
            color: #343a40; 
            text-align: center; 
            margin-bottom: 30px; 
            border-bottom: 3px solid #007bff; 
            padding-bottom: 15px; 
        }
        .summary { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin-bottom: 30px; 
        }
        .summary-card { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 20px; 
            border-radius: 10px; 
            text-align: center; 
            box-shadow: 0 4px 8px rgba(0,0,0,0.1); 
        }
        .summary-card.high-risk { 
            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); 
        }
        .summary-card.public-sites { 
            background: linear-gradient(135deg, #fd7e14 0%, #e8690b 100%); 
        }
        .summary-card.anyone-links { 
            background: linear-gradient(135deg, #ffc107 0%, #e0a800 100%); 
            color: #212529; 
        }
        .summary-card.total-sites { 
            background: linear-gradient(135deg, #28a745 0%, #1e7e34 100%); 
        }
        .summary-card h3 { 
            margin: 0 0 10px 0; 
            font-size: 2em; 
        }
        .risk-distribution {
            background-color: #f8f9fa;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            border: 1px solid #e9ecef;
        }
        .risk-distribution h2 {
            color: #495057;
            margin-top: 0;
            margin-bottom: 20px;
            text-align: center;
        }
        .chart-container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            align-items: center;
        }
        .chart-wrapper {
            position: relative;
            height: 300px;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .risk-stats {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        .risk-stat-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #007bff;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .risk-stat-label {
            font-weight: 600;
            color: #495057;
        }
        .risk-stat-value {
            font-size: 1.5em;
            font-weight: bold;
            color: #007bff;
        }
        @media (max-width: 968px) {
            .chart-container {
                grid-template-columns: 1fr;
                gap: 20px;
            }
        }
        .summary-card p { 
            margin: 0; 
            opacity: 0.9; 
        }
        .scoring-info { 
            background-color: #e9ecef; 
            padding: 20px; 
            border-radius: 10px; 
            margin-bottom: 30px; 
        }
        .scoring-info h2 { 
            color: #495057; 
            margin-top: 0; 
        }
        .controls { 
            margin-bottom: 20px; 
            display: flex; 
            gap: 15px; 
            align-items: center; 
            flex-wrap: wrap; 
        }
        .controls input, .controls select { 
            padding: 8px 12px; 
            border: 1px solid #ddd; 
            border-radius: 5px; 
            font-size: 14px; 
        }
        .controls button { 
            background-color: #007bff; 
            color: white; 
            border: none; 
            padding: 10px 20px; 
            border-radius: 5px; 
            cursor: pointer; 
            font-size: 14px; 
        }
        .controls button:hover { 
            background-color: #0056b3; 
        }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin-top: 20px; 
            font-size: 14px; 
        }
        th, td { 
            padding: 12px; 
            text-align: left; 
            border-bottom: 1px solid #ddd; 
        }
        th { 
            background-color: #343a40; 
            color: white; 
            cursor: pointer; 
            user-select: none; 
            position: sticky; 
            top: 0; 
            z-index: 100; 
        }
        th:hover { 
            background-color: #495057; 
        }
        th.sort-asc::after {
            content: ' ^';
            font-weight: bold;
        }
        th.sort-desc::after {
            content: ' v';
            font-weight: bold;
        }
        tr:nth-child(even) { 
            background-color: #f8f9fa; 
        }
        tr:hover { 
            background-color: #e3f2fd; 
        }
        .risk-badge { 
            padding: 4px 12px; 
            border-radius: 20px; 
            color: white; 
            font-weight: bold; 
            font-size: 12px; 
            text-align: center; 
            display: inline-block; 
            min-width: 80px; 
        }
        .risk-reasons { 
            font-size: 12px; 
            color: #666; 
            max-width: 300px; 
            word-wrap: break-word; 
        }
        .site-url { 
            color: #007bff; 
            text-decoration: none; 
            max-width: 250px; 
            word-wrap: break-word; 
            display: block; 
        }
        .site-url:hover { 
            text-decoration: underline; 
        }
        .legend { 
            display: flex; 
            gap: 15px; 
            margin-bottom: 20px; 
            flex-wrap: wrap; 
        }
        .legend-item { 
            display: flex; 
            align-items: center; 
            gap: 5px; 
        }
        .legend-color { 
            width: 20px; 
            height: 20px; 
            border-radius: 10px; 
        }
        .guidance-link {
            background-color: #f8f9fa;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            border: 1px solid #e9ecef;
            text-align: center;
        }
        .guidance-link h2 {
            color: #495057;
            margin-top: 0;
            margin-bottom: 15px;
        }
        .guidance-link p {
            color: #6c757d;
            margin-bottom: 25px;
        }
        .guidance-button {
            display: inline-flex;
            align-items: center;
            background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
            color: white;
            padding: 20px 30px;
            border-radius: 10px;
            text-decoration: none;
            box-shadow: 0 4px 8px rgba(0,123,255,0.3);
            transition: all 0.3s ease;
            max-width: 500px;
        }
        .guidance-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,123,255,0.4);
            text-decoration: none;
            color: white;
        }
        .guidance-icon {
            font-size: 2em;
            margin-right: 20px;
        }
        .guidance-text {
            flex-grow: 1;
            text-align: left;
        }
        .guidance-text h3 {
            margin: 0 0 5px 0;
            font-size: 18px;
        }
        .guidance-text p {
            margin: 0;
            color: #ffffff;
            font-size: 14px;
            font-weight: 500;
        }
        .guidance-arrow {
            font-size: 1.5em;
            margin-left: 20px;
        }
        @media (max-width: 768px) {
            .guidance-button {
                flex-direction: column;
                text-align: center;
                padding: 20px;
            }
            .guidance-icon, .guidance-arrow {
                margin: 0;
            }
            .guidance-text {
                margin: 10px 0;
                text-align: center;
            }
        }
        @media (max-width: 768px) {
            .container { 
                padding: 15px; 
            }
            .controls { 
                flex-direction: column; 
                align-items: stretch; 
            }
            table { 
                font-size: 12px; 
            }
            th, td { 
                padding: 8px; 
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>SharePoint Risk Analysis Report</h1>
        
        <div class="summary">
            <div class="summary-card total-sites">
                <h3>$($Statistics.TotalSites)</h3>
                <p>Total Sites Analyzed</p>
            </div>
            <div class="summary-card high-risk">
                <h3>$($Statistics.HighRiskSites)</h3>
                <p>High Risk Sites (7+ Score)</p>
            </div>
            <div class="summary-card public-sites">
                <h3>$($Statistics.PrivateSitesWithBroadAccess)</h3>
                <p>Private Sites with Broad Access</p>
            </div>
            <div class="summary-card anyone-links">
                <h3>$($Statistics.SitesWithAnyoneLinks)</h3>
                <p>Sites with Anyone Links</p>
            </div>
        </div>
        
        <div class="risk-distribution">
            <h2>Risk Distribution Analysis</h2>
            <div class="chart-container">
                <div class="chart-wrapper">
                    <canvas id="riskChart"></canvas>
                </div>
                <div class="risk-stats">
                    <div class="risk-stat-item">
                        <span class="risk-stat-label">Average Risk Score:</span>
                        <span class="risk-stat-value" id="avgRiskScore">0</span>
                    </div>
                    <div class="risk-stat-item">
                        <span class="risk-stat-label">Critical + High Risk:</span>
                        <span class="risk-stat-value" id="criticalHighRisk">0</span>
                    </div>
                    <div class="risk-stat-item">
                        <span class="risk-stat-label">Highest Risk Score:</span>
                        <span class="risk-stat-value" id="highestRiskScore">0</span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="scoring-info">
            <h2>Scoring Methodology</h2>
            <p><strong>Risk factors and their weights (focused on actual SharePoint security risks):</strong></p>
            <ul>
                <li>High EEEU Permissions ($($ScoringConfig.EEEUPermissionThreshold)+): +$($ScoringConfig.HighEEEUPermissions) points</li>
                <li>Private Site with EEEU/External Sharing: +$($ScoringConfig.PrivateSiteWithEEEU) points</li>
                <li>Public Site with Sensitive Title: +$($ScoringConfig.PublicSiteWithSensitiveTitle) points</li>
                <li>Everyone Permissions Present: +$($ScoringConfig.EveryonePermissions) points</li>
                <li>Anyone Links Present: +$($ScoringConfig.AnyoneLinks) points</li>
                <li>High User Count ($($ScoringConfig.UniquePermissionThreshold)+) with EEEU: +$($ScoringConfig.HighUniquePermissions) points</li>
                <li>No Sensitivity Label: +$($ScoringConfig.NoSensitivityLabel) points</li>
            </ul>
            <p><strong>Note:</strong> Public sites are internal-only by default and not inherently risky. Focus is on inappropriate broad access patterns and sensitive content exposure.</p>
        </div>
        
        <div class="guidance-link">
            <h2>What to Do Next?</h2>
            <p>Now that you've identified SharePoint security risks, it's time to take action.</p>
            <a href="#" onclick="openGuidance()" class="guidance-button">
                <span class="guidance-icon">&#128203;</span>
                <div class="guidance-text">
                    <h3>View Complete Action Plan</h3>
                    <p>Get step-by-step guidance for addressing these risks</p>
                </div>
                <span class="guidance-arrow">&rarr;</span>
            </a>
        </div>
        
        <div class="legend">
            <div class="legend-item">
                <div class="legend-color" style="background-color: #dc3545;"></div>
                <span>Critical Risk (10+)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #fd7e14;"></div>
                <span>High Risk (7-9)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #ffc107;"></div>
                <span>Medium Risk (4-6)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #17a2b8;"></div>
                <span>Low Risk (1-3)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #28a745;"></div>
                <span>No Risk (0)</span>
            </div>
        </div>
        
        <div class="controls">
            <input type="text" id="searchBox" placeholder="Search sites..." />
            <select id="riskFilter" onchange="filterByRisk(this.value)">
                <option value="">All Risk Levels</option>
                <option value="Critical">Critical Risk</option>
                <option value="High">High Risk</option>
                <option value="Medium">Medium Risk</option>
                <option value="Low">Low Risk</option>
                <option value="NoRisk">No Risk</option>
            </select>
            <button onclick="exportToJSON()">Export to JSON</button>
            <button onclick="exportToCSV()">Export to CSV</button>
        </div>
        
        <table id="riskTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0)" id="riskScoreHeader">Risk Score</th>
                    <th onclick="sortTable(1)">Risk Level</th>
                    <th onclick="sortTable(2)">Site Name</th>
                    <th onclick="sortTable(3)">Site URL</th>
                    <th onclick="sortTable(4)">Privacy</th>
                    <th onclick="sortTable(5)">Users</th>
                    <th onclick="sortTable(6)">Anyone Links</th>
                    <th onclick="sortTable(7)">EEEU Perms</th>
                    <th onclick="sortTable(8)">Everyone Perms</th>
                    <th onclick="sortTable(9)">Risk Factors</th>
                </tr>
            </thead>
            <tbody>
"@
    
    foreach ($site in $AnalyzedSites) {
        $riskInfo = Get-RiskCategory -Score $site.RiskScore
        
        # Get values using safe property access
        $sitePrivacy = Get-SafePropertyValue -Object $site -StandardName 'Site privacy' -ColumnMap $ColumnMap
        $siteName = Get-SafePropertyValue -Object $site -StandardName 'Site name' -ColumnMap $ColumnMap
        $siteUrl = Get-SafePropertyValue -Object $site -StandardName 'Site URL' -ColumnMap $ColumnMap
        $userCount = Get-SafePropertyValue -Object $site -StandardName 'Number of users having access' -ColumnMap $ColumnMap
        $anyoneLinks = Get-SafePropertyValue -Object $site -StandardName 'Anyone link count' -ColumnMap $ColumnMap
        $eeeuCount = Get-SafePropertyValue -Object $site -StandardName 'EEEU permission count' -ColumnMap $ColumnMap
        $everyoneCount = Get-SafePropertyValue -Object $site -StandardName 'Everyone permission count' -ColumnMap $ColumnMap
        
        # Handle null/empty values
        $privacy = if ([string]::IsNullOrWhiteSpace($sitePrivacy)) { "Not Set" } else { $sitePrivacy }
        $displayName = if ([string]::IsNullOrWhiteSpace($siteName)) { "Unnamed Site" } else { $siteName }
        $displayUrl = if ([string]::IsNullOrWhiteSpace($siteUrl)) { "No URL" } else { $siteUrl }
        
        $html += @"
                <tr data-risk="$($riskInfo.Category)">
                    <td style="font-weight: bold; font-size: 16px;">$($site.RiskScore)</td>
                    <td><span class="risk-badge" style="background-color: $($riskInfo.Color);">$($riskInfo.Label)</span></td>
                    <td>$(ConvertTo-HtmlSafe $displayName)</td>
                    <td><a href="$displayUrl" target="_blank" class="site-url">$(ConvertTo-HtmlSafe $displayUrl)</a></td>
                    <td>$privacy</td>
                    <td>$($userCount -replace '[^\d]', '')</td>
                    <td>$($anyoneLinks -replace '[^\d]', '')</td>
                    <td>$($eeeuCount -replace '[^\d]', '')</td>
                    <td>$($everyoneCount -replace '[^\d]', '')</td>
                    <td class="risk-reasons">$(ConvertTo-HtmlSafe $site.RiskReasons)</td>
                </tr>
"@
    }
    
    $html += @"
            </tbody>
        </table>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        let originalData = [];
        let riskChart = null;
        
        // Store original table data and initialize chart
        document.addEventListener('DOMContentLoaded', function() {
            const table = document.getElementById('riskTable');
            const tbody = table.querySelector('tbody');
            originalData = Array.from(tbody.querySelectorAll('tr')).map(row => ({
                element: row.cloneNode(true),
                text: row.textContent.toLowerCase()
            }));
            
            // Set up search functionality
            document.getElementById('searchBox').addEventListener('input', filterTable);
            document.getElementById('riskFilter').addEventListener('change', filterTable);
            
            // Initialize risk distribution chart
            initializeRiskChart();
        });
        
        function initializeRiskChart() {
            const table = document.getElementById('riskTable');
            const rows = table.querySelectorAll('tbody tr');
            
            // Count risk levels
            let riskCounts = {
                'Critical': 0,
                'High': 0, 
                'Medium': 0,
                'Low': 0,
                'No Risk': 0
            };
            
            let totalScore = 0;
            let maxScore = 0;
            
            rows.forEach(row => {
                const riskScore = parseInt(row.cells[0].textContent.trim());
                const riskCategory = row.getAttribute('data-risk');
                
                totalScore += riskScore;
                maxScore = Math.max(maxScore, riskScore);
                
                // Map data-risk attributes to display names
                if (riskCategory === 'Critical') riskCounts.Critical++;
                else if (riskCategory === 'High') riskCounts.High++;
                else if (riskCategory === 'Medium') riskCounts.Medium++;
                else if (riskCategory === 'Low') riskCounts.Low++;
                else riskCounts['No Risk']++;
            });
            
            const avgScore = rows.length > 0 ? (totalScore / rows.length).toFixed(1) : 0;
            const criticalHighCount = riskCounts.Critical + riskCounts.High;
            
            // Update statistics
            document.getElementById('avgRiskScore').textContent = avgScore;
            document.getElementById('criticalHighRisk').textContent = criticalHighCount.toLocaleString();
            document.getElementById('highestRiskScore').textContent = maxScore;
            
            // Create chart
            const ctx = document.getElementById('riskChart').getContext('2d');
            
            riskChart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Critical Risk', 'High Risk', 'Medium Risk', 'Low Risk', 'No Risk'],
                    datasets: [{
                        data: [riskCounts.Critical, riskCounts.High, riskCounts.Medium, riskCounts.Low, riskCounts['No Risk']],
                        backgroundColor: ['#dc3545', '#fd7e14', '#ffc107', '#17a2b8', '#28a745'],
                        borderColor: ['#c82333', '#e8690b', '#e0a800', '#117a8b', '#1e7e34'],
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                padding: 20,
                                usePointStyle: true
                            }
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                    const percentage = ((context.raw / total) * 100).toFixed(1);
                                    return context.label + ': ' + context.raw.toLocaleString() + ' (' + percentage + '%)';
                                }
                            }
                        }
                    }
                }
            });
        }
        
        function sortTable(columnIndex) {
            const table = document.getElementById('riskTable');
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            
            // Get the header element
            const header = table.querySelectorAll('th')[columnIndex];
            
            // Determine current sort state based on CSS classes
            const isCurrentlyDescending = header.classList.contains('sort-desc');
            const isCurrentlyAscending = header.classList.contains('sort-asc');
            
            // Determine new sort direction
            let newDescending;
            if (isCurrentlyDescending) {
                newDescending = false; // Switch to ascending
            } else if (isCurrentlyAscending) {
                newDescending = true; // Switch to descending
            } else {
                // No current sort indicator - use default for column
                newDescending = (columnIndex === 0) ? true : false; // Risk score defaults to descending, others to ascending
            }
            
            // Reset all headers - remove sort classes
            table.querySelectorAll('th').forEach(th => {
                th.classList.remove('sort-asc', 'sort-desc');
            });
            
            // Sort rows
            rows.sort((a, b) => {
                let aVal = a.cells[columnIndex].textContent.trim();
                let bVal = b.cells[columnIndex].textContent.trim();
                
                // Handle numeric columns
                if (columnIndex === 0 || columnIndex === 5 || columnIndex === 6 || columnIndex === 7 || columnIndex === 8) {
                    aVal = parseFloat(aVal) || 0;
                    bVal = parseFloat(bVal) || 0;
                }
                
                if (aVal < bVal) return newDescending ? 1 : -1;
                if (aVal > bVal) return newDescending ? -1 : 1;
                return 0;
            });
            
            // Update header with sort indicator using CSS class
            header.classList.add(newDescending ? 'sort-desc' : 'sort-asc');
            
            // Re-append sorted rows
            rows.forEach(row => tbody.appendChild(row));
        }
        
        function filterTable() {
            const searchTerm = document.getElementById('searchBox').value.toLowerCase();
            const riskFilter = document.getElementById('riskFilter').value;
            const tbody = document.querySelector('#riskTable tbody');
            
            // Clear current rows
            tbody.innerHTML = '';
            
            // Filter and display matching rows
            originalData.forEach(item => {
                const matchesSearch = !searchTerm || item.text.includes(searchTerm);
                const matchesRisk = !riskFilter || item.element.getAttribute('data-risk') === riskFilter;
                
                if (matchesSearch && matchesRisk) {
                    tbody.appendChild(item.element.cloneNode(true));
                }
            });
        }
        
        function exportToJSON() {
            const table = document.getElementById('riskTable');
            const rows = table.querySelectorAll('tbody tr');
            const headers = Array.from(table.querySelectorAll('th')).map(th => 
                th.textContent.replace(/[\u25B2\u25BC]/, '').trim()
            );
            
            const data = Array.from(rows).map(row => {
                const cells = row.querySelectorAll('td');
                const obj = {};
                headers.forEach((header, index) => {
                    obj[header] = cells[index] ? cells[index].textContent.trim() : '';
                });
                return obj;
            });
            
            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'sharepoint-risk-analysis.json';
            a.click();
            window.URL.revokeObjectURL(url);
        }
        
        function exportToCSV() {
            const table = document.getElementById('riskTable');
            const rows = table.querySelectorAll('tbody tr');
            const headers = Array.from(table.querySelectorAll('th')).map(th => 
                th.textContent.replace(/[\u2191\u2193\u25B2\u25BC]/g, '').trim()
            );
            
            // Create CSV content
            let csvContent = headers.join(',') + '\n';
            
            Array.from(rows).forEach(row => {
                const cells = row.querySelectorAll('td');
                const rowData = Array.from(cells).map(cell => {
                    let text = cell.textContent.trim();
                    // Escape quotes and wrap in quotes if contains comma
                    if (text.includes(',') || text.includes('"') || text.includes('\n')) {
                        text = '"' + text.replace(/"/g, '""') + '"';
                    }
                    return text;
                });
                csvContent += rowData.join(',') + '\n';
            });
            
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'sharepoint-risk-analysis.csv';
            a.click();
            window.URL.revokeObjectURL(url);
        }
        
        function openGuidance() {
            const guidanceUrl = window.location.href.replace('.html', '_guidance.html');
            window.open(guidanceUrl, '_blank');
        }
        
        // Initial sort indicator (data is already sorted by PowerShell)
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(() => {
                // Set initial sort indicator for Risk Score column
                const riskScoreHeader = document.getElementById('riskScoreHeader');
                if (riskScoreHeader) {
                    riskScoreHeader.classList.add('sort-desc'); // Down arrow to show it's sorted descending
                }
            }, 100);
        });
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}

function Test-CsvColumns {
    <#
    .SYNOPSIS
    Validates CSV columns and provides mapping for different formats
    #>
    param(
        [array]$CsvData
    )
    
    if ($CsvData.Count -eq 0) {
        throw "CSV file is empty or could not be read"
    }
    
    $firstRow = $CsvData[0]
    $actualColumns = $firstRow.PSObject.Properties.Name
    
    Write-Host "`nDetected CSV columns:" -ForegroundColor Cyan
    $actualColumns | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    
    # Define required columns and their possible variations
    $columnMappings = @{
        'Site URL' = @('Site URL', 'SiteUrl', 'Site Url', 'URL', 'Url')
        'Site name' = @('Site name', 'Site Name', 'SiteName', 'Name', 'Title')
        'Site privacy' = @('Site privacy', 'Site Privacy', 'Privacy', 'Site Type')
        'Number of users having access' = @('Number of users having access', 'Users with access', 'User Count', 'Users', 'Total Users')
        'EEEU permission count' = @('EEEU permission count', 'EEEU permissions', 'EEEU', 'Everyone Except External Users')
        'Everyone permission count' = @('Everyone permission count', 'Everyone permissions', 'Everyone')
        'Anyone link count' = @('Anyone link count', 'Anyone links', 'Anonymous links', 'External links')
        'Site sensitivity' = @('Site sensitivity', 'Sensitivity label', 'Sensitivity Label', 'Label')
    }
    
    $mappedColumns = @{}
    $missingColumns = @()
    
    foreach ($requiredColumn in $columnMappings.Keys) {
        $found = $false
        foreach ($variation in $columnMappings[$requiredColumn]) {
            if ($actualColumns -contains $variation) {
                $mappedColumns[$requiredColumn] = $variation
                $found = $true
                break
            }
        }
        if (-not $found) {
            $missingColumns += $requiredColumn
        }
    }
    
    if ($missingColumns.Count -gt 0) {
        Write-Host "`nMissing required columns:" -ForegroundColor Red
        $missingColumns | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host "`nThis may not be a SharePoint Advanced Management Site Permissions Report." -ForegroundColor Yellow
        Write-Host "Expected columns: Site URL, Site name, Site privacy, Number of users having access," -ForegroundColor Yellow
        Write-Host "EEEU permission count, Everyone permission count, Anyone link count, Site sensitivity" -ForegroundColor Yellow
        throw "Required columns missing from CSV file"
    }
    
    Write-Host "`nColumn mapping successful:" -ForegroundColor Green
    foreach ($mapping in $mappedColumns.GetEnumerator()) {
        if ($mapping.Key -ne $mapping.Value) {
            Write-Host "  $($mapping.Key) -> $($mapping.Value)" -ForegroundColor Green
        }
    }
    
    return $mappedColumns
}

function Get-SafePropertyValue {
    <#
    .SYNOPSIS
    Safely gets a property value with fallback to mapped column name
    #>
    param(
        [PSCustomObject]$Object,
        [string]$StandardName,
        [hashtable]$ColumnMap
    )
    
    $actualColumnName = if ($ColumnMap.ContainsKey($StandardName)) { $ColumnMap[$StandardName] } else { $StandardName }
    
    if ($Object.PSObject.Properties[$actualColumnName]) {
        return $Object.$actualColumnName
    } else {
        return $null
    }
}

function Generate-GuidancePage {
    <#
    .SYNOPSIS
    Generates a separate HTML guidance page with next steps
    #>
    param(
        [string]$OutputPath
    )
    
    $guidancePath = $OutputPath -replace '\.html$', '_guidance.html'
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SharePoint Governance Action Plan</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f8f9fa; 
            line-height: 1.6;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 10px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.1); 
            padding: 30px; 
        }
        h1 { 
            color: #343a40; 
            text-align: center; 
            margin-bottom: 30px; 
            border-bottom: 3px solid #007bff; 
            padding-bottom: 15px; 
        }
        .back-link {
            background: #007bff;
            color: white;
            padding: 10px 20px;
            border-radius: 5px;
            text-decoration: none;
            display: inline-block;
            margin-bottom: 30px;
        }
        .back-link:before {
            content: "\2190";
            margin-right: 8px;
        }
        .back-link:hover {
            background: #0056b3;
            text-decoration: none;
            color: white;
        }
        .intro {
            background: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            border-left: 4px solid #2196f3;
        }
        .step-section {
            margin-bottom: 40px;
            padding: 25px;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 4px solid #007bff;
        }
        .step-section.advanced {
            border-left-color: #28a745;
            background: linear-gradient(135deg, #f8fff9 0%, #e8f5e8 100%);
        }
        .step-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }
        .step-number {
            background: #007bff;
            color: white;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 18px;
            margin-right: 15px;
        }
        .step-section.advanced .step-number {
            background: #28a745;
        }
        .step-title {
            color: #343a40;
            margin: 0;
            font-size: 24px;
        }
        .step-content ul {
            list-style-type: none;
            padding-left: 0;
        }
        .step-content li {
            margin-bottom: 15px;
            padding-left: 30px;
            position: relative;
        }
        .step-content li:before {
            content: "\2713";
            position: absolute;
            left: 0;
            color: #28a745;
            font-weight: bold;
            font-size: 16px;
        }
        .step-content strong {
            color: #495057;
        }
        .tips-section {
            background: #fff3cd;
            padding: 20px;
            border-radius: 8px;
            margin: 30px 0;
            border-left: 4px solid #ffc107;
        }
        .tips-section h3 {
            color: #856404;
            margin-top: 0;
        }
        .enterprise-note {
            background: #d1ecf1;
            padding: 20px;
            border-radius: 8px;
            margin-top: 30px;
            border-left: 4px solid #17a2b8;
            text-align: center;
        }
        @media (max-width: 768px) {
            .container { 
                padding: 15px; 
            }
            .step-title {
                font-size: 20px;
            }
            .step-number {
                width: 35px;
                height: 35px;
                font-size: 16px;
            }
        }
    </style>
    <script>
        function goBackToReport() {
            // Try to close the window first (if opened in new tab)
            if (window.opener) {
                window.close();
            } else {
                // If window doesn't close, navigate to main report
                const mainReportUrl = window.location.href.replace('_guidance.html', '.html');
                window.location.href = mainReportUrl;
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <a href="#" onclick="goBackToReport()" class="back-link">Back to Risk Analysis Report</a>
        
        <h1>SharePoint Governance Action Plan</h1>
        
        <div class="intro">
            <h3>From Analysis to Action</h3>
            <p>You've identified SharePoint security risks - now it's time to take systematic action. This guide provides a proven methodology for transforming your risk analysis into meaningful security improvements.</p>
            <p><strong>Start with Critical and High risk sites first, then work your way down the priority list.</strong></p>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">1</div>
                <h2 class="step-title">Analyze Key Risk Indicators</h2>
            </div>
            <div class="step-content">
                <p>Focus on the most critical data points in your risk analysis report:</p>
                <ul>
                    <li><strong>Site Privacy Patterns:</strong> Compare Public vs. Private site configurations</li>
                    <li><strong>External Sharing Status:</strong> Review sites with external sharing enabled</li>
                    <li><strong>EEEU & Everyone Permissions:</strong> Identify inappropriate broad access patterns</li>
                    <li><strong>Unique Permissions:</strong> Look for broken inheritance (permission sprawl)</li>
                    <li><strong>Sharing Links Audit:</strong> Review "Anyone" and "People in Org" link counts</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">2</div>
                <h2 class="step-title">Target High-Risk Sites</h2>
            </div>
            <div class="step-content">
                <p>Prioritize sites based on these critical patterns:</p>
                <ul>
                    <li><strong>EEEU/Everyone in Groups:</strong> Sites with broad permissions in Members/Visitors groups</li>
                    <li><strong>Permission Sprawl:</strong> High unique permissions count or excessive sharing links</li>
                    <li><strong>Classic Sites:</strong> STS#0 templates often accumulate stale permissions over time</li>
                    <li><strong>Sensitive Public Sites:</strong> Public sites containing HR, Finance, or Legal content</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">3</div>
                <h2 class="step-title">Engage Site Owners</h2>
            </div>
            <div class="step-content">
                <p>Delegate governance through owner empowerment:</p>
                <ul>
                    <li><strong>Site Access Reviews:</strong> Use SharePoint Advanced Management's built-in delegation features</li>
                    <li><strong>Targeted Owner Reports:</strong> Send specific site analysis to responsible owners</li>
                    <li><strong>Manual Outreach:</strong> Provide guidance and training for high-risk site owners</li>
                    <li><strong>Access Confirmation:</strong> Have owners review and remove unnecessary permissions</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">4</div>
                <h2 class="step-title">Apply Governance Controls</h2>
            </div>
            <div class="step-content">
                <p>Implement technical controls to reduce risk:</p>
                <ul>
                    <li><strong>Remove Broad Access:</strong> Eliminate EEEU/Everyone permissions where inappropriate</li>
                    <li><strong>External Sharing Audit:</strong> Disable external sharing for internal-only content</li>
                    <li><strong>Simplify Permissions:</strong> Reduce broken inheritance and complex permission structures</li>
                    <li><strong>Sensitivity Labels:</strong> Apply appropriate data classification labels</li>
                    <li><strong>Restricted Access Control (RAC):</strong> Immediate lockdown for critical sites</li>
                    <li><strong>Restricted Content Discovery (RCD):</strong> Hide sensitive sites from Copilot and org-wide search</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">5</div>
                <h2 class="step-title">Address Stale or Ownerless Sites</h2>
            </div>
            <div class="step-content">
                <p>Clean up abandoned content:</p>
                <ul>
                    <li><strong>Inactive Sites Policy:</strong> Archive or delete sites that haven't been accessed recently</li>
                    <li><strong>Site Ownership Policy:</strong> Assign new owners to "ownerless" sites</li>
                    <li><strong>Regular Cleanup:</strong> Establish recurring governance processes</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">6</div>
                <h2 class="step-title">Prevent Future Oversharing</h2>
            </div>
            <div class="step-content">
                <p>Implement proactive controls:</p>
                <ul>
                    <li><strong>Default Link Settings:</strong> Change default sharing to "Specific People" only</li>
                    <li><strong>Global EEEU Policy:</strong> Consider disabling organization-wide EEEU if suitable</li>
                    <li><strong>User Education:</strong> Train users on proper SharePoint sharing practices</li>
                    <li><strong>Automated Governance:</strong> Schedule recurring Data Access Governance (DAG) reports and reviews</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section">
            <div class="step-header">
                <div class="step-number">7</div>
                <h2 class="step-title">Document & Communicate Changes</h2>
            </div>
            <div class="step-content">
                <p>Ensure stakeholder alignment:</p>
                <ul>
                    <li><strong>Stakeholder Updates:</strong> Inform users about governance changes and site lockdowns</li>
                    <li><strong>Access Instructions:</strong> Provide clear guidance for requesting access to restricted sites</li>
                    <li><strong>Change Documentation:</strong> Track all governance actions for compliance and audit purposes</li>
                </ul>
            </div>
        </div>
        
        <div class="step-section advanced">
            <div class="step-header">
                <div class="step-number">+</div>
                <h2 class="step-title">Advanced Actions (Optional)</h2>
            </div>
            <div class="step-content">
                <p>For organizations with advanced governance needs:</p>
                <ul>
                    <li><strong>PowerShell Automation:</strong> Schedule automated DAG reports and detailed CSV exports</li>
                    <li><strong>Block Download Policy:</strong> Prevent offline file copies for highly sensitive sites</li>
                    <li><strong>Conditional Access:</strong> Implement location or device-based access restrictions</li>
                    <li><strong>DLP Integration:</strong> Link governance policies with Data Loss Prevention controls</li>
                </ul>
            </div>
        </div>
        
        <div class="tips-section">
            <h3>Implementation Tips</h3>
            <ul>
                <li><strong>Start Small:</strong> Begin with Critical and High risk sites, then work down the priority list</li>
                <li><strong>Track Progress:</strong> Re-run this analysis monthly to measure security posture improvements</li>
                <li><strong>Collaborate:</strong> Work with site owners rather than imposing changes unilaterally</li>
                <li><strong>Measure Success:</strong> Use decreasing high-risk site counts as your primary success metric</li>
            </ul>
        </div>
        
        <div class="enterprise-note">
            <h3>Enterprise Integration</h3>
            <p><strong>This governance methodology integrates seamlessly with SharePoint Advanced Management, Microsoft Purview, and broader Microsoft 365 governance strategies.</strong></p>
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
            <a href="#" onclick="goBackToReport()" class="back-link">Return to Risk Analysis Report</a>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $guidancePath -Encoding UTF8
    return $guidancePath
}

# Helper function for HTML encoding
function ConvertTo-HtmlSafe {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    
    return $Text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&#39;'
}

# Main execution
try {
    Write-Host "SharePoint Risk Analysis Tool" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Validate input file
    if (-not (Test-Path $CsvPath)) {
        throw "CSV file not found: $CsvPath"
    }
    
    # Set output path if not specified
    if (-not $OutputPath) {
        $OutputPath = [System.IO.Path]::ChangeExtension($CsvPath, 'html')
    }
    
    # Get scoring configuration
    $useCustomScoring = Get-ScoringPreference
    $scoringConfig = if ($useCustomScoring) { Get-CustomScoring } else { $DefaultScoring }
    
    Write-Host "`nLoading CSV data..." -ForegroundColor Yellow
    $sites = Import-Csv -Path $CsvPath
    Write-Host "Loaded $($sites.Count) raw entries" -ForegroundColor Green
    
    # Validate and map CSV columns
    $columnMap = Test-CsvColumns -CsvData $sites
    
    Write-Host "`nDeduplicating and aggregating site data..." -ForegroundColor Yellow
    # Group by Site URL and aggregate data for each unique site
    $uniqueSites = $sites | Group-Object { Get-SafePropertyValue -Object $_ -StandardName 'Site URL' -ColumnMap $columnMap } | ForEach-Object {
        $siteGroup = $_.Group
        $firstEntry = $siteGroup[0]  # Use first entry as base
        
        # Create aggregated site object
        $aggregatedSite = $firstEntry.PSObject.Copy()
        
        # Aggregate numeric values (take maximum values to represent worst-case risk)
        $userAccessColumn = $columnMap['Number of users having access']
        $eeeuColumn = $columnMap['EEEU permission count']
        $everyoneColumn = $columnMap['Everyone permission count']
        $anyoneColumn = $columnMap['Anyone link count']
        
        try {
            $userCounts = $siteGroup | Where-Object { $_.$userAccessColumn -ne $null -and $_.$userAccessColumn -ne '' } | ForEach-Object { [int]($_.$userAccessColumn -replace '[^\d]', '') }
            if ($userCounts) {
                $aggregatedSite.$userAccessColumn = ($userCounts | Measure-Object -Maximum).Maximum
            } else {
                $aggregatedSite.$userAccessColumn = 0
            }
            
            $eeeuCounts = $siteGroup | Where-Object { $_.$eeeuColumn -ne $null -and $_.$eeeuColumn -ne '' } | ForEach-Object { [int]($_.$eeeuColumn -replace '[^\d]', '') }
            if ($eeeuCounts) {
                $aggregatedSite.$eeeuColumn = ($eeeuCounts | Measure-Object -Maximum).Maximum
            } else {
                $aggregatedSite.$eeeuColumn = 0
            }
            
            $everyoneCounts = $siteGroup | Where-Object { $_.$everyoneColumn -ne $null -and $_.$everyoneColumn -ne '' } | ForEach-Object { [int]($_.$everyoneColumn -replace '[^\d]', '') }
            if ($everyoneCounts) {
                $aggregatedSite.$everyoneColumn = ($everyoneCounts | Measure-Object -Maximum).Maximum
            } else {
                $aggregatedSite.$everyoneColumn = 0
            }
            
            $anyoneCounts = $siteGroup | Where-Object { $_.$anyoneColumn -ne $null -and $_.$anyoneColumn -ne '' } | ForEach-Object { [int]($_.$anyoneColumn -replace '[^\d]', '') }
            if ($anyoneCounts) {
                $aggregatedSite.$anyoneColumn = ($anyoneCounts | Measure-Object -Maximum).Maximum
            } else {
                $aggregatedSite.$anyoneColumn = 0
            }
        } catch {
            Write-Warning "Error aggregating data for site group: $($_.Exception.Message)"
            # Use first entry values as fallback
        }
        
        return $aggregatedSite
    }
    
    Write-Host "Deduplicated to $($uniqueSites.Count) unique sites" -ForegroundColor Green
    
    Write-Host "`nAnalyzing risk scores..." -ForegroundColor Yellow
    $analyzedSites = @()
    
    foreach ($site in $uniqueSites) {
        $riskResult = Calculate-RiskScore -Site $site -ScoringConfig $scoringConfig -ColumnMap $columnMap
        $analyzedSite = $site | Select-Object *, @{n='RiskScore';e={$riskResult.Score}}, @{n='RiskReasons';e={$riskResult.Reasons}}
        $analyzedSites += $analyzedSite
    }
    
    # Sort by risk score (highest first)
    $analyzedSites = $analyzedSites | Sort-Object RiskScore -Descending
    
    # Calculate statistics
    $statistics = @{
        TotalSites = $analyzedSites.Count
        HighRiskSites = ($analyzedSites | Where-Object { $_.RiskScore -ge 7 }).Count
        PrivateSitesWithBroadAccess = ($analyzedSites | Where-Object { 
            $sitePrivacy = Get-SafePropertyValue -Object $_ -StandardName 'Site privacy' -ColumnMap $columnMap
            $eeeuCount = Get-SafePropertyValue -Object $_ -StandardName 'EEEU permission count' -ColumnMap $columnMap
            $anyoneCount = Get-SafePropertyValue -Object $_ -StandardName 'Anyone link count' -ColumnMap $columnMap
            $eeeuNum = if ($eeeuCount) { [int]($eeeuCount -replace '[^\d]', '') } else { 0 }
            $anyoneNum = if ($anyoneCount) { [int]($anyoneCount -replace '[^\d]', '') } else { 0 }
            
            $sitePrivacy -eq 'Private' -and ($eeeuNum -gt 0 -or $anyoneNum -gt 0)
        }).Count
        SitesWithAnyoneLinks = ($analyzedSites | Where-Object { 
            $anyoneCount = Get-SafePropertyValue -Object $_ -StandardName 'Anyone link count' -ColumnMap $columnMap
            $anyoneNum = if ($anyoneCount) { [int]($anyoneCount -replace '[^\d]', '') } else { 0 }
            $anyoneNum -gt 0
        }).Count
    }
    
    Write-Host "`nGenerating HTML report..." -ForegroundColor Yellow
    Generate-HtmlReport -AnalyzedSites $analyzedSites -ScoringConfig $scoringConfig -Statistics $statistics -OutputPath $OutputPath -ColumnMap $columnMap
    
    Write-Host "Generating guidance page..." -ForegroundColor Yellow
    $guidancePath = Generate-GuidancePage -OutputPath $OutputPath
    
    Write-Host "`n=== Analysis Complete ===" -ForegroundColor Green
    Write-Host "Report generated: $OutputPath" -ForegroundColor Green
    Write-Host "Guidance page generated: $guidancePath" -ForegroundColor Green
    Write-Host "Total sites analyzed: $($statistics.TotalSites)" -ForegroundColor White
    Write-Host "High risk sites (score 7+): $($statistics.HighRiskSites)" -ForegroundColor Red
    Write-Host "Private sites with broad access: $($statistics.PrivateSitesWithBroadAccess)" -ForegroundColor Yellow
    Write-Host "Sites with anyone links: $($statistics.SitesWithAnyoneLinks)" -ForegroundColor Yellow
    
    # Show top 5 highest risk sites
    Write-Host "`nTop 5 Highest Risk Sites:" -ForegroundColor Cyan
    $topRisk = $analyzedSites | Select-Object -First 5
    foreach ($site in $topRisk) {
        $siteName = Get-SafePropertyValue -Object $site -StandardName 'Site name' -ColumnMap $columnMap
        $displayName = if ([string]::IsNullOrWhiteSpace($siteName)) { "Unnamed Site" } else { $siteName }
        Write-Host "  $($site.RiskScore) - $displayName" -ForegroundColor White
    }
    
    # Open report in default browser
    Write-Host "`nOpening report in default browser..." -ForegroundColor Yellow
    Start-Process $OutputPath
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}