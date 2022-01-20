<#
    .DESCRIPTION
        This script is to help you automate a decision process around which subscription you want to assign users to. 
        This is meant to be used in combination with Azure AD Dynamic Groups for group-based licensing but 
        can also be used for direct signed licensing. 
        
        The idea for this script came when approached about a complex licensing scenario which effectively equaled an M365 E5 license 
        but was segmented across multiple subset subscription types as well as the M365 E5 grouping. 

        The idea is to be able to detect a preferred licenses current usage and assign a user to it and only assign the user the alternative 
        subscription if the preferred license is completely in use. This will allow for automated assigning of different licenses according to current usage.

        !! View the comment segmented out under the Get-LicensingUsage function to add additional logic. !!
         
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

        Author: Brian Baldock - brian.baldock@microsoft.com

        Requirements: 
            Have the Azure AD PowerShell module installed by following the instructions at this link: https://aka.ms/AAau56t"
    
    .PARAMETER Admin
        Madatory Parameter - Admin account utilized for accessing the Microsoft 365 platform
    
    .PARAMETER PreferredLicense
        This is the license you would prefer a user be assigned unless there is no available licenses

    .PARAMETER BackupLicense
        This is the license you would like to use in case the preferred license has no available licenses
  
    .EXAMPLE
        Validate if the preferred license has available licenses if not validate that the backup license has available licenses.
        .\Get-LicenseUsage.ps1 -Admin admin@contoso.com -PreferredLicense SPE_E5 -BackupLicense EMSPREMIUM
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True,
    HelpMessage='Enter the admin account for the tenant - Example admin@contoso.com.')]
    [String]$Admin,

    [Parameter(Mandatory=$True,
    HelpMessage='Provide preferred license name.')]
    [String]$PreferredLicense,

    [Parameter(Mandatory=$True,
    HelpMessage='Provide backup license name.')]
    [string]$BackupLicense
)

begin {
    function CheckModules{
        try{
            #Test for AzureAD or AzureADPreview Module
            if(Get-Module -ListAvailable -Name "AzureAD"){
                return 1
            }
            elseif(Get-Module -ListAvailable -Name "AzureADPreview"){
                return 2
            }
            else{
                return 3
            }
        }
        catch{
            return $_.Exception.Message
        }
    }
    try{
        switch(CheckModules){
            1 {Import-Module AzureAD}
            2 {Import-Module AzureADPreview}
            3 {
                Write-Output "Please install the Azure AD powershell module by following the instructions at this link: https://aka.ms/AAau56t"
                break
            }
        }
    }
    catch{
        return $_.Exception.Message
    }            
    #Check if already connected to AAD PowerShell:
    try{
        $TestConnection = Get-AzureADTenantDetail
    }
    catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]{
        try{
            Connect-AzureAD -AccountId $Admin | Out-Null
        }
        catch{
            return $_.Exception.Message
        }
    }
}

process {
    function Get-LicenseInfo{
        param(
            [Parameter(Mandatory=$True,
            HelpMessage='Enter the Subscription Name - Example "SPE_E5".')]
            [String]$SubscriptionName
        )
        try{
            if($SubList = Get-AzureADSubscribedSku | Where-Object {$_.SKUPartNumber -eq $($SubscriptionName)}){
                if($Sublist.PrepaidUnits.Enabled -gt 0){
                    $EnabledUnits = $Sublist.PrepaidUnits.Enabled
                }
                Else{
                    $EnabledUnits = 0
                }
                $Table = New-Object PSObject -Property @{
                    SKUPartNumber = $SubList.SKUPartNumber
                    ConsumedUnits = $SubList.ConsumedUnits
                    TotalUnits = $EnabledUnits
                }
                $SubTable += $Table
                return $SubTable
            }
            else{
                Write-Output "No subscription by the name $($SubscriptionName) found."
                break
            }
        }
        catch{
            return $_.Exception.Message
            break
        }
    }
}

end {
    try{
        if([array]$PreferredLicense = Get-LicenseInfo -SubscriptionName $PreferredLicense){
            if([array]$BackupLicense = Get-LicenseInfo -SubscriptionName $BackupLicense){
                if($PreferredLicense.ConsumedUnits -lt $PreferredLicense.TotalUnits){
                    <#
                        Do stuff here, 
                        Example: Assign a user to a specific group if the preferred license is available.
                        Add a specific AD attribute etc.
                    #>
                    Write-Output "There are $($PreferredLicense.TotalUnits - $PreferredLicense.ConsumedUnits) preferred $($PreferredLicense.SkuPartNumber) licenses left."
                    break
                }
                else{
                    if($BackupLicense.ConsumedUnits -lt $BackupLicense.TotalUnits){
                        <#
                            Do other stuff here, 
                            Example: Assign a user to a specific group if the preferred license isn't available, using the "backup" license.
                            Add a specific AD attribute etc.
                        #>
                        Write-Output "There are not enough $($PreferredLicense.SkuPartNumber) licences left. Use $($BackupLicense.SkuPartNumber) instead."
                        break
                    }
                    else{
                        Write-Output "There is a problem comparing the license usage versus availability."
                        break
                    }
                }
            }
        }
        else{
            Write-Output "Something is preventing you from accessing Get-LicenseInfo function."
        }
    }
    catch{
        return $_.Exception.Message
        break
    }        
}