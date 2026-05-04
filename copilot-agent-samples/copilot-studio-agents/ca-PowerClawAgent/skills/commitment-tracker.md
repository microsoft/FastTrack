# 🎯 Commitment Tracker

> Extract commitments from your meetings and emails — PowerClaw tracks them and chases follow-through autonomously.

## At a Glance

| | |
|---|---|
| **Best for** | Managers, execs, PMs, anyone who makes promises in meetings |
| **Complexity** | Medium |
| **Requires** | WorkIQ Calendar + Mail MCPs, WorkIQ SharePoint MCP, one prompt tool; optional Outlook Send Email and Teams Post Message actions |
| **Outputs** | Task board entries, memory entries, reminder emails, commitment reviews |
| **Works in** | Both |

## What This Skill Does

This skill turns vague “I’ll get that done” moments into something PowerClaw can actively manage.

It runs a four-part loop:

1. **Extract** — Search meetings, email, and recent interactions for promises, deadlines, action items, and follow-ups the user appears to own
2. **Track** — Create or update:
   - a **PowerClaw_Tasks** item for visible management on the SharePoint board
   - a **PowerClaw_Memory** entry with **MemoryType = Commitment**, a durable **ScopeKey**, and **ExpiresAt** set to the commitment deadline when known
3. **Chase** — On heartbeat, PowerClaw notices commitments that are due soon or overdue, then nudges the user and updates task notes
4. **Review** — Give the user a synthesized “open commitments” view across memory and tasks

The result is not just recall. It is autonomous follow-through.

## Why This Is Uniquely PowerClaw

- **Heartbeat-driven follow-up** — reminders happen automatically every 30 minutes without the user remembering to ask
- **Persistent memory across conversations** — commitments survive past the original meeting or email thread
- **SharePoint task board integration** — every real commitment can become a visible card on the PowerClaw kanban board
- **Cross-signal reasoning** — PowerClaw can connect what was said in meetings with what happened later in email
- **Proactive chasing** — it does not stop at extraction; it can draft reminder or follow-up messages before things slip

## When to Use It

- Right after a meeting when several promises or next steps were discussed
- After an important email thread where deadlines or deliverables were agreed
- During a weekly review to see everything you owe people
- Before a 1:1, leadership review, or project check-in
- When you want PowerClaw to monitor commitments quietly in the background

## Trigger Phrases

### Extract
- “What did I commit to this week?”
- “Pull commitments from my last meeting with Sarah”
- “What promises did I make in email this week?”
- “Find my action items from the budget review”

### Review
- “What commitments are open?”
- “Show me overdue commitments”
- “What am I on the hook for right now?”
- “Review my commitments by deadline”

### Chase
- “Check if any commitments need follow-up”
- “Draft follow-ups for overdue commitments”
- “What should I chase before Friday?”
- “Run a commitment check”

## Prerequisites

- PowerClaw is already deployed and the baseline heartbeat is healthy
- **WorkIQ Calendar MCP** is enabled
- **WorkIQ Mail MCP** is enabled
- **WorkIQ SharePoint MCP** is enabled for:
  - **PowerClaw_Tasks**
  - **PowerClaw_Memory**
- A **Prompt** tool is configured
- Optional but valuable:
  - **WorkIQ Teams MCP** for recent conversation context
  - **Office 365 Outlook - Send email (V2)** for reminder delivery
  - **Microsoft Teams - Post message** if you want reminder nudges in Teams

## Setup

### Step 1 — Confirm the PowerClaw foundation

1. Open **PowerClaw** in SharePoint and confirm the standard lists exist:
   - **PowerClaw_Tasks**
   - **PowerClaw_Memory**
2. Confirm the task board uses the standard columns:
   - **Title**
   - **TaskStatus**
   - **TaskDescription**
   - **Priority**
   - **Source**
   - **DueDate**
   - **Notes**
   - **LastActionDate**
3. Confirm heartbeat is enabled in **Power Automate** and already running successfully every 30 minutes.

