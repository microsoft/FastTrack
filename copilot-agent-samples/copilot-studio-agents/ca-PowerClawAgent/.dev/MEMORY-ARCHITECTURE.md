# PowerClaw_Memory Architecture (Final)

> **Status:** Design reference for PowerClaw v1.1.0. Captures the agreed memory model across the 4 existing stores + constitution files. v1.0.2 ships the minimum stability patch from §7; v1.1.0 delivers §4–§6.

> **Callout:** If you are willing to add **one column** to an existing list, add `ScopeKey` to `PowerClaw_Memory_Log`. It is **not required**, but it makes dedupe queries safer than parsing `Summary`. If you do **not** want that change, the `Summary` contract below is good enough.

## 1. One-paragraph memory model

PowerClaw uses **four persistent stores plus constitution files**, each with a distinct job: `memory-journal.md` is the **reflective working-synthesis** layer for curated narrative, `PowerClaw_Memory_Log` is the **episodic event stream plus dedupe memory** for "what happened / did I already do this?", `PowerClaw_Memory` is the **semantic store** for durable facts that should shape future behavior, and `PowerClaw_Tasks` is the **prospective store** for anything that still needs to happen. The design borrows from human memory only where it helps engineering: narrative reflection stays separate from canonical facts, raw events stay separate from knowledge, and open commitments become tasks instead of floating notes.

---

## 2. Content contracts

### `memory-journal.md`

| Rule | Contract |
|---|---|
| **Purpose** | Curated reflective memory: recent narrative, emerging patterns, weekly synthesis. |
| **Goes here** | Short summaries of notable work, repeated themes, behavior-relevant observations, weekly synthesis. |
| **NEVER goes here** | Raw heartbeat dumps, MCP action lists, full JSON, dedupe markers, reminders, open loops, one-off transient events with no meaning. |
| **Writers** | Heartbeat **only when it has a meaningful reflective delta**; Housekeeping consolidates and rotates. |
| **Lifecycle / rotation** | Rolling current journal; target current-file size **~200–250 KB**, redline **~300 KB**; weekly archive to `memory-journal-YYYY-Www.md`; current file retains `Today`, active `Emerging Patterns`, recent `Weekly Synthesis`. |

### `PowerClaw_Memory_Log`

| Rule | Contract |
|---|---|
| **Purpose** | Raw episodic log + dedupe source of truth for "already sent / already acted". |
| **Goes here** | Heartbeat starts/skips/errors, digest sent, recap sent, alert sent, meeting prep sent, task reminder sent, task pickup sent, memory promotion/archive events. |
| **NEVER goes here** | Durable personal/project facts, human task backlog, reflective narrative. |
| **Writers** | HeartbeatFlow, Housekeeping, task-processing steps, error handlers. |
| **Lifecycle / rotation** | Keep **30 days** live; delete older rows daily. Query **targeted slices only**; never dump the whole list into prompt. |

**Canonical `EventType` values for dedupe**
- `DailyDigestSent`
- `WeeklyRecapSent`
- `VIPAlertSent`
- `MeetingPrepSent`
- `TaskReminderSent`
- `TaskPickedUp`
- `HeartbeatError`
- `MemoryPromoted`
- `JournalRolled`

**`Summary` contract**
- Format: `scope=<scope> | target=<target> | note=<short note>`
- Examples:
  - `scope=digest:daily:2026-04-22 | target=user | note=Daily digest sent`
  - `scope=task:123 | target=user | note=Reminder sent after 3 days in Human Review`
  - `scope=vip:person:sarah:2026-W17 | target=user | note=VIP alert sent`

**Example dedupe query pattern**
- **Prefer CAML** when `Summary` scope matching is required:
```xml
<View>
  <Query>
    <Where>
      <And>
        <Eq>
          <FieldRef Name='EventType'/>
          <Value Type='Choice'>TaskReminderSent</Value>
        </Eq>
        <And>
          <Geq>
            <FieldRef Name='Created'/>
            <Value IncludeTimeValue='TRUE' Type='DateTime'>@{addDays(utcNow(),-3)}</Value>
          </Geq>
          <Contains>
            <FieldRef Name='Summary'/>
            <Value Type='Text'>scope=task:123</Value>
          </Contains>
        </And>
      </And>
    </Where>
    <OrderBy><FieldRef Name='Created' Ascending='FALSE'/></OrderBy>
  </Query>
  <RowLimit>1</RowLimit>
</View>
```
- **Use OData** when `EventType + time window` is enough.

