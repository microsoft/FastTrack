<p align="center">
  <img src="./Images/powerclaw-rounded.png" width="120" />
</p>
<h1 align="center">PowerClaw Agent</h1>
<p align="center"><strong>Your 24/7 AI Chief of Staff — Built Entirely on Microsoft 365</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0.1-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Released-March_2026-lightgrey?style=flat-square" alt="Released" />
  <img src="https://img.shields.io/badge/Setup-~30_minutes-0078D4?style=flat-square" alt="Time to Value" />
  <img src="https://img.shields.io/badge/Stack-M365_·_Copilot_Studio_·_Power_Automate-742774?style=flat-square" alt="Stack" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
</p>

<p align="center"><em>An autonomous AI agent that monitors your calendar, email, and tasks on a 30-minute heartbeat — so you can focus on the work that matters.</em></p>

---

## What PowerClaw Does

PowerClaw is a personal AI assistant that works around the clock inside your existing Microsoft 365 environment. It uses a SharePoint site as its "brain" — storing memories, configuration, and a task board — and operates in two modes:

| | How it works |
|---|---|
| 💬 **Interactive** | Chat in Teams: *"brief me"*, *"create a task for..."*, *"what's on my plate today?"* |
| 🤖 **Autonomous** | Runs every 30 minutes — checks your calendar, picks up tasks, and sends proactive briefings and alerts |

No manual Power Automate flows to build. No step-by-step workflow setup. Just describe what you want in natural language — add a calendar event like *"Send me a Microsoft News Brief every morning at 8am"* — and PowerClaw handles the rest.

---

## Why It Matters

| Outcome | How |
|---|---|
| 🎯 **Arrive prepared** | Automated meeting prep with attendee context and recent email threads — delivered before the meeting starts |
| 📬 **Reclaim your inbox** | Morning briefings summarize what matters so you skip the noise |
| 🔬 **Delegate research** | Drop a task on the board, get a polished report in your inbox — with a Word doc saved to OneDrive |
| 📅 **Schedule anything** | Add a calendar event, PowerClaw executes during that window and emails the deliverable |
| 🧠 **An agent that learns** | Remembers your preferences, people, and patterns over time — gets better the more you use it |
| 🔒 **Enterprise-ready** | Runs entirely within your M365 tenant — inherits your security, compliance, and data residency policies |

---

## See It in Action

### 💬 Interactive — Chat in Teams
Ask PowerClaw anything: a daily briefing, a task update, a research request. It adapts to your working style using customizable personality files.

<p align="center">
  <img src="./Images/WalterPowerClaw-TeamsMorningSync.gif" alt="PowerClaw morning sync chat in Teams" width="800" />
</p>

### 🤖 Autonomous — Calendar-Driven Tasks
Schedule PowerClaw to do work while you sleep. Add a recurring calendar event and it executes during that window — then emails you the deliverable.

<p align="center">
  <img src="./Images/CalendarDrivenTasks.gif" alt="PowerClaw autonomous calendar-driven tasks" width="800" />
</p>

### 📋 Autonomous — Task-Board-Driven Research
Ask PowerClaw to add a task its list OR drop a task on the SharePoint Kanban board. PowerClaw picks it up, researches the topic, saves a Word doc to OneDrive, and emails you the report.

<p align="center">
  <img src="./Images/KanbanBoardResearchReport.gif" alt="PowerClaw Kanban to research report flow" width="800" />
</p>

---

## Example Scenarios

| | Scenario | What Happens |
|---|---|---|
| 📬 | **Morning Work Briefing** | Start your day with an automated summary of today's calendar, pending tasks, and important emails — delivered before you even open Outlook |
| 📋 | **Research via Kanban Board** | Drop a task on the SharePoint board — PowerClaw picks it up, researches the topic, saves a Word doc to OneDrive, and emails you the link |
| 🔔 | **Proactive Meeting Prep** | PowerClaw detects an upcoming meeting, reviews attendees and recent emails, and sends you prep notes before it starts — without being asked |
| 📰 | **Scheduled Intelligence** | Want an AI News Brief every morning at 8am? A Roadmap Rundown on Fridays? Just add a recurring calendar event — PowerClaw handles the rest |

---

## How It's Different

