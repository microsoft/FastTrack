<#
    .DESCRIPTION
        This script is designed to display all of the members of the Azure AD Administrator Roles. You can filter by three
        different parameters. Either "-All" displaying all members from all Administrator Roles, "-UserPrincipalName" to find
        out which Roles a specific user is member of, or, "-RoleName" to display the members of a specific role group.
         
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
        Displays all members from all Administrator Roles. This is the default output

    .PARAMETER UserPrincipalName
        Specify a specific UserPrincipalName to display roles for that specific user

    .PARAMETER RoleName
        Specify a specifc roles name to get a list of users who are members of said role
    
    .EXAMPLE
        Get a list of all the members of all the Administrator Roles in Azure AD
        .\Get-AADAdminRoleMembers.ps1 -Admin admin@contoso.onmicrosoft.com -All

    .EXAMPLE
        Get a list of all the roles a user is member of
        .\Get-AADAdminRoleMembers.ps1 -Admin admin@contoso.onmicrosoft.com -UserPrincipalName user@contoso.onmicrosoft.com

    .EXAMPLE
        Display the members for a particular Adminitrator Role
        .\Get-AADAdminRoleMembers.ps1 -Admin admin@contoso.onmicrosoft.com -RoleName "Power BI Service Administrators"
#>

[CmdletBinding(DefaultParameterSetName='All')]
    param (
        [Parameter(Mandatory=$True,
        ParameterSetName='UPN',
        HelpMessage='Enter the admin account for the tenant - Example "admin@domain.com".')]
        [Parameter(Mandatory=$True,
        ParameterSetName='RoleName',
        HelpMessage='Enter the admin account for the tenant - Example "admin@domain.com".')]
        [Parameter(Mandatory=$True,
        ParameterSetName='All',
        HelpMessage='Enter the admin account for the tenant - Example "admin@domain.com".')]
        [String]$Admin,
        
        [Parameter(Mandatory=$false,
        ParameterSetName='All',
        HelpMessage='This is the default parameter, will list all "active" admin roles and members.')]
        [switch]$All,

        [Parameter(Mandatory=$false,
        ParameterSetName='UPN',
        HelpMessage='Enter the UserPrincipalName - Example "user@domain.com".')]
        [String]$UserPrincipalName,

        [Parameter(Mandatory=$false,
        ParameterSetName='RoleName',
        HelpMessage='Enter the name of the Admin Role you would like to see members of.')]
        [String]$RoleName
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
            $MemberList = @()
            if($PSCmdlet.ParameterSetName -eq "All"){
                $RoleList = Get-AzureADDirectoryRole
                foreach($Role in $RoleList){
                    $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId
                    $Table = New-Object PSObject -Property @{
                        ObjectID = ($Role.ObjectId)
                        RoleName = ($Role.DisplayName)
                        Member = (@($RoleMembers.UserPrincipalName) -join ', ')
                    }
                    $MemberList += $Table
                }
            }

            if($PSCmdlet.ParameterSetName -eq "UPN"){
                $RoleList = Get-AzureADDirectoryRole
                foreach($Role in $RoleList){
                    $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectID
                    foreach($Member in $RoleMembers){
                        if($Member.UserPrincipalName -eq $UserPrincipalName){
                            $Table = New-Object PSObject -Property @{
                                ObjectID = ($Role.ObjectId)
                                RoleName = ($Role.DisplayName)
                                Member = ($Member.UserPrincipalName)
                            }
                            $MemberList += $Table 
                        }
                    }           
                }
            }

            if ($PSCmdlet.ParameterSetName -eq "RoleName"){
                try{
                    $VerifiedRoleName = Get-AzureADDirectoryRole | Where-Object -Property DisplayName -eq $RoleName
                    $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $VerifiedRoleName.ObjectId
                    $Table = New-Object PSObject -Property @{
                        ObjectID = ($VerifiedRoleName.ObjectID)
                        RoleName = ($VerifiedRoleName.DisplayName)
                        Member = ""
                    }
                    foreach($Member in $RoleMembers){
                        $Table.Member += "$($Member.UserPrincipalName), "
                    }
                    $MemberList += $Table
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
        return $MemberList | Select-Object ObjectID, RoleName, Member
    }