### `PowerClaw_Memory`

| Rule | Contract |
|---|---|
| **Purpose** | Canonical semantic memory: durable facts that should influence behavior later. |
| **Goes here** | `Preference`, `Person`, `Project`, `Pattern`, `Insight` only. |
| **NEVER goes here** | Commitments, reminders, follow-ups, dedupe markers, raw telemetry, one-off observations, task status exhaust. |
| **Writers** | Interactive mode when user explicitly states a durable fact; HeartbeatFlow via gated `proposedMemories`; Housekeeping may archive/supersede. |
| **Lifecycle / rotation** | Status-driven: `Tentative → Active → Superseded/Archived`; stale tentative items archived quickly; active items reviewed periodically; no blind insert. |

### `PowerClaw_Tasks`

| Rule | Contract |
|---|---|
| **Purpose** | Prospective memory for anything that still needs to happen. |
| **Goes here** | Human work items, follow-ups, reminders, "check back Friday", "ask user for X", agent-created commitments. |
| **NEVER goes here** | Durable facts, dedupe tokens, reflective summaries, raw event history. |
| **Writers** | User, interactive agent, HeartbeatFlow/Housekeeping when converting commitments into explicit tasks. |
| **Lifecycle / rotation** | `To Do → Human Review → Done`; `Done` retained **30 days** then deleted; `To Do` / `Human Review` kept until resolved. |

**Agent-initiated commitments**
- Use existing `Source` column.
- Preferred v1.1.0 value: `agent-initiated`
- If you do not widen the choice field yet, use legacy `Heartbeat`.

### Constitution files (`soul.md`, `user.md`, `agents.md`, `tools.md`)

| Rule | Contract |
|---|---|
| **Purpose** | Procedural priors: identity, user context, operating rules, available tools. |
| **Goes here** | Stable rules, role context, communication preferences, operating policy, safety constraints. |
| **NEVER goes here** | Episodic events, semantic memory facts, active commitments, journal content. |
| **Writers** | Human editors; Bootstrap seeds defaults. |
| **Lifecycle / rotation** | Manual edits only; no automated append. Treat as instructions, not memory. |

---

## 3. Heartbeat prompt design

### Prompt sections and order

1. **Heartbeat header** — timestamp, mode, local time/day, run reason
2. **Procedural priors** — `soul.md`, `user.md`, `agents.md`, `tools.md`
3. **Current live context** — calendar/email/user context payload already assembled for heartbeat
4. **Open tasks** — compact task summaries only
5. **Semantic memory** — active/high-signal facts only
6. **Dedupe state** — compact booleans / recent hits from `PowerClaw_Memory_Log`
7. **Journal tail** — recent reflective narrative only
8. **Output contract** — exact JSON schema / rules

### Soft budgets

| Section | Soft budget |
|---|---|
| Heartbeat header + output contract | 2–5 KB |
| Constitution files | 15–35 KB |
| Live context payload | 20–80 KB |
| Open tasks | 5–20 KB |
| Semantic memory | 5–15 KB |
| Dedupe state | 1–5 KB |
| Journal tail | 80–200 KB |

### Journal injection

**Inject only the tail slice**, not the whole file.

**Recommended cap:** **200,000 characters** for v1.0.2 and v1.1.0.

**Expression**
```text
@if(
  greater(length(body('Get_file_content:_memory-journal.md')), 200000),
  substring(
    body('Get_file_content:_memory-journal.md'),
    sub(length(body('Get_file_content:_memory-journal.md')), 200000),
    200000
  ),
  body('Get_file_content:_memory-journal.md')
)
```

**Why this cap**
- Preserves far more context than the known-good **86 KB** journal case.
- Stays far below the **~1.5 MB** failure regime.
- Tail-biased retrieval is correct because the journal is redesigned as recent synthesis, not an append-only dump.

### Memory log slicing for dedupe

