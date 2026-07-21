---
# Required catalog metadata. See docs/CATALOG-METADATA.md.
title: "Your resource title"
type: script # script | agent | strategy | analytics | prompt | skill
category: "PowerShell" # Short catalog sub-label, such as Copilot Studio or Power BI
summary: "Describe the resource and its outcome in 140 characters or fewer."
author:
  - "Your Name"
version: 1.0.0
published: 2026-01-01
updated: 2026-01-01

# Recommended discovery metadata.
tags:
  - example
format: ps1 # ps1 | bundle | declarative | interactive | pptx | pbix | md
featured: false
status: active # active | preview | archived

# Detail-page content. Use YAML block scalars for paragraphs and Markdown.
whatItIs: >-
  Explain what this resource is, what it produces, and the problem it addresses.
whyUseIt:
  - "State a concrete outcome or when-to-use scenario."
  - "State another verified benefit."
howToUse: |-
  1. Install or download the resource.
  2. Configure the prerequisites described below.
  3. Run the resource:

     ```powershell
     .\Your-Script.ps1
     ```
prerequisites:
  - "List required products, permissions, modules, or licenses."
# url: "https://github.com/microsoft/FastTrack/tree/master/path/to/resource"
---

# Microsoft FastTrack Open Source - Your resource title

Introduce the resource, the problem it solves, and its intended audience.

## Usage

Provide a complete installation and usage guide. Include configuration, options, expected output, and important error handling. You may link to supporting material, but this section must contain enough detail to use the resource.

## Applies To

- List the applicable Microsoft products and environments.

## Author

Keep this human-readable table aligned with the front-matter authors.

| Author | Original Publish Date |
| --- | --- |
| Your Name | YYYY-MM-DD |

## Issues

Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

<!-- DO NOT DELETE OR ALTER THE SECTIONS BELOW. -->

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
