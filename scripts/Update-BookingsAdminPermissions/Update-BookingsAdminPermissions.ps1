<#
Update-BookingsAdminPermissions.ps1 PowerShell script | Version 0.1
by NickBear@microsoft.com and David.Whitney@microsoft.com
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

<#
.SYNOPSIS
    To Add/Remove user(s) to all Bookings's mailboxes and export out to a CSV. 

.DESCRIPTION
    To Add/Remove user(s) to all Bookings's mailboxes's permissions so that you can view/edit Bookings via Graph API or Bookings PowerShell SDK. Then you can export out
    the Bookings mailbox permissions afterwards to a CSV.

.EXAMPLE
    .\Update-BookingsAdminPermissions.ps1 -ExportCSVFilePath "C:\path\to\export.csv"
    Report on all Bookings's mailboxes's permissions.

.EXAMPLE
    .\Update-BookingsAdminPermissions.ps1 -AddUser "User1@Contoso.com","User2@Contoso.com" -ExportCSVFilePath C:\path\to\export.csv
    Add users "User1@Contoso.com" and "User2@Contoso.com" to all Bookings's mailboxes's permissions and then Export a CSV of all Bookings's Mailboxes's permissions.

.EXAMPLE
    .\Update-BookingsAdminPermissions.ps1 -RemoveUser "User3@Contoso.com","User4@Contoso.com" -ExportCSVFilePath C:\path\to\export.csv
    Remove users "User3@Contoso.com" and "User4@Contoso.com" from all Bookings's mailboxes's permissions and then Export a CSV of all Bookings's Mailboxes's permissions.

.EXAMPLE
    .\Update-BookingsAdminPermissions.ps1 -AddUser "User1@Contoso.com","User2@Contoso.com" -RemoveUser "User3@Contoso.com","User4@Contoso.com" -ExportCSVFilePath C:\path\to\export.csv
    Add users "User1@Contoso.com" and "User2@Contoso.com" to all Bookings's mailboxes's permissions, Remove users "User3@Contoso.com" and "User4@Contoso.com" from all Bookings's mailboxes's permissions,
    and then Export a CSV of all Bookings's Mailboxes's permissions.

.OUTPUTS
    Writes out a CSV file report with columns:
    - Identity
    - User
    - AccessRights
    - ObjectState
#>

[CmdletBinding()]
param
(   
    # Path to where to save the report export CSV file
    [Parameter(Mandatory = $false)]
    [string]
    $ExportCSVFilePath,
    
    # Provide the specific user ID that you want to add to the Bookings Mailboxes
    [Parameter(Mandatory = $false)]
    [string[]]
    $AddUser,

    # Provide the specific user ID that you want to remove from the Bookings Mailboxes
    [Parameter(Mandatory = $false)]
    [string[]]
    $RemoveUser
)

# Checks for the Exchange Online PowerShell Module
$ExchangeModule = Get-Module -Name "ExchangeOnlineManagement" -ListAvailable
if (-not ($ExchangeModule)) 
{
    throw "This script requires the Exchange Online module - use 'Install-Module -Name ExchangeOnlineManagement' from an elevated PowerShell session, restart this PowerShell session, then try again."
}

Import-Module ExchangeOnlineManagement -WarningAction SilentlyContinue -ErrorAction Stop

# Connect to Exchange Online
Connect-ExchangeOnline

# To pull all Bookings Exchange mailboxes
$BookingsMailboxes = Get-Mailbox -RecipientTypeDetails SchedulingMailbox -ResultSize: Unlimited 

If ($AddUser)
    {
        foreach ($BookingsMailbox in $BookingsMailboxes) 
        {
            foreach ($UserToAdd in $AddUser)
            {
                Add-MailboxPermission -Identity $BookingsMailbox.Identity -User:$UserToAdd -AccessRights FullAccess -Deny:$false -Confirm:$false

                Add-RecipientPermission -Identity $BookingsMailbox.Identity -Trustee:$UserToAdd -AccessRights SendAs -Confirm:$false
            }
        }
    }

If ($RemoveUser)
    {
        foreach ($BookingsMailbox in $BookingsMailboxes) 
        {
            foreach ($UserToRemove in $RemoveUser)
            {   
                Remove-MailboxPermission -Identity $BookingsMailbox.Identity -User:$UserToRemove -AccessRights FullAccess -Deny:$false -Confirm:$false

                Remove-RecipientPermission -Identity $BookingsMailbox.Identity -Trustee:$UserToRemove -AccessRights SendAs -Confirm:$false
            }
        }
    }

# To pull the Bookings mailboxes permissions
$BookingsPermissionUsers = $BookingsMailboxes | Get-MailboxPermission | Where-Object {($_.user -like '*@*')} 

# To export to a location the permissions in a CSV format
If ($ExportCSVFilePath)
    {
        $BookingsPermissionUsers | Select-Object Identity, User, AccessRights, ObjectState | Export-Csv -Path $ExportCSVFilePath

        Write-Output "Saved output file: $($ExportCSVFilePath)"
    }
