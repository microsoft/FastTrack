# Copilot & Foundry Agent Cost Calculator — Walk-Through Guide

> Open `index.html` in any modern browser (Edge, Chrome, Firefox). No account, server, or login required.

---

> ## ⚠️ Important Disclaimer — Please Read First
>
> **This tool produces planning estimates only. It is not a quote, a billing commitment, a contractual obligation, or a guarantee of any kind.**
>
> Figures are USD list-price assumptions, excluding taxes, currency conversion, and negotiated discounts. Actual charges can and will differ, because:
>
> - **Runtime behavior varies.** Agents may use more or fewer operations, tokens, or tools than you modeled.
> - **Licensing and billing rules are conditional.** Licence coverage, test exemptions, and capacity enforcement depend on channel, identity, harness, and configuration.
> - **Pricing changes.** Copilot Credit rates were reviewed on 28 September 2026. Foundry numeric prices are a historical May 2026 snapshot or values you enter; they were not reverified.
>
> **Do not use this tool to make contractual cost commitments.** Use it to build intuition, compare options, and set a planning baseline. Validate against actual consumption before purchasing.

---

## Before You Start: What is This Tool?

This calculator estimates what a Microsoft Copilot or Microsoft Foundry agent will cost to **run in production for a month** or to **test with a suite of scenarios**, and what that means for **purchase commitments** such as credit packs or pre-purchase plans.

The key idea in version 2: **count billable operations, not user turns.** One user turn can trigger several meters (for example, a graph-grounded generative answer plus an agent action). You describe what one conversation or run actually does, and the tool multiplies it by your workload.

---

## 5-Minute Quick Start

1. Open `index.html` in a browser.
2. In **1. Agent and billing scope**, pick a **Quick start template** (for example, *Enterprise FAQ agent*).
3. In **2. Forecast period and workload**, choose *Production forecast – one month* or *Test budget – one suite* and enter your numbers.
4. Read the results panel: runs, billable credits, PAYG-equivalent value, and purchase commitment.
5. Check the **Cost trace and assumptions** table, then **Export CSV** or **Print snapshot**.

If an input is missing or invalid, the tool shows **Estimate unavailable** with the list of fixes instead of a misleading zero.

---

## Understanding the Layout

```
1. Agent and billing scope
2. Forecast period and workload
3. Licence eligibility            (Standard, Agent Builder, SharePoint)
4. Billable operations per run    (Standard, Agent Builder, SharePoint)
   or GitHub Copilot harness task budget
   or Microsoft Foundry model, tokens and tools
5. Separately billed integrations
6. Purchase commitment and available capacity
        ↓
Results · Purchase economics · Credit distribution · Capacity impact
Cost trace and assumptions
Billing references, voice reference, and sources
```

The header has a **Dark / Light** theme selector and **Start Over**.

---

## Step-by-Step Walkthrough

### 1. Agent and billing scope

| Option | What it is | Billing model |
|---|---|---|
| **Copilot Studio – Standard harness** | Custom agent with topics, tools, flows, prompts | Copilot Credits per feature meter |
| **Agent Builder – Copilot Chat harness** | Declarative agent built in Agent Builder | Copilot Credits; non-graph generative responses are exempt |
| **SharePoint agent** | Agent created from a SharePoint site | Copilot Credits for counted responses and graph messages |
| **Copilot Studio – GitHub Copilot harness** | Copilot Studio agents built on the GitHub Copilot harness | Measured all-in credits per task; no per-feature tariff |
| **Microsoft Foundry agent** | Azure-hosted prompt or hosted (container) agent | Azure USD for tokens, tools, and infrastructure |

> The GitHub Copilot harness is Copilot Studio technology, not a GitHub Copilot subscription. Standard feature rates must not be applied to it.

**Quick start templates** fill in an illustrative operation profile. Selecting one keeps your estimate mode and resets everything else to defaults first.

