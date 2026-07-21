<#

.SYNOPSIS
  Name: Get-FullOwnerReport.ps1
  This script looks for and reports all users and groups that have full control access for all sites and subsites
  in a user's tenant

.Requirements
SPO PnP Module: https://github.com/SharePoint/PnP-PowerShell/releases 

.PARAMETER rootSite
  The SharePoint Online root site url

.PARAMETER outputPath
  The file path that the user wishes to contain the final report


.OUTPUTS
Exports data into a csv named FullOwnersReport.csv

  
.EXAMPLE
  .\Get-FullOwnerReport.ps1 -rootSite "https://myTenant.sharepoint.com/" -outputPath "c:\users\me\documents"


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

    try
    {

    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop

    }
    catch
    {

    
    Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber;" -Wait
    Import-Module SharePointPnPPowerShellOnline

    }



$spcred = Get-Credential

$allSubSites = @()
$urls = @()

$allGroupSites = @()

Connect-PNPonline -Url "$($rootSite)" -Credentials $spcred 

$urls = Get-PnPTenantSite -Url "$rootSite"  -IncludeOneDriveSites  -Detailed


foreach($url in $urls)
{

try
{

Connect-PNPonline -Url "$($url.Url)" -Credentials $spcred -ErrorAction SilentlyContinue
$allSubSites += Get-PnPSubWebs -Recurse -ErrorAction SilentlyContinue

}
catch
{

Write-Warning -Message "Warning Access to $($url.Url) was denied."

}

}

$allSubSites += $urls

$allOwners = @()

foreach($url in $allSubSites)
{

try
{

Connect-PNPonline -Url "$($url.Url)" -Credentials $spcred -ErrorAction Stop

$owners  = Get-PnPGroup -ErrorAction Stop | where {$_.Title -match "Owners"} 


foreach($owner in $owners)
{

$allOwnerGroups  = Get-PnPGroupMembers -Identity "$($owner.Title)"
Write-Host "Accessing users of group $($owner.Title)"

foreach($lowerOwner in $allOwnerGroups)
{

Write-Host "User $($lowerOwner.LoginName) found as owner for site $($url.Url)"

$object = New-Object –TypeName PSObject
$object | Add-Member –MemberType NoteProperty –Name LoginName –Value $lowerOwner.LoginName
$object | Add-Member –MemberType NoteProperty –Name Email –Value $lowerOwner.Email
$object | Add-Member –MemberType NoteProperty –Name URL –Value "$($url.Url)"

$allOwners += $object

}


}

}
catch
{
Write-Warning -Message "Warning Access to $($url.Url) was denied."
}

}

$GroupReport = $outputPath + "\FullOwnersReport.csv"


if((Test-Path -Path "$GroupReport"))
{

$allOwners  | Export-Csv -Path "$GroupReport" -Force -NoTypeInformation

}
else
{

New-Item -Path "$GroupReport" -ItemType file
$allOwners  | Export-Csv -Path "$GroupReport" -Force -NoTypeInformation

}