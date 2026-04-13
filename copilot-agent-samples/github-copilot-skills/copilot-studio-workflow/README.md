# copilot-studio-workflow
**Build Copilot Studio agents like software: local YAML, source control, repeatable packaging, and an AI assistant that already knows the platform's sharp edges.**

![Version](https://img.shields.io/badge/version-1.0.0-2563eb?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Copilot%20CLI%20%7C%20VS%20Code%20%7C%20Claude%20Code%20%7C%20Cloud%20Agent-111827?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-16a34a?style=for-the-badge)
[![Install](https://img.shields.io/badge/install-copilot%20plugin%20install-7c3aed?style=for-the-badge&logo=github)](#quick-install)

```sh
copilot plugin install microsoft/FastTrack:copilot-agent-samples/github-copilot-skills/copilot-studio-workflow
```

> 📖 **[View the interactive showcase →](https://microsoft.github.io/FastTrack/copilot-agent-samples/github-copilot-skills/copilot-studio-workflow/docs/showcase.html)** — see the full workflow, example conversations, and platform gotchas in a visual guide.

## Why This Exists
Copilot Studio is powerful, but the default workflow is still portal-heavy: click through the UI, hope you remember what changed, and figure out packaging only when it is time to ship. That is workable for demos. It is not a good engineering workflow.

This skill gives builders a better model. Your agent definition lives as YAML in git. You pull from the cloud, revert environment-specific artifacts, edit locally, push intentionally, publish, test in the real channel, and package for deployment with a repeatable process. Instead of learning the platform by trial and error, you can ask for the next step in plain English and get workflow-aware guidance.

It also bakes in the painful lessons most teams discover the hard way: why pull dirties workflow files, why push does not update solution membership, why variable hygiene matters for imports, and how to move from dev environment to clean solution zip without surprises. The result is a Copilot Studio workflow that feels like engineering, not archaeology.

## What You Can Do
### 1) First-time setup
```text
You: I need to start building a Copilot Studio agent. What's the workflow?

Copilot: I'll walk you through the local dev loop, run cps-status.ps1, and
make sure VS Code plus the Copilot Studio extension are ready before you pull
or push anything.
```

### 2) Pull changes safely
```text
You: I just pulled my agent from the cloud and git shows a bunch of changed
workflow files. What happened?

Copilot: That's the environment URL translation problem. A pull can bring
live URLs and settings into repo files. Run cps-revert.ps1 now, then review a
clean diff that only shows intentional source changes.
```

### 3) Add a new topic to the solution
```text
You: I pushed a new topic via VS Code but it's not showing up in my solution
export. What's wrong?

Copilot: Push created the Dataverse component, but it did not add that
component to the Power Platform solution. Run cps-add-component.ps1 with the
solution name and schema pattern, then re-export.
```

### 4) Validate before push
```text
You: I'm about to push my changes. Anything I should check first?

Copilot: Run cps-preflight.ps1. It will catch dirty workflow files, missing
variable definitions, and basic repo hygiene issues before the push becomes a
cloud problem.
```

## Quick Install
### GitHub Copilot CLI
Run this in your terminal:
```sh
copilot plugin install microsoft/FastTrack:copilot-agent-samples/github-copilot-skills/copilot-studio-workflow
```
Update later with `copilot plugin update copilot-studio-workflow`.

After install, just ask naturally:
- `Help me safely push my Copilot Studio YAML changes.`
- `Why did my pull dirty workflow JSON files?`
- `How do I package this agent for production?`
- `Run a preflight check before I push.`

> Tip: If needed, force activation by including `/copilot-studio-workflow` in your prompt.

## Other Install Methods
<details>
<summary><strong>Manual install — personal skill (all repos)</strong></summary>

Copy the folder to your personal skills directory.

**Windows**
```powershell
Copy-Item -Recurse path\to\copilot-studio-workflow "$env:USERPROFILE\.copilot\skills\copilot-studio-workflow"
```

**macOS / Linux**
```bash
cp -r path/to/copilot-studio-workflow ~/.copilot/skills/copilot-studio-workflow
```
</details>

<details>
<summary><strong>Manual install — project skill (single repo)</strong></summary>

**Windows**
```powershell
Copy-Item -Recurse path\to\copilot-studio-workflow .\.github\skills\copilot-studio-workflow
```

**macOS / Linux**
```bash
cp -r path/to/copilot-studio-workflow .github/skills/copilot-studio-workflow
```
</details>

<details>
<summary><strong>Claude Code</strong></summary>

```bash
cp -r path/to/copilot-studio-workflow ~/.claude/skills/copilot-studio-workflow
```
</details>

## What's Inside
| File | Why it matters |
|---|---|
| `SKILL.md` | Core workflow logic, triggers, and operational guidance |
| `scripts/cps-status.ps1` | Checks project health, tool availability, and repo state |
| `scripts/cps-revert.ps1` | Cleans up pull-induced workflow and settings churn |
| `scripts/cps-preflight.ps1` | Runs pre-push hygiene checks before you sync |
| `scripts/cps-add-component.ps1` | Adds pushed components to the Power Platform solution |
| `reference/gotchas.md` | Documents platform traps and workarounds |
| `reference/workflow-guide.md` | Expands the day-to-day development and packaging loop |
| `docs/showcase.html` | Interactive visual guide to the skill and workflow |
| `plugin.json` | Plugin manifest for `copilot plugin install` |
| `CHANGELOG.md` | Release history |

## Compatibility
![Copilot CLI](https://img.shields.io/badge/GitHub_Copilot_CLI-supported-000000?style=flat-square&logo=github)
![VS Code](https://img.shields.io/badge/VS_Code_Copilot-supported-007acc?style=flat-square&logo=visualstudiocode)
![Claude Code](https://img.shields.io/badge/Claude_Code-supported-d97706?style=flat-square)
![Cloud Agent](https://img.shields.io/badge/Copilot_Cloud_Agent-supported-2563eb?style=flat-square)

| Tool | Status | Install path |
|---|---|---|
| GitHub Copilot CLI | Recommended | Plugin install or `~/.copilot/skills/` |
| VS Code Copilot | Supported | `.github/skills/` |
| Claude Code | Supported | `~/.claude/skills/` |
| Copilot Cloud Agent | Supported | `.github/skills/` |

The `SKILL.md` format follows the [Agent Skills](https://github.com/agentskills/agentskills) open standard, so the same workflow knowledge travels across tools.

## Prerequisites
Keep this short list in place and the workflow becomes smooth:
- **Git** for version control
- **VS Code** plus the **Copilot Studio VS Code extension** for pull/push
- **PowerShell** (7+ recommended; Windows PowerShell 5.1 works on Windows)
- **Power Platform CLI (`pac`)** recommended for solution packaging and exports
- Access to a **Copilot Studio-enabled Power Platform environment**

For YAML authoring, schema validation, topic creation, and agent testing in Copilot CLI, also install the **Copilot Studio Plugin** by the Microsoft Copilot Studio CAT Team (`copilot-studio` from `skills-for-copilot-studio`). It complements this skill's engineering workflow guidance; see `SKILL.md` for details.

Run `skills\copilot-studio-workflow\scripts\cps-status.ps1` to validate the local setup.

## Versioning
This plugin uses [Semantic Versioning](https://semver.org/). Current version: **1.0.0**.
- Release notes: `CHANGELOG.md`
- Update: `copilot plugin update copilot-studio-workflow`

## Contributing
Keep the skill lean and operational:
- Put core instructions in `SKILL.md`
- Put deeper explanations in `reference/`
- Keep scripts safe to run repeatedly
- Bump `plugin.json` and `CHANGELOG.md` together on release

Quick script check:
```powershell
powershell -NoProfile -File skills\copilot-studio-workflow\scripts\<name>.ps1 -?
```

## License
MIT
