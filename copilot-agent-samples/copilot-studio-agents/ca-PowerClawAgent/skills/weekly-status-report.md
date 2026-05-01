# 📈 Weekly Status Report

> Turn a week of meetings, email, tasks, and commitments into a clean status update for chat, email, or a document.

## At a Glance

| | |
|---|---|
| **Best for** | Managers, ICs, project leads, executives |
| **Complexity** | Medium |
| **Requires** | WorkIQ Calendar MCP, WorkIQ Mail MCP, one prompt tool; optional heartbeat-compatible scheduling |
| **Outputs** | Formatted weekly status report in chat, email, or Word doc |
| **Works in** | Both |

## What This Skill Does

This skill compiles a weekly summary from the signals PowerClaw already has access to:

- **Calendar** for meetings attended and notable conversations
- **Email** for key threads, decisions, and follow-ups
- **PowerClaw_Tasks** for completed work and in-flight items
- **Memory** for commitments, promises, and recurring priorities

It supports two modes:

1. **Interactive** — the user asks for a weekly status update on demand
2. **Scheduled** — PowerClaw detects a Friday routine event and drafts or emails the report automatically during heartbeat

The report is organized into:

1. **Wins / Accomplishments**
2. **Progress on Goals**
3. **Meetings & Decisions**
4. **Blockers / Risks**
5. **Upcoming Priorities**
6. **Follow-ups Needed**

> 💡 **Quick start — no setup needed:** Add a recurring calendar event named **`[PowerClaw Routine] Weekly Status Report`** and PowerClaw can pick it up on heartbeat and generate the report automatically.
>
> This skill is the more interactive version: use it any time, tailor the report for your manager vs. leadership vs. project team, change the date range, skip or emphasize sections, and review the draft before anything gets sent.

## When to Use It

Use this skill when you need to:

- Prepare for a leadership, manager, or project review
- Send a Friday wrap-up to your manager or team
- Capture what actually happened this week before details fade
- Turn scattered meetings and email threads into a structured summary
- Automate a recurring status report without building a custom flow

## Trigger Phrases

- “Draft my weekly status report”
- “Give me my weekly status for the leadership meeting”
- “Summarize my last 5 days of work”
- “Create a Friday status update for my manager”
- “What should I send as my weekly update?”
- “Run my weekly status report routine”

## Prerequisites

- PowerClaw is already connected to:
  - **WorkIQ Calendar MCP**
  - **WorkIQ Mail MCP**
  - **WorkIQ SharePoint MCP** for the **PowerClaw_Tasks** list
- Your SharePoint workspace includes the standard PowerClaw constitution files
- Optional for automation: the **HeartbeatFlow** is enabled
- Optional for document output: **WorkIQ Word MCP** or Outlook send email action is available

## Setup (Step-by-step with Copilot Studio UI paths)

### Interactive setup

1. Open **Copilot Studio** → select your **PowerClaw** agent
2. Go to **Tools**
3. Click **+ Add a tool** → **Prompt**
4. Choose **Create new prompt**
5. Name it **Weekly Status Report**
6. Add one input:
   - **`weekScope`** → **Text** → mark as **Optional**
7. Paste the prompt from **Prompt Tool(s)** below
8. Save the prompt
9. Confirm these tools are enabled on the agent:
   - **WorkIQ Calendar MCP**
   - **WorkIQ Mail MCP**
   - **WorkIQ SharePoint MCP**
   - Optional: **WorkIQ Word MCP** or **Office 365 Outlook - Send email (V2)**
10. In the agent's instructions or relevant orchestrated topic, add guidance such as:
    - “When the user asks for a weekly recap, weekly status, Friday update, or leadership summary, use the **Weekly Status Report** prompt.”

### Scheduled Friday routine setup

1. In **Outlook Calendar**, create a recurring Friday event named:
   - **`[PowerClaw Routine] Weekly Status Report`**
2. Set it for the time window you want PowerClaw to notice during heartbeat (for example, Friday at 3:30 PM)
3. In **SharePoint** → **Documents**, open **`agents.md`**
4. Add or confirm an operating rule telling PowerClaw to treat `[PowerClaw Routine]` calendar events as autonomous work requests
5. If you want email delivery, include the expected behavior in **`agents.md`**, for example:
   - “For `[PowerClaw Routine] Weekly Status Report`, draft the report from the current week and email it to me unless the event body says otherwise.”
6. Make sure **HeartbeatFlow** is turned on in **Power Automate**

## Prompt Tool(s) (with full copy-paste prompts)

### Prompt Tool: Weekly Status Report

**Input**

- `weekScope` (text, optional) — examples: `this week`, `last 5 days`, `Mar 1-Mar 7`

**Copy-paste prompt**

