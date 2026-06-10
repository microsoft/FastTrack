# Copilot Analytics Samples 📊

## Overview

This directory contains distinct sample solutions to help organizations analyze the usage, adoption, and potential impact of Microsoft Copilot. Each sub-directory typically contains a specific Power BI report template focused on different data sources available within Microsoft 365. 💡

## Sample Solutions ✨

The following table summarizes the available samples within this directory. Please navigate to the respective sub-directory for the specific files and potentially more detailed instructions.

| Solution / Directory                 | Description                                                                                                                                                              | Data Sources Used                                              |
| :----------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------- |
| [Copilot-VivaInsights-PBI-Report](./VivaInsights-Copilot-Dashboard-Sample/)    | Provides a Power BI template focused on analyzing Copilot adoption and its potential correlation with collaboration patterns using aggregated Viva Insights data. Visualizes trends 📈 in focus time, meeting hours, network size, etc., for identified Copilot user cohorts compared to peers. | Microsoft Viva Insights (Advanced Insights Analyst Workbench) 🧠 |
| [Copilot-PurviewAudit-PBI-Report](./Copilot_Audit_PBI/)    | Offers a Power BI template designed to visualize granular Copilot usage 🔍 based on specific audit events captured in Microsoft Purview. Helps track frequency and types of Copilot interactions across supported M365 applications (subject to audit log configuration and availability). | Microsoft Purview Audit Logs 🛡️                                   |
| [Copilot-Usage-Users-and-Apps](./copilot-usage-users-and-apps/)    | Offers a Power BI template designed to show how a Viva Insights Person Query export can be used to visualize user and application data in PowerBI. Helps visualize where additional training investments may be needed in order to help increase license utilization. | Microsoft Viva Insights (Advanced Insights Analyst Workbench) 🧠                                   |
| [Copilot-Interaction-Report (PowerShell)](./copilot-interaction-report/)    | A PowerShell sample that pulls Microsoft 365 Copilot **enterprise interaction history** directly from the Microsoft Graph API and renders a self-contained **HTML dashboard** (no Power BI required) — surfaces used, top users, friction/error rates, prompt-intent breakdown, and a sortable per-user leaderboard. 🖥️ | Microsoft Graph (`getAllEnterpriseInteractions`) 🔌 |

## General Prerequisites 📋

To effectively use these Power BI sample reports and connect them to your own data, you will generally need:

* 🖥️ **Power BI Desktop:** Installed on your machine to open and edit the `.pbix` files.
* 🔑 **Appropriate Data Source Access:**
    * For **Viva Insights** samples: Access to Microsoft Viva Insights Advanced capabilities and the Analyst Workbench role.
    * For **Purview Audit Log** samples: Permissions to access and search Audit Logs within the Microsoft Purview compliance portal.
* ⚙️ **Relevant Configurations:**
    * Ensure Viva Insights is set up and generating data.
    * Ensure relevant Copilot activities are being audited and retained in Purview according to your organization's policies.
* 🧩 **Familiarity with Power Query:** Understanding how to connect to data sources (OData, Audit Logs, etc.) and perform necessary data transformations within Power BI.
* 🔒 **Organizational Data Privacy Awareness:** Understanding and adhering to your company's policies regarding data privacy and the use of employee data.

## Getting Started 🚀 (General Steps)

1.  📂 **Navigate:** Go into the specific sub-directory for the sample you want to use.
2.  ⬇️ **Download:** Clone the repository or download the contents of the chosen sub-directory, ensuring you have the sample `.pbix` file.
3.  🖥️ **Open:** Launch Power BI Desktop and open the downloaded `.pbix` file.
4.  🔌 **Connect Data Sources:**
    * You will likely be prompted to configure or update the data source connections specific to that report (e.g., Viva Insights OData URL, Purview connection).
    * Examine the queries in the Power Query Editor (`Transform data` button) within the specific report to understand the expected data structure and update connection parameters as needed for *that sample's required data source*.
5.  🔄 **Refresh Data:** Once connections are configured for the specific report, refresh the data model in Power BI.
6.  🔍 **Explore:** Interact with the report visuals to explore Copilot analytics based on the data source focus of that sample.

## Contributing 🙌

This repository is part of the Microsoft FastTrack effort. Please refer to the contribution guidelines in the root of the `microsoft/FastTrack` repository if you wish to suggest improvements or report issues.

## License 📄

The code and samples in this repository are licensed under the MIT License. Please refer to the `LICENSE` file in the root of the `microsoft/FastTrack` repository for specific details.

## Disclaimer ⚠️


These samples are provided "as-is" for illustrative and educational purposes. They likely require modification and customization to fit your specific organizational environment, data schema, available audit events, and reporting requirements. Always ensure compliance with your organization's data privacy, security, and governance policies when working with employee data.
