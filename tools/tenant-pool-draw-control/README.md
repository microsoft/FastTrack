---
title: Tenant Pool Draw Control
type: app
category: Copilot Managed Runtime
summary: Turn off Copilot Credits tenant pool draw across many Power Platform environments at once, with read-back and an audit log.
author: Jake Stoker
version: 1.0.0
published: "2026-11-13"
updated: "2026-11-13"
tags:
  - copilot-credits
  - power-platform
  - copilot-managed-runtime
  - governance
  - capacity
format: bundle
featured: false
status: preview
whatItIs: >-
  A Copilot Managed Runtime (App Builder) app that lists the Power Platform environments you can
  administer and turns off, or back on, "Draw from the available capacity in my tenant" for Copilot
  Credits. It changes one environment, a ticked selection, or every environment of chosen types,
  previews each change, reads it back to confirm it applied, and keeps a change log with CSV export.
whyUseIt:
  - "Cap environments at their own Copilot Credits allocation without switching pool draw off one environment at a time in the Power Platform admin center."
  - "Confirm every change by read-back and keep a CSV audit log with one row per environment per change."
  - "See environments controlled by an environment-group rule reported as locked by policy and left unchanged."
howToUse: |-
  1. Review the Requirements section: an admin role, the Power Platform for Admins V2 connector allowed by your policies, and a Copilot Managed Runtime spending policy.
  2. Follow Running it: attach the app source as a zip in the Copilot app's Code tab with the prompt provided, and let Copilot build the app in your tenant.
  3. Publish the app, test on one non-production environment, and check the change log shows Confirmed before using the bulk options.
prerequisites:
  - "Power Platform administrator (or a role allowed to manage capacity allocations)"
  - "Power Platform for Admins V2 connector allowed by data policies and environment-group connector policies"
  - "Copilot Managed Runtime spending policy for the people who open the app"
  - "Copilot license and a Copilot Code spending policy for the person building the app"
---

# Tenant Pool Draw Control

Turn off **"Draw from the available capacity in my tenant"** for Copilot Credits across many
Power Platform environments at once, from one screen.

When pool draw is off, an environment can only consume the Copilot Credits explicitly
allocated to it. With an allocation of 0, agents in that environment cannot consume
Copilot Credits at all until credits are allocated or pool draw is turned back on.

