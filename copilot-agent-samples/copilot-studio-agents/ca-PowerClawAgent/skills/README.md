<p align="center">
  <img src="../Images/powerclaw-rounded.png" alt="PowerClaw" width="120" />
</p>

# PowerClaw Skills Library

PowerClaw is already a strong 24/7 AI Chief of Staff out of the box. This library extends it with optional, focused capabilities that leverage PowerClaw's unique strengths — autonomous heartbeat, persistent memory, SharePoint task board, and cross-M365 synthesis — in ways that go beyond what vanilla M365 Copilot can do.

> 💡 Skills are add-on experiences activated through Copilot Studio UI configuration, not by editing PowerClaw's core runtime or heartbeat logic.

---

## What is a Skill?

A **skill** is a self-contained capability that teaches PowerClaw how to do a specific job especially well using:

- **Prompt tools** in Copilot Studio
- **Code Interpreter** for file analysis, charts, slides, and generated outputs
- **Existing MCPs and connectors** already available to PowerClaw

Skills are **not** the same thing as:

- **Core agent behavior** in the shipped PowerClaw configuration
- **Built-in topics** that support normal assistant conversation
- **Heartbeat automations** that run every 30 minutes
- **SharePoint brain configuration** such as `user.md`, `agents.md`, `soul.md`, or list-based settings

Think of PowerClaw as the operating system, and skills as optional apps you layer on top.

---

## How Skills Work

Most skills follow the same simple pattern:

1. A user asks for a job to be done in natural language
2. An admin adds the needed **prompt tool(s)** in Copilot Studio
3. Optional capabilities are enabled if needed:
   - **Code Interpreter**
   - **File upload**
   - Relevant **MCPs/connectors**
4. The user invokes the skill conversationally in Teams or Microsoft 365 Copilot

No PowerClaw YAML surgery required. The goal is to keep the foundation stable while making capability expansion easy.

---

## Skills Catalog

| Skill | Complexity | Best For | Requires | Summary |
|---|---|---|---|---|
| [Weekly Status Report](weekly-status-report.md) | Medium | Managers, ICs, execs | WorkIQ MCPs | Compile weekly wins, progress, blockers, and priorities |
| [Meeting Copilot Loop](meeting-copilot-loop.md) | Medium | Execs, managers, PMs, account teams | WorkIQ MCPs | Prep before, recap after, track commitments between — full meeting lifecycle |
| [Decision Memo Builder](decision-memo-builder.md) | Hard | Strategy, PMs, execs | WorkIQ MCPs | Transform rough notes into structured decision memos |
| [Commitment Tracker](commitment-tracker.md) | Medium | Managers, execs, PMs | WorkIQ MCPs, SharePoint Lists MCP | Extract commitments, track them, and chase follow-through autonomously |
| [Executive Radar](executive-radar.md) | Medium | Execs, managers, chiefs of staff | WorkIQ MCPs, SharePoint Lists MCP | "What needs my attention?" — prioritized triage across mail, calendar, tasks, and memory |
| [Stakeholder Brief](stakeholder-brief.md) | Medium | Execs, PMs, account teams | WorkIQ MCPs | Living dossier on a person, account, or project with recommended next moves |

---

## Before You Start

Before adding any skill, make sure:

- [ ] PowerClaw is deployed and responding in chat
- [ ] The heartbeat and baseline setup are working
- [ ] Required connectors and MCPs are authenticated and verified
- [ ] You have reviewed the main setup guide: [SETUP.md](../SETUP.md)

If PowerClaw itself is not healthy yet, fix that first. Skills work best on a solid foundation.

---

## Recommended Starting Order

If you're building out the library over time, this is the smoothest path:

1. **Weekly Status Report** — highest frequency, clearest value, strong demo
2. **Meeting Copilot Loop** — full meeting lifecycle: prep + recap + commitment tracking
3. **Commitment Tracker** — autonomous follow-through on promises and deadlines
4. **Executive Radar** — synthesized "what needs my attention" triage
5. **Stakeholder Brief** — living dossiers that compound over time
6. **Decision Memo Builder** — highest complexity, strongest executive output

This sequence starts with the most immediately useful skills and progresses toward richer capabilities that benefit from accumulated memory and context.

---

## How to Contribute a Skill

Want to add a new skill? Great — please keep the library consistent.

1. Copy [`_skill-template.md`](./_skill-template.md)
2. Name your new file clearly, like `customer-brief.md` or `pipeline-summary.md`
3. Follow the standard headings in the template
4. Include tested prompts and at least one realistic example interaction
5. Open a PR with your new skill doc

### Authoring Checklist

- [ ] Clear job-to-be-done and target audience
- [ ] Prerequisites listed accurately
- [ ] Setup steps are repeatable in Copilot Studio
- [ ] Prompt tool text is copy-paste ready
- [ ] Example interaction feels realistic
- [ ] Limitations and governance notes are honest
- [ ] Related skills are linked where useful

---

## Notes on Cost & Governance

- **Code Interpreter** may consume additional Copilot Studio credits depending on usage and output generation
- **WorkIQ-based skills** may access tenant data such as meetings, mail, documents, and people context
- **File-upload skills** may process user-provided content that should follow your organization's data handling policies

For production use, it's smart to involve your security, compliance, and platform admins early — especially for skills that touch executive communications, sensitive documents, or broad tenant context.

---

Happy building. Start simple, prove value quickly, and grow PowerClaw one skill at a time. ⚡
