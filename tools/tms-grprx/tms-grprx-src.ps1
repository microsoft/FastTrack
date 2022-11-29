# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# AUTHOR: Mihai Filip
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# Dependencies: AzureADPreview
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# USAGE: 
# .\tms-ninja-group-restriction-src.ps1
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# FOR DEBUGGING N PROD
$ErrorActionPreference = "SilentlyContinue"

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----UI
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

Add-Type -AssemblyName PresentationCore, PresentationFramework

$Xaml = @"
<Window xmlns:syncfusion="http://schemas.syncfusion.com/wpf"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Name="MainWindow" Title="TMS-GRPRX" Background="#141414" WindowStartupLocation="
CenterScreen" ResizeMode="CanResizeWithGrip" FontFamily="Segoe UI" Height="844" Width="1262" BorderThickness="1" BorderBrush="#292929" AllowsTransparency="True" WindowStyle="None">

    <Grid>
        <DockPanel VerticalAlignment="Top" Height="580">

            <DockPanel Name="TitleBar" DockPanel.Dock="Top" Background="#141414" Height="24">

                <TextBlock Name="Title" Margin="7,0,0,0" HorizontalAlignment="Left" VerticalAlignment="Center" Background="#141414" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold">
                    TMS-GRPRX v1.00
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
                    <Border BorderThickness="0" BorderBrush="#292929">
                        <StackPanel>
                            <Image Name="Logo" Source="https://i.postimg.cc/sDQBJNjP/tms-ninja-logo-white.png" HorizontalAlignment="Center" VerticalAlignment="Top" Width="200" Height="200"></Image>
                        </StackPanel>
                    </Border>
                </Grid>

                <Grid Name="grdAuthFields">
                    <Border BorderThickness="0" BorderBrush="#292929">
                        <StackPanel>
                            <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0">Username:</Label>
                            <TextBox Name="txtUsername" Padding="5" Margin="15,5,15,5"></TextBox>
                            <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0">Password:</Label>
                            <PasswordBox Name="txtPassword" Padding="5" Margin="15,5,15,5"></PasswordBox>
                            <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0" HorizontalAlignment="Center">aka.ms/create-o365-groups</Label>
                            <PasswordBox Name="txtClientId" Padding="5" Margin="15,5,15,5" Visibility="Hidden"></PasswordBox>
                            <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="10,0,10,0" Visibility="Hidden">Client secret:</Label>
                            <PasswordBox Name="txtClientSecret" Padding="5" Margin="15,5,15,5" Visibility="Hidden"></PasswordBox>
                            <Button Name="btnSignIn" Content="Connect" Padding="5" Margin="5, 20, 5, 10" Width="150" Cursor="Hand"></Button>
                        </StackPanel>
                    </Border>
                </Grid>

                <Grid Name="grdAuthStatus">
                    <Label Name="lblAuthStatus" Content="" HorizontalAlignment="Center" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Background="#141414"></Label>
                </Grid>

                <Grid Name="grdApp" Visibility="Hidden">
                    <Border BorderThickness="0" BorderBrush="#292929">
                        <DockPanel>
                            <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                <Grid Name="grdNav" HorizontalAlignment="Left" Width="180">
                                    <StackPanel>
                                        <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                            <Label Name="lblGroupRestriction" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Background="#141414" Padding="7">---------------------------------</Label>
                                        </Border>
                                        <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                            <Label Name="lblEnableGroupRestriction" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#141414" Padding="7">Enable restriction</Label>
                                        </Border>
                                        <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                            <Label Name="lblCheckGroupRestriction" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#141414" Padding="7">Check restriction</Label>
                                        </Border>
                                        <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                            <Label Name="lblDisableGroupRestriction" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Cursor="Hand" Background="#141414" Padding="7">Disable restriction</Label>
                                        </Border>
                                        <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                            <Label Name="lblEnd" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Background="#141414" Padding="7">---------------------------------</Label>
                                        </Border>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <Border BorderThickness="0" BorderBrush="#bdbdbd">
                                <Grid Name="grdActivity" HorizontalAlignment="Right" Background="#292929" Width="620">
                                        <Grid Name="grdEnableGroupRestriction" Margin="10,10,10,10">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#bdbdbd" Padding="5" Margin="5">
                                                <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Group Restriction \ Enable restriction</Label>
                                            </Border>
                                            <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="0,5,0,0">Group name:</Label>
                                            <TextBox Name="txtGREnableGroupName" Padding="5" Margin="5" HorizontalContentAlignment="Left"></TextBox>
                                            <Button Name="btnGREnable" Content="Enable" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtGREnableOutput" Margin="5,10,5,0" Height="330" IsEnabled="False" Background="#292929" FontFamily="Segoe UI" Foreground="#bdbdbd"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdCheckGroupRestriction" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#bdbdbd" Padding="5" Margin="5">
                                                <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Group Restriction \ Check restriction</Label>
                                            </Border>
                                            <Button Name="btnGRCheck" Content="Check" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtGRCheckOutput" Margin="5,10,5,0" Height="399" IsEnabled="False" Background="#292929" FontFamily="Segoe UI" Foreground="#bdbdbd"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Name="grdDisableGroupRestriction" Margin="10,10,10,10" Visibility="Hidden">
                                        <StackPanel>
                                            <Border BorderThickness="0.5" BorderBrush="#bdbdbd" Padding="5" Margin="5">
                                                <Label Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="14">Group Restriction \ Disable restriction</Label>
                                            </Border>
                                            <Button Name="btnGRDisable" Content="Disable" FontFamily="Segoe UI" FontWeight="DemiBold" Margin="5,10,450,10" Height="30" Cursor="Hand"></Button>
                                            <TextBox Name="txtGRDisableOutput" Margin="5,10,5,0" Height="399" IsEnabled="False" Background="#292929" FontFamily="Segoe UI" Foreground="#bdbdbd"></TextBox>
                                        </StackPanel>
                                    </Grid>
                                </Grid>
                            </Border>
                        </DockPanel>
                    </Border>

                    <DockPanel Margin="0,531,0,0" Background="#141414" Height="24">

                        <TextBlock Name="txtSignedInUser" Margin="7,0,0,0" HorizontalAlignment="Center" VerticalAlignment="Center" Background="#141414" Foreground="#bdbdbd" FontFamily="Segoe UI" FontWeight="DemiBold" FontSize="11">
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