### Step 2 — Add the prompt tool in Copilot Studio

1. Open **Copilot Studio** → select your **PowerClaw** agent
2. Go to **Tools**
3. Click **+ Add a tool** → **Prompt**
4. Choose **Create new prompt**
5. Name it **Commitment Tracker**
6. Add one input:
   - **`commitmentRequest`** → **Text** → mark as **Optional**
7. Paste the prompt from **Prompt Tool** below

### Step 3 — Choose the prompt model

This skill benefits from cross-source reasoning, date interpretation, and duplicate detection. Use:

| Recommendation | Model | Why |
|---|---|---|
| **Best default** | **GPT-4.1** | Strong balance of reasoning quality, speed, and cost |
| **Best for harder cases** | **GPT-5 chat** | Better for ambiguous deadlines and multi-thread commitment extraction |

### Step 4 — Verify tools and actions

In the same agent, confirm these are enabled:

- **WorkIQ Calendar MCP**
- **WorkIQ Mail MCP**
- **WorkIQ SharePoint MCP**
- Optional: **WorkIQ Teams MCP**
- Optional: **Office 365 Outlook - Send email (V2)**
- Optional: **Microsoft Teams - Post message**

### Step 5 — Add orchestration guidance

In the agent instructions or the relevant orchestrated topic, add guidance such as:

- “When the user asks what they committed to, what is open, what is overdue, or asks for follow-up on commitments, use the **Commitment Tracker** prompt.”
- “When extracting commitments, create or update both PowerClaw task entries and PowerClaw memory entries for durable follow-through.”
- “When a commitment is due soon or overdue, prefer drafting a reminder or follow-up before the user asks.”

### Step 6 — Publish and test

1. Save the prompt
2. Publish the agent
3. Test these flows:
   - “What did I commit to this week?”
   - “Show me all open commitments”
   - “Check if anything is overdue”
4. Confirm:
   - commitments are summarized clearly
   - task items are created or updated in **PowerClaw_Tasks**
   - memory items are created or updated in **PowerClaw_Memory**
   - reminders are drafted appropriately when deadlines are near

## Prompt Tool

### Prompt Tool: Commitment Tracker

**Input**

- `commitmentRequest` (text, optional) — examples: `what did I commit to this week`, `pull commitments from my last meeting with Sarah`, `show overdue items`

**Copy-paste prompt**

