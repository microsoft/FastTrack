---
title: Agents Cost Calculator
type: strategy
category: Interactive
summary: >-
  Estimate test and production costs for Copilot Studio, Agent Builder, SharePoint, and Foundry
  agents.
author: Microsoft FastTrack
version: 1.0.0
published: "2026-04-01"
updated: "2026-07-16"
tags:
  - cost
  - roi
  - calculator
format: interactive
featured: true
whatItIs: >-
  A self-contained browser calculator for modeling Copilot Credits or token-based costs across
  custom, Agent Builder, SharePoint, and Microsoft Foundry agents.
whyUseIt:
  - Trace per-turn costs before testing or production rollout.
  - Compare pay-as-you-go, capacity, model, knowledge, tool, and conversation assumptions.
  - Export a scenario to CSV or print a shareable planning snapshot.
howToUse: >-
  Open `index.html` in a browser, select an agent type, and optionally load a quick-start template.
  Enter knowledge, component, conversation, test-scale, or token assumptions, then review the cost
  trace and production estimate. Export CSV or print the results.
prerequisites:
  - Modern web browser
  - Current licensing and pricing inputs for planning validation
---

# M365 Copilot Agents Cost Calculator

A self-contained, browser-based cost estimator for Microsoft 365 Copilot agents.
Open `index.html` in any modern browser — no server, no dependencies, no login required.

> **This tool produces planning estimates only. Results are not a billing commitment.**
> Actual charges depend on runtime behavior, orchestration paths, tenant configuration,
> model usage, Microsoft licensing changes, and feature availability.

---

## What it covers

| Agent type | Billing model |
|---|---|
| **Custom agent** (Copilot Studio) | Copilot Credits — per classic answer, generative answer, agent action, graph grounding, AI prompt, agent flow, content processing |
| **Agent Builder agent** (M365 Copilot declarative) | Copilot Credits — knowledge sources only; public website grounding is free |
| **SharePoint agent** | Copilot Credits — SharePoint via tenant graph grounding |
| **Foundry agent** (Azure AI Foundry Agent Service) | Token-based — input + output tokens billed to Azure subscription; no Copilot Credits |

---

## How to use

1. Open `index.html` in a browser.
2. **Select your agent type** at the top.
3. (Optional) **Pick a quick-start template** to pre-fill a realistic enterprise scenario.
4. Fill in the steps:
   - **Knowledge sources** — which sources your agent uses and how many.
   - **Components** (custom agents) — topics, tools, AI prompts, flows.
   - **Conversation profile** — how many turns per conversation and what happens in each.
   - **Test plan scale** — number of scenarios × iterations.
   - **Foundry agents** — model, token sizes, turns, and built-in tools (File Search, Code Interpreter).
5. Review the **Example Prompt & Cost Trace** to validate the per-turn breakdown.
6. Review the **Production Cost Estimate** panel for totals, a credit breakdown chart, and capacity impact.
7. Use **Export CSV** to save the configuration and results, or **Print** for a shareable snapshot.
8. Click **Start Over** (header or results panel) to reset everything.

---

## Quick-start templates

| Template | Agent type | What it models |
|---|---|---|
| Enterprise FAQ agent | Custom (Copilot Studio) | SharePoint + enterprise connectors, authored topics, no tools or flows |
| HR policy agent | Custom (Copilot Studio) | SharePoint, connectors, uploaded files, pure internal knowledge — no tools, flows, or AI prompts |
| IT helpdesk with tools + flows | Custom (Copilot Studio) | SharePoint, connectors, tools, agent flow, AI prompts, reasoning model |
| Employee Self-Service — HR agent starter | Custom (Copilot Studio) | SharePoint HR policies + ServiceNow Knowledge KB + Workday connector; HRSD topics for create/get/update HR cases; shared orchestrator flow; no reasoning; 70% M365 user share |
| Employee Self-Service — IT agent starter | Custom (Copilot Studio) | SharePoint IT docs + ServiceNow Knowledge KB + Microsoft Self-Help connector; ITSM topics for create/get/update tickets; reasoning model for diagnostic classification; 50% M365 user share |
| General purpose assistant (GPT-4o) | Foundry agent | GPT-4o, 5 turns with file search, token-based billing |
| Code assistant (GPT-4.1) | Foundry agent | GPT-4.1, 6 turns with code interpreter, token-based billing |

---

## Billing rates reference

### Copilot Studio / M365 Copilot agents