Do **not** inject "last 25 log entries" into the prompt as a generic block. Query `PowerClaw_Memory_Log` **per action family**:

- Daily digest → `EventType = DailyDigestSent`, window = today
- Weekly recap → `EventType = WeeklyRecapSent`, window = current week
- VIP alert → `EventType = VIPAlertSent`, window = 7 days, scope match in `Summary`
- Meeting prep → `EventType = MeetingPrepSent`, window = 6 hours, scope match
- Task reminder → `EventType = TaskReminderSent`, window = 3 days, scope match `task:<ID>`

Then inject only a compact section like:
- `dailyDigestSentToday = true`
- `weeklyRecapSentThisWeek = false`
- `task:123 reminderSentInLast3Days = true`

### Practical prompt max

**Target assembled heartbeat prompt:** **~250–350 KB**
**Red zone:** **>500 KB**
Conservative relative to the observed failure point while still keeping the agent context-rich.

---

## 4. Journal redesign (v1.1.0)

### File shape

```md
# PowerClaw_Memory Journal

## Today
### 2026-04-22
- ...
- ...

## Emerging Patterns
- ...
- ...

## Weekly Synthesis
### 2026-W17
- ...
- ...
```

### Writer rules

- **Heartbeat**
  - does **not** blindly append every run
  - may write **one short `Today` entry** only when something genuinely notable happened
  - max ~600–900 chars per entry
- **Housekeeping (daily)**
  - prunes stale `Today` noise
  - promotes repeated `Today` themes into `Emerging Patterns`
- **Housekeeping (weekly)**
  - writes one `Weekly Synthesis`
  - rotates/archive snapshot

### Should heartbeat auto-append?

**No, not unconditionally.** Heartbeat should only append when the agent returns an explicit reflective delta, e.g. `journalEntry`. Idle runs should write nothing.

### Bounded size / rotation

- Keep current journal at **~200–250 KB target**
- If it drifts past **~300 KB**, rotate immediately
- Weekly archive name: `memory-journal-YYYY-Www.md`
- On rotation:
  1. archive full current file
  2. rebuild current file with:
     - fresh `Today`
     - active `Emerging Patterns`
     - recent `Weekly Synthesis` only

### Good vs bad entry

**Good**
```md
### 2026-04-22
- Moved two staffing-analysis tasks to Human Review after producing draft briefs.
- Repeated pattern: the user responds fastest to concise bullet summaries before 9 AM.
- Budget-related follow-ups involving Sarah tend to stall unless explicitly surfaced within 48 hours.
```

**Bad (current pattern)**
```md
## 2026-04-22T08:30:00Z - Heartbeat Memory Update
Checked Calendar, Sent Teams Message, Updated Task 123
New Memories Saved: 2
---
```

---

## 5. Semantic memory gatekeeping (v1.1.0)

### Promotion test

A proposed fact may enter `PowerClaw_Memory` only if **all** are true:

1. **Type is semantic**: `Preference | Person | Project | Pattern | Insight`
2. **Scope is stable**: `user`, `person:sarah`, `project:alpha`, etc.
3. **Fact is durable**: likely useful beyond the current day/run
4. **Fact is singular**: one clear canonical statement
5. **Not a commitment**: if it implies future work, it belongs in `PowerClaw_Tasks`
6. **Evidence threshold met**:
   - user explicitly said it, **or**
   - observed twice on separate days, **or**
   - confirmed by two independent sources, **or**
   - pattern seen **3+ times over 7+ days**
7. **No unresolved contradiction**: if it conflicts with an existing active fact, supersede first

### Status model

- **Tentative** — plausible but not yet canonical
- **Active** — trusted and behavior-shaping
- **Superseded** — replaced by a newer fact
- **Archived** — stale or no longer useful

> `Expired` can remain as a **legacy status** for old data, but v1.1.0 semantic memory should use the four-state model above.

### Confidence seeds

| Case | Seed | Status |
|---|---:|---|
| User explicitly states fact | 90 | Active |
| Strong single observation | 60 | Tentative |
| Two observations / two sources | 75 | Tentative |
| Pattern inferred from repeated behavior | 65 | Tentative |

### Confidence updates

