# 🧭 Decision Memo Builder

> Turn rough notes, competing options, and scattered evidence into an executive-ready decision memo with an explicit recommendation.

## At a Glance

| | |
|---|---|
| **Best for** | Strategy teams, PMs, executives, architecture leads |
| **Complexity** | Hard |
| **Requires** | Code Interpreter optional, WorkIQ MCPs for context gathering, two prompt tools |
| **Outputs** | Structured decision memo in chat, email, or Word doc |
| **Works in** | Both |

## What This Skill Does

This skill helps PowerClaw convert messy decision material into a polished memo suitable for executive review.

It follows a two-stage pattern:

1. **Intake prompt** — converts rough input into a structured decision framework and asks up to three clarifying questions if critical information is missing
2. **Memo generator prompt** — turns the framework into a readable executive memo with a trade-offs table, risks, assumptions, gaps, recommendation, and decision deadline

It works well for:

- Technology platform choices
- Vendor selections
- Strategy pivots
- Resource allocation decisions
- Process or operating model changes

## When to Use It

Use this skill when:

- The user has notes but not a polished memo
- There are multiple options with trade-offs
- Stakeholders need a recommendation, not just brainstorming
- Evidence is spread across meetings, files, email, or prior research
- The decision requires assumptions, risks, and open gaps to be stated clearly

## Trigger Phrases

- “Build me a decision memo”
- “Turn these notes into an executive memo”
- “Help me decide between these options”
- “Create a recommendation memo from this research”
- “Draft a technology decision memo”
- “Summarize this vendor choice with pros and cons”

## Prerequisites

- PowerClaw has access to:
  - Relevant **WorkIQ MCPs** for context gathering
  - Optional **WorkIQ Word MCP** if you want document output
  - Optional **Code Interpreter** for tabular comparison cleanup or document generation support
- Two prompt tools are created:
  - **Decision Memo Intake**
  - **Decision Memo Generator**
- If files are uploaded, PowerClaw must have permission to read them

## Setup (Step-by-step with Copilot Studio UI paths)

### Create the intake prompt

1. Open **Copilot Studio** → select your **PowerClaw** agent
2. Go to **Tools**
3. Click **+ Add a tool** → **Prompt**
4. Choose **Create new prompt**
5. Name it **Decision Memo Intake**
6. Add one input:
   - **`rawInput`** → **Text**
7. Paste the intake prompt from **Prompt Tool(s)** below
8. Save

### Create the generator prompt

1. Stay in **Copilot Studio** → **Tools**
2. Click **+ Add a tool** → **Prompt**
3. Choose **Create new prompt**
4. Name it **Decision Memo Generator**
5. Add one input:
   - **`decisionFramework`** → **Text**
6. Paste the generator prompt from **Prompt Tool(s)** below
7. Save

### Wire the skill into PowerClaw behavior

1. In the agent's instructions or relevant orchestration/topic logic, add guidance such as:
   - “When the user asks for a decision memo, first run **Decision Memo Intake**. If the intake returns clarifying questions, ask them. Once complete, pass the structured framework to **Decision Memo Generator**.”
2. Confirm these tools are enabled if you want richer context or outputs:
   - **WorkIQ Mail MCP**
   - **WorkIQ Calendar MCP**
   - **WorkIQ Word MCP** (optional)
   - **Code Interpreter** (optional)
3. If you want automatic document save behavior, add an instruction in **`agents.md`** explaining where finished decision memos should be stored in SharePoint or OneDrive

## Prompt Tool(s) (with full copy-paste prompts)

### Prompt Tool 1: Decision Memo Intake

**Input**

- `rawInput` (text) — rough notes, pasted research, options, constraints, stakeholder opinions, or raw context

**Copy-paste prompt**

```text
You are PowerClaw, an executive-grade AI Chief of Staff.

Your task is to turn `rawInput` into a structured decision framework for a formal decision memo.

First, inspect the raw material and determine whether the following elements are present with enough clarity:
- decision title
- context / background
- options under consideration
- constraints
- stakeholders
- timeline or decision deadline

Rules:
1. If critical information is missing, ask targeted clarifying questions.
2. Ask a maximum of 3 questions total.
3. Only ask for information that is necessary to produce a high-quality memo.
4. If the input is sufficient, do not ask questions.
5. Do not generate the final memo in this step.

If clarification is needed, output:

CLARIFYING_QUESTIONS
1. ...
2. ...
3. ...

If no clarification is needed, output valid JSON only using this schema:

{
  "decisionTitle": "",
  "decisionType": "",
  "contextBackground": "",
  "problemStatement": "",
  "options": [
    {
      "name": "",
      "description": "",
      "pros": [],
      "cons": [],
      "evidence": [],
      "estimatedCost": "",
      "timeline": "",
      "capabilityFit": "",
      "risks": []
    }
  ],
  "constraints": [],
  "stakeholders": [],
  "decisionNeededBy": "",
  "recommendedEvaluationCriteria": [],
  "assumptions": [],
  "knownGaps": []
}

Extraction guidance:
- `decisionType` should be something like: technology decision, vendor selection, strategy pivot, resource allocation, or process change
- `problemStatement` should be one concise sentence describing the actual decision to be made
- `recommendedEvaluationCriteria` should reflect how the options should be judged
- `assumptions` should contain explicit assumptions already implied by the notes
- `knownGaps` should list missing evidence, unresolved questions, or data the user has not supplied yet

Be precise, conservative, and faithful to the source material. Do not invent evidence.
```

