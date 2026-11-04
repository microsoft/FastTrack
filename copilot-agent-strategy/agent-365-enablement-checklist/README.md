---
title: "Agent 365 Enablement Checklist"
type: strategy
category: "Interactive"
summary: "A sample Agent 365 deployment plan in one HTML file: scope by agent type, pillar, or feature, track tasks to go-live, and export to Excel."
author:
  - "Alejandro Lopez"
version: 1.0.3
published: 2026-10-28
updated: 2026-10-30
tags:
  - agent-365
  - deployment
  - checklist
  - planning
  - governance
format: interactive
interactiveKind: tool
preview: preview.webp
featured: false
status: active
whatItIs: >-
  A self-contained, offline tracker for planning and tracking a Microsoft Agent 365 enablement. It
  organizes the work into workstreams with role-based tasks, shows a readiness dashboard, and exports
  to Excel, CSV, or JSON. It opens with a made-up plan for Contoso so you can explore before you start
  your own.
whyUseIt:
  - "Scope the plan by agent type, pillar, or feature so each team sees the tasks that apply to it."
  - "Track every task through to the go-live baseline, with owners, dates, and notes, and watch readiness on the dashboard."
  - "Share the plan with your steering group as an Excel workbook (a dashboard plus one sheet per workstream), a CSV task list for Planner, DevOps, or Jira, or a printable report."
  - "Work entirely offline: it is a single file with no server, sign-in, tracking, or network requests."
howToUse: |-
  1. Open `index.html` in a modern browser, or use the hosted copy from the catalog.
  2. Explore the sample plan, then start your own: set the customer name, deployment lead, sponsor, and go-live date.
  3. Scope the plan, then work through the tasks by workstream and role, marking status, owners, dates, and notes as you go.
  4. Export to Excel, CSV, or a JSON backup, or print or save a report. Your plan autosaves in your browser on that device, so use the JSON backup to move it or share it.
prerequisites:
  - "Modern web browser"
  - "Appropriate Microsoft 365, Agent 365, security, compliance, identity, and endpoint licenses for the features you plan to enable"
  - "Administrative roles required by the tasks you choose to perform"
---

# Agent 365 Enablement Checklist

A sample Microsoft Agent 365 deployment plan in a single, self-contained HTML file. Use it to scope an enablement by agent type, pillar, or feature, track every task through to go-live, and export the plan to Excel to share with your team.

Open [`index.html`](index.html) in a modern browser. It opens with a made-up plan for Contoso, so you can see how it works before you start your own plan.

## What it does

- **Scope the plan.** Include only the agent types, pillars, and features that apply to your tenant.
- **Work the tasks.** Tasks are grouped into workstreams and assigned to roles, with status, owner, dates, and notes. Tasks link to Microsoft Learn documentation.
- **See readiness.** A dashboard summarizes progress toward the go-live baseline.
- **Export and share.** Export an Excel workbook (a dashboard and one sheet per workstream with live totals), a CSV task list for Planner, DevOps, or Jira, or a JSON backup you can import later. You can also print or save a report.

## Privacy and data

The checklist is a single file with no server, sign-in, tracking, or network requests. Your plan is stored only in your browser's local storage on that device. Export it to share it with others or to move it to another device.

## Works with the other Agent 365 guides

This checklist and the [Agent 365 Customer Implementation Guide](../agent-365-customer-implementation-guide/) are companions: the guide explains each configuration in detail, and the checklist helps you plan and track the work. The checklist links to the guide's Detailed view and opens the exact step for each task, for example `index.html#advanced/4.04a`, to the [Microsoft Agent 365 Technical Advisory](../agent-365-technical-advisory/) for reference architecture and best practices, and to the [Agents Cost Calculator](../copilot-agents-cost-tool/) for budgeting.

When you rename or move any of these folders, update the links in the others. `npm run check` in `tools/catalog-build` fails if a FastTrack link in a resource page or README no longer resolves.

## Disclaimer

This is a community sample, provided as is. It is not official Microsoft documentation. Validate product availability, licensing, roles, and portal behavior in your tenant, and tailor the plan to your organization before making production changes.

## Author

|Author|Original Publish Date
|----|--------------------------
|Alejandro Lopez, Microsoft|October 28th, 2026|

## Issues

Please [report problems or suggest updates](https://github.com/microsoft/FastTrack/issues/new?template=resource-feedback.yml&resource=Agent%20365%20Enablement%20Checklist) with the resource feedback form.
