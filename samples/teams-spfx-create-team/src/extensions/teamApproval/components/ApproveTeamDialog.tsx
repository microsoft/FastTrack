import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { BaseDialog, IDialogConfiguration } from '@microsoft/sp-dialog';
import {
    autobind,
    DatePicker,
    PrimaryButton,
    DefaultButton,
    TextField,
    Label,
    Dropdown,
    DropdownMenuItemType,
    IDropdownOption,
    DialogFooter,
    DialogContent
} from 'office-ui-fabric-react';

import { Dialog } from '@microsoft/sp-dialog';

import { stringIsNullOrEmpty } from "@pnp/common";

import styles from './TeamApproval.module.scss';

interface IApproveTeamDialogProps {
    teamName: string;
    teamDescription: string;
    cancel: () => void;
    approve: (teamName: string, teamDescription: string) => void;
}

interface IApproveTeamDialogState {
    teamName: string;
    teamDescription: string;
}

class ApproveTeamContent extends
    React.Component<IApproveTeamDialogProps, IApproveTeamDialogState> {

    constructor(props) {
        super(props);

        this.state = {
            teamName: this.props.teamName,
            teamDescription: this.props.teamDescription,
        };
    }

    public render(): JSX.Element {
        return (<DialogContent
            title="Approve Team"
            subText="Please review team settings"
            onDismiss={this.props.cancel}
            showCloseButton={true}>
            <div className={styles.TeamApprovalDialog}>
                <div className="ms-Grid">
                    <div className="ms-Grid-row">
                        <div className="ms-Grid-col ms-u-sm12 ms-u-md12 ms-u-lg12">
                            <TextField
                                label="Team Name"
                                required={true}
                                value={this.state.teamName}
                                onChanged={this._onChangedName}
                                onGetErrorMessage={this._getErrorMessageRequired}
                                validateOnFocusOut={true}
                            />
                        </div>
                    </div>
                    <div className="ms-Grid-row">
                        <div className="ms-Grid-col ms-u-sm12 ms-u-md12 ms-u-lg12">
                            <TextField
                                label="Team Description"
                                required={true}
                                value={this.state.teamDescription}
                                onChanged={this._onChangedDescription}
                                onGetErrorMessage={this._getErrorMessageRequired}
                                validateOnFocusOut={true}
                            />
                        </div>
                    </div>
                </div>

                <DialogFooter>
                    <DefaultButton text='Cancel' title='Cancel' onClick={this.props.cancel} />
                    <PrimaryButton text='Approve' title='Approve' onClick={() => { this.props.approve(this.state.teamName, this.state.teamDescription); }} />
                </DialogFooter>
            </div>
        </DialogContent>);
    }

    @autobind
    private _onChangedName(value: string): void {
        this.setState({
            teamName: value,
        });
    }

    private _getErrorMessageRequired(value: string): string {
        return (value === null || value.length === 0)
            ? "Required"
            : "";
    }

    @autobind
    private _onChangedDescription(value: string): void {
        this.setState({
            teamDescription: value,
        });
    }
}

export class ApproveTeamDialog extends BaseDialog {
    public teamName: string;
    public teamDescription: string;
    public approve: (name: string, description: string) => void;

    public render(): void {
        ReactDOM.render(<ApproveTeamContent
            teamName={this.teamName}
            teamDescription={this.teamDescription}
            cancel={this.close}
            approve={this._submit} />, this.domElement);
    }

    @autobind
    private _submit(name: string, description: string): void {

        if (stringIsNullOrEmpty(name) || stringIsNullOrEmpty(description)) {
            return;
        }

        this.approve(name, description);
        this.close();
    }
}