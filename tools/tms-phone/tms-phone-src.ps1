# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# AUTHOR: Mihai Filip
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# Dependencies: MSOnline, MicrosoftTeams
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# USAGE: 
# .\tms-phone-src.ps1
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# FOR DEBUGGING N PROD
$ErrorActionPreference = "SilentlyContinue"

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----FUNC
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
function Get-OfficeUserLicense {
    param (
        [string]$UserPrincipalName
    )
  
  
    $SKUs = (Get-MsolUser -UserPrincipalName $UserPrincipalName).Licenses.AccountSkuId
    $ServicePlans = (Get-MsolUser -UserPrincipalName $UserPrincipalName).Licenses.ServiceStatus.ServicePlan.ServiceName
  
    $licenses = @{
        isLicensed   = (Get-MsolUser -UserPrincipalName $UserPrincipalName).isLicensed
        SKU          = @()
        ServicePlans = ''
    }
  
    if ($SKUs.length -gt 1) {
        foreach ($SKU in $SKUs) {
            $licenses.SKU += $SKU.split(":")[1]
        }
    }
    else {
        try {
            $licenses.SKU += $SKUs.split(":")[1]
        }
        catch {} # exception if user is unlicensed
    }
  
    $licenses.ServicePlans = $ServicePlans
  
    return $licenses
}

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----UI
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

Add-Type -AssemblyName PresentationCore, PresentationFramework

$Xaml = @"
<Window xmlns:syncfusion="http://schemas.syncfusion.com/wpf"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Name="MainWindow" Title="TMS-PHONE" Background="#181B40" WindowStartupLocation="
CenterScreen" ResizeMode="CanResizeWithGrip" FontFamily="Segoe UI" Height="844" Width="1262" BorderThickness="1" BorderBrush="#353A7A" AllowsTransparency="True" WindowStyle="None">

    <Grid>
        <DockPanel VerticalAlignment="Top" Height="580">

            <DockPanel Name="TitleBar" DockPanel.Dock="Top" Background="#181B40" Height="24">

                <TextBlock Name="Title" Margin="7,0,0,0" HorizontalAlignment="Left" VerticalAlignment="Center" Background="#181B40" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold">
                    TMS-PHONE v1.0
                </TextBlock>

                <Button Name="btnCloseScreen" HorizontalAlignment="Right" VerticalAlignment="Center" BorderThickness="0" Height="20" Width="208" Cursor="Hand">

                    <Button.Template>
                        <ControlTemplate>
                            <Image Name="imgClose" Margin="0,0,5,0" Source="https://i.postimg.cc/G2xkjsq0/close.png" Height="14" Width="14" HorizontalAlignment="Right" VerticalAlignment="Center" ToolTip="Quit"/>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

            </DockPanel>

            <StackPanel Name="stackAuth">
                <Grid Name="grdLogo">
                    <Border BorderThickness="0" BorderBrush="#353A7A">
                        <StackPanel>
                            <Image Name="Logo" Source="https://i.postimg.cc/wvK98CQg/Frame-7-1.png" HorizontalAlignment="Center" VerticalAlignment="Top" Width="200" Height="200"></Image>
                        </StackPanel>
                    </Border>
                </Grid>

                <Grid Name="grdAuthFields">
                    <Border BorderThickness="0" BorderBrush="#353A7A">
                        <StackPanel>
                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0">Username:</Label>
                            <TextBox Name="txtUsername" Padding="5" Margin="15,5,15,5"></TextBox>
                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0">Password:</Label>
                            <PasswordBox Name="txtPassword" Padding="5" Margin="15,5,15,5"></PasswordBox>
                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0" HorizontalAlignment="Center">_______________________________________________________</Label>
                            <PasswordBox Name="txtClientId" Padding="5" Margin="15,5,15,5" Visibility="Hidden"></PasswordBox>
                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0" Visibility="Hidden">Client secret:</Label>
                            <PasswordBox Name="txtClientSecret" Padding="5" Margin="15,5,15,5" Visibility="Hidden"></PasswordBox>
                            <Button Name="btnSignIn" Content="Connect" Padding="5" Margin="5, 20, 5, 10" Width="150" Cursor="Hand"></Button>
                        </StackPanel>
                    </Border>
                </Grid>

                <Grid Name="grdAuthStatus">
                    <Label Name="lblAuthStatus" Content="" HorizontalAlignment="Center" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Background="#181B40"></Label>
                </Grid>

                <Grid Name="grdApp" Visibility="Hidden">
                    <Border BorderThickness="0" BorderBrush="#353A7A">
                        <DockPanel>
                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                                    <Grid Name="grdNav" HorizontalAlignment="Left" Width="180">
                                        <StackPanel>
                                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                                <Label Name="lblDialPad" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#181B40" Padding="7">Dial Pad</Label>
                                            </Border>
                                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                                <Label Name="lblForwarding" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#181B40" Padding="7">Forwarding</Label>
                                            </Border>
                                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                                <Label Name="lblAutoAttendant" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#181B40" Padding="7">Auto Attendant</Label>
                                            </Border>
                                        </StackPanel>
                                    </Grid>
                                </ScrollViewer>
                            </Border>

                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                <Grid Name="grdActivity" HorizontalAlignment="Right" Background="#353A7A" Width="620">
                                        <Grid Name="grdDialPad" Margin="10,10,10,10">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Voice \ Dial pad missing</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtDPUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnDPRun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtDPOutput" Margin="5,10,5,0" Height="330" IsReadOnly="True" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF" VerticalScrollBarVisibility="Auto"  ></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdForwarding" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Voice \ Cannot forward to number</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtFWUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">Phone number:</Label>
                                            <TextBox Name="txtFWPhoneNumber" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnFWRun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtFWOutput" Margin="5,10,5,0" Height="261" IsReadOnly="True" TextWrapping="Wrap" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdAutoAttendant" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Voice \ Auto attendant is not receiving calls</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtAAUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnAARun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtAAOutput" Margin="5,10,5,0" Height="330" IsReadOnly="True" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                </Grid>
                            </Border>
                        </DockPanel>
                    </Border>

                    <DockPanel Margin="0,531,0,0" Background="#181B40" Height="24">

                        <TextBlock Name="txtSignedInUser" Margin="7,0,0,0" HorizontalAlignment="Center" VerticalAlignment="Center" Background="#181B40" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="11">
                            Signed in as: user@domain.com
                        </TextBlock>

                    </DockPanel>
                </Grid>
            </StackPanel>

        </DockPanel>
    </Grid>