### Prompt Tool 2: Decision Memo Generator

**Input**

- `decisionFramework` (text or JSON) — the structured framework returned from the intake prompt

**Copy-paste prompt**

```text
You are PowerClaw, an executive-grade AI Chief of Staff.

Your task is to convert `decisionFramework` into a complete executive decision memo.

Requirements:
1. Produce a polished, readable memo using clear headers, bullets, and bold key terms.
2. Include these sections in this order:
   - Title
   - Context / Background
   - Problem Statement
   - Options Overview
   - Trade-offs Comparison Table
   - Recommendation
   - Risks
   - Assumptions and Gaps
   - Next Steps
   - Decision Needed By
3. The trade-offs comparison table must compare the options across practical criteria such as cost, speed, capability fit, risk, stakeholder alignment, and strategic flexibility.
4. Explicitly call out assumptions and evidence gaps.
5. Make the recommendation clear and defensible.
6. If the framework does not support a strong recommendation, say so and recommend the fastest path to close the decision gap.
7. Do not hide uncertainty.

Formatting guidance:
- Use concise executive prose
- Prefer bullets over dense paragraphs
- Use bold labels for key conclusions
- Keep the recommendation actionable

Output template:

# [Decision Title]

## Context / Background
...

## Problem Statement
...

## Options Overview
### Option 1: [Name]
- Summary:
- Benefits:
- Trade-offs:

### Option 2: [Name]
- Summary:
- Benefits:
- Trade-offs:

## Trade-offs Comparison Table
| Option | Cost | Speed / Timeline | Capability Fit | Key Risks | Stakeholder Alignment | Notes |
|---|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | ... | ... |

## Recommendation
**Recommended option:** ...

Why:
- ...
- ...

## Risks
- ...

## Assumptions and Gaps
**Assumptions**
- ...

**Gaps**
- ...

## Next Steps
1. ...
2. ...
3. ...

## Decision Needed By
**[date or timeframe]**

Write as if this memo will be read by busy executives. Make it scannable, balanced, and specific.
```

## Example Interaction (realistic multi-turn)

**User:** I need to decide between building our own analytics platform vs buying Tableau vs extending Power BI. Here are my notes: our BI team already knows Power BI, Tableau would be faster for some dashboards, building in-house gives us more flexibility but probably takes 9-12 months, finance is worried about cost growth, the CIO wants standardization, product wants faster self-service analytics, and we need a direction before Q3 planning.

**PowerClaw:** I can turn that into a decision memo. I have enough to frame the options, but I need two details before I finalize the recommendation:

1. What matters most in the decision: speed, cost, strategic control, or user adoption?
2. Do you have a target decision date or a deadline tied to Q3 planning?

**User:** Prioritize speed to value first, then cost control. We need a recommendation by June 15.

**PowerClaw:** Great — I’ll structure the decision framework and generate the memo.

**PowerClaw:**  
**Recommendation:** Extend **Power BI** as the primary path, with a limited exception review for gaps that truly require Tableau-level capabilities.  

**Why:**  
- Fastest path to value given current team skills  
- Best fit for CIO standardization goals  
- Lower change-management risk than a new platform  
- Lower near-term execution risk than building in-house

**Decision Needed By:** **June 15**

## Tips

- Paste raw notes exactly as you have them; the intake prompt is designed for messy input
- If you already know the audience, say so: **“make this suitable for the ELT”**
- Upload background documents or previous analyses if the trade-offs are evidence-heavy
- Use the output as a chat draft first, then save the final version as a Word doc if needed

## Limitations

- Recommendations are constrained by the quality and completeness of the input
- If the user provides biased or one-sided evidence, the memo may reflect that imbalance unless PowerClaw is asked to gather more context
- The trade-offs table is only as strong as the facts behind each option
- Word document generation depends on the relevant MCP/tool being enabled

## Extension Ideas

- Save the final memo to SharePoint and email a review link
- Add a follow-up skill that converts the memo into a leadership deck
- Use Code Interpreter to normalize cost models or score options quantitatively
- Add a companion prompt that generates stakeholder-specific talking points from the memo
- Store past decisions in memory so future recommendations can reference precedent

## Related Skills

- Weekly Status Report
- Research Brief Builder
- Executive Summary Writer
- Leadership Deck Generator
