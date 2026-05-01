# 🔄 Meeting Copilot Loop

> Prep before, recap after, track commitments between — a complete meeting lifecycle powered by PowerClaw.

## At a Glance
| | |
|---|---|
| **Best for** | Execs, managers, PMs, chiefs of staff, account teams |
| **Complexity** | Medium |
| **Requires** | WorkIQ Calendar, Mail, User MCPs; one prompt tool |
| **Outputs** | Meeting briefs, recaps, action items, task board entries |
| **Works in** | Both (interactive + autonomous heartbeat) |

## What This Skill Does
Meeting Copilot Loop merges PowerClaw’s former **Pre-Meeting Brief** and **Meeting Recap** patterns into one end-to-end meeting workflow.

It supports three modes:

1. **Pre-Meeting Brief** — finds the meeting, gathers attendees, recent email context, likely objectives, unresolved items, and prior commitments from memory.
2. **Post-Meeting Recap** — drafts a structured recap with attendees, summary, decisions, action items, open questions, and next steps.
3. **Commitment Extraction & Follow-through** — turns commitments into SharePoint task board entries, saves memory for future meetings, and helps PowerClaw check whether promises were completed later.

This is where PowerClaw becomes more than “meeting summarization.” It connects **before**, **after**, and **what happened next** into one continuous operating loop.

> 💡 **Quick start — already built in:** PowerClaw’s heartbeat already watches for meetings starting soon and can send a prep brief automatically, so you may not need any extra setup for the prep half.
>
> This skill adds the interactive, full-loop version: ask for prep on demand, recap a meeting after it ends, extract commitments, and push follow-through into the SharePoint task board instead of stopping at a one-time brief.

## Why This Beats Native M365 Copilot Recaps
- **It remembers history** — prior commitments, unresolved issues, and relationship context can carry forward across recurring meetings.
- **It works proactively** — PowerClaw’s heartbeat can brief the user automatically before a meeting starts, without being asked.
- **It creates follow-through** — action items can be pushed into the PowerClaw_Tasks SharePoint list instead of staying trapped in chat.
- **It tracks commitments over time** — recap output becomes future memory, so PowerClaw can ask what was fulfilled or still open.
- **It improves recurring meeting quality** — recurring meetings can include “what changed since last time” rather than starting from zero.

## When to Use It
- Before a 1:1, customer call, leadership review, or project sync when the user needs context fast
- Right after a meeting when the user wants a polished recap with owners and due dates
- During weekly operating rhythms when the user wants to know which meeting commitments are still open
- For recurring meetings where prior decisions and unfinished items matter
- When PowerClaw should convert talk into tracked work automatically

## Trigger Phrases
**Prep mode**
- Brief me for my next meeting
- Prep me for my 2pm customer call
- What should I know before my 1:1 with Sarah?
- Give me the meeting brief for tomorrow’s steering committee

**Recap mode**
- Recap my last meeting
- Draft a follow-up for the budget review
- Summarize the decisions from today’s product sync
- Create a post-meeting recap for my call with Contoso

**Commitment review mode**
- What commitments are still open from last week’s meetings?
- Review outstanding commitments from my recurring staff meetings
- What follow-through items do I still owe after recent meetings?
- Show me unresolved meeting action items

## Prerequisites
- **WorkIQ Calendar MCP** is enabled
- **WorkIQ Mail MCP** is enabled
- **WorkIQ User MCP** is enabled
- **WorkIQ SharePoint MCP** is enabled for the **PowerClaw_Tasks** list
- PowerClaw memory is available, including **scopeKeys** such as:
  - `person:NAME`
  - `meeting:SERIES`
  - `commitment:DESCRIPTION`
- One **Prompt** tool is configured
- Optional but recommended: PowerClaw heartbeat is enabled for proactive prep delivery
- Optional delivery tools:
  - **Office 365 Outlook - Send email**
  - **Microsoft Teams - Post message**

## Setup
### Step 1 — Create the prompt tool
1. Open **Copilot Studio** and select your **PowerClaw** agent.
2. Go to **Tools**.
3. Click **+ Add a tool** → **Prompt**.
4. Choose **Create new prompt**.
5. Name it **Meeting Copilot Loop**.
6. Add one input:
   - **`meetingRequest`** → **Text**
7. Paste the prompt from **Prompt Tool** below.

### Step 2 — Choose the prompt model
In the prompt editor, choose at least **GPT-4.1** or **GPT-5 chat**.

- **Recommended minimum:** GPT-4.1
- **Best fit:** GPT-5 chat for stronger mode selection, synthesis, and structured extraction

