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

## ✅ Prerequisites

- Microsoft Employee Self-Service agent (deployed)
- ServiceNow ITSM extension pack installed in Copilot Studio
- An active ServiceNow connection in Power Platform — this sample ships with the maker's `embedded` connection; on-behalf-of (`invoker`) auth is strongly recommended, see [Configure OBO](#-configure-obo-strongly-recommended)
- ESS Maker Kit (for automated deployment via `push.py`)

---

## 🚀 Setup

> **⚠️ Read the OBO note first.** Unlike the other ServiceNow samples in this collection,
> this flow ships with `"runtimeSource": "embedded"` — it calls ServiceNow as the **maker**,
> and relies on a `requested_for.email` filter for isolation. For most tenants you should
> switch it to OBO. See [Configure OBO](#-configure-obo-strongly-recommended) below.

### Option A — ESS Maker Kit (recommended)

1. Run `/setup` in your ESS Maker Kit workspace to connect to the environment.
2. Copy `topics/` → `workspace/agents/{slug}/topics/`.
3. Copy `workflow/` → `workspace/agents/{slug}/workflows/ess-hr-servicenow-itsm-get-user-requests-{NEW-GUID}/`.
4. Replace the placeholders:
   - `{FLOW_GUID}` — in the system topic **and** `workflow/metadata.yml` (use the GUID from step 3).
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in `workflow.json`, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
5. `python scripts/push.py`
6. **Decide on OBO vs embedded** — see below. Do this *before* turning the flow on.
7. Turn the flow **on** in [Power Automate](https://make.powerautomate.com) (API activation is blocked for ServiceNow flows).
8. `python scripts/push.py --repair "Get User Requests"` to wire topic → flow.
9. Publish the agent in Copilot Studio.

### Option B — Manual

1. Import `workflow/workflow.json` into Power Automate as a new cloud flow.
2. Point the ServiceNow and Dataverse connection references at your environment's connections.
3. **Decide on OBO vs embedded** — see below.
4. Turn the flow on and copy its ID from the URL.
5. In Copilot Studio, create the two topics from `topics/`, replacing `{FLOW_GUID}` with that ID.
6. Publish.

### 🔐 Configure OBO (strongly recommended)

**As shipped (`embedded`):** the flow uses the maker's ServiceNow connection. Users are
isolated only by the `requested_for.email = UserIdentifier` filter in the query — ServiceNow's
own ACLs are evaluated against the *maker's* account. That means the maker needs broad read
access to `sc_request`, and a bug or prompt-injection in the filter could expose other users' data.

**Switch to OBO (`invoker`)** so ServiceNow enforces per-user access itself. Enable parameter
sharing on the ServiceNow connection backing this flow:

1. In [Copilot Studio](https://copilotstudio.microsoft.com/), select **Agents** and open your agent.
2. Select **Settings**, then **Connection Settings**.
3. Find the **ServiceNow** connection row. Under **Manage**, select **See details**.
4. Open the **Connection parameters** tab.
5. Turn on **Allow permission to share parameters**.
6. Select the checkboxes for the parameters you want the user to share.

Each employee is prompted to grant permission the first time the agent uses the connection on
their behalf. Full reference:
[Share connection parameters for On-Behalf-Of (OBO) authentication](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-connections#share-connection-parameters-for-on-behalf-of-obo-authentication).

On the ServiceNow side, ensure the OAuth application registry entry allows your Entra ID users
and that they have read access to `sc_request`.

Afterwards, confirm `workflow.json` shows `"runtimeSource": "invoker"` on the ServiceNow
connection reference. Keep the `requested_for.email` filter — with OBO it becomes
defence-in-depth rather than the sole isolation boundary.

Trade-off: OBO prompts each employee to grant permission once, and the 15-minute cache
becomes per-user. Stay on `embedded` only if every agent user is meant to see the same data.

> **Note:** configuring OBO through the Copilot Studio UI rewrites the flow's
> `connectionReferences` block (the key typically becomes `shared_service-now-1`). If you
> re-export or re-push the flow later, re-check that block so you don't overwrite the live
> OBO binding with a stale one.

---

## ⚠️ Known Limitations

- **Activation via API fails** — same as other ServiceNow standalone flows in this collection. Manual turn-on in Power Automate is required.
- **Embedded connection by default** — as shipped the flow runs as the maker, not the invoker. See [Configure OBO](#-configure-obo-strongly-recommended) for the trade-off and how to switch.
- **Global cache variables** — the topic uses `Global.ESS_ServiceNow_AllRequests` and `Global.ESS_ServiceNow_NextAllRequestsRefresh`. These are agent-scoped global variables — ensure they don't conflict with other topics in your agent.
- **Reference fields** — `requested_for` and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Request_Records` **Select** step normalizes these to plain display-value strings across every row before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
- **Result key** — the ServiceNow connector returns rows under `result` (ServiceNow Table API v2), *not* OData's `value`. Feeding `body(...)?['value']` to the output mapper yields `null` and fails with `A null value was found for the property named 'ServiceNowTableData'`. Keep the `?['result']` references intact if you customise this flow.

---

## Author

| Author | Original Publish Date |
| --- | --- |
| Dean Cron | 2026-07-30 |
