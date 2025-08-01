# 🔍 Copilot Audit Dashboard

> [!NOTE] 
> New Version! This version includes agent details including columns to categorize interactions that are related to SPO Agent, Custom Agent, and Copilot Pages (powered by Loop).

## 📊 Overview
This solution provides a comprehensive dashboard for analyzing and visualizing Microsoft 365 Copilot Purview Audit events across your organization. It consists of a PowerShell script for data extraction and a Power BI template for visualization and insights.

## 🧩 Components
1. **PowerShell Script**: Extracts data from various Microsoft 365 sources including Entra users, Copilot audit logs, and usage reports
![alt text](./Images/2025-03-27%2014_42_33-AlejanlDev.png)

2. **Power BI Template**: Visualization dashboard for analyzing Copilot usage patterns, user behavior, and adoption metrics
![alt text](./Images/image.png)

## ✅ Prerequisites
- PowerShell 5.1 or higher
- Microsoft Graph PowerShell SDK
- Exchange Online Management module
- Admin permissions for Microsoft Graph and Exchange Online
- Microsoft 365 E5 license or Microsoft 365 Copilot license
- Power BI Desktop (for opening and customizing the template)

## 🚀 Installation

### Required PowerShell Modules
The script will check for the required modules and offer to install them if they're missing:
- Microsoft.Graph
- ExchangeOnlineManagement

If you prefer to install manually, run:

Install-Module -Name Microsoft.Graph -Force -AllowClobber
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

## 🔧 Usage

### Running the PowerShell Script
1. Download the script file `Export-M365CopilotReports.ps1`
2. Open PowerShell as an administrator
3. Navigate to the script location
4. Run the script:

   .\Export-M365CopilotReports.ps1

5. The script will display a menu with the following options:
   - Export Entra Users Details
   - Export Purview Audit Logs (Copilot Interactions Only)
   - Export Microsoft 365 Copilot Usage Reports
   - Exit

### Data Export Options

#### 👥 Export Entra Users Details
This option exports user information from Microsoft Entra (Azure AD), including:
- User profile details (DisplayName, Email, Department, etc.)
- Manager information (critical for organizational hierarchy in reports)
- License information (to identify Copilot-licensed users)

The exported CSV file will be used as input for the Power BI dashboard to build organizational context.

#### 📝 Export Copilot Audit Logs
This option extracts Copilot interaction data from Microsoft Purview audit logs:
- User activity with Copilot across different applications
- Copilot prompts and responses (where available)
- Context of Copilot usage (documents, chats, etc.)
- Resources accessed by Copilot
- Identification of SPO Agent, Custom Agent, and Copilot Pages interactions

You can specify the number of days to look back (default is 7 days).

#### 📈 Export Microsoft 365 Copilot Usage Reports
This option retrieves aggregated Copilot usage data at the user level:
- User activity dates across different applications
- Last activity timestamps by application

You can choose from different time periods:
- D7 (7 days)
- D30 (30 days) - default
- D90 (90 days)
- D180 (180 days)

### Setting Up the Power BI Dashboard
1. Open the Power BI File (`.pbix` file)
2. This will open the dashboard with sample data. 
3. To load your reports, **Click Home > Transform Data** and update the parameters to point to your Entra Users CSV Export and Copilot Audit Activities CSV Export.  

   ![alt text](./Images/image-updateparameters.png)
4. Click **Close & Apply** and Power BI will load the dashboard with your reports. 

## 📊 Dashboard Features
The Copilot Analytics Dashboard provides visualizations including:
- User adoption and activity metrics
- Department-level usage patterns
- Application-specific Copilot usage
- Activity timelines and trends
- Resource access patterns
- SPO Agent, Custom Agent, and Copilot Pages usage analytics

## ⚠️ Troubleshooting

### Common Issues
- **Authentication Errors**: Ensure you have appropriate admin permissions
- **Missing Data**: Verify audit logging is enabled in Microsoft Purview
- **Performance Issues**: For large organizations, consider reducing the data export timeframe
- **Module Loading Errors**: Try reinstalling the required PowerShell modules

### Logging
The script creates detailed log files in the output directory. Review these for troubleshooting:
- Each export function creates its own log file with timestamp
- Logs contain detailed information about connection attempts and data retrieval

## 📚 Additional Resources
- [Microsoft 365 Copilot Documentation](https://learn.microsoft.com/en-us/microsoft-365-copilot/)
- [Microsoft Purview Audit Logging](https://learn.microsoft.com/en-us/purview/audit-log-search)
- [Microsoft Graph API Documentation](https://learn.microsoft.com/en-us/graph/api/overview)

## 👨‍💻 Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|March 26th, 2025|

## ✨ Inspiration
This solution builds on top of the great work from Bojan: [M365 Copilot Audit PowerBI Report](https://github.com/BojanBuhac/M365-Copilot-Audit-Report). The original report provided a foundation that has been expanded with additional features and visualizations.

## ❓ Issues

Please report any issues you find to the [issues list](../../../../issues).

## ⚖️ Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## 🤝 Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## 📜 Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.
