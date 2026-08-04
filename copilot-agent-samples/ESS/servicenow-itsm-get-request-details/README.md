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
- The **`ServiceNowITSMPortalBaseURI`** environment variable populated — see [Set the portal base URI](#-set-the-portal-base-uri-required-for-links)
- [ESS Maker Kit](https://github.com/microsoft/Employee-Self-Service-Agent-Developer-Kit/tree/main/solutions/ess-maker-skills) (for automated deployment via `push.py`)

---

## 🚀 Setup

> **⚠️ OBO (on-behalf-of) is required for this flow.** The ServiceNow connection uses
> `"runtimeSource": "invoker"`, so the flow calls ServiceNow **as the signed-in employee**,
> not as the maker. This is what keeps ServiceNow's own row-level ACLs in force — each user
> only sees requests they're entitled to. See [Configure OBO](#-configure-obo-required) below.

> **🔗 Also required:** set the `ServiceNowITSMPortalBaseURI` environment variable.
> It ships empty, and the "Open in ServiceNow" links render without a host until you set it.
> See [Set the portal base URI](#-set-the-portal-base-uri-required-for-links) below.

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

#### B1 — Import the solution

1. Go to [Power Apps](https://make.powerapps.com) and confirm the environment picker (top right) shows your target environment.
2. Select **Solutions** in the left nav, then **Import solution** on the command bar.
3. Select **Browse**, choose `solution/ESSServiceNowITSMGetRequestDetails_1_0_0_0.zip`, then **Next**.
4. On the **Connections** step, map **ESS Sample ServiceNow Connection** to your ServiceNow connection. If you don't have one, select **+ New connection**, create it, then return and select **Refresh**.
   - You will **not** be asked to map a Dataverse connection. The flows bind Dataverse through `new_sharedcommondataserviceforapps_41c83`, which is already in your environment courtesy of the ServiceNow extension pack.
5. Select **Import** and wait for the success banner.

#### B2 — Identify the two packaged workflow IDs

1. In [Power Automate](https://make.powerautomate.com), select **Solutions**, then open **ESS ServiceNow ITSM - Get Request Details**.
2. Confirm both flows show **Status: On**. If either is **Off**, open it and select **Turn on**.
   - `ESS IT ServiceNow ITSM Get Request Details`
   - `ESS IT ServiceNow ITSM Get Request Item`
3. Use these packaged workflow IDs in the matching system topics:

   ```text
   Get Request Details: 5750fc72-738f-412c-b9cb-5094507f2eb2
   Get Request Item:    917c7b14-8bcb-4492-bf4a-eb52cfadbc3d
   ```

   Do **not** copy the GUID from either Power Automate browser URL. Solution import creates a
   generated Power Automate resource ID for each URL, which can look like a second standalone
   flow. Each is the same imported flow, but it is **not** the Dataverse workflow ID used by the
   Copilot Studio `InvokeFlowAction`. Keep the two packaged IDs straight: swapping them sends REQ
   lookups to the RITM flow and vice versa, which fails silently with an empty card rather than an error.

#### B3 — Create the three topics

For each file in `topics/`:

1. In [Copilot Studio](https://copilotstudio.microsoft.com/), open your agent and select **Topics** → **+ Add a topic** → **From blank**.
2. Open the **⋮** menu and select **Open code editor**.
3. Paste the entire contents of the `.mcs.yml` file, replacing whatever is already there.
4. Set the topic name **exactly** as below. The name matters: the portal derives the topic's schema name from it, and the user-facing topic locates the system topics by schema name.

   | File | Topic name to use |
   |------|-------------------|
   | `ess-it-servicenow-itsm-system-get-request-details.mcs.yml` | `ESS IT ServiceNow ITSM System Get Request Details` |
   | `ess-it-servicenow-itsm-system-get-request-item.mcs.yml` | `ESS IT ServiceNow ITSM System Get Request Item` |
   | `servicenow-itsm-get-request-details.mcs.yml` | `ESS ServiceNow ITSM Get Request Details` |

5. In each **system** topic, replace `{FLOW_GUID}` with that topic's matching packaged workflow ID from B2:
   - `…system-get-request-details` → ID of **Get Request Details**
   - `…system-get-request-item` → ID of **Get Request Item**
6. In the **user-facing** topic, replace both `dialog:` values with the PascalCase schema names the portal generated:

   ```yaml
   dialog: msdyn_copilotforemployeeselfserviceit.topic.ESSITServiceNowITSMSystemGetRequestDetails
   dialog: msdyn_copilotforemployeeselfserviceit.topic.ESSITServiceNowITSMSystemGetRequestItem
   ```

   The shipped values are kebab-case (correct for Option A only). Leaving them produces
   `Dialog with id '…' not found` at publish — see the note under [Files](#-files).
7. **Save** each topic.

#### B4 — Publish

Select **Publish** in Copilot Studio. If publish reports `Dialog with id … not found`, revisit
step B3.6; if it reports `IncorrectTypeAssignment` alongside it, that's the same fault, not a
second one.

> The solution declares the ServiceNow connection as `"runtimeSource": "invoker"`, so an imported
> flow is wired for OBO from the start. You still need the connection-side step in B5.

#### B5 — Configure OBO (do this after publishing, before testing)

Both flows call ServiceNow **as the signed-in employee**, which requires parameter sharing on the
ServiceNow connection. This is configured in **Copilot Studio**, not Power Automate — follow
[Configure OBO](#-configure-obo-required) below.

> Publish the agent first. The imported flows do not appear under **Settings** → **Connection settings**
> until the agent has been published, so you cannot configure their connection parameters before B4.

### 🔗 Set the portal base URI (required for links)

Both flows in this sample resolve the "Open in ServiceNow" link base the same way the
out-of-the-box ESS orchestrator does:

1. the **`ServiceNowITSMPortalBaseURI`** environment variable's **current value**, then
2. that variable's **default value**, then
3. the `ServiceNowPortalBaseURI` property of the `msdyn_ServiceNowITSM` template
   configuration record.

**This environment variable ships empty**, and so does the template configuration
property. If you don't set one of them, the adaptive cards still render correctly,
but every "Open in ServiceNow" link points at `?id=ticket&table=...` with no host
and won't resolve.

1. Go to [make.powerapps.com](https://make.powerapps.com) → your environment →
   **Solutions** → **Default Solution** → **Environment variables**.
2. Open **ServiceNowITSMPortalBaseURI**.
3. Set the **Current value** to your ServiceNow portal base URL — no trailing
   slash, no query string:

   ```text
   https://<instance>.service-now.com/esc
   ```

   Use `/esc` for **Employee Center** or `/sp` for the classic **Service Portal**,
   whichever your employees use. To confirm which is default in your instance, go
   to **Service Portal → Portals** in ServiceNow and check the **URL suffix** of
   the portal flagged as default.
4. **Save**.

The topics append `?id=ticket&table=sc_request&sys_id=...` to this value, so a
finished link looks like:

```text
https://<instance>.service-now.com/esc?id=ticket&table=sc_request&sys_id=127a3aef8356cf1028e6cc65eeaad3d4
```

> This variable is shared with the out-of-the-box ServiceNow ITSM topics —
> setting it fixes their links too.

---

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

| Author | Original Publish Date | Latest Publish Date |
| --- | --- | --- |
| Dean Cron | 2026-07-30 | 2026-08-03 |
