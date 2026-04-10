# copilot-studio-workflow

A development workflow skill for building, syncing, packaging, and shipping Copilot Studio agents.

## What this skill does
- Teaches the proven **pull → revert → edit → push → publish → test → commit** loop
- Captures platform gotchas around sync, solution packaging, variables, and flows
- Ships helper PowerShell scripts for project status, workflow reverts, preflight checks, and solution component adds
- Includes best practices for agent architecture, YAML hygiene, testing, memory, and security
- Provides deeper reference docs for day-to-day development and production packaging

## Install

### From GitHub (recommended)

Install directly from the FastTrack repository:

```sh
copilot plugin install microsoft/FastTrack:copilot-agent-samples/github-copilot-skills/copilot-studio-workflow
```

Update to the latest version:

```sh
copilot plugin update copilot-studio-workflow
```

### From the CLI (interactive)

```text
/plugin add
```

Then search for `copilot-studio-workflow`.

### Manual — personal skill (all repos)

Copy the inner skill folder to your personal skills directory.

**Windows:**

```powershell
$src = "path\\to\\copilot-studio-workflow\\skills\\copilot-studio-workflow"
Copy-Item -Recurse $src "$env:USERPROFILE\\.copilot\\skills\\copilot-studio-workflow"
```

**macOS / Linux:**

```bash
cp -r path/to/copilot-studio-workflow/skills/copilot-studio-workflow ~/.copilot/skills/
```

### Manual — project skill (single repo)

Copy the inner skill folder into your repository.

**Windows:**

```powershell
Copy-Item -Recurse .\skills\copilot-studio-workflow .\.github\skills\copilot-studio-workflow
```

**macOS / Linux:**

```bash
cp -r skills/copilot-studio-workflow .github/skills/copilot-studio-workflow
```

### Claude Code

Copy the inner skill folder to your Claude skills directory:

```bash
cp -r skills/copilot-studio-workflow ~/.claude/skills/copilot-studio-workflow
```

## Prerequisites
- Git
- PowerShell (7+ recommended, 5.1 works on Windows)
- `pac` CLI is optional but recommended for solution packaging

## Compatibility

| Tool | Install method |
|---|---|
| **GitHub Copilot CLI** | `copilot plugin install` or personal skill at `~/.copilot/skills/` |
| **Claude Code** | Personal skill at `~/.claude/skills/` |
| **VS Code Copilot** | Project skill at `.github/skills/` |
| **Copilot Cloud Agent** | Project skill at `.github/skills/` |

The `SKILL.md` format is an [open standard](https://github.com/agentskills/agentskills) supported across multiple AI coding tools.

## What's included

| File | Purpose |
|---|---|
| `plugin.json` | Plugin manifest for `copilot plugin install` |
| `CHANGELOG.md` | Version history |
| `skills/copilot-studio-workflow/SKILL.md` | Core skill instructions |
| `skills/copilot-studio-workflow/scripts/cps-status.ps1` | Project health check |
| `skills/copilot-studio-workflow/scripts/cps-revert.ps1` | Workflow file revert |
| `skills/copilot-studio-workflow/scripts/cps-preflight.ps1` | Pre-push hygiene checks |
| `skills/copilot-studio-workflow/scripts/cps-add-component.ps1` | Add component to solution |
| `skills/copilot-studio-workflow/reference/gotchas.md` | Platform gotchas deep-dive |
| `skills/copilot-studio-workflow/reference/workflow-guide.md` | Workflow documentation |

## How to use

After installing, the skill activates automatically when your prompts mention Copilot Studio, `.mcs.yml`, solution packaging, `pac` CLI, or related topics.

Examples:
- "Help me push these Copilot Studio YAML changes safely."
- "How do I package this Copilot Studio agent for production?"
- "Why did my pull dirty workflow JSON files?"
- "Run a preflight check before I push."

Force activation: include `/copilot-studio-workflow` in your prompt.

## Versioning

This plugin uses [Semantic Versioning](https://semver.org/). Check `CHANGELOG.md` for the full version history.

To update:

```sh
copilot plugin update copilot-studio-workflow
```

## Contributing
- Keep `SKILL.md` concise — it is loaded directly into context
- Put detailed explanations in `reference/`
- Keep scripts safe to run repeatedly
- Bump the version in both `plugin.json` and `CHANGELOG.md` on every release
- Test scripts: `powershell -NoProfile -File skills\\copilot-studio-workflow\\scripts\\<name>.ps1 -?`

## License
MIT
