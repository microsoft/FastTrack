from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path
from textwrap import dedent


SITE_URL_EXPR = "@triggerBody()['text']"
ADMIN_EMAIL_EXPR = "@triggerBody()['text_1']"
AGENT_NAME_EXPR = "@triggerBody()['text_2']"
AGENT_NAME_INLINE_EXPR = "@{triggerBody()['text_2']}"
CONTINUE_AFTER_FAILURE = ["Succeeded", "Failed"]


SOUL_MD = dedent(
    """\
    # @{triggerBody()['text_2']} Soul
    You are @{triggerBody()['text_2']}, your user's AI copilot — an intelligent enterprise assistant running on Microsoft 365 and powered by the PowerClaw framework.
    Your primary goal is to assist the user by autonomously managing tasks, summarizing information, and providing actionable insights.

    ## Identity
    - Your name is **@{triggerBody()['text_2']}**. You respond to this name in conversations.
    - When appropriate, sign off messages with your name to establish your identity (e.g., "— @{triggerBody()['text_2']}").
    - You are powered by the PowerClaw autonomous agent framework, but your persona is @{triggerBody()['text_2']}.
    - Email subjects still use "PowerClaw:" prefix (product branding, not your name).
    - Calendar routines still use [PowerClaw routine] tags (operational convention).

    ## Core Values
    1. **Proactive**: Don't wait to be asked. If you see meeting conflicts or an urgent email, flag it.
    2. **Secure**: Never expose sensitive data outside the tenant. Respect privacy.
    3. **Concise**: The user is busy. Be brief. Use bullet points.
    4. **Transparent**: Always log your actions to the PowerClaw_Memory_Log.
    """
)

USER_MD = dedent(
    """\
    # User Profile
    **Name**: [User Name]
    **Role**: [Job Title]
    **Department**: [Department]
    **Organization**: [Organization Name]

    ## Preferences
    - **Communication Style**: Direct and professional.
    - **Meeting Hours**: 9:00 AM - 5:00 PM [Timezone]
    - **Focus Time**: No interruptions between 2:00 PM - 4:00 PM.

    ## Team
    - **Direct Reports**: [Name 1], [Name 2]
    - **Manager**: [Manager Name]
    """
)

AGENTS_MD = dedent(
    """\
    # Operating Rules

    ## Heartbeat Behavior
    On each heartbeat, evaluate what actions to take based on the current time and context.

    ### Calendar Monitoring
    - Check for meetings in the next 2 hours
    - Flag any double-bookings or conflicts
    - If a meeting starts within 15 minutes, prepare a brief: attendees, agenda, relevant recent emails/docs

    ### Email Triage
    - Check for unread emails from VIPs (Manager, Direct Reports listed in user.md)
    - Flag emails with "urgent", "ASAP", or "action required" in subject
    - Summarize key emails that need attention

    ### Task Management (PowerClaw Tasks List)
    - Tasks are managed via the "PowerClaw Tasks" SharePoint list on this workspace site
    - 3 statuses: To Do → Human Review → Done
    - On heartbeat: check for "To Do" tasks, pick up new ones, send analysis via email
    - Move completed work to "Human Review" for user approval
    - User marks tasks "Done" when satisfied
    - Create tasks from calendar events, emails, or user requests
    - Always check memory before acting on a task to avoid duplicates

    ### Daily Digest (Morning Brief)
    - Send between 07:00-09:00 UTC (adjustable via DigestTimeUTC setting)
    - Only send ONCE per day — check PowerClaw_Memory_Log for an existing DailyDigest entry today
    - Include: today's calendar, overdue tasks, tasks due today, urgent emails, any conflicts
    - Send via Teams message

    ### Weekly Recap (Friday)
    - Send on Fridays between 15:00-17:00 UTC (adjustable via WeeklyRecapDay setting)
    - Summarize: meetings attended, tasks completed, key decisions, upcoming Monday priorities
    - Only send ONCE per week

    ### Quiet Hours
    - Between QuietHoursStart and QuietHoursEnd (default 22:00-07:00 UTC), do NOT send proactive notifications
    - Still perform checks and log to memory, just don't message the user
    - Exception: if something is flagged truly urgent, notify anyway

    ### Notification Rules
    - ALWAYS send proactive messages to the user's 1:1 direct chat ONLY — NEVER to group chats or channels
    - If you cannot identify the correct 1:1 chat, fall back to email instead
    - Only post to group chats or channels if the user explicitly asks you to in an interactive conversation
    - Be concise — use bullet points
    - Always log what you did to the PowerClaw_Memory_Log with appropriate EventType
    """
)

