---
title: Agents Cost Calculator
type: strategy
category: Interactive
summary: >-
  Estimate production, test, and purchase-commitment costs for Copilot Studio, Agent Builder,
  SharePoint, and Foundry agents.
author: Microsoft FastTrack
version: 2.0.0
published: "2026-04-01"
updated: "2026-09-28"
tags:
  - cost
  - roi
  - calculator
format: interactive
featured: true
whatItIs: >-
  A self-contained browser calculator that models Copilot Credits, Microsoft Foundry token and
  infrastructure costs, and purchase commitments for Copilot Studio (Standard and GitHub Copilot
  harnesses), Agent Builder, SharePoint, and Microsoft Foundry agents. It separates consumption
  value from purchase commitments and shows a dated source for every rate.
whyUseIt:
  - Forecast a monthly production workload or budget a single test suite from counted billable operations.
  - Compare PAYG, credit packs, Copilot Credit P3, and Microsoft Agent P3 without mixing consumption with commitment.
  - Trace every meter, licence exclusion, and test exemption, then export the scenario to CSV or print it.
howToUse: |-
  1. Open `index.html` in a browser.
  2. Choose the agent or harness, the estimate mode (production month or test suite), and optionally a quick-start template.
  3. Enter licence eligibility, billable operations per run (or Foundry tokens/tools, or measured GitHub Copilot harness task credits), integrations, and a purchase scenario.
  4. Review the results, purchase economics, capacity impact, and cost trace, then export CSV or print.
prerequisites:
  - Modern web browser
  - Current licensing and pricing inputs for planning validation
---

# Copilot & Foundry Agent Cost Calculator

A self-contained, browser-based cost estimator for Microsoft Copilot and Microsoft Foundry agents.
Open `index.html` in any modern browser. No server, build step, or login is required.

> **This tool produces planning estimates only. Results are not a quote or billing commitment.**
> Figures are USD list-price assumptions, excluding taxes, currency conversion, and negotiated
> discounts. Runtime behavior, licensing, billing aggregation, and service availability can change
> the outcome. Validate against actual consumption before purchasing.

**Version 2.0.0** · Billing content reviewed 28 September 2026. Foundry numeric rates are a
historical May 2026 snapshot or user-supplied values; they were not reverified in this review.

---

## What's new in 2.0.0

- **Operation-based model.** You count billable operations per conversation or run (generative
  responses, graph-grounded messages, classic answers, agent actions, flows, prompts). Knowledge
  sources are a planning inventory only; they no longer add a fixed charge per "lookup turn".
- **Production and test modes.** Forecast one production month (users × conversations × active days
  + autonomous runs) or budget one test suite (scenarios × iterations). Standard-harness embedded
  maker tests apply the documented test exclusions.
- **Harness-aware agent types.** Copilot Studio Standard harness, Copilot Studio GitHub Copilot
  harness (measured all-in credits per task), Agent Builder, SharePoint agent, and Microsoft Foundry.
- **Token-metered AI tools and reasoning.** Prompt tools and reasoning models use credits per started
  1,000 tokens (basic 0.1, standard 1.5, premium 10) instead of a flat per-call surcharge.
- **Licence eligibility, not a blanket discount.** The covered share applies only to eligible meter
  rows, only for Microsoft employee-facing channels, and requires an explicit confirmation.
- **Purchase economics.** PAYG, credit packs, 9 Copilot Credit P3 tiers, and 3 Microsoft Agent P3
  tiers, with commitment, allocated usage value, unused pool, and annual projections.
- **Richer Foundry model.** Model calls per turn, history mode (full, sliding window, stateless),
  prompt caching, reasoning tokens, hosted-agent compute, vector storage, search, and monitoring
  allowances. Newer models require you to enter rates rather than using invented prices.
- **Work IQ and external costs.** Work IQ Tools API (0.1 credit per call), measured Work IQ
  Chat/Context credits, and an explicit allowance for other Azure or third-party costs.
- **Validation and provenance.** Invalid or missing inputs block the estimate rather than showing a
  misleading zero. Every rate source has a review date and confidence note.

---

## What it covers

