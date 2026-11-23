---
title: "Copilot Spending Policy Planner"
type: strategy
category: "Interactive"
summary: "Plan Copilot Credits spending policies in one HTML file: billing methods, groups, limits and checks, with a summary PDF and build sheet."
author: "Sumit Sadhu"
version: 1.0.0
published: 2026-11-23
updated: 2026-11-23
tags:
  - copilot-credits
  - spending-policies
  - cost
  - governance
  - billing
  - planning
format: interactive
interactiveKind: tool
preview: preview.webp
featured: false
status: preview
whatItIs: >-
  A self-contained, offline planner for Copilot Credits spending policies.
  You draw the design on a canvas: billing methods, spending policies, groups and the services they cover.
  The planner estimates credits and cost, runs checks against public Microsoft Learn guidance, and exports a summary PDF and an admin build sheet.
  It includes ten sample designs, so you can explore before you start your own.
whyUseIt:
  - "See billing methods, policies, groups and services on one canvas before you change anything in the admin centers."
  - "Compare limits with expected usage and cost, and see the effect of a pilot, production or scale stage."
  - "Get a worst-first list of Fix, Check and Tip items before you build. Microsoft rules link to Microsoft Learn; other items are labelled as recommended practice, seen in the admin center, or Microsoft API (beta)."
  - "Hand administrators a build sheet (CSV) and a summary report (PDF) that follow the design."
howToUse: |-
  1. Open `index.html` in a modern browser, or use the hosted copy from the catalog.
  2. Under "Start a design", pick a sample design. You can also use "Start from" for a sample or a blank canvas, or "Open" to load a saved design file.
  3. Set the stage, the cost model, the number of people and the default price per credit.
  4. From the Blocks pane, add billing methods, identity-based or resource-based policies, groups, Copilot Studio agents and environments. Set limits in the Inspector.
  5. Open the Checks tab and work through the Fix, Check and Tip items. Use "Today vs plan" to compare with the current setup.
  6. Choose Save, then Design file, then Download to keep the design as a file.
  7. Choose Save, then Admin build sheet, then Download CSV for the build sheet. On the Summary view, choose Download PDF for the report.
prerequisites:
  - "A modern web browser"
  - "Access to the Microsoft 365 admin center and the Power Platform admin center to build the policies you plan"
  - "The admin roles the planner names for policies: Global administrator, Billing administrator, AI administrator and License administrator"
---

# Copilot Spending Policy Planner

A planning aid for designing Copilot Credits spending policies, billing and limits, in one self-contained HTML file.

Open `index.html` in a modern browser. Pick one of the ten sample designs to see how the planner works, then start your own design.

## What it does

- **Design on a canvas.** Add billing methods, spending policies, groups and services, and see how they connect.
- **Estimate credits and cost.** See limits, expected use and cost for a pilot, production or scale stage.
- **Run checks.** One list shows Fix, Check and Tip items, worst first. Microsoft rules link to Microsoft Learn; other items are labelled as recommended practice, seen in the admin center, or Microsoft API (beta).
- **Compare with today.** Save the current setup as "today", then see what the plan changes.
- **Save and share.** Save the design as a file, download the admin build sheet as CSV, or create a summary as PDF, HTML or print.

## Privacy and data

- The planner runs entirely in your browser. It needs no sign-in and has no tracking.
- It makes no network requests. Links to Microsoft Learn open only when you select them.
- It stores nothing in the browser. Close the page and the design is gone.
- A design leaves the page only when you save, copy or print it.

## Usage

1. Open `index.html`, or the hosted copy.
2. Pick a sample under "Start a design", or choose "Blank canvas". To continue earlier work, choose "Open", then "From a file…" or "Paste design text…".
3. Set the stage (Pilot, Production or Scale) and the cost model (Central, Showback or Chargeback).
4. Add blocks from the Blocks pane. Select an item to edit it in the Inspector.
5. Review the Checks tab. The "Who gets what" and "Run it" tabs hold the people view and the run-time settings.
6. Use "Today vs plan" and "Summary" to review and share.
7. Choose Save to download the design file or the admin build sheet. On the Summary view, choose Download PDF, Save as HTML or Print.

Use "Present" for a clean canvas when you show the design to others.

## Applies To

- Copilot Cowork
- Advanced work in SharePoint and OneDrive, Work IQ API, Copilot Managed Runtime, Teams Phone Agent, Code (Frontier), Opal, Sales Development Agent, Teams: Consecutive interpretation and Intelligent Call Delegation
- Copilot Studio agents and their environments
- Copilot Credits billing: pay-as-you-go, prepaid capacity packs and the pre-purchase plan
- Spending policies in the Microsoft 365 admin center and capacity in the Power Platform admin center

## Sources

The rules in the checks are based on public Microsoft Learn documentation. The planner was last checked against it on 9 to 14 November 2026. The service list and Teams interpretation billing were rechecked on 23 November 2026. Sources include:

- [Copilot Credits overview](https://learn.microsoft.com/en-us/copilot/plan/usage-based-billing-overview-copilot-credits)
- [Set up Copilot Credits](https://learn.microsoft.com/en-us/copilot/implement/usage-based-billing-copilot-credits-setup)
- [Manage Copilot Credits](https://learn.microsoft.com/en-us/copilot/implement/usage-based-billing-manage-copilot-credits)
- [Monitor spending](https://learn.microsoft.com/en-us/copilot/implement/usage-based-billing-copilot-credits-monitor-spending)
- [Manage Copilot Studio costs](https://learn.microsoft.com/en-us/copilot/implement/usage-based-billing-manage-copilot-studio-costs)
- [Copilot Studio billing and licensing](https://learn.microsoft.com/en-us/microsoft-copilot-studio/billing-licensing)
- [Copilot Studio credit overview](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/billing-credit-overview)
- [Manage Copilot Credits capacity](https://learn.microsoft.com/en-us/power-platform/admin/manage-copilot-studio-copilot-credits-capacity)
- [Manage Interpreter agent in Teams](https://learn.microsoft.com/en-us/microsoftteams/interpreter-agent-teams)

## Disclaimer

This is a community sample from Microsoft FastTrack, provided as is. It is not official Microsoft documentation, not a price quote and not a commitment.

Credit and cost figures are planning estimates. Check product behavior, licensing and prices on Microsoft Learn and in your own tenant before you make changes.

Third-party notices are in `THIRD-PARTY-NOTICES.txt` and in the About dialog of the planner.

## Author

| Author | Original Publish Date |
|--------|-----------------------|
| Sumit Sadhu, Microsoft | November 23rd, 2026 |

## Issues

Please report problems or suggest updates as an [issue on GitHub](https://github.com/microsoft/FastTrack/issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://github.com/microsoft/FastTrack/blob/master/LICENSE), see the LICENSE file, and grant you a license to any code in the repository under the [MIT License](https://github.com/microsoft/FastTrack/blob/master/LICENSE-CODE), see the LICENSE-CODE file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.