TOOLS_MD = dedent(
    """\
    # Available Tools

    ## WorkIQ MCP Capabilities
    You have access to Microsoft 365 through WorkIQ MCP servers:

    ### Calendar (WorkIQ Calendar MCP)
    - Read calendar events, check free/busy, find conflicts
    - Look ahead for upcoming meetings

    ### Mail (WorkIQ Mail MCP)
    - Read emails, search inbox, check unread
    - Send emails when instructed

    ### Teams (WorkIQ Teams MCP + Teams Connector)
    - Send messages to chats and channels
    - Read recent messages for context

    ### Task Management (SharePoint Lists MCP)
    - Read and manage tasks in the "PowerClaw Tasks" SharePoint list
    - Create new tasks with Title, TaskStatus, Priority, Source, DueDate, TaskDescription
    - Update task status: To Do → Human Review → Done
    - Add notes and deliverables to tasks via the Notes column
    - No Plan ID discovery needed — tasks are in a simple SharePoint list on this workspace site

    ### User Profile (WorkIQ User MCP)
    - Look up user details, org chart, reporting structure

    ### Documents (WorkIQ Word MCP + SharePoint Lists MCP)
    - Read and search documents in SharePoint/OneDrive
    - Access SharePoint list data

    ### Copilot Search (WorkIQ Copilot MCP)
    - Search across M365 for relevant content
    - Find documents, emails, and conversations by topic

    ## Usage Guidelines
    - Prefer WorkIQ MCP tools for read operations
    - Use connector actions (Teams Post, Outlook Send) for write operations
    - Always check PowerClaw_Memory_Log before sending digests to avoid duplicates
    - Log all actions to the PowerClaw_Memory_Log for audit trail
    """
)

MEMORY_JOURNAL_MD = dedent(
    """\
    # PowerClaw Memory Journal

    ## Today
    _No entries yet. PowerClaw will append observations, patterns, and insights here._

    ## Emerging Patterns
    _Recurring behaviors and trends will be noted here as they develop._

    ## Open Loops
    _Follow-ups, pending items, and commitments tracked here._

    ## Weekly Synthesis
    _End-of-week summaries consolidating the week's learnings._
    """
)


