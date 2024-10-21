<# 

Co-Authors: Laure VAN DER HAUWAERT, 


Script Function:
To check some prerequisites and enable voice with Phone number assigned to users - according to a input file


Input : File with Users to enable with Phone numbers - UPN, E164 phone number, OperatorType (CallingPLan, DirectRouting, OperatorConnect).

Requirements : 
- All the policies have been already created, configured, tested and  in MS Teams Admin Center.
- MicrosoftTeams module is already installed (latest versions)
- For CallingPlan and OperatorConnect, the phone numbers needs to be available in the tenant
- For CallingPlan numbers, make sure Users are assigned with both Teams Phone license & Calling Plan 
- For DirectRouting, the phone number assignment can be done but will only work if the SBC infrastructure has been enabled.
- The locationID must be filled out (preferred than City - especially if multiple locations in the same city e.g. Campus)

Disclaimer:
This script it not supported under any Microsoft standard support program or service.
This script is provided AS IS without any warranty of any kind
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability
or of fitness for a particular purpose.
The entire risk arising out of the use or performance of the script or documentation remains with you.
In no event shall  Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script
be liable for any damages whatsoever (including, without limitation, damages for loss of business profits,
business interruption, loss of business information, or other pecuniary loss) arising out of use of or inability
to use the script or documentation, even if Microsoft has been advised of the possibility of such damages.
#>




#GLOBAL VARIABLES
Write-Host ""
Write-Host "This script assigns to users the phone number and the relative locationID in Teams as part of the phase 2 (Cutover). Values are defined in the CSV file"
Write-Host "Make sure you get the latest versions for MicrosoftTeams module and PowerShell."
Write-Host ""

# Establish Teams remote PowerShell session
Write-Host ""
Write-Host "Connecting to Microsoft Teams AC"
Write-Host ""
$Session = Connect-MicrosoftTeams

#GLOBAL VARIABLES
[String]$date = Get-Date -UFormat "%Y_%m_%d_%H_%M_%S"
$DomainName = (Get-CsTenant).DisplayName
$TargetPath = 'C:\Temp\'+$DomainName+'\Teams-Output-Config'+"\v"+$date+"\"                                                    

$TestPath = test-path -path $TargetPath
if ($TestPath -ne $true) {New-Item -ItemType directory -Path $TargetPath | Out-Null
    $MessagePath = 'Creating directory to write file to '+$TargetPath+'.Your files will be uploaded in this folder'
    write-Host  $MessagePath}
else { $MessagePath = 'Your files will be uploaded to '+$TargetPath }
    
[String]$transcriptFilePath = $TargetPath+"Transcript-TeamsEV-UserProvisioning-Phase2-v$date.txt"
[String]$logFilePath = $TargetPath+"Logs-TeamsEV-UserProvisioning_Phase2-$date.csv"
[String]$ExportUsersFilePath = $TargetPath+"ExportUsers-TeamsEV-Phase2-v$date.csv"
Write-Host "  - TranscriptFilePath :"$transcriptFilePath
Write-Host "  - LogFilePath :"$logFilePath
Write-Host "  - UsersExportFile :"$logFilePath
$users = $null
$global:errorCount = 0
$global:errorCountUser = 0
#Log Initialization
Add-Content -Path $logFilePath -Value "LogLevel,UPN,Parameter,Message"


