# M365 Copilot Agents Cost Calculator

A self-contained, browser-based cost estimator for Microsoft 365 Copilot agents.
Open `AgentCosTest.html` in any modern browser — no server, no dependencies, no login required.

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

1. Open `AgentCosTest.html` in a browser.
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

## What makes this tool different from Microsoft's official estimator

Microsoft provides the [Copilot Studio agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) for Copilot Credits forecasting.
Here is what this tool covers that theirs does not:

| Capability | This tool | Microsoft's estimator |
|---|---|---|
| Azure Foundry / token-based agents | **Yes** | No |
| Per-turn cost trace with credit breakdown | **Yes** | No |
| Dollar cost display (not just credits) | **Yes** | Credits only |
| SharePoint / Agent Builder agent types | **Yes** | No |
| Quick-start templates (pre-filled configs) | **Yes** | Category filter only |
| Reasoning model surcharge modelled | **Yes** | Not explicit |
| CSV export + Print snapshot | **Yes** | Download results |
| Pay-as-you-go vs Credit pack vs CC P3 vs Agent P3 comparison | **Yes** *(all 4 plans incl. May 2026 Agent P3)* | No |

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

The [Microsoft agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) forecasts monthly production usage. This script does the opposite — it calculates the cost of your **test plan** based on individual conversations, so you can budget before you start testing.

---

## Prerequisites

- **PowerShell 7+** (the script uses `#Requires -Version 7.0`)
  - Check your version: `$PSVersionTable.PSVersion`
  - If you need to install it: `winget install Microsoft.PowerShell`
- No modules or authentication required — everything runs locally

---

## Quick Start

### Option A: Interactive Mode (guided prompts)

```powershell
.\Estimate-CopilotStudioTestCost.ps1
```

The script will walk you through each test scenario step by step.

### Option B: Batch Mode (from a CSV file)

```powershell
.\Estimate-CopilotStudioTestCost.ps1 -ScenarioFile .\sample-test-plan.csv -PrepaidCredits 25000
```

---

## Step-by-Step Guide: Interactive Mode

### Step 1 — Open a terminal and navigate to the script

```powershell
cd path\to\copilot-studio-test-cost
```

### Step 2 — Run the script

```powershell
.\Estimate-CopilotStudioTestCost.ps1
```

### Step 3 — Enter your prepaid capacity (optional)

The script asks for your monthly prepaid Copilot Credits. This lets it show what percentage of your capacity testing will consume. Enter `0` to skip.

```
Monthly prepaid Copilot Credits - enter 0 to skip capacity check [0]: 25000
```

### Step 4 — Define your first test scenario

Give the scenario a descriptive name:

```
Scenario name: FAQ flow test
```

### Step 5 — Enter the features used in ONE test conversation

For each feature, enter how many times it fires in a single conversation. Press Enter to accept the default of `0`.

```
Classic answers [0]: 2
Generative answers [0]: 3
Agent actions - triggers / topic transitions / deep reasoning [0]: 1
Tenant graph grounded messages [0]: 0
Agent flow actions - note: FREE in test pane [0]: 0
AI prompt tool calls - basic tier [0]: 0
AI prompt tool calls - standard tier [0]: 0
AI prompt tool calls - premium tier [0]: 0
Content processing pages [0]: 0
Uses reasoning model? [y/N]: n
```

> **Tip**: If you're unsure what counts as each feature, open your agent in Copilot Studio, run a test conversation, and check the **activity map** — each step shown there maps to the features above.

### Step 6 — Enter the number of iterations

How many times will this scenario be run? Count all testers and all passes (e.g., 3 testers × 2 passes = 6).

```
How many times will you run this scenario? [1]: 10
```

### Step 7 — Add more scenarios or finish

```
Add another scenario? [y/N]: y
```

Repeat steps 4–6 for each scenario. When done, enter `n`.

### Step 8 — Review the results

The script outputs a summary with:

- **Per-scenario breakdown** — credits per conversation × iterations
- **Feature breakdown** — which features drive the most cost
- **Capacity impact** — percentage of your monthly prepaid credits consumed by testing

---

## Step-by-Step Guide: Batch Mode (CSV)

### Step 1 — Create your test plan CSV

Copy `sample-test-plan.csv` and edit it with your scenarios. The columns are:

