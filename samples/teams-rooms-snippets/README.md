# Microsoft FastTrack Open Source - Teams Rooms Snippets

Microsoft Teams Rooms configuration snippets for single room creation and configuration as well as bulk.

## Usage

The modules required to run these snippets are:
- [Microsoft Graph](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)
- [Exchange Online](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#install-the-exchange-online-powershell-module)


After installing these modules, here's how you will connect to them in order to be able to run the snippets:

```PowerShell
Connect-MgGraph -Scopes "User.Read, User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All"
Connect-ExchangeOnline
```

**Note:** Make sure you're running the latest versions of the modules by running `Get-InstalledModule <MODULENAME>`. If not latest, update them with `Update-Module <MODULENAME>`.

## Create and configure a single resource account
```PowerShell
$UPN = "mtr-focusroom@contoso.com"
$Alias = "mtr-focusroom"
$Password = "R3pl4c3th1sw1th4str0n6p4ssw0rd!!"
$License = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "Microsoft_Teams_Rooms_Pro"}
$UsageLocation = "US"
$DisplayName = "MTR-FocusRoom"

$Room = New-Mailbox -Name $UPN -Alias $Alias -Room -DisplayName $DisplayName -EnableRoomMailboxAccount $true -RoomMailboxPassword (ConvertTo-SecureString -String $Password -AsPlainText -Force)

Set-CalendarProcessing -Identity $Alias -AutomateProcessing AutoAccept -AddOrganizerToSubject $false -DeleteComments $false -DeleteSubject $false -RemovePrivateProperty $false -ProcessExternalMeetingMessages $true -AdditionalResponse "This is a Microsoft Teams meeting room!"

Update-MgUser -UserId $Room.ExternalDirectoryObjectId -PasswordPolicies DisablePasswordExpiration -UsageLocation $UsageLocation 

Set-MgUserLicense -UserId $Room.ExternalDirectoryObjectId -AddLicenses @{SkuId = $License.SkuId} -RemoveLicenses @()
```

## Create and configure resource accounts in bulk
If you need to create and configure resource accounts in bulk, you can leverage a CSV with the following properties:
- **UPN**
- **Alias**
- **Password**
- **License**
- **UsageLocation**
- **DisplayName**
- **AutomateProcessing**
- **AddOrganizerToSubject**
- **DeleteComments**
- **RemovePrivateProperty**
- **ProcessExternalMeetingMessages**
- **AdditionalResponse**

Sample CSV is included:
![Sample CSV](https://i.postimg.cc/XqSZ4rpk/2x1-Nye-GOk-T.png)

Then use the following snippet that will read the CSV, create a resource account per entry and configure it according to the settings specified in the CSV:

```PowerShell
$path = ".\resource-accounts.csv"
$RAs = Import-Csv -Path $path

foreach ($RA in $RAs) {
    $UPN = $RA.UPN
    $Alias = $RA.Alias 
    $Password = $RA.Password
    $License = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq $RA.License}
    $UsageLocation = $RA.UsageLocation
    $DisplayName = $RA.DisplayName
    $AutomateProcessing = $RA.AutomateProcessing
    $AddOrganizerToSubject = if ($RA.AddOrganizerToSubject -eq '1') { $true } else { $false }
    $DeleteComments = if ($RA.DeleteComments -eq '1') { $true } else { $false }
    $DeleteSubject = if ($RA.DeleteSubject -eq '1') { $true } else { $false }
    $RemovePrivateProperty = if ($RA.RemovePrivateProperty -eq '1') { $true } else { $false }
    $ProcessExternalMeetingMessages = if ($RA.ProcessExternalMeetingMessages -eq '1') { $true } else { $false }
    $AdditionalResponse = $RA.AdditionalResponse

    $Room = New-Mailbox -Name $UPN -Alias $Alias -Room -DisplayName $DisplayName -EnableRoomMailboxAccount $true -RoomMailboxPassword (ConvertTo-SecureString -String $Password -AsPlainText -Force)

    Set-CalendarProcessing -Identity $Alias -AutomateProcessing $AutomateProcessing -AddOrganizerToSubject $AddOrganizerToSubject -DeleteComments $DeleteComments -DeleteSubject $DeleteSubject -RemovePrivateProperty $RemovePrivateProperty -ProcessExternalMeetingMessages $ProcessExternalMeetingMessages -AdditionalResponse $AdditionalResponse

    Update-MgUser -UserId $Room.ExternalDirectoryObjectId -PasswordPolicies DisablePasswordExpiration -UsageLocation $UsageLocation 

    Set-MgUserLicense -UserId $Room.ExternalDirectoryObjectId -AddLicenses @{SkuId = $License.SkuId} -RemoveLicenses @()
}
```

## Author

|Author|Last Updated Date
|----|--------------------------
|Mihai Filip, Microsoft|February 10, 2023|

## Issues

Please report any issues you find to the [issues list](https://github.com/microsoft/FastTrack/issues).

## Support Statement

The scripts, samples, and tools made available through the FastTrack Open Source initiative are provided as-is. These resources are developed in partnership with the community and do not represent official Microsoft software. As such, support is not available through premier or other Microsoft support channels. If you find an issue or have questions please reach out through the issues list and we'll do our best to assist, however there is no associated SLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
