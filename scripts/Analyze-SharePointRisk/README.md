# 🔐 SharePoint Permissions Risk Analysis Tool

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)

**A comprehensive PowerShell solution for analyzing SharePoint permissions data and generating prioritized risk assessment reports.**

*Transform your SharePoint Advanced Management Data Governance reports into actionable security insights*

---

**📊 Analyze** • **🎯 Prioritize** • **📈 Visualize** • **⬆️⬇️ Sort** • **� Export**

</div>

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [📥 Data Source](#-data-source)
- [✨ Features](#-features)
- [⚙️ Default Scoring Methodology](#️-default-scoring-methodology)
- [🛠️ Usage](#️-usage)
- [📁 Input Data Format](#-input-data-format)
- [📊 Sample Output](#-sample-output)
- [🎨 Risk Categories](#-risk-categories)
- [🎯 Next Steps & Action Plan](#-next-steps--action-plan)
- [📋 Requirements](#-requirements)
- [🚀 Examples](#-examples)
- [🗂️ Sample Data](#️-sample-data)
- [👨‍💻 Author](#-author)
- [📄 License](#-license)

## 🚀 Quick Start

```powershell
# 1. Generate SharePoint Site Permissions Report (see Data Source section)
# 2. Run analysis with default scoring
.\Analyze-SharePointRisk.ps1 -CsvPath ".\your-permissions-report.csv"

# 3. View interactive HTML reports (both open automatically)
#    📊 Main Report: Risk analysis with sortable data table ⬆️⬇️
#    📖 Guidance Page: 7-step action plan and remediation guide
#    🔍 Use search box to filter results, export to CSV/JSON 📤
```

## 📥 Data Source

This tool is specifically designed to analyze the **SharePoint Advanced Management Data Governance "Site Permissions Report"**.

### 🔗 How to Generate the Input Data

1. **Navigate to SharePoint Advanced Management**
   - Go to the SharePoint Online Admin Center
   - Access SharePoint Advanced Management

2. **Generate Site Permissions Report**
   - Navigate to **Data access governance** → **Reports**
   - Select **"Site permissions report"**
   - Configure your report parameters and generate

3. **Download CSV Export**
   - Once generated, download the CSV file
   - This CSV file is your input for this analysis tool

📖 **Detailed Instructions**: [Microsoft Learn - SharePoint Data Access Governance Reports](https://learn.microsoft.com/en-us/sharepoint/data-access-governance-reports)

> ⚠️ **Important**: This tool requires the specific CSV format from SharePoint Advanced Management's Site Permissions Report. Other SharePoint exports may not contain the required columns.

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **Risk Analysis**
- 🔧 **Customizable scoring system** with configurable weights
- ⚡ **Interactive scoring configuration** at runtime
- 🏷️ **Risk categorization**: Critical (10+), High (7-9), Medium (4-6), Low (1-3), No Risk (0)
- 📄 **Professional HTML reports** with sortable columns and color-coding

### 📊 **Visual Dashboard**
- 🎨 **Color-coded risk levels** with visual badges
- 🔍 **Search functionality** (filter by site name, URL, etc.)
- 📋 **Risk level filtering** dropdown
- 📈 **Risk distribution chart** (interactive doughnut chart)
- 📱 **Mobile-responsive design**
- ⬆️⬇️ **Column sorting** with visual indicators (click any column header)
- 🔄 **Bidirectional sort** (toggle ascending/descending with multiple clicks)

### 🎯 **Action Guidance**
- 📋 **Separate guidance page** with comprehensive action plan
- 🔗 **Integrated navigation** from main report to guidance page
- 📖 **7-step methodology** for systematic risk remediation
- 💡 **Implementation tips** and best practices
- 🏢 **Enterprise integration** guidance for SharePoint Advanced Management
- ↩️ **Smart navigation** - guidance page opens in new tab with working back links
- 🎨 **Professional styling** with visual step indicators and checklists

</td>
<td width="50%">

### 🗂️ **Sample Data**
- 🏢 Includes anonymized sample data with `contoso.sharepoint.com` domains
- 📈 Realistic data structure for testing and demonstration
- 🔒 No customer-identifiable information

### 📤 **Export & Reporting**
- 💾 **CSV Export** - Download filtered/sorted data as spreadsheet
- 📄 **JSON Export** - Structured data export for further analysis
- 📊 **Summary statistics** dashboard
- 📋 **Interactive table** with all site data
- 🎛️ **Risk scores and explanations**

</td>
</tr>
</table>

## ⚙️ Default Scoring Methodology

Our risk scoring algorithm focuses on **actual SharePoint security risks** rather than architectural patterns that aren't inherently dangerous.

<div align="center">

| 🚨 Risk Factor | 📊 Default Score | 💡 Why It Matters |
|----------------|:----------------:|-------------------|
| 🔴 **High EEEU Permissions (10+)** | **+4 points** | Excessive broad internal access |
| � **Private Site + EEEU/External** | **+3 points** | Private sites shouldn't have broad access |
| 🎯 **Public Site + Sensitive Title** | **+5 points** | HR, Finance, Legal content shouldn't be public |
| 🔓 **Everyone Permissions Present** | **+3 points** | All users (including future hires) can access |
| 🔗 **Anyone Links Present** | **+2 points** | Anonymous external sharing enabled |
| 📊 **Complex Permissions (50+ users + EEEU)** | **+3 points** | High user count with broad access |
| 🏷️ **No Sensitivity Label** | **+1 point** | Missing data classification (compliance) |

</div>

> � **Customizable**: All scoring weights and thresholds can be adjusted interactively when running the tool!

### 🔄 **Methodology Update (October 2025)**

**Previous Version Issue**: Earlier versions incorrectly penalized public sites with +3 points, treating them as internet-accessible. However, SharePoint "public" sites are **internal-only by default** and not inherently risky.

**Current Focus**: The refined methodology targets actual security risks:
- ✅ **Contextual Analysis**: Private sites with broad access patterns
- ✅ **Content-Aware**: Sensitive keywords in public sites (HR, Finance, etc.)  
- ✅ **Threshold-Based**: EEEU permissions only flagged when excessive (10+)
- ✅ **Realistic Scoring**: More actionable risk prioritization

## 🛠️ Usage

### 🚀 **Risk Analysis**

```powershell
# 📊 Basic analysis with default scoring
.\Analyze-SharePointRisk.ps1 -CsvPath ".\your-permissions-report.csv"

# 🎯 Specify custom output path
.\Analyze-SharePointRisk.ps1 -CsvPath ".\your-permissions-report.csv" -OutputPath ".\custom-report.html"
```

### ⚙️ **Interactive Scoring Configuration**

When you run the analysis script, you'll be prompted:

<details>
<summary>📋 <strong>Click to expand scoring configuration example</strong></summary>

```
Scoring Configuration
===================
Default scoring weights:
- High EEEU Permissions (10+): +4 points
- Private Site with EEEU: +3 points
- Public Site with Sensitive Title: +5 points
- Everyone Permissions: +3 points
- Anyone Links: +2 points
- High Unique Permissions (50+): +3 points
- No Sensitivity Label: +1 points

Would you like to customize these scoring weights? (y/N): 
```

- 💚 Press **Enter** or **N** for default scoring
- 🎛️ Press **Y** to customize each weight interactively

</details>

## � Report Output Structure

The tool generates **two HTML files** for a comprehensive analysis experience:

### 📊 **Main Risk Analysis Report** (`your-report.html`)
- 🎯 **Risk Analysis Dashboard** with summary statistics and distribution chart
- 📋 **Interactive Data Table** with sortable columns and search functionality
- 🔍 **Risk Level Filtering** dropdown to focus on specific risk categories
- 📤 **Export Functions** (CSV and JSON) for filtered data
- 🎨 **Color-coded risk levels** for quick visual assessment
- 🔗 **Guidance Link** prominent button to access action plan

### 📖 **Action Guidance Page** (`your-report_guidance.html`)
- 🎯 **7-Step Remediation Methodology** with detailed implementation guidance
- ✅ **Visual Checklists** with professional styling and step indicators
- 💡 **Best Practices** for SharePoint governance and security
- 🏢 **Enterprise Integration** tips for SharePoint Advanced Management
- ↩️ **Working Navigation** back to main report (closes tab or navigates)
- 📱 **Mobile-Responsive** design for reading on any device

### 🔄 **Navigation Flow**
1. Run script → Main report opens automatically
2. Click **"View Complete Action Plan"** button → Guidance opens in new tab
3. Click **"Back to Risk Analysis Report"** → Returns to main report
4. Both files can be bookmarked and shared independently

> 💡 **Pro Tip**: The separation keeps your data analysis clean while providing comprehensive guidance when needed!

## �📁 Input Data Format

> 📋 **Required Source**: SharePoint Advanced Management - Site Permissions Report CSV

<details>
<summary>📊 <strong>Click to view required CSV columns</strong></summary>

The script expects a CSV file with the following columns (from SharePoint Advanced Management permissions export):

- 🆔 `Tenant ID`
- 🆔 `Site ID`
- 📝 `Site name`
- 🔗 `Site URL`
- 📄 `Site template`
- 👤 `Primary admin`
- 📧 `Primary admin email`
- 🔄 `External sharing`
- 🔒 `Site privacy` (Public/Private/blank)
- 🏷️ `Site sensitivity` (sensitivity label or blank)
- 👥 `Number of users having access`
- 👤 `Guest user permissions`
- 🌐 `External participant permissions`
- 📊 `Entra group count`
- 📁 `File count`
- 🔐 `Items with unique permissions count`
- 🔗 `PeopleInYourOrg link count`
- 🔗 `Anyone link count`
- 🔓 `EEEU permission count`
- 🔓 `Everyone permission count`
- 📅 `Report date`

</details>

## 📊 Sample Output

### 💻 **Console Output Example**

<details>
<summary>🖥️ <strong>Click to view console output</strong></summary>

```
SharePoint Risk Analysis Tool
================================

Scoring Configuration
===================
Default scoring weights:
- High EEEU Permissions (10+): +4 points
- Private Site with EEEU: +3 points
- Public Site with Sensitive Title: +5 points
- Everyone Permissions: +3 points
- Anyone Links: +2 points
- High Unique Permissions (50+): +3 points
- No Sensitivity Label: +1 points

Would you like to customize these scoring weights? (y/N): n

Loading CSV data...
Loaded 4105 raw entries

Deduplicating and aggregating site data...
Deduplicated to 4105 unique sites

Analyzing risk scores...

Generating HTML report...
Generating guidance page...

=== Analysis Complete ===
Report generated: .\risk_analysis.html
Guidance page generated: .\risk_analysis_guidance.html
Total sites analyzed: 4105
High risk sites (score 7+): 25
Private sites with broad access: 16
Sites with anyone links: 0

Top 5 Highest Risk Sites:
  14 - 2025 Automation Initiative
  14 - Domestic Research
  14 - Project RESTRUCTURING - Partner
  13 - Backup Research
  11 - Forecasting Tracking

Opening report in default browser...
```

</details>

### 🎨 **Report Structure**

The tool generates **two complementary HTML files**:

**📊 Main Risk Analysis Report** (`*_report.html`)
- Interactive dashboard with risk data and charts
- Sortable/filterable table of all analyzed sites
- Summary statistics and methodology
- Clean focus on data analysis

**📋 Action Guidance Page** (`*_report_guidance.html`)
- Comprehensive 7-step remediation methodology
- Detailed implementation guidance
- Best practices and enterprise integration tips
- Linked from main report for easy access

> **💡 Design Philosophy**: Keep the data analysis clean and uncluttered while providing comprehensive guidance in a separate, dedicated space.

### 🎨 **HTML Report Features**

The main analysis report includes:

**📊 Dashboard Summary Cards**
- Average Risk Score, Critical/High Risk Count, Highest Risk Score
- Color-coded statistics with visual indicators

**📈 Interactive Risk Distribution Chart**
- Doughnut chart showing breakdown by risk category
- Click legend items to filter data dynamically

**📋 Interactive Data Table**

<details>
<summary>📊 <strong>Sample table data preview</strong></summary>

```
Risk Score | Risk Level    | Site Name           | Site URL                    | Privacy | Users | Risk Factors
-----------|---------------|---------------------|-----------------------------|---------|---------|--------------
13         | Critical Risk | Primary Reports     | contoso.sharepoint.com/... | Public  | 1,247   | Public, EEEU, Everyone, No Label, 500+ Users
10         | High Risk     | Marketing Templates | contoso.sharepoint.com/... | Public  | 892     | Public, EEEU, Everyone, No Label
7          | High Risk     | Finance Dashboard   | contoso.sharepoint.com/... | Private | 634     | EEEU, Everyone, No Label, 500+ Users
4          | Medium Risk   | Team Collaboration | contoso.sharepoint.com/... | Private | 234     | Everyone, No Label
0          | No Risk       | Secure Archive      | contoso.sharepoint.com/... | Private | 12      | (none)
```

</details>

**🎨 Visual Elements**
- 🏷️ **Risk Badges**: Color-coded labels (🔴 Critical, 🟠 High, 🟡 Medium, 🔵 Low, 🟢 No Risk)
- 🔽 **Sortable Columns**: Click any header to sort (with ▲▼ indicators)
- 🔍 **Search Bar**: Filter results by any text (site name, URL, etc.)
- 📋 **Risk Filter**: Dropdown to show only specific risk levels
- 📱 **Responsive Design**: Mobile-friendly layout

**⚡ Interactive Features**
- 🔄 **Column Sorting**: Click any column header to sort data
  - � **Bidirectional**: Toggle between ascending (^) and descending (v) 
  - 🎯 **Smart Sorting**: Numeric columns sort numerically, text columns alphabetically
  - ✨ **Visual Indicators**: Clear ASCII arrows show current sort direction
- � **Real-time Search**: Filter results by any text (site name, URL, risk factors)
- 📋 **Risk Level Filter**: Dropdown to show only specific risk categories
- � **Export Options**: 
  - �💾 **CSV Export**: Download current filtered/sorted data as spreadsheet
  - 📄 **JSON Export**: Structured data export for further analysis
- 📱 **Responsive Design**: Mobile-friendly layout that adapts to screen size
- ✨ **Professional Polish**: Hover effects, smooth transitions, and intuitive UX

> **💡 See it in Action**: Run the tool with the included sample data to see the full interactive HTML report:
> ```powershell
> .\Analyze-SharePointRisk.ps1 -CsvPath ".\Permissioned_Users_Count_SharePoint_report_2025-09-29_scrubbed.csv"
> ```
> The report will automatically open in your default browser showing all interactive features with real data.

## 🎨 Risk Categories

<div align="center">

| 🏷️ Category | 📊 Score Range | ⚠️ Priority Level | 📝 Description |
|-------------|:-------------:|:----------------:|----------------|
| 🔴 **Critical Risk** | **10+** | 🚨 **URGENT** | Immediate attention required |
| 🟠 **High Risk** | **7-9** | ⚡ **HIGH** | Should be reviewed soon |
| 🟡 **Medium Risk** | **4-6** | 📋 **MEDIUM** | Monitor and plan remediation |
| 🔵 **Low Risk** | **1-3** | 📝 **LOW** | Low priority for review |
| 🟢 **No Risk** | **0** | ✅ **SAFE** | No risk factors identified |

</div>

## 🎯 Next Steps & Action Plan

> 📖 **Complete Guidance Available**: After generating your report, click the **"View Complete Action Plan"** button in the main report to access a comprehensive 7-step remediation guide in a separate page.

Once you've generated your risk analysis report, use these actionable steps to improve your SharePoint security posture:

### 1️⃣ **Analyze Key Risk Indicators**

Focus on the most critical data points in your report:

- **🏢 Site Privacy Patterns**: Compare Public vs. Private site configurations
- **🌐 External Sharing Status**: Identify sites with external sharing enabled  
- **👥 EEEU & Everyone Permissions**: Look for inappropriate broad access patterns
- **🔗 Sharing Links Audit**: Review "Anyone" and "People in Org" link counts
- **⚠️ Unique Permissions**: Sites with broken inheritance (permission sprawl)

### 2️⃣ **Target High-Risk Sites First**

Prioritize sites based on these critical patterns:

- **🚨 EEEU/Everyone in Groups**: Sites with broad permissions in Members/Visitors groups
- **📊 Permission Sprawl**: High unique permissions count or excessive sharing links
- **🏛️ Classic Sites**: STS#0 templates often accumulate stale permissions over time
- **🎯 Sensitive Public Sites**: Public sites containing HR, Finance, or Legal content

### 3️⃣ **Engage Site Owners**

Delegate governance through owner empowerment:

- **📋 Site Access Reviews**: Use SharePoint Advanced Management's built-in delegation features
- **📧 Targeted Owner Reports**: Send specific site analysis to responsible owners
- **🤝 Manual Outreach**: Provide guidance and training for high-risk site owners
- **✅ Access Confirmation**: Have owners review and remove unnecessary permissions

### 4️⃣ **Apply Governance Controls**

Implement technical controls to reduce risk:

- **🚫 Remove Broad Access**: Eliminate EEEU/Everyone permissions where inappropriate
- **🌐 External Sharing Audit**: Disable external sharing for internal-only content
- **🔧 Simplify Permissions**: Reduce broken inheritance and complex permission structures
- **🏷️ Sensitivity Labels**: Apply appropriate data classification labels
- **🔒 Restricted Access Control (RAC)**: Immediate lockdown for critical sites
- **🔍 Restricted Content Discovery (RCD)**: Hide sensitive sites from Copilot and org-wide search

### 5️⃣ **Address Stale or Ownerless Sites**

Clean up abandoned content:

- **🗂️ Inactive Sites Policy**: Archive or delete sites that haven't been accessed recently
- **👤 Site Ownership Policy**: Assign new owners to "ownerless" sites
- **🔄 Regular Cleanup**: Establish recurring governance processes

### 6️⃣ **Prevent Future Oversharing**

Implement proactive controls:

- **🔗 Default Link Settings**: Change default sharing to "Specific People" only
- **🌍 Global EEEU Policy**: Consider disabling organization-wide EEEU if suitable
- **📚 User Education**: Train users on proper SharePoint sharing practices
- **🤖 Automated Governance**: Schedule recurring Data Access Governance (DAG) reports and reviews

### 7️⃣ **Document & Communicate Changes**

Ensure stakeholder alignment:

- **📢 Stakeholder Updates**: Inform users about governance changes and site lockdowns
- **📖 Access Instructions**: Provide clear guidance for requesting access to restricted sites
- **📝 Change Documentation**: Track all governance actions for compliance and audit purposes

### ⚡ **Advanced Actions** *(Optional)*

For organizations with advanced governance needs:

- **🔧 PowerShell Automation**: Schedule automated DAG reports and detailed CSV exports
- **📱 Block Download Policy**: Prevent offline file copies for highly sensitive sites
- **🚪 Conditional Access**: Implement location or device-based access restrictions
- **🛡️ DLP Integration**: Link governance policies with Data Loss Prevention controls

### 💡 **Implementation Tips**

> **🎯 Start Small**: Begin with Critical and High risk sites, then work down the priority list  
> **📊 Track Progress**: Re-run this analysis monthly to measure security posture improvements  
> **🤝 Collaborate**: Work with site owners rather than imposing changes unilaterally  
> **📈 Measure Success**: Use decreasing high-risk site counts as your primary success metric

---

*💼 **Enterprise Integration**: This analysis integrates seamlessly with SharePoint Advanced Management, Microsoft Purview, and broader Microsoft 365 governance strategies.*

## 📋 Requirements

- 💻 **PowerShell 5.1 or later**
- 🪟 **Windows** with default browser for report viewing
- 📊 **SharePoint Advanced Management** - Site Permissions Report CSV

## 🚀 Examples

### 🔧 **Basic Usage**
```powershell
# 📊 Analyze your SharePoint permissions data
.\Analyze-SharePointRisk.ps1 -CsvPath ".\your-sharepoint-permissions-report.csv"

# 🎛️ The script will prompt interactively for custom scoring if desired
```

### ⚙️ **Custom Scoring Example**

<details>
<summary>🎛️ <strong>Advanced configuration example</strong></summary>

```
Would you like to customize these scoring weights? (y/N): y

=== Custom Scoring Configuration ===
Enter custom scores for each risk factor (press Enter to keep default):
Site Privacy = Public (default: 3): 5
EEEU Permissions Present (default: 3): 4
Everyone Permissions Present (default: 3): 4
Anyone Links Present (default: 2): 3
No Sensitivity Label (default: 2): 1
High User Count (default: 2): 2
User Count Threshold (default: 500): 1000
```

</details>

## 🗂️ Sample Data

The included sample CSV file contains anonymized data with:
- 🔗 Generic `https://contoso.sharepoint.com/sites/[sitename]` URLs
- 🏢 Anonymized site names (e.g., "HR Dashboard", "Marketing Portal")  
- 📧 Generic `user###@contoso.com` email addresses
- 👤 Generic admin names and tenant ID
- 📊 **Realistic numerical data** for testing the analysis tool

## 👨‍💻 Author

<div align="center">

**John Cummings**  
📧 [john@jcummings.net](mailto:john@jcummings.net)  
📅 Published: October 16, 2025

---

*Built with ❤️ for SharePoint security professionals*

</div>

## 📄 License

This tool is provided as-is for SharePoint security analysis purposes under the MIT License.

---

<div align="center">

### 🛡️ Security • 📊 Analytics • 🚀 Efficiency

**Star ⭐ this repository if it helped you secure your SharePoint environment!**

[![GitHub issues](https://img.shields.io/github/issues/jcummings/Analyze-PermissionsState)](https://github.com/jcummings/Analyze-PermissionsState/issues)
[![GitHub stars](https://img.shields.io/github/stars/jcummings/Analyze-PermissionsState)](https://github.com/jcummings/Analyze-PermissionsState/stargazers)

</div>