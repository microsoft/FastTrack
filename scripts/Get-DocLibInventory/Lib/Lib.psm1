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
