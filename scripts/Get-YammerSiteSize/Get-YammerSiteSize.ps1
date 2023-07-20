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
    -Gets the amount of storage used for all Yammer-connected SharePoint Online sites
     
Author:
    Dean Cron

Version:
    1.0

Requirements:

    1. Admin account with M365 Groups and SPO access

.EXAMPLE
    .\Get-YammerSiteSize.ps1
#>

<############    STUFF YOU NEED TO MODIFY    ############>
#Change this to your admin site URL
$AdminSiteURL="https://tenant-admin.sharepoint.com"

#If you want the report to be output to a specific path, change the path below
$ReportOutput="c:\temp\YammerSPOStorage{0}.csv" -f [DateTime]::Now.ToString("yyyy-MM-dd_hh-mm-ss")

<############    YOU SHOULD NOT HAVE TO MODIFY ANYTHING BELOW THIS LINE    ############>
#Get Credentials
$Credential = Get-Credential
 
#Connect to SPO
Connect-SPOService -Credential $Credential -Url $AdminSiteURL
   
#Connect to ExO
Connect-ExchangeOnline -Credential $Credential -ShowBanner:$False

#Array to store Result
$ResultSet = @()

#Do the work
Write-Host "Gathering list of Yammer-connected SharePoint sites" -f Yellow
$yamSites = Get-UnifiedGroup -ResultSize Unlimited | ?{$_.GroupSku -eq "Yammer"} | Select -ExpandProperty SharePointSiteURL

foreach($yamSite in $yamSites)
{
    $Result = new-object PSObject
    $spoSite = Get-SPOSite $yamSite | Select Title, Url, StorageUsageCurrent
    Write-Host "Processing Site Collection :"$spoSite.URL -f Yellow
    $Result | add-member -membertype NoteProperty -name "SiteTitle" -Value $spoSite.Title
    $Result | add-member -membertype NoteProperty -name "SiteURL" -Value $spoSite.URL
    $Result | add-member -membertype NoteProperty -name "Used" -Value $spoSite.StorageUsageCurrent
    $ResultSet += $Result
}

#Export Result to csv file
$ResultSet |  Export-Csv $ReportOutput -notypeinformation
 
Write-Host "Report created successfully. See $ReportOutput" -f Green
