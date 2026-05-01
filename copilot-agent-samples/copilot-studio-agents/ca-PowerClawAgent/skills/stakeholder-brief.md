# 👤 Stakeholder Brief

> Get a living dossier on any person, account, or project — built from memory, email, calendar, and org signals.

## At a Glance

| | |
|---|---|
| **Best for** | Execs, account managers, PMs, chiefs of staff |
| **Complexity** | Medium |
| **Requires** | WorkIQ Mail, Calendar, User, Copilot MCPs; one prompt tool |
| **Outputs** | Synthesized brief with context, history, open items, and recommended actions |
| **Works in** | Both |

## What This Skill Does

Stakeholder Brief gives PowerClaw a reusable briefing pattern for any important **person, account, or project**. Instead of making the user manually search mail, meetings, org charts, task boards, and old notes, PowerClaw assembles a compact dossier that answers: **what’s the context, what’s changed, what is still open, and what should I do next?**

It supports three common modes:

1. **Person brief** — recent interactions, role context, open asks, commitments, relationship history, and suggested talking points
2. **Project brief** — current status, recent activity, open decisions, task drift, risks, and recommended next moves
3. **Account brief** — key people, recent customer or partner signals, unresolved issues, decision points, and follow-up recommendations

The output is designed for rapid preparation before a meeting, email, review, or re-entry into work you have not touched recently.

## Why This Gets Better Over Time

The first brief is often powered mostly by recent Microsoft 365 data. Over time, PowerClaw compounds value because it stores durable context in memory:

- **Person** memories capture stakeholder preferences, working style, sensitivities, and past commitments
- **Project** memories capture decisions, risks, milestones, and recurring blockers
- **Pattern** and **Insight** memories capture what tends to matter in similar situations
- Heartbeat continuously adds fresh observations from mail, meetings, and follow-through

That means the tenth brief can be far richer than the first. PowerClaw is not just retrieving recent activity — it is building a living dossier as memory compounds.

## When to Use It

Use this skill when you need context fast, especially:

- Before a 1:1 or skip-level conversation
- Before a customer, partner, or stakeholder call
- Before a leadership review or project checkpoint
- When picking up a project you have not touched in weeks
- When you need to understand the current state of a relationship or workstream before responding

## Trigger Phrases

- “Brief me on Sarah.”
- “Prep me for my call with Sarah.”
- “What’s the latest on Project Alpha?”
- “Catch me up on Project Alpha.”
- “Give me a stakeholder brief for Contoso.”
- “What do I need to know before my 1:1 with Alex?”
- “Brief me on the account before tomorrow’s meeting.”
- “Summarize my history with Jordan.”
- “What’s open with this project?”
- “Give me the latest context on this stakeholder.”

## Prerequisites

- **WorkIQ Mail MCP** is available
- **WorkIQ Calendar MCP** is available
- **WorkIQ User MCP** is available
- **WorkIQ Copilot MCP** is available for broader org or topic context when useful
- **WorkIQ SharePoint MCP** is connected to the PowerClaw_Memory list and task board
- A **Prompt** tool is configured in Copilot Studio
- PowerClaw’s SharePoint brain includes the standard constitution files and a usable `user.md`

## Setup

### Interactive setup

1. Open **Copilot Studio** and select your **PowerClaw** agent.
2. Go to **Tools**.
3. Click **+ Add a tool** → **Prompt**.
4. Choose **Create new prompt**.
5. Name it **Stakeholder Brief**.
6. Add one input:
   - **`briefTarget`** → **Text** → required
7. Paste the prompt from **Prompt Tool** below.
8. Save the prompt.
9. Confirm these tools are enabled on the agent:
   - **WorkIQ Mail MCP**
   - **WorkIQ Calendar MCP**
   - **WorkIQ User MCP**
   - **WorkIQ Copilot MCP**
   - **WorkIQ SharePoint MCP**
10. In the agent’s instructions or orchestration guidance, add language such as:
    - “When the user asks to brief them on a person, account, stakeholder, or project, use the **Stakeholder Brief** prompt.”
11. Publish the agent and test with “Brief me on Sarah before our 1:1.”

### Prompt model recommendation

Choose a model with strong synthesis across memory plus live M365 context. Recommended options:

| Tier | Model | Best for |
|---|---|---|
| Standard | GPT-4.1 | Good general-purpose brief generation |
| Standard | GPT-5 chat | Better at merging relationship history with live signals |
| Premium | GPT-5 reasoning | Best for messy projects, ambiguous entity matching, and nuanced action advice |
| Standard | Claude Sonnet 4.6 | Good text-only synthesis if enabled in your environment |

> 💡 If the target could refer to a person, project, or account ambiguously, prefer **GPT-5 chat** or **GPT-5 reasoning**.

## Prompt Tool

### Prompt Tool: Stakeholder Brief

**Input**

- `briefTarget` (text, required) — examples: `Sarah before our 1:1`, `Project Alpha`, `Contoso account`

**Copy-paste prompt**

