# ESS ServiceNow ITSM – Get Request Details (REQ + RITM)

## 📌 Overview

Extends the Microsoft Employee Self-Service (ESS) agent with the ability to look up **service catalog requests** (REQ) and **request items** (RITM) from ServiceNow. The built-in ESS ITSM orchestrator only handles incidents (INC), so this sample adds two standalone flows — one for `sc_request`, one for `sc_req_item`.

A **single user-facing topic** handles both. It extracts the identifier from the user's message and routes RITM-prefixed numbers to the request-item flow and everything else to the request flow.

**Example conversation:**

> User: "What's the status of my request REQ0012345?"  
> Agent: *[Adaptive card showing request number, state, description, requested for, assigned to, last updated, and a link to open in ServiceNow]*

> User: "Look up RITM0001234"  
> Agent: *[Adaptive card showing request item number, state, catalog item, parent request, assigned to, quantity, and a link to open in ServiceNow]*

---

## 📁 Files

| File | Purpose |
|------|---------|
| `topics/servicenow-itsm-get-request-details.mcs.yml` | User-facing topic — trigger phrases, AI input extraction, REQ/RITM routing, both adaptive cards |
| `topics/ess-hr-servicenow-itsm-system-get-request-details.mcs.yml` | System topic — invokes the REQ flow |
| `topics/ess-hr-servicenow-itsm-system-get-request-item.mcs.yml` | System topic — invokes the RITM flow |
| `workflows/get-request-details/` | Power Automate flow — queries `sc_request` by REQ number |
| `workflows/get-request-item/` | Power Automate flow — queries `sc_req_item` by RITM number |

Each `workflows/*` folder contains a `workflow.json` and a `metadata.yml`.

> **Install all of it.** The user-facing topic references *both* system topics, so the pieces are not independently installable — deploy both flows and all three topics together.

---

## ✅ Prerequisites

- Microsoft Employee Self-Service agent (deployed)
- ServiceNow ITSM extension pack installed in Copilot Studio
- An active ServiceNow connection in Power Platform configured for on-behalf-of (invoker) auth — see [Configure OBO](#-configure-obo-required)
- ESS Maker Kit (for automated deployment via `push.py`)

---

## 🚀 Setup

> **⚠️ OBO (on-behalf-of) is required for this flow.** The ServiceNow connection uses
> `"runtimeSource": "invoker"`, so the flow calls ServiceNow **as the signed-in employee**,
> not as the maker. This is what keeps ServiceNow's own row-level ACLs in force — each user
> only sees requests they're entitled to. See [Configure OBO](#-configure-obo-required) below.

### Option A — ESS Maker Kit (recommended)

This sample ships **two** flows. Generate a separate GUID for each and repeat the copy/replace for both.

1. Run `/setup` in your ESS Maker Kit workspace to connect to the environment.
2. Copy `topics/` → `workspace/agents/{slug}/topics/` (all three topic files).
3. Copy each flow into its own workspace folder:
   - `workflows/get-request-details/` → `workspace/agents/{slug}/workflows/ess-hr-servicenow-itsm-get-request-details-{GUID-A}/`
   - `workflows/get-request-item/` → `workspace/agents/{slug}/workflows/ess-hr-servicenow-itsm-get-request-item-{GUID-B}/`
4. Replace the placeholders **in each flow folder and its matching system topic**:
   - `{FLOW_GUID}` → `{GUID-A}` in `ess-hr-servicenow-itsm-system-get-request-details.mcs.yml` and `get-request-details/metadata.yml`.
   - `{FLOW_GUID}` → `{GUID-B}` in `ess-hr-servicenow-itsm-system-get-request-item.mcs.yml` and `get-request-item/metadata.yml`.
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in both `workflow.json` files, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
5. `python scripts/push.py`
6. **Configure OBO** — see below. Do this *before* turning the flows on.
7. Turn **both flows** on in [Power Automate](https://make.powerautomate.com) (API activation is blocked for invoker-auth ServiceNow flows).
8. `python scripts/push.py --repair "Get Request Details"` and `--repair "Get Request Item"` to wire topic → flow.
9. Publish the agent in Copilot Studio.

### Option B — Manual

1. Import **both** `workflows/*/workflow.json` files into Power Automate as new cloud flows.
2. Point the ServiceNow and Dataverse connection references at your environment's connections.
3. **Configure OBO** — see below.
4. Turn both flows on and copy each flow ID from its URL.
5. In Copilot Studio, create the three topics from `topics/`, replacing `{FLOW_GUID}` in each system topic with its matching flow ID.
6. Publish.

### 🔐 Configure OBO (required)

The ServiceNow connector must authenticate as the end user, not the maker:

1. In **Copilot Studio**, open your agent → **Settings** → **Generative AI / Connections**.
2. Select the **ServiceNow** connection and choose **Sign in on behalf of the user**
   (OAuth 2.0 with the user's identity) rather than a shared maker connection.
3. In ServiceNow, make sure the OAuth application registry entry allows the Entra ID users
   who will use the agent, and that those users have read access to `sc_request` and `sc_req_item`.
4. Each employee is prompted to sign in to ServiceNow **once**, on first use.

Confirm it worked: both `workflow.json` files should show `"runtimeSource": "invoker"` on the
ServiceNow connection reference after deployment. If either flips to `"embedded"`, that flow is
running as the maker and every user will see the maker's data — reconfigure before shipping.

> **Note:** configuring OBO through the Copilot Studio UI rewrites the flow's
> `connectionReferences` block (the connection key typically becomes `shared_service-now-1`).
> If you later re-export or re-push the flow, re-check that block so you don't overwrite the
> live OBO binding with a stale one.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flows are created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 7 above).
- **sc_request fields** — the REQ flow returns `request_state` (not `state`) and `requested_for` (not `caller_id`). The adaptive card handles this, but if you customise the output be aware the field names differ from the incident table.
- **Reference fields** — `requested_for`, `assigned_to`, `cat_item`, and `request` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). Each flow's `Flatten_Reference_Fields` step normalizes these to plain display-value strings before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
- **Result key** — the ServiceNow connector returns rows under `result` (ServiceNow Table API v2), *not* OData's `value`. Feeding `body(...)?['value']` to the output mapper yields `null` and fails with `A null value was found for the property named 'ServiceNowTableData'`. Keep the `?['result']` references intact if you customise these flows.

---

## Author

| Author | Original Publish Date |
| --- | --- |
| Dean Cron | 2026-07-30 |