LIST_DEFINITIONS = [
    {
        "title": "PowerClaw_Memory_Log",
        "columns": [
            {
                "title": "EventType",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": [
                    "Heartbeat",
                    "HeartbeatSkipped",
                    "MemoryUpdate",
                    "Error",
                    "AgentResponse",
                ],
            },
            {"title": "Summary", "type_name": "SP.Field", "field_type_kind": 3},
            {"title": "Timestamp", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "FullContextJSON", "type_name": "SP.Field", "field_type_kind": 3},
        ],
    },
    {
        "title": "PowerClaw_Config",
        "columns": [
            {"title": "SettingName", "type_name": "SP.Field", "field_type_kind": 2},
            {"title": "SettingValue", "type_name": "SP.Field", "field_type_kind": 2},
        ],
    },
    {
        "title": "PowerClaw Memory",
        "columns": [
            {
                "title": "MemoryType",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": [
                    "Preference",
                    "Person",
                    "Project",
                    "Pattern",
                    "Commitment",
                    "Insight",
                ],
            },
            {"title": "ScopeKey", "type_name": "SP.Field", "field_type_kind": 2},
            {"title": "CanonicalFact", "type_name": "SP.Field", "field_type_kind": 3},
            {"title": "Confidence", "type_name": "SP.Field", "field_type_kind": 9},
            {
                "title": "Status",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": [
                    "Active",
                    "Tentative",
                    "Superseded",
                    "Expired",
                    "Archived",
                ],
            },
            {
                "title": "Importance",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": ["Low", "Med", "High", "Critical"],
            },
            {"title": "FirstLearnedAt", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "LastConfirmedAt", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "ReviewAfter", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "ExpiresAt", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "EvidenceSummary", "type_name": "SP.Field", "field_type_kind": 3},
            {"title": "UsageCount", "type_name": "SP.Field", "field_type_kind": 9},
        ],
    },
    {
        "title": "PowerClaw Tasks",
        "columns": [
            {
                "title": "TaskStatus",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": ["To Do", "Human Review", "Done"],
            },
            {"title": "TaskDescription", "type_name": "SP.Field", "field_type_kind": 3},
            {
                "title": "Priority",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": ["Low", "Medium", "High", "Critical"],
            },
            {
                "title": "Source",
                "type_name": "SP.FieldChoice",
                "field_type_kind": 6,
                "choices": ["Calendar", "Manual", "Heartbeat"],
            },
            {"title": "DueDate", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "Notes", "type_name": "SP.Field", "field_type_kind": 3},
            {"title": "LastActionDate", "type_name": "SP.Field", "field_type_kind": 4},
            {"title": "CompletedDate", "type_name": "SP.Field", "field_type_kind": 4},
        ],
    },
]


SETTINGS_TO_SEED = [
    ("KillSwitch", "false"),
    ("IsRunning", "false"),
    ("MaxActionsPerHour", "10"),
    ("DigestEnabled", "true"),
    ("DigestTimeUTC", "08:00"),
    ("WeeklyRecapDay", "Friday"),
    ("QuietHoursStart", "22"),
    ("QuietHoursEnd", "07"),
    ("TeamsMessageMode", "direct_chat_only"),
    ("MemoryConsolidationEnabled", "true"),
    ("MemoryMaxActiveItems", "100"),
    ("LastHousekeepingDate", "2000-01-01"),
    ("HeartbeatIntervalMinutes", "30"),
    ("AgentName", AGENT_NAME_INLINE_EXPR),
]


CONSTITUTION_FILES = [
    ("soul.md", SOUL_MD),
    ("user.md", USER_MD),
    ("agents.md", AGENTS_MD),
    ("tools.md", TOOLS_MD),
    ("memory-journal.md", MEMORY_JOURNAL_MD),
]


def compact_json(value: dict) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def sharepoint_http_request_action(*, uri: str, method: str, body: dict | str) -> dict:
    request_body = body if isinstance(body, str) else compact_json(body)
    return {
        "type": "OpenApiConnection",
        "inputs": {
            "parameters": {
                "dataset": SITE_URL_EXPR,
                "parameters/uri": uri,
                "parameters/method": method,
                "parameters/headers": compact_json({
                    "Accept": "application/json;odata=verbose",
                    "Content-Type": "application/json;odata=verbose",
                }),
                "parameters/body": request_body,
            },
            "host": {
                "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                "operationId": "HttpRequest",
                "connectionName": "shared_sharepointonline",
            },
        },
    }


def sharepoint_post_item_action(*, table: str, title: str, field_values: dict[str, str]) -> dict:
    """Use HTTP request to create list items (avoids schema validation issues with dynamic lists)."""
    item_data = {"__metadata": {"type": "SP.Data.{table_type}ListItem"}, "Title": title}
    item_data.update(field_values)
    # Build the body as a JSON string with the actual field values
    body_parts = ['"__metadata":{"type":"SP.Data.OData__x0078_002e_ListItem"}']
    body_parts = []
    fields = {"Title": title}
    fields.update(field_values)
    body_str = compact_json(fields)
    uri = f"_api/web/lists/getByTitle('{table}')/items"
    return {
        "type": "OpenApiConnection",
        "inputs": {
            "parameters": {
                "dataset": SITE_URL_EXPR,
                "parameters/uri": uri,
                "parameters/method": "POST",
                "parameters/headers": compact_json({
                    "Accept": "application/json;odata=verbose",
                    "Content-Type": "application/json;odata=verbose",
                }),
                "parameters/body": body_str,
            },
            "host": {
                "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                "operationId": "HttpRequest",
                "connectionName": "shared_sharepointonline",
            },
        },
    }


