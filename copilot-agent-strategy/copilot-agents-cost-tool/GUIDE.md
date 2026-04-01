# M365 Copilot Agents Cost Calculator — Walk-Through Guide

> Open `index.html` in any modern browser (Edge, Chrome, Firefox). No account, server, or login required.

---

> ## ⚠️ Important Disclaimer — Please Read First
>
> **This tool produces planning estimates only. It is not a billing commitment, a contractual obligation, or a guarantee of any kind.**
>
> The numbers you see are based on simplified assumptions about how an agent behaves. Actual charges on your Microsoft or Azure invoice can and will differ — sometimes significantly — because:
>
> - **Runtime behavior varies.** The agent may take more or fewer turns, trigger different features, or follow different orchestration paths than you modeled.
> - **Tenant configuration matters.** Licensing, capacity pools, and feature availability affect how billing is applied.
> - **Model usage is dynamic.** Token consumption and credit usage change based on the content of real user conversations.
> - **Microsoft pricing and licensing terms can change.** Rates shown reflect Microsoft Learn documentation as of the date noted at the bottom of the calculator. Microsoft reserves the right to update pricing at any time.
>
> **Do not use this tool to make contractual cost commitments to customers, management, or finance.** Use it to build intuition, compare architectural options, and establish a planning baseline. Validate against actual Azure and Copilot Studio usage reports once the agent is running in production.

---

## Before You Start: What is This Tool?

This calculator helps you **estimate the cost of running a Microsoft 365 Copilot agent before you deploy it**. It models credits and dollars, not vague ranges — so you can plan budgets, compare options, and have an informed conversation with stakeholders.

Think of it like a flight-price estimator: the final fare depends on fuel surcharges, seat selection, and what actually happens at runtime. This tool gives you a solid planning baseline — not a receipt.

> **Key rule**: Outputs are planning estimates only. They carry no contractual weight and should not be treated as a billing guarantee.

---

## 5-Minute Quick Start (for anyone)

1. Open `index.html` in a browser.
2. At the top, pick a **Quick start template** from the drop-down (for example, *Enterprise FAQ agent*).
3. Scroll to the bottom — you will see an **Example Prompt & Cost Trace** and a **Production Cost Estimate** panel filled in automatically.
4. Adjust any number that doesn't match your real situation. The estimate refreshes instantly.
5. Click **Export CSV** to save the results, or **Print** for a PDF snapshot.

That's it. The template does most of the thinking for you.

> Remember: the number you see is a starting-point estimate. Your actual invoice will depend on real usage patterns, tenant configuration, and Microsoft's current pricing at the time of billing.

---

## Understanding the Layout

The tool is a single scrollable page divided into numbered steps. Each step feeds into the final estimate at the bottom.

```
[Agent Type]  →  [Knowledge Sources]  →  [Components]  →  [Conversation Profile]  →  [Test Scale]
                                                                       ↓
                                               [Example Prompt & Cost Trace]
                                               [Production Cost Estimate]
```

At the top right you can toggle between **Dark** and **Light** themes.  
The **⟳ Start Over** button resets everything to defaults.

---

## Step-by-Step Walkthrough

### ★  Agent Type — Start Here

**What to do**: Select the type of agent you are building.

| Option | What it is | Billing model |
|---|---|---|
| **Custom agent (Copilot Studio)** | Full-featured agent with topics, tools, flows, and AI prompts | Copilot Credits |
| **Agent Builder (M365 Copilot)** | Declarative agent built in Agent Builder — instructions + knowledge only | Copilot Credits (public website grounding is free) |
| **SharePoint agent** | Auto-created from a SharePoint site | Copilot Credits |
| **Foundry Agent (Azure AI)** | Azure-hosted agent billed by tokens, not credits | USD tokens via Azure subscription |

**Not sure which to pick?** If you are building in Copilot Studio and your agent has custom topics or can take actions (send emails, create tickets), pick *Custom agent*. If you simply connected a SharePoint site and let M365 Copilot surface it, pick *SharePoint agent*.