</Window>
"@

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Handlers and Logic
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

$Window.Width = 400
$Window.Height = 580
$Window.ResizeMode = 'NoResize'

$lblDialPad.Background = '#353A7A'


$btnCloseScreen.Add_Click({
        $Window.Close()

        Start-Sleep -s 3

        # Disconnect-AzureAD
        Write-Host "Disconnecting from Microsoft Teams PowerShell..."
        Disconnect-MicrosoftTeams
        Write-Host "Disconnecting from MSO PowerShell..."
        [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
    })

$TitleBar.Add_MouseDown({
        $Window.DragMove()
    })

$lblDialPad.Add_MouseEnter({
        $lblDialPad.Background = '#353A7A'
    })

$lblDialPad.Add_MouseLeave({
        if ($grdDialPad.Visibility -eq 'Visible') {
            $lblDialPad.Background = '#353A7A'
        }
        else {
            $lblDialPad.Background = '#181B40'
        }
    })

$lblAutoAttendant.Add_MouseEnter({
        $lblAutoAttendant.Background = '#353A7A'
    })

$lblAutoAttendant.Add_MouseLeave({
        if ($grdAutoAttendant.Visibility -eq 'Visible') {
            $lblAutoAttendant.Background = '#353A7A'
        }
        else {
            $lblAutoAttendant.Background = '#181B40'
        }
    })

$lblAutoAttendant.Add_MouseLeftButtonUp({
        $grdForwarding.Visibility = 'Hidden'
        $grdDialPad.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Visible'
        $lblForwarding.Background = '#181B40'
        $lblDialPad.Background = '#181B40'
    })

$lblDialPad.Add_MouseLeftButtonUp({
        $grdForwarding.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Hidden'
        $grdDialPad.Visibility = 'Visible'
        $lblForwarding.Background = '#181B40'
        $lblAutoAttendant.Background = '#181B40'
    })

$lblForwarding.Add_MouseEnter({
        $lblForwarding.Background = '#353A7A'
    })

$lblForwarding.Add_MouseLeave({
        if ($grdForwarding.Visibility -eq 'Visible') {
            $lblForwarding.Background = '#353A7A'
        }
        else {
            $lblForwarding.Background = '#181B40'
        }
    })

$lblForwarding.Add_MouseLeftButtonUp({
        $grdDialPad.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Hidden'
        $grdForwarding.Visibility = 'Visible'
        $lblDialPad.Background = '#181B40'
        $lblAutoAttendant.Background = '#181B40'
    })

$btnSignIn.Add_Click({
        if (!($txtUsername.Text) -OR !($txtPassword.Password)) {
            Write-Host 'INCORRECT USERNAME AND/OR PASSWORD'
            $lblAuthStatus.Foreground = "Salmon"
            $lblAuthStatus.Content = "INCORRECT USERNAME AND/OR PASSWORD"
            return
        }

        $Username = $txtUsername.Text
        $Password = ConvertTo-SecureString $txtPassword.Password -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

        # AzureADPreview\Connect-AzureAD -Credential $Credentials

        # $usr = Get-AzureADUser -ObjectId $Username

        Write-Host "Connecting to Microsoft Teams PowerShell..."
        Connect-MicrosoftTeams -Credential $Credentials
        Write-Host "Connecting to MSO PowerShell..."
        Connect-MsolService -Credential $Credentials

        $usr = Get-MsolUser -UserPrincipalName $Username
        $tmsUsr = Get-CsOnlineUser -Identity $Username

        if ($usr) {
            Write-Host -ForegroundColor Green 'MSO AUTH VALID.'
            $lblAuthStatus.Foreground = "#BDF2D5"
            $lblAuthStatus.Content = "MSO AUTH SUCCESSFUL"

            if ($tmsUsr) {
                Write-Host -ForegroundColor Green 'TMS AUTH VALID.'
                $lblAuthStatus.Foreground = "#BDF2D5"
                $lblAuthStatus.Content = "TMS AUTH SUCCESSFUL"
                $grdLogo.Visibility = 'Hidden'
                $grdAuthFields.Visibility = 'Hidden'
                $grdAuthStatus.Visibility = 'Hidden'
                $Window.Width = 800
                $Window.Left -= 200
                $grdApp.VerticalAlignment = 'Top'
                $grdApp.Margin = '0,-540,0,0'
                $grdApp.Height = 554
                $grdApp.Visibility = 'Visible'
                $txtSignedInUser.Text = "Signed in as: $($Username)"
            }
            else {
                Write-Host -ForegroundColor Red 'TMS AUTH FAILED.'
                $lblAuthStatus.Foreground = "Salmon"
                $lblAuthStatus.Content = "TMS AUTH FAILED"
            }
        }
        else {
            Write-Host -ForegroundColor Red 'MSO AUTH FAILED.'
            $lblAuthStatus.Foreground = "Salmon"
            $lblAuthStatus.Content = "MSO AUTH FAILED"

            # AUTH BYPASS FOR DEBUG
            # $grdLogo.Visibility = 'Hidden'
            # $grdAuthFields.Visibility = 'Hidden'
            # $grdAuthStatus.Visibility = 'Hidden'
            # $Window.Width = 800
            # $Window.Left -= 200
            # $grdApp.VerticalAlignment = 'Top'
            # $grdApp.Margin = '0,-540,0,0'
            # $grdApp.Height = 554
            # $grdApp.Visibility = 'Visible'
            # $txtSignedInUser.Text = "Signed in as: $($Username)"

        }
    })

$btnDPRun.Add_Click({
        $txtDPOutput.Foreground = "White"
        $txtDPOutput.Text = ''

        if (!$txtDPUPN.Text) {
            $txtDPOutput.Foreground = "Salmon"
            $txtDPOutput.Text += "---------------------------------`n"
            $txtDPOutput.Text += "FAILURE`n"
            $txtDPOutput.Text += "---------------------------------`n"
            $txtDPOutput.Text += "Please provide a valid User Principal Name and try again.`n"
            return
        }

        $user = Get-CsOnlineUser -Identity $txtDPUPN.Text
        $txtDPOutput.Text += "---------------------------------`n"
        $txtDPOutput.Text += "USER VALIDATION`n"
        $txtDPOutput.Text += "---------------------------------`n"

        if ($user) {
            $txtDPOutput.Text += "The user was found in the directory.`n"
            $txtDPOutput.Text += "Checking the user's licenses:`n"
            $userLicense = Get-OfficeUserLicense $txtDPUPN.Text
            if ($userLicense) {
                $txtDPOutput.Text += "The user is licensed.`n"
                $txtDPOutput.Text += "Checking if the user is appropriately licensed for Teams Phone (TEAMS1, MCOSTANDARD, MCOEV):`n"
                if (($userLicense.ServicePlans -contains 'TEAMS1') -AND ($userLicense.ServicePlans -contains 'MCOSTANDARD') -AND ($userLicense.ServicePlans -contains 'MCOEV')) {
                    $txtDPOutput.Text += "The user is licensed appropriately for Teams Phone.`n"
                    $txtDPOutput.Text += "Checking if the user is SIP enabled:`n"
                    if ($user.isSipEnabled) {
                        $txtDPOutput.Text += "The user is SIP enabled.`n"
                        $txtDPOutput.Text += "Checking if the user is hoped online:`n"
                        if ($user.HostingProvider -eq 'sipfed.online.lync.com') {
                            $txtDPOutput.Text += "The user is homed online.`n"
                            $txtDPOutput.Text += "Checking if the user is set up for TeamsOnly:`n"
                            if ($user.TeamsUpgradeEffectiveMode -eq 'TeamsOnly') {
                                $txtDPOutput.Text += "The user is set up for TeamsOnly.`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                $txtDPOutput.Text += "VOICE VALIDATION`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                $txtDPOutput.Text += "Checking if the user is Enterprise Voice enabled`n"
                                if ($user.EnterpriseVoiceEnabled) {
                                    $txtDPOutput.Text += "The user is Enterprise Voice enabled.`n"
                                    $txtDPOutput.Text += "Checking if the user is assigned a Teams calling policy that allows private calling:`n"
                                    $callingPolicyName = $user.TeamsCallingPolicy.Name
                                    if ($callingPolicyName -eq $null) {
                                        $callingPolicyName = 'Global'
                                    }
                                    $callingPolicy = (Get-CsTeamsCallingPolicy -Identity $callingPolicyName)
                                    if ($callingPolicy.AllowPrivateCalling) {
                                        $txtDPOutput.Text += "The user is assigned a Teams calling policy that allows private calling.`n"
                                        $txtDPOutput.Text += "Checking if the user is a Calling Plan or Direct Routing user:`n"
                                        $PSTNType = ((Get-CsOnlineVoiceUser -Identity $txtDPUPN.Text).PSTNConnectivity | Out-String).trim()
                                        if ($PSTNType -eq 'Online') {
                                            $txtDPOutput.Text += "The user is a Calling Plan user.`n"
                                            $txtDPOutput.Text += "Checking if the user has a phone number assigned:`n"
                                            if ($user.LineUri) {
                                                $txtDPOutput.Foreground = "#BDF2D5"
                                                $txtDPOutput.Text += "The user has a phone number assigned.`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                $txtDPOutput.Text += "SUCCESS`n"
                                                $txtDPOutput.Text += "---------------------------------"
                                            }
                                            else {
                                                $txtDPOutput.Foreground = "Salmon"
                                                $txtDPOutput.Text += "The user does not have a phone number assigned.`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                $txtDPOutput.Text += "FAILURE`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                return
                                            }
                                        }
                                        elseif ($PSTNType -eq 'OnPremises') {
                                            $txtDPOutput.Text += "The user is a Direct Routing user.`n"
                                            $txtDPOutput.Text += "Checking if the user has a phone number assigned:`n"
                                            if ($user.LineUri) {
                                                $txtDPOutput.Text += "The user has a phone number assigned.`n"
                                                $txtDPOutput.Text += "Checking if the user's voice routing policy has a gateway route:`n"
                                                $voiceRoutingPolicy = $user.OnlineVoiceRoutingPolicy.Name

                                                if ($voiceRoutingPolicy -eq $null) {
                                                    $voiceRoutingPolicy = 'Global'
                                                }

                                                $pstnUsageName = ((Get-CsOnlineVoiceRoutingPolicy -Identity $voiceRoutingPolicy).OnlinePstnUsages | Out-String).trim()
                                                $voiceRoute = (Get-CsOnlineVoiceRoute | Where-Object { $_.OnlinePstnUsages -contains $pstnUsageName })

                                                if ($voiceRoute.OnlinePstnGatewayList) {
                                                    $txtDPOutput.Foreground = "#BDF2D5"
                                                    $txtDPOutput.Text += "The user's voice routing policy has a gateway route.`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "SUCCESS`n"
                                                    $txtDPOutput.Text += "---------------------------------"
                                                }
                                                else {
                                                    $txtDPOutput.Foreground = "Salmon"
                                                    $txtDPOutput.Text += "The user's voice routing policy does not have a gateway route.`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "FAILURE`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    return
                                                }

                                            }
                                            else {
                                                $txtDPOutput.Foreground = "Salmon"
                                                $txtDPOutput.Text += "The user does not have a phone number assigned.`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                $txtDPOutput.Text += "FAILURE`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                return
                                            }
                                        }
                                    }
                                    else {
                                        $txtDPOutput.Foreground = "Salmon"
                                        $txtDPOutput.Text += "The user is assigned a Teams calling policy that doesn't allow private calling.`n"
                                        $txtDPOutput.Text += "---------------------------------`n"
                                        $txtDPOutput.Text += "FAILURE`n"
                                        $txtDPOutput.Text += "---------------------------------`n"
                                        return
                                    }
                                }
                                else {
                                    $txtDPOutput.Foreground = "Salmon"
                                    $txtDPOutput.Text += "The user is not Enterprise Voice enabled.`n"
                                    $txtDPOutput.Text += "---------------------------------`n"
                                    $txtDPOutput.Text += "FAILURE`n"
                                    $txtDPOutput.Text += "---------------------------------`n"
                                    return
                                }
                            }
                            else {
                                $txtDPOutput.Foreground = "Salmon"
                                $txtDPOutput.Text += "The user is not set up for TeamsOnly.`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                $txtDPOutput.Text += "FAILURE`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                return
                            }
                        }
                        else {
                            $txtDPOutput.Foreground = "Salmon"
                            $txtDPOutput.Text += "The user is not homed online.`n"
                            $txtDPOutput.Text += "---------------------------------`n"
                            $txtDPOutput.Text += "FAILURE`n"
                            $txtDPOutput.Text += "---------------------------------`n"
                            return
                        }
                    }
                    else {
                        $txtDPOutput.Foreground = "Salmon"
                        $txtDPOutput.Text += "The user is not SIP enabled.`n"
                        $txtDPOutput.Text += "---------------------------------`n"
                        $txtDPOutput.Text += "FAILURE`n"
                        $txtDPOutput.Text += "---------------------------------`n"
                        return
                    }
                }
                else {
                    $txtDPOutput.Foreground = "Salmon"
                    $txtDPOutput.Text += "The user is missing one of the following licenses: TEAMS1, MCOSTANDARD, MCOEV.`n"
                    $txtDPOutput.Text += "---------------------------------`n"
                    $txtDPOutput.Text += "FAILURE`n"
                    $txtDPOutput.Text += "---------------------------------`n"
                    return
                }
            }
            else {
                $txtDPOutput.Foreground = "Salmon"
                $txtDPOutput.Text += "The user is not licensed.`n"
                $txtDPOutput.Text += "---------------------------------`n"
                $txtDPOutput.Text += "FAILURE`n"
                $txtDPOutput.Text += "---------------------------------`n"
                return
            }
        }
        else {
            $txtDPOutput.Foreground = "Salmon"
            $txtDPOutput.Text += "The user was not found in the directory. Please check the User Principal Name and try again.`n"
            $txtDPOutput.Text += "---------------------------------`n"
            $txtDPOutput.Text += "FAILURE`n"
            $txtDPOutput.Text += "---------------------------------`n"
            return 
        }

    })

$btnFWRun.Add_Click({
        $txtFWOutput.Foreground = "White"
        $txtFWOutput.Text = ''

        $txtFWOutput.Text += "---------------------------------`n"
        $txtFWOutput.Text += "DISCLAIMER`n"
        $txtFWOutput.Text += "---------------------------------`n"
        $txtFWOutput.Text += "This diagnostic assumes that you have run the Dial Pad diagnostic to first validate the user is properly set for Teams Phone.`n"

        $txtFWOutput.Text += "---------------------------------`n"
        $txtFWOutput.Text += "FORWARDING SETTINGS`n"
        $txtFWOutput.Text += "---------------------------------`n"
        $txtFWOutput.Text += "Checking if call forwarding is enabled for the user:`n"
        $callingSettings = (Get-CsUserCallingSettings -Identity $txtFWUPN.Text)
        if ($callingSettings.IsForwardingEnabled) {
            $txtFWOutput.Text += "Call forwarding is enabled for the user.`n"
            $txtFWOutput.Text += "Checking if the forwarding target matches the provided phone number:`n"
            if ($callingSettings.ForwardingTarget -eq $txtFWPhoneNumber.Text) {
                $txtFWOutput.Text += "The forwarding target matches the provided phone number.`n"
                $txtFWOutput.Text += "---------------------------------`n"
                $txtFWOutput.Text += "SUCCESS`n"
                $txtFWOutput.Text += "---------------------------------`n"
                $txtFWOutput.Foreground = "#BDF2D5"
            }
            else {
                $txtFWOutput.Foreground = "Salmon"
                $txtFWOutput.Text += "The forwarding target does not match the provided phone number.`n"
                $txtFWOutput.Text += "---------------------------------`n"
                $txtFWOutput.Text += "FAILURE`n"
                $txtFWOutput.Text += "---------------------------------`n"
                return
            }
        }
        elseif (!$callingSettings.IsForwardingEnabled) {
            $txtFWOutput.Foreground = "Salmon"
            $txtFWOutput.Text += "Call forwarding is not enabled for the user.`n"
            $txtFWOutput.Text += "---------------------------------`n"
            $txtFWOutput.Text += "FAILURE`n"
            $txtFWOutput.Text += "---------------------------------`n"
            return
        }
        else {
            $txtFWOutput.Foreground = "Salmon"
            $txtFWOutput.Text += "Something went wrong when trying to retrieve  the user's calling settings.`n"
            $txtFWOutput.Text += "---------------------------------`n"
            $txtFWOutput.Text += "FAILURE`n"
            $txtFWOutput.Text += "---------------------------------`n"
            return
        }

    })

$btnAARun.Add_Click({
        $txtAAOutput.Foreground = "White"
        $txtAAOutput.Text = ""

        $txtAAOutput.Text += "---------------------------------`n"
        $txtAAOutput.Text += "RESOURCE ACCOUNT`n"
        $txtAAOutput.Text += "---------------------------------`n"
        $ra = (Get-MsolUser -UserPrincipalName $txtAAUPN.Text)

        if ($ra) {
            $txtAAOutput.Text += "The resource account exists`n"

            $txtAAOutput.Text += "Checking if the resource account is licensed:`n"
            $raLicense = Get-OfficeUserLicense $txtAAUPN.Text

            if ($raLicense.isLicensed) {
                $txtAAOutput.Text += "The resource account is licensed.`n"

                $txtAAOutput.Text += "Checking if the resource account is assigned a Teams Phone  Resource Account license:`n"

                if ($raLicense.ServicePlans -contains 'MCOEV_VIRTUALUSER') {
                    $txtAAOutput.Text += "The resource account is assigned a Teams Phone Resource Account license.`n"

                    $txtAAOutput.Text += "Checking if the resource account is enabled:`n"

                    if ($ra.BlockCredential) {
                        $txtAAOutput.Text += "The resource account is not enabled.`n"

                        $txtAAOutput.Text += "Checking if the Department property is valid:`n"

                        if ($ra.Department -eq 'Microsoft Communication Application Instance') {
                            $txtAAOutput.Text += "The Department property is valid.`n"

                            $txtAAOutput.Text += "Checking if there is a SIP address set:`n"

                            $tmsRa = (Get-CsOnlineUser $txtAAUPN.Text)

                            if ($tmsRa.SipAddress -eq $null) {
                                $txtAAOutput.Text += "There is no SIP address set.`n"

                                $txtAAOutput.Text += "Checking if there is a phone number assigned:`n"

                                if ($tmsRa.lineUri) {
                                    $txtAAOutput.Text += "There is a phone number assigned.`n"

                                    $txtAAOutput.Text += "---------------------------------`n"
                                    $txtAAOutput.Text += "SUCCESS`n"
                                    $txtAAOutput.Text += "---------------------------------`n"
                                    $txtAAOutput.Foreground = "#BDF2D5"
                                }
                                else {
                                    $txtAAOutput.Foreground = "Salmon"
                                    $txtAAOutput.Text += "There is no phone number assigned.`n"
                                    $txtAAOutput.Text += "---------------------------------`n"
                                    $txtAAOutput.Text += "FAILURE`n"
                                    $txtAAOutput.Text += "---------------------------------`n"
                                    return
                                }
                            }
                            else {
                                $txtAAOutput.Foreground = "Salmon"
                                $txtAAOutput.Text += "There is a SIP address set.`n"
                                $txtAAOutput.Text += "---------------------------------`n"
                                $txtAAOutput.Text += "FAILURE`n"
                                $txtAAOutput.Text += "---------------------------------`n"
                                return
                            }
                        }
                        else {
                            $txtAAOutput.Foreground = "Salmon"
                            $txtAAOutput.Text += "The Department property is not valid.`n"
                            $txtAAOutput.Text += "---------------------------------`n"
                            $txtAAOutput.Text += "FAILURE`n"
                            $txtAAOutput.Text += "---------------------------------`n"
                            return
                        }
                    }
                    else {
                        $txtAAOutput.Foreground = "Salmon"
                        $txtAAOutput.Text += "The resource account is enabled.`n"
                        $txtAAOutput.Text += "---------------------------------`n"
                        $txtAAOutput.Text += "FAILURE`n"
                        $txtAAOutput.Text += "---------------------------------`n"
                        return
                    }
                }
                else {
                    $txtAAOutput.Foreground = "Salmon"
                    $txtAAOutput.Text += "The resource account is not assigned a Teams Phone Resource Account license.`n"
                    $txtAAOutput.Text += "---------------------------------`n"
                    $txtAAOutput.Text += "FAILURE`n"
                    $txtAAOutput.Text += "---------------------------------`n"
                    return
                }
            }
            else {
                $txtAAOutput.Foreground = "Salmon"
                $txtAAOutput.Text += "The resource account is not licensed.`n"
                $txtAAOutput.Text += "---------------------------------`n"
                $txtAAOutput.Text += "FAILURE`n"
                $txtAAOutput.Text += "---------------------------------`n"
                return
            }
        }
        else {
            $txtAAOutput.Foreground = "Salmon"
            $txtAAOutput.Text += "The resource account does not exist in the directory.`n"
            $txtAAOutput.Text += "---------------------------------`n"
            $txtAAOutput.Text += "FAILURE`n"
            $txtAAOutput.Text += "---------------------------------`n"
            return
        }

    })

$Window.ShowDialog()
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----END
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #