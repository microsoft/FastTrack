import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { Log } from '@microsoft/sp-core-library';
import { override } from '@microsoft/decorators';
import {
  BaseFieldCustomizer,
  IFieldCustomizerCellEventParameters
} from '@microsoft/sp-listview-extensibility';

import * as strings from 'TeamApprovalFieldCustomizerStrings';

import { CellContainer } from "./components/CellContainer";

import { AdalClient } from "@pnp/common";
import { graph } from "@pnp/graph";

import { ICellContainerProps, ICellState, IFieldValue } from "./interfaces";

import { demoConfig } from "../../demo-config";
import { escapedStringToJson } from "../../utils";

/**
 * If your field customizer uses the ClientSideComponentProperties JSON input,
 * it will be deserialized into the BaseExtension.properties object.
 * You can define an interface to describe it.
 */
export interface ITeamApprovalFieldCustomizerProperties {
  // this is an example; replace with your own property
  sampleText?: string;
}

const LOG_SOURCE: string = "TeamApprovalFieldCustomizer";

export default class TeamApprovalFieldCustomizer
  extends BaseFieldCustomizer<ITeamApprovalFieldCustomizerProperties> {

  @override
  public onInit(): Promise<void> {
    // add your custom initialization to this method.  The framework will wait
    // for the returned promise to resolve before firing any BaseFieldCustomizer events.
    Log.info(LOG_SOURCE, "Activated TeamApprovalFieldCustomizer with properties:");
    Log.info(LOG_SOURCE, JSON.stringify(this.properties, undefined, 2));
    Log.info(LOG_SOURCE, `The following string should be equal: "TeamApprovalFieldCustomizer" and "${strings.Title}"`);

    graph.setup({
      graph: {
        fetchClientFactory: () => {
          const client: AdalClient = AdalClient.fromSPFxContext(this.context);
          client.clientId = demoConfig.clientId;
          return client;
        },
      },
      spfxContext: this.context,
    });

    return Promise.resolve();
  }

  @override
  public onRenderCell(event: IFieldCustomizerCellEventParameters): void {

    // we need to deserialize our field value
    console.log(`fields: ${event.listItem.fields.map(f => f.internalName).join("-")}`);

    const cellProps: ICellContainerProps = {
      listId: this.context.pageContext.list.id.toString(),
      listItemId: event.listItem.getValueByName("ID"),
      fieldValue: escapedStringToJson<IFieldValue>(event.fieldValue),
      submitterEmail: "email@place.com",
      teamName: event.listItem.getValueByName("TeamName"),
      teamDescription: event.listItem.getValueByName("TeamDescription"),
    };

    const renderingComponent: React.ReactElement<ICellContainerProps> = React.createElement(CellContainer, cellProps);
    ReactDOM.render(renderingComponent, event.domElement);
  }

  @override
  public onDisposeCell(event: IFieldCustomizerCellEventParameters): void {
    // this method should be used to free any resources that were allocated during rendering.
    // for example, if your onRenderCell() called ReactDOM.render(), then you should
    // call ReactDOM.unmountComponentAtNode() here.
    ReactDOM.unmountComponentAtNode(event.domElement);
    super.onDisposeCell(event);
  }
}
