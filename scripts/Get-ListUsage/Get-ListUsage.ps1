[CmdletBinding()]
param(
    [Parameter(Mandatory = $true,
        HelpMessage = "Please supply a valid SPList",
        ValueFromPipeline = $true)]
    $list,
    [Parameter(Mandatory = $false,
        HelpMessage = "Number of months to gather (default: 6)")]
    $months = 6,
    [Parameter(Mandatory = $false,
        HelpMessage = "CAML query used to select the items to process")]
    $query = "<View Scope='RecursiveAll'><ViewFields><FieldRef Name='ID'/><FieldRef Name='FileLeafRef'/></ViewFields><Query></Query><RowLimit>20</RowLimit></View>"
)

begin {
    
    # load the stuff we need
    # [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
    # [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
    # [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Search.Applications") | Out-Null

    # can use this method if there are version incompatibilities
    Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.10.1906.0\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.10.1906.0\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.10.1906.0\Microsoft.SharePoint.Client.Search.Applications.dll"

    $monthDates = @()

    if ($months -lt 1) {
        $months = 1
    }

    if ($months -gt 12) {
        $months = 12
    }

    # used to order the results
    $names = @("Id", "Title", "LastProcessingTime", "TotalHits", "TotalUniqueUsers")
    $defaultNames = 5

    $date = Get-Date

    for ($i = 0; $i -lt $months; $i++) {
        $monthDates += $date.AddMonths(($i * -1))
    }

    for ($i = 0; $i -lt $monthDates.length; $i++) {
        $name = "UniqueUsers-{0}-{1}" -f $monthDates[$i].Year, $monthDates[$i].Month
        $names += $name
    }

    for ($i = 0; $i -lt $monthDates.length; $i++) {
        $name = "HitCount-{0}-{1}" -f $monthDates[$i].Year, $monthDates[$i].Month
        $names += $name
    }
}

process {
    
    $ctx = Get-PnPContext
    $usage = New-Object -TypeName Microsoft.SharePoint.Client.Search.Analytics.UsageAnalytics -ArgumentList $ctx, $ctx.Site

    Get-PnPListItem $list -Query $query | ForEach-Object { 

        $data = $usage.GetAnalyticsItemData(1, $_)
        $ctx.Load($data)
        $ctx.ExecuteQueryRetry();

        if ($data.ServerObjectIsNull) {
            return
        }

        $uniqueUsersMonth = $monthDates | ForEach-Object { $data.GetUniqueUsersCountForMonth($_) }

        # execute to get unique users for month
        $ctx.ExecuteQueryRetry()

        $hitCountMonth = $monthDates | ForEach-Object { $data.GetHitCountForMonth($_) }

        # execute to get hit count for month
        $ctx.ExecuteQueryRetry()

        # create our item summary hash
        $itemSummary = @{
            Id                 = $_["ID"]
            Title              = $_["FileLeafRef"]
            LastProcessingTime = $data.LastProcessingTime
            TotalHits          = $data.TotalHits
            TotalUniqueUsers   = $data.TotalUniqueUsers
        }

        # add in the unique users data
        for ($i = 0; $i -lt $monthDates.length; $i++) {
            $name = $names[$i + $defaultNames]
            $itemSummary.Add($name, $uniqueUsersMonth[$i].Value)
        }

        # add in the hit count data
        for ($i = 0; $i -lt $monthDates.length; $i++) {
            $name = $names[$i + $defaultNames + $monthDates.length]
            $itemSummary.Add($name, $hitCountMonth[$i].Value)
        }

        New-Object PSObject -Property $itemSummary

    } | Select-Object $names
} 

end {
    # $ctx.Dispose()
}