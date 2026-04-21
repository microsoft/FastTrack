# Microsoft FastTrack Open Source - M365 Copilot Agents Cost Calculator

An interactive, browser-based calculator that helps you estimate production costs for Microsoft 365 Copilot agents — including Custom Agents (Copilot Studio), Agent Builder (M365 Copilot), SharePoint Agents, and Azure Foundry Agents — before you deploy them.

> **⚠️ Important:** This tool produces **planning estimates only**. It is not a billing commitment, a contractual obligation, or a guarantee of any kind. Actual charges will vary based on runtime behavior, tenant configuration, model usage, and current Microsoft pricing. See the [full disclaimer](#legal--disclaimer-notice) below.

## Usage

### Quick Start

1. Open [`index.html`](./index.html) in any modern browser (Edge, Chrome, Firefox) — no account, server, or login required
2. Pick a **Quick Start Template** from the drop-down (e.g., *Enterprise FAQ agent*)
3. Scroll to the bottom to see the **Example Prompt & Cost Trace** and **Production Cost Estimate**
4. Adjust any numbers to match your scenario — the estimate refreshes instantly
5. Click **Export CSV** or **Print** to save results

### Hosted Version

The calculator is also available via GitHub Pages at:

`https://microsoft.github.io/FastTrack/copilot-agent-strategy/copilot-agents-cost-tool/`

### Features

- **4 agent types**: Custom Agent (Copilot Studio), Agent Builder (M365 Copilot), SharePoint Agent, Azure Foundry Agent
- **Quick start templates**: Enterprise FAQ, HR Policy, IT Helpdesk with tools + flows, General Purpose (GPT-4o), Code Assistant (GPT-4.1)
- **12 Azure OpenAI models**: GPT-4o family, GPT-4.1 family, GPT-5 family (incl. nano, 5.1, 5.2, 5.3), o3, o4-mini
- **Full cost modeling**: Knowledge sources, tools/connectors, AI prompts, agent flows, reasoning models, content processing
- **Copilot Credits & Azure tokens**: Models both billing systems depending on agent type
- **Capacity tracking**: Prepaid vs. pay-as-you-go comparison with overage visualization
- **M365 Copilot license impact**: Accounts for licensed users whose interactions cost zero credits
- **Export**: CSV export and print-friendly PDF output
- **Dark/light theme**: Toggle between themes

### Walk-Through Guide

For a detailed step-by-step guide covering every section of the calculator, see [GUIDE.md](./GUIDE.md).

## Applies To

- Microsoft 365 Copilot
- Microsoft Copilot Studio
- Azure AI Foundry Agent Service
- Microsoft 365 Copilot Agent Builder

## Author

|Author|Original Publish Date
|----|--------------------------
|[Georgi Nunev](mailto:Georgi.Nunev@microsoft.com)|April 2025|

## Reference Links

- [Copilot Credits billing rates (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)
- [Reasoning model billing (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#reasoning-model-billing-rates)
- [Cost considerations for extensibility (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/cost-considerations)
- [Foundry Agent Service overview (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/foundry/agents/overview)
- [Azure OpenAI pricing (azure.microsoft.com)](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/)

## Issues

Please report any issues you find to the [issues list](https://github.com/Microsoft/FastTrack/issues).

## Legal & Disclaimer Notice

This tool is provided for **planning and estimation purposes only**. It does not constitute a contract, quote, invoice, or billing commitment of any kind. Microsoft's actual pricing, licensing terms, and billing behavior are governed solely by the applicable Microsoft Customer Agreement, Product Terms, and the Azure pricing pages in effect at the time of use.

Pricing rates used in this calculator were sourced from Microsoft Learn documentation and Azure pricing pages. Rates are subject to change without notice. Always verify current rates at:
- [Copilot Credits billing rates](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates)
- [Azure OpenAI pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/)

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