```text
You are PowerClaw, a 24/7 AI Chief of Staff for Microsoft 365.

Your job is to generate a living brief on the entity described in `briefTarget`.

First determine whether the target is primarily:
- a person
- a project
- an account / customer / stakeholder group

Use the best match based on the user’s wording and available evidence. If ambiguous, say which interpretation you chose.

You may use:
- WorkIQ Mail MCP
- WorkIQ Calendar MCP
- WorkIQ User MCP
- WorkIQ Copilot MCP
- SharePoint Lists / PowerClaw_Tasks list
- PowerClaw_Memory list

Research workflow:
1. Resolve the entity type.
2. Search memory first:
   - For a person, look for relevant memories using a scope like `person:NAME` or equivalent matching entries.
   - For a project, look for relevant memories using a scope like `project:NAME`.
   - For an account or stakeholder group, look for matching memory entries, people, tasks, and recent discussions.
3. Gather live Microsoft 365 context:
   - recent emails to/from or mentioning the target
   - recent or upcoming meetings related to the target
   - org context from WorkIQ User MCP when the target is a person
   - broader topic momentum from WorkIQ Copilot MCP when helpful
4. Check open commitments, tasks, and unresolved follow-ups connected to the target.
5. Synthesize the result into a concise brief.

Required output structure:
# Stakeholder Brief
**Target:** [resolved entity]
**Type:** [person / project / account]

## Context
- who/what this is
- why it matters
- relationship or business context

## Recent Activity
- key recent emails, meetings, decisions, or developments

## Open Items
- unresolved asks, commitments, due dates, dependencies, or waiting items

## Risks / Watch-outs
- tensions, blockers, relationship sensitivities, stale work, or decision gaps

## Recommended Next Actions
- the 3–5 smartest next moves

Instructions:
- Keep it scannable and executive-friendly.
- Use bullets over long paragraphs.
- Distinguish facts from inferences when needed.
- For a person brief, include role, recent interaction history, unresolved asks, and likely priorities.
- For a project brief, include status, key people, recent movement, open decisions, and risks.
- For an account brief, include stakeholders, relationship state, recent contact, risks, and next touchpoints.
- If memory is thin, say so clearly and rely on recent M365 evidence.
- If both memory and live evidence are thin, say that directly and suggest what context the user could provide to strengthen future briefs.
- Do not invent relationship history, commitments, or project status.
```

## Example Interactions

### Example 1 — Person brief

**User:** Brief me on Sarah before our 1:1.

**PowerClaw:** I pulled recent emails, meetings, open commitments, and prior memory for Sarah. Here’s the brief.

# Stakeholder Brief
**Target:** Sarah Chen
**Type:** Person

## Context
- Director of Operations and one of your most frequent cross-functional partners
- Regularly involved in planning, staffing, and execution-risk conversations
- Memory indicates she values concise updates and dislikes surprise escalations

## Recent Activity
- Met twice in the last 10 days: weekly ops sync and Q2 planning review
- Recent email thread focused on staffing assumptions and timeline confidence
- Shared doc comments suggest concern about unresolved ownership on one dependency

## Open Items
- You owe Sarah an updated staffing assumption summary before Friday
- Waiting on her confirmation for the revised planning review agenda
- One follow-up from last week’s sync is still not captured as a task

## Risks / Watch-outs
- **Fact:** There is still no named owner for the dependency discussed in the last planning review
- **Inference:** If you enter the 1:1 without a recommendation, the conversation may turn into an escalation on execution discipline

## Recommended Next Actions
- Send the staffing summary before the meeting
- Bring one clear owner recommendation for the unresolved dependency
- Ask whether she wants a lighter or more detailed review cadence for the next two weeks

### Example 2 — Project brief

**User:** Catch me up on Project Alpha.

**PowerClaw:** I merged recent mail, meetings, tasks, and project memory into a short project brief.

# Stakeholder Brief
**Target:** Project Alpha
**Type:** Project

## Context
- Internal transformation project tied to Q2 operating model changes
- High visibility because leadership expects a recommendation this month
- Project memory shows recurring risk around dependency ownership

## Recent Activity
- Discussed in three meetings this week, including the product-ops sync and leadership prep
- Recent mail shows debate over sequencing analytics versus reporting work
- Task board shows one review item still waiting on human sign-off

## Open Items
- Final recommendation memo is not yet drafted
- Ownership of one cross-team dependency remains unresolved
- Due date for the review package is approaching within the next week

## Risks / Watch-outs
- **Fact:** The task board has not been updated in several days for a visible priority
- **Inference:** Leadership may perceive drift if no status signal is sent before the next checkpoint

## Recommended Next Actions
- Publish a short status update today
- Assign an explicit owner to the unresolved dependency
- Draft the recommendation memo before the next leadership review

## Tips

- Add context such as **“before my 1:1”** or **“for tomorrow’s customer call”** to sharpen the brief.
- Use the exact project or stakeholder name when several similar entities exist.
- Follow this skill with **Executive Radar** if the brief surfaces multiple urgent risks.
- Encourage the user to let PowerClaw capture decisions and follow-ups into memory so future briefs get richer.

## Limitations

- The first brief on a new person or project may be thin if PowerClaw has little memory yet.
- Quality depends on accessible mail, calendar, task, and org signals.
- Some relationship or risk judgments require inference and should be reviewed by the user.
- Ambiguous names may require PowerClaw to make a best-match assumption.

## Extension Ideas

- Auto-generate stakeholder maps for major projects or accounts
- Add a relationship health score based on recency, sentiment cues, and unresolved asks
- Trigger proactive nudges such as “you haven’t spoken to this stakeholder in two weeks”
- Save approved briefs back into SharePoint as reusable relationship history

## Related Skills

- Pre-Meeting Brief
- Executive Radar
- Commitment Tracker
- Meeting Copilot Loop
