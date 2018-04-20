export interface IFieldValue {
    status: "None" | "Pass" | "Warn" | "Blocked" | "InProgress" | "Error";
    message?: string;
}

export interface ITeamPrecheckProps {
    listId: string;
    listItemId: number;
    fieldValue: IFieldValue;
    teamName: string;
}

export interface ITeamPrecheckState {
    status: "None" | "Pass" | "Warn" | "Blocked" | "InProgress" | "Error";
    message: string;
}