### Step 3 — Confirm required tools and data sources
Make sure the agent has access to:
- **WorkIQ Calendar MCP**
- **WorkIQ Mail MCP**
- **WorkIQ User MCP**
- **WorkIQ SharePoint MCP**
- Optional: **Outlook Send Email**
- Optional: **Teams Post Message**

### Step 4 — Add orchestration guidance
In your agent instructions or orchestration guidance, add behavior such as:

- “When the user asks for meeting prep, meeting recap, follow-up actions, or open commitments from meetings, use the **Meeting Copilot Loop** prompt.”
- “If action items are extracted, create or update entries in the PowerClaw_Tasks SharePoint list when appropriate.”
- “When prior commitments exist in memory, include them as context.”
- “For recurring meetings, compare against the prior meeting context when available.”

### Step 5 — Publish and test
Test these three requests:
- “Brief me for my next meeting”
- “Recap my last meeting”
- “What commitments are open from last week’s meetings?”

Then verify:
- the correct mode is selected
- recurring meetings include prior context when available
- action items include owner and due date when known
- commitments can be pushed into tasks and memory cleanly

## Prompt Tool
### Prompt: Meeting Copilot Loop
**Input**
- `meetingRequest` (Text): A natural-language request such as `brief me for my next meeting`, `recap my last meeting`, or `what commitments are still open from last week's meetings?`

**Copy-paste prompt**
```text
You are PowerClaw, a 24/7 AI Chief of Staff operating across Microsoft 365, SharePoint memory, and task workflows.

The user's request is:
{{meetingRequest}}

Your job is to determine which meeting-lifecycle mode to run:
1. PREP
2. RECAP
3. COMMITMENTS

First, infer the intended mode from the user's request.
- Use PREP for requests about upcoming meetings, preparation, attendee context, what to know, or briefing.
- Use RECAP for requests about a completed or recent meeting, follow-up notes, summary, decisions, or action items.
- Use COMMITMENTS for requests about unresolved promises, follow-through, outstanding actions, or what is still open from prior meetings.

Use only information the user already has permission to access.

Available evidence sources:
- WorkIQ Calendar MCP for meeting title, time, organizer, attendees, recurrence, and meeting timing
- WorkIQ Mail MCP for recent threads and related context
- WorkIQ User MCP for attendee role, org, and relationship context when available
- PowerClaw memory for prior commitments, recurring-meeting context, unresolved issues, and relationship history
- SharePoint Lists / PowerClaw_Tasks for existing follow-through items and task status

General instructions for all modes:
1. Identify the best matching meeting or time period from the request and state assumptions if ambiguous.
2. Reference prior context from memory when available.
3. For recurring meetings, include “what changed since last time” if enough evidence exists.
4. Be explicit about facts vs likely inferences when confidence is limited.
5. Do not invent decisions, owners, deadlines, or prior commitments.
6. Keep the output concise, scannable, and executive-friendly.

Mode instructions:

If mode = PREP:
- Find the relevant upcoming meeting.
- Gather:
  - meeting info
  - attendees
  - recent related emails
  - likely objectives
  - unresolved items from previous meetings
  - prior commitments from memory using relevant scopeKeys such as person:NAME or meeting:SERIES
- If recurring, summarize what changed since the last meeting.
- Produce a practical brief the user can use immediately.

If mode = RECAP:
- Find the relevant recent meeting.
- Gather the meeting details and any recent context that improves continuity.
- Draft a structured recap with:
  - attendees
  - summary
  - key decisions
  - action items
  - open questions
  - next steps
- Every action item should include owner and deadline when known; otherwise mark as TBD.
- Extract commitments clearly so they can be saved to memory or tasks.

If mode = COMMITMENTS:
- Search memory and tasks for open commitments related to recent meetings or the requested time period.
- Prefer unresolved commitments linked to people, recurring meetings, or specific commitments.
- Summarize:
  - open commitments
  - owner
  - due date or expected timing
  - source meeting
  - current status if visible
  - suggested follow-up
- Highlight overdue or at-risk commitments first.

Output format:

# Meeting Copilot Loop
**Mode:** [PREP | RECAP | COMMITMENTS]
**Resolved scope:** [meeting name, attendee, or time range]
**Assumptions:** [if any]

If PREP, use:
## Meeting Info
- ...
## Attendees
- ...
## Prior Context
- ...
## Likely Goals
- ...
## Unresolved Items / Prior Commitments
- ...
## What Changed Since Last Time
- ...
## Suggested Talking Points
- ...
## Best Use of the Meeting
- ...

If RECAP, use:
## Meeting Info
- ...
## Attendees
- ...
## Summary
- ...
## Key Decisions
- ...
## Action Items
- Owner | Action | Due date
## Open Questions
- ...
## Next Steps
- ...
## Commitments Extracted
- ...

If COMMITMENTS, use:
## Open Commitments
- Owner | Commitment | Due date | Source meeting | Status
## Risks / Overdue Items
- ...
## Suggested Follow-ups
- ...
## Memory / Task Updates Recommended
- ...

Final rule:
- If the user appears to want delivery, prepare the output so it can be sent by email or Teams, but do not send automatically unless the operating context explicitly allows autonomous delivery.
```

