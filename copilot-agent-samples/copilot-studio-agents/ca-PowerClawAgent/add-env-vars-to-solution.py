from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import xml.etree.ElementTree as ET


SCRIPT_ROOT = Path(__file__).resolve().parent
DEFAULT_SOLUTION_DIR = SCRIPT_ROOT / "PowerClaw_unpacked"
STRING_TYPE_CODE = "100000000"
ROOT_COMPONENT_TYPE = "380"
XSI_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance"


@dataclass(frozen=True)
class EnvironmentVariableDefinition:
    schema_name: str
    display_name: str
    description: str


ENVIRONMENT_VARIABLES = (
    EnvironmentVariableDefinition(
        schema_name="ftk_SharePointSiteUrl",
        display_name="PowerClaw SharePoint Site URL",
        description=(
            "URL of the SharePoint site used as PowerClaw's workspace "
            "(e.g., https://contoso.sharepoint.com/sites/PowerClaw-Workspace)"
        ),
    ),
    EnvironmentVariableDefinition(
        schema_name="ftk_AdminEmail",
        display_name="PowerClaw Admin Email",
        description=(
            "Email address for the PowerClaw administrator who receives alerts and reports"
        ),
    ),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Add Power Platform environment variable components to an unpacked solution."
    )
    parser.add_argument(
        "solution_dir",
        nargs="?",
        default=str(DEFAULT_SOLUTION_DIR),
        help="Path to the unpacked solution directory. Defaults to PowerClaw_unpacked next to this script.",
    )
    return parser.parse_args()


def require_path(path: Path) -> Path:
    if not path.exists():
        raise FileNotFoundError(f"Required path does not exist: {path}")
    return path


def indent_xml(element: ET.Element, level: int = 0) -> None:
    indent = "\n" + ("  " * level)
    child_indent = "\n" + ("  " * (level + 1))

    if len(element):
        if not element.text or not element.text.strip():
            element.text = child_indent

        for child in element:
            indent_xml(child, level + 1)
            if not child.tail or not child.tail.strip():
                child.tail = child_indent

        if not element[-1].tail or not element[-1].tail.strip():
            element[-1].tail = indent
    elif level and (not element.tail or not element.tail.strip()):
        element.tail = indent


def write_xml(path: Path, root: ET.Element, *, preserve_xsi_namespace: bool) -> None:
    xml_text = ET.tostring(root, encoding="utf-8", xml_declaration=True).decode("utf-8")
    xml_text = xml_text.replace(
        "<?xml version='1.0' encoding='utf-8'?>",
        '<?xml version="1.0" encoding="utf-8"?>',
        1,
    )

    if preserve_xsi_namespace and 'xmlns:xsi="' not in xml_text:
        root_tag = f"<{root.tag}"
        replacement = f'{root_tag} xmlns:xsi="{XSI_NAMESPACE}"'
        xml_text = xml_text.replace(root_tag, replacement, 1)

    path.write_text(xml_text, encoding="utf-8-sig")


def get_or_create_environment_variable_definitions(root: ET.Element) -> tuple[ET.Element, bool]:
    definitions = root.find("environmentvariabledefinitions")
    if definitions is not None:
        return definitions, False

    definitions = ET.Element("environmentvariabledefinitions")
    languages = root.find("Languages")
    if languages is None:
        root.append(definitions)
    else:
        children = list(root)
        root.insert(children.index(languages), definitions)
    return definitions, True


def ensure_definition(
    definitions_element: ET.Element, variable: EnvironmentVariableDefinition
) -> bool:
    for definition in definitions_element.findall("environmentvariabledefinition"):
        if definition.get("schemaname") == variable.schema_name:
            return False

    definition = ET.SubElement(
        definitions_element,
        "environmentvariabledefinition",
        {"schemaname": variable.schema_name},
    )
    ET.SubElement(definition, "displayname", {"default": variable.display_name})
    ET.SubElement(definition, "description", {"default": variable.description})
    type_element = ET.SubElement(definition, "type")
    type_element.text = STRING_TYPE_CODE
    required_element = ET.SubElement(definition, "isrequired")
    required_element.text = "1"
    return True


def ensure_root_component(root_components: ET.Element, schema_name: str) -> bool:
    for component in root_components.findall("RootComponent"):
        if (
            component.get("type") == ROOT_COMPONENT_TYPE
            and component.get("schemaname") == schema_name
        ):
            return False

    ET.SubElement(
        root_components,
        "RootComponent",
        {"type": ROOT_COMPONENT_TYPE, "schemaname": schema_name, "behavior": "0"},
    )
    return True


def update_customizations(customizations_path: Path) -> tuple[int, bool]:
    original_text = customizations_path.read_text(encoding="utf-8-sig")
    tree = ET.parse(customizations_path)
    root = tree.getroot()
    definitions_element, created_container = get_or_create_environment_variable_definitions(root)

    added_count = 0
    for variable in ENVIRONMENT_VARIABLES:
        if ensure_definition(definitions_element, variable):
            added_count += 1

    if created_container or added_count:
        indent_xml(root)
        write_xml(
            customizations_path,
            root,
            preserve_xsi_namespace='xmlns:xsi="' in original_text,
        )

    return added_count, created_container


def update_solution(solution_path: Path) -> int:
    original_text = solution_path.read_text(encoding="utf-8-sig")
    tree = ET.parse(solution_path)
    root = tree.getroot()
    root_components = root.find("./SolutionManifest/RootComponents")
    if root_components is None:
        raise ValueError(f"Could not find SolutionManifest/RootComponents in {solution_path}")

    added_count = 0
    for variable in ENVIRONMENT_VARIABLES:
        if ensure_root_component(root_components, variable.schema_name):
            added_count += 1

    if added_count:
        indent_xml(root)
        write_xml(solution_path, root, preserve_xsi_namespace='xmlns:xsi="' in original_text)

    return added_count


def main() -> int:
    args = parse_args()
    solution_dir = require_path(Path(args.solution_dir).resolve())
    other_dir = require_path(solution_dir / "Other")
    customizations_path = require_path(other_dir / "Customizations.xml")
    solution_path = require_path(other_dir / "Solution.xml")

    added_definitions, created_container = update_customizations(customizations_path)
    added_root_components = update_solution(solution_path)

    print(
        "Updated solution files: "
        f"definitions_added={added_definitions}, "
        f"definitions_container_created={str(created_container).lower()}, "
        f"root_components_added={added_root_components}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
