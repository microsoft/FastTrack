#Method to get credentials
$adminCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $adminCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $adminCredential
$error.Clear()

$MyDate = (get-date -uformat "%Y%m%d-%H.%M.%S").ToString()
Write-Host " Date : $MyDate " -ForegroundColor Blue

Write-host "`nPlease select the location of the log file"

$SaveFileDialog = New-Object windows.forms.savefiledialog   
$SaveFileDialog.initialDirectory = [System.IO.Directory]::GetCurrentDirectory()   
$SaveFileDialog.title = "Save File to Disk"   
$SaveFileDialog.filter = "Log Files|*.Log|All Files|*.*" 
$SaveFileDialog.ShowHelp = $True   
$result = $SaveFileDialog.ShowDialog()    
$result 
if ($result -eq "OK") {    
    Write-Host "Selected File and Location:"  -ForegroundColor Green  
    $SaveFileDialog.filename   
} 
else { Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow} 
#$SaveFileDialog.Dispose() 

$MyLogFile = $SaveFileDialog.filename

Add-content –path $MyLogFile "#---------------------------------------------------------- "
Add-content –path $MyLogFile "      Set mailbox forwarding in Office 365       "
Add-content –path $MyLogFile "#---------------------------------------------------------- "
Add-content –path $MyLogFile ""
Add-content –path $MyLogFile "Start date and time $(Get-Date)"

#Import source csv file

Write-Output "`nPlease select csv file with users"

Function Get-FileName($InitialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv) | *.csv"  
    $OpenFileDialog.ShowDialog()| Out-Null
    $OpenFileDialog.FileName    
    Write-Host "Selected File and Location:"  -ForegroundColor Green  $OpenFileDialog.Filename
}

$Path = Get-Filename

Write-Output "`nImporting CSV File"
$users = Import-CsV $Path 

foreach ($user in $users) {
    
    #Set Forwarding SMTP adress in Office 365
    Try {
        If ($user.DeliverToMailboxAndForward -eq "TRUE") {
            Set-Mailbox $user.UPN -ForwardingSmtpAddress $user.ForwardingSMTPAddress -DeliverToMailboxAndForward $true
        }
        else {
            Set-Mailbox $user.UPN -ForwardingSmtpAddress $user.ForwardingSMTPAddress -DeliverToMailboxAndForward $false
        }
        if ($Error.Count -ne 0) {
            $MyDate = (get-date -uformat "%Y%m%d-%H.%M.%S").ToString()
            $MyValueToWrite = "$MyDate - An error was thrown during the set of the forwarding address for :  $($user.UPN)"
            Write-Host "$MyValueToWrite" -ForegroundColor Red
            $Error[0].Exception
            Add-content –path $MyLogFile "$MyValueToWrite"
            Write-Host "Erreur"
            Add-content –path $MyLogFile $Error[0].Exception
            $Error.clear()
        }
        else {
            #Log Informations into the log file
            $MyDate = (get-date -uformat "%Y%m%d-%H.%M.%S").ToString()
            $MyValueToWrite = "$MyDate - The forwarding address has been set for :  $($user.UPN) "
            Write-Host "$MyValueToWrite" -ForegroundColor Green
            Add-content –path $MyLogFile "$MyValueToWrite"
            Write-Host ""
        }
    }
    Catch {
        $MyDate = (get-date -uformat "%Y%m%d-%H.%M.%S").ToString()
        $MyValueToWrite = "$MyDate - An error was thrown during the set of the forwarding address for :  $($user.UPN)"
        Write-Host "$MyValueToWrite" -ForegroundColor Red
        $Error[0].Exception
        Add-content –path $MyLogFile "$MyValueToWrite"
        Write-Host ""
        Add-content –path $MyLogFile $Error[0].Exception
        $Error.clear();
    }
}

Write-Host " Select file and location where to save report : " 

$SaveFileDialog2 = New-Object windows.forms.savefiledialog   
$SaveFileDialog2.initialDirectory = [System.IO.Directory]::GetCurrentDirectory()   
$SaveFileDialog2.title = "Save File to Disk"   
$SaveFileDialog2.filter = "csv (*.csv) | *.csv|All Files|*.*" 
$SaveFileDialog2.ShowHelp = $True   
$result2 = $SaveFileDialog2.ShowDialog()     
if ($result2 -eq "OK") {    
    Write-Host "Selected File and Location:"  -ForegroundColor Green  
    $SaveFileDialog2.filename   
} 
else { Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow} 
#$SaveFileDialog2.Dispose() 


$report = Foreach ($user in $users) { Get-Mailbox $user.UPN }
$report2 = $report | Select-Object UserPrincipalName, PrimarySmtpAddress, ForwardingAddress, ForwardingSMTPAddress, DelivertoMailboxandForward 
$report2 | Export-Csv -Path $SaveFileDialog2.FileName -NoTypeInformation

Write-Host "Report exported!" 
