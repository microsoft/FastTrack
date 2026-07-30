---
title: ESS ServiceNow ITSM – Get Request Details
type: extension
category: Copilot Studio / Employee Self-Service
summary: Adds a topic to the Microsoft Employee Self-Service (ESS) agent that lets employees look up the status and details of a ServiceNow service catalog request (REQ number) via natural language.
author:
  - Dean Cron
version: 1.0.0
published: "2026-07-30"
tags:
  - ESS
  - Employee Self-Service
  - ServiceNow
  - ITSM
  - service catalog
  - sc_request
format: extension
whatItIs: >-
  A two-topic + standalone flow extension for the Microsoft Employee Self-Service
  (ESS) Copilot Studio agent. Employees can ask the agent about any service
  catalog request (REQ prefix) and receive a rich adaptive card showing the
  request number, state, description, who it's assigned to, and a direct link
  to ServiceNow.
whyUseIt:
  - The ESS shared ITSM orchestrator flow only supports incident (INC) lookups.
    This extension adds sc_request (REQ) support without modifying any shared flows.
  - Follows the ESS two-topic pattern (user-facing + system routing) for
    consistency with out-of-the-box ESS topics.
  - Uses the same msdyn_ServiceNowOutputFieldMapperPlugin for field renaming,
    keeping the response shape compatible with standard ESS adaptive card patterns.
howToUse: |-
  See the Setup section below.
prerequisites:
  - Microsoft Employee Self-Service agent (deployed)
  - ServiceNow ITSM extension pack installed in Copilot Studio
  - An active ServiceNow connection in Power Platform (Entra ID auth recommended)
  - ESS Maker Kit (for automated deployment via push.py)
---

# ESS ServiceNow ITSM – Get Request Details

## 📌 Overview

Extends the Microsoft Employee Self-Service (ESS) agent with the ability to look up **service catalog requests** (REQ numbers) from ServiceNow. The built-in ESS ITSM orchestrator only handles incidents (INC). This sample adds a standalone flow that queries the `sc_request` table directly.

**Example conversation:**

> User: "What's the status of my request REQ0012345?"  
> Agent: *[Adaptive card showing request number, state, description, assigned to, last updated, and a link to open in ServiceNow]*

---

## 📁 Files

| File | Purpose |
|------|---------|
| `topics/servicenow-itsm-get-request-details.mcs.yml` | User-facing topic — trigger phrases, AI input extraction, adaptive card |
| `topics/ess-hr-servicenow-itsm-system-get-request-details.mcs.yml` | System topic — routes to the standalone flow via `InvokeFlowAction` |
| `workflow/workflow.json` | Standalone Power Automate flow — queries `sc_request` by SysId |
| `workflow/metadata.yml` | Flow metadata for the ESS Maker Kit push script |

---

## 🚀 Setup

### Option A — ESS Maker Kit (recommended)

1. Open your ESS Maker Kit workspace and run `/setup` to connect to the target environment.
2. Copy the `topics/` files into `workspace/agents/{your-agent-slug}/topics/`.
3. Copy the `workflow/` folder into `workspace/agents/{your-agent-slug}/workflows/ess-hr-servicenow-itsm-get-request-details-{NEW-GUID}/`.
4. In **the system topic**, replace `{FLOW_GUID}` with the same GUID you used for the workflow folder name.
6. In **workflow.json**, replace `{SERVICENOW_CONNREF}` and `{DATAVERSE_CONNREF}` with your environment's connection reference logical names (find these in `workspace/agents/{slug}/connectionreferences.mcs.yml`).
7. In **workflow/metadata.yml**, replace `{FLOW_GUID}` with your chosen GUID.
8. Run `python scripts/push.py` to deploy.
9. Manually **turn on** the flow in [Power Automate](https://make.powerautomate.com) — activation via API is blocked for flows that use the ServiceNow connector with `runtimeSource: invoker`.
10. Run `python scripts/push.py --repair "Get Request Details"` to wire the topic→flow link.
11. Publish the agent in Copilot Studio.

### Option B — Manual

1. In Power Automate, import `workflow/workflow.json` as a new cloud flow.
2. Update the ServiceNow and Dataverse connection references to point to your environment's connections.
3. Turn the flow on. Note the flow's ID (visible in the Power Automate URL).
4. In Copilot Studio, open your ESS agent and create two new topics using the YAML in `topics/` as the content — replacing `{AGENT_SCHEMA_NAME}` with your schema name and `{FLOW_GUID}` with the flow ID from step 3.
5. Publish.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flow is created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 9 above).
- **sc_request fields** — the flow returns `request_state` (not `state`) and `requested_for` (not `caller_id`). The adaptive card handles this, but if you customise the output be aware the field names differ from the incident table.
- **SysId lookup only** — the flow looks up by SysId. The user-facing topic extracts the REQ number or SysId from the user's message. If only a REQ number is provided (not a SysId), ensure your ServiceNow instance returns records when queried by `number` field — you may need to adapt the flow to use a `GetRecords` filter instead of `GetRecord`.