def sharepoint_create_file_action(*, file_name: str, body: str) -> dict:
    return {
        "type": "OpenApiConnection",
        "inputs": {
            "parameters": {
                "dataset": SITE_URL_EXPR,
                "folderPath": "/Shared Documents",
                "name": file_name,
                "body": body,
            },
            "host": {
                "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                "operationId": "CreateFile",
                "connectionName": "shared_sharepointonline",
            },
        },
    }


def chain_actions(actions: list[tuple[str, dict]]) -> dict[str, dict]:
    chained_actions: dict[str, dict] = {}
    previous_name: str | None = None
    for name, action in actions:
        action = dict(action)
        action["runAfter"] = {} if previous_name is None else {previous_name: CONTINUE_AFTER_FAILURE}
        chained_actions[name] = action
        previous_name = name
    return chained_actions


def build_column_body(column: dict) -> dict:
    payload = {
        "__metadata": {"type": column["type_name"]},
        "Title": column["title"],
        "FieldTypeKind": column["field_type_kind"],
        "Required": False,
    }
    if "choices" in column:
        payload["Choices"] = {"results": column["choices"]}
    return payload


def sanitize_name(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_")
    return cleaned or "Action"


def make_scope(actions: list[tuple[str, dict]], *, run_after: dict | None = None) -> dict:
    scope = {
        "type": "Scope",
        "actions": chain_actions(actions),
    }
    if run_after is not None:
        scope["runAfter"] = run_after
    return scope


def build_bootstrap_definition() -> dict:
    create_list_actions: list[tuple[str, dict]] = []
    add_column_actions: list[tuple[str, dict]] = []

    for list_definition in LIST_DEFINITIONS:
        list_title = list_definition["title"]
        list_key = sanitize_name(list_title)
        create_list_actions.append(
            (
                f"Create_List_{list_key}",
                sharepoint_http_request_action(
                    uri="_api/web/lists",
                    method="POST",
                    body={
                        "__metadata": {"type": "SP.List"},
                        "BaseTemplate": 100,
                        "Title": list_title,
                    },
                ),
            )
        )
        for column in list_definition["columns"]:
            column_key = sanitize_name(column["title"])
            add_column_actions.append(
                (
                    f"Add_Column_{list_key}_{column_key}",
                    sharepoint_http_request_action(
                        uri=f"_api/web/lists/getByTitle('{list_title}')/fields",
                        method="POST",
                        body=build_column_body(column),
                    ),
                )
            )

    add_column_actions.append(
        (
            "Make_Tasks_Title_Not_Required",
            sharepoint_http_request_action(
                uri="_api/web/lists/getByTitle('PowerClaw Tasks')/fields/getByTitle('Title')",
                method="PATCH",
                body={"Required": False},
            ),
        )
    )

    seed_setting_actions = [
        (
            f"Seed_Setting_{sanitize_name(setting_name)}",
            sharepoint_post_item_action(
                table="PowerClaw_Config",
                title=setting_name,
                field_values={
                    "SettingName": setting_name,
                    "SettingValue": setting_value,
                },
            ),
        )
        for setting_name, setting_value in SETTINGS_TO_SEED
    ]

    upload_file_actions = [
        (
            f"Upload_{sanitize_name(file_name)}",
            sharepoint_create_file_action(file_name=file_name, body=file_body),
        )
        for file_name, file_body in CONSTITUTION_FILES
    ]

    return {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "$authentication": {
                "defaultValue": {},
                "type": "SecureObject",
            },
            "$connections": {
                "defaultValue": {},
                "type": "Object",
            },
        },
        "triggers": {
            "manual": {
                "type": "Request",
                "kind": "Button",
                "inputs": {
                    "schema": {
                        "type": "object",
                        "properties": {
                            "text": {
                                "title": "SiteUrl",
                                "type": "string",
                                "x-ms-visibility": "important",
                            },
                            "text_1": {
                                "title": "AdminEmail",
                                "type": "string",
                                "x-ms-visibility": "important",
                            },
                            "text_2": {
                                "title": "AgentName",
                                "type": "string",
                                "default": "PowerClaw",
                                "x-ms-visibility": "important",
                            },
                        },
                        "required": ["text", "text_1"],
                    }
                },
            }
        },
        "actions": {
            "Scope_Create_Lists": make_scope(create_list_actions),
            "Scope_Add_Columns": make_scope(
                add_column_actions,
                run_after={"Scope_Create_Lists": CONTINUE_AFTER_FAILURE},
            ),
            "Scope_Seed_Settings": make_scope(
                seed_setting_actions,
                run_after={"Scope_Add_Columns": CONTINUE_AFTER_FAILURE},
            ),
            "Scope_Upload_Constitution_Files": make_scope(
                upload_file_actions,
                run_after={"Scope_Seed_Settings": CONTINUE_AFTER_FAILURE},
            ),
            "Compose_Summary": {
                "type": "Compose",
                "inputs": {
                    "siteUrl": SITE_URL_EXPR,
                    "adminEmail": ADMIN_EMAIL_EXPR,
                    "agentName": AGENT_NAME_EXPR,
                    "lists": [item["title"] for item in LIST_DEFINITIONS],
                    "settingsSeeded": [name for name, _ in SETTINGS_TO_SEED],
                    "filesUploaded": [name for name, _ in CONSTITUTION_FILES],
                },
                "runAfter": {
                    "Scope_Upload_Constitution_Files": CONTINUE_AFTER_FAILURE,
                },
            },
        },
        "outputs": {},
    }


BOOTSTRAP_DEFINITION = build_bootstrap_definition()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def load_json(path: Path) -> dict:
    return json.loads(read_text(path))


def write_json(path: Path, payload: dict) -> None:
    path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8-sig",
    )


def parse_flow_name(metadata_path: Path) -> str:
    for line in read_text(metadata_path).splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()
    return ""


def find_sharepoint_connection_reference(solution_root: Path) -> str | None:
    connection_file = solution_root / "connectionreferences.mcs.yml"
    if not connection_file.exists():
        return None

    current_logical_name: str | None = None
    for raw_line in read_text(connection_file).splitlines():
        line = raw_line.strip()
        if "connectionReferenceLogicalName:" in line:
            current_logical_name = line.split(":", 1)[1].strip()
            continue
        if (
            current_logical_name
            and line.startswith("connectorId:")
            and line.endswith("/shared_sharepointonline")
        ):
            return current_logical_name
    return None


def ensure_sharepoint_connection_reference(workflow_payload: dict, solution_root: Path) -> None:
    properties = workflow_payload.setdefault("properties", {})
    connection_references = properties.setdefault("connectionReferences", {})
    existing_reference = connection_references.get("shared_sharepointonline", {})
    logical_name = (
        existing_reference.get("connection", {}).get("connectionReferenceLogicalName")
        or find_sharepoint_connection_reference(solution_root)
        or "shared_sharepointonline"
    )

    connection_references["shared_sharepointonline"] = {
        "api": {"name": "shared_sharepointonline"},
        "connection": {
            "connectionReferenceLogicalName": logical_name,
        },
        "runtimeSource": existing_reference.get("runtimeSource", "invoker"),
    }


def contains_workflows(root: Path) -> bool:
    return any(root.rglob("workflow.json"))


def extract_zip_if_needed(zip_path: Path, extract_dir: Path) -> Path:
    extract_dir.mkdir(parents=True, exist_ok=True)
    if not contains_workflows(extract_dir):
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(extract_dir)
    return extract_dir


