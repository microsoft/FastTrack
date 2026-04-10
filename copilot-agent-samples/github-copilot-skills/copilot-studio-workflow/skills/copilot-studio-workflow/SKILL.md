---
name: copilot-studio-workflow
description: >
  Development workflow for building, syncing, packaging, and shipping Copilot Studio agents.
  Use this skill when working with Copilot Studio YAML files (agent.mcs.yml, topics, actions, variables),
  when pulling or pushing agent changes, when packaging solutions for distribution,
  or when troubleshooting common Copilot Studio platform issues.
  Triggers on: Copilot Studio, MCS, agent.mcs.yml, .mcs.yml files, pac CLI, Power Platform solution,
  pull from cloud, push to cloud, publish agent, solution packaging, heartbeat flow, Power Automate flows.
allowed-tools: shell
license: MIT
---

# Copilot Studio Workflow

## Overview
- Copilot Studio agents are YAML-first assets (`.mcs.yml`) that sync between a local repo and the cloud.
- Treat the **development/demo** environment as the real working environment and the **production** environment as a packaged distribution target.
- Keep generic placeholder URLs in git (for example `contoso.sharepoint.com`); real demo URLs belong only in the live environment.
- Follow the proven loop: **pull → revert env-specific files → edit → push → publish → test → commit**.

## Prerequisites & First-Time Setup

When starting work on a Copilot Studio project for the first time, verify the following tools are installed and configured. Run `.\scripts\cps-status.ps1` for a quick health check.

