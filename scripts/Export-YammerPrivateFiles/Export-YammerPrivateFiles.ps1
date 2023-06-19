<#
.DESCRIPTION
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

Purpose: 
    -Exports files attached to private messages for all users prior to native mode migration
     
Author:
    Dean Cron

Version:
    1.0

Requirements:

    1. Admin-created bearer token for Yammer app authentication:
        https://learn.microsoft.com/en-us/rest/api/yammer/app-registration
        https://techcommunity.microsoft.com/t5/yammer-developer/generating-an-administrator-token/m-p/97058

    2. Private content mode enabled for the verified admin that created the bearer token:
        https://learn.microsoft.com/en-us/yammer/manage-security-and-compliance/monitor-private-content

    3. Generate a network data export (uncheck "Include Attachments" and "Include external networks") from your network
        https://learn.microsoft.com/en-us/yammer/manage-security-and-compliance/export-yammer-enterprise-data#export-yammer-network-data-by-date-range-and-network

.EXAMPLE
    .\Export-YammerPrivateFiles.ps1
#>


<############    STUFF YOU NEED TO MODIFY    ############>

#Replace BearerTokenString with the Yammer API bearer token you generated. See "Requirements" near the top of the script.
$Global:YammerAuthToken = "BearerTokenString"

#Point this to the messages.csv you obtained from a network data export.
$messagesCsvPath = 'C:\temp\messages.csv'

#Root directory where files will be saved.
#Subdirectories will be created under here to separate each script run.
$outPath = 'C:\Temp'

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>

function Get-YammerAuthHeader {
    @{ AUTHORIZATION = "Bearer $YammerAuthToken" }
}

#Make sure messages.csv is where it's supposed to be
try{
    $messagesCsv = Import-Csv $messagesCsvPath
}
catch{
    Write-Host "Unable to open messages.csv. Ensure it's located at $messagesCsvPath"
    Return
}

#Create a separate folder in $rootPath for the output of each export run
$exportPath = $outPath +"\PrivateFilesExport{0}" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")

$authHeader = Get-YammerAuthHeader

Write-Host "Starting download of private message attachments to $exportPath"
$messagesCsv | ForEach-Object {
    do {
        $rateLimitHit = $false

        #Get private message files that haven't been deleted
        if (-not $_.deleted_by_id -AND $_.scope_type -eq "YAMMER_PRIVATE_CONVERSATION") { 

            $finalPath = $exportPath + "\" + $_.sender_email

            if(!(Test-Path -Path $finalPath)){
                New-Item -ItemType directory -Path $finalPath | Out-Null
            }

            #Deal with scenarios where multiple files were uploaded to a single private message
            $filesArray = $_.attachments.split(", :").trim("uploadedfile:") | Where-Object { -not [String]::IsNullOrEmpty($_) }

            foreach($fileID in $filesArray)
            {
                $uri =  "https://www.yammer.com/api/v1/uploaded_files/$fileID/download"

                try
                {
                    $response = Invoke-WebRequest -Uri $uri -Headers $authHeader -method GET
                    $contentDisposition = $response.Headers.'Content-Disposition'
                    $fileName = $contentDisposition.Split("=;")[2].Replace("`"","")
                    $outFile = Join-Path $finalPath $fileName

                    Write-Host "Downloading $fileName"
                    $file = [System.IO.FileStream]::new($outFile, [System.IO.FileMode]::Create)
                    $file.Write($response.Content, 0, $response.RawContentLength)
                    $file.close()
                }
                catch {
                    if( $_.Exception.Response.StatusCode.Value__ -eq "429" -or $_.Exception.Response.StatusCode.Value__ -eq "503" )
                    {
                       #Deal with rate limiting
                       #https://learn.microsoft.com/en-us/rest/api/yammer/rest-api-rate-limits#yammer-api-rate-limts
                       $rateLimitHit = $true
                    }
                    elseif( $_.Exception.Response.StatusCode.Value__ -eq "403")
                    {
                        #https://learn.microsoft.com/en-us/yammer/manage-security-and-compliance/monitor-private-content
                        Write-Host "Download attempt reported ACCESS DENIED on $uri. Please ensure your user account has Private Content Mode enabled in Yammer." -ForegroundColor Red
                    }
                    else{
                        $e = $error[0]
                        $l = $_.InvocationInfo.ScriptLineNumber
                        Write-Host "Failed while attempting download of export file $uri" -ForegroundColor Red
                        Write-Host "error $e on line $l" -ForegroundColor Red
                    }
                }
                if ($rateLimitHit) {
                    #429 or 503: Sleep for a bit before retrying
                    Write-Host "Rate limit hit, sleeping for 15 seconds"
                    Start-Sleep -Seconds 15 
                }
            }
        }
    } while ($rateLimitHit)
}

Write-Host "Downloads complete, files will be located in $exportPath"
