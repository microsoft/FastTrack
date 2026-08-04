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
| `topics/ess-it-servicenow-itsm-get-user-requests.mcs.yml` | User-facing topic — trigger phrases, state extraction, cache check, list rendering |
| `topics/ess-it-servicenow-itsm-system-get-user-requests.mcs.yml` | System topic — routes to the standalone flow and populates the 15-min cache |
| `workflow/workflow.json` | Raw flow definition — queries `sc_request` filtered by user email + active state; used by **Option A** |
| `workflow/metadata.yml` | Flow metadata for the ESS Maker Kit push script |
| `solution/ESSServiceNowITSMGetUserRequests_1_0_0_0.zip` | Unmanaged Power Platform solution containing the flow and its ServiceNow connection reference — **Option B** |

> **⚠️ Topic schema names depend on how you install.** The user-facing topic reaches the system
> topic by schema name, e.g.
> `dialog: msdyn_copilotforemployeeselfserviceit.topic.ess-it-servicenow-itsm-system-get-user-requests`
> (two occurrences). How that schema name gets assigned differs by install path:
>
> | Install path | Schema name derived from | Result |
> |---|---|---|
> | **Option A** (`push.py`) | the **filename** | `…topic.ess-it-servicenow-itsm-system-get-user-requests` |
> | **Option B** (Copilot Studio portal) | the **display name**, spaces removed | `…topic.ESSITServiceNowITSMSystemGetUserRequests` |
>
> The references in this sample are written for **Option A** and resolve as-is. If you install
> via the portal, update both `dialog:` lines in
> `topics/ess-it-servicenow-itsm-get-user-requests.mcs.yml` to the PascalCase form. A mismatch
> fails at publish with `Dialog with id '…' not found`, followed by a second, misleading
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
> not as the maker. This keeps ServiceNow's own row-level ACLs in force — each user only sees
> requests they're entitled to. See [Configure OBO](#-configure-obo-required) below.

