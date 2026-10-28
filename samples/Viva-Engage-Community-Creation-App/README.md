---
title: Viva Engage Community Creation App
type: script
category: Power Apps
summary: Sample Power App and Power Automate flow that create Viva Engage communities by calling the Microsoft Graph community creation API.
author: Dean Cron
version: 1.0.0
published: "2024-07-31"
updated: "2024-11-13"
tags:
  - viva-engage
  - communities
  - power-apps
  - power-automate
  - microsoft-graph
format: bundle
featured: false
status: preview
whatItIs: >-
  An importable Power Apps solution (VivaEngageCommunityCreationApp.zip) containing a canvas app and a
  Power Automate flow. The app collects a community name, description, and privacy setting, and the flow
  gets a Microsoft Graph token with an Entra app registration and creates the community through the
  community creation API, with the signed-in user as owner. It is a sample and not intended for
  production use.
whyUseIt:
  - See an end-to-end example of the Viva Engage community creation API behind a Power App front end.
  - Start from a working app and flow and adapt them to your own community creation process.
howToUse: |-
  1. Create an Entra app registration with the Microsoft Graph `Community.ReadWrite.All` and `User.Read.All` application permissions, grant admin consent, and create a client secret. Note the application (client) ID and directory (tenant) ID.
  2. In Power Apps, choose Import canvas app, upload `VivaEngageCommunityCreationApp.zip`, and select or create an Office 365 Users connection.
  3. Edit the app, remove and re-add the `Viva Engage CC Flow` in the Power Automate pane, and enter your values in the flow's `Get Access Token` action, which uses this request body:

     ```text
     grant_type=client_credentials
     &client_id=CLIENTID
     &client_secret=CLIENTSECRET
     &scope=https://graph.microsoft.com/.default
     ```

  4. Turn the flow on in Power Automate, then save and publish the app. The full steps are in `AppImportInstructions.docx`.
prerequisites:
  - "Microsoft Viva Engage"
  - "Power Apps and Power Automate environment where you can import a solution"
  - "Microsoft Entra app registration with Community.ReadWrite.All and User.Read.All application permissions and a client secret"
  - "Office 365 Users connection"
---

# Viva Engage Community Creation Power App - Sample

## Summary

This Power App import package is intended to be used as a sample that shows how to use the [Viva Engage Community Creation API](https://learn.microsoft.com/en-us/graph/api/employeeexperience-post-communities?view=graph-rest-1.0&tabs=http) to create new communities. Please review the included [Word document](AppImportInstructions.docx) for steps on how to import it into your environment.

![image](VECCApp.png)

## Prerequisites

> Microsoft Viva Engage

## Solution

| Solution    | Author(s)                                               |
| ----------- | ------------------------------------------------------- |
| Viva Engage Community Creation Power App - Sample | Dean Cron - dean.cron@microsoft.com |

## Version history

| Version | Date             | Comments        |
| ------- | ---------------- | --------------- |
| 1.0.0     | July 31st, 2024 | Initial release |


## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**

---


