<#
    .DESCRIPTION
        Script to list all existing Teams, filters on visibility status (Public or Private) and
        associated owners. The owners are listed in way that's easy to paste into an email for mass mailing if necessary.
         
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
            Microsoft Teams powershell module can be installed following the instructions at this link: https://aka.ms/AAatf62
    
    .PARAMETER M365Admin
        Admin account utilized for accessing the Microsoft 365 platform

    .PARAMETER GroupVisibility
        Used to reduce the amount of teams returned in the output, is the group "Public" or "Private"

    .PARAMETER ExportPath
        Optional parameter for specifying the path of the exported CSV report, default is script directory
    
    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to the defaulted script directory
        .\Get-TeamVisibilityAndOwnerReport.ps1 -M365Admin admin@contoso.onmicrosoft.com -GroupVisility Public

    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to specific directory, do not include trailing '\'
        .\Get-TeamVisibilityAndOwnerReport.ps1 -M365Admin admin@contoso.onmicrosoft.com -GroupVisility Public -ExportPath "C:\Scripts"
#>

[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage='Enter an admin account UPN - Example "user@domain.com"')]
        [String]$M365Admin,

        [Parameter(Mandatory=$true,
        HelpMessage='Enter Private or Public to filter Team searchbase')]
        [String]$GroupVisibility,
        
        [Parameter(Mandatory=$false,
        HelpMessage='Enter the path to save the CSV file without the trailing "\" Defaults to script location if none specificied')]
        [String]$ExportPath
    )

    begin{
        if(!($GroupVisibility -eq "Private" -or $GroupVisibility -eq "private" -or $GroupVisibility -eq "Public" -or $GroupVisibility -eq "public")){
            Write-Host "Please enter a valid option for -GroupVisibility. Private or Public are the valid options."
            Break
        }
        else{
            if($ExportPath -eq ""){
                $ExportPath = Split-Path $script:MyInvocation.MyCommand.Path
            }
            try{
                Import-Module MicrosoftTeams
                try{
                    Connect-MicrosoftTeams -AccountId $M365Admin
                    try{
                        $Teams = Get-Team | Where-Object -Property Visibility -eq $GroupVisibility
                        $Object = New-Object PSObject -Property @{}
                        $Masterlist = @()
    
                        Foreach($Team in $Teams){
                            $TeamMembers = Get-TeamUser -GroupId $Team.GroupID | Where-Object -Property Role -eq "owner" | Select-Object User
                            $Object = New-Object PSObject -Property @{
                                GroupID = ($Team.GroupID)
                                TeamName = ($Team.DisplayName)
                                Visibility = ($Team.Visibility)
                                Owners = (@($TeamMembers.User) -join '; ')
                            }
                            $Masterlist += $Object
                        }
                        try{
                            Export-Csv -InputObject $Object -path "$($ExportPath)\TeamsOwnerReport.csv" -NoTypeInformation
                        }
                        catch{
                            return $_.Exception.Message
                            Break
                        }
                    }
                    catch{
                        return $_.Exception.Message
                        Break
                    }
                }
                catch{
                    return $_.Exception.Message
                    Break
                }
            }
            catch{
                Write-Output "Please install the MicrosoftTeams powershell module following the instructions at this link: https://aka.ms/AAatf62"
                Break
            }
        }
    }

    end{
        return $Masterlist | Format-Table GroupID,TeamName,Visibility,Owners
        Break
    }