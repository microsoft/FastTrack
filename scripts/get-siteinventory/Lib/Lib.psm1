function Join-TempCSV {

    param (
        [Parameter(Mandatory = $true)]
        [String]$SearchFolderMask,

        [Parameter(Mandatory = $true)]
        [String]$OutFilePath
    )

    begin {
        $getFirstLine = $true    
    }

    process {
        
        Get-ChildItem $SearchFolderMask | ForEach-Object {

            $lines = Get-Content $_ 

            if ($lines.length -gt 0) {

                $linesToWrite = switch ($getFirstLine) {
                    $true {$lines}
                    $false {$lines | Select-Object -Skip 1}
                }
    
                $getFirstLine = $false
                Add-Content $OutFilePath $linesToWrite
            }           
        }
    }
}

function Add-Worksheet {

    param (
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(Mandatory = $true)]
        [String]$SheetName,

        [Parameter(Mandatory = $true)]
        [String]$InputFilePath,

        [Parameter(Mandatory = $false)]
        $Worksheet = $null
    )

    begin {
        if ($Worksheet -eq $null) {
            $ws = $workbook.worksheets.add()
        }
        else {
            $ws = $Worksheet
        }
    }

    process {

        $ws.Name = $SheetName
        
        if ([System.IO.File]::Exists($InputFilePath)) {

            $cellRef = $ws.Range("A1")
            $txtConnector = ("TEXT;" + $InputFilePath)
            $connector = $ws.QueryTables.add($txtConnector, $cellRef)
            $ws.QueryTables.item($connector.name).TextFileCommaDelimiter = $True
            $ws.QueryTables.item($connector.name).TextFileParseType = 1
            $ws.QueryTables.item($connector.name).Refresh() | Out-Null
            $ws.QueryTables.item($connector.name).Delete() | Out-Null
            $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
        }
    }
}

function Import-ModuleWithInstall {

    param (
        [Parameter(Mandatory = $true)]
        $Name
    )

    process {
        try {
            Import-Module -DisableNameChecking $Name -Verbose:$false
        }
        catch {

            Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module $Name -Force -AllowClobber;" -Wait
            Import-Module -DisableNameChecking $Name -Verbose:$false
        }
    }
}

function Reset-DirectoryToNew {
    
    param (
        [Parameter(Mandatory = $true)]
        $Path
    ) 

    process {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
        Get-ChildItem -Path $Path -Include *.* -File -Recurse | ForEach-Object { $_.Delete()}
    }
}

function New-RunspacePool {

    param (
        [Parameter(Mandatory = $true)]
        [Int32]$PoolSize
    ) 

    process {
        # setup session state
        $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    
        # setup runspace pool
        $pool = [runspacefactory]::CreateRunspacePool(1, $PoolSize, $sessionstate, $Host)  
        $pool.ApartmentState = "STA"
        $pool.Open()

        Write-Output $pool
    }
}

function Format-SubTaskError {
    param (
        [Parameter(Mandatory = $true)]
        [String]$WebUrl,

        [Parameter(Mandatory = $true)]
        $Err
    ) 

    process {
        Write-Host "`r`n------ Begin: $($WebUrl)" -ForegroundColor Gray
        Write-Host "Error in sub-task for web $($WebUrl)." -ForegroundColor Yellow
        Write-Host $Err -ForegroundColor Red
        Write-Host "------ End: $($WebUrl)" -ForegroundColor Gray
    }
}