**Quick start template**: Below the agent type buttons there is a drop-down with ready-made configurations. Pick one and the rest of the form fills in automatically. Templates available:

| Template | Best for |
|---|---|
| Enterprise FAQ agent | Internal FAQ scenarios using SharePoint + enterprise connectors |
| HR policy agent | Pure internal knowledge (SharePoint, uploaded files) |
| IT helpdesk with tools + flows | Complex agents with tool calls and automated flows |
| General purpose assistant (GPT-4o) | Foundry agents answering questions from uploaded files |
| Code assistant (GPT-4.1) | Foundry agents doing code review / generation |

---

### Step 1 — Knowledge Sources

**What are knowledge sources?** They are the data stores your agent searches to answer questions. Examples: a SharePoint site, uploaded policy documents, or a public website.

**What to do**: Check every data source your agent connects to, and set the count (number of sites, files, URLs, etc.) for reference.

> **Important**: The *count* of sources is for planning reference only — it does not change the credit cost. What matters is the *type* of source and how many lookup turns you configure in Step 3.

| Source | Cost per query turn | Notes |
|---|---|---|
| SharePoint / OneDrive | **12 credits** (with Tenant graph grounding) or 2 credits (without) | Tenant graph grounding enabled by default — leave it on for realistic estimates |
| Dataverse | **2 credits** | |
| Public websites | **2 credits** (or **free** for Agent Builder agents) | |
| Uploaded files | **2 credits** | |
| Enterprise data (Graph/Copilot connectors) | **12 credits** (graph-grounded) | Model these the same as SharePoint with graph on |

**Tenant graph grounding**: When you check SharePoint or Enterprise connectors, a sub-option appears: "Tenant graph grounding enabled." Leave this checked unless you specifically disabled it in your agent configuration. It adds 10 credits per query but dramatically improves answer quality.

---

### Step F — Foundry Agent Configuration *(only visible when Foundry Agent is selected)*

**What are tokens?** Language models charge by *tokens* — roughly 1 token ≈ 4 characters. Unlike Copilot Studio, Foundry agents have no concept of "credits"; they charge input and output tokens directly to your Azure subscription.

**What to do**: Fill in these fields.

| Field | What to enter | Example |
|---|---|---|
| **Model** | The AI model your agent uses | GPT-4o, GPT-4.1-nano |
| **System prompt size (tokens)** | How long your agent's instructions are | 500 for a simple agent, 2 000 for a detailed one |
| **Avg user message (tokens/turn)** | Typical length of a user question | 150 tokens ≈ ~600 characters |
| **Avg assistant response (tokens/turn)** | Typical length of the agent's reply | 400 tokens ≈ ~1 600 characters |
| **Turns per conversation** | How many back-and-forth exchanges happen | 5 turns |
| **File Search calls per conversation** | If your agent searches uploaded files | $2.50 per 1 000 calls |
| **Code Interpreter sessions per conversation** | If your agent writes and runs code | $0.033 per session |

> **Context accumulation explained** (non-technical): Each time a user sends a new message, the agent re-reads the entire conversation history. So a 5-turn conversation is not 5× the cost of 1 turn — it costs progressively more because each turn carries the weight of all previous turns.

---

### Step 2 — Topics, Tools, Prompts & Flows *(Copilot Studio agents only)*

These are the *capabilities* your agent has, not what it does in a single conversation. Think of this as configuring the agent's feature set.

| Field | What it means | Cost when triggered |
|---|---|---|
| **Authored (classic) topics** | Pre-written scripted responses (no AI involved) | 1 credit per trigger |
| **Tools / Connectors** | External API or service calls (create ticket, send email) | 5 credits (action) + 2 credits (AI response) = **7 credits** |
| **AI Prompt actions** | Prompt the AI to summarize, translate, classify, etc. | Basic: 0.1 cr / Standard: 1.5 cr / Premium: 10 cr |
| **Text & generative AI tools tier** | Quality level of the AI model used in prompts | Basic, Standard, or Premium |
| **Agent flows** | Automated multi-step task sequences | 7 credits base + 13 credits per 100 steps |
| **Actions per flow run** | Average number of steps in one flow execution | Used to calculate the per-run flow cost |
| **Uses reasoning model** | Whether the agent uses an advanced reasoning model | +10 credits on every generative answer and agent action |

