# Tenant Pool Draw Control

Turn off **"Draw from the available capacity in my tenant"** for Copilot Credits across many
Power Platform environments at once, from one screen.

When pool draw is off, an environment can only consume the Copilot Credits explicitly
allocated to it. With an allocation of 0, agents in that environment cannot consume
Copilot Credits at all until credits are allocated or pool draw is turned back on.

## What it does

- Lists every environment you can administer, with its environment group, type, and current
  Copilot Credits allocation and pool-draw setting.
- **Pick environments yourself:** flip the switch on one environment, or tick several and use
  the selection bar (Disable / Enable for selected). Every change is
  previewed first (including the exact API request) and read back afterwards to confirm it stuck.
- **Disable by rule:** choose environment types, then click **Disable now** to turn pool draw
  off for every environment of those types that still has it on. This ignores your ticked
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

Request body used to turn pool draw off (the current allocation quantity is kept):

```json
{
  "scope": { "environmentId": "<environment-id>" },
  "allocatedEntitlements": [
    {
      "entitlementId": "MCSMessages",
      "allocation": { "quantity": 0 },
      "enforcementRules": [{ "ruleType": "TenantPool", "enabled": false }]
    }
  ]
}
```

Notes:

- An environment that has never had an allocation returns **404** on the single-environment
  read. The app treats that as "0 credits, drawing from the pool" (the platform default).
- If an environment-group rule controls the setting, the update fails with
  `TenantPoolLockedByPolicy`.

Reference: Microsoft Learn, *Manage Copilot Credits allocations programmatically*.

## Requirements

- A Power Platform administrator (or a role allowed to manage capacity allocations).
- The **Power Platform for Admins V2** connector must be allowed by the data policies **and**
  any environment-group **advanced connector policies** that apply to the environment hosting
  the app. Policy changes can take a while to apply at runtime.

## Project structure

- `src/lib/pool-api.ts`: all API calls, the read/write logic and the read-back check.
- `src/pages/home.tsx`: the user interface.
- `src/data/environments.ts`: rule settings and change log (browser storage).
- `generated/`: connector client generated from the connector definition. Do not edit by hand.
- `ms.config.json`: app and connection binding. The IDs are placeholders and must be
  replaced with the values from your own environment when the app is provisioned.

## Running it

This app was built as a **Microsoft 365 Copilot App Builder** (managed) app. It uses the
`@microsoft/managed-apps` runtime to call the connector, so connector calls only work when it
is hosted by that runtime with a connection to Power Platform for Admins V2 in your
environment. It is not a standalone website. Running `npm install && npm run build` compiles
it, but the connector calls need the managed host.

To deploy it in your tenant type the following prompt into cowork. Note you must have copilot managed runtime enabled in usage based billing.

I've attached tenant-pool-draw-control.zip. It's the source code of an App Builder app called
"Tenant Pool Draw Control". It lists the Power Platform environments I administer and turns off
"Draw from the available capacity in my tenant" (Copilot Credits / MCSMessages, TenantPool
enforcement rule) for one or many environments at once. Read the README in the zip first.
Recreate this app in my environment as a new App Builder app:
Create a new app named "Tenant Pool Draw Control" and copy over the app code from the zip:
src/ (especially src/lib/pool-api.ts, src/lib/connector-safety.ts, src/pages/home.tsx,
src/data/environments.ts, src/components/app-shell.tsx, src/index.css).
Do NOT copy generated/ or ms.config.json from the zip. Those must be created for my
environment.
Bind the "Power Platform for Admins V2" connector (shared_powerplatformadminv2) with its
actions, so the connector client is generated for my environment. Then create a connection
and give me the sign-in link.
Use the live API only. No sample or mock data.
Once I've signed in, verify with live reads that environments, environment groups and Copilot
Credits allocations load. An environment that has never had an allocation returns 404 on the
single-environment read, and the app should treat that as "0 credits, drawing from the pool".
When the test passes, publish the app.
If a call fails with a data loss prevention / connector policy error (HTTP 442), stop and tell me
which policy to change. Don't work around it.

## Testing status

Verified against a live tenant: listing environments and groups, reading allocations
(including environments with no allocation), and turning pool draw off on two environments
with the change confirmed by read-back.

Not yet verified: environments that also have allocations of other credit types. Test on one
such environment before bulk use, to confirm those allocations are kept.

## Disclaimer

Provided as-is, without warranty. Test in a non-production environment first.