> **Getting started:** check the [Requirements](#requirements) (including the Copilot Managed
> Runtime spending policy), then upload this zip to the Copilot app's **Code** tab together with
> the prompt in [Running it](#running-it). Copilot builds the app in your tenant from it.

## What it does

- Lists every environment you can administer, with its environment group, type, and current
  Copilot Credits allocation and pool-draw setting.
- **Pick environments yourself:** flip the switch on one environment, or tick several and use
  the selection bar (Disable / Enable for selected). Every change is
  previewed first (including the exact API request) and read back afterwards to confirm it stuck.
- **Disable by rule:** choose environment types, then click **Disable now** to turn pool draw
  off for every environment of those types, on the page of environments currently loaded, that
  still has it on. This ignores your ticked
  selection. Use it to catch newly created environments. (The "New" badge window only
  highlights recent environments and doesn't change what the rule disables.)
- Bulk changes show live progress ("working on 3 of 10"), the environment being changed, and
  a final summary of confirmed, locked and unconfirmed changes.
- Change log of what was changed, locked or not confirmed (stored in the browser), with a
  **Download CSV** option: one row per environment per change (run ID, time, action, whether it
  came from the rule / a selection / a switch, environment name and ID, result and reason), so
  runs over hundreds of environments are fully recorded. Each finished run also offers
  **Download results** for just that run.
- Environments whose setting is enforced by an environment-group rule are reported as
  **locked by policy** and left unchanged.

## Recommended for new environments: environment-group rule

The API (and therefore this app) changes environments that already exist. To cover new
environments automatically, use the built-in rule:

1. Power Platform admin center → **Manage → Environment groups** → your group → **Rules**.
2. Turn off **Cost controls → Draw from tenant credit pool**, then **Publish rules**.
3. Use **environment routing** so new environments land in that group.

Use the app for bulk changes to existing environments, auditing, and environments outside
governed groups.

## How it works

All calls go through the **Power Platform for Admins V2** connector
(`shared_powerplatformadminv2`), which wraps the Power Platform API:

| Purpose | Operation | Endpoint |
|---|---|---|
| List environments | `ListEnvironmentsForUser` | `GET /environmentmanagement/environments?api-version=2022-03-01-preview` |
| Read allocations (all) | `ListAllocationsByEnvironment` | `GET /licensing/allocationsByEnvironment?api-version=2024-10-01` |
| Read allocation (one) | `GetAllocationsByEnvironment` | `GET /licensing/allocationsByEnvironment/{environmentId}?api-version=2024-10-01` |
| Change pool draw | `PutAllocationsV2` | `PUT /licensing/allocationsV2?api-version=2024-10-01` |
| Group names | `ListEnvironmentGroups` | `GET /environmentmanagement/environmentGroups?api-version=2024-10-01` |

Request body used to turn pool draw off. The app first reads the environment's current
allocation and sends it back unchanged: the same quantity and every existing rule (for example an
**Alert** rule with its `ruleData`). Only the `TenantPool` flag changes:

```json
{
  "scope": { "environmentId": "<environment-id>" },
  "allocatedEntitlements": [
    {
      "entitlementId": "MCSMessages",
      "allocation": { "quantity": 5000 },
      "enforcementRules": [
        { "ruleType": "TenantPool", "enabled": false },
        { "ruleType": "Alert", "enabled": false, "ruleData": {} }
      ]
    }
  ]
}
```

After each change the app reads the environment back and marks it **Confirmed** only if pool draw
has the new value **and** everything else in the allocation record (quantities and other rules) is
unchanged. If the current record can't be read reliably, nothing is sent.

Notes:

- There's no API call that changes only the pool-draw setting, so the app reads the current record
  and sends it back with just that flag changed. Tested against the live API:
  - A `PUT allocationsV2` with only the `TenantPool` rule is accepted with **200 OK** but not
    applied, so `allocation.quantity` must be included.
  - `PATCH /licensing/allocationsByEnvironment` (`UpdateAllocationsByEnvironment`) is **not** a
    partial update: a rule-only PATCH reset the allocation to **0** and removed the other rules.
    Don't use it for this.
  - `PATCH /licensing/environments/{id}/allocations` only accepts credit quantities, not rules.
- An environment with **no allocation record** (never configured) returns **404** on the
  single-environment read. The app treats it as the platform default: 0 credits, drawing from the
  pool. An environment with 0 credits **and** pool draw turned off has a record
  (`allocated: 0`, `enabled: false`) and is shown as not drawing.
- If an environment-group rule controls the setting, the update fails with
  `TenantPoolLockedByPolicy`.

Reference: Microsoft Learn, *Manage Copilot Credits allocations programmatically*.

## Requirements

**To run the app**

- A Power Platform administrator (or a role allowed to manage capacity allocations).
- The **Power Platform for Admins V2** connector must be allowed by the data policies **and**
  any environment-group **advanced connector policies** that apply to the environment hosting
  the app. Policy changes can take a while to apply at runtime.
- A **Copilot Managed Runtime spending policy**. Apps on Copilot Managed Runtime are billed in
  Copilot Credits. Each person who opens the app needs either a Power Apps Premium license or a
  spending policy that includes **Copilot Managed Runtime**. Set this up in the
  **Microsoft 365 admin center → Copilot → Cost management**:
  1. Turn on usage-based billing (pick a billing method, e.g. pay-as-you-go through an Azure
     subscription or prepaid capacity).
  2. Add a spending policy that includes **Copilot Managed Runtime** and covers the admins who
     will use this app (all users or a security group), with a monthly per-user limit.

  Creating spending policies needs the **Global Administrator** or **Billing Administrator**
  role. A spending policy is a limit, not a purchase: you pay only for what is used.

**To build it in your tenant (Copilot Code)**

- A Microsoft Copilot license for the person building it, plus Copilot Credits through a
  spending policy that includes **Copilot Code**.

> The spending policy pays for *running this app*. It's separate from the per-environment
> Copilot Credits allocations that the app turns on and off.

Reference: Microsoft Learn, *Manage licensing and Copilot Credits for apps on Copilot Managed
Runtime*.

## Project structure

- `src/lib/pool-api.ts`: all API calls, the read/write logic and the read-back check.
- `src/pages/home.tsx`: the user interface.
- `src/data/environments.ts`: rule settings and change log (browser storage).
- `generated/`: connector client generated from the connector definition. Do not edit by hand.
- `ms.config.json`: app and connection binding. The IDs are placeholders and must be
  replaced with the values from your own environment when the app is provisioned.

## Running it

This is a **Copilot Managed Runtime** app (built with App Builder in the Copilot Code tab). It
isn't a standalone website: the connector calls only work when the runtime hosts the app with
a connection to Power Platform for Admins V2 in your environment. `npm install && npm run build`
compiles it, but that alone won't make it work.

**To set it up, upload this zip to the Copilot app's Code tab and send the prompt below with
it.** Complete the [Requirements](#requirements) first.

```text
I've attached tenant-pool-draw-control.zip. Use it to build this app in my tenant as a new
App Builder (Copilot Managed Runtime) app.

1. Create a new app called "Tenant Pool Draw Control".
2. Copy everything under src/ from the zip into the new app. Do NOT copy generated/ or
   ms.config.json from the zip; those hold placeholders and must come from my environment.
   Don't change the protected scaffold files.
3. Bind the "Power Platform for Admins V2" connector (shared_powerplatformadminv2) with these
   actions: ListEnvironmentsForUser, ListAllocationsByEnvironment, GetAllocationsByEnvironment,
   PutAllocationsV2 and ListEnvironmentGroups. Then create a connection and let me sign in.
4. Use the live API only. No sample or mock data.
5. Check the reads work: list environments, list allocations and list environment groups.
   A 404 from GetAllocationsByEnvironment is normal for an environment with no allocation
   (treat it as 0 credits, drawing from the pool).
6. If any call fails with a 442 / data-policy or connector-policy error, stop and tell me.
   That means a DLP policy or environment-group advanced connector policy is blocking the
   connector, and I need to fix it in the Power Platform admin center.
7. Fix any type errors so it compiles, then publish the app and give me the link.
8. Don't make any changes to environments. I'll test turning pool draw off on one
   non-production environment myself first.
```

When it's published, test on one non-production environment and check the change log says
**Confirmed** before you use the bulk options.

## Testing status

Verified against a live tenant:

- Listing environments and groups, and reading allocations (including environments with no
  allocation record).
- Turning pool draw off on environments with no allocation, confirmed by read-back.
- Turning pool draw off on an environment with **5,000 credits and an Alert rule**: the credits
  and the Alert rule were kept, and only pool draw changed.

Not yet verified: environments that also have allocations of **other credit types** (not just
Copilot Credits). It isn't confirmed that the API keeps those allocations when only Copilot
Credits are sent, so the app **skips** any environment that has a non-empty allocation of
another credit type (nothing is sent, and it's reported as not confirmed). Change those in the
Power Platform admin center. Remove this guard only after testing on such an environment.
If a change does alter anything else in the allocation record, the app stops the bulk run
immediately instead of continuing with the remaining environments.

## Known limitations and ideas for a next version

- **Rule scope:** "Disable by rule" acts on the environments loaded on the current page only. Load
  every page before applying a rule, so it covers all environments of the chosen types.
- **Preview:** the preview shows the API request for the first environment as an example. Each
  environment's request is built from its own current allocation when it is applied.
- **Concurrent edits:** the app reads an allocation immediately before writing it back. A change
  made by someone else in that short window would be overwritten.
- **Bulk runs:** add handling for throttling (HTTP 429 and `Retry-After`) and a cancel button for
  runs over hundreds of environments.
- **Tests:** add mocked tests for `setTenantPool` (updated, locked, mismatch, side effect, skipped
  and no-record cases) and the CSV export.
- **Packaging:** provide a ready-made zip, or step-by-step instructions to create it, for the
  Copilot Code upload; trim template code the app doesn't use; keep one lock file (`package-lock.json`
  or `bun.lock`).

## Disclaimer

Provided as-is, without warranty. Test in a non-production environment first.