**Content Processing** (optional step below components): If your agent reads or processes documents or images, enter how many pages it handles per conversation. Each page costs **8 credits**.

---

### Step 3 — Typical Test Conversation

This is where you describe what actually happens during a conversation — not what the agent *can* do, but what it *typically does* in a single test session.

**User turns per conversation** is calculated automatically as the sum of all turn types below it.

| Turn type | What it means | Credits used |
|---|---|---|
| **Knowledge lookups** | Agent searches a knowledge source | 2 cr (+ 10 if graph-grounded) |
| **Tool / Connector calls** | Agent calls an external system | 7 cr (5 action + 2 gen answer) |
| **AI Prompt runs** | Agent runs a prompt action | Depends on tier (Basic/Standard/Premium) |
| **Classic topic responses** | Agent returns a scripted answer | 1 cr |
| **Agent flow runs** | Agent triggers an automated workflow | 7+ cr depending on steps |

**Example**: A conversation with 2 knowledge lookups (SharePoint with graph) + 1 classic response =  
2 × 12 cr + 1 × 1 cr = **25 credits per conversation**.

> **Warning banner**: If you enter knowledge lookup turns but haven't checked any knowledge source in Step 1, the tool will show a warning. Those turns won't cost anything unless a source is enabled.

---

### Step 4 — Test Plan Scale

**What to do**: Describe the size of your test plan.

| Field | What to enter |
|---|---|
| **Distinct test scenarios** | The number of unique conversation scripts or test cases |
| **Iterations per scenario** | How many times you run each script (for consistency testing) |
| **Monthly prepaid credits** | Your tenant's monthly credit allowance (0 = not using prepaid) |
| **Pricing model** | Pay-as-you-go ($0.01/credit) or Prepaid pack ($0.008/credit) |
| **% users with M365 Copilot license** | If some users have M365 Copilot licenses, their interactions cost **zero credits** |

**Total test conversations** = Scenarios × Iterations.

**Prepaid vs. Pay-as-you-go**:
- Pay-as-you-go: $0.01 per credit, billed through Azure.
- Prepaid pack: $200 for 25 000 credits ($0.008/credit — 20% cheaper).

**M365 Copilot license impact**: If 50% of your users have M365 Copilot licenses, half of all interactions are free. The "% users with M365 Copilot license" field accounts for this in the estimate.

**Capacity overage**: If prepaid credits are configured, the tool shows a capacity bar. At **125% of prepaid**, custom agents are disabled by the platform. The bar turns yellow at 80% and red at 100%.

---

### Step 5 — Example Prompt & Cost Trace

This section is **read-only** — it is generated automatically from your configuration.

It shows a realistic sample conversation with:
- A user prompt for each turn type you configured.
- A breakdown of what the agent does in that turn.
- The exact credit cost of each step.
- A total for the full example conversation.

Use this to **sanity-check your setup**. If the trace looks wrong (e.g., the cost per conversation is unexpectedly high or low), review Step 3 and adjust the turn mix.

---

### Production Cost Estimate (Results Panel)

At the bottom of the page, the results panel shows:

| Section | What it tells you |
|---|---|
| **Summary boxes** | Total test conversations, credits per conversation, total credits, and estimated cost in dollars |
| **Credit breakdown** | Per-turn costs itemized by feature type (knowledge, actions, prompts, flows, etc.) |
| **Credit distribution chart** | Horizontal bars showing which features drive the most cost |
| **Capacity impact** | How testing compares to your monthly prepaid allocation (if configured) |
| **Export CSV / Print** | Save or share the results |
| **Start Over** | Reset everything |

> **When sharing results**: Always communicate clearly that the figures are planning estimates and not contractual cost commitments. Actual production costs depend on real conversation patterns, user volume, tenant configuration, and Microsoft's current pricing terms — none of which this tool can predict with certainty.

