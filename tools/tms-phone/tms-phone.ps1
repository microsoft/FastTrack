# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# AUTHOR: Mihai Filip
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# Dependencies: MicrosoftTeams
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# USAGE: 
# .\tms-phone-src.ps1
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# FOR DEBUGGING N PROD
$ErrorActionPreference = "SilentlyContinue"

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----FUNC
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

function Get-UserAssignedPlans {
    param (
        [string]$UserPrincipalName
    )

    $AssignedPlans = (Get-CsOnlineUser $UserPrincipalName).AssignedPlan

    return $AssignedPlans
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
                                                <Label Name="lblAutoAttendant" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#181B40" Padding="7">Resource Account</Label>
                                            </Border>
                                            <Border BorderThickness="0" BorderBrush="#FFFFFF">
                                                <Label Name="lblUserValidationErrors" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#181B40" Padding="7">User Validation Errors</Label>
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
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Dial pad missing</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtDPUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnDPRun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtDPOutput" Margin="5,10,5,0" Height="330" IsReadOnly="True" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF" VerticalScrollBarVisibility="Auto"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdForwarding" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Cannot forward to number</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtFWUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">Phone number:</Label>
                                            <TextBox Name="txtFWPhoneNumber" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnFWRun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtFWOutput" Margin="5,10,5,0" Height="261" IsReadOnly="True" TextWrapping="Wrap" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF" VerticalScrollBarVisibility="Auto"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdAutoAttendant" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">(AA/CQ) Resource account is not receiving calls</Label>
                                            </Border>
                                            <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">User Principal Name:</Label>
                                            <TextBox Name="txtAAUPN" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnAARun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtAAOutput" Margin="5,10,5,0" Height="330" IsReadOnly="True" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF" VerticalScrollBarVisibility="Auto"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdUserValidationErrors" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#FFFFFF" Padding="5" Margin="5">
                                                <Label Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Find users with validation errors</Label>
                                            </Border>
                                            <CheckBox Name="chkUVECSV" Content="CSV" Foreground="#FFFFFF" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,5,0,0"></CheckBox>
                                            <Button Name="btnUVERun" Content="Run" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtUVEOutput" Margin="5,10,5,0" Height="379" IsReadOnly="True" Background="#353A7A" FontFamily="Segoe UI" Foreground="#FFFFFF" VerticalScrollBarVisibility="Auto"></TextBox>
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

        Write-Host "Disconnecting from Microsoft Teams PowerShell..."
        Disconnect-MicrosoftTeams
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

$lblUserValidationErrors.Add_MouseEnter({
        $lblUserValidationErrors.Background = '#353A7A'
    })

$lblUserValidationErrors.Add_MouseLeave({
        if ($grdUserValidationErrors.Visibility -eq 'Visible') {
            $lblUserValidationErrors.Background = '#353A7A'
        }
        else {
            $lblUserValidationErrors.Background = '#181B40'
        }
    })

$lblAutoAttendant.Add_MouseLeftButtonUp({
        $grdForwarding.Visibility = 'Hidden'
        $grdDialPad.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Visible'
        $lblForwarding.Background = '#181B40'
        $lblDialPad.Background = '#181B40'
        $grdUserValidationErrors.Visibility = 'Hidden'
        $lblUserValidationErrors.Background = '#181B40'
    })

$lblDialPad.Add_MouseLeftButtonUp({
        $grdForwarding.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Hidden'
        $grdDialPad.Visibility = 'Visible'
        $lblForwarding.Background = '#181B40'
        $lblAutoAttendant.Background = '#181B40'
        $grdUserValidationErrors.Visibility = 'Hidden'
        $lblUserValidationErrors.Background = '#181B40'
    })

$lblForwarding.Add_MouseLeftButtonUp({
        $grdDialPad.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Hidden'
        $grdForwarding.Visibility = 'Visible'
        $lblDialPad.Background = '#181B40'
        $lblAutoAttendant.Background = '#181B40'
        $grdUserValidationErrors.Visibility = 'Hidden'
        $lblUserValidationErrors.Background = '#181B40'
    })

$lblUserValidationErrors.Add_MouseLeftButtonUp({
        $grdForwarding.Visibility = 'Hidden'
        $grdDialPad.Visibility = 'Hidden'
        $grdAutoAttendant.Visibility = 'Hidden'
        $lblForwarding.Background = '#181B40'
        $lblDialPad.Background = '#181B40'
        $grdUserValidationErrors.Visibility = 'Visible'
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

        Write-Host "Connecting to Microsoft Teams PowerShell..."
        Connect-MicrosoftTeams -Credential $Credentials

        $usr = Get-CsOnlineUser -Identity $Username

        if ($usr) {
            Write-Host -ForegroundColor Green 'TEAMS AUTH SUCCESSFUL.'
            $lblAuthStatus.Foreground = "#BDF2D5"
            $lblAuthStatus.Content = "TEAMS AUTH SUCCESSFUL"
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
            Write-Host -ForegroundColor Red 'TEAMS AUTH FAILED.'
            $lblAuthStatus.Foreground = "Salmon"
            $lblAuthStatus.Content = "TEAMS AUTH FAILED"

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
        $txtDPOutput.Text += "USER`n"
        $txtDPOutput.Text += "---------------------------------`n"

        if ($user) {
            $txtDPOutput.Text += "The user was found in the directory.`n"
            $txtDPOutput.Text += "---------------------------------`n"
            $txtDPOutput.Text += "LICENSE`n"
            $txtDPOutput.Text += "---------------------------------`n"
            $txtDPOutput.Text += "Checking the user is properly licensed for Teams Phone:`n"
            $userAssignedPlans = Get-UserAssignedPlans $txtDPUPN.Text

            if ($userAssignedPlans.length -ne 0) {
                $txtDPOutput.Text += "The user has assigned plans.`n"
                $txtDPOutput.Text += "Checking if the user is licensed for Teams:`n"
                $isTeamsAssignedAndEnabled = $false

                foreach ($plan in $userAssignedPlans) {
                    if ($plan.Capability -eq 'Teams' -AND $plan.CapabilityStatus -eq 'Enabled') {
                        $isTeamsAssignedAndEnabled = $true
                    }
                }

                if ($isTeamsAssignedAndEnabled) {
                    $txtDPOutput.Text += "The user is licensed for Teams.`n"

                    $txtDPOutput.Text += "Checking if the user is licensed for Skype for Business Online:`n"
                    $isSfBOAssignedAndEnabled = $false

                    foreach ($plan in $userAssignedPlans) {
                        if ($plan.Capability -eq 'MCOProfessional' -AND $plan.CapabilityStatus -eq 'Enabled') {
                            $isSfBOAssignedAndEnabled = $true
                        }
                    }

                    if ($isSfBOAssignedAndEnabled) {
                        $txtDPOutput.Text += "The user is licensed for Skype for Business Online.`n"

                        $txtDPOutput.Text += "Checking if the user is licensed for Teams Phone:`n"
                        $isMCOEVAssignedAndEnabled = $false

                        foreach ($plan in $userAssignedPlans) {
                            if ($plan.Capability -eq 'MCOEV' -AND $plan.CapabilityStatus -eq 'Enabled') {
                                $isMCOEVAssignedAndEnabled = $true
                            }
                        }

                        if ($isMCOEVAssignedAndEnabled) {
                            $txtDPOutput.Text += "The user is licensed for Teams Phone.`n"

                            $txtDPOutput.Text += "---------------------------------`n"
                            $txtDPOutput.Text += "VOICE`n"
                            $txtDPOutput.Text += "---------------------------------`n"
                            $txtDPOutput.Text += "Checking if the user is Enterprise Voice enabled:`n"

                            if ($user.EnterpriseVoiceEnabled) {
                                $txtDPOutput.Text += "The user is Enterprise Voice enabled.`n"

                                $txtDPOutput.Text += "Checking if the user is homed online in Skype for Business:`n" 

                                if ($user.HostingProvider -eq 'sipfed.online.lync.com') {
                                    $txtDPOutput.Text += "The user is homed online.`n" 

                                    $txtDPOutput.Text += "Checking if the user is set up for TeamsOnly:`n" 

                                    if ($user.TeamsUpgradeEffectiveMode -eq 'TeamsOnly') {
                                        $txtDPOutput.Text += "The user is set up for TeamsOnly.`n"

                                        $txtDPOutput.Text += "Checking if the user has a phone number assigned:`n"

                                        if ($user.LineUri) {
                                            $txtDPOutput.Text += "The user has a phone number assigned.`n"

                                            $txtDPOutput.Text += "Checking the PSTN connectivity type:`n"

                                            $PSTNType = (Get-CsPhoneNumberAssignment -AssignedPstnTargetId $user.UserPrincipalName).NumberType


                                            if ($PSTNType -eq 'CallingPlan') {
                                                $txtDPOutput.Text += "The user is set up for Calling Plan.`n"

                                                $txtDPOutput.Text += "Checking if the user is assigned a Caling Plan license:`n"
                                                $isMCOPSTNAssignedAndEnabled = $false

                                                foreach ($plan in $userAssignedPlans) {
                                                    if (($plan.Capability -eq 'MCOPSTN1' -OR $plan.Capability -eq 'MCOPSTN2' -OR $plan.Capability -eq 'MCOPSTN5' -OR $plan.Capability -eq 'MCOPSTN6' -OR $plan.Capability -eq 'MCOPSTN8' -OR $plan.Capability -eq 'MCOPSTN9') -AND $plan.CapabilityStatus -eq 'Enabled') {
                                                        $isMCOPSTNAssignedAndEnabled = $true
                                                    }
                                                }

                                                if ($isMCOPSTNAssignedAndEnabled) {
                                                    $txtDPOutput.Text += "The user is assigned a Callign Plan license.`n"

                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "ERRORS`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "Checking if the user has any validation error:`n"

                                                    if (!($user.UserValidationErrors -gt 0)) {
                                                        $txtDPOutput.Text += "The user does not have any validation error.`n"

                                                        $txtDPOutput.Foreground = "#BDF2D5"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        $txtDPOutput.Text += "SUCCESS`n"
                                                        $txtDPOutput.Text += "---------------------------------"
                                                    }
                                                    else {
                                                        $txtDPOutput.Foreground = "Salmon"
                                                        $txtDPOutput.Text += "The user has a validation error of $($user.UserValidationErrors[0].ErrorCode): $($user.UserValidationErrors[0].ErrorDescription).`n"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        $txtDPOutput.Text += "FAILURE`n"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        return 
                                                    }
                                                }
                                                else {
                                                    $txtDPOutput.Foreground = "Salmon"
                                                    $txtDPOutput.Text += "The user is not assigned any Calling Plan license.`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "FAILURE`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    return 
                                                }

                                            }
                                            elseif ($PSTNType -eq 'DirectRouting') {
                                                $txtDPOutput.Text += "The user is set up for Direct Routing.`n"

                                                $txtDPOutput.Text += "Checking if the user is assigned a voice routing policy with a gateway route:`n"

                                                $voiceRoutingPolicy = $user.OnlineVoiceRoutingPolicy.Name

                                                if ($voiceRoutingPolicy -eq $null) {
                                                    $voiceRoutingPolicy = 'Global'
                                                }

                                                $pstnUsageName = ((Get-CsOnlineVoiceRoutingPolicy -Identity $voiceRoutingPolicy).OnlinePstnUsages | Out-String).trim()
                                                $voiceRoute = (Get-CsOnlineVoiceRoute | Where-Object { $_.OnlinePstnUsages -contains $pstnUsageName })

                                                if ($voiceRoute.OnlinePstnGatewayList) {
                                                    $txtDPOutput.Text += "The user's voice routing policy has a gateway route.`n"

                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "ERRORS`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "Checking if the user has any validation error:`n"

                                                    if (!($user.UserValidationErrors -gt 0)) {
                                                        $txtDPOutput.Text += "The user does not have any validation error.`n"

                                                        $txtDPOutput.Foreground = "#BDF2D5"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        $txtDPOutput.Text += "SUCCESS`n"
                                                        $txtDPOutput.Text += "---------------------------------"
                                                    }
                                                    else {
                                                        $txtDPOutput.Foreground = "Salmon"
                                                        $txtDPOutput.Text += "The user has a validation error of $($user.UserValidationErrors[0].ErrorCode): $($user.UserValidationErrors[0].ErrorDescription).`n"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        $txtDPOutput.Text += "FAILURE`n"
                                                        $txtDPOutput.Text += "---------------------------------`n"
                                                        return 
                                                    }
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
                                            elseif ($PSTNType -eq 'OperatorConnect') {
                                                $txtDPOutput.Text += "The user is set up for Operator Connect.`n"

                                                # TO VALIDATE EMERGENCY CALLING POLICY NOT NULL ???

                                                $txtDPOutput.Text += "---------------------------------`n"
                                                $txtDPOutput.Text += "ERRORS`n"
                                                $txtDPOutput.Text += "---------------------------------`n"
                                                $txtDPOutput.Text += "Checking if the user has any validation error:`n"

                                                if (!($user.UserValidationErrors -gt 0)) {
                                                    $txtDPOutput.Text += "The user does not have any validation error.`n"

                                                    $txtDPOutput.Foreground = "#BDF2D5"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "SUCCESS`n"
                                                    $txtDPOutput.Text += "---------------------------------"
                                                }
                                                else {
                                                    $txtDPOutput.Foreground = "Salmon"
                                                    $txtDPOutput.Text += "The user has a validation error of $($user.UserValidationErrors[0].ErrorCode): $($user.UserValidationErrors[0].ErrorDescription).`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    $txtDPOutput.Text += "FAILURE`n"
                                                    $txtDPOutput.Text += "---------------------------------`n"
                                                    return 
                                                }
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
                                $txtDPOutput.Text += "The user is not Enterprise Voice enabled.`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                $txtDPOutput.Text += "FAILURE`n"
                                $txtDPOutput.Text += "---------------------------------`n"
                                return 
                            }
                        }
                        else {
                            $txtDPOutput.Foreground = "Salmon"
                            $txtDPOutput.Text += "The user is not licensed for Teams Phone.`n"
                            $txtDPOutput.Text += "---------------------------------`n"
                            $txtDPOutput.Text += "FAILURE`n"
                            $txtDPOutput.Text += "---------------------------------`n"
                            return 
                        }
                    }
                    else {
                        $txtDPOutput.Foreground = "Salmon"
                        $txtDPOutput.Text += "The user is not licensed for Skype for Business Online.`n"
                        $txtDPOutput.Text += "---------------------------------`n"
                        $txtDPOutput.Text += "FAILURE`n"
                        $txtDPOutput.Text += "---------------------------------`n"
                        return 
                    }
                }
                else {
                    $txtDPOutput.Foreground = "Salmon"
                    $txtDPOutput.Text += "The user is not licensed for Teams.`n"
                    $txtDPOutput.Text += "---------------------------------`n"
                    $txtDPOutput.Text += "FAILURE`n"
                    $txtDPOutput.Text += "---------------------------------`n"
                    return 
                }
            }
            else {
                $txtDPOutput.Foreground = "Salmon"
                $txtDPOutput.Text += "The user doesn't have any assigned plans.`n"
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
        $txtAAOutput.Text += "Checking if the resource account exists:`n"
        $RA = (Get-CsOnlineUser $txtAAUPN.Text)

        if (($RA) -AND ($RA.InterpretedUserType -eq 'PureOnlineApplicationInstance')) {
            $txtAAOutput.Text += "The resource account exists.`n"

            $txtAAOutput.Text += "---------------------------------`n"
            $txtAAOutput.Text += "LICENSE`n"
            $txtAAOutput.Text += "---------------------------------`n"
            $txtAAOutput.Text += "Checking if the resource account is properly licensed:`n"
            $raAssignedPlans = Get-UserAssignedPlans $txtAAUPN.Text

            if ($raAssignedPlans.length -ne 0) {
                $txtAAOutput.Text += "The resorce account has plans assigned.`n"
                $txtAAOutput.Text += "Checking if the resource account has a Teams Phone Resource Account plan assigned:`n"
                $isMCOEVVIRTUALUSERAssignedAndEnabled = $false

                foreach ($plan in $raAssignedPlans) {
                    if ($plan.Capability -eq "MCOEV_VIRTUALUSER" -AND $plan.CapabilityStatus -eq 'Enabled') {
                        $isMCOEVVIRTUALUSERAssignedAndEnabled = $true
                    }
                }

                if ($isMCOEVVIRTUALUSERAssignedAndEnabled) {
                    $txtAAOutput.Text += "The resource account has a Teams Phone Resource Account Plan assigned.`n"

                    $txtAAOutput.Text += "---------------------------------`n"
                    $txtAAOutput.Text += "VOICE`n"
                    $txtAAOutput.Text += "---------------------------------`n"

                    $txtAAOutput.Text += "Checking if the resource account is enabled:`n"
                    if (!($RA.AccountEnabled)) {
                        $txtAAOutput.Text += "The resource account is not enabled.`n"

                        $txtAAOutput.Text += "Checking if the department property is valid:`n"

                        if ($RA.Department -eq 'Microsoft Communication Application Instance') {
                            $txtAAOutput.Text += "The department property is valid.`n"

                            $txtAAOutput.Text += "Checking if there is a SIP address set:`n"

                            if ($RA.SipAddress -eq $null) {
                                $txtAAOutput.Text += "There is no SIP address set.`n"

                                $txtAAOutput.Text += "Checking if there is a phone number assigned:`n"

                                if ($RA.LineUri) {
                                    $txtAAOutput.Text += "There is a phone number assigned.`n"

                                    $txtAAOutput.Text += "---------------------------------`n"
                                    $txtAAOutput.Text += "SUCCESS`n"
                                    $txtAAOutput.Text += "---------------------------------`n"
                                    $txtAAOutput.Foreground = "#BDF2D5"
                                }
                                else {
                                    $txtAAOutput.Foreground = "Salmon"
                                    $txtAAOutput.Text += "There isn't a phone number set.`n"
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
                            $txtAAOutput.Text += "The department property is not valid.`n"
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
                    $txtAAOutput.Text += "The resource account does not have a Teams Phone Resource Account plan assigned.`n"
                    $txtAAOutput.Text += "---------------------------------`n"
                    $txtAAOutput.Text += "FAILURE`n"
                    $txtAAOutput.Text += "---------------------------------`n"
                    return
                }

            }
            else {
                $txtAAOutput.Foreground = "Salmon"
                $txtAAOutput.Text += "The resource account does not have any plans assigned.`n"
                $txtAAOutput.Text += "---------------------------------`n"
                $txtAAOutput.Text += "FAILURE`n"
                $txtAAOutput.Text += "---------------------------------`n"
                return
            }
        }
        else {
            $txtAAOutput.Foreground = "Salmon"
            $txtAAOutput.Text += "The resource account does not exist or its type is not supported.`n"
            $txtAAOutput.Text += "---------------------------------`n"
            $txtAAOutput.Text += "FAILURE`n"
            $txtAAOutput.Text += "---------------------------------`n"
            return
        }
    })


$btnUVERun.Add_Click({
        $txtUVEOutput.Foreground = "White"
        $txtUVEOutput.Text = ""

        $txtUVEOutput.Text += "Checking if there are users with validation errors:`n"
        $UPNs = (Get-CsOnlineUser).UserPrincipalName
        $usersWithValidationErrors = @()

        foreach ($UPN in $UPNs) {
            $user = (Get-CsOnlineUser $UPN)
            $errors = $user.UserValidationErrors
            
            if ($errors.length -gt 0) {
                foreach ($err in $errors) {
                    $usersWithValidationErrors += New-Object PSObject -Property @{User = $UPN; ErrorCode = $err.ErrorCode; ErrorDescription = $err.ErrorDescription }
                }
            }
        }

        if (!($usersWithValidationErrors.length -eq 0)) {
            $txtUVEOutput.Text += "Found users with validation errors:`n"
            if ($chkUVECSV.IsChecked) {
                $txtUVEOutput.Text += "---------------------------------`n"
                $txtUVEOutput.Text += "Exporting users:"
                $loc = Get-Location
    
                $usersWithValidationErrors | Select-Object User, ErrorCode, ErrorDescription | Export-Csv ".\TMS-PHONE-UsersWithValidationErrors.csv" -NoTypeInformation
            
                $txtUVEOutput.Text += "$($loc.path)\TMS-PHONE-UsersWithValidationErrors.csv`n"
                $txtUVEOutput.Text += "---------------------------------`n"
            } else {
                $txtUVEOutput.Text += "---------------------------------`n"
                foreach ($u in $usersWithValidationErrors) {
                    $txtUVEOutput.Text += "User: $($u.User) --- Error: $($u.ErrorCode) - $($u.ErrorDescription)`n"         
                }
                $txtUVEOutput.Text += "---------------------------------`n"
            }
        } else {
            $txtUVEOutput.Text += "---------------------------------`n"
            $txtUVEOutput.Text += "Found no users with validation errors.`n"
            $txtUVEOutput.Text += "---------------------------------`n"
        }

    })

$Window.ShowDialog()
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----END
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #