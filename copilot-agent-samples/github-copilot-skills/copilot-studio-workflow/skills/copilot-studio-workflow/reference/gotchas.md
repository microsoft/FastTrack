# Copilot Studio Platform Gotchas

This reference captures recurring issues that show up when teams build Copilot Studio agents from YAML, sync with the VS Code extension, and package solutions for customers.

## Initialization

### `OnConversationStart` is not a reliable initialization hook
**Symptom:** Initialization logic works in the Copilot Studio test pane or in Teams once, but not in Microsoft 365 Copilot or later turns.

**Why it happens:** `OnConversationStart` is channel-sensitive. In Microsoft 365 Copilot it often does not fire at all, and in Teams it usually fires only once for a conversation.

**Proven workaround:** Move initialization into an `OnActivity` trigger for `Message` activity and guard it with `IsBlank()` checks. That gives you just-in-time initialization that runs only when data is missing.

**Typical pattern:**
- Trigger on `Message`
- Check if a critical global variable is blank
- If blank, populate profile, glossary, or configuration variables
- Continue to the user-facing topic

### There is no true message streaming
**Symptom:** Multiple `SendMessage` nodes look like they should stream progress updates, but the user receives a single batched response.

**Why it happens:** Copilot Studio buffers output before returning it to the channel.

**Workaround:** Design messages as complete, self-contained responses. If you need visible phases, use explicit “working / done” mechanics through external channels rather than assuming in-chat streaming.

## Packaging

### VS Code push creates Dataverse artifacts but not solution membership
**Symptom:** A new topic or component works in the demo environment, but it is missing from exported solutions.

**Why it happens:** Syncing YAML to the cloud creates the Dataverse component, but it does not automatically add that component to the Power Platform solution.

**Workaround:** Add every new bot component explicitly with `pac solution add-solution-component ... -ct botcomponent`. The `cps-add-component.ps1` helper exists for exactly this step.

### Global variables must have YAML definitions
**Symptom:** The agent imports poorly, variables are missing, or topics fail at runtime after solution import.

**Why it happens:** A variable referenced in `agent.mcs.yml` is not enough. The corresponding variable definition in `variables/*.mcs.yml` must exist so the solution contains the full definition.

**Workaround:** Treat `variables/` as required source of truth. Run `cps-preflight.ps1` before push and before packaging.

### Cloud pulls leak environment-specific URLs into source control
**Symptom:** After a pull, unrelated diffs appear under `workflows/*.json` or `settings.mcs.yml`.

**Why it happens:** The extension downloads live environment values, including real SharePoint URLs, flow endpoints, and environment-specific settings.

**Workaround:** Revert those files immediately after every pull unless you intentionally changed them. The repository should keep generic placeholder values.

### Solution import deactivates Power Automate flows
**Symptom:** A customer imports the solution successfully, but flows never fire.

**Why it happens:** Imported flows are usually disabled by default.

**Workaround:** The post-import checklist must include reconnecting connections and re-enabling all flows.

### Push/pull is all-or-nothing
**Symptom:** You want to sync only one topic or one action, but the extension wants to move the whole agent.

**Why it happens:** The current sync model is agent-wide.

**Workaround:** Coordinate changes, pull before push, and avoid parallel edits in the same environment.

## Development

### `ConcurrencyVersionMismatch` means your local copy is stale
**Symptom:** Push fails even though the YAML looks valid.

**Why it happens:** Someone or something updated the cloud copy after your last pull.

**Workaround:** Pull again, revert environment-specific workflow files, re-apply your local changes if needed, then push.

### The test pane is not the real product
**Symptom:** Behavior in the test pane differs from Teams or Microsoft 365 Copilot.

**Why it happens:** Authentication, channel lifecycle, activity model, and trigger behavior differ between the test pane and production channels.

**Workaround:** Use the test pane for quick iteration only. Final validation must happen in Teams or Microsoft 365 Copilot.

### Housekeeping flow error `0x80040216` is usually benign
**Symptom:** Push reports a housekeeping flow error even though the agent works.

**Why it happens:** The platform sometimes throws a noisy error during housekeeping flow sync.

**Workaround:** Confirm whether the functional assets actually synced. If the agent behaves correctly, treat the error as informational unless you see a real missing component.

## Deployment

### Export scripts capture the state that exists at export time
**Symptom:** The packaged zip does not match the YAML you expected.

**Why it happens:** Exporting after an unintended push captures whatever is in the demo environment at that moment.

**Workaround:** Be deliberate about sequence. For packaging, know whether you are exporting the last published demo state or a freshly pushed state.

### Prefer `-ct botcomponent` over brittle numeric component type codes
**Symptom:** Script works in one environment but fails or becomes unclear in another.

**Why it happens:** Numeric component-type workflows are harder to maintain and easier to misread.

**Workaround:** Use the name-based pattern in your scripted workflow and keep the GUID lookup separate from the add-to-solution step.

## Operational Tips
- Pull before every push.
- Revert workflow JSON and `settings.mcs.yml` after every pull.
- Publish after every meaningful cloud change.
- Test in the real channel, not only the test pane.
- Before packaging, verify that every required component is both in Dataverse and in the solution.
