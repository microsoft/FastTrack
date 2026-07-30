---
title: ESS ServiceNow ITSM – Get User Requests
type: extension
category: Copilot Studio / Employee Self-Service
summary: Adds a topic to the Microsoft Employee Self-Service (ESS) agent that lets employees list their ServiceNow service catalog requests (REQ numbers) via natural language.
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
  (ESS) Copilot Studio agent. Employees can ask the agent for a list of their
  service catalog requests — filtered by state (active, inactive, or all) — and
  receive a numbered list with direct ServiceNow links.
whyUseIt:
  - The ESS shared ITSM orchestrator flow only supports listing incidents (INC).
    This extension adds sc_request (REQ) list support without modifying any shared flows.
  - Includes a 15-minute cache for "all requests" queries (matching the Get User Tickets pattern).
  - Pairs naturally with the ESS ServiceNow ITSM – Get Request Details sample for
    full REQ request management.
howToUse: |-
  See the Setup section below.
prerequisites:
  - Microsoft Employee Self-Service agent (deployed)
  - ServiceNow ITSM extension pack installed in Copilot Studio
  - An active ServiceNow connection in Power Platform (maker's embedded connection)
  - ESS Maker Kit (for automated deployment via push.py)
---

# ESS ServiceNow ITSM – Get User Requests

## 📌 Overview

Extends the Microsoft Employee Self-Service (ESS) agent with the ability to list a user's **service catalog requests** (REQ numbers) from ServiceNow. The built-in ESS ITSM orchestrator only handles incident lists (INC). This sample adds a standalone flow that queries the `sc_request` table directly.

**Example conversations:**

> User: "Show me my open requests"  
> Agent: *[Numbered list of active REQ items with links]*

> User: "What requests have I submitted?"  
> Agent: *[Numbered list of all REQ items, most recently updated first]*

---

## 📁 Files

| File | Purpose |
|------|---------|
| `topics/ess-hr-servicenow-itsm-get-user-requests.mcs.yml` | User-facing topic — trigger phrases, state extraction, cache check, list rendering |
| `topics/ess-hr-servicenow-itsm-system-get-user-requests.mcs.yml` | System topic — routes to the standalone flow and populates the 15-min cache |
| `workflow/workflow.json` | Standalone Power Automate flow — queries `sc_request` filtered by user email + active state |
| `workflow/metadata.yml` | Flow metadata for the ESS Maker Kit push script |

---

## 🚀 Setup

### Option A — ESS Maker Kit (recommended)

1. Open your ESS Maker Kit workspace and run `/setup` to connect to the target environment.
2. Copy the `topics/` files into `workspace/agents/{your-agent-slug}/topics/`.
3. Copy the `workflow/` folder into `workspace/agents/{your-agent-slug}/workflows/ess-hr-servicenow-itsm-get-user-requests-{NEW-GUID}/`.
4. In **the system topic**, replace `{FLOW_GUID}` with the same GUID you used for the workflow folder name.
5. In **workflow.json**, replace `{SERVICENOW_CONNREF}` and `{DATAVERSE_CONNREF}` with your environment's connection reference logical names (find these in `workspace/agents/{slug}/connectionreferences.mcs.yml`).
6. In **workflow/metadata.yml**, replace `{FLOW_GUID}` with your chosen GUID.
7. Run `python scripts/push.py` to deploy.
8. Manually **turn on** the flow in [Power Automate](https://make.powerautomate.com) — activation via API is blocked for flows that use the ServiceNow connector.
9. Run `python scripts/push.py --repair "Get User Requests"` to wire the topic→flow link.
10. Publish the agent in Copilot Studio.

### Option B — Manual

1. In Power Automate, create a new cloud flow. Add a **Copilot Studio → When Copilot Studio calls a flow** trigger with inputs: `UserIdentifier` (Text) and `IsActive` (Text).
2. Add a **ServiceNow → List Records** action on the `sc_request` table. Set the filter query to build from the inputs (active/inactive/all based on `IsActive`), select fields `number,short_description,request_state,requested_for,assigned_to,sys_updated_on,sys_id,price`, limit 10.
3. Add the **Dataverse → Perform an unbound action** step calling `msdyn_ServiceNowOutputFieldMapperPlugin` to rename the fields.
4. Return the mapped output via a **Respond to Copilot** action.
5. Note the flow ID and update the system topic's `flowId` field.
6. In Copilot Studio, open your ESS agent and create two new topics using the YAML in `topics/` — replacing `{FLOW_GUID}` with the flow ID from step 5.
7. Publish.

---

## ⚠️ Known Limitations

- **Activation via API fails** — same as other ServiceNow standalone flows in this collection. Manual turn-on in Power Automate is required.
- **Embedded connection** — the list flow uses `runtimeSource: embedded` (maker's connection), not the invoker's credentials. The filter `requested_for.email = UserIdentifier` ensures each user only sees their own requests, but ServiceNow row-level ACLs are evaluated against the maker's account. Ensure the maker's ServiceNow account has read access to `sc_request`.
- **Global cache variables** — the topic uses `Global.ESS_ServiceNow_AllRequests` and `Global.ESS_ServiceNow_NextAllRequestsRefresh`. These are agent-scoped global variables — ensure they don't conflict with other topics in your agent.
