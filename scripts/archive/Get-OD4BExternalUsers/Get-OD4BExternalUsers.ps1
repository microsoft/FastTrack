<#

.SYNOPSIS
  Name: Get-OD4BExternalUsers.ps1
  The purpose of this script is to search a tenant's OD4B sites
  for all files that are shared with external users. Once all of this data is found
  a csv report will be created.

.Requirements
SPO Powershell Module: https://www.microsoft.com/en-us/download/details.aspx?id=35588
SPO Client Components SDK: https://www.microsoft.com/en-us/download/details.aspx?id=42038 
SPO PnP Module: https://github.com/SharePoint/PnP-PowerShell/releases 


.PARAMETER rootSite
  The SharePoint Online root site url

.PARAMETER outputPath
  The file path that the user wishes to contain the final report
  
.OUTPUTS
Exports data into a csv named OD4BReportExternalUsers.csv


.EXAMPLE
  .\Get-OD4BExternalUser.ps1 -rootSite "https://myTenant.sharepoint.com/" -outputPath "c:\users\me\documents"


#>


param(

    [Parameter(Mandatory=$true,
	HelpMessage="Enter sharepoint root url",
	ValueFromPipeline=$false)]
	$rootSite,
    
    [Parameter(Mandatory=$true,
	HelpMessage="Enter file path to create CSV report in",
	ValueFromPipeline=$false)]
    [ValidateScript({ Test-Path $_ -PathType Container  })]
	$outputPath
)

#import SharePointPnPPowerShellOnline
#import SharePointSDK


    try
    {

    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
    Import-Module SharePointSDK -ErrorAction Stop

    }
    catch
    {

    
    Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber;" -Wait 
    Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module SharePointSDK -Force -AllowClobber;" -Wait 
    Import-Module SharePointPnPPowerShellOnline
    Import-Module SharePointSDK 

    }

$spcred = Get-Credential

$urls = @()

$OD4BSites = @()


Connect-PNPonline -Url "$($rootSite)" -Credentials $spcred 

$urls = Get-PnPTenantSite -IncludeOneDriveSites  -Detailed  

$allContentObjects = @()

foreach($url in $urls)
{


if($url.Url -match "personal")
{

try
{

Connect-PNPonline -Url "$($url.Url)" -Credentials $spcred



$allLists = Get-PnPList 

foreach($list in $allLists)
{


try
{

$items = Get-SPListItem -Credential $spcred -IsSharePointOnlineSite $true -ListName "$($list.Title)" -SiteUrl "$($url.Url)" 

}
catch
{

Write-Warning -Message "Warning Access to $($list.Title) was denied. Files from this list will not be scanned"

}

foreach($listItem in $items)
{

$userName = $listItem.SharedWithUsers.LookupValue 
$emailName = $listItem.SharedWithUsers.Email
$tenantName = $spcred.UserName.Split('@')[1]

if($userName -ne $null -and $emailName -notmatch $tenantName -and $userName -ne "Everyone except external users")
{

if($listItem.FileLeafRef.Contains('.'))
{

Write-Host "File $($listItem.FileLeafRef) shared with $username at $($listItem.FileRef)"

}
else
{

Write-Host "Folder $($listItem.FileLeafRef) shared with $username at $($listItem.FileRef)"

}


$object = New-Object –TypeName PSObject 
$object | Add-Member –MemberType NoteProperty –Name Name –Value $listItem.FileLeafRef 

if($emailName -ne "")
{

$object | Add-Member –MemberType NoteProperty –Name ExternalUser –Value " $emailName "
}
else
{

$object | Add-Member –MemberType NoteProperty –Name ExternalUser –Value " $username "
}


$object | Add-Member –MemberType NoteProperty –Name URL –Value $listItem.FileRef 




if($object -ne $null)
{
    $OD4BSites += $object

}
#endNullCheck

}
#endcheck

}
#enditemsloop

}
#endlistsloop

}
catch
{

Write-Warning -Message "Warning Access to $($url.Url) was denied. Files from this site will not be scanned"

}

}


}
#endsitesloop

$OD4Breport = $outputPath + "\OD4BReportExternalUsers.csv"

if((Test-Path -Path "$OD4Breport"))
{

$OD4BSites | Export-Csv -Path "$OD4Breport" -Force -NoTypeInformation

}
else
{

New-Item -Path "$OD4Breport" -ItemType file
$OD4BSites | Export-Csv -Path "$OD4Breport" -Force -NoTypeInformation
}


