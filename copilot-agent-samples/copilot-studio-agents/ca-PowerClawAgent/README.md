<p align="center">
  <img src="./Images/powerclaw-rounded.png" width="120" />
</p>
<h1 align="center">PowerClaw Agent</h1>
<p align="center"><strong>Your 24/7 AI Chief of Staff — Built Entirely on Microsoft 365</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/Setup-~15_minutes-0078D4?style=flat-square" alt="Time to Value" />
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
  <img src="./Images/TeamsChatPowerClaw.gif" alt="PowerClaw interactive chat in Teams" width="800" />
</p>

### 🤖 Autonomous — Calendar-Driven Tasks
Schedule PowerClaw to do work while you sleep. Add a recurring calendar event and it executes during that window — then emails you the deliverable.

<p align="center">
  <img src="./Images/CalendarDrivenTasks.gif" alt="PowerClaw autonomous calendar-driven tasks" width="800" />
</p>

---

## 📸 Example Scenarios

### 📬 Morning Work Briefing
Start your day with an automated summary of today's calendar, pending tasks, and important emails — delivered before you even open Outlook.

<p align="center">
  <img src="./Images/Morning%20Work%20Briefing.png" alt="Morning Work Briefing" width="800" />
</p>

---

### 📋 Research via Kanban Board
Drop a task on the SharePoint board. PowerClaw picks it up, researches the topic, saves a Word doc to OneDrive, and emails you the link — then moves the task to "Human Review."

<p align="center">
  <img src="./Images/PowerclawKanbanTask.png" alt="Kanban Task Board" width="800" />
</p>
<p align="center">
  <img src="./Images/EmailedResearchReport.png" alt="Emailed Research Report" width="800" />
</p>

---

### 🔔 Proactive Meeting Prep
PowerClaw detects an upcoming meeting, reviews attendees and recent emails, and sends you prep notes before it starts — without being asked.

<p align="center">
  <img src="./Images/MeetingPrepDetails.png" alt="Meeting Prep Details" width="800" />
</p>

---

### 📰 Scheduled Intelligence
Want an AI News Brief every morning at 8am? A Roadmap Rundown on Fridays? Just add a recurring calendar event — PowerClaw handles the rest.

<p align="center">
  <img src="./Images/AINewsBriefMorning.png" alt="AI News Brief Calendar Event" width="800" />
</p>

---

## How It's Different

PowerClaw is inspired by [**OpenClaw**](https://github.com/openclaw/openclaw), the open-source autonomous AI agent platform. OpenClaw is powerful — but it requires infrastructure beyond Microsoft 365. PowerClaw brings the same concept, built **entirely within the M365 stack** you already have:

| | OpenClaw | PowerClaw |
|---|---|---|
| **Infrastructure** | Local server + Docker + API keys | M365 + Copilot Studio + Power Automate |
| **Data residency** | Your machine | Your M365 tenant |
| **Security** | Self-managed | Inherits your M365 policies |
| **Chat** | WhatsApp, Telegram, Discord | Microsoft Teams |
| **Setup** | Docker compose + config files | Import solution + run a flow (~15 min) |

> 💡 If security, compliance, or organizational policy is a blocker for external AI infrastructure, PowerClaw gets you started using tools your IT team already approves.

---

## Getting Started

PowerClaw is designed to be up and running in about 15 minutes. The setup is three steps:

1. **Import** the Copilot Studio solution into your environment
2. **Provision** your SharePoint workspace by running the included Bootstrap Flow
3. **Personalize** by editing `user.md` with your name, role, and preferences

That's it. The heartbeat starts automatically.

📖 **[Full Setup Guide →](SETUP.md)**

<details>
<summary><strong>Prerequisites</strong></summary>

| Requirement | Details |
|---|---|
| Microsoft 365 | E3 or E5 (for Graph API, SharePoint, Teams) |
| Copilot Studio | Per-user or capacity-based license |
| Power Automate | Premium license (for Copilot Studio connector) |
| Permissions | Ability to create a SharePoint site |

</details>

---

## Built as a Foundation

PowerClaw is intentionally lightweight — a starting point you can extend. Integrate it with Planner, To Do, or any Power Platform connector. Customize its personality, operating rules, and behavior by editing simple markdown files — no code changes required.

**Best for:** Innovation teams · Executive productivity · Internal AI enablement · Copilot Studio pilots

---

## Version History

| Date | Comments | Author |
|---|---|---|
| March 2026 | Initial release | Alejandro Lopez — alejanl@microsoft.com |

## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