$lblEnableGroupRestriction.Background = '#292929'


$btnCloseScreen.Add_Click({
        $Window.Close()

        Start-Sleep -s 3

        Disconnect-AzureAD
    })

$TitleBar.Add_MouseDown({
        $Window.DragMove()
    })

$lblEnableGroupRestriction.Add_MouseEnter({
        $lblEnableGroupRestriction.Background = '#292929'
    })

$lblEnableGroupRestriction.Add_MouseLeave({
        if ($grdEnableGroupRestriction.Visibility -eq 'Visible') {
            $lblEnableGroupRestriction.Background = '#292929'
        }
        else {
            $lblEnableGroupRestriction.Background = '#141414'
        }
    })

$lblDisableGroupRestriction.Add_MouseEnter({
        $lblDisableGroupRestriction.Background = '#292929'
    })

$lblDisableGroupRestriction.Add_MouseLeave({
        if ($grdDisableGroupRestriction.Visibility -eq 'Visible') {
            $lblDisableGroupRestriction.Background = '#292929'
        }
        else {
            $lblDisableGroupRestriction.Background = '#141414'
        }
    })

$lblDisableGroupRestriction.Add_MouseLeftButtonUp({
        $grdCheckGroupRestriction.Visibility = 'Hidden'
        $grdEnableGroupRestriction.Visibility = 'Hidden'
        $grdDisableGroupRestriction.Visibility = 'Visible'
        $lblCheckGroupRestriction.Background = '#141414'
        $lblEnableGroupRestriction.Background = '#141414'
    })

$lblEnableGroupRestriction.Add_MouseLeftButtonUp({
        $grdCheckGroupRestriction.Visibility = 'Hidden'
        $grdDisableGroupRestriction.Visibility = 'Hidden'
        $grdEnableGroupRestriction.Visibility = 'Visible'
        $lblCheckGroupRestriction.Background = '#141414'
        $lblDisableGroupRestriction.Background = '#141414'
    })

$lblCheckGroupRestriction.Add_MouseEnter({
        $lblCheckGroupRestriction.Background = '#292929'
    })

$lblCheckGroupRestriction.Add_MouseLeave({
        if ($grdCheckGroupRestriction.Visibility -eq 'Visible') {
            $lblCheckGroupRestriction.Background = '#292929'
        }
        else {
            $lblCheckGroupRestriction.Background = '#141414'
        }
    })

$lblCheckGroupRestriction.Add_MouseLeftButtonUp({
        $grdEnableGroupRestriction.Visibility = 'Hidden'
        $grdDisableGroupRestriction.Visibility = 'Hidden'
        $grdCheckGroupRestriction.Visibility = 'Visible'
        $lblEnableGroupRestriction.Background = '#141414'
        $lblDisableGroupRestriction.Background = '#141414'
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

        AzureADPreview\Connect-AzureAD -Credential $Credentials

        $usr = Get-AzureADUser -ObjectId $Username

        if ($usr) {
            Write-Host 'AAD AUTH VALID.'
            $lblAuthStatus.Foreground = "#BDF2D5"
            $lblAuthStatus.Content = "AAD AUTH SUCCESSFUL"
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
            Write-Host 'AAD AUTH FAILED.'
            $lblAuthStatus.Foreground = "Salmon"
            $lblAuthStatus.Content = "AAD AUTH FAILED"
        }
    })