PowerClaw is inspired by [**OpenClaw**](https://github.com/openclaw/openclaw), the open-source autonomous AI agent platform. OpenClaw is powerful — but it requires infrastructure beyond Microsoft 365. PowerClaw brings the same concept, built **entirely within the M365 stack** you already have:

| | OpenClaw | PowerClaw |
|---|---|---|
| **Infrastructure** | Local server + Docker + API keys | M365 + Copilot Studio + Power Automate |
| **Data residency** | Your machine | Your M365 tenant |
| **Security** | Self-managed | Inherits your M365 policies |
| **Chat** | WhatsApp, Telegram, Discord | Microsoft Teams |
| **Setup** | Docker compose + config files | Import solution + run a flow (~30 min) |

> 💡 If security, compliance, or organizational policy is a blocker for external AI infrastructure, PowerClaw gets you started using tools your IT team already approves.

---

## Getting Started

PowerClaw is designed to be up and running in about 30 minutes. The setup is three steps:

1. **Import** the Copilot Studio solution into your environment
2. **Provision** your SharePoint workspace by running the included Bootstrap Flow
3. **Personalize** by editing `user.md` with your name, role, and preferences

That's it. The heartbeat starts automatically.

📖 **[Full Setup Guide →](SETUP.md)**

<details>
<summary><strong>Prerequisites</strong></summary>

| Requirement | Details |
|---|---|
| Microsoft 365 | E3 or E5 (for SharePoint, Teams, Outlook, Graph API) |
| Copilot Studio | Credit pack or pay-as-you-go — [see pricing](https://aka.ms/copilotstudio/licensingguide) |
| Power Automate | Premium plan — required because HeartbeatFlow uses the Copilot Studio connector |
| Permissions | Ability to create a SharePoint site |

> 💡 See the [FAQ](#frequently-asked-questions) for detailed licensing guidance. M365 Copilot is **not** required.

</details>

---

## Built as a Foundation

PowerClaw is intentionally lightweight — a starting point you can extend. Integrate it with Planner, To Do, or any Power Platform connector. Customize its personality, operating rules, and behavior by editing simple markdown files — no code changes required.

**Best for:** Innovation teams · Executive productivity · Internal AI enablement · Copilot Studio pilots

### 🔌 Extend PowerClaw

Power Platform provides 1000+ connectors to build on. A few ideas that play to PowerClaw's strengths — autonomous follow-through, cross-source synthesis, and proactive intelligence:

- **CRM pulse** — Before every customer call, pull open opportunities, last touchpoints, and recent support tickets into a one-pager. Heartbeat delivers it before the meeting starts.
- **Copilot Analytics brief** — Connect to Power BI and M365 Copilot usage reports. Every Monday, get an AI adoption summary with top users, underutilized licenses, and trends — automatically.
- **Event-driven reflexes** — Expose a Power Automate HTTP trigger so external events (a form submission, a new lead, a Teams mention) wake the agent instantly instead of waiting for the next heartbeat
- **Risk & escalation monitor** — Scan email and Teams for escalation signals (keywords, VIP senders, overdue threads) and surface a daily risk digest before things spiral

> 📚 **Looking for step-by-step guides?** The **[Skills Library](skills/README.md)** has ready-to-use skill guides with setup instructions, copy-paste prompts, and recommended AI models for use cases like these and more.

---

## Frequently Asked Questions

<details>
<summary><strong>💰 Why does PowerClaw require Power Automate Premium?</strong></summary>

The HeartbeatFlow uses the **Microsoft Copilot Studio connector** — a premium connector — to invoke the agent on a schedule. Any Power Automate flow using a premium connector requires a Power Automate Premium plan. The SharePoint and Outlook connectors used in the other flows are standard and don't require premium on their own.

</details>

<details>
<summary><strong>💳 How much does the 30-minute heartbeat cost?</strong></summary>

The heartbeat runs ~1,440 times per month (48 runs/day × 30 days). This is well within the flow run limits included in a Power Automate Premium plan. You won't pay extra per run.

Each heartbeat also consumes **Copilot Studio credits** (typically 2–25 credits depending on the complexity of the agent's actions). With a standard credit pack, a typical heartbeat pattern uses a small fraction of the monthly allotment — leaving plenty for interactive chat and complex tasks.

You can also adjust the heartbeat frequency (e.g., every hour instead of 30 minutes) by editing the recurrence trigger in the HeartbeatFlow.

> 📖 Check the [Copilot Studio licensing guide](https://aka.ms/copilotstudio/licensingguide) and [Power Automate pricing](https://www.microsoft.com/en-us/power-platform/products/power-automate/pricing) for current rates.

</details>

<details>
<summary><strong>🪪 Is a Microsoft 365 Copilot license required?</strong></summary>

**No.** PowerClaw runs on Copilot Studio + Power Automate — it does not require a Microsoft 365 Copilot license.

However, if users **do** have M365 Copilot, their interactive chats with the agent inside Teams and M365 may be included at no extra Copilot Studio credit cost (subject to fair-use limits). Without M365 Copilot, interactive chats consume credits from your Copilot Studio credit pack.

The autonomous heartbeat always consumes Copilot Studio credits regardless of M365 Copilot licensing.

> 📖 See the [M365 Copilot licensing guide](https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-licensing) for current bundling details.

</details>

<details>
<summary><strong>📦 What licenses do I actually need?</strong></summary>

| License | Required? | Why |
|---|---|---|
| **Microsoft 365** (E3/E5) | ✅ Yes | SharePoint, Teams, Outlook, Graph API |
| **Copilot Studio** | ✅ Yes | Powers the AI agent (credit pack or pay-as-you-go) |
| **Power Automate Premium** | ✅ Yes | HeartbeatFlow uses the Copilot Studio connector (premium) |
| **Microsoft 365 Copilot** | ❌ Optional | If present, interactive chats in Teams don't consume credits |

> 📖 Licensing changes frequently. Always verify with the official [Copilot Studio licensing guide](https://aka.ms/copilotstudio/licensingguide) and [Power Automate pricing](https://www.microsoft.com/en-us/power-platform/products/power-automate/pricing) for current plans and rates.

</details>

<details>
<summary><strong>🔒 Does any data leave my tenant?</strong></summary>

**No.** PowerClaw runs entirely within your Microsoft 365 environment. All data — SharePoint lists, constitution files, emails, calendar — stays in your tenant. The AI model is accessed via Copilot Studio's built-in model endpoint, which follows your tenant's data residency and compliance policies.

</details>

<details>
<summary><strong>👥 Can multiple users share one PowerClaw agent?</strong></summary>

PowerClaw is designed as a **personal assistant** — one agent instance per user. The SharePoint workspace, constitution files, and memory are all scoped to a single user's context. Multiple users would each need their own SharePoint site and flow configuration.

For team-level scenarios, consider customizing PowerClaw to monitor shared resources (team mailbox, shared calendar, team channel) instead.

</details>

<details>
<summary><strong>⏱️ Can I change the heartbeat frequency?</strong></summary>

Yes. Open the **HeartbeatFlow** in Power Automate, find the **Recurrence** trigger at the top, and change the interval. Common options:
- **Every 15 minutes** — more responsive but uses more credits
- **Every 30 minutes** — default, good balance
- **Every hour** — lower cost, still proactive

Remember: more frequent heartbeats = more Copilot Studio credit consumption.

</details>

<details>
<summary><strong>🧠 What AI model does PowerClaw use?</strong></summary>

PowerClaw uses **Claude Sonnet 4.6** via Copilot Studio's model selection. You can change this in the Copilot Studio agent settings under "Select your agent's model." Different models may affect response quality, speed, and credit consumption.

</details>

<details>
<summary><strong>🔄 What happens if I run out of Copilot Studio credits?</strong></summary>

If your credit pack is exhausted, the agent stops responding to both heartbeat and interactive requests until the next billing cycle or until you add more capacity. The HeartbeatFlow will still trigger (it's a Power Automate flow), but the Copilot Studio connector call will fail gracefully. No data is lost — tasks remain in the SharePoint list and will be processed when credits are available again.

> 💡 Set up [usage monitoring](https://learn.microsoft.com/en-us/microsoft-copilot-studio/analytics-billed-sessions) in Copilot Studio to track credit consumption and avoid surprises.

</details>

---

## Version History

| Version | Date | Changes |
|---|---|---|
| **1.0.1** | March 2026 | Fix: Reliable context loading in M365 Copilot & Teams (JIT OnActivity init replaces OnConversationStart), improved soul.md personality template, removed canned Greeting topic |
| **1.0.0** | March 2026 | Initial release — Heartbeat + Bootstrap + Housekeeping flows, HttpRequest-based SharePoint ops for cross-environment portability, configurable agent identity, Compose-based flow configuration, loop safety guards |

> 💡 **Updating:** Download the latest `PowerClaw_Solution.zip` and re-import into your environment. Your SharePoint data (lists, settings, memories, tasks) is preserved. After import, re-edit the `Compose:_Config_SiteURL` action in HeartbeatFlow, GetContext, and Housekeeping with your site URL. **Do not re-run the Bootstrap flow** — your SharePoint lists and constitution files are already in place.

---

<p align="center"><sub>Created by <a href="mailto:alejanl@microsoft.com">Alejandro Lopez</a> · Contributions welcome</sub></p>

## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
