# Changelog

All notable changes to the copilot-studio-workflow skill are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-04-10

### Added
- SKILL.md with full development workflow: pull → revert → edit → push → publish → test → commit
- Prerequisites and first-time setup guidance with dependency tables and checklist
- Platform gotchas covering initialization, packaging, development, and deployment
- Best practices for agent architecture, YAML hygiene, testing, solution packaging, memory/state, and security
- `scripts/cps-status.ps1` — project health check with dependency detection
- `scripts/cps-revert.ps1` — safe workflow file revert after cloud pull
- `scripts/cps-preflight.ps1` — pre-push hygiene checks
- `scripts/cps-add-component.ps1` — add bot component to Power Platform solution
- `reference/gotchas.md` — deep-dive platform gotchas
- `reference/workflow-guide.md` — detailed workflow documentation
- Plugin manifest (`plugin.json`) for GitHub Copilot CLI plugin install
- Compatibility notes for GitHub Copilot CLI, Claude Code, VS Code Copilot, and Copilot Cloud Agent