## Proactive Mode (Heartbeat Integration)
PowerClaw already has the core mechanics needed for proactive meeting prep.

During heartbeat, PowerClaw can:
- inspect upcoming calendar events
- detect meetings starting within roughly the next 15 minutes
- identify whether the user likely needs a prep brief
- deliver that brief by email or chat based on the operating rules already defined in the agent

That means this skill does **not** require a new flow just to enable proactive prep.

Instead, this prompt tool complements the heartbeat in two ways:
- it gives users an **on-demand interactive entry point** to the same prep capability
- it extends the lifecycle beyond prep into **recap** and **commitment review**

If your PowerClaw instructions already include proactive meeting prep logic, no additional flow changes are needed. This skill simply unifies the interactive and autonomous experiences under one meeting-lifecycle pattern.

## Example Interactions
### 1) User asks for a pre-meeting brief
**User:** Brief me for my next meeting with Megan.

**PowerClaw:** I found your upcoming 1:1 with Megan Ortiz at 2:30 PM. Here’s your meeting brief.

**Mode:** PREP  
**Resolved scope:** 1:1 with Megan Ortiz, today 2:30 PM

**Meeting Info**
- 30-minute 1:1
- Organizer: You

**Attendees**
- Megan Ortiz — Director of Operations

**Prior Context**
- Recent email traffic focused on staffing trade-offs and Q2 process changes
- Memory shows one unresolved commitment from the prior 1:1: confirm owner for onboarding metrics

**Likely Goals**
- Resolve the onboarding metrics owner
- Align on staffing implications for next month

**Suggested Talking Points**
- Confirm whether onboarding metrics now has a clear owner
- Ask what decision Megan needs from you this week

### 2) User asks for a post-meeting recap
**User:** Recap my last product sync.

**PowerClaw:** I found your most recent Product Sync and drafted a recap with extracted actions.

**Mode:** RECAP  
**Resolved scope:** Product Sync, today 10:00 AM

**Summary**
- Reviewed roadmap status, launch risk, and dependency timing

**Key Decisions**
- Keep beta date unchanged for now
- Escalate one dependency risk to engineering leadership

**Action Items**
- Priya | Confirm dependency dates | Friday
- Daniel | Update risk tracker | Monday

**Commitments Extracted**
- Priya committed to confirm dependency timing by Friday
- Daniel committed to refresh the risk tracker before Monday

### 3) User asks for commitment review
**User:** What commitments are open from last week's meetings?

**PowerClaw:** I checked recent meeting memory plus open PowerClaw_Tasks and found these unresolved commitments.

**Mode:** COMMITMENTS  
**Resolved scope:** Last week’s meetings

**Open Commitments**
- Alex | Send revised roadmap slide | Overdue | Product Sync | Not completed
- Megan | Confirm onboarding metrics owner | Due this week | Weekly 1:1 | Open
- You | Follow up with finance on budget assumptions | Due date TBD | Budget Review | In progress

**Suggested Follow-ups**
- Nudge Alex for the roadmap slide
- Ask Megan to close the metrics owner decision in the next 1:1
- Convert the finance follow-up into a dated task if timing matters

## Tips
- “My next meeting” and “my last meeting” are the fastest ways to invoke the skill
- Mention an attendee name when multiple meetings are close together
- Use this skill after recurring meetings to preserve continuity over time
- If you want autonomous delivery, define the preferred delivery channel in PowerClaw’s operating instructions

## Limitations
- The output is limited by what exists in calendar, email, memory, and tasks
- Spoken decisions that were never captured anywhere may still require user confirmation
- Owner and due-date extraction may need review when the source context is thin
- Commitment tracking is strongest when recap outputs are consistently written back to memory and tasks

## Extension Ideas
- Auto-create the next follow-up calendar hold when a commitment is high risk
- Send the final recap to all attendees after approval
- Compare actual meeting outcomes to stated pre-meeting goals
- Add a relationship heatmap using repeated attendee context from memory
- Generate a manager-ready “meeting health” summary across recurring meetings

## Related Skills
- Weekly Status Report
- Decision Memo Builder
- Commitment Tracker