```text
You are PowerClaw, a 24/7 autonomous AI Chief of Staff running on Microsoft 365.

Your job is to identify, track, review, and chase the user's commitments using Microsoft 365 context plus PowerClaw's SharePoint-based task board and memory system.

User request:
{{commitmentRequest}}

Available operating context:
- WorkIQ Calendar MCP for meetings, attendees, organizers, timing, and context
- WorkIQ Mail MCP for message threads, requests, promises, deadlines, and follow-ups
- Optional WorkIQ Teams MCP for recent conversation context
- WorkIQ SharePoint MCP for:
  - PowerClaw_Tasks list
  - PowerClaw_Memory list

PowerClaw memory schema:
- MemoryType values may include: Preference, Person, Project, Pattern, Commitment, Insight
- Use ScopeKey to create stable commitment identifiers
- Use CanonicalFact for the normalized commitment statement
- Use Confidence and Importance to reflect certainty and significance
- Use ExpiresAt for the commitment deadline when known

PowerClaw task schema:
- Title
- TaskStatus (To Do / Human Review / Done)
- TaskDescription
- Priority
- Source
- DueDate
- Notes
- LastActionDate

First, determine the operating mode from the user's request:
1. EXTRACT
2. REVIEW
3. CHASE

Mode rules:
- Use EXTRACT when the user asks what they committed to, asks to pull commitments from meetings/email, or wants action items found
- Use REVIEW when the user asks what commitments are open, overdue, active, or due soon
- Use CHASE when the user asks for reminders, follow-ups, nudges, or a proactive commitment check
- If the request is ambiguous, choose the best-fit mode and state your assumption briefly

Definitions:
- A commitment is something the user appears to have promised, agreed to deliver, agreed to follow up on, or implicitly owns with a clear next step
- Strong evidence includes phrases like: "I'll send", "I'll follow up", "I'll deliver", "I'll get this done", "by Friday", "I'll own this", "let me take that", assigned action items, or explicit deadlines
- Do not invent commitments from vague discussion alone

General instructions:
1. Use the user's request to determine the time range or conversation scope
2. Search the relevant sources before answering
3. Prefer explicit evidence over inference
4. Deduplicate commitments across meetings, mail, and chat
5. If the same commitment already exists in memory or tasks, update it rather than creating a duplicate
6. Normalize each commitment into a concise CanonicalFact
7. Build ScopeKey values in the form:
   - commitment:[normalized-short-description]
8. If a deadline exists, map it to ExpiresAt in memory and DueDate in tasks
9. If no deadline exists, leave it unknown rather than inventing one
10. If another person is involved, capture that relationship clearly

EXTRACT mode instructions:
1. Search recent calendar events, attendee context, and relevant email threads for commitments, promises, deadlines, and action items
2. Focus on commitments owned by the user
3. For each valid commitment, prepare:
   - commitment
   - owner
   - deadline
   - status
   - source (meeting / email / chat)
   - source detail (meeting title, email thread, or chat context)
4. Cross-check the PowerClaw_Memory list for an existing MemoryType = Commitment entry
5. Cross-check the PowerClaw_Tasks list for an existing open task representing the same commitment
6. For any commitment not already tracked, recommend creating or updating:
   - a PowerClaw_Memory entry with:
     - MemoryType = Commitment
     - ScopeKey = commitment:[normalized-short-description]
     - CanonicalFact = normalized commitment statement
     - Confidence = High / Medium / Low based on evidence strength
     - Importance = High / Medium / Low based on impact and visibility
     - ExpiresAt = deadline if known
   - a PowerClaw_Tasks entry with:
     - Title = short action-oriented commitment title
     - TaskStatus = To Do
     - TaskDescription = fuller commitment detail plus source context
     - Priority = High / Medium / Low
     - Source = meeting/email/chat + source detail
     - DueDate = deadline if known
     - Notes = extracted by Commitment Tracker on [today's date]
7. Suggest task creation for any newly discovered untracked commitments

REVIEW mode instructions:
1. Query PowerClaw_Memory for active MemoryType = Commitment items
2. Ignore expired or completed items if the task board clearly shows they are Done
3. Cross-reference PowerClaw_Tasks to determine current state:
   - open and on track
   - due soon
   - overdue
   - waiting for review
   - completed
4. Surface inconsistencies, for example:
   - task exists but no memory entry
   - memory entry exists but no visible task
   - due date mismatch between memory and task
5. Prioritize items with nearest deadlines or highest importance

CHASE mode instructions:
1. Identify commitments due soon or overdue
2. Treat "due soon" as within the next 3 business days unless the user specifies a different window
3. For each item, determine the best next action:
   - remind the user
   - draft a follow-up email for the user to send
   - update task Notes with a follow-up recommendation
   - flag for Human Review if the wording is sensitive
4. If the commitment involves another person, draft a short, professional follow-up email for the user to review
5. For reminder email subject lines, prefer:
   - 🦞 PowerClaw: Commitment Check — [item]
6. Keep reminder tone gentle, clear, and non-accusatory

Output format:

# Commitment Tracker
**Mode:** [Extract / Review / Chase]
**Scope Assumption:** [if needed]

## Commitments
For each item, provide:
- **Commitment:** ...
- **Owner:** ...
- **Deadline:** ...
- **Status:** ...
- **Source:** ...
- **Tracking:** [In memory / On task board / Both / Untracked]
- **Recommended next action:** ...

## Untracked Commitments to Add
- ...

## Follow-up Drafts
- Include only when useful in CHASE mode

## Notes on Confidence
- Explain ambiguous ownership, weak evidence, or inferred dates

Important guardrails:
- Do not fabricate commitments, deadlines, or ownership
- Be explicit when something is inferred instead of directly evidenced
- Prefer concise, operational language
- Default to helping the user track and follow through, not just summarizing
```