$btnGREnable.Add_Click({
        $txtGREnableOutput.Foreground = "White"
        $txtGREnableOutput.Text = ''

        if (!$txtGREnableGroupName.Text) {
            $txtGREnableOutput.Foreground = "Salmon"
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "GROUP NAME EMPTY`n"
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "Please provide a group name as input and try again."
            return
        }

        $GroupName = $txtGREnableGroupName.Text
        $AllowGroupCreation = $False

        $Group = Get-AzureADGroup -SearchString $GroupName
        $txtGREnableOutput.Text += "---------------------------------`n"
        $txtGREnableOutput.Text += "GROUP VALIDATION`n"
        $txtGREnableOutput.Text += "---------------------------------`n"
        $txtGREnableOutput.Text += "Checking if the provided group $($GroupName) exists in the directory:`n"

        if ($Group) {
            $txtGREnableOutput.Text += "Group exists with id $($Group.ObjectId).`n"
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "ENABLING RESTRICTION`n"
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "Setting EnableGroupCreation to False`nSetting GroupCreationAllowedGroupId to $($Group.ObjectId)`n"
            $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
            if (!$settingsObjectID) {
                $template = Get-AzureADDirectorySettingTemplate | Where-object { $_.displayname -eq "group.unified" }
                $settingsCopy = $template.CreateDirectorySetting()
                New-AzureADDirectorySetting -DirectorySetting $settingsCopy
                $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
            }

            $settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
            $settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

            if ($GroupName) {
                $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
            }
            else {
                $settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
            }
            Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

            $Settings = (Get-AzureADDirectorySetting -Id $settingsObjectID).Values
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "VALIDATION`n"
            $txtGREnableOutput.Text += "---------------------------------`n"
            $txtGREnableOutput.Text += "Verifying if the values were set correctly:`n"

            if (($Settings.Value[14] -eq $False) -AND ($Settings.Value[10] -eq $Group.ObjectId)) {
                $txtGREnableOutput.Foreground = "#BDF2D5"
                $txtGREnableOutput.Text += "EnableGroupCreation is set to False`n"
                $txtGREnableOutput.Text += "GroupCreationAllowedGroupId is set to $($Group.ObjectId)`n"
                $txtGREnableOutput.Text += "---------------------------------`n"
                $txtGREnableOutput.Text += "SUCCESS`n"
                $txtGREnableOutput.Text += "---------------------------------`n"
            }
            else {
                $txtGREnableOutput.Foreground = "Salmon"
                $txtGREnableOutput.Text += "Something went wrong, please consult the docs:`n"
                $txtGREnableOutput.Text += "https://aka.ms/create-o365-groups`n"
                $txtGREnableOutput.Text += "---------------------------------`n"
                $txtGREnableOutput.Text += "FAILURE`n"
                $txtGREnableOutput.Text += "---------------------------------`n"
            }
        }
        else {
            $txtGREnableOutput.Foreground = "Salmon"
            $txtGREnableOutput.Text += "Group does not exist in the directory. Please check the name and try again."
            return
        }
    })

