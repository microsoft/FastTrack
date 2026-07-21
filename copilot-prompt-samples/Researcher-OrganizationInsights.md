---
title: Researcher — Automation Opportunities
type: prompt
category: Researcher
summary: >-
  Analyze Microsoft 365 signals to identify repetitive work and prioritize high-value Copilot agent
  automation opportunities.
author: Alexander Hurtado
version: 1.0.0
published: "2025-05-14"
updated: "2025-05-15"
tags:
  - researcher
  - frontier
  - automation
format: md
whatItIs: >-
  A Microsoft 365 Researcher prompt that looks across available organizational signals for
  repetitive, fragmented, or manual workflows suited to intelligent automation.
whyUseIt:
  - Discover automation opportunities grounded in observed work patterns.
  - Prioritize scenarios by frequency, departments involved, and estimated time savings.
  - Focus agent ideas on gaps that need intelligence, summarization, or cross-source coordination.
howToUse: >-
  Copy the prompt from this file into Microsoft 365 Researcher. Replace the bracketed department
  example with the desired scope, confirm Researcher has access to the intended organizational
  sources, run it, and review the structured opportunity table.
prerequisites:
  - Access to Microsoft 365 Researcher
  - Permission to use the relevant Microsoft 365 organizational data
---

# Researcher-AutomationOpportunities

## 🎯 Use Case
This prompt enables the Researcher agent to analyze organizational data across multiple Microsoft 365 services to identify high-value automation opportunities for Copilot Agents. It focuses on discovering repetitive, manual, or fragmented workflows that could benefit from intelligent automation.

## 📝 Prompt
```
Analyze all available data from across my organization, including Outlook emails, calendar invites, Teams meetings (recordings, transcripts, and invites), group chats, channel messages, shared OneDrive/SharePoint files, and task-related tools like Planner or To Do. Your goal is to uncover the most valuable use cases for Copilot Agents that could automate or assist with repetitive, manual, or fragmented workflows.

Identify patterns such as repeated status updates, frequent information requests, duplicated efforts, report generation, data lookups, cross-department coordination, or tasks that require pulling information from multiple systems.

**Apply the following criteria in your analysis:**

  1. Scope
    - Begin by analyzing all available organizational data, but prioritize insights from the following departments if they show stronger automation potential:
      - [Insert your department, e.g., FastTrack, Sales, Finance, HR]
  2. Tool Focus
    - Emphasize areas where manual processes are most common in these systems:
      - Outlook, Teams, SharePoint/OneDrive, Excel, Planner, Power BI
  3. Time Savings Format
    - Report estimated time savings per task in hours per week per user or per team.
  4. Task Type Priority
    - Prioritize the following task categories:
      - Manual data entry or aggregation
      - Weekly status reporting
      - Follow-up/reminder communications
      - Frequently asked internal questions (FAQs)
      - Meeting-related tasks (preparation, summaries, follow-ups)
      - Requests that traverse multiple systems (e.g., Teams + Excel + Outlook)


**Output Format (Structured Table):**

Please provide your results in the following structured format:
Use Case Name  Source(s) Detected  Description of Pattern  Departments Involved  Estimated Time Savings  Proposed Copilot Agent Function


**Final Notes:**

  "If possible, also identify the volume or frequency of the task across the organization to help prioritize which Copilot Agents would have the highest impact."
  "Do not propose ideas that are already well-automated or covered by current Power Automate flows—focus on gaps that require intelligence, summarization, or multi-source decision support."

**Example Output:**

| Use Case Name | Source(s) Detected | Description | Departments | Time Savings | Copilot Function |
|---------------|-------------------|-------------|-------------|--------------|------------------|
| Meeting Action Item Extractor | Teams meeting transcripts + Outlook | Users manually write meeting notes and follow-ups after meetings | Engineering, PMO | 2 hrs/week/user | Automatically summarize meetings, extract tasks, and post to Planner |
| Quarterly Metrics Summary | Email threads + Excel files + SharePoint | Managers spend time collecting KPIs from various owners | Sales, Operations | 5 hrs/quarter | Auto-pull KPI data, compile into report draft |
| Repetitive IT Request Responses | Outlook + Teams chats | Repeated IT questions about password resets, access issues | Org-wide | 15 mins/request | AI-driven FAQ responder with adaptive cards |
| Escalation Summary Generator | Emails + Teams | Manual duplication of status updates across stakeholders | Customer Success, Support | 1.5 hrs/escalation | Compile single escalation status brief and route to stakeholders |
```

## 📊 Example Output

| Use Case Name | Source(s) Detected | Description | Departments | Time Savings | Copilot Function |
|---------------|-------------------|-------------|-------------|--------------|------------------|
| Meeting Action Item Extractor | Teams meeting transcripts + Outlook | Users manually write meeting notes and follow-ups after meetings | Engineering, PMO | 2 hrs/week/user | Automatically summarize meetings, extract tasks, and post to Planner |
| Quarterly Metrics Summary | Email threads + Excel files + SharePoint | Managers spend time collecting KPIs from various owners | Sales, Operations | 5 hrs/quarter | Auto-pull KPI data, compile into report draft |
| Repetitive IT Request Responses | Outlook + Teams chats | Repeated IT questions about password resets, access issues | Org-wide | 15 mins/request | AI-driven FAQ responder with adaptive cards |
| Escalation Summary Generator | Emails + Teams | Manual duplication of status updates across stakeholders | Customer Success, Support | 1.5 hrs/escalation | Compile single escalation status brief and route to stakeholders |

## 👤 Author Information

| Author | Original Publish Date |
|--------|----------------------|
| Alexander Hurtado - Alexander.Hurtado@microsoft.com | May 14, 2025 |


## 📌 Notes
- This prompt is designed for organizational analysis and works best with full access to Microsoft 365 data sources
- Customize the department focus in the Scope section based on your specific organizational needs
- The agent will need sufficient permissions to access the necessary data sources