## Autonomous Mode (Heartbeat Integration)

This skill fits PowerClaw's existing operating model naturally.

- PowerClaw already scans memory and tasks during its normal heartbeat cycle
- Commitments saved with **MemoryType = Commitment** and **ExpiresAt** naturally become reviewable during that scan
- Matching task cards in **PowerClaw_Tasks** give the agent a visible execution surface for reminders, status notes, and human-review routing
- If a commitment is near deadline or overdue, PowerClaw can include it in the heartbeat reasoning and generate reminder actions or follow-up drafts
- No extra architectural changes are required; this builds on the memory, task board, and heartbeat infrastructure that PowerClaw already has

In practice, this means a user can ask once, “Track my commitments,” and PowerClaw can keep nudging follow-through later without needing another custom flow.

## Example Interactions

### 1) Extract — “What did I commit to in my meetings this week?”

**User:** What did I commit to in my meetings this week?

**PowerClaw:** I reviewed this week’s meetings and related email threads. I found four likely commitments you own.

#### Commitments
- **Commitment:** Send revised hiring plan to Sarah
- **Owner:** You
- **Deadline:** Friday
- **Status:** Due soon
- **Source:** Meeting — Weekly staffing review
- **Tracking:** Untracked
- **Recommended next action:** Add to task board and memory

- **Commitment:** Follow up with finance on budget assumptions
- **Owner:** You
- **Deadline:** Not explicitly stated
- **Status:** Open
- **Source:** Meeting — Q4 budget review
- **Tracking:** In memory only
- **Recommended next action:** Create visible task card

**PowerClaw:** I can add the untracked commitments to PowerClaw_Tasks and store them in memory for heartbeat follow-up.

### 2) Review — “Show me all open commitments”

**User:** Show me all open commitments.

**PowerClaw:** Here’s your current commitment view across memory and the task board.

#### Commitments
- **Commitment:** Send revised hiring plan to Sarah
- **Owner:** You
- **Deadline:** Apr 12
- **Status:** Due soon
- **Source:** Staffing review + follow-up email
- **Tracking:** Both
- **Recommended next action:** Finish draft and send before Thursday afternoon

- **Commitment:** Share launch-readiness notes with product leads
- **Owner:** You
- **Deadline:** Apr 9
- **Status:** Overdue
- **Source:** Email thread — Launch readiness
- **Tracking:** Both
- **Recommended next action:** Draft follow-up now and update task notes

### 3) Autonomous chase — Heartbeat reminder

**Heartbeat outcome:** PowerClaw detects that **“Share launch-readiness notes with product leads”** is overdue by 1 day.

**Reminder draft**

**Subject:** 🦞 PowerClaw: Commitment Check — Share launch-readiness notes with product leads

Hi,

Quick nudge: this commitment appears overdue based on your recent launch-readiness thread.  
Would you like me to draft the follow-up email to the product leads or update the task with the latest status?

— PowerClaw

## Tips

- Ask right after a meeting for the strongest extraction accuracy
- Add names or meeting titles when you want narrower results
- Use “show overdue commitments” for a fast triage list
- If you want PowerClaw to be more proactive, add expectation-setting guidance in `agents.md`

## Limitations

- Commitment extraction is only as good as the evidence in meetings, email, and chat
- Spoken promises that were never captured anywhere may be missed
- Ownership can be ambiguous in group meetings; the prompt calls that out rather than guessing
- Reminder sending should follow your organization’s approval and communication norms

## Extension Ideas

- Commitment heatmap by person or team
- Auto-escalate long-overdue commitments into **Human Review**
- Add commitment-aging summaries to weekly status reports
- Add team-level commitment tracking for shared staff meetings
- Create a “commitment risk score” using importance, confidence, and days overdue

## Related Skills

- Meeting Copilot Loop
- Weekly Status Report
- Executive Radar
