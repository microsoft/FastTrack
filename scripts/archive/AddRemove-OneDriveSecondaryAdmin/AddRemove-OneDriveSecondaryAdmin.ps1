<#       
    .DESCRIPTION
        Script to add/remove secondary admins (user or group) to ODB sites. 

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
            SharePoint Online Management Shell : https://www.microsoft.com/en-us/download/details.aspx?id=35588
            SharePoint PNP: https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets?view=sharepoint-ps 
#>

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

Function EnsureLoginName($userOrGroupName) {
    $web = Get-PnPWeb
    $userOrGroup = $web.EnsureUser($userOrGroupName)
    $web.Context.Load($userOrGroup)
    $web.Context.ExecuteQuery()
    Return $userOrGroup.LoginName
}

Function Add-OnedriveSecondaryAdmin{
    Param ( 
            [Parameter(Mandatory=$True)] 
            [string]$SecondaryAdmin
    )

    $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
    $count = $OneDriveURLs.Count
    $i = 0
    foreach($OneDriveURL in $OneDriveURLs){
        $i++
        if (($i % $Batch) -eq 0) {
            Write-Progress -Activity "Adding secondary admin" -Status "Processed $i of $count " -PercentComplete ($i/$count*100)
        }
        try{
            Set-SPOUser -Site $OneDriveURL.URL -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue | Out-Null
            Write-LogEntry -LogName:$Log -LogEntryText "Added $SecondaryAdmin secondary admin to the site $($OneDriveURL.URL)"  
        }
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "Error: Adding $SecondaryAdmin secondary admin to the site $($OneDriveURL.URL): $_"  -foregroundcolor Yellow
        }
    }
}

Function Remove-OnedriveSecondaryAdmin{
    Param ( 
            [Parameter(Mandatory=$True)] 
            [string]$SecondaryAdmin
    )
    $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
    $count = $OneDriveURLs.Count
    $i = 0
    foreach($OneDriveURL in $OneDriveURLs){
        $i++
        if (($i % $Batch) -eq 0) {
            Write-Progress -Activity "Removing secondary admin" -Status "Processed $i of $count " -PercentComplete ($i/$count*100)
        }
        try{
            Set-SPOUser -Site $OneDriveURL.URL -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $false -ErrorAction SilentlyContinue | Out-Null
            Write-LogEntry -LogName:$Log -LogEntryText "Removed $SecondaryAdmin secondary admin to the site $($OneDriveURL.URL)"  
        }
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "Error: Removing $SecondaryAdmin secondary admin to the site $($OneDriveURL.URL): $_"  -foregroundcolor Yellow 
        }
        
    }
}

Function Add-OnedriveSecondaryAdminGroup{
    Param ( 
            [Parameter(Mandatory=$True)] 
            [string]$GroupUPN
    )
    $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
    $loginName = EnsureLoginName $GroupUPN
    If(!$loginName){
        Throw 
    }
    $count = $OneDriveURLs.Count
    $i = 0
    #Add Group to OneDrive for Business sites
    foreach($OneDriveURL in $OneDriveURLs){
        $i++
        if (($i % $Batch) -eq 0) {
            Write-Progress -Activity "Adding Group as secondary admin" -Status "Processed $i of $count " -PercentComplete ($i/$count*100)
        }
        try{
            Set-SPOUser -Site $OneDriveURL.URL -LoginName $loginName -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue | Out-Null
            Write-LogEntry -LogName:$Log -LogEntryText "Added $GroupUPN as secondary admin to the site $($OneDriveURL.URL)" 
        }
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "Error: Adding $GroupUPN as secondary admin to the site $($OneDriveURL.URL): $_" -foregroundcolor Yellow
        }
    }
}

Function Remove-OnedriveSecondaryAdminGroup{
    Param ( 
            [Parameter(Mandatory=$True)] 
            [string]$GroupUPN
    )
    $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
    $loginName = EnsureLoginName $GroupUPN
    If(!$loginName){
        Throw 
    }
    $count = $OneDriveURLs.Count
    $i = 0
    #Remove Group from OneDrive for Business sites
    foreach($OneDriveURL in $OneDriveURLs){
        $i++
        if (($i % $Batch) -eq 0) {
            Write-Progress -Activity "Removing Group as secondary admin" -Status "Processed $i of $count " -PercentComplete ($i/$count*100)
        }
        try{
            Set-SPOUser -Site $OneDriveURL.URL -LoginName $loginName -IsSiteCollectionAdmin $false -ErrorAction SilentlyContinue | Out-Null
            Write-LogEntry -LogName:$Log -LogEntryText "Removed $GroupUPN as secondary admin to the site $($OneDriveURL.URL)" 
        }
        catch{
            Write-LogEntry -LogName:$Log -LogEntryText "Error: Removing $GroupUPN as secondary admin to the site $($OneDriveURL.URL): $_" -foregroundcolor Yellow
        }
    }
}

Function Run-Preflight{
    $gotError = $false
    #SPO
    try{$testSPO = get-spotenant -erroraction silentlycontinue   }
    catch{}
    If($testSPO -ne $null){
        Write-LogEntry -LogName:$Log -LogEntryText "Connected to SharePoint Online" -ForegroundColor Green
    }
    Else{
        Write-LogEntry -LogName:$Log -LogEntryText "Please connect to SPO using: Connect-SPOService -Url https://contoso-admin.sharepoint.com " -ForegroundColor Red
        $gotError = $true
    }

    #PNP
    try{$testPNP = Get-PnPSite}
    catch{}
    If($testPNP -ne $null){
        Write-LogEntry -LogName:$Log -LogEntryText "Connected to PNP Online" -ForegroundColor Green
    }
    Else{
        Write-LogEntry -LogName:$Log -LogEntryText "Please connect to PNP using: Connect-PNPOnline -Url https://contoso-admin.sharepoint.com -UseWebLogin" -ForegroundColor Red
        $gotError = $true
    }

    If($gotError){
        exit
    }
}


### MAIN ###
$yyyyMMdd = Get-Date -Format 'yyyyMMdd'
$Log = "$PSScriptRoot\AddRemove-OneDriveSecondaryAdmin-$yyyyMMdd.log"
$Batch = 50
Run-Preflight

$Menu = [ordered]@{
    1 = 'Add-OnedriveSecondaryAdmin'
    2 = 'Remove-OnedriveSecondaryAdmin'
    3 = 'Add-OnedriveSecondaryAdminGroup'
    4 = 'Remove-OnedriveSecondaryAdminGroup'
}
  
$Result = $Menu | Out-GridView -PassThru  -Title 'Select which command to run'
    Switch ($Result)  {
    {$Result.Name -eq 1} {Add-OnedriveSecondaryAdmin}
    {$Result.Name -eq 2} {Remove-OnedriveSecondaryAdmin}
    {$Result.Name -eq 3} {Add-OnedriveSecondaryAdminGroup}   
    {$Result.Name -eq 4} {Remove-OnedriveSecondaryAdminGroup}
} 

Write-LogEntry -LogName:$Log -LogEntryText "Script completed. Log location: $Log " -ForegroundColor Green                  