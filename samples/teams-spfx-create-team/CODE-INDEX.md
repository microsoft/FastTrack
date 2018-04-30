# Code Index

This page lists the various features in the code and links to their usage in the sample to make it easy to see how things are done and how you might use the techniques in your applications. The listing is organized around each component and then what is used in each.

## Team Precheck Field Customizer

A [React](https://reactjs.org/) based [SharePoint Framework](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/sharepoint-framework-overview) [field customizer](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/building-simple-field-customizer).

* [TeamPrecheckFieldCustomizer](/src/extensions/teamPrecheck/TeamPrecheckFieldCustomizer.ts)
  * [pnp setup](./src/extensions/teamPrecheck/TeamPrecheckFieldCustomizer.ts#L47)
  * [onRenderCell](./src/extensions/teamPrecheck/TeamPrecheckFieldCustomizer.ts#L60)
  * [React Component](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx)
    * [Selective Rendering](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx#L40) - using functions as components
    * [Running Checks](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx#L86)
    * [Render UI Fabric Hovercard](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx#L143)
    * [Get SharePoint list item data](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx#L200)
    * [Update SharePoint list item data](./src/extensions/teamPrecheck/components/TeamPrecheck.tsx#L196)


## Team Approve Field Customizer

A [React](https://reactjs.org/) based [SharePoint Framework](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/sharepoint-framework-overview) [field customizer](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/building-simple-field-customizer).

* [TeamApprovalFieldCustomizer](./src/extensions/teamApproval/TeamApprovalFieldCustomizer.ts)
  * [pnp setup](./src/extensions/teamApproval/TeamApprovalFieldCustomizer.ts#L43)
  * [onRenderCell](./src/extensions/teamPrecheck/TeamPrecheckFieldCustomizer.ts#L56)
  * [Cell Container React Component](./src/extensions/teamApproval/components/CellContainer.tsx)
    * [Selective Rendering](./src/extensions/teamApproval/components/CellContainer.tsx#L46) - using component classes
    * [Tracking State](./src/extensions/teamApproval/components/CellContainer.tsx#L75)
  * [Cell Component Classes](./src/extensions/teamApproval/components/cells.tsx)
    * [CellBase](./src/extensions/teamApproval/components/cells.tsx#L23) - base class for cells
    * [ApprovedCell](./src/extensions/teamApproval/components/cells.tsx#L48)
    * [DeniedCell](./src/extensions/teamApproval/components/cells.tsx#L56) - shows use of Hovercard
    * [ErrorCell](./src/extensions/teamApproval/components/cells.tsx#L79)
    * [PendingCell](./src/extensions/teamApproval/components/cells.tsx#L110) - shows button actions, getting information from a dialog, updating SharePoint

## References

* [SharePoint Framework](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/sharepoint-framework-overview)
* [Microsoft Graph](https://developer.microsoft.com/en-us/graph/)
* [React](https://reactjs.org/)
* [SharePoint Patterns and Practices](https://dev.office.com/patterns-and-practices)
* [PnPjs Libraries](https://github.com/pnp/pnpjs)
* [Office UI Fabric](https://developer.microsoft.com/en-us/fabric)
* [TypeScript](https://www.typescriptlang.org/)