```text
You are PowerClaw, a 24/7 AI Chief of Staff for Microsoft 365.

Your job is to draft a clean, scannable weekly status report for the user using the time period in `weekScope`. If `weekScope` is blank, default to the current work week.

Use available evidence from:
- WorkIQ Calendar MCP for meetings attended, meeting subjects, attendees, and timing
- WorkIQ Mail MCP for important email threads, decisions, requests, approvals, and follow-ups
- SharePoint Lists / PowerClaw_Tasks for completed tasks, active tasks, and overdue items
- PowerClaw memory for commitments, promises made, recurring goals, and unresolved obligations

Instructions:
1. Determine the reporting window from `weekScope`.
2. Search calendar, email, tasks, and memory for that period.
3. Build a status report with these sections in this order:
   - Wins / Accomplishments
   - Progress on Goals
   - Meetings & Decisions
   - Blockers / Risks
   - Upcoming Priorities
   - Follow-ups Needed
4. Clearly distinguish:
   - **Facts** = meetings attended, tasks completed, emails sent/received, explicit decisions, stated deadlines
   - **Inferences** = likely blockers, emerging priorities, suggested follow-ups, themes
5. If the user's request includes an audience (for example: leadership, manager, project team, executive staff), tune tone and level of detail for that audience.
6. If the user's request asks to emphasize or skip sections, honor that request.
7. Keep the report concise but useful. Prefer bullets over long paragraphs.
8. Do not invent accomplishments, decisions, or blockers. If evidence is weak, say so.

Output format:

# Weekly Status Report
**Period:** [resolved date range]
**Audience:** [default to "general" unless user specified]

## Wins / Accomplishments
- ...

## Progress on Goals
- ...

## Meetings & Decisions
- **Fact:** ...
- **Fact:** ...

## Blockers / Risks
- **Fact:** ...
- **Inference:** ...

## Upcoming Priorities
- **Inference:** ...

## Follow-ups Needed
- ...

End with a short optional section:
## Notes on Confidence
- Mention any gaps in the source material or areas where you had to infer likely priorities.
```

## Example Interaction (realistic multi-turn)

**User:** Give me my weekly status for the leadership meeting.

**PowerClaw:** Absolutely — I’ll pull from this week’s meetings, email threads, completed tasks, and active commitments, then format it for a leadership audience.

**PowerClaw:**  
**Weekly Status Report**  
**Period:** Mar 4-Mar 8  
**Audience:** Leadership

### Wins / Accomplishments
- Closed the Q2 planning draft and circulated it to the leadership group
- Completed 6 tasks in the PowerClaw_Tasks list, including the customer escalation summary and roadmap review notes

### Progress on Goals
- Advanced the operating model proposal from outline to review-ready draft
- Reduced open follow-ups on stakeholder requests from 11 to 4

### Meetings & Decisions
- **Fact:** Attended the Tuesday staffing review; decision made to delay hiring for the analyst role until next quarter
- **Fact:** In the Thursday product sync, leadership aligned on prioritizing customer adoption reporting over additional dashboard features

### Blockers / Risks
- **Fact:** Waiting on finance assumptions before finalizing the budget narrative
- **Inference:** Analytics reporting may slip if data-owner approval is not secured early next week

### Upcoming Priorities
- Prepare final leadership readout for the operating model proposal
- Confirm budget assumptions with finance
- Close the remaining action items from this week’s product sync

### Follow-ups Needed
- Send finance the missing assumptions request
- Reply to the adoption metrics thread with the revised timeline

### Notes on Confidence
- Most meeting coverage is strong; blocker assessment is partly inferred from recent email and task activity.

## Tips

- Use phrases like **“for leadership”**, **“for my manager”**, or **“make it concise”** to shape tone
- Use `weekScope` for custom ranges such as **“last 5 days”** or **“March 1-March 7”**
- For a cleaner executive version, ask PowerClaw to keep only **wins, risks, and next priorities**
- For autonomous delivery, put routing instructions in the calendar event body, such as **“email this to me and save a Word doc”**

## Limitations

- The report is only as good as the underlying calendar, email, task, and memory signals
- Private work that never appeared in meetings, mail, or tasks may be underrepresented
- “Blockers” and “priorities” often require inference; the prompt calls that out explicitly, but users should still review before sending
- Scheduled mode depends on heartbeat timing, so delivery happens when PowerClaw next processes the routine window

## Extension Ideas

- Save the final report as a Word document in SharePoint or OneDrive
- Auto-send to a manager every Friday afternoon
- Add a “team impact” section for people managers
- Add a “customer signals” section by including CRM or support connectors
- Append a short KPI snapshot if the user uploads a spreadsheet and enables Code Interpreter

## Related Skills

- Daily Briefing
- Meeting Prep Pack
- Follow-up Draft Generator
- Decision Memo Builder