---

## Common Scenarios and Tips

### "I just want a rough number fast"
Pick a template that is closest to your use case, check whether the turn counts in Step 3 look right, update the test scale in Step 4, and read the dollar total. Done.

### "Our agent calls an API every time someone asks a question"
That is a *Tool / Connector call* turn. In Step 3, set "Tool / Connector calls" to the number of times the agent calls external systems per conversation. Each call costs 7 credits.

### "Some of our users have M365 Copilot licenses and some don't"
Use the "% users with M365 Copilot license" field in Step 4. Users with those licenses consume zero credits for all features.

### "We haven't decided on a pricing model yet"
Try both. Change the "Pricing model" in Step 4 between Pay-as-you-go and Prepaid pack. The credit count stays the same; only the dollar total changes.

### "The agent reads from multiple SharePoint sites"
Check **SharePoint / OneDrive** in Step 1 and set the number of sites for reference. The credit cost per lookup is still 12 credits (with graph) regardless of how many sites — the per-query cost comes from Step 3's knowledge lookup turns, not Step 1's source count.

### "Our agent uses a Foundry model, not Copilot Studio"
Select **Foundry Agent** as the agent type. The rest of the form changes to the Foundry configuration. Fill in Step F (model, token sizes, turns, built-in tools) and Step 4 (scale). The result will be in USD tokens, not credits.

---

## Exporting and Sharing Results

**Export CSV**: Downloads a flat file with all inputs and outputs — useful for sharing with finance or project stakeholders, or for tracking estimates over time.

**Print**: Renders a clean printer-friendly version of the full estimate. Save as PDF for asynchronous sharing.

---

## Glossary

| Term | Plain-language definition |
|---|---|
| **Copilot Credit** | The billing unit for Copilot Studio agents. 1 credit = $0.01 (PAYG) or $0.008 (prepaid). |
| **Generative answer** | An AI-generated response to a user query. Costs 2 credits. |
| **Classic answer** | A scripted, authored response (no AI). Costs 1 credit. |
| **Agent action** | A tool or connector call (e.g., create ticket, send email). Costs 5 credits. |
| **Tenant graph grounding** | Using Microsoft Graph semantic search for knowledge retrieval. Adds 10 credits per query. |
| **Agent flow** | An automated workflow defined in Copilot Studio. Costs 7 credits per run + steps. |
| **Reasoning model** | An advanced AI model that thinks through complex problems. Adds 10 credits per response. |
| **Token** | The unit of billing for Foundry agents. 1 token ≈ 4 characters in English. |
| **PAYG** | Pay-as-you-go pricing. You pay per credit consumed with no upfront commitment. |
| **Prepaid pack** | Purchase 25 000 credits for $200 upfront — 20% cheaper than PAYG. |
| **Overage enforcement** | When a tenant reaches 125% of prepaid capacity, custom agents are automatically disabled. |

---

## Reference Links

- [Copilot Credits billing rates (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)
- [Reasoning model billing (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#reasoning-model-billing-rates)
- [Cost considerations for extensibility (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/cost-considerations)
- [Foundry Agent Service overview (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)
- [Azure OpenAI pricing (azure.microsoft.com)](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/)
- [Production usage estimator (Copilot Studio)](https://microsoft.github.io/copilot-studio-estimator/)

---

---

## Legal & Disclaimer Notice

This tool is provided for **planning and estimation purposes only**. It does not constitute a contract, quote, invoice, or billing commitment of any kind. Microsoft's actual pricing, licensing terms, and billing behavior are governed solely by the applicable Microsoft Customer Agreement, Product Terms, and the Azure pricing pages in effect at the time of use.

Pricing rates used in this calculator were sourced from Microsoft Learn documentation and Azure pricing pages, last verified in **March 2026**. Rates are subject to change without notice. Always verify current rates at:
- [Copilot Credits billing rates](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)
- [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/)

*Last updated: March 2026 — aligned with calculator v1.3.0*
