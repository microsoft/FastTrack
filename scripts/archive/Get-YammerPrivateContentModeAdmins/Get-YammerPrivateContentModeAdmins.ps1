<#
    .DESCRIPTION
        Script to list Yammer verified Admins that have promoted themselves to Private Content Mode.
         
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
            Yammer developer token created at the following site : https://www.yammer.com/client_applications
    
    .PARAMETER DeveloperToken
        The developer token generated above
    .PARAMETER VerifiedAdminsOnly
        Boolean ($True or $False) will list only verified admins in Yammer otherwise will list all users 
	    
    .EXAMPLE
        To list all users whether or not they are verified admins:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly $False

    .EXAMPLE
        To list only verified admins and whether they have Private Content Mode enabled:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly $True
    
    .EXAMPLE
        To export the list as a CSV file:
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > -VerifiedAdminsOnly [$True | $False]| Export-CSv -Path "C:\scripts\YammerPrivateContentModeAdmins.csv" -NoTypeInformation
#>

[Cmdletbinding()]
    Param (
        [Parameter(mandatory=$true)][String]$DeveloperToken,
        [Parameter(mandatory=$true)][Bool]$VerifiedAdminsOnly
    )

    begin{
        
        function Get-UserList{
            $Url = "https://www.yammer.com/api/v1/users.json"
            $Header = @{ Authorization=("Bearer " + $DeveloperToken) }
            $TableOutput = @()

            try{
                $WebRequest = Invoke-WebRequest –Uri $Url –Method Get -Headers $Header
                $ConvertJSON = $WebRequest.Content | ConvertFrom-Json

                if($VerifiedAdminsOnly){
                    $ConvertJSON | ForEach-Object {
                        $UserList = $_
                        $Output = New-Object psobject -Property ([ordered]@{
                            'Username' = ($UserList.email)
                            'Verified Admin' = ($UserList.verified_admin)
                            'Private Content Mode Enabled' = ($UserList.supervisor_admin)
                            })

                        if($UserList.verified_admin -eq "TRUE" -or $UserList.verified_admin -eq "true"){
                            $TableOutput += $Output
                        }
                    }
                }

                else{
                    $ConvertJSON | ForEach-Object {
                        $UserList = $_
                        $Output = New-Object psobject -Property ([ordered]@{
                            'Username' = ($UserList.email)
                            'Verified Admin' = ($UserList.verified_admin)
                            'Private Content Mode Enabled' = ($UserList.supervisor_admin)
                        })
                    $TableOutput += $Output
                    }
                }
                return $TableOutput
            }
            catch{
                return $_.Exception.Message
            }
        }
    }

    process{
        try{
           Get-UserList
        }
        catch{
            return $_.Exception.Message
        }
    }
 