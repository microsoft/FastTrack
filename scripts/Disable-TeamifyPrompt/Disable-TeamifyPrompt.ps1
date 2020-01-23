<#       
    .DESCRIPTION
        Disable the teamify prompt that comes up in modern, group-connected SPO sites. 
        Builds on the Trevor Seward's script here: https://thesharepointfarm.com/2019/04/disable-teams-creation-prompt-in-spo/

        The sample scripts are not supported under any Microsoft standard support 
        program or service. The sample scripts are provided AS IS without warranty  
        of any kind. Microsoft further disclaims all implied warranties including,  
        without limitation, any implied warranties of merchantability or of fitness for 
        a particular purpose. The entire risk arising out of the use or performance of  
        the sample scripts and documentation remains with you. In no event shall 
        Microsoft, its authors, or anyone else involved in the creation, production, or 
        delivery of the scripts be liable for any damages whatsoever (including, 
        without limitation, damages for loss of business profits, business interruption, 
        loss of business information, or other pecuniary loss) arising out of the use 
        of or inability to use the sample scripts or documentation, even if Microsoft 
        has been advised of the possibility of such damages.

        Author: Alejandro Lopez - alejanl@microsoft.com
        Version:
            1.20200122

        Requirements: 
            -SharePoint PNP Online: https://docs.microsoft.com/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps

    .PARAMETER Tenant
        Tenant URL     
    .PARAMETER ImportCSVFile
        This is optional. You can use this if you want to run the report against a subset of sites. If empty, it'll run against all sites in the tenant. 
        The CSV file needs to have "URL" as the column header. 
    .PARAMETER EnableCustomScript
    Include this if you want to Enable Custom Scripting (DenyAndAddCustomizePages = $false). Otherwise, the script will skip sites where scripting is disabled. 
    Please review the following considerations when enabling scripting: https://docs.microsoft.com/sharepoint/allow-or-prevent-custom-script
    
    .EXAMPLE
    .\Disable-TeamifyPrompt.ps1 -Tenant "https://tenant-admin.sharepoint.com" -ImportCSVFile "c:\SitesList.csv"

#>
param(
    [Parameter(mandatory=$true)][string]$Tenant, #"https://tenant-admin.sharepoint.com"
    [String]$ImportCSVFile,
    [switch]$EnableCustomScript
)

Begin{
    #Functions: 
    Function Write-LogEntry {
        param(
            [string] $LogName ,
            [string] $LogEntryText,
            [string] $ForegroundColor
        )
        if ($LogName -NotLike $Null) {
            # log the date and time in the text file along with the data passed
            "$([DateTime]::Now.ToShortDateString()) $([DateTime]::Now.ToShortTimeString()) : $LogEntryText" | Out-File -FilePath $LogName -append;
            if ($ForeGroundColor -NotLike $null) {
                # for testing i pass the ForegroundColor parameter to act as a switch to also write to the shell console
                write-host $LogEntryText -ForegroundColor $ForeGroundColor
            }
        }
    }

    Try{
        $yyyyMMdd = Get-Date -Format 'yyyyMMdd'
        $computer = $env:COMPUTERNAME
        $user = $env:USERNAME
        $version = "1.20191101"
        $Log = "$PSScriptRoot\Disable-TeamifyPrompt-$yyyyMMdd.log"

        Write-LogEntry -LogName:$Log -LogEntryText "User: $user Computer: $computer Version: $version" -foregroundcolor Yellow

        Connect-PnPOnline -Url $tenant -SPOManagementShell -cleartokencache

        If($ImportCSVFile){
            $Sites = import-csv $ImportCSVFile -delimiter ","
        }
        Else{
            $Sites = Get-PnPTenantSite
        }
        $NumOfSites = $Sites.Count
    }
    catch{
        Write-LogEntry -LogName:$Log -LogEntryText "Pre-flight failed: $_" -foregroundcolor Red
    }
}
Process{
    try{
        $i=0
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        Foreach($SiteURL in $Sites){
            $site = Get-PnPTenantSite -Detailed -Url $SiteURL.URL

            If($EnableCustomScript){
                if ($site.DenyAddAndCustomizePages -ne 'Disabled') {
                    $site.DenyAddAndCustomizePages = 'Disabled'
                    $site.Update()
                    $site.Context.ExecuteQuery()
                }
                Connect-PnPOnline -Url $site -SPOManagementShell 
                Set-PnPPropertyBagValue -Key 'TeamifyHidden' -Value 'True'  
            }
            Else{
                if ($site.DenyAddAndCustomizePages -eq 'Disabled'){
                    Connect-PnPOnline -Url $site -SPOManagementShell
                    Set-PnPPropertyBagValue -Key 'TeamifyHidden' -Value 'True'
                }
            }
            
            $i++
            if ($sw.Elapsed.TotalMilliseconds -ge 500) {
                Write-Progress -Activity "Disable Teamify Prompt" -Status "Done $i out of $NumOfSites"
                $sw.Reset(); $sw.Start()
            }
        }
    }
    catch{
        Write-LogEntry -LogName:$Log -LogEntryText "Error with: $_" -foregroundcolor Red
    }
}
End{
    Write-LogEntry -LogName:$Log -LogEntryText "Total Elapsed Time: $($elapsed.Elapsed.ToString()). " -foregroundcolor White
    Write-LogEntry -LogName:$Log -LogEntryText "Total Users Processed: $NumOfSites. " -foregroundcolor White
    Write-LogEntry -LogName:$Log -LogEntryText "Average Time Per Site: $($elapsed.Elapsed.Seconds / $NumOfSites)s." -foregroundcolor White
    Write-LogEntry -LogName:$Log -LogEntryText "Log: $log" -foregroundcolor Green
    ""
}