| Template | Best for |
|---|---|
| Enterprise FAQ agent | Graph-grounded FAQ answers from SharePoint and connectors |
| HR policy agent | Internal policy knowledge with mostly graph-grounded answers |
| IT helpdesk with tools + flows | Agents that call tools, run a flow, use a prompt, and a reasoning model |
| Employee Self-Service – HR | ServiceNow HRSD + Workday scenarios with two flows |
| Employee Self-Service – IT | ServiceNow ITSM + Microsoft Self-Help with a reasoning step |
| Foundry general assistant | GPT-4o (historical rates) with file search |
| Foundry code assistant | GPT-4.1 (historical rates) with Code Interpreter |

---

### 2. Forecast period and workload

| Mode | Runs formula |
|---|---|
| **Production forecast – one month** | Active users × conversations per user per active day × active days + additional autonomous runs |
| **Test budget – one suite** | Distinct test scenarios × iterations per scenario |

For the Standard harness in test mode, choose the **test surface**:

- **Published endpoint** – normal meters apply.
- **Embedded maker test chat / designer** – core Standard-harness usage, topic prompts, and flow-action capacity are excluded. AI tools inside flows, Work IQ, and excluded-feature allowances still count.

Foundry and GitHub Copilot harness testing is always billable. Annual purchase projections repeat the production month 12 times; seasonality is not inferred.

---

### 3. Licence eligibility (not a blanket discount)

- Choose the **channel / audience**. *External / other / unauthenticated* receives no licence reduction.
- Enter the **share of usage** (not headcount) covered by a licensed Microsoft Copilot user.
- Tick the confirmation that covered usage is employee-facing, in eligible Microsoft channels, under the licensed user's authenticated identity. A non-zero share without this confirmation blocks the estimate.

The share reduces **only eligible meter rows**. Work IQ APIs, computer use, external services, and independently triggered agent flows stay billable. Fair-use limits apply. A Microsoft Copilot licence does not cover the GitHub Copilot harness.

---

### 4. Billable operations in one conversation or run

Describe what **one run** actually does. Knowledge sources are recorded as a **planning inventory** only; they do not add a charge by themselves.

| Field | Meter |
|---|---|
| **Generative responses per run** | 2 credits each (Agent Builder: only graph-grounded ones are billed) |
| **Tenant graph-grounded messages per run** | +10 credits each; must not exceed generative responses |
| **Classic responses per run** *(Standard)* | 1 credit each |
| **Agent actions per run** *(Standard)* | 5 credits each; exclude flow invocations counted below |

**Standard harness only:**

| Section | How it is charged |
|---|---|
| **Prompt tools in topics or actions** | Invocations × started 1K tokens (input + output) × tier rate: basic 0.1, standard 1.5, premium 10 |
| **Reasoning-model usage** | Invocations × started 1K tokens × premium rate (10), in addition to the core operation |
| **Agent flows** | Invocation: 5 credits (generative) or 1 credit (topic), plus 13 credits per 100 executed actions. Independent/scheduled flows are not licence-covered |
| **AI tools inside agent flows** | Token-metered prompts and 8 credits per page/image; billable even in designer tests |
| **Document/image processing** | 8 credits per page or image outside flows |
| **Computer use / other excluded features** | A measured all-in credit allowance; never licence-zero-rated |

**Example:** 3 generative responses, all graph-grounded, plus 1 classic response = 3 × (2 + 10) + 1 = **37 credits per run**.

---

### 4. GitHub Copilot harness: measured task budget *(when selected)*

| Field | What to enter |
|---|---|
| **Measured all-in Copilot Credits per task** | Observed or explicitly assumed credits including model, runtime, context, and tools. Required. |
| **LLM authoring / evaluation credits for this period** | Creation, preview, testing, and evaluation budget |
| **Measurement source / assumption note** | Required, for example a dated monitoring report |

---

### 4. Microsoft Foundry model, tokens and tools *(when selected)*

