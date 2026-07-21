<#

.SYNOPSIS
  Name: Get-FullTeamsReport.ps1
  The purpose of this script is to report all teams, channels, and users that exists in an environment

.Requirements
MicrosoftTeams PowerShell Module

.PARAMETER ReportName
  The file path that the user wishes to contain the final report

.OUTPUTS
Exports data into an html file named according to the ReportName parameter


.EXAMPLE
  .\Get-FullTeamsReport.ps1 -ReportName 'MyReport'

#>

param(

	[Parameter(Mandatory=$true,
	HelpMessage="Please enter a name for this Report",
	ValueFromPipeline=$false)]
	$ReportName
)

    try
    {

    Import-Module MicrosoftTeams -ErrorAction Stop

    }
    catch
    {

    
    Start-Process -FilePath "powershell" -Verb runas -ArgumentList "Install-Module MicrosoftTeams -Force -AllowClobber;" -Wait 
    Import-Module MicrosoftTeams

    }

$allGroups = @()

$creds = Get-Credential

$Session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $creds -Authentication Basic -AllowRedirection


$allGroups = Invoke-Command -ScriptBlock {Get-UnifiedGroup -ResultSize Unlimited} -Session $Session365 

Remove-PSSession -Session $Session365


Connect-MicrosoftTeams -Credential $creds


$allChannels = @()
$allMembers = @()
$allOwners = @()
$allGuests = @()
$allInfo = @()




foreach($team in $allGroups)
{

try
{

$channelNames = ""
$memberNames = ""
$ownerNames = ""
$guestsNames = ""

$allChannels = Get-TeamChannel -GroupId $($team.ExternalDirectoryObjectId) 

foreach($channel in $allChannels)
{
$channelNames += $channel.DisplayName + ","
}

$allMembers = Get-TeamUser -GroupId $($team.ExternalDirectoryObjectId) -Role Member 

foreach($members in $allMembers)
{
$memberNames += $members.User + ","
}

$allOwners = Get-TeamUser -GroupId $($team.ExternalDirectoryObjectId) -Role Owner 

foreach($owner in $allOwners)
{
$ownerNames += $owner.User + ","
}

$allGuests = Get-TeamUser -GroupId $($team.ExternalDirectoryObjectId) -Role Guest 

foreach($guest in $allGuests)
{
$guestsNames += $guest.User + ","
}

$object = New-Object -TypeName PSObject

Add-Member -InputObject $object -MemberType NoteProperty -Name TeamName -Value $($team.DisplayName)
Add-Member -InputObject $object -MemberType NoteProperty -Name channels -Value $channelNames
Add-Member -InputObject $object -MemberType NoteProperty -Name members -Value $memberNames
Add-Member -InputObject $object -MemberType NoteProperty -Name owners -Value $ownerNames
Add-Member -InputObject $object -MemberType NoteProperty -Name guests -Value $guestsNames

$allInfo += $object
}
catch
{
$result = $_.Exception.Message.toString()

if($result -match "AccessDenied")
{

$object = New-Object -TypeName PSObject

Add-Member -InputObject $object -MemberType NoteProperty -Name TeamName -Value $($team.DisplayName)
Add-Member -InputObject $object -MemberType NoteProperty -Name channels -Value "Access Forbidden"
Add-Member -InputObject $object -MemberType NoteProperty -Name members -Value "Access Forbidden"
Add-Member -InputObject $object -MemberType NoteProperty -Name owners -Value "Access Forbidden"
Add-Member -InputObject $object -MemberType NoteProperty -Name guests -Value "Access Forbidden"

$allInfo += $object
}


}
}

$head = @"
<Title></Title>
<Style>
table {
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

 td,  th {
    border: 1px solid #ddd;
    padding: 8px;
}

 tr:nth-child(even){background-color: #f2f2f2;}

 tr:hover {background-color: #ddd;}

 th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: #5558af;
    color: white;
}
</Style>

</script>
"@


$allInfo | ConvertTo-Html -Head $head | Out-File -FilePath "$ReportName.html" -Force