#Select CSV file dialog
Function Select-CSVFile
{
	param([string]$Title="Please select the batch file",[string]$Directory=$((Get-Location).Path + "\Batches"),[string]$Filter="Comma Seperated Values | *.csv")
	[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
	$objForm = New-Object Microsoft.Win32.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$show = $objForm.ShowDialog()

	If ($show -eq $true)
	{
		#Get file path
        [String]$csvFile = $objForm.FileName

		#Check file
        Write-Warning "The following file was selected: $($csvFile.Split("\")[$_.Length-1])"
		$continue = Read-Host "Press [C] to continue"

		If ($continue.ToLower() -eq "c")
		{
			Return $csvFile
		}
    }
    
    Return 0
}


#Log errors to file
Function Add-Log
{
    Param([String]$UPN, [ValidateSet("INFO", "WARNING", "ERROR")][string]$Level="ERROR", [String]$Parameter, [String]$Message)
    switch ($Level)
    {
        "INFO"
        {
        Write-Host "INFO: "$user.UserPrincipalName " : " $Message -ForegroundColor Green
        }
        "WARNING"
        {
        Write-Host "WARNING: "$user.UserPrincipalName " : " $Message -ForegroundColor Yellow
        }
        "ERROR"
        {
        Write-Host "ERROR: "$user.UserPrincipalName " : " $Message -ForegroundColor Red
        $global:errorCount++
        $global:errorCountUser++
        }
    }
    $log = $level+ ',' +$UPN + ',' + $Parameter + ',"' + $Message + '"'
    Add-Content -Path $logFilePath -Value $log
}

# Create Transcript file for analysis later when script is completed.  Checking for errors etc.
Start-Transcript -path $transcriptFilePath -append

write-host " "
write-host " "
write-host "Select your users batch CSV file" -ForegroundColor Yellow
$csvFile = Select-CSVFile
$users = Import-CSV $csvFile
$count = $users.count

write-host " "
write-host " "
write-host "From the CSV file, We have found "$count " Users to assign the relative policies" 
write-host "Processing "$count "Users...Please wait..." -foregroundcolor Yellow
write-host " "
write-host " "

# Run the PowerShell commands for each user, line by line in the CSV file - UserPrincipalName, PhoneNumberToAssign, OperatorType.

ForEach ($user in $users) 
{
    $global:errorCountUser = 0
    
    $userEnabled = $( try{ Get-csOnlineUser -Identity $user.UserPrincipalName |select AccountEnabled} catch {$Null})
    #checking if the UPN exists (or check for typo error)
    if($userEnabled -ne $null){
     
       
        #checking if the user account is enabled or error in the log
        if($userEnabled.accountenabled -eq 'TRUE')
        {

		    #Assign the phone number if defined - or if not filled out, just enable enterprise voice 
            If (($user.PhoneNumberToAssign -ne "") -and ($user.OperatorType -ne ""))
             { 
            If ($user.LocationID -ne ""){ # Note : LocationID need to be assigned to users with phone number          
                Try { Set-CsPhoneNumberAssignment -Identity $user.UserPrincipalName -PhoneNumber $user.PhoneNumberToAssign -PhoneNumberType $user.OperatorType -LocationId $user.LocationID -ErrorAction Stop}
	            Catch { Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "EV with PhoneNumber and LocationID" -Message $Error[0] }
            }else{ 
                #no LocationID defined - Use of the City to get the Location ID related to this City and assign it to the user. If you have Campus or multiple offices in the same city, fill out the Location ID in the spreadsheet !
                If ($user.City -ne "") {
                    Try { $loc=Get-CsOnlineLisLocation -City $user.City -ErrorAction Stop
	                Set-CsPhoneNumberAssignment -Identity $user.UserPrincipalName -PhoneNumber $user.PhoneNumberToAssign -PhoneNumberType $user.OperatorType -LocationId $loc.LocationId -ErrorAction Stop
                    }
                    Catch { 
                    Write-Host "TO REMOVE CATCH : "$loc.LocationId " for the city :" $user.City -ForegroundColor Magenta
                    Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "Location ID with City" -Message $Error[0] }
                }else{
                #nothing to assign the locationID - Only PhoneNumber will be assigned without LocationID
                    Add-Log -UPN $user.UserPrincipalName -Level WARNING -Parameter "Assignement without LocationID" -Message "The user will get a number but no Location attached"
                    Try {Set-CsPhoneNumberAssignment -Identity $user.UserPrincipalName -PhoneNumber $user.PhoneNumberToAssign -PhoneNumberType $user.OperatorType  -ErrorAction Stop}
                    Catch {Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "No EV Phone Assignment" -Message $Error[0] }
                }
             
            }
        }else { #No Phone Number or Operator Type (DR, CP, OC) defined - EnableEV to check if other errors (e.g.License)
            Try { Set-CsPhoneNumberAssignment -Identity $user.UserPrincipalName -EnterpriseVoiceEnabled $true -ErrorAction Stop }
            Catch { Add-Log -UPN $user.UserPrincipalName -Level WARNING -Parameter "EnterpriseVoice enabled only - no PhoneNumber nor locationID" -Message $Error[0] }
        }
     
     }else{ 
        Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "Disabled" -Message " The user account is disabled"    
        }

  }else{ Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "UPN not found" -Message "The UPN can not be found"}

  #For this user, review if any error has been reported for Logs
  If ($global:errorCountUser -ne 0)
  {
    Add-Log -UPN $user.UserPrincipalName -Level ERROR -Parameter "Errors during Assignment" -Message "Assignment of this user has completed with errors, please see logs in log Folder."
  }
  else{
    Add-Log -UPN $user.UserPrincipalName -Level INFO -Parameter "Assignment completed" -Message "Assignment of this user has completed with no errors"
  }
} #END OF THIS USER LOOP

#ASSIGNMENT COMPLETED FOR ALL THE USERS
write-host ""
write-host ""
write-host "PROGRESS STATUS : Completed Voice policies assignment for this users batch !" -foregroundcolor White 
write-host ""    
    If ($global:errorCount -ne 0)
    {
       Write-Host "Assignment of the batch has completed with errors, please see transcript and logs in Logs Folder." -Foregroundcolor Yellow 
    }
    Else
    {
       Write-Host "Assignment of the batch has completed with no errors. Check UsersExport CSV file for any discrepancy." -ForegroundColor Green
    }


#Creating a user assignment export with new Users policies values  
write-host " "
Write-host "User Assignment Status Report being generated" -foregroundcolor White -backgroundcolor Black
write-host " "
ForEach ($user in $users) 
{ 
    try{ Get-CsOnlineUser -Identity $user.UserPrincipalName | Select UserPrincipalName, DisplayName, AccountEnabled, EnterpriseVoiceEnabled, LineURI, UsageLocation, Country, DialPlan, TenantDialPlan, TeamsCallingPolicy, CallingLineIdentity, OnlineVoicemailPolicy, TeamsCallHoldPolicy, TeamsCallParkPolicy, TeamsEmergencyCallingPolicy, TeamsIPPhonePolicy, OnlineVoiceRoutingPolicy, InterpretedUserType, ProvisioningStamp, SubProvisioningStamp | Export-csv -path $ExportUsersFilePath -Append -NoTypeInformation }
    Catch { Add-Log -UPN $user.UserPrincipalName -Level Error -Parameter "UPN not found" -Message "The user will not be in the User Export CSV file - UPN not found" }
} 
    
Write-Host "Closing Teams admin session.....Done!" -foregroundcolor White
Write-Host ""
Stop-Transcript

Disconnect-MicrosoftTeams  


