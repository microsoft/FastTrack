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

> **⚠️ OBO (on-behalf-of) is required for this flow.** The ServiceNow connection uses
> `"runtimeSource": "invoker"`, so the flow calls ServiceNow **as the signed-in employee**,
> not as the maker. This is what keeps ServiceNow's own row-level ACLs in force — each user
> only sees requests they're entitled to. See [Configure OBO](#-configure-obo-required) below.

### Option A — ESS Maker Kit (recommended)

1. Run `/setup` in your ESS Maker Kit workspace to connect to the environment.
2. Copy `topics/` → `workspace/agents/{slug}/topics/`.
3. Copy `workflow/` → `workspace/agents/{slug}/workflows/ess-hr-servicenow-itsm-get-request-details-{NEW-GUID}/`.
4. Replace the placeholders:
   - `{FLOW_GUID}` — in the system topic **and** `workflow/metadata.yml` (use the GUID from step 3).
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in `workflow.json`, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
5. `python scripts/push.py`
6. **Configure OBO** — see below. Do this *before* turning the flow on.
7. Turn the flow **on** in [Power Automate](https://make.powerautomate.com) (API activation is blocked for invoker-auth ServiceNow flows).
8. `python scripts/push.py --repair "Get Request Details"` to wire topic → flow.
9. Publish the agent in Copilot Studio.

### Option B — Manual

1. Import `workflow/workflow.json` into Power Automate as a new cloud flow.
2. Point the ServiceNow and Dataverse connection references at your environment's connections.
3. **Configure OBO** — see below.
4. Turn the flow on and copy its ID from the URL.
5. In Copilot Studio, create the two topics from `topics/`, replacing `{FLOW_GUID}` with that ID.
6. Publish.

### 🔐 Configure OBO (required)

The ServiceNow connector must authenticate as the end user, not the maker:

1. In **Copilot Studio**, open your agent → **Settings** → **Generative AI / Connections**.
2. Select the **ServiceNow** connection and choose **Sign in on behalf of the user**
   (OAuth 2.0 with the user's identity) rather than a shared maker connection.
3. In ServiceNow, make sure the OAuth application registry entry allows the Entra ID users
   who will use the agent, and that those users have read access to `sc_request`.
4. Each employee is prompted to sign in to ServiceNow **once**, on first use.

Confirm it worked: `workflow.json` should show `"runtimeSource": "invoker"` on the
ServiceNow connection reference after deployment. If it flips to `"embedded"`, the flow is
running as the maker and every user will see the maker's data — reconfigure before shipping.

> **Note:** configuring OBO through the Copilot Studio UI rewrites the flow's
> `connectionReferences` block (the connection key typically becomes `shared_service-now-1`).
> If you later re-export or re-push the flow, re-check that block so you don't overwrite the
> live OBO binding with a stale one.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flow is created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 9 above).
- **sc_request fields** — the flow returns `request_state` (not `state`) and `requested_for` (not `caller_id`). The adaptive card handles this, but if you customise the output be aware the field names differ from the incident table.
- **Reference fields** — `requested_for` and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Reference_Fields` step normalizes these to plain display-value strings before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
- **RITM lookups require the companion sample** — the user-facing topic recognizes RITM numbers and routes them to `ess-hr-servicenow-itsm-system-get-request-item`, but that system topic and its flow live in the separate `servicenow-itsm-get-request-item` sample. Install both samples together for full REQ + RITM coverage.