> **🔗 Also required:** set the `ServiceNowITSMPortalBaseURI` environment variable.
> It ships empty, and the "Open in ServiceNow" links render without a host until you set it.
> See [Set the portal base URI](#-set-the-portal-base-uri-required-for-links) below.

### Option A — [ESS Maker Kit](https://github.com/microsoft/Employee-Self-Service-Agent-Developer-Kit/tree/main/solutions/ess-maker-skills) (recommended)

1. Run `/setup` in your ESS Maker Kit workspace to connect to the environment.
2. Copy `topics/` → `workspace/agents/{slug}/topics/`.
3. Copy `workflow/` → `workspace/agents/{slug}/workflows/ess-it-servicenow-itsm-get-user-requests-{NEW-GUID}/`.
4. Replace the placeholders:
   - `{FLOW_GUID}` — in the system topic **and** `workflow/metadata.yml` (use the GUID from step 3).
   - `{SERVICENOW_CONNREF}` / `{DATAVERSE_CONNREF}` — in `workflow.json`, from `workspace/agents/{slug}/connectionreferences.mcs.yml`.
5. `python scripts/push.py`
6. **Configure OBO** — see below. Do this *before* turning the flow on.
7. Turn the flow **on** in [Power Automate](https://make.powerautomate.com) (API activation is blocked for ServiceNow flows).
8. `python scripts/push.py --repair "Get User Requests"` to wire topic → flow.
9. Publish the agent in Copilot Studio.

### Option B — Import the solution

The solution ships the flow plus its own ServiceNow connection reference
(`esss_servicenow`), so there is exactly one connection to map at import time.

#### B1 — Import the solution

1. Go to [Power Apps](https://make.powerapps.com) and confirm the environment picker (top right) shows your target environment.
2. Select **Solutions** in the left nav, then **Import solution** on the command bar.
3. Select **Browse**, choose `solution/ESSServiceNowITSMGetUserRequests_1_0_0_0.zip`, then **Next**.
4. On the **Connections** step, map **ESS Sample ServiceNow Connection** to your ServiceNow connection. If you don't have one, select **+ New connection**, create it, then return and select **Refresh**.
   - You will **not** be asked to map a Dataverse connection. The flow binds Dataverse through `new_sharedcommondataserviceforapps_41c83`, which is already in your environment courtesy of the ServiceNow extension pack.
5. Select **Import** and wait for the success banner.

#### B3 — Collect the flow ID

1. In [Power Automate](https://make.powerautomate.com), select **Solutions**, then open **ESS ServiceNow ITSM - Get User Requests**.
2. Confirm **ESS IT ServiceNow ITSM Get User Requests** shows **Status: On**. If it's **Off**, open it and select **Turn on**.
3. Open the flow and read its ID from the browser address bar — it's the GUID immediately after `/flows/`:

   ```text
   https://make.powerautomate.com/environments/{env}/solutions/{sol}/flows/5f08a17c-ed32-42ea-bbe4-29da0e9e98b1/details
                                                                           └──────────── flow ID ────────────┘
   ```

#### B4 — Create the two topics

For each file in `topics/`:

1. In [Copilot Studio](https://copilotstudio.microsoft.com/), open your agent and select **Topics** → **+ Add a topic** → **From blank**.
2. Open the **⋮** menu and select **Open code editor**.
3. Paste the entire contents of the `.mcs.yml` file, replacing whatever is already there.
4. Set the topic name **exactly** as below. The name matters: the portal derives the topic's schema name from it, and the user-facing topic locates the system topic by schema name.

   | File | Topic name to use |
   |------|-------------------|
   | `ess-it-servicenow-itsm-system-get-user-requests.mcs.yml` | `ESS IT ServiceNow ITSM System Get User Requests` |
   | `ess-it-servicenow-itsm-get-user-requests.mcs.yml` | `ESS IT ServiceNow ITSM Get User Requests` |

5. In the **system** topic, replace `{FLOW_GUID}` with the flow ID from B3.
6. In the **user-facing** topic, replace **both** `dialog:` values (they appear twice — once in the all-requests branch, once in the filtered branch) with the PascalCase schema name the portal generated:

   ```yaml
   dialog: msdyn_copilotforemployeeselfserviceit.topic.ESSITServiceNowITSMSystemGetUserRequests
   ```

   The shipped values are kebab-case (correct for Option A only). Leaving them produces
   `Dialog with id '…' not found` at publish — see the note under [Files](#-files).
7. **Save** each topic.

#### B5 — Publish

Select **Publish** in Copilot Studio. If publish reports `Dialog with id … not found`, revisit
step B4.6; if it reports `IncorrectTypeAssignment` alongside it, that's the same fault, not a
second one.

> The solution declares the ServiceNow connection as `"runtimeSource": "invoker"`, so an imported
> flow is wired for OBO from the start. You still need the connection-side step in B6.

#### B6 — Configure OBO (do this after publishing, before testing)

The flow calls ServiceNow **as the signed-in employee**, which requires parameter sharing on the
ServiceNow connection. This is configured in **Copilot Studio**, not Power Automate — follow
[Configure OBO](#-configure-obo-required) below.

> Publish the agent first. The imported flow does not appear under **Settings** → **Connection settings**
> until the agent has been published, so you cannot configure its connection parameters before B5.

### 🔗 Set the portal base URI (required for links)

The flow in this sample resolve the "Open in ServiceNow" link base the same way the
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

The flow must call ServiceNow as the signed-in employee so ServiceNow enforces per-user access
itself. Enable parameter sharing on the ServiceNow connection backing this flow:

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

Confirm it worked: `workflow.json` should still show `"runtimeSource": "invoker"` on the
ServiceNow connection reference after deployment. If it flips to `"embedded"`, the flow is
running as the maker — every user would see the maker's data, so reconfigure before shipping.

The `requested_for.email` filter stays in the query regardless. With OBO it's defence-in-depth
rather than the sole isolation boundary. Note that the 15-minute cache is per-user under OBO.

> **Note:** configuring OBO through the Copilot Studio UI rewrites the flow's
> `connectionReferences` block (the key typically becomes `shared_service-now-1`). If you
> re-export or re-push the flow later, re-check that block so you don't overwrite the live
> OBO binding with a stale one.

---

## ⚠️ Known Limitations

- **Activation via API fails** — same as other ServiceNow standalone flows in this collection. Manual turn-on in Power Automate is required.
- **Per-user cache** — because the flow runs as the invoker, the 15-minute cache holds each employee's own results. It is not shared across users.
- **Global cache variables** — the topic uses `Global.ESS_ServiceNow_AllRequests` and `Global.ESS_ServiceNow_NextAllRequestsRefresh`. These are agent-scoped global variables — ensure they don't conflict with other topics in your agent.
- **Reference fields** — `requested_for` and `assigned_to` come back from `GetRecords` as `{display_value, link}` objects when populated (or an empty string when not set). The flow's `Flatten_Request_Records` **Select** step normalizes these to plain display-value strings across every row before mapping — if you add more reference fields to `sysparm_fields`, apply the same flatten pattern.
- **Result key** — the ServiceNow connector returns rows under `result` (ServiceNow Table API v2), *not* OData's `value`. Feeding `body(...)?['value']` to the output mapper yields `null` and fails with `A null value was found for the property named 'ServiceNowTableData'`. Keep the `?['result']` references intact if you customise this flow.

---

## Author

| Author | Original Publish Date | Latest Publish Date |
| --- | --- | --- |
| Dean Cron | 2026-07-30 | 2026-08-03 |
