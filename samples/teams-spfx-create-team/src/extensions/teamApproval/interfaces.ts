export interface IFieldValue {
  status: "Approved" | "Pending" | "Denied" | "Error" | "InProgress";
  deniedReason?: string;
  groupId?: string;
  error?: string;
  retryPossible?: boolean;
  retryAction?: "Approve" | "Deny";
}

export interface ICellContainerProps {
  listId: string;
  listItemId: number;
  fieldValue: IFieldValue;
  submitterEmail: string;
  teamName: string;
  teamDescription?: string;
}

export interface ICellProps extends ICellContainerProps {
  onCellChanged: (value: IFieldValue) => void;
}

export interface ICellState {
  fieldValue: IFieldValue;
}

