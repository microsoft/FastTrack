# Microsoft FastTrack Open Source - Migrate-CopilotStudioAgents

A small toolkit for inventorying and migrating classic Copilot Studio agents across Power Platform environments, using the agent owner/creator's Microsoft Entra ID `department` attribute to decide where each agent should land.

This is useful for tenants that started out with all their Copilot Studio agents in a single (often the default) environment, and now want to redistribute them into department-specific environments for better governance, licensing isolation, or environment strategy - without losing agent ownership or record-level sharing in the process.

The toolkit is made up of four scripts, meant to be run in order:

1. **`Generate-DepartmentMappings.ps1`** (optional, one-time/occasional) - discovers every department in your tenant (from Entra ID user profiles) and every non-default Power Platform environment, then generates `department-environment-mapping.json`, randomly assigning each department to a target environment plus a short naming-convention code. You can also hand-author this file yourself instead (see `department-environment-mapping.example.json`) - the only fields `Migrate-CopilotStudioAgents.ps1` actually reads are `department` and `environmentName`.
2. **`Inventory-PowerPlatformAgents.ps1`** - inventories every Copilot Studio / Microsoft 365 Copilot Agent Builder agent in the tenant via the Power Platform inventory API (the same data source behind the "Agents" list in the Power Platform admin center), resolves each agent's creator/owner to a display name/email/department via Microsoft Graph, flags first-party Microsoft-managed agents (e.g. "Finance in Microsoft 365 Copilot") that can't be migrated, and exports CSV/JSON reports.
3. **`Migrate-CopilotStudioAgents.ps1`** - consumes the raw JSON from step 2 plus the department mapping from step 1, builds a per-agent migration plan (skipping agents with no resolvable department, no mapping, a same-as-source target, or first-party/Microsoft-managed status), then for each planned agent creates a dedicated unmanaged Dataverse solution, exports it, and imports it into the target environment - restoring the agent's owner and record-level sharing afterward (Dataverse solution import does not preserve either). Supports `-WhatIf` for a full dry run.
4. **`Confirm-ScriptRequirements.ps1`** - a shared helper (dot-sourced by the three scripts above, not run directly) that checks for the `pac` CLI and the `MSAL.PS` PowerShell module before any real work starts, and offers to install whichever is missing for you.

The original agent in the source environment is left untouched by step 3 - migration is a copy, not a destructive move.

## Usage

### Prerequisites

- **Power Platform CLI (`pac`)** and the **MSAL.PS** PowerShell module. You don't need to install these yourself - every script checks for both on startup and will offer to install whichever is missing (with your confirmation) before doing any real work.
- One of these Microsoft Entra roles, to read the Power Platform inventory: Global Administrator, Power Platform Administrator, Dynamics 365 Administrator, Global Reader, or AI Administrator/AI Reader. If you can see the "Agents" list in the Power Platform admin center yourself, you already have enough access.
- Delegated Microsoft Graph access (`User.Read.All`) to resolve agent creator/owner department, display name, and email.
- Access to Dataverse in both the source and target environments (for the migration step), including permission to create/export/import unmanaged solutions.

All three main scripts sign in interactively via MSAL's device code flow by default (open a URL, enter a code) - pass `-UseInteractiveBrowser` to any of them to use an embedded browser prompt instead.

### 1. (Optional) Generate a department -> environment mapping

```powershell
.\Generate-DepartmentMappings.ps1
```

Produces `department-environment-mapping.json`. See `department-environment-mapping.example.json` for the expected shape if you'd rather hand-author it:

```json
[
  { "department": "Executive", "environmentName": "Contoso-Executive", "code": "EXE" },
  { "department": "Human Resources", "environmentName": "Contoso-HR", "code": "HR" },
  { "department": "Finance", "environmentName": "Contoso-Finance", "code": "FIN" }
]
```

Only `department` and `environmentName` are used by the migration script; `code` is a naming-convention field for your own use.

### 2. Inventory your tenant's Copilot Studio agents

```powershell
.\Inventory-PowerPlatformAgents.ps1
```

