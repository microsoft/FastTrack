cls
## ------------------------------------------
##
##Script: MigrationToTeamsDNSCheck
##Version: V1.6
##Author: Tiago Roxo
##Description: Powershell Script used to query Skype for Business hardcoded DNS's to all your Domains part of the tenant, help you detect your current configuration, and help you migrate the tenant Coexistance mode to TeamsOnly.
##
##Warning: Make sure you have the latest "MicrosoftTeams" module version installed - "Update-Module MicrosoftTeams".
##
## ------------------------------------------

#Variables
##############################################################################################
$warningflag = $false
$domainStatus = $null
$DomainsToCheck = @()
$DNSServer = 8.8.8.8
$DNSonline = "-> DNS Record is pointing to an Online environment:"
$DNSOnPremises = "-> DNS Record is NOT pointing to Online environment: "
$DNSARecord = "-> DNS Record is pointing to an A record - unable to determine. Result: "
$DNSTXTRecord = "-> DNS Record is pointing to an TXT record. Result: "
$DNSTypeOther = "-> DNS Record type found :"
$DNSError = "DNS name does not exist"
##############################################################################################

##Function: Connection to Microsoft Teams
try{

Import-Module MicrosoftTeams
Connect-MicrosoftTeams
Read-Host -Prompt "Press enter to Start"
cls


#Function: Get the List of SIP Domains Enabled/Disabled
$domains = get-CsOnlineSipDomain

}catch{
    write-host "Problem loading Microsoft Teams Module - Make sure the Authentication is correct and make sure you latest version installed - https://www.powershellgallery.com/packages/MicrosoftTeams/2.0.0" -ForegroundColor Red
    $version = Get-Module MicrosoftTeams 
    exit
}

#Function: Start of the Script
write-host "-------------------------------------------------"
write-host $domains.Count "SIP Domains found in the tenant"
write-host "-------------------------------------------------"
write-host "-------------------------------------------------"
write-host "Checking Skype for Business hardcoded DNS Records:"
write-host "-------------------------------------------------"