| Column | What it means | Example |
|---|---|---|
| `ScenarioName` | Description of the test case | `FAQ flow test` |
| `ClassicAnswers` | Static/authored responses per conversation | `2` |
| `GenerativeAnswers` | AI-generated responses per conversation | `3` |
| `AgentActions` | Triggers, topic transitions, deep reasoning steps | `1` |
| `TenantGraphMessages` | Messages using tenant graph grounding | `0` |
| `AgentFlowActions` | Flow actions (FREE in test pane — tracked for awareness) | `0` |
| `BasicPrompts` | Basic-tier AI prompt tool calls | `0` |
| `StandardPrompts` | Standard-tier AI prompt tool calls | `0` |
| `PremiumPrompts` | Premium-tier AI prompt tool calls | `0` |
| `ContentPages` | Pages processed by content processing tools | `0` |
| `UsesReasoningModel` | `1` if reasoning model is enabled, `0` otherwise | `0` |
| `Iterations` | Total times this scenario will be run (testers × passes) | `10` |

**Example row:**

```csv
FAQ flow test,2,3,1,0,0,0,0,0,0,0,10
```

### Step 2 — Run the script with your CSV

```powershell
.\Estimate-CopilotStudioTestCost.ps1 -ScenarioFile .\my-test-plan.csv
```

### Step 3 — Add prepaid capacity (optional)

To see the capacity impact:

```powershell
.\Estimate-CopilotStudioTestCost.ps1 -ScenarioFile .\my-test-plan.csv -PrepaidCredits 25000
```

---

## Understanding the Output

```
===============================================================
  COPILOT STUDIO - TEST COST ESTIMATE
===============================================================

  Scenario Breakdown:
  -------------------------------------------------------------
  Scenario                       Per Conv  Iter.    Credits        USD
  -------------------------------------------------------------
  Greeting and FAQ                      9      5         45      $0.45
  Knowledge retrieval (ShareP...       16     10        160      $1.60
  ...
  TOTAL                                                2072     $20.72
```

| Column | Meaning |
|---|---|
| **Per Conv** | Credits consumed by one execution of the scenario |
| **Iter.** | Total number of times the scenario runs |
| **Credits** | Per Conv × Iter. |
| **USD** | Credits × $0.01 |

The **Credit Breakdown by Feature** section shows which features cost the most — useful for identifying where to optimize.

The **Capacity Impact** section (when you provide `-PrepaidCredits`) shows:
- What percentage of your monthly allocation testing will use
- How many credits remain for production
- The overage enforcement threshold (125% of capacity)

---

## How to Count Features in Your Agent

Not sure what numbers to enter? Here's how to figure it out:

1. **Open your agent** in Copilot Studio
2. **Run a test conversation** in the test pane
3. **Check the activity map** — each step maps to a feature:

| What you see in the activity map | Feature to count |
|---|---|
| A static, authored response | Classic answer |
| An AI-generated answer from knowledge | Generative answer |
| A trigger firing, topic transition, or deep reasoning step | Agent action |
| A response grounded in Microsoft Graph tenant data | Tenant graph grounding |
| A flow executing a sequence of steps | Agent flow action (free in test pane) |
| A prompt tool running (check the tier in Prompt Builder) | Basic / Standard / Premium prompt |
| Document/image processing | Content processing (per page) |

4. **Check if reasoning is enabled** — in your agent's model settings, if a reasoning-capable model is selected, set `UsesReasoningModel` to `1`

---

## Billing Rates Reference

Source: [Copilot Credits billing rates](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)

| Feature | Credits | Unit | Free in Test Pane? |
|---|---|---|---|
| Classic answer | 1 | per response | No |
| Generative answer | 2 | per response | No |
| Agent action | 5 | per action | No |
| Tenant graph grounding | 10 | per message | No |
| Agent flow actions | 13 | per 100 actions | **Yes** |
| AI tools (basic) | 1 | per 10 responses | No |
| AI tools (standard) | 15 | per 10 responses | No |
| AI tools (premium) | 100 | per 10 responses | No |
| Content processing | 8 | per page | No |

**Reasoning model surcharge**: When enabled, adds 10 credits per generative answer response (100 credits / 10 responses) on top of the base rate.

---

## Tips to Reduce Test Costs

- **Start without tenant graph grounding** — at 10 credits/message, it's the most expensive per-unit feature. Test your agent's core logic first, then enable graph grounding for a final validation pass.
- **Test with standard models first** — if your agent uses a reasoning model, switch to standard for initial testing (2 credits vs 12 credits per generative answer). Use reasoning only for final QA.
- **Prioritize critical paths** — don't iterate every scenario equally. Run edge cases 2–3 times, but run your happy path and critical flows more.
- **Leverage free flow testing** — agent flow actions don't consume credits in the test pane, so test flows thoroughly before publishing.
- **Combine similar scenarios** — if two test cases exercise the same features, merge them to reduce overhead.