- Exact reconfirmation: **+10**, cap **95**
- Successful use in action: **+5**, increment `UsageCount`
- No confirmation for long interval: archive if weak/stale
- Contradiction:
  - old fact → `Superseded`
  - new fact → `Tentative 60` unless user-stated (`Active 90`)

### Practical Power Automate upsert pattern

**Replace blind POST** (current HeartbeatFlow lines **851–876**) with **find → compare → update/insert**:

1. **Skip non-semantic proposals** — if `memoryType = Commitment`, do **not** save to `PowerClaw_Memory`; route to `PowerClaw_Tasks`.

2. **Find existing active/tentative rows** — GET:
```text
_api/web/lists/getByTitle('PowerClaw_Memory')/items?$filter=
ScopeKey eq '<scopeKey>' and
MemoryType eq '<memoryType>' and
(Status eq 'Tentative' or Status eq 'Active')
&$orderby=Modified desc&$top=5
```

3. **Exact match path**
   - Use `Filter array` on returned rows where `CanonicalFact` exactly matches
   - If found:
     - MERGE existing item
     - set `LastConfirmedAt = utcNow()`
     - set `Confidence = min(95, max(existingConfidence, proposedConfidence) + 10)`
     - set `Status = if(confidence >= 80, 'Active', 'Tentative')`

4. **Contradiction path**
   - If same scope/type exists but fact differs:
     - MERGE prior active/tentative rows to `Status = Superseded`
     - POST new row with seeded confidence/status

5. **Insert path**
   - If nothing exists: POST new row

**Useful expression**
```text
@min(
  95,
  add(
    max(
      int(first(body('Get_items:_Existing_Memory')?['value'])?['Confidence']),
      int(items('Apply_to_each:_Save_Memories')?['confidence'])
    ),
    10
  )
)
```

---

## 6. Housekeeping redesign (v1.1.0)

Treat Housekeeping as an **existing flow to rewrite**, not a new flow.

### Daily responsibilities (bounded)

**Budget:** one daily run, aim **<10 minutes**, batch-oriented

1. **Memory log cleanup** — delete `PowerClaw_Memory_Log` rows older than **30 days**
2. **Done task cleanup** — delete `PowerClaw_Tasks` where `TaskStatus = Done` and `CompletedDate < now-30d` (current flow deletes all Done tasks; too aggressive)
3. **Semantic memory review**
   - archive `Tentative` facts not reconfirmed in **30 days**
   - archive weak `Active` facts not reconfirmed in **180 days**
   - leave high-confidence active facts alone
4. **Journal maintenance**
   - normalize `Today`
   - lift repeated items into `Emerging Patterns`
   - enforce file size target

### Weekly responsibilities

**Budget:** one weekly run, aim **<15 minutes**

1. Generate **Weekly Synthesis**
2. Rotate/archive journal
3. Archive old `Superseded` memory rows
4. Optional memory hygiene pass for duplicate semantic rows

### Reads / writes by store

| Store | Reads | Writes |
|---|---|---|
| `memory-journal.md` | current file | condensed current file, weekly archive file |
| `PowerClaw_Memory_Log` | recent event slices, old rows | delete old rows, log housekeeping errors/rolls |
| `PowerClaw_Memory` | active/tentative/superseded rows | archive/supersede weak or stale rows |
| `PowerClaw_Tasks` | done tasks, stale Human Review tasks if needed | delete aged done tasks, optional reminder tasks |
| Constitution files | none normally | none |

### Retention rules

- **Memory_Log**: 30 days
- **Tasks**
  - `Done`: 30 days then delete
  - `To Do` / `Human Review`: keep
- **Semantic memory**
  - `Tentative`: archive after 30 days without confirmation
  - `Superseded`: archive after 30 days
  - `Archived`: retain for 180 days or manual review
- **Journal**
  - current file target 200–250 KB
  - weekly archive files retained for ~26 weeks

### Failure modes to handle

- **One store missing** → log error, continue other scopes
- **`memory-journal.md` missing** → recreate skeleton file
- **SharePoint list not found / bad schema** → log `HeartbeatError`/`HousekeepingError`, notify admin
- **Partial delete/update failure** → continue batch, record count failed
- **Auth/connection failure** → stop current scope, log clearly
- **Large result sets** → batch/paginate rather than single-pass
- **Concurrent run** → disable concurrency or use simple running guard

