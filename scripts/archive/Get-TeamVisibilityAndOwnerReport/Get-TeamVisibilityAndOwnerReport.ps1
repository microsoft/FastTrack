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
    
    .PARAMETER GroupVisibility
        Used to reduce the amount of teams returned in the output, is the group "Public" or "Private"

    .PARAMETER ExportPath
        Optional parameter for specifying the path of the exported CSV report, default is script directory
    
    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to the defaulted script directory
        .\Get-TeamVisibilityAndOwnerReport.ps1 -GroupVisibility Public

    .EXAMPLE
        To get a list of all public groups and their owner(s) CSV is exported to specific directory, do not include trailing '\'
        .\Get-TeamVisibilityAndOwnerReport.ps1 -GroupVisibility Public -ExportPath "C:\Scripts"
#>

[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage='Enter Private or Public to filter Team searchbase')]
        [ValidateSet("Private","Public")]
        [String]$GroupVisibility,
        
        [Parameter(Mandatory=$false,
        HelpMessage='Enter the path to save the CSV file without the trailing "\" Defaults to script location if none specificied')]
        [String]$ExportPath
    )

    begin{
        function CheckModules{
            try{
                #Test for AzureAD or AzureADPreview Module
                if(Get-Module -ListAvailable -Name "MicrosoftTeams"){
                    return 1
                }
                else{
                    return 2
                }
            }
            catch{
                return $_.Exception.Message
            }
        }
        try{
            switch(CheckModules){
                1 {Import-Module MicrosoftTeams}
                2 {
                    Write-Output "Microsoft Teams PowerShell module not found - Please install the Microsoft Teams powershell module by following the instructions at this link: https://aka.ms/AAbfj8w `n"
                    break
                }
            }
        }
        catch{
            return $_.Exception.Message
        } 
        
        try{
            $TestConnection = Get-CsGroupPolicyAssignment -ErrorAction Stop
        }
        catch [System.Management.Automation.CmdletInvocationException]{
            try{
                Connect-MicrosoftTeams | Out-Null
            }
            catch{
                return $_.Exception.Message
            }
        }
        
        if($ExportPath -eq ""){
            $ExportPath = Split-Path $script:MyInvocation.MyCommand.Path
        }
    }

    process{
        try{
            Connect-MicrosoftTeams | Out-Null
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
                    Export-Csv -InputObject $Object -path "$($ExportPath)\TeamsVisibilityOwnerReport.csv" -NoTypeInformation
                }
                catch{
                    return $_.Exception.Message
                    Break
                }
            }
            catch{
                return $_.Exception.Message
            }
        }
        catch{
            return $_.Exception.Message
        }
    }
    end{
        return $Masterlist | Select GroupID,TeamName,Visibility,Owners
        Break
    }