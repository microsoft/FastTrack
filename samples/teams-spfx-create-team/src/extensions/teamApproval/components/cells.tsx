import { Log } from '@microsoft/sp-core-library';
import { override } from '@microsoft/decorators';
import * as React from 'react';
import {
    Link as ReactLink,
    Button as ReactButton,
    ProgressIndicator as ReactProgress,
    autobind,
    HoverCard,
    IExpandingCardProps,
    Icon,
} from 'office-ui-fabric-react';

import styles from './TeamApproval.module.scss';
import { ICellProps, ICellState, IFieldValue } from '../interfaces';
import { sp, ItemUpdateResult } from "@pnp/sp";
import { graph, TeamCreateResult } from "@pnp/graph";
import { ApproveTeamDialog } from "./ApproveTeamDialog";
import { DenyTeamDialog } from "./DenyTeamDialog";

import { jsonToEscapedString } from "../../../utils";

const LOG_SOURCE: string = 'TeamApproval';

export abstract class CellBase extends React.Component<ICellProps, ICellState> {

    constructor(props: ICellProps, state: ICellState) {
        super(props, state);

        this.state = {
            fieldValue: props.fieldValue,
        };
    }

    @override
    public componentDidMount(): void {
        Log.info(LOG_SOURCE, 'React Element: TeamApproval mounted');
    }

    @override
    public componentWillUnmount(): void {
        Log.info(LOG_SOURCE, 'React Element: TeamApproval unmounted');
    }

    protected async updateListItem(properties: any): Promise<ItemUpdateResult> {
        return sp.web.lists.getById(this.props.listId).items.getById(this.props.listItemId).update(properties);
    }
}

export class ApprovedCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {
        return (<span><Icon iconName="TeamsLogo" className={styles.IconSuccess} />Created</span>);
    }
}

export class DeniedCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {

        const expandingCardProps: IExpandingCardProps = {
            onRenderCompactCard: this._onRenderCompactCard,
            renderData: this.props.fieldValue.deniedReason,
        };

        return (<HoverCard
            expandingCardProps={expandingCardProps}
        ><Icon iconName="InfoSolid" className={styles.IconDenied} />Denied</HoverCard>);
    }

    @autobind
    private _onRenderCompactCard(reason: any): JSX.Element {
        return (
            <p className={styles.TeamApprovalHovercard}>{reason}</p>
        );
    }
}

export class ErrorCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {

        const expandingCardProps: IExpandingCardProps = {
            onRenderCompactCard: this._onRenderCompactCard,
            renderData: this.props.fieldValue.error,
        };

        return (<HoverCard
            expandingCardProps={expandingCardProps}
        ><Icon iconName="IncidentTriangle" className={styles.IconError} />Error</HoverCard>);
    }

    @autobind
    private _onRenderCompactCard(error: any): JSX.Element {
        return (
            <p className={styles.TeamApprovalHovercard}>{error}</p>
        );
    }
}

export class UnknownCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {
        return (<span><Icon iconName="Help" className={styles.IconUnknown} />Unknown: {this.props.fieldValue.status}</span>);
    }
}

export class PendingCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {
        return (
            <div className={styles.cell}>
                <ReactButton onClick={this.approveTeam} text="Approve" />
                <ReactButton onClick={this.denyTeam} text="Deny" />
            </div>
        );
    }

    @autobind
    private async approveTeam(): Promise<void> {

        const dialog: ApproveTeamDialog = new ApproveTeamDialog();
        dialog.teamName = this.props.teamName;
        dialog.teamDescription = this.props.teamDescription;
        dialog.approve = this.doApproveTeam;
        dialog.show();
    }

    @autobind
    private async doApproveTeam(name: string, description: string): Promise<void> {

        const newFieldValue: IFieldValue = {
            status: "Approved",
        };

        // show  progress message
        this.props.onCellChanged({ status: "InProgress" });

        try {

            const team: TeamCreateResult = await graph.teams.create(this.props.teamName, this.props.teamDescription);

            newFieldValue.groupId = team.data.id;

            this.updateListItem({
                TeamApproval: jsonToEscapedString(newFieldValue),
            });

            this.props.onCellChanged(newFieldValue);

        } catch (e) {
            this.handleError(e);
        }
    }

    @autobind
    private async denyTeam(): Promise<void> {

        const dialog: DenyTeamDialog = new DenyTeamDialog();
        dialog.deny = this.doDenyTeam;
        dialog.show();
    }

    @autobind
    private async doDenyTeam(reason: string): Promise<void> {

        const newFieldValue: IFieldValue = {
            status: "Denied",
            deniedReason: reason
        };

        // show a progress message
        this.props.onCellChanged({ status: "InProgress" });

        try {

            const updateResult: ItemUpdateResult = await this.updateListItem({
                TeamApproval: jsonToEscapedString(newFieldValue),
            });

            this.props.onCellChanged(newFieldValue);

        } catch (e) {
            this.handleError(e);
        }
    }

    private async handleError(e: any): Promise<void> {
        const errorFieldValue: IFieldValue = {
            status: "Error",
            error: e.message,
        };

        await sp.web.lists.getById(this.props.listId).items.getById(this.props.listItemId).update({
            "TeamApproval": jsonToEscapedString(errorFieldValue),
        });

        this.props.onCellChanged(errorFieldValue);
    }
}

export class InProgressCell extends CellBase {

    @override
    public render(): React.ReactElement<{}> {
        return (<ReactProgress />);
    }
}

