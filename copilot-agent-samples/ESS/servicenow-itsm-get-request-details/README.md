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
| `topics/ess-it-servicenow-itsm-system-get-request-details.mcs.yml` | System topic — invokes the REQ flow |
| `topics/ess-it-servicenow-itsm-system-get-request-item.mcs.yml` | System topic — invokes the RITM flow |
| `workflows/get-request-details/` | Power Automate flow — queries `sc_request` by REQ number |
| `workflows/get-request-item/` | Power Automate flow — queries `sc_req_item` by RITM number |
| `solution/ESSServiceNowITSMGetRequestDetails_1_0_0_0.zip` | Unmanaged Power Platform solution containing **both** flows and their ServiceNow connection reference — **Option B** |

Each `workflows/*` folder ships the flow definition for the push-script path:

| File | Use it for |
|------|------------|
| `workflow.json` | Raw flow definition — **Option A** (ESS Maker Kit `push.py`) |
| `metadata.yml` | Flow metadata for the ESS Maker Kit push script |

> **Install all of it.** The user-facing topic references *both* system topics, so the pieces are not independently installable — deploy both flows and all three topics together.

> **⚠️ Topic schema names depend on how you install.** The user-facing topic reaches the two
> system topics by schema name, e.g.
> `dialog: msdyn_copilotforemployeeselfserviceit.topic.ess-it-servicenow-itsm-system-get-request-item`.
> How that schema name gets assigned differs by install path:
>
> | Install path | Schema name derived from | Result |
> |---|---|---|
> | **Option A** (`push.py`) | the **filename** | `…topic.ess-it-servicenow-itsm-system-get-request-item` |
> | **Option B** (Copilot Studio portal) | the **display name**, spaces removed | `…topic.ESSITServiceNowITSMSystemGetRequestItem` |
>
> The references in this sample are written for **Option A** and resolve as-is. If you install
> via the portal, update both `dialog:` lines in
> `topics/servicenow-itsm-get-request-details.mcs.yml` to the PascalCase form. A mismatch fails
> at publish with `Dialog with id '…' not found`, followed by a second, misleading
> `IncorrectTypeAssignment` error (`Assigned: Unspecified, expected: String`) — that one is a
> symptom of the unresolved reference, not a separate problem, and clears with it.
>
> Also note the `msdyn_copilotforemployeeselfserviceit` prefix is the **agent's** schema name.
> These topics target the ESS **IT** agent; retarget the prefix if your agent differs.

---

## ✅ Prerequisites

- Microsoft Employee Self-Service agent (deployed)
- ServiceNow ITSM extension pack installed in Copilot Studio
- An active ServiceNow connection in Power Platform configured for on-behalf-of (invoker) auth — see [Configure OBO](#-configure-obo-required)
- [ESS Maker Kit](https://github.com/microsoft/Employee-Self-Service-Agent-Developer-Kit/tree/main/solutions/ess-maker-skills) (for automated deployment via `push.py`)

---

## 🚀 Setup

> **⚠️ OBO (on-behalf-of) is required for this flow.** The ServiceNow connection uses
> `"runtimeSource": "invoker"`, so the flow calls ServiceNow **as the signed-in employee**,
> not as the maker. This is what keeps ServiceNow's own row-level ACLs in force — each user
> only sees requests they're entitled to. See [Configure OBO](#-configure-obo-required) below.

### Option A — [ESS Maker Kit](https://github.com/microsoft/Employee-Self-Service-Agent-Developer-Kit/tree/main/solutions/ess-maker-skills) (recommended)

This sample ships **two** flows. Generate a separate GUID for each and repeat the copy/replace for both.

1. Run `/setup` in your ESS Maker Kit workspace to connect to the environment.
2. Copy `topics/` → `workspace/agents/{slug}/topics/` (all three topic files).
3. Copy each flow into its own workspace folder:
   - `workflows/get-request-details/` → `workspace/agents/{slug}/workflows/ess-it-servicenow-itsm-get-request-details-{GUID-A}/`
   - `workflows/get-request-item/` → `workspace/agents/{slug}/workflows/ess-it-servicenow-itsm-get-request-item-{GUID-B}/`
4. Replace the placeholders **in each flow folder and its matching system topic**:
   - `{FLOW_GUID}` → `{GUID-A}` in `ess-it-servicenow-itsm-system-get-request-details.mcs.yml` and `get-request-details/metadata.yml`.
   - `{FLOW_GUID}` → `{GUID-B}` in `ess-it-servicenow-itsm-system-get-request-item.mcs.yml` and `get-request-item/metadata.yml`.
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in both `workflow.json` files, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
5. `python scripts/push.py`
6. **Configure OBO** — see below. Do this *before* turning the flows on.
7. Turn **both flows** on in [Power Automate](https://make.powerautomate.com) (API activation is blocked for invoker-auth ServiceNow flows).
8. `python scripts/push.py --repair "Get Request Details"` and `--repair "Get Request Item"` to wire topic → flow.
9. Publish the agent in Copilot Studio.

### Option B — Import the solution

The solution ships both flows plus its own ServiceNow connection reference
(`esss_servicenow`), so there is exactly one connection to map at import time.

1. In [Power Apps](https://make.powerapps.com), select your environment, then **Solutions** → **Import solution**.
2. **Browse** to `solution/ESSServiceNowITSMGetRequestDetails_1_0_0_0.zip` → **Next**.
3. Under **Connections**, map **ESS Sample ServiceNow Connection** to your ServiceNow connection (or create one inline). The Dataverse binding resolves to the connection reference already present from your ServiceNow extension pack — it is not part of this solution and needs no mapping.
4. Select **Import** and wait for it to complete.
5. **Configure OBO** — see below.
6. In [Power Automate](https://make.powerautomate.com), confirm **ESS IT ServiceNow ITSM Get Request Details** and **ESS IT ServiceNow ITSM Get Request Item** are **On**, and copy each flow ID from its URL.
7. In Copilot Studio, create the three topics from `topics/`, replacing `{FLOW_GUID}` in each system topic with its matching flow ID. Then update the two `dialog:` references in the user-facing topic to the portal's PascalCase schema names — see the schema-name note under [Files](#-files).
8. Publish.

> The solution declares the ServiceNow connection as `"runtimeSource": "invoker"`, so an imported
> flow is wired for OBO from the start. You still need the connection-side step below.

### 🔐 Configure OBO (required)

Both flows must call ServiceNow as the signed-in employee. Enable parameter sharing on the
ServiceNow connection backing **each** flow:

1. In [Copilot Studio](https://copilotstudio.microsoft.com/), select **Agents** and open your agent.
2. Select **Settings**, then **Connection Settings**.
3. Find the **ServiceNow** connection row. Under **Manage**, select **See details**.
4. Open the **Connection parameters** tab.
5. Turn on **Allow permission to share parameters**.
6. Select the checkboxes for the parameters you want the user to share.
7. Repeat for the connection entry of **each** flow (Get Request Details *and* Get Request Item).

Each employee is prompted to grant permission the first time the agent uses the connection on
their behalf. Full reference:
[Share connection parameters for On-Behalf-Of (OBO) authentication](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-connections#share-connection-parameters-for-on-behalf-of-obo-authentication).

You also need the ServiceNow side to permit those users — the OAuth application registry entry
must allow your Entra ID users, and they need read access to `sc_request` and `sc_req_item`.

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
