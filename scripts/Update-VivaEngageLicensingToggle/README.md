# Microsoft FastTrack Open Source - Update-VivaEngageLicensingToggle

>**IMPORTANT:** This script and readme are being published ahead of the availability of both the endpoint and additional documentation. This message will be removed when the underlying REST API is available for use.

This sample script checks the status and enforce per-user licensing for a Viva Engage network using a REST API endpoint. The script is designed to be used as-is, but you can modify it to suit your organization's requirements, if required.

> **⚠️ Warning:** This script makes changes to the Viva Engage network which are **irreversible**. Ensure that Viva Engage Core (recommended) or Yammer Enterprise service plans have been provisioned to all users before running this script.

## Usage

### Prerequisites

- Global administrator access to the Viva Engage network where you wish to enforce per-user licensing.
- PowerShell (version 5.1 or above recommended). 
- Network access from the machine running the script to Viva Engage.
- Service plans have been provisioned to all Viva Engage users.

### Parameters

|Parameter|Description
|----|--------------------------
|Action|Either *enforce_user_license* or *fetch_current_license_state*|
|Token|A string containing a valid Entra token with Global Admin privileges|

### Usage

#### Checking the setting state

Check the current setting:

```./license.ps1 fetch_current_license_state "<AAD_ACCESS_TOKEN>"```

This makes the following request: 

> **GET** /api/v1/networks/fetch_current_enforce_license_state

#### Enforcing per-user licensing

Enforce per-user licensing (this cannot be reversed):

```./license.ps1 enforce_user_license "<AAD_ACCESS_TOKEN>"```
 
This makes the following request: 

> **POST** /api/v1/networks/enforce_user_license

## Applies To

Viva Engage networks in M365 which have not previously enforced per-user licensing through the legacy Yammer admin center.

## Author

|Author|Original Publish Date
|----|--------------------------
|Manish Kumar, Microsoft|October 1st, 2025|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

## Support Statement

### Enforcement of per-user licensing

This script enforces per-user licensing through a REST API call to Viva Engage. If you are using the script as-is and you encounter issues, please [open an M365 support case](https://aka.ms/vivaengagesupportcase) for assistance. Additional information including network traces or other logs may be requested. Investigation by Microsoft Support may determine that assistance is required from a different channel. As a result, you may be redirected to other channels, or the case may be closed.

If you use this script to enforce per-user licensing ahead of license provisioning, you may impact end user access to your Viva Engage network. Should the per-user licensing setting be enabled prematurely, you should provision the appropriate service plans as disabling this setting is not supported.

### Customization of the script

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support for customization of the script is not available through Unified or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.