Source: [Copilot Credits billing rates (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)

| Feature | Credits | Unit |
|---|---|---|
| Classic answer | 1 | per response |
| Generative answer | 2 | per response |
| Agent action (tool call, flow trigger) | 5 | per action |
| Tenant graph grounding | 10 | per message |
| SharePoint or connector (graph-grounded) | 12 | per query (10 graph + 2 gen) |
| Agent flow actions | 13 | per 100 actions |
| AI tools — basic | 1 | per 10 responses |
| AI tools — standard | 15 | per 10 responses |
| AI tools — premium | 100 | per 10 responses |
| Content processing | 8 | per page |
| Reasoning model surcharge | +10 | per generative answer and agent action |

**Pricing options** (all bill in Copilot Credits):

| Option | Effective $/credit | Notes |
|---|---|---|
| Pay-as-you-go (PAYG) meter | $0.0100 | Postpaid; billed via Azure subscription. No commitment. |
| Copilot Credit pack (subscription) | $0.0080 | $200/month for 25,000 credits. Unused credits do not roll over. |
| Copilot Credit Pre-Purchase Plan (P3) | $0.0095 → $0.0080 | 1-year commit, 9 tiers, 5% → 20% discount (3,000 → 3,000,000 CCCUs). 1 CCCU = 100 credits. |
| **Microsoft Agent Pre-Purchase Plan (P3)** *(NEW May 2026)* | $0.0095 / $0.0090 / $0.0085 | 1-year commit, 3 tiers, 5% / 10% / 15%. **Covers BOTH Copilot Studio AND Microsoft Foundry usage.** 1 ACU = 100 credits or $1 Foundry. |

Source: [Microsoft Copilot Studio Licensing Guide (May 2026)](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/bizapps/Microsoft-Copilot-Studio-Licensing-Guide-May-2026-PUB.pdf).

**M365 Copilot licensed users** consume zero credits for all features when operating under their authenticated M365 Copilot identity (subject to fair-use limits).

**Voice agents** (introduced in the May 2026 Licensing Guide) are billed by **total call length to the nearest second** plus the configured voice orchestration. Voice agents are **not modeled** in this tool — estimate them separately.

**Agent Builder and SharePoint agents** using pay-as-you-go: billing is configured in the Microsoft 365 admin center and billed to the linked Azure subscription under Microsoft 365 Copilot pay-as-you-go — not Copilot Studio meters.

### Azure Foundry agents

Source: [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/) · [Foundry Agent Service overview](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)

Billed by tokens (input + output) to your Azure subscription. Context accumulates each turn — every user message re-sends the full conversation history as input, so costs grow with conversation length.

Selected models (Global Standard pay-as-you-go, USD / 1M tokens):

| Model | Input | Output |
|---|---|---|
| GPT-4.1-nano | $0.10 | $0.40 |
| GPT-4o mini | $0.15 | $0.60 |
| GPT-5-nano | $0.05 | $0.40 |
| GPT-5-mini | $0.25 | $2.00 |
| GPT-5.1-codex-mini | $0.25 | $2.00 |
| GPT-4.1-mini | $0.40 | $1.60 |
| GPT-4.1 | $2.00 | $8.00 |
| GPT-4o (2024-11-20) | $2.50 | $10.00 |
| o4-mini | $1.10 | $4.40 |
| o3 | $2.00 | $8.00 |
| GPT-5 (2025-08-07) | $1.25 | $10.00 |
| GPT-5.1 | $1.25 | $10.00 |
| GPT-5.2 | $1.75 | $14.00 |
| GPT-5.3 | $1.75 | $14.00 |
| GPT-5.4-nano | $0.20 | $1.25 |
| GPT-5.4-mini | $0.75 | $4.50 |
| GPT-5.4 (<272k ctx) | $2.50 | $15.00 |
| GPT-5.4 Pro (<272k ctx) | $30.00 | $180.00 |

Built-in tools: File Search $2.50/1K calls · Code Interpreter $0.033/session.

---

## Other resources

- [Microsoft agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) — for monthly *production* usage forecasting
- [Overage enforcement](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#overage-enforcement)
- [Cost considerations for M365 Copilot extensibility](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/cost-considerations)
- [M365 Copilot pay-as-you-go overview](https://learn.microsoft.com/en-us/copilot/microsoft-365/pay-as-you-go/overview)


> **1 Copilot Credit = $0.01 USD**

The [Microsoft agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) forecasts monthly production usage. This tool does the opposite — it calculates the cost of your **test plan** based on individual conversations, so you can budget before you start testing.
