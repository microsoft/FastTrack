<#
.Description
This Script function will help IT PROs find the Call Queues to which an specific Agent belongs.
The only needed detail is the “User Principal Name” (UPN) of the Agent.

Once you run the script, you will have to enter the UPN of the Agent, the outcome will give you the following details:
- How many Call Queues the users belongs;
- The details of the user (UPN/SIP/Phone)
- The details of the Call Queue (QQ Name/QQ ID) 
You can read the outcome of report on the screen/shell or you view it in a CSV file.

.Requirements
- This Script function needs MicrosoftTeams module installed in the latest build. You can install it by running "Install-module MicrosoftTeams" or update it by "Update-module Microsoft Teams";
- Administrator rights to Install/Uninstall Modules;
- Administrator rights in the tenant to list Teams Call Queue settings;
- You must set ExecutionPolicy to allow running the script. Example: Set-ExecutionPolicy -ExecutionPolicy Unrestricted

.PARAMETER: "AgentID"
- This parameter will determine the Agent ID that you want to search. You need to type the User Principal Name (UPN of the account)

.EXAMPLE:
- ".\Get-AgentCQFinder -AgentID tiago@contoso.com"

.Version: V1.0

.Author: Tiago Roxo

#> 

#FUNCTION PARAMS
param(
    [Parameter(Mandatory = $true,ParameterSetName='AgentID')] [string] $agentID
    )

#Connecting to Microsoft Teams
try{
    cls
    Write-Host "Connecting to Microsoft Teams" -BackgroundColor White -ForegroundColor Black
    Read-Host -Prompt "Press enter to Start"
    Import-Module MicrosoftTeams 
    Connect-MicrosoftTeams -LogLevel None  -InformationAction SilentlyContinue | Out-Null
    cls
}catch{
    write-host "Problem loading Microsoft Teams Module - Make sure the Authentication is correct and make sure you latest version installed - https://www.powershellgallery.com/packages/MicrosoftTeams" -ForegroundColor Red
    $version = Get-Module MicrosoftTeams 
    exit
}

Write-Host "Search for Agent:" $agentID -BackgroundColor White -ForegroundColor Black

#Variables
##############################################################################################
$filePath = "$($env:USERPROFILE)\Downloads\"
$fileName = "AgentCQFind_"+ (Get-Date).ToString('yyyy-MM-dd') +".csv"
$file = $filePath+$fileName
$users = @()


#MAGIC STARTS HERE
$cq = Get-CsCallQueue
$userID = Get-CsOnlineUser -Identity $agentID
foreach($i in $cq){
    foreach($user in $i.Agents){
        if ($user.ObjectId -eq $userID.identity)
            {
                $users += [PSCustomObject]@{
                UserPrincipalName = $userID.UserPrincipalName
                LineUri = $userID.LineUri
                SipAddress = $userID.SipAddress
                QueueName = $i.Name
                QueueID = $i.Identity
            }
        }
    }
}

if ($users){
    Write-Host "Agent found in" ($users).count "Call Queues." -BackgroundColor Green -ForegroundColor White
    Write-Host "---------------------------------"
    foreach ($u in $users){$u.QueueName + " - " + $u.Queueid }
    Write-Host "---------------------------------"
    Write-Host "Saving Report to CSV File: "$file -BackgroundColor Green -ForegroundColor White
    $users | Export-Csv $file -NoTypeInformation -Encoding UTF8 -Delimiter ";"
}else{Write-Host "User don't belong to any Call Queue" -BackgroundColor White -ForegroundColor Yellow}

Read-Host -Prompt "Press enter to Exit"
