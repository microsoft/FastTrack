# 🔍 Executive Radar

> "What needs my attention?" — a prioritized triage across your email, calendar, tasks, and commitments.

## At a Glance

| | |
|---|---|
| **Best for** | Execs, managers, chiefs of staff, anyone managing multiple workstreams |
| **Complexity** | Medium |
| **Requires** | WorkIQ Calendar, Mail, Copilot MCPs; WorkIQ SharePoint MCP; one prompt tool |
| **Outputs** | Prioritized attention list with recommended actions |
| **Works in** | Both (interactive + autonomous heartbeat) |

## What This Skill Does

Executive Radar gives PowerClaw a judgment layer across the user’s Microsoft 365 environment. Instead of showing raw feeds like unread email or today’s calendar, it synthesizes multiple signals into one ranked answer to the question: **what actually deserves attention right now?**

It pulls together:

- **Calendar signals** such as risky upcoming meetings, conflicts, missing prep, and overloaded schedules
- **Mail signals** such as unread VIP messages, stale reply threads, and flagged items
- **Task signals** from the PowerClaw_Tasks list, including overdue work and stale priorities
- **Memory signals** such as commitments, deadlines, and learned relationship context
- **Org signals** such as topics gaining momentum that may affect the user’s role or priorities

The result is a short, scannable radar ordered by urgency, with a recommended next action for each item.

> 💡 **Quick start — PowerClaw is already scanning:** The heartbeat already checks for urgent email, upcoming meetings, task drift, and follow-ups every 30 minutes, and a routine like **`[PowerClaw Routine] Morning Radar`** can make that even more focused.
>
> This skill adds the on-demand, deeper-triage version: ask what matters right now, get 🔴🟡🟢 prioritization plus recommended actions, and use PowerClaw’s memory to weigh who matters most and what commitments may be slipping.

## Why This Beats "Show Me My Unread Emails"

A normal email or calendar assistant reports what exists. Executive Radar judges what matters.

PowerClaw can do that because it:

- **Combines multiple sources** instead of checking mail, meetings, and tasks in isolation
- **Uses memory** to know which people, projects, and commitments matter most to this user
- **Understands follow-through** by comparing promises, deadlines, and task drift over time
- **Works proactively** through heartbeat, so the radar can arrive before the user asks
- **Improves over time** as PowerClaw learns VIPs, recurring risks, and common failure patterns

This makes it an attention triage system, not just a reporting view.

## When to Use It

Use this skill when you want a fast, judgment-driven scan of your workload, especially:

- At the start of the day
- Before a heavy meeting day or travel day
- After returning from PTO or a long block of meetings
- Between back-to-back meetings when you need the highest-priority next move
- At the start of a week to detect slipping commitments early

## Trigger Phrases

- “What needs my attention today?”
- “What’s on fire right now?”
- “Give me my morning radar.”
- “What did I miss?”
- “Run a priority check.”
- “What should I deal with first?”
- “Show me my executive radar.”
- “What are my biggest risks today?”
- “What follow-ups are slipping?”
- “Give me the attention radar for tomorrow.”

## Prerequisites

- **WorkIQ Calendar MCP** is available
- **WorkIQ Mail MCP** is available
- **WorkIQ Copilot MCP** is available for trending org signals
- **WorkIQ SharePoint MCP** is connected to the **PowerClaw_Tasks** list and memory list
- A **Prompt** tool is configured in Copilot Studio
- PowerClaw’s SharePoint brain includes `user.md` and the standard constitution files so VIPs, role context, and operating norms can be inferred
- Optional for proactive delivery: **HeartbeatFlow** is enabled

## Setup

### Interactive setup

1. Open **Copilot Studio** and select your **PowerClaw** agent.
2. Go to **Tools**.
3. Click **+ Add a tool** → **Prompt**.
4. Choose **Create new prompt**.
5. Name it **Executive Radar**.
6. Add one input:
   - **`radarScope`** → **Text** → mark as **Optional**
7. Paste the prompt from **Prompt Tool** below.
8. Save the prompt.
9. Confirm these tools are enabled on the agent:
   - **WorkIQ Calendar MCP**
   - **WorkIQ Mail MCP**
   - **WorkIQ Copilot MCP**
   - **WorkIQ SharePoint MCP**
10. In the agent’s instructions or orchestration guidance, add language such as:
    - “When the user asks what needs attention, what is on fire, what they missed, or for a morning radar, use the **Executive Radar** prompt.”
11. Publish the agent and test with “What needs my attention today?”

### Prompt model recommendation

Choose a model with strong synthesis and prioritization. Recommended options:

| Tier | Model | Best for |
|---|---|---|
| Standard | GPT-4.1 | Solid quality for daily radar synthesis |
| Standard | GPT-5 chat | Better prioritization across many noisy signals |
| Premium | GPT-5 reasoning | Best for dense calendars, many stakeholders, and nuanced ranking |
| Standard | Claude Sonnet 4.6 | Good text-only synthesis if your tenant allows it |

> 💡 If the user has a high-volume inbox or large org context, prefer **GPT-5 chat** or **GPT-5 reasoning** for cleaner triage.

## Prompt Tool

### Prompt Tool: Executive Radar

**Input**

- `radarScope` (text, optional) — examples: `today`, `tomorrow morning`, `after PTO`, `this week`

**Copy-paste prompt**