### Required
| Tool | Purpose | Install |
|---|---|---|
| **Git** | Source control for agent YAML files | [git-scm.com](https://git-scm.com) |
| **VS Code** | Editor for YAML and local development | [code.visualstudio.com](https://code.visualstudio.com) |
| **Copilot Studio VS Code Extension** | Pull/push agent YAML between local files and cloud environments | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.microsoft-copilot-studio) |
| **Power Platform environment** | A Copilot Studio-enabled environment to develop in | [Power Platform admin center](https://admin.powerplatform.microsoft.com) |

### Recommended
| Tool | Purpose | Install |
|---|---|---|
| **Power Platform CLI (`pac`)** | Solution export/import, component management | [Microsoft docs](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction) |
| **Copilot Studio Skills Plugin** | Additional CPS authoring tools in Copilot CLI | `/plugin add` → search for Copilot Studio |
| **PowerShell 7+** | Cross-platform script execution | [github.com/PowerShell](https://github.com/PowerShell/PowerShell) |

### First session checklist
1. Run `.\scripts\cps-status.ps1` to detect the project and check tool availability.
2. If no `agent.mcs.yml` exists, clone an agent from the cloud using the VS Code extension or Copilot Studio manage flow.
3. If `pac` CLI is needed for solution packaging, authenticate: `pac auth create --environment <URL>`.
4. Verify the VS Code Copilot Studio extension can connect to your environment (open the agent folder, **Sync → Pull**).

## Development Loop
1. **Pull from cloud** using the VS Code Copilot Studio extension (**Sync → Pull**) or the Copilot Studio manage flow.
2. **Revert workflow files immediately.** Cloud pulls often inject environment-specific URLs into `workflows/*.json` and `settings.mcs.yml`. Run `.\scripts\cps-revert.ps1` (or `git checkout -- **/workflows/ **/settings.mcs.yml`) before reviewing diffs.
3. **Edit locally** in `.mcs.yml` files: topics, actions, variables, instructions, triggers, and agent settings.
4. **Push to cloud** with the VS Code extension (**Sync → Push**) or manage-agent tooling.
5. **Publish** in Copilot Studio so the draft becomes live.
6. **Test in the real channel** (Teams or Microsoft 365 Copilot). The test pane is useful for quick checks, but it is not representative of production behavior.
7. **Commit to git** only after the live agent behaves correctly and workflow files are clean.

## Solution Packaging
- Use `pac solution export` to export the solution from the demo environment.
- The solution should include the agent, Power Automate flows, and connection references.
- For production distribution: **export → unpack → scrub environment URLs → repack as a clean zip**.
- Teams import the solution zip, reconnect dependencies, re-enable flows, and follow the setup guide.

## Adding New Components
- A VS Code push creates Dataverse components, but it does **not** add new bot components to the Power Platform solution.
- Add them explicitly with `pac solution add-solution-component -sn <SOLUTION> -c <GUID> -ct botcomponent`.
- Find the component GUID with `pac org fetch` against `botcomponent` records.
- Use `.\scripts\cps-add-component.ps1` for guided lookup and add-to-solution flow.

## Platform Gotchas

### Initialization
- `OnConversationStart` does **not** fire in Microsoft 365 Copilot and usually fires only once in Teams. Use `OnActivity(type: Message)` plus an `IsBlank()` just-in-time guard instead.
- Copilot Studio does not stream partial messages; the platform batches output.

### Packaging
- VS Code push ≠ solution membership. New components must be added to the solution separately.
- Global variables need YAML definitions in `variables/` or solution imports can fail or create broken references.
- Solution import deactivates Power Automate flows; always re-enable them after import.
- Cloud pull brings environment-specific URLs into workflow files; always revert them before commit.
- Extension push/pull is all-or-nothing; there is no selective sync.

### Development
- `ConcurrencyVersionMismatch` on push usually means someone changed the cloud copy. Pull again before pushing.
- The Copilot Studio test pane does not match real channel behavior; validate in Teams or Microsoft 365 Copilot.
- Housekeeping flow push error `0x80040216` is a known benign issue.

### Deployment
- Export scripts capture the state that exists at export time. Do not run packaging scripts after a YAML push unless you intend to rebuild from that exact state.
- `pac` component type codes are brittle across environments; prefer the name-based `-ct botcomponent` pattern in your workflow.

## Best Practices

### Agent Architecture
- Use a **constitution file pattern** (markdown files in SharePoint or OneDrive) for dynamic instructions — edit behavior without YAML surgery.
- Keep agent instructions concise in `agent.mcs.yml`; load detailed context via global variables populated at runtime by a Power Automate flow.
- Use `OnActivity(type: Message)` with an `IsBlank()` JIT guard for reliable context initialization across all channels (Teams, M365 Copilot).

### YAML Hygiene
- One topic per file. Name files to match the topic's purpose (for example `Greeting.mcs.yml`, `EscalateToHuman.mcs.yml`).
- Define all global variables explicitly in `variables/` with YAML files — never rely on UI-only definitions.
- Use descriptive `schemaName` values — they appear in Dataverse queries and logs.

### Testing
- Always test in the real channel (Teams or M365 Copilot), not just the test pane.
- MCP tools, connectors, and OAuth flows only work in published agents on real channels.
- Use calendar-driven routines (for example `[AgentName Routine] Weekly Review`) for testing autonomous behaviors.

### Solution Packaging
- Establish a URL placeholder convention from day one (for example `contoso.sharepoint.com`). Retrofitting is painful.
- Always revert workflow files after cloud pulls — one missed revert leaks production URLs into source control.
- After pushing new components via VS Code, explicitly add them to the solution with `pac solution add-solution-component`.
- Re-enable all Power Automate flows after every solution import — imports deactivate them silently.

### Memory & State (for agents with persistent memory)
- Use SharePoint lists for structured memory (facts, preferences, tasks) and markdown files for narrative or journal memory.
- Design memory with expiration — stale facts degrade agent quality over time.
- Keep memory scoped (for example `preference:timezone`, `person:manager`) for efficient retrieval.

### Security & Governance
- Review all MCP tools and connectors before enabling — each one expands the agent's access surface.
- Use the `KillSwitch` pattern (a config flag that halts autonomous behavior) for any agent that acts without user prompting.
- Audit agent activity through logging lists or flows — autonomous agents need observability.

## Included Scripts
- `scripts/cps-status.ps1` — quick project health check: agent info, counts, git state, dirty workflow files, and `pac` availability.
- `scripts/cps-revert.ps1` — run after every cloud pull to revert `workflows/*.json` and `settings.mcs.yml` back to the repo-safe version.
- `scripts/cps-preflight.ps1` — run before push to check workflow hygiene, git state, and missing global variable definitions.
- `scripts/cps-add-component.ps1` — locate a bot component by schema pattern and add it to the Power Platform solution.

## Quick Reference
| Task | Command / Path |
| --- | --- |
| First-time setup | `.\scripts\cps-status.ps1` |
| Install pac CLI | `winget install Microsoft.PowerPlatformCLI` (Windows) or `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| Authenticate pac | `pac auth create --environment <URL>` |
| Clone agent from cloud | VS Code extension → open folder → Sync → Pull |
| Pull from cloud | VS Code Copilot Studio extension → **Sync → Pull** |
| Push to cloud | VS Code Copilot Studio extension → **Sync → Push** |
| Revert workflows | `.\scripts\cps-revert.ps1` or `git checkout -- **/workflows/ **/settings.mcs.yml` |
| Publish | Copilot Studio → **Publish** |
| Pre-push check | `.\scripts\cps-preflight.ps1` |
| Add component | `.\scripts\cps-add-component.ps1 -SolutionName "MySolution" -SchemaPattern "my.topic.Name"` |
| Project status | `.\scripts\cps-status.ps1` |
| Emergency stop | Set `KillSwitch = true` in the config list |

## References
- Deep dive: `reference/gotchas.md`
- Workflow details: `reference/workflow-guide.md`



