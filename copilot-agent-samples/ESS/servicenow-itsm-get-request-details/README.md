# ESS ServiceNow ITSM – Get Request Details

## 📌 Overview

Extends the Microsoft Employee Self-Service (ESS) agent with the ability to look up **service catalog requests** (REQ numbers) from ServiceNow. The built-in ESS ITSM orchestrator only handles incidents (INC). This sample adds a standalone flow that queries the `sc_request` table directly.

The user-facing topic also **routes RITM (request item) numbers** to the companion [`servicenow-itsm-get-request-item`](../servicenow-itsm-get-request-item/) sample — install that sample too if you want RITM lookups to work. Without it, RITM input is still recognized but the routed dialog reference won't resolve.

**Example conversation:**

> User: "What's the status of my request REQ0012345?"  
> Agent: *[Adaptive card showing request number, state, description, assigned to, last updated, and a link to open in ServiceNow]*

> User: "Look up RITM0001234"  
> Agent: *[Adaptive card showing request item number, state, catalog item, parent request, assigned to, and a link to open in ServiceNow — requires the companion `servicenow-itsm-get-request-item` sample]*

---

## 📁 Files

| File | Purpose |
|------|---------|
| `topics/servicenow-itsm-get-request-details.mcs.yml` | User-facing topic — trigger phrases, AI input extraction, REQ/RITM routing, adaptive card |
| `topics/ess-hr-servicenow-itsm-system-get-request-details.mcs.yml` | System topic — routes to the standalone flow via `InvokeFlowAction` |
| `workflow/workflow.json` | Standalone Power Automate flow — queries `sc_request` by REQ number |
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
4. In Copilot Studio, open your ESS agent and create two new topics using the YAML in `topics/` as the content — replacing `{FLOW_GUID}` with the flow ID from step 3.
5. Publish.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flow is created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 9 above).
- **sc_request fields** — the flow returns `request_state` (not `state`) and `requested_for` (not `caller_id`). The adaptive card handles this, but if you customise the output be aware the field names differ from the incident table.
- **Reference fields** — `requested_for` and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Reference_Fields` step normalizes these to plain display-value strings before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
- **RITM lookups require the companion sample** — the user-facing topic recognizes RITM numbers and routes them to `ess-hr-servicenow-itsm-system-get-request-item`, but that system topic and its flow live in the separate `servicenow-itsm-get-request-item` sample. Install both samples together for full REQ + RITM coverage.
