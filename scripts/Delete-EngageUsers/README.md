---
title: Delete-EngageUsers
type: script
category: PowerShell
summary: Bulk-remove users from Viva Engage communities from a CSV through Microsoft Graph; dry run by default, accounts are not deleted.
author: Dean Cron
version: 1.0.0
published: "2023-11-28"
updated: "2026-07-22"
tags:
  - viva-engage
  - administration
  - communities
  - bulk-delete
  - microsoft-graph
format: ps1
featured: false
status: active
whatItIs: >-
  A PowerShell sample that removes users from the Microsoft 365 group behind a Viva Engage community,
  one group and user per CSV row, through Microsoft Graph. It removes access to the listed communities
  only; it does not delete the user's account or remove them from any other community. Removal can't
  be undone by the script. It runs as a dry run by default (`$whatIfMode = $true`).
whyUseIt:
  - Remove many users from communities in one run.
  - Preview the removals first; `$whatIfMode` is `$true` by default.
  - Resolves each user's object ID from the email address in the CSV for you.
howToUse: |-
  1. Create a Microsoft Entra app registration with the Microsoft Graph `Group.ReadWrite.All` application permission and grant admin consent.
  2. Create a CSV with a `GroupID` column (the Microsoft 365 group ID behind the community) and an `Email` column (the user to remove), one pair per row.
  3. Set `$usersToBeDeletedCSV`, `$ClientId`, `$TenantId`, and `$ClientSecret` near the top of the script.
  4. Run with the default `$whatIfMode = $true` and review the output. Set it to `$false` only when you are sure.
  5. Run:

     ```powershell
     .\Delete-EngageUsers.ps1
     ```
prerequisites:
  - "Test in a non-production tenant first; removals can't be undone by the script"
  - "Microsoft Entra app registration with the Group.ReadWrite.All application permission and admin consent"
  - "CSV with GroupID and Email columns; GroupID is the Microsoft 365 group GUID behind the community"
---

# Microsoft FastTrack Open Source - Delete-EngageUsers

This sample script bulk-removes users from a specific Viva Engage community (Microsoft 365 group) using the Microsoft Graph API.

**Important - this is a change in scope from earlier versions:** The original version of this script called the legacy Yammer REST API's `DELETE /users/{id}.json` endpoint, which deleted/deactivated the user's Yammer account entirely, removing them from every group/community they belonged to. There is no Graph (or otherwise supported) API to delete a "Yammer user" as a standalone concept. This version instead removes each listed user from **one specific group per CSV row** - it does not delete their account and does not touch any other group/community memberships they may have.

If you need to remove someone's access across every community they belong to, either:
- Run this script once per group they're a member of (list each group/user pair as its own CSV row), or
- Deprovision/disable their Entra ID account instead, which is the modern equivalent of deactivating a user tenant-wide.

## Usage

### Prerequisites

- You must create a new Azure AD (Entra ID) App Registration with the following Microsoft Graph **application** permission, with admin consent granted:
  ```
  Group.ReadWrite.All
  ```

- You'll need to create a CSV file containing two columns:
	- **GroupID**. The Microsoft 365 group ID (a GUID) that backs the community you want to remove the user from.
	- **Email**. The UPN/email address of the user to remove.

  The CSV should look similar to this:

  ![CSV format](UserIDSample.png?raw=true "Title")

  You can find the group ID for a community via Microsoft Graph:
  `GET https://graph.microsoft.com/beta/employeeExperience/communities?$filter=displayName eq 'Community Display Name'`
  The `groupId` property in the response is the value to use.

### Variables

There are a few variables you need to change in the script itself. These are located very early in the script just below “<############    STUFF YOU NEED TO MODIFY    ############>”:

1. **$usersToBeDeletedCSV = 'C:\temp\userstobedeleted.csv'**

	Point this to the CSV file you created as mentioned above.

2. **$ClientId = "clientid"**

	  >Replace with the Client ID of the app registration you created in the prerequisites.

3. **$TenantId = "tenantid"**

     >Replace with your tenant ID.

4. **$ClientSecret = "clientsecret"**

     >Replace with the client secret value of the app registration you created in the prerequisites.

5. **$whatIfMode = $true**

   The script runs in a WhatIf mode by default since removal can't be undone, so it'll only loop through the CSV and tell you which users it *would* have removed, it doesn't actually take hard action. When you're ready to have it actually remove users, change the value to $false

### Parameters

None

### Execution

Once you've completed the pre-reqs, you're ready to go. Run the script like so:

	.\Delete-EngageUsers.ps1

## Applies To

- Viva Engage communities in M365

## Author

|Author|Original Publish Date
|----|--------------------------
|Dean Cron, Microsoft|November 28th, 2023|
|Dean Cron, Microsoft|November 4th, 2025|
|Dean Cron, Microsoft|July 22nd, 2026|

## Issues

Please report any issues you find to the [issues list](../../../../issues).

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

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,or trademarks, whether by implication, estoppel or otherwise.

