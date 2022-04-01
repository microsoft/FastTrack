
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
