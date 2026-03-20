from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any


HARDCODED_SITE_URL = "https://m365cpi23966391.sharepoint.com/sites/PowerClaw-Workspace"
SITE_URL_PARAMETER = "@parameters('ftk_PowerClawSharePointSiteURL')"
ADMIN_EMAIL = "admin@M365CPI23966391.onmicrosoft.com"
ADMIN_EMAIL_PARAMETER = "@parameters('ftk_PowerClawAdminEmail')"
LIST_GUID_TO_NAME = {
    "c330bd00-7966-455c-991c-d726485c7ae5": "PowerClaw_Memory_Log",
    "390396f9-02ac-4401-b3f5-4808ed84ec24": "PowerClaw_Config",
    "e3c0c6fd-a67a-470f-967e-727f13814e52": "PowerClaw Memory",
    "592d6022-8c5d-4a2b-8cb9-1f63f30c4e5b": "PowerClaw Tasks",
}
SCRIPT_ROOT = Path(__file__).resolve().parent
DEFAULT_WORKFLOWS = [
    SCRIPT_ROOT
    / "PowerClaw"
    / "workflows"
    / "HeartbeatFlow-04cf2235-af1c-f111-88b1-6045bd0079f1"
    / "workflow.json",
    SCRIPT_ROOT
    / "PowerClaw"
    / "workflows"
    / "GetContext-ff84c862-c7f6-819b-5ec6-7201f9389c85"
    / "workflow.json",
]


def get_definition(document: dict[str, Any]) -> dict[str, Any]:
    if isinstance(document.get("properties"), dict) and isinstance(
        document["properties"].get("definition"), dict
    ):
        return document["properties"]["definition"]
    if isinstance(document.get("definition"), dict):
        return document["definition"]
    raise ValueError("Could not find flow definition at properties.definition or definition.")


def ensure_parameters(
    definition: dict[str, Any], *, include_admin_email: bool, summary: Counter[str]
) -> None:
    parameters = definition.setdefault("parameters", {})
    if not isinstance(parameters, dict):
        raise ValueError("Flow definition parameters must be an object.")

    if "ftk_PowerClawSharePointSiteURL" not in parameters:
        parameters["ftk_PowerClawSharePointSiteURL"] = {"defaultValue": "", "type": "String"}
        summary["parameters_added"] += 1

    if include_admin_email and "ftk_PowerClawAdminEmail" not in parameters:
        parameters["ftk_PowerClawAdminEmail"] = {"defaultValue": "", "type": "String"}
        summary["parameters_added"] += 1


def parameterize_node(node: Any, summary: Counter[str]) -> Any:
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "dataset" and value == HARDCODED_SITE_URL:
                node[key] = SITE_URL_PARAMETER
                summary["site_url_replacements"] += 1
                continue

            if key == "table" and value in LIST_GUID_TO_NAME:
                node[key] = LIST_GUID_TO_NAME[value]
                summary["table_replacements"] += 1
                continue

            if isinstance(value, str) and value == ADMIN_EMAIL:
                node[key] = ADMIN_EMAIL_PARAMETER
                summary["admin_email_replacements"] += 1
                continue

            node[key] = parameterize_node(value, summary)
        return node

    if isinstance(node, list):
        for index, item in enumerate(node):
            if isinstance(item, str) and item == ADMIN_EMAIL:
                node[index] = ADMIN_EMAIL_PARAMETER
                summary["admin_email_replacements"] += 1
            else:
                node[index] = parameterize_node(item, summary)
        return node

    return node


def process_workflow(path: Path) -> Counter[str]:
    summary: Counter[str] = Counter()
    document = json.loads(path.read_text(encoding="utf-8-sig"))
    definition = get_definition(document)
    include_admin_email = "HeartbeatFlow-" in path.parent.name

    parameterize_node(document, summary)
    ensure_parameters(
        definition, include_admin_email=include_admin_email, summary=summary
    )

    path.write_text(
        json.dumps(document, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8-sig",
    )
    return summary


def main() -> int:
    workflow_paths = [Path(argument).resolve() for argument in sys.argv[1:]]
    if not workflow_paths:
        workflow_paths = DEFAULT_WORKFLOWS

    total_summary: Counter[str] = Counter()
    for workflow_path in workflow_paths:
        summary = process_workflow(workflow_path)
        total_summary.update(summary)
        print(
            f"{workflow_path}: "
            f"site_url_replacements={summary['site_url_replacements']}, "
            f"table_replacements={summary['table_replacements']}, "
            f"admin_email_replacements={summary['admin_email_replacements']}, "
            f"parameters_added={summary['parameters_added']}"
        )

    print(
        "TOTAL: "
        f"site_url_replacements={total_summary['site_url_replacements']}, "
        f"table_replacements={total_summary['table_replacements']}, "
        f"admin_email_replacements={total_summary['admin_email_replacements']}, "
        f"parameters_added={total_summary['parameters_added']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