> Current Housekeeping only deletes old logs, deletes all Done tasks, and expires active memories. That is too shallow for the new design.

---

## 7. v1.0.2 stability patch (ship this week)

**Change only one thing in `HeartbeatFlow/workflow.json`:** bound journal injection in the heartbeat message.

### Current issue
At **line 634**, HeartbeatFlow injects the **entire** journal:
```text
@{body('Get_file_content:_memory-journal.md')}
```

### Replace with
```text
@{if(
  greater(length(body('Get_file_content:_memory-journal.md')), 200000),
  substring(
    body('Get_file_content:_memory-journal.md'),
    sub(length(body('Get_file_content:_memory-journal.md')), 200000),
    200000
  ),
  body('Get_file_content:_memory-journal.md')
)}
```

### Scope of change
- File: `PowerClaw\workflows\HeartbeatFlow-04cf2235-af1c-f111-88b1-6045bd0079f1\workflow.json`
- Line to change: **~634**
- Leave `Get_file_content:_memory-journal.md` (**~1112–1133**) as-is for v1.0.2

### Tradeoff
- **Pros:** immediate payload-risk reduction; preserves rich recent context
- **Cons:** oldest journal content falls out of prompt; does **not** fix journal quality or growth discipline

---

## 8. v1.1.0 migration plan

### `HeartbeatFlow/workflow.json`
- Replace broad memory-log dump at **~1058–1080** with **targeted dedupe queries**
- Keep journal tail slicing; move to a named compose if you want cleaner wiring
- Replace blind semantic memory POST loop at **~851–876** with **find-then-update/insert**
- Remove unconditional journal prepend at **~888–945**
- Write journal only when agent returns explicit `journalEntry`
- Route commitment/follow-up proposals to **Tasks**, not semantic memory

### `Housekeeping/workflow.json`
- Rewrite current cleanup-only behavior into:
  - daily retention
  - semantic archival
  - journal maintenance
  - weekly synthesis + rotation
- Preserve flow identity; do not rebuild from scratch

### `agent.mcs.yml`
- Update memory instructions at **~143–154** and **~208–231**:
  - semantic memory excludes `Commitment`
  - commitments/reminders become tasks
- Update heartbeat JSON contract at **~115–133**:
  - add `journalEntry`
  - keep `proposedMemories` semantic-only
- Update dedupe guidance so it references `Memory_Log` event types, not semantic task memories

### Constitution files
- `agents.md`: update operating rules for
  - dedupe via `PowerClaw_Memory_Log`
  - commitments via `PowerClaw_Tasks`
  - journal = reflective only
- `soul.md`: likely no major change
- `tools.md`: optional note that task follow-ups live in Tasks
- `user.md`: no architecture change

### Data migration
- **One-time journal cleanup:** archive current noisy file as `memory-journal-legacy-YYYYMMDD.md`, create curated v1.1.0 journal
- **One-time semantic cleanup:** review/archive noisy transient rows in `PowerClaw_Memory`, especially old `Commitment` entries
- **No new list migration**
- **No need to rebuild Memory_Log**, but widen `EventType` choices if current field blocks new values

### Manual vs automation

**Manual**
- widen SharePoint `EventType` choice values if needed
- widen `Tasks.Source` choices if you want `agent-initiated`
- review one-time semantic cleanup
- approve legacy journal archive

**Automation**
- all steady-state dedupe logging
- semantic upsert
- journal maintenance/rotation
- weekly synthesis
- daily retention

---

## 9. Intelligence wins

- PowerClaw **won't resend the same daily digest, weekly recap, or VIP alert** inside the same intended window.
- PowerClaw **won't keep "remembering" commitments as facts**; follow-ups become visible tasks that can actually be completed.
- Semantic memory becomes **cleaner and more trustworthy**, so the agent adapts to real preferences and people instead of transient noise.
- The journal starts capturing **actual patterns and synthesis**, not operational exhaust.
- Heartbeat stays **context-rich without payload blowups**, because the journal contribution is bounded but still generous.
- Housekeeping becomes a real memory-maintenance layer, so the system **ages gracefully instead of accumulating sludge**.