$btnGRCheck.Add_Click({
        $txtGRCheckOutput.Foreground = "White"
        $txtGRCheckOutput.Text = ''

        $txtGRCheckOutput.Text += "---------------------------------`n"
        $txtGRCheckOutput.Text += "CHECKING RESTRICTION`n"
        $txtGRCheckOutput.Text += "---------------------------------`n"
        $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
        $txtGRCheckOutput.Text += "Checking if there is a settingsObject in place for groups:`n"

        if (!$settingsObjectID) {
            $txtGRCheckOutput.Text += "There is no settingObject configured for groups, so no restriction is in place.`n"
            $txtGRCheckOutput.Text += "---------------------------------`n"
            $txtGRCheckOutput.Text += "SUCCESS`n"
            $txtGRCheckOutput.Text += "---------------------------------`n"
            return
        }
        else {
            $txtGRCheckOutput.Text += "Found a settingsObject configured for groups. Checking the settings:`n"
            $Settings = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Values
            $txtGRCheckOutput.Text += "---------------------------------`n"
            $txtGRCheckOutput.Text += "SETTINGS`n"
            $txtGRCheckOutput.Text += "---------------------------------`n"
            $Group = Get-AzureADGroup -ObjectId $Settings.Value[10]

            if ($Settings.Value[14] -eq $False) {
                $txtGRCheckOutput.Text += "A restriction is in place and EnableGroupCreation is False`n"

                if ($Settings.Value[10]) {
                    $txtGRCheckOutput.Text += "The group allowed to create groups (GroupCreationAllowedGroupId) is: `nName: $($Group.DisplayName)`n"
                    $txtGRCheckOutput.Text += "Id: $($Settings.Value[10])`n"
                    $txtGRCheckOutput.Text += "---------------------------------`n"
                    $txtGRCheckOutput.Text += "SUCCESS`n"
                    $txtGRCheckOutput.Text += "---------------------------------`n"
                }
                else {
                    $txtGRCheckOutput.Text += "The group allowed to create groups (GroupCreationAllowedGroupId) is not defined.`n"
                    $txtGRCheckOutput.Text += "---------------------------------`n"
                    $txtGRCheckOutput.Text += "SUCCESS`n"
                    $txtGRCheckOutput.Text += "---------------------------------`n"
                    return
                }
            }
            elseif ($Settings.Value[14] -eq $True) {
                $txtGRCheckOutput.Text += "No restriction is in place and EnableGroupCreation is True.`n"
                $txtGRCheckOutput.Text += "---------------------------------`n"
                $txtGRCheckOutput.Text += "SUCCESS`n"
                $txtGRCheckOutput.Text += "---------------------------------`n"
            }
            else {
                $txtGRCheckOutput.Foreground = "Salmon"
                $txtGRCheckOutput.Text += "Something went wrong. Please consult the docs:`n"
                $txtGRCheckOutput.Text += "https://aka.ms/create-o365-groups`n"
                $txtGRCheckOutput.Text += "---------------------------------`n"
                $txtGRCheckOutput.Text += "FAILURE`n"
                $txtGRCheckOutput.Text += "---------------------------------`n"
            }
        }
    })

$btnGRDisable.Add_Click({
        $txtGRDisableOutput.Foreground = "White"
        $txtGRDisableOutput.Text = ""

        $GroupName = "" 
        $AllowGroupCreation = $True
        
        $txtGRDisableOutput.Text += "---------------------------------`n"
        $txtGRDisableOutput.Text += "DISABLING RESTRICTION`n"
        $txtGRDisableOutput.Text += "---------------------------------`n"
        $txtGRDisableOutput.Text += "Disabling group creation restriction:`n"

        $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
        if (!$settingsObjectID) {
            $template = Get-AzureADDirectorySettingTemplate | Where-object { $_.displayname -eq "group.unified" }
            $settingsCopy = $template.CreateDirectorySetting()
            New-AzureADDirectorySetting -DirectorySetting $settingsCopy
            $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
        }

        $settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
        $settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

        if ($GroupName) {
            $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
        }
        else {
            $settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
        }
        Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

        $txtGRDisableOutput.Text += "Setting EnableGroupCreation to True.`n"
        $txtGRDisableOutput.Text += "Setting GroupCreationAllowedGroupId to null.`n"

        $txtGRDisableOutput.Text += "---------------------------------`n"
        $txtGRDisableOutput.Text += "VALIDATION`n"
        $txtGRDisableOutput.Text += "---------------------------------`n"
        $Settings = (Get-AzureADDirectorySetting -Id $settingsObjectID).Values
        if ($Settings.Value[14] -eq $True) {
            $txtGRDisableOutput.Foreground = "#BDF2D5"
            $txtGRDisableOutput.Text += "Successfully disabled group creation restriction:`n"
            $txtGRDisableOutput.Text += "EnableGroupCreation is True.`n"
            if (!$Settings.Value[10]) {
                $txtGRDisableOutput.Text += "GroupCreationAllowedGroupId is null.`n"
                $txtGRDisableOutput.Text += "---------------------------------`n"
                $txtGRDisableOutput.Text += "SUCCESS`n"
                $txtGRDisableOutput.Text += "---------------------------------`n"
            }
            else {
                $txtGRDisableOutput.Text += "GroupCreationAllowedGroupId is $($Settings.Value[10])`n"
                $txtGRDisableOutput.Text += "---------------------------------`n"
                $txtGRDisableOutput.Text += "SUCCESS`n"
                $txtGRDisableOutput.Text += "---------------------------------`n"
            }
        }
        else {
            $txtGRDisableOutput.Foreground = "Salmon"
            $txtGRDisableOutput.Text += "Something went wrong. Please consult the docs:`n"
            $txtGRDisableOutput.Text += "https://aka.ms/create-o365-groups`n"
            $txtGRDisableOutput.Text += "---------------------------------`n"
            $txtGRDisableOutput.Text += "FAILURE`n"
            $txtGRDisableOutput.Text += "---------------------------------`n"
        }
    })

$Window.ShowDialog()
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----END
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #