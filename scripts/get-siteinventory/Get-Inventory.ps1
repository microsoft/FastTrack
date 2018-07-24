[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$Url,
        
    [Parameter(Mandatory = $false)]
    [Switch]$ProcessSubWebs = $false,
    
    [Parameter(Mandatory = $false)]
    [String]$TempFolder = (Join-Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) "temp"),
    
    [Parameter(Mandatory = $false)]
    [String]$OutputFolder = (Join-Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) "output"),
    
    [Parameter(Mandatory = $false)]
    [Int32]$PoolSize = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors,
    
    [Parameter(Mandatory = $false)]
    [Switch]$NoWorkbook = $false,
    
    [Parameter(Mandatory = $false)]
    [Switch]$NoQuery = $false,

    [Parameter(Mandatory = $false)]
    $Timeout = -1,

    [Parameter(Mandatory = $false)]
    [Switch]$DeleteTemp = $false
)
    
begin {
    
    # Get our library methods
    Import-Module .\Lib

    # clear display and let the user know we have started
    Clear-Host
    Write-Host "Running FastTrack site inventory"
        
    # always ensure we have the output folder and it is empty
    Reset-DirectoryToNew -Path $OutputFolder
    
    if ($NoQuery) {
        Write-Host "No Query flag supplied, generating workbook from existing reports in $($TempFolder)"
    }
    else {
    
        Import-ModuleWithInstall -Name "SharePointPnPPowerShellOnline"
    
        # ensure we have the temp folder and it is empty
        Reset-DirectoryToNew -Path $TempFolder
    
        $pool = New-RunspacePool -PoolSize $PoolSize
    
        # read in our script to run for each web
        $scriptBlock = [scriptblock]::Create( $(Get-Content "Get-WebInventory.ps1" | out-string) )
    
        # establish the connection to spo
        $connection = Connect-PnPOnline -Url $Url -UseWebLogin -ReturnConnection -Verbose:$false
    
        # grab the target web
        $web = Get-PnPWeb
    }
    
    $websCsvPath = Join-Path $TempFolder "webs.csv"
    $alertsCsvPath = Join-Path $TempFolder "alerts.csv"
    $listsCSVPath = Join-Path $TempFolder "lists.csv"
    $workflowsCSVPath = Join-Path $TempFolder "workflows.csv"
    $success = $true
}
    
process {
    
    if (-not $NoQuery) {
    
        $shells = @()
        $jobs = @()
        $handles = @()
        $webs = @()
        $webs += $web | Select-Object "ServerRelativeUrl", "Id"
    
        if ($ProcessSubWebs) {
            # collect all the sub-web urls
            $webs += Get-PnPSubWebs -Connection $connection -Recurse | Select-Object "ServerRelativeUrl", "Id"
        }
    
        for ($i = 0; $i -lt $webs.length; $i++) {  
            Write-Verbose "Added web $($webs[$i].ServerRelativeUrl) to the processing queue."
        }
    
        # output a reference csv of the webs
        $webs | Select-Object "Id", "ServerRelativeUrl" | Export-Csv -Path $websCsvPath -Delimiter "," -NoTypeInformation
    
        # get the alerts for all users            
        Get-PnPUser -WithRightsAssigned -Web $web -Connection $connection `
            | Select-Object "Id", "LoginName", "Email", @{Name = "AlertCount"; Expression = {$_.Alerts.Count}} `
            | Where-Object { $_.AlertCount -gt 0 } `
            | Export-Csv -Path $alertsCsvPath -Delimiter "," -NoTypeInformation
    
        # setup and queue each web for processing
        for ($i = 0; $i -lt $webs.length; $i++) {  
    
            $subConn = Connect-PnPOnline -Url $Url -UseWebLogin -ReturnConnection -Verbose:$false
            $shell = [powershell]::Create().AddScript($scriptBlock).AddParameter("connection", $subConn).AddParameter("tempFolder", $TempFolder).AddParameter("webUrl", $webs[$i].ServerRelativeUrl)
            $shell.runspacepool = $pool        
    
            # record a ref to the shell
            $shells += $shell
    
            # start the job
            $job = $shell.BeginInvoke()
    
            # track the job and wait handle for the job
            $jobs += $job
            $handles += $job.AsyncWaitHandle
        }
    
        # wait for processing to end and see if all the tasks completed in the specified timeout
        $success = [System.Threading.WaitHandle]::WaitAll($handles, $Timeout)
    
        Write-Host "All background tasks have finished, checking results."
    
        # get our results from each task
        for ($i = 0; $i -lt $webs.length; $i++) { 
         
            try {
    
                # get the result of the sub-process, this will have details on the csv files to gather if success
                # or an error if the process failed
                # $result = $shells[$i].EndInvoke($jobs[$i])
                $shells[$i].EndInvoke($jobs[$i])

                $info = $shells[$i].InvocationStateInfo
    
                if ($info.state -eq [System.Management.Automation.PSInvocationState]::Completed) {
    
                    Write-Host "Successfully processed web $($webs[$i].ServerRelativeUrl)." -ForegroundColor Green
                }
                else {
                    Write-Error "Error in process for web $($webs[$i].ServerRelativeUrl) => $($info.reason)."
                }
            }
            catch {
                # ensure we don't continue if any of the sub-tasks failed
                $success = $false
                Format-SubTaskError -WebUrl $webs[$i].ServerRelativeUrl -Err $_                
            }
            finally {
                $shells[$i].Dispose() 
            }
        }        
    }

    if ($success) {
        Write-Host "Finished Processing webs, gathering temp files into report" -ForegroundColor Cyan
    }
    else {

        Write-Host "There were errors processing the sub-tasks, ending inventory. Please review individual sub-task errors for more details." -ForegroundColor Yellow
        Write-Output $success
        return;
    }
    
    # we need to aggregate the various individual sheets into the ones we will import    
    Join-TempCSV -SearchFolderMask (Join-Path $TempFolder "*_lists.csv")  -OutFilePath $listsCSVPath    
    Join-TempCSV -SearchFolderMask (Join-Path $TempFolder "*_workflows.csv")  -OutFilePath $workflowsCSVPath 
       
    if (-not $NoWorkbook) {
    
        # create an in-memory workbook
        $excel = New-Object -ComObject excel.application 
        $workbook = $excel.Workbooks.Add(1)
    
        # add index of webs processed to first sheet
        Add-Worksheet -Workbook $workbook -SheetName "Webs" -InputFilePath $websCsvPath -Worksheet ($workbook.worksheets.Item(1))
    
        # add alerts
        Add-Worksheet -Workbook $workbook -SheetName "Alerts" -InputFilePath $alertsCsvPath
    
        # add lists
        Add-Worksheet -Workbook $workbook -SheetName "Lists" -InputFilePath $listsCSVPath
    
        # add workflows
        Add-Worksheet -Workbook $workbook -SheetName "Workflows" -InputFilePath $workflowsCSVPath
    
        # save the workbook to the output folder
        $outputWorkbookPath = Join-Path $OutputFolder "inventory.xlsx"
        $workbook.SaveAs($outputWorkbookPath, 51)| Out-Null
        $excel.Quit()
    }
}
    
end {
    if ($pool -ne $null) {
        $pool.Dispose()
    }

    if ($DeleteTemp) {
        Remove-Item $TempFolder -Force -Recurse
    }

    if ($success) {
        if ($NoWorkbook) {
            Write-Host "Done. Output available in temp folder $($TempFolder)"
        }
        else {
            Write-Host "Done. Inventory workbook available at: $($outputWorkbookPath)"
        }  
    }
    else {

        Write-Host  "Done with errors"
    }

    Write-Output $success
}