**Model and rates**

- **Foundry hosting:** managed prompt agent, or hosted agent (container compute also required).
- **Model:** legacy models load a historical May 2026 Global Standard rate. Newer models (GPT-5.3, 5.5, 5.6, GPT-6 families) and *Other / negotiated quote* require you to enter rates.
- **Deployment type** and **context tier:** Data Zone, Regional, and long-context selections clear the preset; enter quoted rates.
- **Exact model/version, region, rate source, and rate date** are required. Editing a preset rate clears the "historical" source so you record your own.

**Tokens per turn**

| Field | Meaning |
|---|---|
| System instruction and tool schema tokens | Sent with every model call |
| User, retrieved, and tool-result tokens | Per turn / per model call |
| Visible output and reasoning output tokens | Billed as output; only visible output is carried into later turns |
| Model calls per turn | Include retries and tool-loop calls |
| History mode | Full history, sliding window, or stateless |
| Cache share | Percentage of input served from cache (requires a cached-input rate) |

If peak input context exceeds a model's short-context tier (for example 272K tokens for GPT-5.4), the tool asks you to select long context and enter its rates.

**Built-in tools:** file-search calls (Responses API) and Code Interpreter sessions. A session is not a tool call; reuse can make it fractional.

**Infrastructure for the period:** hosted compute hours and rate, vector storage GB and retention days, search infrastructure, and monitoring allowances. **Zero means not estimated**, and the results show a warning.

---

### 5. Separately billed integrations

| Field | Rate |
|---|---|
| Work IQ Tools API calls per run | 0.1 credit per call |
| Measured Work IQ Chat/Context credits per run | Variable; enter measured consumption |
| Other Azure / third-party costs (USD/period) | Explicit allowance: Bing grounding, Dataverse overage, APIs, networking |

Work IQ remains billable for licensed users, including when called from Foundry.

---

### 6. Purchase commitment and available capacity

**Purchase scenario** (assumes a new, unused plan for this workload only):

| Option | Terms |
|---|---|
| PAYG | $0.01 per credit |
| Credit pack | $200/month per 25,000 credits, billed annually; unused monthly credits expire |
| Copilot Credit P3 (9 tiers) | 3,000–3,000,000 CCCUs/year, 5%–20% discount; one-year upfront |
| Agent P3 (3 tiers) | 20,000 / 100,000 / 500,000 ACUs/year, 5% / 10% / 15% discount; for Foundry, enter the eligible share of charges |

Discounts do not stack. Reservations apply before P3, and Copilot Credit P3 before Agent P3.

**Capacity monitoring** (independent of the purchase comparison): enter the full applicable monthly prepaid pool and credits already consumed. Tick **PAYG overflow is actually configured** only if it is.

- Standard harness: agents can be disabled at **125%** of prepaid capacity; billable agent flows can be blocked at **100%**.
- GitHub Copilot harness: credit-dependent experiences can stop at **100%**; no 125% grace is assumed.
- With PAYG configured, overage is billed rather than stopped.

---

## Results

| Section | What it tells you |
|---|---|
| **Summary boxes** | Runs, billable credits, Azure/external charges, PAYG-equivalent value, allocated usage value under the selected plan, and full purchase commitment |
| **Purchase economics** | Commitment, period outlay, overflow, unused pool, utilisation, and annual projections (production mode only) |
| **Billable credit distribution** | Bars showing which meters drive cost |
| **Capacity impact** | Projected consumption against your prepaid pool and the enforcement policy that applies |
| **Cost trace and assumptions** | Every meter with count, rate, gross, treatment (licence-covered, test-exempt, or separately billable), and per-period totals; Foundry token and Azure cost trace |
| **Assumption / scope banners** | Warnings such as zero infrastructure allowances or unconfirmed PAYG |

> *Allocated usage value* is not an invoice, and *consumption value* is not the cash you must purchase.

---

## Common Scenarios and Tips