Foreach($i in $domains)
{
    #Ignores the queries to the default O365 Domain
    if ($i.name.Contains("onmicrosoft.com")){
        write-host ""
        write-host "DOMAIN: " $i.name -BackgroundColoR Black -ForegroundColor White
        write-host $i.name "it's the default O365 domain from the tenant, does not require any validations."
    }
    
    #Checks the DNS records for all domains part of the O365 tenant
    else{
        write-host ""
        write-host "DOMAIN:" $i.name -BackgroundColoR Black -ForegroundColor White
        if ($i.Status -eq "Enabled"){
            write-host "SIP Domain Status: Enabled" -ForegroundColor Green
        }if ($i.Status -eq "Disabled"){
            write-host "SIP Domain Status: Disabled" -ForegroundColor Red
            $domainStatus = "true"  
        }if (($i.Status -ne "Disabled") -and ($i.Status -ne "Enabled")) {
            write-host "SIP Domain Status: Unknown" -ForegroundColor Yellow
            $domainStatus = "true"
        }

        #-------------------------------------
        #DNS QUERY: LYNCDISCOVER
        #-------------------------------------  
        $DNS_Lyncdiscover = "lyncdiscover."+$i.Name.ToString()
        $resolution = $null
        try{
            $resolution = Resolve-DnsName -Name $DNS_Lyncdiscover -type ALL -Server $DNSServer -DnsOnly -ErrorAction Stop | where Section -eq "Answer"
            Foreach($d in $resolution){
                if ($d.Type -eq "CNAME"){
                    if ($d.NameHost.ToString() -eq "webdir.online.lync.com"){
                        write-host $DNS_Lyncdiscover $DNSonline $d.NameHost
                    }
                    else{
                        write-host $DNS_Lyncdiscover $DNSOnPremises $d.NameHost -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                    }
                }
                if ($d.Type -eq "A"){
                        write-host $DNS_Lyncdiscover $DNSARecord $d.IPaddress -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                }
                if ($d.Type -eq "TXT"){
                        write-host $DNS_Lyncdiscover $DNSTXTRecord $d.Strings -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                }
                if (($d.Type -ne $null ) -and ($d.Type -ne "CNAME" ) -and ($d.Type -ne "A" ) -and ($d.Type -ne "TXT" )){
                    write-host $DNS_Lyncdiscover $DNSTypeOther $d.Type $d.Target -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
            }
        }catch{ 
            if ($Error[0].Exception.Message.Contains($DNSError)){
                write-host $DNS_Lyncdiscover "->" $DNSError -BackgroundColor Gray -ForegroundColor Black
            }
            else{
                write-host $Error[0].Exception.Message
            }
        }
        #-------------------------------------
        #DNS QUERY: SIP
        #-------------------------------------    
        $DNS_SIP = "sip."+$i.Name.ToString()
        $resolution = $null
         try{
            $resolution = Resolve-DnsName -Name $DNS_SIP -type ALL -Server $DNSServer -DnsOnly -ErrorAction Stop | where Section -eq "Answer"
            Foreach($d in $resolution){
                if ($d.Type -eq "CNAME"){
                    if ($d.NameHost.ToString() -eq "sipdir.online.lync.com")
                    {
                        write-host $DNS_SIP $DNSonline $d.NameHost
                    }
                    else{
                        write-host $DNS_SIP $DNSOnPremises $d.NameHost -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                    }
                }
                if ($d.Type -eq "A"){
                        write-host $DNS_SIP $DNSARecord $d.IPaddress -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                }
                if ($d.Type -eq "TXT"){
                        write-host $DNS_SIP $DNSTXTRecord $d.Strings -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                } 
                if (($d.Type -ne $null ) -and (($d.Type -ne "TXT") -and ($d.Type -ne "A") -and ($d.Type -ne "CNAME"))){
                    write-host $DNS_SIP $DNSTypeOther $d.Type  -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
            }
        }catch{ 
            if ($Error[0].Exception.Message.Contains($DNSError)){
                write-host $DNS_SIP "->" $DNSError -BackgroundColor Gray -ForegroundColor Black
            }
            else{
                write-host $Error[0].Exception.Message
            }  
        }
        #-------------------------------------
        #DNS QUERY: SRV SIPTLS
        #-------------------------------------  
        $DNS_SRVSIP = "_sip._tls."+$i.Name.ToString()
        $resolution = $null
        try{
            $resolution = Resolve-DnsName -Name $DNS_SRVSIP -Type ALL -Server $DNSServer -DnsOnly -ErrorAction Stop | where Section -eq "Answer"
            Foreach($d in $resolution){
                if ($d.Type -eq "SRV"){
                    if ($d.NameTarget.ToString() -eq "sipdir.online.lync.com"){
                        write-host $DNS_SRVSIP $DNSonline $d.NameTarget
                    }
                    else{
                        write-host $DNS_SRVSIP $DNSOnPremises $d.NameTarget -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                    }
                }
                if ($d.Type -eq "A"){
                    write-host $DNS_SRVSIP $DNSARecord $d.IPaddress -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
                if ($d.Type -eq "TXT"){
                    write-host $DNS_SRVSIP $DNSTXTRecord $d.Strings -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
                if (($d.Type -ne $null ) -and (($d.Type -ne "TXT") -and ($d.Type -ne "A") -and ($d.Type -ne "CNAME") -and ($d.Type -ne "SRV"))){
                    write-host $DNS_SRVSIP $DNSTypeOther $d.Type  -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
            }
        }catch{ 
            if ($Error[0].Exception.Message.Contains($DNSError)){
                write-host $DNS_SRVSIP "->" $DNSError -BackgroundColor Gray -ForegroundColor Black
            }
            else{
                write-host $Error[0].Exception.Message
            }  
        }
        #-------------------------------------
        #DNS QUERY: SRV SIPFED
        #-------------------------------------  
        $DNS_SRVSIPFED = "_sipfederationtls._tcp."+$i.Name.ToString()
        $resolution = $null
        try{
            $resolution = Resolve-DnsName -Name $DNS_SRVSIPFED -Type ALL -Server $DNSServer -DnsOnly -ErrorAction Stop | where Section -eq "Answer"
            Foreach($d in $resolution){
                if ($d.Type -eq "SRV"){
                    if ($d.NameTarget.ToString() -eq "sipfed.online.lync.com"){
                        write-host $DNS_SRVSIPFED $DNSonline $d.NameTarget
                    }
                    else{
                        write-host $DNS_SRVSIPFED $DNSOnPremises $d.NameTarget -BackgroundColor Yellow -ForegroundColor Black
                        $warningflag = $true
                        $DomainsToCheck += $i.Name.ToString()
                    }
                }
                if ($d.Type -eq "A"){
                    write-host $DNS_SRVSIPFED $DNSARecord $d.IPaddress -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
                if ($d.Type -eq "TXT"){
                    write-host $DNS_SRVSIPFED $DNSTXTRecord $d.Strings -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
                if (($d.Type -ne $null ) -and (($d.Type -ne "TXT") -and ($d.Type -ne "A") -and ($d.Type -ne "CNAME") -and ($d.Type -ne "SRV"))){
                    write-host $DNS_SRVSIPFED $DNSTypeOther $d.Type  -BackgroundColor Yellow -ForegroundColor Black
                    $warningflag = $true
                    $DomainsToCheck += $i.Name.ToString()
                }
            }
        }catch{ 
            if ($Error[0].Exception.Message.Contains($DNSError)){
                write-host $DNS_SRVSIPFED "->" $DNSError -BackgroundColor Gray -ForegroundColor Black
            }
            else{
                write-host $Error[0].Exception.Message
            }  
        }
        #-------------------------------------  
    }
}
     
if ($warningflag){
    $total = ($DomainsToCheck | sort -Unique).count
    write-host ""
    write-host "-------------------------------------------------"
    write-host "WARNINGS:" -BackgroundColor Yellow -ForegroundColor Black
    write-host $total "SIP Domains are requiring attention:"
    write-host "........."
    $DomainsToCheck | sort -Unique
    write-host "........."
    if ($domainStatus -eq "true"){
        write-host "SIP Domain Status: you have as well some SIP Domains that are in Disabled/Unknown Status. Check the above summary." -ForegroundColor Yellow
        }
    else{
        write-host "SIP Domain Status: All SIP Domains are in Enabled Status. Check the above summary." -ForegroundColor Green
    }
    write-host "........."
    write-host "This is normally caused when there are still an Skype for Business on-premises environment deployed or the DNS records are not properly configured."
    write-host "If you are planning to migrate to TeamsOnly mode, please make sure that all the DNS records are pointing to Online, or if you don't plan to use that Domain, delete the DNS records."
    write-host "For more details, see http://aka.ms/UpgradeToTeams"
    write-host "-------------------------------------------------"
} else{
    write-host ""
    write-host "-------------------------------------------------"
    write-host "200OK" -BackgroundColor DarkGreen
    write-host "The existing DNS records are currently poiting to the Online services."
    write-host "You can now migrate your tenant Coexistence mode to TeamsOnly Mode."
    write-host "-------------------------------------------------"
    }
Read-Host -Prompt "Press enter to Finish"
