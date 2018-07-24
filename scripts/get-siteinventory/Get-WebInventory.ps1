
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$webUrl,
    
    [Parameter(Mandatory = $true)]
    [SharePointPnP.PowerShell.Commands.Base.SPOnlineConnection]$connection,

    [Parameter(Mandatory = $true)]
    [String]$tempFolder
)


$web = Get-PnPWeb -Identity $webUrl -Connection $connection

# get a listing of all the lists
$listProperties = @(
    "Title",
    "Created",
    "LastItemModifiedDate",
    "LastItemUserModifiedDate",
    "ItemCount",
    "BaseType",
    "DefaultViewUrl"
)
$listsCsvFile = Join-Path $tempFolder "web_$($web.Id)_lists.csv"
$listWorkflowsCsvFile = Join-Path $tempFolder "web_$($web.Id)_workflows.csv"

Get-PnPList -Web $web -Connection $connection -Includes "WorkflowAssociations" `
    | ForEach-Object {

    # report list details
    $_ `
        | Select-Object $listProperties `
        | Add-Member @{WebUrl = $web.Url} -PassThru `
        | Export-Csv -Path $listsCsvFile -Delimiter "," -NoTypeInformation -Append
    
    # report any workflow details
    $_ `
        | Select-Object "Title" -ExpandProperty "WorkflowAssociations" `
        | Where-Object { $_.Name -notlike "*(Previous Version:*" } `
        | Add-Member @{WebUrl = $web.Url} -PassThru `
        | Select-Object "Title", "WebUrl", "Id", "Name", "Description", "Created", "Enabled", "IsDeclarative", "ListId", "Modified", "TaskListTitle", "HistoryListTitle" `
        | Export-Csv -Path $listWorkflowsCsvFile -Delimiter "," -NoTypeInformation -Append
}
