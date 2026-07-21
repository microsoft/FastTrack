[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$Url,

    [Parameter(Mandatory = $true)]
    [String]$ListTitle
)

begin {

    # Get our library methods
    Import-Module .\Lib -Force

    # clear display and let the user know we have started
    Clear-Host
    Write-Host "Running FastTrack Document Libary inventory"

    Import-ModuleWithInstall -Name "SharePointPnPPowerShellOnline"

    # establish the connection to spo
    $connection = Connect-PnPOnline -Url $Url -UseWebLogin -ReturnConnection -Verbose:$false
}

process {

    $totalSize = 0

    Get-PnPListItem -Connection $connection -List $ListTitle -PageSize 1500 | ForEach-Object {
        
        $totalSize = $totalSize + $_["File_x0020_Size"] 
        
        New-Object PSObject -Property @{            
            Id    = $_["ID"]
            Title = $_["FileLeafRef"]
            Size  = $_["File_x0020_Size"]   
            Url   = $_["FileRef"]
        }
    }

    New-Object PSObject -Property @{            
        Id    = ""
        Title = "Total Size"
        Size  = $totalSize    
        Url   = ""
    }   
}

end {}