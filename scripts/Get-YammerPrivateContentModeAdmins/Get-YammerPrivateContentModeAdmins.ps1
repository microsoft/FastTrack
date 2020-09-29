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
	    
    .EXAMPLE
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### >
    
    .EXAMPLE
        .\Get-YammerPrivateContentModeAdmins.ps1 -DeveloperToken < ###########-##################### > | Export-CSv -Path "C:\scripts\YammerPrivateContentModeAdmins.csv" -NoTypeInformation
#>

[Cmdletbinding()]
    Param (
        [Parameter(mandatory=$true)][String]$DeveloperToken
    )

    begin{
        $Url = "https://www.yammer.com/api/v1/users.json"
        $Header = @{ Authorization=("Bearer " + $DeveloperToken) }
        $TableOutput = @()
        
        try{
            $WebRequest = Invoke-WebRequest –Uri $Url –Method Get -Headers $Header
            $ConvertJSON = $WebRequest.Content | ConvertFrom-Json

            $ConvertJSON | ForEach-Object {  
                $UserList = $_
                $Output = New-Object psobject -Property ([ordered]@{
                    'Username' = ($UserList.email)
                    'Private Content Mode Enabled' = ($UserList.supervisor_admin)
                })
                    $TableOutput += $Output 
            }
            return $TableOutput
        }

    catch{
        return $_.Exception.Message
        }
    }
