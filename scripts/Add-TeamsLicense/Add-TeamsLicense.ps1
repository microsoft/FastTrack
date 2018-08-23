<#       
    .DESCRIPTION
        Add Teams License Only (keep existing license configuration).   

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

        Requirements: 
            MSOnline module : https://docs.microsoft.com/en-us/office365/enterprise/powershell/connect-to-office-365-powershell

    .PARAMETER AccountSkuId
            E1 = CONTOSO:STANDARDPACK 
            E3 = CONTOSO:ENTERPRISEPACK 
            E4 = CONTOSO:ENTERPRISEWITHSCAL
            E5 = CONTOSO:ENTERPRISEPREMIUM
	.PARAMETER ImportCSVFile
        Script will add licenses to the users in the CSV file. "UserPrincipalName" needs to be the column header. 
    .EXAMPLE
        .\Add-TeamsLicense.ps1 -AccountSkuId "CONTOSO:ENTERPRISEPREMIUM" -ImportCSVFile "c:\userslist.csv"

#>
[Cmdletbinding()]
Param (
    [Parameter(mandatory=$true)][String]$AccountSkuId = "M365x877915:ENTERPRISEPREMIUM",
	[Parameter(mandatory=$true)][String]$ImportCSVFile
)

begin{
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

    $yyyyMMdd = Get-Date -Format 'yyyyMMdd'
    $computer = $env:COMPUTERNAME
    $user = $env:USERNAME
    $version = "1.20180823"
    $log = "$PSScriptRoot\Add-TeamsLicense-$yyyyMMdd.log"
    $DefaultUsageLocation = "US"

    $users = import-csv $ImportCSVFile -delimiter ","
    $NumOfUsers = $users.Count

    Write-LogEntry -LogName:$Log -LogEntryText "User: $user Computer: $computer Version: $version" -foregroundcolor Yellow
}
process{
    $i=0
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    ForEach ($user in $users){
        try{
            $User = Get-MsolUser -UserPrincipalName $user.UserPrincipalName
            if (!$User.UsageLocation){
                Set-MsolUser -UserPrincipalName $UPN -UsageLocation $DefaultUsageLocation
            }
            $License = $User.Licenses | where {$_.AccountSkuId -eq $AccountSkuId}
            $DisabledOptions = @()
            Foreach($serviceStatus in $License.ServiceStatus){
                If (($serviceStatus.ProvisioningStatus -eq "Disabled" ) -and(-not($serviceStatus.ServicePlan.ServiceName -like "*TEAMS*"))) {
                    $DisabledOptions += "$($serviceStatus.ServicePlan.ServiceName)" 
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $AccountSkuId -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -LicenseOptions $LicenseOptions
        }
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "ERROR: $($user.UserPrincipalName) :  $_" -foregroundcolor Red
        }
        
        $i++
        if ($sw.Elapsed.TotalMilliseconds -ge 500) {
            Write-Progress -Activity "Add Teams License" -Status "Done $i out of $NumOfUsers"
            $sw.Reset(); $sw.Start()
        }
    }
}
end{
    Write-LogEntry -LogName:$Log -LogEntryText "Total Elapsed Time: $($elapsed.Elapsed.ToString()). " -foregroundcolor White
    Write-LogEntry -LogName:$Log -LogEntryText "Total Users Processed: $NumOfUsers. " -foregroundcolor White
    Write-LogEntry -LogName:$Log -LogEntryText "Average Time Per User: $($sw.Elapsed.TotalSeconds / $NumOfUsers)s." -foregroundcolor White
}





