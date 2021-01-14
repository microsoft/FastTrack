<#
Write-Output "Please install the Azure AD Powershell Module to continue: https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0"
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

        [Parameter(Mandatory=$true,
        ParameterSetName='UPN',
        HelpMessage='Enter the UserPrincipalName - Example "user@domain.com".')]
        [String]$UserPrincipalName,

        [Parameter(Mandatory=$True,
        ParameterSetName='RoleName',
        HelpMessage='Enter the name of the Admin Role you would like to see members of.')]
        [String]$RoleName,
        
        [Parameter(Mandatory=$true,
        ParameterSetName='All',
        HelpMessage='This is the default parameter, will list all "active" admin roles and members.')]
        [switch]$All
    )
    
    begin {
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
                elseif($PSCmdlet.ParameterSetName -eq "UPN"){
                    
                }
                elseif ($PSCmdlet.ParameterSetName -eq "RoleName"){
                    
                }
            }
            catch{
                return $_.Exception.Message
            }
        }
        Catch{
            Write-Output "Please install the Azure AD powershell module following the instructions at this link: https://aka.ms/AAau56t"
            Break
        }
        
    }
    
    process {
        
    }
    
    end {
        return $MemberList
    }