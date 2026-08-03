# ESS ServiceNow ITSM – Get Request Item (RITM)

## 📌 Overview

Extends the Microsoft Employee Self-Service (ESS) agent with the ability to look up **service catalog request items** (RITM numbers) from ServiceNow. This sample is the RITM counterpart to [`servicenow-itsm-get-request-details`](../servicenow-itsm-get-request-details/) — it adds a standalone flow that queries the `sc_req_item` table directly.

**This sample depends on `servicenow-itsm-get-request-details`.** The routing logic that decides "is this a REQ or a RITM?" lives in that sample's user-facing topic (`servicenow-itsm-get-request-details.mcs.yml`). Install both samples together — this one only supplies the system topic + flow that the shared topic redirects to for RITM numbers.

**Example conversation:**

> User: "Look up RITM0001234"  
> Agent: *[Adaptive card showing request item number, state, catalog item, parent request, assigned to, quantity, last updated, and a link to open in ServiceNow]*

---

## 📁 Files

| File | Purpose |
|------|---------|
| `topics/ess-hr-servicenow-itsm-system-get-request-item.mcs.yml` | System topic — routes to the standalone flow via `InvokeFlowAction` |
| `workflow/workflow.json` | Standalone Power Automate flow — queries `sc_req_item` by RITM number |
| `workflow/metadata.yml` | Flow metadata for the ESS Maker Kit push script |

> Note: there is no separate user-facing topic in this sample. RITM lookups are triggered by `servicenow-itsm-get-request-details.mcs.yml` (installed as part of the companion sample), which recognizes RITM-prefixed identifiers and redirects to the system topic here.

---

## 🚀 Setup

### Option A — ESS Maker Kit (recommended)

1. Install and set up the companion [`servicenow-itsm-get-request-details`](../servicenow-itsm-get-request-details/) sample first (its user-facing topic is required for RITM routing to work).
2. Copy the `topics/` file into `workspace/agents/{your-agent-slug}/topics/`.
3. Copy the `workflow/` folder into `workspace/agents/{your-agent-slug}/workflows/ess-hr-servicenow-itsm-get-request-item-{NEW-GUID}/`.
4. In **the system topic**, replace `{FLOW_GUID}` with the same GUID you used for the workflow folder name.
5. In **workflow.json**, replace `{SERVICENOW_CONNREF}` and `{DATAVERSE_CONNREF}` with your environment's connection reference logical names (find these in `workspace/agents/{slug}/connectionreferences.mcs.yml`).
6. In **workflow/metadata.yml**, replace `{FLOW_GUID}` with your chosen GUID.
7. Run `python scripts/push.py` to deploy.
8. Manually **turn on** the flow in [Power Automate](https://make.powerautomate.com) — activation via API is blocked for flows that use the ServiceNow connector with `runtimeSource: invoker`.
9. Run `python scripts/push.py --repair "Get Request Item"` to wire the topic→flow link.
10. Publish the agent in Copilot Studio.

### Option B — Manual

1. In Power Automate, import `workflow/workflow.json` as a new cloud flow.
2. Update the ServiceNow and Dataverse connection references to point to your environment's connections.
3. Turn the flow on. Note the flow's ID (visible in the Power Automate URL).
4. In Copilot Studio, open your ESS agent and create a new system topic using the YAML in `topics/` as the content — replacing `{FLOW_GUID}` with the flow ID from step 3.
5. Make sure the `servicenow-itsm-get-request-details` topic (from the companion sample) is installed and its `BeginDialog` reference to `ess-hr-servicenow-itsm-system-get-request-item` resolves to this new system topic.
6. Publish.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flow is created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 8 above).
- **Requires the companion sample** — this sample has no standalone trigger phrases of its own. Without `servicenow-itsm-get-request-details` installed, RITM input will not be routed here.
- **Reference fields** — `cat_item`, `request`, and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Reference_Fields` step normalizes these to plain display-value strings before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
