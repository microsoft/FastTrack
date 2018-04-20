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

interface IDenyTeamDialogProps {
    cancel: () => void;
    deny: (reason: string) => void;
}

interface IDenyTeamDialogState {
    reason: string;
}

class DenyTeamContent extends
    React.Component<IDenyTeamDialogProps, IDenyTeamDialogState> {

    constructor(props) {
        super(props);

        this.state = {
            reason: "",
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
                                label="Reason"
                                title="Why is this team request being denied?"
                                multiline={true}
                                required={true}
                                value={this.state.reason}
                                onChanged={this._onChangedReason}
                                onGetErrorMessage={this._getErrorMessageRequired}
                            />
                        </div>
                    </div>
                </div>

                <DialogFooter>
                    <DefaultButton text='Cancel' title='Cancel' onClick={this.props.cancel} />
                    <PrimaryButton text='Deny' title='Deny' onClick={() => { this.props.deny(this.state.reason); }} />
                </DialogFooter>
            </div>
        </DialogContent>);
    }

    @autobind
    private _onChangedReason(value: string): void {
        this.setState({
            reason: value,
        });
    }

    private _getErrorMessageRequired(value: string): string {
        return (value === null || value.length === 0)
            ? "Required"
            : "";
    }
}

export class DenyTeamDialog extends BaseDialog {

    public deny: (reason: string) => void;

    public render(): void {

        ReactDOM.render(<DenyTeamContent
            cancel={this.close}
            deny={this._submit} />, this.domElement);
    }

    @autobind
    private _submit(reason: string): void {

        if (stringIsNullOrEmpty(reason)) {
            return;
        }

        this.deny(reason);
        this.close();
    }
}