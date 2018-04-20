import { Log } from "@microsoft/sp-core-library";
import { override } from "@microsoft/decorators";
import * as React from "react";

import {
    Link as ReactLink,
    Button as ReactButton,
} from "office-ui-fabric-react";

import styles from "./TeamApproval.module.scss";
import { ICellContainerProps, ICellProps, ICellState, IFieldValue } from "../interfaces";
import { sp } from "@pnp/sp";
import { extend } from "@pnp/common";

import {
    PendingCell,
    DeniedCell,
    ApprovedCell,
    ErrorCell,
    InProgressCell,
    UnknownCell,
} from "./cells";

const LOG_SOURCE: string = "TeamApproval";

export class CellContainer extends React.Component<ICellContainerProps, ICellState> {

    constructor(props: ICellProps, state: ICellState) {
        super(props, state);

        this.state = {
            fieldValue: props.fieldValue,
        };
    }

    @override
    public render(): React.ReactElement<{}> {

        let element: any | undefined;

        const cellProps: ICellProps = extend({
            onCellChanged: this.onCellChanged.bind(this),
            fieldValue: this.state.fieldValue,
        }, this.props);

        switch (this.state.fieldValue.status) {
            case "Approved":
                element = React.createElement(ApprovedCell, cellProps);
                break;
            case "Denied":
                element = React.createElement(DeniedCell, cellProps);
                break;
            case "Error":
                element = React.createElement(ErrorCell, cellProps);
                break;
            case "Pending":
                element = React.createElement(PendingCell, cellProps);
                break;
            case "InProgress":
                element = React.createElement(InProgressCell, cellProps);
                break;
            default:
                element = React.createElement(UnknownCell, cellProps);

                break;
        }

        return (
            <div className={styles.cell}>
                {element}
            </div>
        );
    }

    private onCellChanged(value: IFieldValue): void {
        this.setState({
            fieldValue: value,
        });
    }
}