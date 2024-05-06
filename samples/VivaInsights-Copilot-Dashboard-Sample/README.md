# Build your Own Copilot Dashboard - Sample

## Summary

This is a PowerBI file (.pbix) showing a sample of how the Viva Advanced Insights Person Query export can be visualized in PowerBI. 

![image](https://user-images.githubusercontent.com/11201670/177055668-e3ebfc7a-a3ce-4276-936a-2e1494ede764.png)


## Used SharePoint Framework Version

![version](https://img.shields.io/badge/version-1.15-green.svg)

## Applies to

- [SharePoint Framework](https://aka.ms/spfx)
- [Microsoft 365 tenant](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/set-up-your-developer-tenant)

> Get your own free development tenant by subscribing to [Microsoft 365 developer program](http://aka.ms/o365devprogram)

## Prerequisites

> Application Insights

## Solution

| Solution    | Author(s)                                               |
| ----------- | ------------------------------------------------------- |
| viva-connections-visitor-counter | Michael Bondarevsky bondarevsky@gmail.com |

## Version history

| Version | Date             | Comments        |
| ------- | ---------------- | --------------- |
| 1.0.1     | June 2022   | Upgrade to SPFx v1.15  |
| 1.0.0     | January 29, 2022 | Initial release |

## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**

---

## Minimal Path to Awesome

- Clone this repository
- Ensure that you are at the solution folder
- in the command-line run:
  - **npm install**
  - **gulp serve --nobrowser**
  - **gulp bundle --ship**
  - **gulp package-solution --ship**

> Aditional steps:
  - Log in to the Azure Portal, 
  - Create an Application Insights resource
  - In the sidebar, navigate to Configure > API Access on the sidebar 
  - Create API key with read telemertry permission
  - Copy the Application ID and API Key

