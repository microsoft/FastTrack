import { Log } from "@microsoft/sp-core-library";
import { override } from "@microsoft/decorators";
import * as React from "react";

import {
  autobind,
  ProgressIndicator,
  Icon,
  HoverCard,
  IExpandingCardProps,
  IconButton
} from "office-ui-fabric-react";

import styles from "./TeamPrecheck.module.scss";

import { graph } from "@pnp/graph";
import { sp, ItemUpdateResult } from "@pnp/sp";
import { stringIsNullOrEmpty } from "@pnp/common";

import { jsonToEscapedString } from "../../../utils";

const LOG_SOURCE: string = "TeamPrecheck";

import { ITeamPrecheckProps, ITeamPrecheckState } from "../interfaces";

export default class TeamPrecheck extends React.Component<ITeamPrecheckProps, ITeamPrecheckState> {

  constructor(props: ITeamPrecheckProps, state: ITeamPrecheckState) {
    super(props, state);

    this.state = {
      status: props.fieldValue.status,
      message: props.fieldValue.message,
    };
  }

  @override
  public render(): React.ReactElement<{}> {

    let element: any = null;

    switch (this.state.status) {
      case "None":
        console.log("none");
        element = <this.None />;
        break;
      case "Pass":
        element = <this.Passing onClick={this._onRefreshClick} />;
        break;
      case "InProgress":
        element = <this.InProgress />;
        break;
      case "Error":
        element = <this.Error message={this.state.message} />;
        break;
      case "Blocked":
        element = <this.Blocked message={this.state.message} />;
        break;
      case "Warn":
        element = <this.Warning message={this.state.message} />;
        break;
      default:
        element = <this.Unknown status={this.state.status} />;
        break;
    }

    return (
      <div className={styles.cell}>
        {element}
      </div>
    );
  }

  @autobind
  private None(): JSX.Element {
    return (<button onClick={this._onRefreshClick}>Run Scan</button>);
  }

  @autobind
  private Passing(props: any): JSX.Element {
    return (<div>Passing  <IconButton
      iconProps={{ iconName: "Refresh" }}
      title="Refresh"
      onClick={this._onRefreshClick} /></div>);
  }

  @autobind
  private async _onRefreshClick(): Promise<void> {

    this.setState({ status: "InProgress" });

    // now we need to do our scans, so these are just business rules we make up
    const message: string[] = [];
    let isBlocked: boolean = false;

    try {

      // we re-get the values from the item we care about as they might have been updated after this was rendered
      const item: { TeamName: string } = await this.getListItem();

      // team name should not be empty
      if (stringIsNullOrEmpty(item.TeamName)) {
        message.push("Team names must not be empty.");
        isBlocked = true;
      }

      // see if a team (group) with this name exists, but only if the name isn't blank
      if (!stringIsNullOrEmpty(item.TeamName)) {
        const groups: any[] = await graph.groups.filter(`displayName eq '${item.TeamName}'`).select("id").get();
        if (groups.length > 0) {
          message.push("A team with this name already exists.");
          isBlocked = true;
        }

        // see if the name meets some made up qualification, here not starting with a number
        // but we will not block on that
        if (/^\d/i.test(item.TeamName)) {
          message.push("Team names should not start with a number.");
        }
      }

      // update our state
      const state: ITeamPrecheckState = {
        status: message.length > 0 ? isBlocked ? "Blocked" : "Warn" : "Pass",
        message: message.join(", "),
      };

      await this.updateListItem({
        TeamPrecheck: jsonToEscapedString(state),
      });

      this.setState(state);

    } catch (e) {
      this.setState({
        status: "Error",
        message: e.message,
      });
    }
  }

  @autobind
  private Warning(props: { message: string }): JSX.Element {

    const expandingCardProps: IExpandingCardProps = {
      onRenderCompactCard: this._onRenderCompactCard,
      renderData: props.message,
    };

    return (<HoverCard
      expandingCardProps={expandingCardProps}
    >Warn <Icon iconName="Refresh" onClick={this._onRefreshClick} /></HoverCard>);
  }

  @autobind
  private Error(props: { message: string }): JSX.Element {

    const expandingCardProps: IExpandingCardProps = {
      onRenderCompactCard: this._onRenderCompactCard,
      renderData: props.message,
    };

    return (<HoverCard
      expandingCardProps={expandingCardProps}
    >Error <Icon iconName="Refresh" onClick={this._onRefreshClick} /></HoverCard>);
  }

  @autobind
  private _onRenderCompactCard(message: any): JSX.Element {
    return (
      <p>{message}</p>
    );
  }

  @autobind
  private Blocked(props: { message: string }): JSX.Element {

    const expandingCardProps: IExpandingCardProps = {
      onRenderCompactCard: this._onRenderCompactCard,
      renderData: props.message,
    };

    return (<HoverCard
      expandingCardProps={expandingCardProps}
    >Blocked <Icon iconName="Refresh" onClick={this._onRefreshClick} /></HoverCard>);
  }

  @autobind
  private InProgress(): JSX.Element {
    return (<ProgressIndicator />);
  }

  @autobind
  private Unknown(props: { status: string }): JSX.Element {
    return (<span>Unknown: {props.status}</span>);
  }

  protected async updateListItem(properties: any): Promise<ItemUpdateResult> {
    return sp.web.lists.getById(this.props.listId).items.getById(this.props.listItemId).update(properties);
  }

  protected async getListItem(): Promise<{ TeamName: string }> {
    return sp.web.lists.getById(this.props.listId).items.getById(this.props.listItemId).select("TeamName").get();
  }
}
