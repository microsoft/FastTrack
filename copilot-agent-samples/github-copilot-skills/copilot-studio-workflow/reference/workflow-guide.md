# Copilot Studio Workflow Guide

## Why this workflow exists
Copilot Studio agent projects sit in an awkward but workable middle ground:
- The source of truth for agent logic is YAML in git.
- The runtime source of truth is the cloud environment.
- Solution packaging is what deployment teams actually import into production.

A reliable workflow has to keep those three views aligned.

## The URL translation problem
A recurring pain point is URL drift across environments.

### Repository state
The repo should store neutral placeholders such as `https://contoso.sharepoint.com/sites/...` so the project can be shared safely and reused.

### Demo environment state
The real development or demo environment contains actual URLs, real flow connection references, and environment-specific settings. Pulling from the cloud brings those values back into local files.

### Production environment state
Production imports produce yet another set of URLs, connections, and environment bindings.

### Practical rule
Never treat pulled workflow JSON as repo-safe by default. Revert `workflows/*.json` and `settings.mcs.yml` after pull unless your explicit goal is to inspect those live values.

## Default day-to-day workflow
1. Pull from cloud.
2. Revert workflow files and `settings.mcs.yml`.
3. Edit YAML locally.
4. Push to cloud.
5. Publish.
6. Test in Teams or Microsoft 365 Copilot.
7. Commit only the intentional source changes.

## Workflow variations

### 1. YAML-only change
Use this for topics, actions, triggers, variables, or agent instructions.
- If you are working in Copilot CLI, pair this workflow with the Microsoft Copilot Studio CAT Team's `copilot-studio` plugin (`skills-for-copilot-studio`) for YAML authoring and validation; this skill covers the surrounding engineering loop.
- Pull
- Revert workflow files
- Edit YAML
- Push
- Publish
- Test
- Commit

### 2. Flow change in Power Automate
Use this when a flow was edited directly in the environment.
- Pull to capture the new flow-backed artifacts
- Immediately review whether workflow JSON contains live URLs you do not want in git
- Revert unsafe files or scrub placeholders before commit
- Validate the agent still calls the flow correctly
- Publish if agent-side assets changed

### 3. Rebuild production zip
Use this when you need a fresh distributable solution.
- Confirm the demo environment is exactly the version you want to ship
- Export the solution with `pac solution export`
- Unpack it if your process scrubs or patches artifacts
- Remove environment-specific URLs and anything production-specific
- Repack to a clean zip
- Update the production setup guide if connection steps changed

### 4. Add component to solution
Use this after pushing a brand-new topic, action, or other bot component.
- Push YAML so the component exists in Dataverse
- Run `cps-add-component.ps1 -SolutionName ... -SchemaPattern ...`
- Confirm the component appears in the solution
- Re-export if you are preparing a production package

### 5. Remove component
Use this carefully because deletion order matters.
- Remove or detach references in YAML first
- Push and validate the agent
- Remove the component from the solution if needed
- Re-export the solution to confirm the package is clean

## Setting up a new agent from scratch
1. Create the Copilot Studio agent and establish the local YAML project structure.
2. Decide the solution name early and keep it stable.
3. Create placeholder-safe configuration values for anything environment-specific.
4. Establish the script habit from day one:
   - `cps-status.ps1` to understand the project
   - `cps-revert.ps1` after pulls
   - `cps-preflight.ps1` before pushes
5. Define every global variable in `variables/` as soon as it exists.
6. Document which flows must be re-enabled after import.
7. Test real-channel behavior before calling the workflow stable.

## Team collaboration tips

### Avoid overlapping pushes
The extension sync model is coarse. Multiple developers editing the same cloud agent without coordination almost guarantees `ConcurrencyVersionMismatch` or accidental overwrite.

### Use pull-first discipline
Before any push, pull first. Even if no conflict is obvious, this reduces surprise drift.

### Separate repo-safe and environment-safe changes
A change can be correct in the demo environment and still be wrong for git if it hard-codes a live URL.

### Keep packaging responsibilities explicit
Not every developer needs to export production zips, but someone must own solution membership, connection references, and post-import instructions.

### Publish is part of done
A pushed draft is not finished work. The workflow is only complete after publish plus real-channel validation.

## Suggested working agreements
- No push without a fresh pull.
- No commit with dirty `workflows/*.json` unless intentionally reviewed.
- No package export without confirming required components are in the solution.
- No release sign-off without Teams or Microsoft 365 Copilot validation.
