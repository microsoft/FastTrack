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

> **⚠️ OBO (on-behalf-of) is required for this flow.** The ServiceNow connection uses
> `"runtimeSource": "invoker"`, so the flow calls ServiceNow **as the signed-in employee**,
> not as the maker. This keeps ServiceNow's row-level ACLs in force. See
> [Configure OBO](#-configure-obo-required) below.

Install the companion [`servicenow-itsm-get-request-details`](../servicenow-itsm-get-request-details/) sample **first** — its user-facing topic supplies the RITM routing.

### Option A — ESS Maker Kit (recommended)

1. Copy `topics/` → `workspace/agents/{slug}/topics/`.
2. Copy `workflow/` → `workspace/agents/{slug}/workflows/ess-hr-servicenow-itsm-get-request-item-{NEW-GUID}/`.
3. Replace the placeholders:
   - `{FLOW_GUID}` — in the system topic **and** `workflow/metadata.yml` (use the GUID from step 2).
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in `workflow.json`, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
4. `python scripts/push.py`
5. **Configure OBO** — see below. Do this *before* turning the flow on.
6. Turn the flow **on** in [Power Automate](https://make.powerautomate.com) (API activation is blocked for invoker-auth ServiceNow flows).
7. `python scripts/push.py --repair "Get Request Item"` to wire topic → flow.
8. Publish the agent in Copilot Studio.

### Option B — Manual

1. Import `workflow/workflow.json` into Power Automate as a new cloud flow.
2. Point the ServiceNow and Dataverse connection references at your environment's connections.
3. **Configure OBO** — see below.
4. Turn the flow on and copy its ID from the URL.
5. In Copilot Studio, create the system topic from `topics/`, replacing `{FLOW_GUID}` with that ID.
6. Confirm the companion topic's `BeginDialog` reference to `ess-hr-servicenow-itsm-system-get-request-item` resolves.
7. Publish.

### 🔐 Configure OBO (required)

The ServiceNow connector must authenticate as the end user, not the maker:

1. In **Copilot Studio**, open your agent → **Settings** → **Generative AI / Connections**.
2. Select the **ServiceNow** connection and choose **Sign in on behalf of the user**
   rather than a shared maker connection.
3. In ServiceNow, ensure the OAuth application registry entry allows your Entra ID users,
   and that they have read access to `sc_req_item`.
4. Each employee signs in to ServiceNow **once**, on first use.

Confirm it worked: `workflow.json` should show `"runtimeSource": "invoker"` on the
ServiceNow connection reference after deployment. If it reads `"embedded"`, the flow is
running as the maker — reconfigure before shipping.

> **Note:** configuring OBO through the Copilot Studio UI rewrites the flow's
> `connectionReferences` block (the key typically becomes `shared_service-now-1`). If you
> re-export or re-push the flow later, re-check that block so you don't overwrite the live
> OBO binding with a stale one.

---

## ⚠️ Known Limitations

- **Activation via API fails** — when deploying via the Maker Kit push script, the flow is created but cannot be activated automatically. Power Platform validates the ServiceNow connection schema at activation time, which requires a live user session. Manual turn-on in Power Automate is required (step 8 above).
- **Requires the companion sample** — this sample has no standalone trigger phrases of its own. Without `servicenow-itsm-get-request-details` installed, RITM input will not be routed here.
- **Reference fields** — `cat_item`, `request`, and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Reference_Fields` step normalizes these to plain display-value strings before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