### "I just want a rough number fast"
Pick the closest template, set the workload in step 2, and read the summary boxes.

### "Our agent calls an API every time someone asks a question"
Add one **agent action** (5 credits) per call. Add a generative response only if the agent actually returns one.

### "Some users have Microsoft Copilot licences"
Enter the share of **usage** from those users in step 3 and tick the eligibility confirmation. Only eligible meter rows are reduced.

### "We haven't decided on a pricing model"
Switch between PAYG, credit packs, and P3 tiers in step 6. Credits stay the same; commitment, allocated value, and unused pool change.

### "We're testing in the Copilot Studio test pane"
Choose *Test budget* and the *Embedded maker test chat / designer* surface. AI tools inside flows still count.

### "Our agent runs on Foundry"
Select **Microsoft Foundry agent**, confirm or enter current rates with a dated source, set token sizes and history mode, and add infrastructure allowances for anything you want estimated.

---

## Exporting and Sharing Results

**Export CSV** downloads the version, review date, disclaimer, every input, results, purchase economics, the credit and Foundry traces, warnings, and sources. It is available only when the estimate is valid.

**Print snapshot** produces a printer-friendly page you can save as PDF.

Inputs are not saved by the page. The page loads the Microsoft Clarity analytics tag when online, so avoid entering confidential information into notes.

---

## Glossary

| Term | Plain-language definition |
|---|---|
| **Copilot Credit** | Billing unit for Copilot Studio, Agent Builder, SharePoint agents, and Work IQ APIs. $0.01 at PAYG. |
| **Harness** | The Copilot Studio runtime an agent uses (Standard, Copilot Chat, or GitHub Copilot). Each bills differently. |
| **Generative answer** | An AI-generated response. 2 credits. |
| **Classic answer** | A scripted, authored response. 1 credit. |
| **Agent action** | A tool call, trigger, or topic transition. 5 credits. |
| **Tenant graph grounding** | Microsoft Graph semantic search for a message. +10 credits. |
| **Agent flow** | A Copilot Studio flow. Invocation credit plus 13 credits per 100 executed actions. |
| **AI tool tier** | Token rate for prompts: basic 0.1, standard 1.5, premium 10 credits per 1K tokens. |
| **Token** | Billing unit for models. About 4 English characters. |
| **CCCU / ACU** | Commit units for Copilot Credit P3 (100 credits) and Agent P3 ($1 of eligible usage). |
| **PAYG-equivalent value** | What the workload would cost at list PAYG rates. |
| **Overage enforcement** | Standard agents can be disabled at 125% of prepaid capacity unless PAYG is configured. |

---

## Reference Links

- [Copilot Studio billing rates and management](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management)
- [AI tools and token units](https://learn.microsoft.com/en-us/ai-builder/message-management)
- [Compare Copilot Studio harnesses](https://learn.microsoft.com/en-us/microsoft-copilot-studio/harnesses-overview)
- [GitHub Copilot harness billing](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/billing-credit-overview)
- [Agent flows](https://learn.microsoft.com/en-us/microsoft-copilot-studio/flows-overview)
- [Copilot Credit P3](https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/copilot-credit-p3) · [Agent P3](https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/agent-pre-purchase)
- [Foundry Agent Service overview](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)
- [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/azure-openai/)
- [Microsoft agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/)

---

## Legal & Disclaimer Notice

This tool is provided for **planning and estimation purposes only**. It does not constitute a contract, quote, invoice, or billing commitment of any kind. Microsoft's actual pricing, licensing terms, and billing behavior are governed solely by the applicable Microsoft Customer Agreement, Product Terms, and Azure pricing pages in effect at the time of use.

Copilot Credit billing content was reviewed on **28 September 2026**. Foundry numeric rates are historical (May 2026) or user-supplied and were not reverified. Rates are subject to change without notice.

*Last updated: September 2026 — aligned with calculator v2.0.0*