By default this reports on the current (default) environment only and excludes Microsoft 365 Copilot Agent Builder agents. Useful switches:

- `-IncludeAgentBuilder` - also include Microsoft 365 Copilot Agent Builder agents in the output.
- `-AllEnvironments` - report on every environment tenant-wide instead of just the current one (mutually exclusive with the current-environment-only output - you get one or the other, not both).
- `-OutputDir <path>` - where to write results (defaults to a timestamped `.\PPAgentInventory-<timestamp>` folder).

This writes both a human-readable CSV and a raw JSON file (e.g. `agents-inventory-<environment>.json`) - the migration script consumes the JSON, not the CSV, since the CSV's datetime fields are locale-formatted for readability while the JSON preserves precise values.

### 3. Migrate agents to their department's target environment

```powershell
.\Migrate-CopilotStudioAgents.ps1 -InventoryJsonPath .\PPAgentInventory-<timestamp>\agents-inventory-<environment>.json -MappingPath .\department-environment-mapping.json -WhatIf
```

Review the printed plan (and `migration-plan.csv`) first - `-WhatIf` shows exactly what would be created/exported/imported without making any real change. Drop `-WhatIf` to actually migrate; each migration still prompts for confirmation unless you also pass `-Confirm:$false`.

Other useful switches:

- `-BulkByDepartment` - bundle every agent mapped to the same department into a single solution/export/import instead of one dedicated solution per agent (fewer imports overall, but a shared import failure affects every agent in that department together).
- `-OutputDir <path>` - where to write the plan/results reports and exported solution zips.

Results (including per-agent success/failure, owner reassignment status, and share-replication details) are written to `migration-results.csv`. Connection references and environment variables in the newly-imported solution still need manual reconfiguration in the target environment - this is called out at the end of the script's output and is not handled automatically.

## Limitations

`Migrate-CopilotStudioAgents.ps1` only considers classic Copilot Studio agents belonging to the SOURCE environment you're currently authenticated to - agents from a different environment, or non-"Copilot Studio" (Agent Builder) entries in the inventory JSON, are filtered out before a plan is even built.

### Agents that won't be migrated

An agent is skipped - with a reason recorded in `migration-plan.csv`/`migration-results.csv` - rather than migrated if:

- Its owner and creator have no `department` value in Microsoft Entra ID (nothing to map from).
- Its resolved department has no entry in the department -> environment mapping file.
- Its mapped target environment is the same as the source environment (nothing to do).
- It's a first-party, Microsoft-managed agent (e.g. "Finance in Microsoft 365 Copilot") - these ship inside a Microsoft-managed solution with no customizable content to copy.
- It belongs to a different source environment than the one currently authenticated, or it's an Agent Builder agent rather than a classic Copilot Studio agent.

### Manual follow-up required after migration

- **Connection references and environment variables** in the imported solution still point at the source environment's connections and are NOT repointed automatically - reconfigure these by hand in the target environment (Power Apps/Power Automate connections, custom connectors, etc.) before treating the migrated agent as production-ready.
- **Owner reassignment and share replication are best-effort**: they only succeed if a matching user (by email) or team (by exact name) already exists in the target environment. If no match is found, the imported agent keeps whichever account ran the import as its owner and that specific share is skipped - both outcomes are logged per-agent in `migration-results.csv` rather than failing the migration.
- **Re-running for the same agent (or, under `-BulkByDepartment`, the same set of agents in a department) will fail** at the solution-create step, since the generated solution name is deterministic - this surfaces as a clear error instead of silently duplicating the agent, but it also means a partially-failed migration can't simply be re-run as-is; investigate the failure first.
- **Validate the migrated agent end-to-end** before deleting or deactivating the original - published channels, topics that call out to connectors, and any other environment-specific configuration should be tested in the target environment.
- With `-BulkByDepartment`, a single failed import affects every agent in that department together (no per-agent isolation) - the default of one solution per agent isolates failures instead.

## Applies To

- Microsoft Copilot Studio
- Power Platform environments / Dataverse
- Microsoft 365 Copilot Agent Builder
- Microsoft Entra ID (for department lookups)

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|July 15th, 2026|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
