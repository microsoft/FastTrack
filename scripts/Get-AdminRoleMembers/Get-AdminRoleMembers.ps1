<#
Write-Output "Please install the Azure AD Powershell Module to continue: https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0"
#>
[CmdletBinding(DefaultParameterSetName='All')]
    param (
        #Admin username
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

        #Specify the export path for the CSV - Default is script directory
        [Parameter(Mandatory=$False,
        ParameterSetName='UPN',
        HelpMessage='Enter the path for the CSV export (Default is the script directory)')]
        [Parameter(Mandatory=$False,
        ParameterSetName='RoleName',
        HelpMessage='Enter the path for the CSV export (Default is the script directory)')]
        [Parameter(Mandatory=$False,
        ParameterSetName='All',
        HelpMessage='Enter the path for the CSV export (Default is the script directory)')]
        [String]$ExportPath,        

        #Mandatory
        [Parameter(Mandatory=$true,
        ParameterSetName='UPN',
        HelpMessage='Enter the UserPrincipalName - Example "user@domain.com".')]
        [String]$UserPrincipalName,

        #Mandatory
        [Parameter(Mandatory=$True,
        ParameterSetName='RoleName',
        HelpMessage='Enter the name of the Admin Role you would like to see members of.')]
        [String]$RoleName,
        
        #Mandatory/Default
        [Parameter(Mandatory=$true,
        ParameterSetName='All',
        HelpMessage='This is the default parameter, will list all "active" admin roles and members.')]
        [switch]$All
    )
    
    process {
        Try{
            Import-Module AzureAD
            try{
                Connect-AzureAd -AccountId $Admin
                $MemberList = @()
                if($PSCmdlet.ParameterSetName -eq "All"){
                    $RoleList = Get-AzureADDirectoryRole
                    foreach($Role in $RoleList){
                        $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId
                        $Table = New-Object PSObject -Property @{
                            ObjectID = ($Role.ObjectId)
                            RoleName = ($Role.DisplayName)
                            Member = (@($RoleMembers.UserPrincipalName) -join '; ')
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
                            }
                            $MemberList += $Table 
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
                            $Table.Member += "$($Member.UserPrincipalName);"
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
                break
            }
        }
        catch{
            Write-Output "Please install the Azure AD powershell module following the instructions at this link: https://aka.ms/AAau56t"
            break
        }
        
    }
        
    end {
        return $MemberList
    }