| Agent / harness | Billing model |
|---|---|
| **Copilot Studio – Standard harness** | Copilot Credits: generative and classic answers, agent actions, tenant graph grounding, token-metered prompt tools and reasoning, agent flows, AI tools inside flows, content processing, and measured excluded-feature allowances |
| **Agent Builder – Copilot Chat harness** | Copilot Credits: generative + tenant graph meters for graph-grounded responses; non-graph generative responses are exempt |
| **SharePoint agent** | Copilot Credits: explicitly counted generative responses and graph-grounded messages (no automatic Agent Builder exemption) |
| **Copilot Studio – GitHub Copilot harness** | Measured all-in Copilot Credits per task plus an LLM authoring/evaluation budget; standard feature tariffs and Copilot licence zero-rating do not apply |
| **Microsoft Foundry agent** | Azure USD: input (uncached/cached) and output tokens, built-in tools, and optional infrastructure allowances; Work IQ API calls add a separate Copilot Credit ledger |

---

## How to use

1. Open `index.html` in a browser.
2. **Agent and billing scope:** choose the agent or harness, and optionally a quick-start template.
3. **Forecast period and workload:** choose *Production forecast – one month* or *Test budget – one
   suite* and enter users/conversations or scenarios/iterations.
4. **Licence eligibility:** enter the share of *usage* (not headcount) covered by a Microsoft Copilot
   licence and confirm eligibility. External or unauthenticated channels receive no reduction.
5. **Billable operations per conversation or run** (Standard, Agent Builder, SharePoint), **measured
   task budget** (GitHub Copilot harness), or **model, tokens, and tools** (Foundry).
6. **Separately billed integrations:** Work IQ APIs and other Azure or third-party allowances.
7. **Purchase commitment and capacity:** choose a purchase scenario and optionally enter your
   applicable prepaid pool and existing consumption.
8. Review the results panel, **Purchase economics**, **Billable credit distribution**, **Capacity
   impact**, and the **Cost trace and assumptions** table.
9. Use **Export CSV** or **Print snapshot**. **Start Over** resets all inputs.

See [GUIDE.md](./GUIDE.md) for a step-by-step walk-through.

---

## Quick-start templates

Templates are illustrative workloads, not observed usage or licensing recommendations. Selecting a
template keeps the current estimate mode and resets other inputs to defaults first.

| Template | Agent type | Per-run operations modeled |
|---|---|---|
| Enterprise FAQ agent | Standard harness | 3 generative (3 graph-grounded), 1 classic |
| HR policy agent | Standard harness | 4 generative (3 graph-grounded), 1 classic |
| IT helpdesk with tools + flows | Standard harness | 3 generative (2 graph), 1 classic, 2 actions, 1 prompt, 1 flow × 12 actions, 1 reasoning call |
| Employee Self-Service – HR | Standard harness | 4 generative (2 graph), 1 classic, 3 actions, 1 prompt, 2 flows × 18 actions |
| Employee Self-Service – IT | Standard harness | 3 generative (2 graph), 1 classic, 3 actions, 1 prompt, 1 flow × 22 actions, 1 reasoning call |
| Foundry general assistant | Foundry | Historical GPT-4o rates, 600-token system prompt, 3 file-search calls |
| Foundry code assistant | Foundry | Historical GPT-4.1 rates, 6 turns, 2 Code Interpreter sessions |

---

## Billing rates reference

Rates below are the values used by the calculator, reviewed 28 September 2026. Always confirm
current rates with the linked sources.

### Copilot Credits (Standard and Copilot Chat harnesses)

