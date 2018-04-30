# Microsoft FastTrack Open Source - Create Team in SPFx

This sample shows how to use a SharePoint Framework field customizer solution to manage the creation of a Microsoft Team. It adds two field customizers, one to run a set of business rules on a submitted team and the other to create the team. Both actions run in the context of the current user, so the sample actor would be an administrator who would review, approve, and create teams. The sample is a [React](https://reactjs.org/) based solution and makes use of the [Office UI Fabric React Components](https://developer.microsoft.com/en-us/fabric#/components).

You can see the code used to create the [team here](/src/extensions/teamApproval/components/cells.tsx#L144). This makes use of the [PnPjs libraries](https://github.com/pnp/pnpjs) to simplify creation of the team and authentication. See the [code index](CODE-INDEX.md) to quickly see how the pieces work.

**This sample currently makes use of pre-release features of Microsoft365 related to ADAL authentication. You need to be working in a first release tenant for the steps described to work correctly. We will remove this message once the features reach GA. If you have any questions please open an issue so we can help.**

To get around this limitation you can register an Azure AD application with delegated Group Read/Write all permissions and paste the client id for that app in the demo-config.js file at the root of the project.

## Usage

### Setup

Please review [this guide](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/serving-your-extension-from-sharepoint) for additional details on the deployment process.

1. [Setup your development environment](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/set-up-your-development-environment) for SPFx
2. Clone this solution folder
3. Run `npm install`
4. Run `gulp build`
5. Run `gulp bundle`
6. Run `gulp package-solution`
7. Copy the ./sharepoint/solution/fasttrack-teams-governance-sample.sppkg to your app catalog (may require admin assistance depending on environment)
8. Deploy the solution when prompted
9. Approve the requested permissions in the admin center ([details](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/use-aad-tutorial#deploy-the-solution-and-grant-permissions))
10. Run `gulp serve --nobrowser` to serve the files from local host for testing
11. Navigate to your site collection and add the app "fasttrack-teams-governance-sample-client-side-solution" to your site

_You must allow pop-ups for the site where you are testing to enable the ADAL authentication_

### Run

Ensure the local web server is running by executing the command `gulp serve --nobrowser`

The solution should create a new list whose title is "Team Approval" in your site. Navigate to this list and add a new list item using the included "Team Request" content type. Once you add the item you should see the two custom fields displayed in the standard list view.

Clicking the "Run Scan" button will execute the code in the [TeamPrecheck component](.src/extensions/teamPrecheck/components/TeamPrecheck.tsx). This shows how you can run a series of checks to determine if a team should be approved based on your business rules. In this example we see if a team with the supplied name already exists, that the name isn't empty, and that the name doesn't start with a number. We also show how you can have blocking and non-blocking rules. You can expand this logic to meet your specific requirements.

Clicking the "Approve" or "Deny" buttons will execute the code in the [TeamApproval component](.src/extensions/teamApproval/components/cells.tsx#L144). In either case you will be presented with a dialog where you can leave comments or update the team properties before creation.

### Deployment

[This guide](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/hosting-extension-from-office365-cdn) covers deploying your extension to a CDN for production.


## Applies To

- SharePoint Online

## Author

|Author|Original Publish Date
|----|--------------------------
|Patrick Rodgers, Microsoft|April 20, 2018|

## Issues

Please report any issues you find to the [issues list](../issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software or releases. As such, support is not available through premier or other official support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, but there is no support SLA associated with these tools.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](https://github.com/Microsoft/FastTrack/blob/master/LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