```text
You are PowerClaw, a 24/7 AI Chief of Staff for Microsoft 365.

Your job is to answer the question: "What needs my attention?" using live Microsoft 365 signals plus PowerClaw memory and task context.

Use `radarScope` to determine the relevant time window. If it is blank, default to today and the next business day.

You may use:
- WorkIQ Calendar MCP
- WorkIQ Mail MCP
- WorkIQ Copilot MCP
- SharePoint Lists / PowerClaw_Tasks list
- PowerClaw_Memory list
- User context from the PowerClaw SharePoint brain, including VIP clues from user.md when available

Workflow:
1. Check calendar for today and tomorrow:
   - upcoming meetings with no clear prep context
   - unresolved scheduling conflicts or double-bookings
   - long back-to-back stretches with no recovery time
   - meetings where important attendees or topics imply risk, but supporting context is thin
2. Check email:
   - unread messages from VIPs such as manager, directs, close stakeholders, or executive partners
   - unanswered threads older than 24 hours that likely expect a reply
   - flagged or high-importance items
3. Check PowerClaw memory:
   - overdue commitments
   - approaching deadlines
   - important promises, decisions, or follow-ups stored as Commitment, Project, Person, Pattern, or Insight memories
4. Check the PowerClaw_Tasks list:
   - overdue tasks
   - tasks in Human Review
   - stale tasks that have not moved and may indicate slipping priorities
5. Optionally check WorkIQ Copilot MCP for trending org topics relevant to the user’s role, team, or active priorities.
6. Synthesize all signals into a single prioritized radar.

Ranking rules:
- Prioritize items that combine urgency + importance + relationship sensitivity.
- Elevate anything involving VIPs, missed commitments, or near-term meeting risk.
- Do not surface more than 10 items.
- If several signals point to the same issue, merge them into one item.
- Prefer judgment over exhaustiveness.

Output format:
# Executive Radar
**Scope:** [resolved time window]

For each item, use one of these indicators:
- 🔴 = urgent / important / likely needs action now
- 🟡 = important but not yet critical
- 🟢 = useful to keep in view

For each radar item include:
- **What it is:** short description
- **Why it matters:** business, relationship, deadline, or meeting risk
- **Recommended next action:** the clearest practical move

Keep the answer highly scannable.
- Max 10 items
- Order by urgency
- Use bullets, not long paragraphs
- Clearly label facts vs inferences where uncertainty exists
- If there are no major issues, say so and provide the top 2–3 watch items anyway
- Do not invent commitments, priorities, or stakeholder importance that are not supported by available evidence
```

## Proactive Mode (Heartbeat Integration)

Executive Radar fits naturally into PowerClaw’s heartbeat model. The heartbeat already scans for commitments, tasks, meetings, and follow-ups every 30 minutes. This skill gives users an on-demand version of the same intelligence and a clean pattern for proactive delivery.

Typical morning pattern:

1. Heartbeat detects the start of the workday
2. PowerClaw checks meetings, inbox changes, task drift, and overdue commitments
3. If meaningful issues are found, it prepares a concise radar
4. PowerClaw can post the result in Teams, hold it for chat retrieval, or create follow-up tasks where configured

Over time, the radar improves as the memory system accumulates better signals about VIPs, recurring risks, response habits, and project momentum.

## Example Interaction

**User:** What needs my attention today?

**PowerClaw:** Here’s your Executive Radar for today.

# Executive Radar
**Scope:** Today + next business morning

- 🔴 **What it is:** Unread email from your manager asking for updated staffing assumptions before the 2 PM review.
  **Why it matters:** VIP request tied to a same-day leadership decision.
  **Recommended next action:** Reply before noon with the latest assumptions or send a quick note committing to a delivery time.

- 🔴 **What it is:** Your 3 PM product sync has no prep notes, but recent mail shows unresolved disagreement on roadmap sequencing.
  **Why it matters:** Meeting risk is high because a decision may be requested without aligned context.
  **Recommended next action:** Spend 10 minutes pulling the latest thread summary and write 3 decision points before the meeting.

- 🟡 **What it is:** Two customer follow-up threads are older than 48 hours with no reply.
  **Why it matters:** Response delay may affect trust and could block pending asks.
  **Recommended next action:** Send short holding replies now and create a task for the detailed response if needed.

- 🟡 **What it is:** “Q2 operating model draft” is still marked To Do with no update in six days.
  **Why it matters:** This is a visible priority and is at risk of slipping silently.
  **Recommended next action:** Either update status today or create a Human Review task with the blocker.

- 🟢 **What it is:** Org discussion volume is rising around adoption reporting, which overlaps with your current priorities.
  **Why it matters:** This may become a near-term leadership topic.
  **Recommended next action:** Skim the recent discussion summary and decide whether to address it in this week’s status update.

## Tips

- Ask for **“today”**, **“tomorrow”**, or **“after PTO”** to change the scan window.
- Use it as a reset between meetings when your inbox and calendar have become noisy.
- Pair it with **Stakeholder Brief** when one radar item involves a sensitive person or project.
- If you want only critical items, ask for **“just the red flags.”**

## Limitations

- Radar quality depends on the quality of the underlying email, calendar, task, and memory signals.
- VIP detection is stronger when `user.md` and Person memory entries are well maintained.
- Trending org insight depends on what WorkIQ Copilot MCP can surface in the tenant.
- Some stale-task or project-drift judgments require inference and should be reviewed by the user before acting on them.

## Extension Ideas

- Weekly radar trend report showing repeated risk themes
- Team radar for managers covering directs, escalations, and staffing gaps
- Custom alert thresholds for VIPs, overdue replies, or meeting overload
- Auto-create PowerClaw_Tasks for red-flag items surfaced repeatedly across heartbeat runs

## Related Skills

- Commitment Tracker
- Meeting Copilot Loop
- Weekly Status Report
- Stakeholder Brief