Source: [Copilot Studio billing rates and management (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management)

| Meter | Rate | Notes |
|---|---|---|
| Classic answer | 1 credit / response | Standard harness |
| Generative answer | 2 credits / response | Agent Builder non-graph responses exempt |
| Agent action | 5 credits / action | No automatic extra generative answer |
| Tenant graph grounding | 10 credits / message | Only actual graph-grounded messages |
| Agent-flow actions | 13 credits / 100 executed actions | Flow invocation also adds 5 (generative) or 1 (topic) credits |
| AI tools – basic / standard / premium | 0.1 / 1.5 / 10 credits per 1K tokens | Input + output tokens; started 1K units per invocation |
| Reasoning model | Premium token rate (10 credits / 1K tokens) | Additional to the core operation |
| Content processing | 8 credits / page or image | Capability-specific, not all document grounding |
| Work IQ Tools API | 0.1 credit / call | Not covered by a Copilot user licence |
| Work IQ Chat/Context API | Variable, measured | No universal per-query rate |

**GitHub Copilot harness:** there is no per-feature tariff. Supply measured all-in credits per task
([billing overview](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/billing-credit-overview)).

**Voice** (reference only, not in the numeric estimate): classic 10, GenAI 35, premium GenAI 75
credits per minute, measured to the nearest second.

### Purchase options

| Option | Terms |
|---|---|
| Pay-as-you-go | $0.01 per credit |
| Copilot Credit pack | $200/month for 25,000 credits, billed annually; monthly credits do not roll over |
| Copilot Credit P3 | 9 tiers, 3,000–3,000,000 CCCUs/year (1 CCCU = 100 credits), 5%–20% discount; one-year upfront, unused units expire |
| Microsoft Agent P3 | 3 tiers, 20,000 / 100,000 / 500,000 ACUs/year, 5% / 10% / 15% discount; can cover eligible Copilot Studio and Foundry usage |

Discounts do not stack. Sources: [Copilot Studio Licensing Guide, September 2026](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/ai/Microsoft-Copilot-Studio-Licensing-Guide-September-2026.pdf) ·
[Copilot Credit P3](https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/copilot-credit-p3) ·
[Agent P3](https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/agent-pre-purchase)

**Licensed Microsoft Copilot users:** eligible Standard / Copilot Chat usage is zero-rated only for
employee-facing usage in eligible Microsoft channels under the licensed user's authenticated
identity, subject to fair use. Work IQ APIs, computer use, external services, and independently
triggered agent flows remain billable.

### Microsoft Foundry agents

Source: [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/azure-openai/) ·
[Foundry Agent Service overview](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)

Foundry presets are a **historical May 2026 Global Standard snapshot, not reverified**. Newer models
(for example GPT-5.3, GPT-5.5, GPT-5.6, and GPT-6 families) have no built-in price; enter a dated
Azure rate or quote. Data Zone, Regional, and long-context selections also require quoted rates.

| Historical preset | Input (USD / 1M) | Output (USD / 1M) |
|---|---|---|
| GPT-5 nano | $0.05 | $0.40 |
| GPT-4.1 nano | $0.10 | $0.40 |
| GPT-4o mini | $0.15 | $0.60 |
| GPT-5.4 nano | $0.20 | $1.25 |
| GPT-5 mini / GPT-5.1 codex mini | $0.25 | $2.00 |
| GPT-4.1 mini | $0.40 | $1.60 |
| GPT-5.4 mini | $0.75 | $4.50 |
| o4-mini | $1.10 | $4.40 |
| GPT-5 / GPT-5.1 | $1.25 | $10.00 |
| GPT-5.2 | $1.75 | $14.00 |
| GPT-4.1 / o3 | $2.00 | $8.00 |
| GPT-4o (2024-11-20) | $2.50 | $10.00 |
| GPT-5.4 (short context, ≤272K) | $2.50 | $15.00 |
| GPT-5.4 Pro (short context, ≤272K) | $30.00 | $180.00 |

Built-in tool baselines (May 2026, not reverified): File Search $2.50 / 1K calls (Responses API),
Code Interpreter $0.033 / session, vector storage $0.11 / GB-day after a 1 GB allowance. Hosted-agent
compute, search, and monitoring are user-entered allowances; zero means *not estimated*, not free.

---

## Not estimated

Dataverse storage overage, standalone Power Automate licensing, telephony and voice, provisioned
model throughput, networking, image/audio/video generation, support, implementation labor,
third-party subscriptions, and Microsoft Copilot user licence costs. Use the explicit allowance
fields or a separate estimate.

---

## Privacy

Inputs are not saved by the page. The page loads the Microsoft Clarity analytics tag when online.
Avoid entering confidential information into notes. Calculations run entirely in the browser.

---

## Other resources

- [Microsoft agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) — complementary scenario estimator for standard agents
- [Compare Copilot Studio harnesses](https://learn.microsoft.com/en-us/microsoft-copilot-studio/harnesses-overview)
- [Copilot Credits Guide, September 2026](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/ai/CopilotCreditsGuideSeptember2026.pdf)
- [Foundry model retirements](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirements)
