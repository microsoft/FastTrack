<#
    .DESCRIPTION
        This is just a one liner script to see your current usage versus available subscriptions in Azure AD.
         
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
    
    .PARAMETER All
        This is the default parameter and will get all SKUs and their current usage vs total available

    .PARAMETER SubscriptionName
        If you are just looking for the current usage or total available licenses for a specific SKU you can enter the name here

    .EXAMPLE
        To get all the avalable SKUs and their current usage to available
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com -All

        To get a specific SKUs current usage to available
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com -SubscriptionName SPE_E5

        To export this to a csv file
        .\Get-LicenseInfo.ps1 -Admin admin@contoso.com | Export-Csv MyLicenses.csv -NoTypeInformation
#>

[CmdletBinding(DefaultParameterSetName='All')]
    param (
        [Parameter(Mandatory=$True,
        ParameterSetName='SUB',
        HelpMessage='Enter the admin account for the tenant - Example "admin@contoso.com".')]
        [Parameter(Mandatory=$True,
        ParameterSetName='All',
        HelpMessage='Enter the admin account for the tenant - Example "admin@contoso.com".')]
        [String]$Admin,
        
        [Parameter(Mandatory=$false,
        ParameterSetName='All',
        HelpMessage='This is the default parameter, will list all subscriptions and how many licenses are available.')]
        [switch]$All,

        [Parameter(Mandatory=$false,
        ParameterSetName='SUB',
        HelpMessage='Enter the Subscription Name - Example "SPE_E5".')]
        [String]$SubscriptionName
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
        #Check if already connected to AAD:
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
        try{
            $SubTable = @()
            if($PSCmdlet.ParameterSetName -eq "All"){
                $SubList = Get-AzureADSubscribedSku
                foreach($Sub in $SubList){
                    if($Sub.PrepaidUnits.Enabled -gt 0){
                        $EnabledUnits = $Sub.PrepaidUnits.Enabled
                    }
                    Else{
                        $EnabledUnits = 0
                    }
                    $Table = New-Object PSObject -Property @{
                        SKUPartNumber = $Sub.SKUPartNumber
                        ConsumedUnits = $Sub.ConsumedUnits
                        TotalUnits = $EnabledUnits
                    }
                    $SubTable += $Table
                }
            }

            if ($PSCmdlet.ParameterSetName -eq "Sub"){
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
        catch{
            return $_.Exception.Message
        }
    }
    end {
        $SubTable
    }