def candidate_roots(solution_path: Path, extract_dir: Path | None) -> list[Path]:
    roots: list[Path] = []
    if solution_path.is_dir():
        roots.append(solution_path)
    else:
        default_extract_dir = extract_dir or solution_path.with_suffix("")
        if not default_extract_dir.name.endswith("_unpacked"):
            default_extract_dir = default_extract_dir.with_name(f"{default_extract_dir.name}_unpacked")
        roots.append(extract_zip_if_needed(solution_path, default_extract_dir))
        roots.append(solution_path.parent)

    deduped: list[Path] = []
    seen: set[str] = set()
    for root in roots:
        resolved = str(root.resolve())
        if resolved not in seen and root.exists():
            deduped.append(root)
            seen.add(resolved)
    return deduped


def derive_solution_root(workflow_path: Path) -> Path:
    for candidate in [workflow_path.parent.parent.parent, *workflow_path.parents]:
        if (candidate / "connectionreferences.mcs.yml").exists():
            return candidate
    return workflow_path.parent.parent.parent


def find_bootstrap_workflow(search_roots: list[Path], flow_name: str) -> tuple[Path, Path]:
    matches: dict[Path, Path] = {}
    available_flows: list[str] = []

    for root in search_roots:
        for metadata_path in root.rglob("metadata.yml"):
            workflow_path = metadata_path.with_name("workflow.json")
            if not workflow_path.exists():
                continue

            metadata_name = parse_flow_name(metadata_path)
            if metadata_name:
                available_flows.append(metadata_name)

            haystacks = [metadata_name.lower(), metadata_path.parent.name.lower()]
            if flow_name.lower() in haystacks[0] or flow_name.lower() in haystacks[1]:
                matches[workflow_path] = derive_solution_root(workflow_path)

    if len(matches) == 1:
        workflow_path = next(iter(matches))
        return workflow_path, matches[workflow_path]

    if len(matches) > 1:
        match_list = "\n".join(f"- {workflow_path}" for workflow_path in matches)
        raise RuntimeError(
            f"Found multiple workflow.json matches for flow name '{flow_name}':\n{match_list}"
        )

    available_hint = ", ".join(sorted(set(available_flows))) if available_flows else "none"
    raise RuntimeError(
        f"Could not find a Bootstrap flow named '{flow_name}'. "
        f"Available flows: {available_hint}. "
        "Create and export a shell flow first, then rerun this script."
    )


def backup_file(path: Path) -> Path:
    backup_path = path.with_suffix(path.suffix + ".bak")
    shutil.copy2(path, backup_path)
    return backup_path


def update_workflow_file(workflow_path: Path, solution_root: Path) -> Path:
    workflow_payload = load_json(workflow_path)
    ensure_sharepoint_connection_reference(workflow_payload, solution_root)
    workflow_payload.setdefault("properties", {})["definition"] = BOOTSTRAP_DEFINITION
    backup_path = backup_file(workflow_path)
    write_json(workflow_path, workflow_payload)
    return backup_path


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Inject the full PowerClaw bootstrap Power Automate definition into an exported "
            "solution's Bootstrap workflow.json."
        )
    )
    parser.add_argument(
        "solution_path",
        help="Path to a pac-exported solution zip or an unpacked solution folder.",
    )
    parser.add_argument(
        "--flow-name",
        default="Bootstrap",
        help="Bootstrap shell flow name to target. Default: Bootstrap",
    )
    parser.add_argument(
        "--extract-dir",
        help="Optional directory to use when a zip must be expanded before searching.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    solution_path = Path(args.solution_path).expanduser().resolve()
    if not solution_path.exists():
        raise FileNotFoundError(f"Solution path does not exist: {solution_path}")

    search_roots = candidate_roots(
        solution_path,
        Path(args.extract_dir).expanduser().resolve() if args.extract_dir else None,
    )
    workflow_path, solution_root = find_bootstrap_workflow(search_roots, args.flow_name)
    backup_path = update_workflow_file(workflow_path, solution_root)

    print(f"Updated bootstrap workflow: {workflow_path}")
    print(f"Backup created at: {backup_path}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
