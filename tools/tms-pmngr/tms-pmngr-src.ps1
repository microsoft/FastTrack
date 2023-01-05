# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# AUTHOR: Mihai Filip
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# Dependencies: WinOS
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 
# USAGE: 
# .\tms-pmngr-src.ps1 (or EXE)
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. 

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Functions
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

#region Functions
Function New-CustomProfile {
  param (
    [string]$pName
  )

  $PN = $pName
  Write-Output "Launching $PN Teams Profile ..."

  $userProfile = $env:USERPROFILE
  $appDataPath = $env:LOCALAPPDATA
  $customProfile = "$appDataPath\Microsoft\Teams\CustomProfiles\$PN"
  $downloadPath = Join-Path $customProfile "Downloads"

  if (!(Test-Path -PathType Container $downloadPath)) {
    New-Item $downloadPath -ItemType Directory |
      Select-Object -ExpandProperty FullName
  }

  $env:USERPROFILE = $customProfile
  Start-Process `
    -FilePath "$appDataPath\Microsoft\Teams\Update.exe" `
    -ArgumentList '--processStart "Teams.exe"' `
    -WorkingDirectory "$appDataPath\Microsoft\Teams"

}

Function Get-CustomProfiles {
  $profiles = gci -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles"

  return $profiles
}
#endregion

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Initial Declarations
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

#region Declarations
Add-Type -AssemblyName PresentationCore, PresentationFramework

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="715" Height="355" Name="PMNGR" Title="TMS-PMNGR v1.0" ResizeMode="NoResize" WindowStartupLocation="CenterScreen"><Window.Resources>
	<ResourceDictionary>
		<ResourceDictionary.MergedDictionaries>
			<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"  xmlns:d="http://schemas.microsoft.com/expression/blend/2008"  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"  mc:Ignorable="d">
				<ResourceDictionary.MergedDictionaries>
					<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:d="http://schemas.microsoft.com/expression/blend/2008" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:System="clr-namespace:System;assembly=mscorlib" mc:Ignorable="d">
						<ResourceDictionary.MergedDictionaries>
							<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:d="http://schemas.microsoft.com/expression/blend/2008" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d">
								<SolidColorBrush x:Key="Brush01" Color="#FF0072C6"/>
								<SolidColorBrush x:Key="Brush02" Color="White"/>
								<SolidColorBrush x:Key="Brush03" Color="#FF6D6D6D"/>
								<SolidColorBrush x:Key="Brush04" Color="#FFE1E1E1"/>
								<SolidColorBrush x:Key="Brush05" Color="#FFF3F3F3"/>
								<Color x:Key="Color_001">#FF444444</Color>
								<Color x:Key="Color_002">#FF6D6D6D</Color>
								<Color x:Key="Color_003">#FF777777</Color>
								<Color x:Key="Color_004">#FF959595</Color>
								<Color x:Key="Color_005">#FFABABAB</Color>
								<Color x:Key="Color_006">#FFE1E1E1</Color>
								<Color x:Key="Color_007">#FFF0F0F0</Color>
								<Color x:Key="Color_008">#FFF3F3F3</Color>
								<Color x:Key="Color_009">#FFFFFFFF</Color>
								<Color x:Key="Color_0010">#FFE6F2FA</Color>
								<Color x:Key="Color_010">#FFCDE6F7</Color>
								<Color x:Key="Color_011">#FF92C0E0</Color>
								<Color x:Key="Color_012">#FF2A8DD4</Color>
								<Color x:Key="Color_013">#FF0072C6</Color>
								<Color x:Key="Color_014">#FFD20000</Color>
								<Color x:Key="Color_015">#FF5B9BD5</Color>
								<Color x:Key="Color_016">#FFED7D31</Color>
								<Color x:Key="Color_017">#FFA5A5A5</Color>
								<Color x:Key="Color_018">#FFFFC000</Color>
								<Color x:Key="Color_019">#FF4472C4</Color>
								<Color x:Key="Color_020">#FF70AD47</Color>
								<Color x:Key="Color_021">#FF255E91</Color>
								<Color x:Key="Color_022">#FF9E480E</Color>
								<Color x:Key="Color_023">#FFE0CD8E</Color>
								<Color x:Key="Color_024">#FF997300</Color>
								<Color x:Key="Color_030">#FF5185B1</Color>
								<Color x:Key="Color_031">#FF6699C0</Color>
								<Color x:Key="Color_032">#FF7CACD0</Color>
								<Color x:Key="Color_040">#E5FFFFFF</Color>
								<Color x:Key="Color_041">#BFFFFFFF</Color>
								<Color x:Key="Color_042">#99FFFFFF</Color>
								<Color x:Key="Color_043">#72FFFFFF</Color>
								<Color x:Key="Color_044">#4CFFFFFF</Color>
								<Color x:Key="Color_045">#26FFFFFF</Color>
								<Color x:Key="Color_046">#00FFFFFF</Color>
								<Color x:Key="Color_050">#E5000000</Color>
								<Color x:Key="Color_051">#BF000000</Color>
								<Color x:Key="Color_052">#99000000</Color>
								<Color x:Key="Color_053">#72000000</Color>
								<Color x:Key="Color_054">#4C000000</Color>
								<Color x:Key="Color_055">#26000000</Color>
								<Color x:Key="Color_056">#19000000</Color>
								</ResourceDictionary>
							<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:d="http://schemas.microsoft.com/expression/blend/2008" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:System="clr-namespace:System;assembly=mscorlib" mc:Ignorable="d">
								<ResourceDictionary.MergedDictionaries>
									<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:d="http://schemas.microsoft.com/expression/blend/2008" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="d">
										<SolidColorBrush x:Key="Brush01" Color="#FF0072C6"/>
										<SolidColorBrush x:Key="Brush02" Color="White"/>
										<SolidColorBrush x:Key="Brush03" Color="#FF6D6D6D"/>
										<SolidColorBrush x:Key="Brush04" Color="#FFE1E1E1"/>
										<SolidColorBrush x:Key="Brush05" Color="#FFF3F3F3"/>
										<Color x:Key="Color_001">#FF444444</Color>
										<Color x:Key="Color_002">#FF6D6D6D</Color>
										<Color x:Key="Color_003">#FF777777</Color>
										<Color x:Key="Color_004">#FF959595</Color>
										<Color x:Key="Color_005">#FFABABAB</Color>
										<Color x:Key="Color_006">#FFE1E1E1</Color>
										<Color x:Key="Color_007">#FFF0F0F0</Color>
										<Color x:Key="Color_008">#FFF3F3F3</Color>
										<Color x:Key="Color_009">#FFFFFFFF</Color>
										<Color x:Key="Color_0010">#FFE6F2FA</Color>
										<Color x:Key="Color_010">#FFCDE6F7</Color>
										<Color x:Key="Color_011">#FF92C0E0</Color>
										<Color x:Key="Color_012">#FF2A8DD4</Color>
										<Color x:Key="Color_013">#FF0072C6</Color>
										<Color x:Key="Color_014">#FFD20000</Color>
										<Color x:Key="Color_015">#FF5B9BD5</Color>
										<Color x:Key="Color_016">#FFED7D31</Color>
										<Color x:Key="Color_017">#FFA5A5A5</Color>
										<Color x:Key="Color_018">#FFFFC000</Color>
										<Color x:Key="Color_019">#FF4472C4</Color>
										<Color x:Key="Color_020">#FF70AD47</Color>
										<Color x:Key="Color_021">#FF255E91</Color>
										<Color x:Key="Color_022">#FF9E480E</Color>
										<Color x:Key="Color_023">#FFE0CD8E</Color>
										<Color x:Key="Color_024">#FF997300</Color>
										<Color x:Key="Color_030">#FF5185B1</Color>
										<Color x:Key="Color_031">#FF6699C0</Color>
										<Color x:Key="Color_032">#FF7CACD0</Color>
										<Color x:Key="Color_040">#E5FFFFFF</Color>
										<Color x:Key="Color_041">#BFFFFFFF</Color>
										<Color x:Key="Color_042">#99FFFFFF</Color>
										<Color x:Key="Color_043">#72FFFFFF</Color>
										<Color x:Key="Color_044">#4CFFFFFF</Color>
										<Color x:Key="Color_045">#26FFFFFF</Color>
										<Color x:Key="Color_046">#00FFFFFF</Color>
										<Color x:Key="Color_050">#E5000000</Color>
										<Color x:Key="Color_051">#BF000000</Color>
										<Color x:Key="Color_052">#99000000</Color>
										<Color x:Key="Color_053">#72000000</Color>
										<Color x:Key="Color_054">#4C000000</Color>
										<Color x:Key="Color_055">#26000000</Color>
										<Color x:Key="Color_056">#19000000</Color>
										</ResourceDictionary>
								</ResourceDictionary.MergedDictionaries>
								<SolidColorBrush x:Key="ForegroundBrush" Color="{StaticResource Color_001}" />
								<SolidColorBrush x:Key="LightForegroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="TransparentBrush" Color="{StaticResource Color_046}" />
								<SolidColorBrush x:Key="DisabledBorderBrush" Color="{StaticResource Color_006}" />
								<SolidColorBrush x:Key="DisabledBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="DisabledForegroundBrush" Color="{StaticResource Color_002}" />
								<SolidColorBrush x:Key="ValidationErrorElement" Color="{StaticResource Color_014}" />
								<SolidColorBrush x:Key="HScrollbarThumbBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="HScrollbarThumbBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="VScrollbarThumbBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="VScrollbarThumbBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="VScrollbarThumbHoverBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="HScrollbarThumbHoverBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="VScrollbarThumbHoverBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="HScrollbarThumbHoverBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="VScrollbarThumbPressedBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="HScrollbarThumbPressedBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="VScrollbarThumbPressedBorderBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="HScrollbarThumbPressedBorderBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonArrowBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonArrowPressedBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonArrowHoverBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonPressedBackgroundBrush" Color="{StaticResource Color_007}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonHoverBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonPressedBorderBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarPageButtonHoverBorderBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="ScrollbarBackgroundBrush" Color="{StaticResource Color_008}" />
								<SolidColorBrush x:Key="ComboBoxBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ComboBoxBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="ComboBoxReadOnlyBorderBrush" Color="{StaticResource Color_006}" />
								<SolidColorBrush x:Key="ComboBoxReadOnlyBackgroundBrush" Color="{StaticResource Color_009 }" />
								<SolidColorBrush x:Key="ComboBoxHoverBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ComboBoxHoverBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ComboBoxFocusedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="PopupBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="PopupBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="TextBoxBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="TextBoxBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="TextBoxHoverBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="TextBoxHoverBorderBrush" Color="{StaticResource Color_011 }" />
								<SolidColorBrush x:Key="TextBoxFocusedBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="TextBoxReadOnlyBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="TextBoxReadOnlyBorderBrush" Color="{StaticResource Color_006}" />
								<SolidColorBrush x:Key="ButtonBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ButtonBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="ButtonHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="ButtonHoverBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ButtonPressedBackgroundBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ButtonPressedBorderBrush" Color="{StaticResource Color_012}" />
								<SolidColorBrush x:Key="ComboBoxItemHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="ComboBoxItemPressedBackgroundBrush" Color="{StaticResource Color_011 }" />
								<SolidColorBrush x:Key="ComboBoxItemFocusedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ComboBoxToggleButtonHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="ComboBoxToggleButtonHoverBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ComboBoxToggleButtonPressedBackgroundBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ComboBoxToggleButtonDisabledBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ComboBoxToggleButtonDisabledBorderBrush" Color="{StaticResource Color_006}" />
								<SolidColorBrush x:Key="ListBoxBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="ListBoxBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="ListBoxItemBackgroundBrush" Color="{StaticResource Color_046}" />
								<SolidColorBrush x:Key="ListBoxItemHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="ListBoxItemSelectedBackgroundBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="ListBoxItemFocusedBorderBrush" Color="{StaticResource Color_013}" />
								<SolidColorBrush x:Key="CheckBoxBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="CheckBoxHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="CheckBoxPressedBackgroundBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="CheckBoxFocusedBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="CheckBoxInvalidUnfocusedBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="CheckBoxInvalidFocusedBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="CheckBoxBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="CheckBoxHoverBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="CheckBoxPressedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="CheckBoxFocusedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="CheckBoxInvalidUnfocusedBorderBrush" Color="{StaticResource Color_014}" />
								<SolidColorBrush x:Key="CheckBoxInvalidFocusedBorderBrush" Color="{StaticResource Color_014}" />
								<SolidColorBrush x:Key="CheckBoxIndeterminateCheckBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="CheckBoxCheckBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="CheckBoxCheckHoverBackgroundBrush" Color="{StaticResource Color_001}" />
								<SolidColorBrush x:Key="RadioButtonBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="RadioButtonHoverBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="RadioButtonPressedBackgroundBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="RadioButtonFocusedBackgroundBrush" Color="{StaticResource Color_010}" />
								<SolidColorBrush x:Key="RadioButtonInvalidUnfocusedBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="RadioButtonInvalidFocusedBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="RadioButtonBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="RadioButtonHoverBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="RadioButtonPressedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="RadioButtonFocusedBorderBrush" Color="{StaticResource Color_011}" />
								<SolidColorBrush x:Key="RadioButtonInvalidUnfocusedBorderBrush" Color="{StaticResource Color_014}" />
								<SolidColorBrush x:Key="RadioButtonInvalidFocusedBorderBrush" Color="{StaticResource Color_014}" />
								<SolidColorBrush x:Key="RadioButtonCheckBackgroundBrush" Color="{StaticResource Color_001}" />
								<SolidColorBrush x:Key="GlyphBackgroundBrush" Color="{StaticResource Color_003}" />
								<SolidColorBrush x:Key="GlyphHoverBackgroundBrush" Color="{StaticResource Color_001}" />
								<SolidColorBrush x:Key="GlyphPressedBackgroundBrush" Color="{StaticResource Color_001}" />
								<SolidColorBrush x:Key="GlyphDisabledBackgroundBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="ValidationToolTipTemplateShadowBrush" Color="{StaticResource Color_056}" />
								<SolidColorBrush x:Key="TooltipBackgroundBrush" Color="{StaticResource Color_009}" />
								<SolidColorBrush x:Key="TooltipBorderBrush" Color="{StaticResource Color_005}" />
								<SolidColorBrush x:Key="TooltipShadowBrush" Color="{StaticResource Color_056}" />
								<Style x:Key="ToolTipStyle" TargetType="ContentControl">
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="Background" Value="{StaticResource TooltipBackgroundBrush}" />
									<Setter Property="BorderBrush" Value="{StaticResource TooltipBorderBrush}" />
									<Setter Property="Padding" Value="12,9" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="HorizontalAlignment" Value="Left" />
									<Setter Property="VerticalAlignment" Value="Center" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="ContentControl">
												<Grid>
													<Grid>
														<Border Background="{StaticResource TooltipShadowBrush}" CornerRadius="5" Margin="-4" Opacity="0.1" />
														<Border Background="{StaticResource TooltipShadowBrush}" CornerRadius="4" Margin="-3" Opacity="0.3" />
														<Border Background="{StaticResource TooltipShadowBrush}" CornerRadius="3" Margin="-2" Opacity="0.5" />
														<Border Background="{StaticResource TooltipShadowBrush}" CornerRadius="2" Margin="-1" Opacity="0.7" />
														<Rectangle Stroke="{TemplateBinding BorderBrush}" Fill="{TemplateBinding Background}" StrokeThickness="{TemplateBinding BorderThickness}" />
														<ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="{TemplateBinding HorizontalAlignment}" VerticalAlignment="{TemplateBinding VerticalAlignment}" />
													</Grid>
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style TargetType="ToolTip" BasedOn="{StaticResource ToolTipStyle}" />
								<ControlTemplate x:Key="ValidationToolTipTemplate">
									<Grid x:Name="Root" Margin="5,0" Opacity="0" RenderTransformOrigin="0,0">
										<Grid.RenderTransform>
											<TranslateTransform x:Name="xform" X="-25" />
										</Grid.RenderTransform>
										<VisualStateManager.VisualStateGroups>
											<VisualStateGroup x:Name="OpenStates">
												<VisualStateGroup.Transitions>
													<VisualTransition GeneratedDuration="0" />
													<VisualTransition GeneratedDuration="0:0:0.2" To="Open">
														<Storyboard>
															<DoubleAnimation Duration="0:0:0.2" To="0" Storyboard.TargetProperty="X" Storyboard.TargetName="xform">
																<DoubleAnimation.EasingFunction>
																	<BackEase Amplitude=".3" EasingMode="EaseOut" />
																</DoubleAnimation.EasingFunction>
															</DoubleAnimation>
															<DoubleAnimation Duration="0:0:0.2" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
														</Storyboard>
													</VisualTransition>
												</VisualStateGroup.Transitions>
												<VisualState x:Name="Closed">
													<Storyboard>
														<DoubleAnimation Duration="0" To="0" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
													</Storyboard>
												</VisualState>
												<VisualState x:Name="Open">
													<Storyboard>
														<DoubleAnimation Duration="0" To="0" Storyboard.TargetProperty="X" Storyboard.TargetName="xform" />
														<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
													</Storyboard>
												</VisualState>
											</VisualStateGroup>
										</VisualStateManager.VisualStateGroups>
										<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="4,4,-4,-4" Opacity="0.02" />
										<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="3,3,-3,-3" Opacity="0.08" />
										<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="2,2,-2,-2" Opacity="0.15" />
										<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="1,1,-1,-1" Opacity="0.21" />
										<Border Background="{StaticResource ValidationErrorElement}" />
										<Border>
											<TextBlock Foreground="{StaticResource LightForegroundBrush}" MaxWidth="250" Margin="8,4,8,4" TextWrapping="Wrap" Text="{Binding (Validation.Errors)[0].ErrorContent}" UseLayoutRounding="false" />
										</Border>
									</Grid>
								</ControlTemplate>
								<Style x:Key="ComboBoxToggleButtonStyle" TargetType="ToggleButton">
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="MinWidth" Value="14" />
									<Setter Property="MinHeight" Value="22" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="Padding" Value="2" />
									<Setter Property="Cursor" Value="Hand" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="ToggleButton">
												<Grid>
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource GlyphHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="hover" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Pressed">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource GlyphPressedBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="pressed" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource GlyphDisabledBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="disabled" />
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="CheckStates">
															<VisualState x:Name="Checked">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="ArrowSelected">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="pressed" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unchecked" />
															<VisualState x:Name="Indeterminate" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused" />
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Grid.ColumnDefinitions>
														<ColumnDefinition />
														<ColumnDefinition Width="14" />
													</Grid.ColumnDefinitions>
													<Rectangle x:Name="Bd" Fill="{StaticResource TransparentBrush}" Grid.ColumnSpan="2" />
													<Grid Grid.Column="1">
														<Rectangle x:Name="hover" Fill="{StaticResource ComboBoxItemHoverBackgroundBrush}" Stroke="{StaticResource ComboBoxToggleButtonHoverBorderBrush}" StrokeThickness="1" IsHitTestVisible="False" Opacity="0" />
														<Rectangle x:Name="pressed" Fill="{StaticResource ComboBoxItemPressedBackgroundBrush}" IsHitTestVisible="False" Opacity="0" />
														<Rectangle x:Name="disabled" Fill="{StaticResource ComboBoxToggleButtonDisabledBackgroundBrush}" Stroke="{StaticResource ComboBoxToggleButtonDisabledBorderBrush}" StrokeThickness="1" IsHitTestVisible="False" Opacity="0" />
														<Path x:Name="Arrow" Width="6" Height="4" Fill="{StaticResource GlyphBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" />
														<Path x:Name="ArrowSelected" Width="6" Height="4" Visibility="Collapsed" Fill="{StaticResource GlyphPressedBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" />
													</Grid>
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style x:Key="ComboBoxItemStyle" TargetType="ComboBoxItem">
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="Height" Value="22" />
									<Setter Property="Padding" Value="6,0" />
									<Setter Property="Margin" Value="1" />
									<Setter Property="HorizontalContentAlignment" Value="Left" />
									<Setter Property="VerticalContentAlignment" Value="Center" />
									<Setter Property="Background" Value="{StaticResource TransparentBrush}" />
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="ComboBoxItem">
												<Grid Background="{TemplateBinding Background}">
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="fillColor" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="DisabledVisualElement">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="SelectionStates">
															<VisualState x:Name="Unselected" />
															<VisualState x:Name="Selected">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="CheckedBd">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="SelectedUnfocused" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="Visibility" Storyboard.TargetName="FocusVisualElement">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="LayoutStates">
															<VisualState x:Name="AfterLoaded" />
															<VisualState x:Name="BeforeLoaded" />
															<VisualState x:Name="BeforeUnloaded" />
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Rectangle Fill="{StaticResource TransparentBrush}" />
													<Rectangle x:Name="fillColor" Fill="{StaticResource ComboBoxItemHoverBackgroundBrush}" IsHitTestVisible="False" Opacity="0" />
													<Rectangle x:Name="FocusVisualElement" Fill="{StaticResource ComboBoxItemHoverBackgroundBrush}" Visibility="Collapsed"  />
													<Rectangle x:Name="CheckedBd" Fill="{StaticResource ComboBoxItemPressedBackgroundBrush}" IsHitTestVisible="False" Visibility="Collapsed" />
													<ContentControl x:Name="contentControl" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" Margin="{TemplateBinding Padding}" Foreground="{TemplateBinding Foreground}">
														<ContentPresenter x:Name="contentPresenter" />
													</ContentControl>
													<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Visibility="Collapsed" />
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style x:Key="ListBoxItemStyle" TargetType="ListBoxItem">
									<Setter Property="Background" Value="{StaticResource ListBoxItemBackgroundBrush}" />
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="MinHeight" Value="22" />
									<Setter Property="Padding" Value="6,2" />
									<Setter Property="Margin" Value="0" />
									<Setter Property="HorizontalContentAlignment" Value="Stretch" />
									<Setter Property="VerticalContentAlignment" Value="Center" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="ListBoxItem">
												<Grid>
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ListBoxItemHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<DoubleAnimation Duration="0" To=".6" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="ContentControl" />
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="SelectionStates">
															<VisualState x:Name="Unselected" />
															<VisualState x:Name="Selected">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="BgSelected">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="SelectedUnfocused">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="BgSelected">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="FocusedVisualElement">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Rectangle x:Name="Bd" Fill="{TemplateBinding Background}" />
													<Rectangle x:Name="BgSelected" Fill="{StaticResource ListBoxItemSelectedBackgroundBrush}" Visibility="Collapsed" />
													<ContentControl x:Name="ContentControl" Foreground="{TemplateBinding Foreground}" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" HorizontalContentAlignment="{TemplateBinding HorizontalContentAlignment}">
														<ContentPresenter x:Name="contentPresenter" />
													</ContentControl>
													<Rectangle x:Name="FocusedVisualElement" IsHitTestVisible="False" Visibility="Collapsed" Stroke="{StaticResource ListBoxItemFocusedBorderBrush}" StrokeThickness="1" />
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style x:Key="CheckBoxStyle" TargetType="CheckBox">
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="HorizontalContentAlignment" Value="Left" />
									<Setter Property="VerticalContentAlignment" Value="Center" />
									<Setter Property="Padding" Value="6,0,0,0" />
									<Setter Property="MinHeight" Value="13" />
									<Setter Property="MinWidth" Value="13" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="CheckBox">
												<Grid VerticalAlignment="{TemplateBinding VerticalContentAlignment}" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" SnapsToDevicePixels="True">
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="hover" />
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="checkBox" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource CheckBoxCheckHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="IndeterminateCheck" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource CheckBoxCheckHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Pressed">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="pressed" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="checkBox" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledForegroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="normal" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="normal" Storyboard.TargetProperty="Stroke">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="CheckStates">
															<VisualState x:Name="Checked">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="checkBox" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unchecked" />
															<VisualState x:Name="Indeterminate">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="IndeterminateCheck" />
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="focused" />
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="checkBox" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource CheckBoxCheckHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="ValidationStates">
															<VisualState x:Name="Valid" />
															<VisualState x:Name="InvalidUnfocused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="invalidUnfocused" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="InvalidFocused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="invalidFocused" />
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Grid.ColumnDefinitions>
														<ColumnDefinition Width="13" />
														<ColumnDefinition Width="*" />
													</Grid.ColumnDefinitions>
													<Rectangle Fill="{StaticResource TransparentBrush}" />
													<Rectangle x:Name="normal" Opacity="1" Stroke="{StaticResource CheckBoxBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxBackgroundBrush}" Width="13" Height="13" />
													<Rectangle x:Name="hover" Stroke="{StaticResource CheckBoxHoverBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxHoverBackgroundBrush}" Opacity="0" Width="13" Height="13" />
													<Rectangle x:Name="focused" Opacity="0" Stroke="{StaticResource CheckBoxFocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxFocusedBackgroundBrush}" Width="13" Height="13" />
													<Rectangle x:Name="pressed" Opacity="0" Stroke="{StaticResource CheckBoxPressedBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxPressedBackgroundBrush}" Width="13" Height="13" />
													<Rectangle x:Name="invalidUnfocused" Opacity="0" Stroke="{StaticResource CheckBoxInvalidUnfocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxInvalidUnfocusedBackgroundBrush}" Width="13" Height="13" />
													<Rectangle x:Name="invalidFocused" Opacity="0" Stroke="{StaticResource CheckBoxInvalidFocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource CheckBoxInvalidFocusedBackgroundBrush}" Width="13" Height="13" />
													<Path x:Name="checkBox" Height="8" Width="8" Stretch="Fill" Opacity="0" Data="M 1145.607177734375,430 C1145.607177734375,430 1141.449951171875,435.0772705078125 1141.449951171875,435.0772705078125 1141.449951171875,435.0772705078125 1139.232177734375,433.0999755859375 1139.232177734375,433.0999755859375 1139.232177734375,433.0999755859375 1138,434.5538330078125 1138,434.5538330078125 1138,434.5538330078125 1141.482177734375,438 1141.482177734375,438 1141.482177734375,438 1141.96875,437.9375 1141.96875,437.9375 1141.96875,437.9375 1147,431.34619140625 1147,431.34619140625 1147,431.34619140625 1145.607177734375,430 1145.607177734375,430 z" Fill="{StaticResource CheckBoxCheckBackgroundBrush}" UseLayoutRounding="False" />
													<Rectangle x:Name="IndeterminateCheck" Fill="{StaticResource CheckBoxIndeterminateCheckBackgroundBrush}" Height="7" Width="7" Opacity="0" />
													<ContentPresenter x:Name="contentPresenter" ContentTemplate="{TemplateBinding ContentTemplate}" Content="{TemplateBinding Content}" Grid.Column="1" Margin="{TemplateBinding Padding}" />
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style x:Key="RadioButtonStyle" TargetType="RadioButton">
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="HorizontalContentAlignment" Value="Left" />
									<Setter Property="VerticalContentAlignment" Value="Center" />
									<Setter Property="Padding" Value="6,0,0,0" />
									<Setter Property="MinHeight" Value="12" />
									<Setter Property="MinWidth" Value="12" />
									<Setter Property="BorderThickness" Value="1" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="RadioButton">
												<Grid>
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="hover" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Pressed">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="pressed" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="normal" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="normal" Storyboard.TargetProperty="Stroke">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="CheckStates">
															<VisualState x:Name="Checked">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="Checked1" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unchecked" />
															<VisualState x:Name="Indeterminate" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="focused" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
														<VisualStateGroup x:Name="ValidationStates">
															<VisualState x:Name="Valid" />
															<VisualState x:Name="InvalidUnfocused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="invalidUnfocused" />
																</Storyboard>
															</VisualState>
															<VisualState x:Name="InvalidFocused">
																<Storyboard>
																	<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="invalidFocused" />
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Grid.ColumnDefinitions>
														<ColumnDefinition Width="12" />
														<ColumnDefinition Width="*" />
													</Grid.ColumnDefinitions>
													<Ellipse x:Name="normal" Opacity="1" Stroke="{StaticResource RadioButtonBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonBackgroundBrush}" Width="12" Height="12" />
													<Ellipse x:Name="hover" Stroke="{StaticResource RadioButtonHoverBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonHoverBackgroundBrush}" Opacity="0" Width="12" Height="12" />
													<Ellipse x:Name="focused" Opacity="0" Stroke="{StaticResource RadioButtonFocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonFocusedBackgroundBrush}" Width="12" Height="12" />
													<Ellipse x:Name="pressed" Opacity="0" Stroke="{StaticResource RadioButtonPressedBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonPressedBackgroundBrush}" Width="12" Height="12" />
													<Ellipse x:Name="invalidUnfocused" Opacity="0" Stroke="{StaticResource RadioButtonInvalidUnfocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonInvalidUnfocusedBackgroundBrush}" Width="12" Height="12" />
													<Ellipse x:Name="invalidFocused" Opacity="0" Stroke="{StaticResource RadioButtonInvalidFocusedBorderBrush}" StrokeThickness="1" Fill="{StaticResource RadioButtonInvalidFocusedBackgroundBrush}" Width="12" Height="12" />
													<Ellipse x:Name="Checked1" Fill="{StaticResource RadioButtonCheckBackgroundBrush}" Opacity="0" Width="6" Height="6" />
													<ContentPresenter x:Name="contentPresenter" ContentTemplate="{TemplateBinding ContentTemplate}" Content="{TemplateBinding Content}" Grid.Column="1" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" />
													</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
								<Style x:Key="ButtonStyle" TargetType="Button">
									<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
									<Setter Property="FontSize" Value="12" />
									<Setter Property="FontFamily" Value="Segoe UI" />
									<Setter Property="Padding" Value="7,0,7,2" />
									<Setter Property="MinHeight" Value="24" />
									<Setter Property="MinWidth" Value="30" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="Button">
												<Grid>
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBorderBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Pressed">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBackgroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBorderBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="DisabledVisualElement">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																	<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Foreground" Storyboard.TargetName="ContentControl">
																		<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledForegroundBrush}" />
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
														</VisualStateGroup>
														<VisualStateGroup x:Name="FocusStates">
															<VisualState x:Name="Focused">
																<Storyboard>
																	<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="FocusedVisualElement">
																		<DiscreteObjectKeyFrame KeyTime="0">
																			<DiscreteObjectKeyFrame.Value>
																				<Visibility>Visible</Visibility>
																			</DiscreteObjectKeyFrame.Value>
																		</DiscreteObjectKeyFrame>
																	</ObjectAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Unfocused" />
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Rectangle x:Name="Bd" Fill="{StaticResource ButtonBackgroundBrush}" Stroke="{StaticResource ButtonBorderBrush}" StrokeThickness="1" />
													<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Stroke="{StaticResource DisabledBorderBrush}" StrokeThickness="1" Visibility="Collapsed" />
													<ContentControl x:Name="ContentControl" Foreground="{TemplateBinding Foreground}" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}">
														<ContentPresenter x:Name="contentPresenter" />
													</ContentControl>
													<Rectangle x:Name="FocusedVisualElement" Stroke="{StaticResource ButtonHoverBorderBrush}" Visibility="Collapsed" StrokeThickness="1" />
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Style>
							</ResourceDictionary>
						</ResourceDictionary.MergedDictionaries>
						<Style x:Key="ScrollBarButtonStyle" TargetType="{x:Type RepeatButton}">
							<Setter Property="MinWidth" Value="15" />
							<Setter Property="MinHeight" Value="15" />
							<Setter Property="Padding" Value="0" />
							<Setter Property="OverridesDefaultStyle" Value="true" />
							<Setter Property="Focusable" Value="false" />
							<Setter Property="IsTabStop" Value="false" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type RepeatButton}">
										<Grid x:Name="grid1">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonArrowHoverBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Background" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonHoverBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="BorderBrush" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonHoverBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Pressed">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonArrowPressedBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Background" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonPressedBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="BorderBrush" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ScrollbarPageButtonPressedBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Disabled">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Arrow">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Background" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="BorderBrush" Storyboard.TargetName="Bg">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Border x:Name="Bg" Background="{StaticResource ScrollbarPageButtonBackgroundBrush}" BorderBrush="{StaticResource ScrollbarPageButtonBorderBrush}" BorderThickness="1" />
											<Path x:Name="Arrow" Data="M0,4 L7,4 L4,0 z" Height="4" Stretch="Uniform" Width="7" Fill="{StaticResource ScrollbarPageButtonArrowBackgroundBrush}" Margin="{TemplateBinding Padding}" />
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<Style x:Key="ScrollBarPageButtonStyle" TargetType="{x:Type RepeatButton}">
							<Setter Property="OverridesDefaultStyle" Value="true" />
							<Setter Property="Background" Value="Transparent" />
							<Setter Property="Focusable" Value="false" />
							<Setter Property="IsTabStop" Value="false" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type RepeatButton}">
										<Rectangle Fill="{TemplateBinding Background}" Height="{TemplateBinding Height}" Width="{TemplateBinding Width}">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver" />
													<VisualState x:Name="Pressed" />
													<VisualState x:Name="Disabled" />
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
										</Rectangle>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<Style x:Key="HScrollBarThumbStyle" TargetType="{x:Type Thumb}">
							<Setter Property="MinWidth" Value="5" />
							<Setter Property="MinHeight" Value="15" />
							<Setter Property="OverridesDefaultStyle" Value="true" />
							<Setter Property="IsTabStop" Value="false" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type Thumb}">
										<Grid Margin="0">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource HScrollbarThumbHoverBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource HScrollbarThumbHoverBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Pressed">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource HScrollbarThumbPressedBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource HScrollbarThumbPressedBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Disabled">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Rectangle x:Name="Thumb" Fill="{StaticResource HScrollbarThumbBackgroundBrush}" Stroke="{StaticResource HScrollbarThumbBorderBrush}" Height="15" />
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<Style x:Key="VScrollBarThumbStyle" TargetType="{x:Type Thumb}">
							<Setter Property="OverridesDefaultStyle" Value="true" />
							<Setter Property="MinWidth" Value="15" />
							<Setter Property="MinHeight" Value="5" />
							<Setter Property="Stylus.IsPressAndHoldEnabled" Value="false" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type Thumb}">
										<Grid x:Name="grid" Height="Auto" Width="Auto">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource VScrollbarThumbHoverBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource VScrollbarThumbHoverBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Pressed">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource VScrollbarThumbPressedBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource VScrollbarThumbPressedBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Disabled">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="Thumb">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Rectangle x:Name="Thumb" Fill="{StaticResource VScrollbarThumbBackgroundBrush}" Stroke="{StaticResource VScrollbarThumbBorderBrush}" Width="15" />
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<Style x:Key="ScrollBarStyle" TargetType="{x:Type ScrollBar}">
							<Setter Property="Background" Value="{StaticResource ScrollbarBackgroundBrush}" />
							<Setter Property="Stylus.IsPressAndHoldEnabled" Value="false" />
							<Setter Property="Stylus.IsFlicksEnabled" Value="false" />
							<Setter Property="Width" Value="15" />
							<Setter Property="MinWidth" Value="15" />
							<Setter Property="Margin" Value="1" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type ScrollBar}">
										<Grid x:Name="Bg" SnapsToDevicePixels="true">
											<Grid.RowDefinitions>
												<RowDefinition Height="15" />
												<RowDefinition Height="*" />
												<RowDefinition Height="15" />
											</Grid.RowDefinitions>
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualStateGroup.Transitions>
														<VisualTransition GeneratedDuration="0:0:0.3" />
													</VisualStateGroup.Transitions>
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver" />
													<VisualState x:Name="Disabled" />
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Rectangle Grid.RowSpan="3" Fill="{TemplateBinding Background}" />
											<RepeatButton x:Name="repeatButton" Command="{x:Static ScrollBar.LineUpCommand}" IsEnabled="True" Style="{StaticResource ScrollBarButtonStyle}" HorizontalAlignment="Center" />
											<Track x:Name="PART_Track" IsDirectionReversed="true" IsEnabled="True" Grid.Row="1">
												<Track.DecreaseRepeatButton>
													<RepeatButton Command="{x:Static ScrollBar.PageUpCommand}" Style="{StaticResource ScrollBarPageButtonStyle}" />
												</Track.DecreaseRepeatButton>
												<Track.IncreaseRepeatButton>
													<RepeatButton Command="{x:Static ScrollBar.PageDownCommand}" Style="{StaticResource ScrollBarPageButtonStyle}" />
												</Track.IncreaseRepeatButton>
												<Track.Thumb>
													<Thumb x:Name="thumb" Style="{StaticResource VScrollBarThumbStyle}" HorizontalAlignment="Center" Width="30" />
												</Track.Thumb>
											</Track>
											<RepeatButton x:Name="repeatButton1" Command="{x:Static ScrollBar.LineDownCommand}" IsEnabled="True" Grid.Row="2" Style="{StaticResource ScrollBarButtonStyle}" RenderTransformOrigin="0.5,0.5" HorizontalAlignment="Center">
												<RepeatButton.RenderTransform>
													<TransformGroup>
														<ScaleTransform />
														<SkewTransform />
														<RotateTransform Angle="180" />
														<TranslateTransform />
													</TransformGroup>
												</RepeatButton.RenderTransform>
											</RepeatButton>
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
							<Style.Triggers>
								<Trigger Property="Orientation" Value="Horizontal">
									<Setter Property="Width" Value="Auto" />
									<Setter Property="MinWidth" Value="0" />
									<Setter Property="Height" Value="15" />
									<Setter Property="MinHeight" Value="15" />
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="{x:Type ScrollBar}">
												<Grid x:Name="Bg" SnapsToDevicePixels="true">
													<Grid.ColumnDefinitions>
														<ColumnDefinition Width="15" />
														<ColumnDefinition Width="*" />
														<ColumnDefinition Width="15" />
													</Grid.ColumnDefinitions>
													<VisualStateManager.VisualStateGroups>
														<VisualStateGroup x:Name="CommonStates">
															<VisualStateGroup.Transitions>
																<VisualTransition GeneratedDuration="0:0:0.3" />
															</VisualStateGroup.Transitions>
															<VisualState x:Name="Normal" />
															<VisualState x:Name="MouseOver">
																<Storyboard>
																	<DoubleAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="repeatButton">
																		<EasingDoubleKeyFrame KeyTime="0" Value="1" />
																	</DoubleAnimationUsingKeyFrames>
																	<DoubleAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="repeatButton1">
																		<EasingDoubleKeyFrame KeyTime="0" Value="1" />
																	</DoubleAnimationUsingKeyFrames>
																</Storyboard>
															</VisualState>
															<VisualState x:Name="Disabled" />
														</VisualStateGroup>
													</VisualStateManager.VisualStateGroups>
													<Rectangle Grid.ColumnSpan="5" Fill="{TemplateBinding Background}" />
													<RepeatButton x:Name="repeatButton" Command="{x:Static ScrollBar.LineLeftCommand}" IsEnabled="True" Style="{DynamicResource ScrollBarButtonStyle}" Opacity="1" RenderTransformOrigin="0.5,0.5" VerticalAlignment="Center">
														<RepeatButton.RenderTransform>
															<TransformGroup>
																<ScaleTransform />
																<SkewTransform />
																<RotateTransform Angle="-90" />
																<TranslateTransform />
															</TransformGroup>
														</RepeatButton.RenderTransform>
													</RepeatButton>
													<Track x:Name="PART_Track" Grid.Column="1" IsEnabled="True">
														<Track.DecreaseRepeatButton>
															<RepeatButton Command="{x:Static ScrollBar.PageLeftCommand}" Style="{StaticResource ScrollBarPageButtonStyle}" />
														</Track.DecreaseRepeatButton>
														<Track.IncreaseRepeatButton>
															<RepeatButton Command="{x:Static ScrollBar.PageRightCommand}" Style="{StaticResource ScrollBarPageButtonStyle}" />
														</Track.IncreaseRepeatButton>
														<Track.Thumb>
															<Thumb Style="{StaticResource HScrollBarThumbStyle}" VerticalAlignment="Center" Height="30" />
														</Track.Thumb>
													</Track>
													<RepeatButton x:Name="repeatButton1" Grid.Column="2" Command="{x:Static ScrollBar.LineRightCommand}" IsEnabled="True" Style="{DynamicResource ScrollBarButtonStyle}" Opacity="1" RenderTransformOrigin="0.5,0.5" VerticalAlignment="Center">
														<RepeatButton.RenderTransform>
															<TransformGroup>
																<ScaleTransform />
																<SkewTransform />
																<RotateTransform Angle="90" />
																<TranslateTransform />
															</TransformGroup>
														</RepeatButton.RenderTransform>
													</RepeatButton>
												</Grid>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
								</Trigger>
							</Style.Triggers>
						</Style>
						<Style x:Key="ScrollViewerStyle" TargetType="{x:Type ScrollViewer}">
							<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
							<Setter Property="HorizontalContentAlignment" Value="Left" />
							<Setter Property="VerticalContentAlignment" Value="Top" />
							<Setter Property="VerticalScrollBarVisibility" Value="Auto" />
							<Setter Property="Padding" Value="0" />
							<Setter Property="BorderThickness" Value="1" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type ScrollViewer}">
										<Grid x:Name="Grid">
											<Grid.ColumnDefinitions>
												<ColumnDefinition Width="*" />
												<ColumnDefinition Width="Auto" />
											</Grid.ColumnDefinitions>
											<Grid.RowDefinitions>
												<RowDefinition Height="*" />
												<RowDefinition Height="Auto" />
											</Grid.RowDefinitions>
											<ScrollContentPresenter x:Name="PART_ScrollContentPresenter" CanContentScroll="{TemplateBinding CanContentScroll}" CanHorizontallyScroll="False" CanVerticallyScroll="False" ContentTemplate="{TemplateBinding ContentTemplate}" Content="{TemplateBinding Content}" Grid.Column="0" Margin="{TemplateBinding Padding}" Grid.Row="0" />
											<ScrollBar x:Name="PART_VerticalScrollBar" AutomationProperties.AutomationId="VerticalScrollBar" Cursor="Arrow" Grid.Column="1" Maximum="{TemplateBinding ScrollableHeight}" Minimum="0" Grid.Row="0" Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}" Value="{Binding VerticalOffset, Mode=OneWay, RelativeSource={RelativeSource TemplatedParent}}" ViewportSize="{TemplateBinding ViewportHeight}" Style="{StaticResource ScrollBarStyle}" />
											<ScrollBar x:Name="PART_HorizontalScrollBar" AutomationProperties.AutomationId="HorizontalScrollBar" Cursor="Arrow" Grid.Column="0" Maximum="{TemplateBinding ScrollableWidth}" Minimum="0" Orientation="Horizontal" Grid.Row="1" Visibility="{TemplateBinding ComputedHorizontalScrollBarVisibility}" Value="{Binding HorizontalOffset, Mode=OneWay, RelativeSource={RelativeSource TemplatedParent}}" ViewportSize="{TemplateBinding ViewportWidth}" Style="{StaticResource ScrollBarStyle}" />
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<ControlTemplate x:Key="TextBoxValidationToolTipTemplate">
							<Grid x:Name="Root" Margin="5,0" Opacity="0" RenderTransformOrigin="0,0">
								<Grid.RenderTransform>
									<TranslateTransform x:Name="xform" X="-25" />
								</Grid.RenderTransform>
								<VisualStateManager.VisualStateGroups>
									<VisualStateGroup x:Name="OpenStates">
										<VisualStateGroup.Transitions>
											<VisualTransition GeneratedDuration="0" />
											<VisualTransition GeneratedDuration="0:0:0.2" To="Open">
												<Storyboard>
													<DoubleAnimation Duration="0:0:0.2" To="0" Storyboard.TargetProperty="X" Storyboard.TargetName="xform">
														<DoubleAnimation.EasingFunction>
															<BackEase Amplitude=".3" EasingMode="EaseOut" />
														</DoubleAnimation.EasingFunction>
													</DoubleAnimation>
													<DoubleAnimation Duration="0:0:0.2" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
												</Storyboard>
											</VisualTransition>
										</VisualStateGroup.Transitions>
										<VisualState x:Name="Closed">
											<Storyboard>
												<DoubleAnimation Duration="0" To="0" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
											</Storyboard>
										</VisualState>
										<VisualState x:Name="Open">
											<Storyboard>
												<DoubleAnimation Duration="0" To="0" Storyboard.TargetProperty="X" Storyboard.TargetName="xform" />
												<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="Root" />
											</Storyboard>
										</VisualState>
									</VisualStateGroup>
								</VisualStateManager.VisualStateGroups>
								<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="4,4,-4,-4" Opacity="0.02" />
								<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="3,3,-3,-3" Opacity="0.08" />
								<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="2,2,-2,-2" Opacity="0.15" />
								<Border Background="{StaticResource ValidationToolTipTemplateShadowBrush}" Margin="1,1,-1,-1" Opacity="0.21" />
								<Border Background="{StaticResource ValidationErrorElement}" />
								<Border>
									<TextBlock Foreground="{StaticResource LightForegroundBrush}" MaxWidth="250" Margin="8,4,8,4" TextWrapping="Wrap" Text="{Binding (Validation.Errors).CurrentItem.ErrorContent}" UseLayoutRounding="false" />
								</Border>
							</Grid>
						</ControlTemplate>
						<Style x:Key="ComboBoxEditableTextBoxStyle" TargetType="{x:Type TextBox}">
							<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
							<Setter Property="FontSize" Value="12" />
							<Setter Property="FontFamily" Value="Segoe UI" />
							<Setter Property="OverridesDefaultStyle" Value="true" />
							<Setter Property="AllowDrop" Value="true" />
							<Setter Property="MinWidth" Value="0" />
							<Setter Property="Padding" Value="4,2" />
							<Setter Property="FocusVisualStyle" Value="{x:Null}" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type TextBox}">
										<ScrollViewer Style="{StaticResource ScrollViewerStyle}" x:Name="PART_ContentHost" Background="Transparent" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="Disabled">
														<Storyboard>
															<DoubleAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Opacity)" Storyboard.TargetName="PART_ContentHost">
																<EasingDoubleKeyFrame KeyTime="0" Value="0.3" />
															</DoubleAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="ReadOnly" />
													<VisualState x:Name="MouseOver" />
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
										</ScrollViewer>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<ControlTemplate x:Key="ComboBoxEditableTemplate" TargetType="{x:Type ComboBox}">
							<Grid x:Name="MainGrid" SnapsToDevicePixels="true">
								<Grid.ColumnDefinitions>
									<ColumnDefinition Width="*" />
									<ColumnDefinition Width="Auto" />
								</Grid.ColumnDefinitions>
								<VisualStateManager.VisualStateGroups>
									<VisualStateGroup x:Name="CommonStates">
										<VisualState x:Name="Normal" />
										<VisualState x:Name="MouseOver">
											<Storyboard>
												<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="hover">
													<DiscreteObjectKeyFrame KeyTime="0">
														<DiscreteObjectKeyFrame.Value>
															<Visibility>Visible</Visibility>
														</DiscreteObjectKeyFrame.Value>
													</DiscreteObjectKeyFrame>
												</ObjectAnimationUsingKeyFrames>
											</Storyboard>
										</VisualState>
										<VisualState x:Name="Disabled">
											<Storyboard>
												<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="normal">
													<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
												</ObjectAnimationUsingKeyFrames>
												<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="normal">
													<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
												</ObjectAnimationUsingKeyFrames>
												</Storyboard>
										</VisualState>
									</VisualStateGroup>
									<VisualStateGroup x:Name="FocusStates">
										<VisualState x:Name="Unfocused" />
										<VisualState x:Name="Focused">
											<Storyboard>
												<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="focused">
													<DiscreteObjectKeyFrame KeyTime="0">
														<DiscreteObjectKeyFrame.Value>
															<Visibility>Visible</Visibility>
														</DiscreteObjectKeyFrame.Value>
													</DiscreteObjectKeyFrame>
												</ObjectAnimationUsingKeyFrames>
											</Storyboard>
										</VisualState>
										<VisualState x:Name="FocusedDropDown">
											<Storyboard>
												<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="focused">
													<DiscreteObjectKeyFrame KeyTime="0">
														<DiscreteObjectKeyFrame.Value>
															<Visibility>Visible</Visibility>
														</DiscreteObjectKeyFrame.Value>
													</DiscreteObjectKeyFrame>
												</ObjectAnimationUsingKeyFrames>
											</Storyboard>
										</VisualState>
									</VisualStateGroup>
								</VisualStateManager.VisualStateGroups>
								<Rectangle x:Name="normal" Fill="{StaticResource ComboBoxBackgroundBrush}" Stroke="{StaticResource ComboBoxBorderBrush}" StrokeThickness="1" Grid.ColumnSpan="2" />
								<Rectangle x:Name="hover" Fill="{StaticResource ComboBoxHoverBackgroundBrush}" Stroke="{StaticResource ComboBoxHoverBorderBrush}" StrokeThickness="1" Visibility="Collapsed" Grid.ColumnSpan="2" />
								<Popup x:Name="PART_Popup" AllowsTransparency="true" Grid.ColumnSpan="2" IsOpen="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}}" Margin="1" PopupAnimation="{DynamicResource {x:Static SystemParameters.ComboBoxPopupAnimationKey}}" Placement="Bottom">
									<Border x:Name="DropDownBorder" HorizontalAlignment="Stretch" Background="{StaticResource PopupBackgroundBrush}" BorderBrush="{StaticResource PopupBorderBrush}" BorderThickness="1" MaxHeight="{TemplateBinding MaxDropDownHeight}" MinWidth="{Binding ActualWidth, ElementName=MainGrid}" >
										<ScrollViewer x:Name="DropDownScrollViewer" Style="{StaticResource ScrollViewerStyle}">
											<Grid RenderOptions.ClearTypeHint="Enabled">
												<Canvas HorizontalAlignment="Left" Height="0" VerticalAlignment="Top" Width="0">
													<Rectangle x:Name="OpaqueRect" Fill="{Binding Background, ElementName=DropDownBorder}" Height="{Binding ActualHeight, ElementName=DropDownBorder}" Width="{Binding ActualWidth, ElementName=DropDownBorder}" />
												</Canvas>
												<ItemsPresenter x:Name="ItemsPresenter" KeyboardNavigation.DirectionalNavigation="Contained" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" />
											</Grid>
										</ScrollViewer>
									</Border>
								</Popup>
								<ToggleButton BorderBrush="{TemplateBinding BorderBrush}" Background="{TemplateBinding Background}" Grid.Column="1" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" Style="{StaticResource ComboBoxToggleButtonStyle}" />
								<TextBox x:Name="PART_EditableTextBox" HorizontalContentAlignment="{TemplateBinding HorizontalContentAlignment}" IsReadOnly="{Binding IsReadOnly, RelativeSource={RelativeSource TemplatedParent}}" Style="{StaticResource ComboBoxEditableTextBoxStyle}" VerticalContentAlignment="{TemplateBinding VerticalContentAlignment}" Margin="0,0,5,0" />
								<Rectangle x:Name="focused" Stroke="{StaticResource ComboBoxFocusedBorderBrush}" StrokeThickness="1" Visibility="Collapsed" Grid.ColumnSpan="2" />
								</Grid>
							<ControlTemplate.Triggers>
								<Trigger Property="HasItems" Value="false">
									<Setter Property="Height" TargetName="DropDownBorder" Value="95" />
								</Trigger>
							</ControlTemplate.Triggers>
						</ControlTemplate>
						<Style x:Key="ComboBoxStyle" TargetType="{x:Type ComboBox}">
							<Setter Property="Padding" Value="4,2,20,2" />
							<Setter Property="Margin" Value="0" />
							<Setter Property="FontSize" Value="12" />
							<Setter Property="FontFamily" Value="Segoe UI" />
							<Setter Property="Height" Value="22" />
							<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
							<Setter Property="Background" Value="{StaticResource TransparentBrush}" />
							<Setter Property="BorderBrush" Value="{StaticResource ComboBoxBorderBrush}" />
							<Setter Property="ItemContainerStyle" Value="{StaticResource ComboBoxItemStyle}" />
							<Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto" />
							<Setter Property="ScrollViewer.VerticalScrollBarVisibility" Value="Auto" />
							<Setter Property="ScrollViewer.CanContentScroll" Value="true" />
							<Setter Property="ScrollViewer.PanningMode" Value="Both" />
							<Setter Property="Stylus.IsFlicksEnabled" Value="False" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type ComboBox}">
										<Grid x:Name="MainGrid" SnapsToDevicePixels="true">
											<Grid.ColumnDefinitions>
												<ColumnDefinition Width="*" />
												<ColumnDefinition MinWidth="14"  />
											</Grid.ColumnDefinitions>
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="hover">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Disabled">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Fill" Storyboard.TargetName="normal">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBackgroundBrush}" />
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="Stroke" Storyboard.TargetName="normal">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource DisabledBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
												<VisualStateGroup x:Name="FocusStates">
													<VisualState x:Name="Unfocused" />
													<VisualState x:Name="Focused">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="focused">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="FocusedDropDown">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="focused">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Rectangle x:Name="normal" Fill="{StaticResource ComboBoxBackgroundBrush}" Stroke="{StaticResource ComboBoxBorderBrush}" StrokeThickness="1" Grid.ColumnSpan="2" />
											<Rectangle x:Name="hover" Fill="{StaticResource ComboBoxHoverBackgroundBrush}" Stroke="{StaticResource ComboBoxHoverBorderBrush}" StrokeThickness="1" Visibility="Collapsed" Grid.ColumnSpan="2" />
											<Popup x:Name="PART_Popup" AllowsTransparency="true" Grid.ColumnSpan="2" IsOpen="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}}" Margin="1" PopupAnimation="{DynamicResource {x:Static SystemParameters.ComboBoxPopupAnimationKey}}" Placement="Bottom">
												<Border x:Name="DropDownBorder" HorizontalAlignment="Stretch" Background="{StaticResource PopupBackgroundBrush}" BorderBrush="{StaticResource PopupBorderBrush}" BorderThickness="1" MaxHeight="{TemplateBinding MaxDropDownHeight}" MinWidth="{Binding ActualWidth, ElementName=MainGrid}" >
													<ScrollViewer x:Name="DropDownScrollViewer" Style="{StaticResource ScrollViewerStyle}">
														<Grid RenderOptions.ClearTypeHint="Enabled">
															<Canvas HorizontalAlignment="Left" Height="0" VerticalAlignment="Top" Width="0">
																<Rectangle x:Name="OpaqueRect" Fill="{Binding Background, ElementName=DropDownBorder}" Height="{Binding ActualHeight, ElementName=DropDownBorder}" Width="{Binding ActualWidth, ElementName=DropDownBorder}" />
															</Canvas>
															<ItemsPresenter x:Name="ItemsPresenter" KeyboardNavigation.DirectionalNavigation="Contained" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" />
														</Grid>
													</ScrollViewer>
												</Border>
											</Popup>
											<ToggleButton Grid.ColumnSpan="2" BorderBrush="{TemplateBinding BorderBrush}" Background="{TemplateBinding Background}" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" Style="{StaticResource ComboBoxToggleButtonStyle}" />
											<ContentPresenter Grid.ColumnSpan="2" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" Content="{TemplateBinding SelectionBoxItem}" ContentStringFormat="{TemplateBinding SelectionBoxItemStringFormat}" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" IsHitTestVisible="false" Margin="{TemplateBinding Padding}" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" />
											<Rectangle x:Name="focused" Stroke="{StaticResource ComboBoxFocusedBorderBrush}" StrokeThickness="1" Visibility="Collapsed" Grid.ColumnSpan="2" />
										</Grid>
										<ControlTemplate.Triggers>
											<Trigger Property="HasItems" Value="false">
												<Setter Property="Height" TargetName="DropDownBorder" Value="95" />
											</Trigger>
											<Trigger Property="IsEnabled" Value="false">
												<Setter Property="Foreground" Value="{StaticResource DisabledForegroundBrush}" />
												<Setter Property="Background" Value="{StaticResource DisabledBackgroundBrush}" />
												<Setter Property="BorderBrush" Value="{StaticResource DisabledBorderBrush}" />
											</Trigger>
											<Trigger Property="IsGrouping" Value="true">
												<Setter Property="ScrollViewer.CanContentScroll" Value="false" />
											</Trigger>
											<Trigger Property="ScrollViewer.CanContentScroll" SourceName="DropDownScrollViewer" Value="false">
												<Setter Property="Canvas.Top" TargetName="OpaqueRect" Value="{Binding VerticalOffset, ElementName=DropDownScrollViewer}" />
												<Setter Property="Canvas.Left" TargetName="OpaqueRect" Value="{Binding HorizontalOffset, ElementName=DropDownScrollViewer}" />
											</Trigger>
										</ControlTemplate.Triggers>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
							<Style.Triggers>
								<Trigger Property="IsEditable" Value="true">
									<Setter Property="IsTabStop" Value="false" />
									<Setter Property="Padding" Value="0" />
									<Setter Property="Template" Value="{StaticResource ComboBoxEditableTemplate}" />
								</Trigger>
							</Style.Triggers>
						</Style>
						<Style x:Key="TextBoxStyle" TargetType="TextBox">
							<Setter Property="BorderThickness" Value="1" />
							<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
							<Setter Property="FontSize" Value="12" />
							<Setter Property="FontFamily" Value="Segoe UI" />
							<Setter Property="Background" Value="{StaticResource TextBoxBackgroundBrush}" />
							<Setter Property="BorderBrush" Value="{StaticResource TextBoxBorderBrush}" />
							<Setter Property="MinHeight" Value="22" />
							<Setter Property="Padding" Value="4,2" />
							<Setter Property="SelectionBrush" Value="{StaticResource TextBoxFocusedBrush}" />
							<Setter Property="Validation.ErrorTemplate" Value="{StaticResource TextBoxValidationToolTipTemplate}" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="TextBox">
										<Grid x:Name="RootElement" SnapsToDevicePixels="True">
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="CommonStates">
													<VisualState x:Name="Normal" />
													<VisualState x:Name="MouseOver">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Duration="0" Storyboard.TargetProperty="BorderBrush" Storyboard.TargetName="Border">
																<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource TextBoxHoverBorderBrush}" />
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Disabled">
														<Storyboard>
															<DoubleAnimation Duration="0" To="0.55" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="DisabledVisualElement" />
														</Storyboard>
													</VisualState>
													<VisualState x:Name="ReadOnly">
														<Storyboard>
															<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="ReadOnlyVisualElement" />
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
												<VisualStateGroup x:Name="FocusStates">
													<VisualState x:Name="Focused">
														<Storyboard>
															<DoubleAnimation Duration="0" To="1" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="FocusVisualElement" />
														</Storyboard>
													</VisualState>
													<VisualState x:Name="Unfocused">
														<Storyboard>
															<DoubleAnimation Duration="0" To="0" Storyboard.TargetProperty="Opacity" Storyboard.TargetName="FocusVisualElement" />
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
												<VisualStateGroup x:Name="ValidationStates">
													<VisualState x:Name="Valid" />
													<VisualState x:Name="InvalidUnfocused">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="Visibility" Storyboard.TargetName="ValidationErrorElement">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="InvalidFocused">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="Visibility" Storyboard.TargetName="ValidationErrorElement">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="IsOpen" Storyboard.TargetName="validationTooltip">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<System:Boolean>True</System:Boolean>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Grid>
												<Border x:Name="Border" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" Opacity="1" />
												<Border x:Name="DisabledVisualElement" BorderBrush="{StaticResource DisabledBorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{StaticResource DisabledBackgroundBrush}" IsHitTestVisible="False" Opacity="0" />
												<Border x:Name="ReadOnlyVisualElement" Background="{StaticResource TextBoxReadOnlyBackgroundBrush}" BorderBrush="{StaticResource TextBoxReadOnlyBorderBrush}" Opacity="0" />
												<ScrollViewer x:Name="PART_ContentHost" BorderThickness="0" IsTabStop="False" Padding="{TemplateBinding Padding}" />
											</Grid>
											<Border x:Name="FocusVisualElement" BorderBrush="{StaticResource TextBoxFocusedBrush}" BorderThickness="{TemplateBinding BorderThickness}" IsHitTestVisible="False" Opacity="0" />
											<Border x:Name="ValidationErrorElement" BorderBrush="{StaticResource ValidationErrorElement}" BorderThickness="{TemplateBinding BorderThickness}" Visibility="Collapsed">
												<ToolTipService.ToolTip>
													<ToolTip x:Name="validationTooltip" DataContext="{Binding RelativeSource={RelativeSource TemplatedParent}}" Placement="Right" PlacementTarget="{Binding RelativeSource={RelativeSource TemplatedParent}}" Template="{StaticResource TextBoxValidationToolTipTemplate}" />
												</ToolTipService.ToolTip>
												<Grid Background="Transparent" HorizontalAlignment="Right" Height="12" Margin="1,-4,-4,0" VerticalAlignment="Top" Width="12">
													<Path Data="M 1,0 L6,0 A 2,2 90 0 1 8,2 L8,7 z" Fill="{StaticResource ValidationErrorElement}" Margin="1,3,0,0" />
													<Path Data="M 0,0 L2,0 L 8,6 L8,8" Fill="{StaticResource LightForegroundBrush}" Margin="1,3,0,0" />
												</Grid>
											</Border>
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
						<Style x:Key="ListBoxStyle" TargetType="ListBox">
							<Setter Property="Padding" Value="0" />
							<Setter Property="Background" Value="{StaticResource ListBoxBackgroundBrush}" />
							<Setter Property="BorderBrush" Value="{StaticResource ListBoxBorderBrush}" />
							<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
							<Setter Property="HorizontalContentAlignment" Value="Left" />
							<Setter Property="VerticalContentAlignment" Value="Top" />
							<Setter Property="IsTabStop" Value="False" />
							<Setter Property="BorderThickness" Value="1" />
							<Setter Property="ItemContainerStyle" Value="{StaticResource ListBoxItemStyle}" />
							<Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto" />
							<Setter Property="ScrollViewer.VerticalScrollBarVisibility" Value="Auto" />
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="ListBox">
										<Grid>
											<VisualStateManager.VisualStateGroups>
												<VisualStateGroup x:Name="ValidationStates">
													<VisualState x:Name="Valid" />
													<VisualState x:Name="InvalidUnfocused">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="Visibility" Storyboard.TargetName="ValidationErrorElement">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
													<VisualState x:Name="InvalidFocused">
														<Storyboard>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="Visibility" Storyboard.TargetName="ValidationErrorElement">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<Visibility>Visible</Visibility>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
															<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="IsOpen" Storyboard.TargetName="validationTooltip">
																<DiscreteObjectKeyFrame KeyTime="0">
																	<DiscreteObjectKeyFrame.Value>
																		<System:Boolean>True</System:Boolean>
																	</DiscreteObjectKeyFrame.Value>
																</DiscreteObjectKeyFrame>
															</ObjectAnimationUsingKeyFrames>
														</Storyboard>
													</VisualState>
												</VisualStateGroup>
											</VisualStateManager.VisualStateGroups>
											<Border BorderThickness="{TemplateBinding BorderThickness}" BorderBrush="{TemplateBinding BorderBrush}" Background="{TemplateBinding Background}">
												<ScrollViewer x:Name="ScrollViewer" BorderThickness="0" Padding="{TemplateBinding Padding}" Style="{StaticResource ScrollViewerStyle}">
													<ItemsPresenter />
												</ScrollViewer>
											</Border>
											<Border x:Name="ValidationErrorElement" BorderBrush="{StaticResource ValidationErrorElement}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="2" Visibility="Collapsed">
												<ToolTipService.ToolTip>
													<ToolTip x:Name="validationTooltip" DataContext="{Binding RelativeSource={RelativeSource TemplatedParent}}" Placement="Right" PlacementTarget="{Binding RelativeSource={RelativeSource TemplatedParent}}" Template="{StaticResource ValidationToolTipTemplate}">
														<ToolTip.Triggers>
															<EventTrigger RoutedEvent="Canvas.Loaded">
																<BeginStoryboard>
																	<Storyboard>
																		<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="IsHitTestVisible" Storyboard.TargetName="validationTooltip">
																			<DiscreteObjectKeyFrame KeyTime="0">
																				<DiscreteObjectKeyFrame.Value>
																					<System:Boolean>true</System:Boolean>
																				</DiscreteObjectKeyFrame.Value>
																			</DiscreteObjectKeyFrame>
																		</ObjectAnimationUsingKeyFrames>
																	</Storyboard>
																</BeginStoryboard>
															</EventTrigger>
														</ToolTip.Triggers>
													</ToolTip>
												</ToolTipService.ToolTip>
												<Grid Background="{StaticResource TransparentBrush}" HorizontalAlignment="Right" Height="10" Margin="0,-4,-4,0" VerticalAlignment="Top" Width="10">
													<Path Data="M 1,0 L6,0 A 2,2 90 0 1 8,2 L8,7 z" Fill="{StaticResource ValidationErrorElement}" Margin="-1,3,0,0" />
													<Path Data="M 0,0 L2,0 L 8,6 L8,8" Fill="{StaticResource LightForegroundBrush}" Margin="-1,3,0,0" />
												</Grid>
											</Border>
										</Grid>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Style>
					</ResourceDictionary>
				</ResourceDictionary.MergedDictionaries>
				<SolidColorBrush x:Key="SliderThumbBackgroundBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="SliderThumbHoverBackgroundBrush" Color="{StaticResource Color_010}" />
				<SolidColorBrush x:Key="SliderThumbPressedBackgroundBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="SliderThumbFocusedBorderBrush" Color="{StaticResource Color_024}" />
				<SolidColorBrush x:Key="SliderTrackBackgroundBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="SliderSelectionRangeBackgroundBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="GridSplitterBackgroundBrush" Color="{StaticResource Color_009}" />
				<SolidColorBrush x:Key="GridSplitterBorderBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="GridSplitterHoverBackgroundBrush" Color="{StaticResource Color_010}" />
				<SolidColorBrush x:Key="GridSplitterHoverBorderBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="GridSplitterPressedBackgroundBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="GridSplitterFocusedBorderBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="ProgressBarBackgroundBrush" Color="{StaticResource Color_013}" />
				<SolidColorBrush x:Key="ProgressBarForegroundBrush" Color="{StaticResource Color_009}" />
				<LinearGradientBrush x:Key="ProgressBarIndeterminateBackgroundBrush" EndPoint="0,1" MappingMode="Absolute" SpreadMethod="Repeat" StartPoint="500,1">
					<LinearGradientBrush.Transform>
						<TransformGroup>
							<TranslateTransform X="0" />
							<SkewTransform AngleX="-0" />
						</TransformGroup>
					</LinearGradientBrush.Transform>
					<GradientStop Color="{StaticResource Color_009}" Offset="0.5001" />
					<GradientStop Color="{StaticResource Color_013}" Offset="0.5" />
					<GradientStop Color="{StaticResource Color_013}"  Offset="0.0001"/>
					<GradientStop Color="{StaticResource Color_009}" Offset="1" />
				</LinearGradientBrush>
				<SolidColorBrush x:Key="TooltipBackgroundBrush" Color="{StaticResource Color_009}" />
				<SolidColorBrush x:Key="TooltipBorderBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="ExpanderButtonBackgroundBrush" Color="{StaticResource Color_009}" />
				<SolidColorBrush x:Key="ExpanderButtonBorderBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="ExpanderButtonHoverBackgroundBrush" Color="{StaticResource Color_010}" />
				<SolidColorBrush x:Key="ExpanderButtonHoverBorderBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="ExpanderButtonPressedBackgroundBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="ExpanderButtonPressedBorderBrush" Color="{StaticResource Color_011}" />
				<SolidColorBrush x:Key="ExpanderArrowHoverBorderBrush" Color="{StaticResource Color_001}" />
				<SolidColorBrush x:Key="ExpanderArrowPressedBorderBrush" Color="{StaticResource Color_001}" />
				<SolidColorBrush x:Key="ExpanderDisabledForegroundBrush" Color="{StaticResource Color_007}" />
				<SolidColorBrush x:Key="GroupBoxBorderBrush" Color="{StaticResource Color_005}" />
				<SolidColorBrush x:Key="PasswordBoxForegroundBrush" Color="{StaticResource Color_013}" />
				<Style x:Key="TextBlockStyle" TargetType="TextBlock">
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="FontSize" Value="12" />
					<Setter Property="FontFamily" Value="Segoe UI" />
				</Style>
				<Style x:Key="LabelStyle" TargetType="{x:Type Label}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize" Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="IsTabStop" Value="False" />
					<Setter Property="HorizontalContentAlignment" Value="Left" />
				</Style>
				<Style x:Key="SliderRepeatButtonStyle" TargetType="{x:Type RepeatButton}">
					<Setter Property="OverridesDefaultStyle" Value="true" />
					<Setter Property="Focusable" Value="false" />
					<Setter Property="IsTabStop" Value="false" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type RepeatButton}">
								<Rectangle Fill="{StaticResource TransparentBrush}" />
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="HSliderThumbStyle" TargetType="{x:Type Thumb}">
					<Setter Property="Background" Value="{StaticResource SliderThumbBackgroundBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="MinHeight" Value="11" />
					<Setter Property="MinWidth" Value="4" />
					<Setter Property="IsTabStop" Value="False" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type Thumb}">
								<Grid>
									<Rectangle x:Name="ThumbBackground" Fill="{TemplateBinding Background}" Width="4" Height="11" />
									<Rectangle x:Name="FocusedVisualElement" Stroke="{StaticResource SliderThumbFocusedBorderBrush}" Width="4" Height="11" StrokeThickness="1" Opacity="0" />
									<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Width="4" Height="11" Opacity="0" />
								</Grid>
								<ControlTemplate.Triggers>
									<Trigger Property="IsMouseOver" Value="True">
										<Setter TargetName="ThumbBackground" Property="Fill" Value="{StaticResource SliderThumbHoverBackgroundBrush}" />
									</Trigger>
									<Trigger Property="IsMouseCaptured" Value="True">
										<Setter TargetName="ThumbBackground" Property="Fill" Value="{StaticResource SliderThumbPressedBackgroundBrush}" />
									</Trigger>
									<Trigger Property="IsEnabled" Value="false">
										<Setter TargetName="DisabledVisualElement" Property="Opacity" Value="1" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="VSliderThumbStyle" TargetType="{x:Type Thumb}">
					<Setter Property="Background" Value="{StaticResource SliderThumbBackgroundBrush}" />
					<Setter Property="MinHeight" Value="4" />
					<Setter Property="MinWidth" Value="11" />
					<Setter Property="IsTabStop" Value="False" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type Thumb}">
								<Grid>
									<Rectangle x:Name="ThumbBackground" Fill="{TemplateBinding Background}" Width="11" Height="4" />
									<Rectangle x:Name="FocusedVisualElement" Stroke="{StaticResource SliderThumbFocusedBorderBrush}" Width="11" Height="4" StrokeThickness="1" Opacity="0" />
									<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Width="11" Height="4" Opacity="0" />
								</Grid>
								<ControlTemplate.Triggers>
									<Trigger Property="IsMouseOver" Value="True">
										<Setter TargetName="ThumbBackground" Property="Fill" Value="{StaticResource SliderThumbHoverBackgroundBrush}" />
									</Trigger>
									<Trigger Property="IsMouseCaptured" Value="True">
										<Setter TargetName="ThumbBackground" Property="Fill" Value="{StaticResource SliderThumbPressedBackgroundBrush}" />
									</Trigger>
									<Trigger Property="IsEnabled" Value="false">
										<Setter TargetName="DisabledVisualElement" Property="Opacity" Value="1" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="SliderStyle" TargetType="{x:Type Slider}">
					<Setter Property="Background" Value="Transparent" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="Stylus.IsPressAndHoldEnabled" Value="false" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type Slider}">
								<Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" SnapsToDevicePixels="true">
									<Grid>
										<Grid.RowDefinitions>
											<RowDefinition Height="Auto" />
											<RowDefinition Height="Auto" MinHeight="{TemplateBinding MinHeight}" />
											<RowDefinition Height="Auto" />
										</Grid.RowDefinitions>
										<TickBar x:Name="TopTick" Fill="{TemplateBinding Foreground}" Height="1" Placement="Top" Grid.Row="0" Visibility="Collapsed" />
										<TickBar x:Name="BottomTick" Fill="{TemplateBinding Foreground}" Height="1" Placement="Bottom" Grid.Row="2" Visibility="Collapsed" />
										<Border x:Name="TrackBackground" Background="{StaticResource SliderTrackBackgroundBrush}" Height="1" Grid.Row="1" VerticalAlignment="center">
											<Canvas Margin="-6,-1">
												<Rectangle x:Name="PART_SelectionRange" Fill="{StaticResource SliderSelectionRangeBackgroundBrush}" Height="1" Width="0" Visibility="Hidden" />
											</Canvas>
										</Border>
										<Track x:Name="PART_Track" Grid.Row="1">
											<Track.DecreaseRepeatButton>
												<RepeatButton Command="{x:Static Slider.DecreaseLarge}" Style="{StaticResource SliderRepeatButtonStyle}" />
											</Track.DecreaseRepeatButton>
											<Track.IncreaseRepeatButton>
												<RepeatButton Command="{x:Static Slider.IncreaseLarge}" Style="{StaticResource SliderRepeatButtonStyle}" />
											</Track.IncreaseRepeatButton>
											<Track.Thumb>
												<Thumb x:Name="Thumb" Style="{StaticResource HSliderThumbStyle}" />
											</Track.Thumb>
										</Track>
									</Grid>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="TickPlacement" Value="TopLeft">
										<Setter Property="Visibility" TargetName="TopTick" Value="Visible" />
										<Setter Property="Style" TargetName="Thumb" Value="{StaticResource HSliderThumbStyle}" />
										<Setter Property="Margin" TargetName="TrackBackground" Value="5,2,5,0" />
									</Trigger>
									<Trigger Property="TickPlacement" Value="BottomRight">
										<Setter Property="Visibility" TargetName="BottomTick" Value="Visible" />
										<Setter Property="Style" TargetName="Thumb" Value="{StaticResource HSliderThumbStyle}" />
										<Setter Property="Margin" TargetName="TrackBackground" Value="5,0,5,2" />
									</Trigger>
									<Trigger Property="TickPlacement" Value="Both">
										<Setter Property="Visibility" TargetName="TopTick" Value="Visible" />
										<Setter Property="Visibility" TargetName="BottomTick" Value="Visible" />
									</Trigger>
									<Trigger Property="IsSelectionRangeEnabled" Value="true">
										<Setter Property="Visibility" TargetName="PART_SelectionRange" Value="Visible" />
									</Trigger>
									<Trigger Property="IsKeyboardFocused" Value="true">
										<Setter Property="Foreground" TargetName="Thumb" Value="{StaticResource SliderThumbFocusedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
					<Style.Triggers>
						<Trigger Property="Orientation" Value="Vertical">
							<Setter Property="Template">
								<Setter.Value>
									<ControlTemplate TargetType="{x:Type Slider}">
										<Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" SnapsToDevicePixels="true">
											<Grid>
												<Grid.ColumnDefinitions>
													<ColumnDefinition Width="Auto" />
													<ColumnDefinition MinWidth="{TemplateBinding MinWidth}" Width="Auto" />
													<ColumnDefinition Width="Auto" />
												</Grid.ColumnDefinitions>
												<TickBar x:Name="TopTick" Grid.Column="0" Fill="{TemplateBinding Foreground}" Placement="Left" Visibility="Collapsed" Width="1" />
												<TickBar x:Name="BottomTick" Grid.Column="2" Fill="{TemplateBinding Foreground}" Placement="Right" Visibility="Collapsed" Width="1" />
												<Border x:Name="TrackBackground" Background="{StaticResource SliderTrackBackgroundBrush}" Grid.Column="1" HorizontalAlignment="center" Width="1">
													<Canvas Margin="-1,-6">
														<Rectangle x:Name="PART_SelectionRange" Fill="{StaticResource SliderSelectionRangeBackgroundBrush}" Visibility="Hidden" Width="1" />
													</Canvas>
												</Border>
												<Track x:Name="PART_Track" Grid.Column="1">
													<Track.DecreaseRepeatButton>
														<RepeatButton Command="{x:Static Slider.DecreaseLarge}" Style="{StaticResource SliderRepeatButtonStyle}" />
													</Track.DecreaseRepeatButton>
													<Track.IncreaseRepeatButton>
														<RepeatButton Command="{x:Static Slider.IncreaseLarge}" Style="{StaticResource SliderRepeatButtonStyle}" />
													</Track.IncreaseRepeatButton>
													<Track.Thumb>
														<Thumb x:Name="Thumb" Style="{StaticResource VSliderThumbStyle}" />
													</Track.Thumb>
												</Track>
											</Grid>
										</Border>
										<ControlTemplate.Triggers>
											<Trigger Property="TickPlacement" Value="TopLeft">
												<Setter Property="Visibility" TargetName="TopTick" Value="Visible" />
												<Setter Property="Style" TargetName="Thumb" Value="{StaticResource VSliderThumbStyle}" />
												<Setter Property="Margin" TargetName="TrackBackground" Value="2,5,0,5" />
											</Trigger>
											<Trigger Property="TickPlacement" Value="BottomRight">
												<Setter Property="Visibility" TargetName="BottomTick" Value="Visible" />
												<Setter Property="Style" TargetName="Thumb" Value="{StaticResource VSliderThumbStyle}" />
												<Setter Property="Margin" TargetName="TrackBackground" Value="0,5,2,5" />
											</Trigger>
											<Trigger Property="TickPlacement" Value="Both">
												<Setter Property="Visibility" TargetName="TopTick" Value="Visible" />
												<Setter Property="Visibility" TargetName="BottomTick" Value="Visible" />
											</Trigger>
											<Trigger Property="IsSelectionRangeEnabled" Value="true">
												<Setter Property="Visibility" TargetName="PART_SelectionRange" Value="Visible" />
											</Trigger>
											<Trigger Property="IsKeyboardFocused" Value="true">
												<Setter Property="Foreground" TargetName="Thumb" Value="{StaticResource SliderThumbFocusedBorderBrush}" />
											</Trigger>
										</ControlTemplate.Triggers>
									</ControlTemplate>
								</Setter.Value>
							</Setter>
						</Trigger>
					</Style.Triggers>
				</Style>
				<Style x:Key="RepeatButtonStyle" TargetType="{x:Type RepeatButton}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize"  Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="Padding" Value="7,0,7,2" />
					<Setter Property="MinHeight" Value="22" />
					<Setter Property="MinWidth" Value="22" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type RepeatButton}">
								<Grid SnapsToDevicePixels="True">
									<VisualStateManager.VisualStateGroups>
										<VisualStateGroup x:Name="CommonStates">
											<VisualState x:Name="Normal" />
											<VisualState x:Name="MouseOver">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBackgroundBrush}" />
													</ObjectAnimationUsingKeyFrames>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBorderBrush}" />
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
											<VisualState x:Name="Pressed">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBackgroundBrush}" />
													</ObjectAnimationUsingKeyFrames>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBorderBrush}" />
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
											<VisualState x:Name="Disabled">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="DisabledVisualElement">
														<DiscreteObjectKeyFrame KeyTime="0">
															<DiscreteObjectKeyFrame.Value>
																<Visibility>Visible</Visibility>
															</DiscreteObjectKeyFrame.Value>
														</DiscreteObjectKeyFrame>
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
										</VisualStateGroup>
										<VisualStateGroup x:Name="FocusStates">
											<VisualState x:Name="Focused"/>
											<VisualState x:Name="Unfocused" />
										</VisualStateGroup>
									</VisualStateManager.VisualStateGroups>
									<Rectangle x:Name="Bd" Fill="{StaticResource ButtonBackgroundBrush}" Stroke="{StaticResource ButtonBorderBrush}" StrokeThickness="1" />
									<ContentControl x:Name="ContentControl" Foreground="{TemplateBinding Foreground}" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}">
										<ContentPresenter x:Name="contentPresenter" />
									</ContentControl>
									<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Visibility="Collapsed" />
								</Grid>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="GridSplitterStyle" TargetType="{x:Type GridSplitter}">
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="Background" Value="{StaticResource GridSplitterBackgroundBrush}" />
					<Setter Property="BorderBrush" Value="{StaticResource GridSplitterBorderBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="SnapsToDevicePixels" Value="True" />
					<Setter Property="PreviewStyle">
						<Setter.Value>
							<Style TargetType="Control">
								<Setter Property="Control.Template">
									<Setter.Value>
										<ControlTemplate>
											<Rectangle Fill="{StaticResource GridSplitterPressedBackgroundBrush}" Opacity="0.8" />
										</ControlTemplate>
									</Setter.Value>
								</Setter>
							</Style>
						</Setter.Value>
					</Setter>
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate>
								<Grid>
									<Border x:Name="border" BorderThickness="{TemplateBinding BorderThickness}" BorderBrush="{TemplateBinding BorderBrush}" Background="{TemplateBinding Background}" MinHeight="8" MinWidth="8">
										<Grid>
											<StackPanel x:Name="HGrip" Height="8" VerticalAlignment="Center" HorizontalAlignment="Center" Orientation="Vertical">
												<Rectangle Fill="{StaticResource GlyphBackgroundBrush}" Height="1" Margin="1,2,1,1" StrokeThickness="0" Width="20" />
												<Rectangle Fill="{StaticResource GlyphBackgroundBrush}" Height="1" Margin="1,1,1,2" StrokeThickness="0" Width="20" />
											</StackPanel>
											<StackPanel x:Name="VGrip" Width="8" VerticalAlignment="Center" HorizontalAlignment="Center" Orientation="Horizontal" Visibility="Collapsed">
												<Rectangle Fill="{StaticResource GlyphBackgroundBrush}" Height="20" Margin="2,1,1,1" StrokeThickness="0" Width="1" />
												<Rectangle Fill="{StaticResource GlyphBackgroundBrush}" Height="20" Margin="1,1,2,1" StrokeThickness="0" Width="1" />
											</StackPanel>
										</Grid>
									</Border>
								</Grid>
								<ControlTemplate.Triggers>
									<Trigger Property="HorizontalAlignment" Value="Stretch">
										<Setter TargetName="HGrip" Property="Visibility" Value="Visible" />
										<Setter TargetName="VGrip" Property="Visibility" Value="Collapsed" />
									</Trigger>
									<Trigger Property="VerticalAlignment" Value="Stretch">
										<Setter TargetName="VGrip" Property="Visibility" Value="Visible" />
										<Setter TargetName="HGrip" Property="Visibility" Value="Collapsed" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="True">
										<Setter TargetName="border" Property="Background" Value="{StaticResource GridSplitterHoverBackgroundBrush}" />
										<Setter TargetName="border" Property="BorderBrush" Value="{StaticResource GridSplitterHoverBorderBrush}" />
									</Trigger>
									<Trigger Property="IsFocused" Value="True">
										<Setter TargetName="border" Property="BorderBrush" Value="{StaticResource GridSplitterFocusedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ProgressBarStyle" TargetType="{x:Type ProgressBar}">
					<Setter Property="Foreground" Value="{StaticResource ProgressBarForegroundBrush}" />
					<Setter Property="Background" Value="{StaticResource ProgressBarBackgroundBrush}" />
					<Setter Property="BorderBrush" Value="{StaticResource ProgressBarBackgroundBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="Height" Value="12" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ProgressBar}">
								<Grid x:Name="TemplateRoot" SnapsToDevicePixels="true">
									<VisualStateManager.VisualStateGroups>
										<VisualStateGroup x:Name="CommonStates">
											<VisualState x:Name="Determinate" />
											<VisualState x:Name="Indeterminate">
												<Storyboard RepeatBehavior="Forever">
													<DoubleAnimation Duration="00:00:2" From="0" To="500" Storyboard.TargetProperty="(Shape.Fill).(LinearGradientBrush.Transform).(TransformGroup.Children)[0].X" Storyboard.TargetName="IndeterminateGradientFill" />
												</Storyboard>
											</VisualState>
										</VisualStateGroup>
									</VisualStateManager.VisualStateGroups>
									<Border x:Name="ProgressBarTrack" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" />
									<Rectangle x:Name="PART_Track" Margin="{TemplateBinding BorderThickness}" />
									<Decorator x:Name="PART_Indicator" HorizontalAlignment="Left" Margin="{TemplateBinding BorderThickness}">
										<Grid x:Name="Foreground">
											<Rectangle x:Name="Indicator" Fill="{TemplateBinding Foreground}" />
										</Grid>
									</Decorator>
									<Grid x:Name="IndeterminateRoot" Visibility="Collapsed">
										<Rectangle x:Name="IndeterminateSolidFill" Fill="{TemplateBinding Foreground}" Margin="{TemplateBinding BorderThickness}" Opacity="1" RenderTransformOrigin="0.5,0.5" StrokeThickness="0" />
										<Rectangle x:Name="IndeterminateGradientFill" Fill="{StaticResource ProgressBarIndeterminateBackgroundBrush}" Margin="{TemplateBinding BorderThickness}" StrokeThickness="1" />
									</Grid>
								</Grid>
								<ControlTemplate.Triggers>
									<Trigger Property="Orientation" Value="Vertical">
										<Setter Property="LayoutTransform" TargetName="TemplateRoot">
											<Setter.Value>
												<RotateTransform Angle="-90" />
											</Setter.Value>
										</Setter>
									</Trigger>
									<Trigger Property="IsIndeterminate" Value="true">
										<Setter Property="Visibility" TargetName="Indicator" Value="Collapsed" />
										<Setter Property="Visibility" TargetName="IndeterminateRoot" Value="Visible" />
									</Trigger>
									<Trigger Property="IsIndeterminate" Value="false"/>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="PasswordBoxStyle" TargetType="{x:Type PasswordBox}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize" Value="12" />
					<Setter Property="Foreground" Value="{StaticResource PasswordBoxForegroundBrush}" />
					<Setter Property="Background" Value="{StaticResource TextBoxBackgroundBrush}" />
					<Setter Property="BorderBrush" Value="{StaticResource TextBoxBorderBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="Padding" Value="6,2" />
					<Setter Property="MinHeight" Value="22" />
					<Setter Property="SelectionBrush" Value="{StaticResource TextBoxFocusedBrush}" />
					<Setter Property="PasswordChar" Value="*" />
					<Setter Property="KeyboardNavigation.TabNavigation" Value="None" />
					<Setter Property="AllowDrop" Value="true" />
					<Setter Property="FocusVisualStyle" Value="{x:Null}" />
					<Setter Property="ScrollViewer.PanningMode" Value="VerticalFirst" />
					<Setter Property="Stylus.IsFlicksEnabled" Value="False" />
					<Setter Property="FlowDirection" Value="LeftToRight" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type PasswordBox}">
								<Grid>
									<Border Background="{TemplateBinding Background}" x:Name="Bd" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" />
									<Border x:Name="DisabledVisualElement" BorderBrush="{StaticResource DisabledBorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{StaticResource DisabledBackgroundBrush}" IsHitTestVisible="False" Opacity="0" />
									<Border x:Name="ReadOnlyVisualElement" Background="{StaticResource TextBoxReadOnlyBackgroundBrush}" Opacity="0" />
									<Border>
										<ScrollViewer x:Name="PART_ContentHost" />
									</Border>
								</Grid>
								<ControlTemplate.Triggers>
									<Trigger Property="IsEnabled" Value="False">
										<Setter Property="Opacity" Value="1" TargetName="DisabledVisualElement" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="True">
										<Setter Property="BorderBrush" Value="{StaticResource TextBoxHoverBorderBrush}" TargetName="Bd" />
									</Trigger>
									<Trigger Property="IsFocused" Value="True">
										<Setter Property="BorderBrush" Value="{StaticResource TextBoxFocusedBrush}" TargetName="Bd" />
									</Trigger>
									<MultiDataTrigger>
										<MultiDataTrigger.Conditions>
											<Condition Binding="{Binding IsReadOnly, RelativeSource={RelativeSource Self}}" Value="True" />
											<Condition Binding="{Binding IsEnabled, RelativeSource={RelativeSource Self}}" Value="True" />
										</MultiDataTrigger.Conditions>
										<Setter Property="Opacity" Value="1" TargetName="ReadOnlyVisualElement" />
									</MultiDataTrigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="{x:Type ToolTip}" TargetType="ToolTip">
					<Setter Property="OverridesDefaultStyle" Value="true" />
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize"  Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="Background" Value="{StaticResource TooltipBackgroundBrush}" />
					<Setter Property="BorderBrush" Value="{StaticResource TooltipBorderBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="Padding" Value="12,9" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="ToolTip">
								<Grid >
									<Rectangle Stroke="{TemplateBinding BorderBrush}" Fill="{TemplateBinding Background}" StrokeThickness="{TemplateBinding BorderThickness}" />
									<StackPanel Orientation="Horizontal" d:LayoutOverrides="Width, Height">
										<ContentPresenter Margin="{TemplateBinding Padding}" Content="{TemplateBinding Content}" />
									</StackPanel>
								</Grid>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ExpanderRightHeaderStyle" TargetType="{x:Type ToggleButton}">
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ToggleButton}">
								<Border Padding="{TemplateBinding Padding}">
									<Grid Background="{StaticResource TransparentBrush}" SnapsToDevicePixels="False">
										<Grid.RowDefinitions>
											<RowDefinition Height="22" />
											<RowDefinition Height="*" />
										</Grid.RowDefinitions>
										<Grid>
											<Grid.LayoutTransform>
												<TransformGroup>
													<TransformGroup.Children>
														<TransformCollection>
															<RotateTransform Angle="-90" />
														</TransformCollection>
													</TransformGroup.Children>
												</TransformGroup>
											</Grid.LayoutTransform>
											<Rectangle x:Name="rectangle" Width="22" Height="22" Fill="{StaticResource ExpanderButtonBackgroundBrush}" HorizontalAlignment="Center" Stroke="{StaticResource ExpanderButtonBorderBrush}" VerticalAlignment="Center" />
											<Path x:Name="arrow" Width="10" Height="6" Fill="{StaticResource GlyphBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" RenderTransformOrigin="0.5, 0.5" />
										</Grid>
										<ContentPresenter HorizontalAlignment="Center" Margin="0,4,0,0" Grid.Row="1" RecognizesAccessKey="True" SnapsToDevicePixels="True" VerticalAlignment="Stretch" />
									</Grid>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="IsChecked" Value="true">
										<Setter Property="Data" TargetName="arrow" Value="M3.4,-4.4 L6.8,3.9 3.9566912E-07,3.9 z" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowHoverBorderBrush}" />
									</Trigger>
									<Trigger Property="IsPressed" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowPressedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ExpanderUpHeaderStyle" TargetType="{x:Type ToggleButton}">
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ToggleButton}">
								<Border Padding="{TemplateBinding Padding}">
									<Grid Background="{StaticResource TransparentBrush}" SnapsToDevicePixels="False">
										<Grid.ColumnDefinitions>
											<ColumnDefinition Width="22" />
											<ColumnDefinition Width="*" />
										</Grid.ColumnDefinitions>
										<Grid>
											<Grid.LayoutTransform>
												<TransformGroup>
													<TransformGroup.Children>
														<TransformCollection>
															<RotateTransform Angle="180" />
														</TransformCollection>
													</TransformGroup.Children>
												</TransformGroup>
											</Grid.LayoutTransform>
											<Rectangle x:Name="rectangle" Width="22" Height="22" Fill="{StaticResource ExpanderButtonBackgroundBrush}" HorizontalAlignment="Center" Stroke="{StaticResource ExpanderButtonBorderBrush}" VerticalAlignment="Center" />
											<Path x:Name="arrow" Width="10" Height="6" Fill="{StaticResource GlyphBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" RenderTransformOrigin="0.5, 0.5" />
										</Grid>
										<ContentPresenter Grid.Column="1" HorizontalAlignment="Stretch" Margin="4,0,0,0" RecognizesAccessKey="True" SnapsToDevicePixels="True" VerticalAlignment="Center" />
									</Grid>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="IsChecked" Value="true">
										<Setter Property="Data" TargetName="arrow" Value="M3.4,-4.4 L6.8,3.9 3.9566912E-07,3.9 z" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowHoverBorderBrush}" />
									</Trigger>
									<Trigger Property="IsPressed" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowPressedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ExpanderLeftHeaderStyle" TargetType="{x:Type ToggleButton}">
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ToggleButton}">
								<Border Padding="{TemplateBinding Padding}">
									<Grid Background="{StaticResource TransparentBrush}" SnapsToDevicePixels="False">
										<Grid.RowDefinitions>
											<RowDefinition Height="22" />
											<RowDefinition Height="*" />
										</Grid.RowDefinitions>
										<Grid>
											<Grid.LayoutTransform>
												<TransformGroup>
													<TransformGroup.Children>
														<TransformCollection>
															<RotateTransform Angle="90" />
														</TransformCollection>
													</TransformGroup.Children>
												</TransformGroup>
											</Grid.LayoutTransform>
											<Rectangle x:Name="rectangle" Width="22" Height="22" Fill="{StaticResource ExpanderButtonBackgroundBrush}" HorizontalAlignment="Center" Stroke="{StaticResource ExpanderButtonBorderBrush}" VerticalAlignment="Center" />
											<Path x:Name="arrow" Width="10" Height="6" Fill="{StaticResource GlyphBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" RenderTransformOrigin="0.5, 0.5" />
										</Grid>
										<ContentPresenter Grid.Row="1" HorizontalAlignment="Center" Margin="0,4,0,0" RecognizesAccessKey="True" SnapsToDevicePixels="True" VerticalAlignment="Stretch" />
									</Grid>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="IsChecked" Value="true">
										<Setter Property="Data" TargetName="arrow" Value="M3.4,-4.4 L6.8,3.9 3.9566912E-07,3.9 z" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowHoverBorderBrush}" />
									</Trigger>
									<Trigger Property="IsPressed" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowPressedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ExpanderDownHeaderStyle" TargetType="{x:Type ToggleButton}">
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ToggleButton}">
								<Border Padding="{TemplateBinding Padding}">
									<Grid Background="{StaticResource TransparentBrush}" SnapsToDevicePixels="False">
										<Grid.ColumnDefinitions>
											<ColumnDefinition Width="22" />
											<ColumnDefinition Width="*" />
										</Grid.ColumnDefinitions>
										<Rectangle x:Name="rectangle" Width="22" Height="22" Fill="{StaticResource ExpanderButtonBackgroundBrush}" HorizontalAlignment="Center" Stroke="{StaticResource ExpanderButtonBorderBrush}" VerticalAlignment="Center" />
										<Path x:Name="arrow" Width="10" Height="6" Fill="{StaticResource GlyphBackgroundBrush}" Data="F1 M 301.14,-189.041L 311.57,-189.041L 306.355,-182.942L 301.14,-189.041 Z " Stretch="Fill" RenderTransformOrigin="0.5, 0.5" />
										<ContentPresenter Grid.Column="1" HorizontalAlignment="Stretch" Margin="4,0,0,0" RecognizesAccessKey="True" SnapsToDevicePixels="True" VerticalAlignment="Center" />
									</Grid>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="IsChecked" Value="true">
										<Setter Property="Data" TargetName="arrow" Value="M3.4,-4.4 L6.8,3.9 3.9566912E-07,3.9 z" />
									</Trigger>
									<Trigger Property="IsMouseOver" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonHoverBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowHoverBorderBrush}" />
									</Trigger>
									<Trigger Property="IsPressed" Value="true">
										<Setter Property="Fill" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBackgroundBrush}" />
										<Setter Property="Stroke" TargetName="rectangle" Value="{StaticResource ExpanderButtonPressedBorderBrush}" />
										<Setter Property="Fill" TargetName="arrow" Value="{StaticResource ExpanderArrowPressedBorderBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ExpanderStyle" TargetType="{x:Type Expander}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize"  Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="HorizontalContentAlignment" Value="Stretch" />
					<Setter Property="VerticalContentAlignment" Value="Stretch" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type Expander}">
								<Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" CornerRadius="3" SnapsToDevicePixels="true">
									<DockPanel>
										<ToggleButton x:Name="HeaderSite" ContentTemplate="{TemplateBinding HeaderTemplate}" ContentTemplateSelector="{TemplateBinding HeaderTemplateSelector}" Content="{TemplateBinding Header}" DockPanel.Dock="Top" Foreground="{TemplateBinding Foreground}" FontWeight="{TemplateBinding FontWeight}" FontStyle="{TemplateBinding FontStyle}" FontStretch="{TemplateBinding FontStretch}" FontSize="{TemplateBinding FontSize}" FontFamily="{TemplateBinding FontFamily}" HorizontalContentAlignment="{TemplateBinding HorizontalContentAlignment}" IsChecked="{Binding IsExpanded, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" Margin="1" MinWidth="0" MinHeight="0" Padding="{TemplateBinding Padding}" Style="{StaticResource ExpanderDownHeaderStyle}" VerticalContentAlignment="{TemplateBinding VerticalContentAlignment}" />
										<ContentPresenter x:Name="ExpandSite" DockPanel.Dock="Bottom" Focusable="false" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" Margin="{TemplateBinding Padding}" Visibility="Collapsed" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" />
									</DockPanel>
								</Border>
								<ControlTemplate.Triggers>
									<Trigger Property="IsExpanded" Value="true">
										<Setter Property="Visibility" TargetName="ExpandSite" Value="Visible" />
									</Trigger>
									<Trigger Property="ExpandDirection" Value="Right">
										<Setter Property="DockPanel.Dock" TargetName="ExpandSite" Value="Right" />
										<Setter Property="DockPanel.Dock" TargetName="HeaderSite" Value="Left" />
										<Setter Property="Style" TargetName="HeaderSite" Value="{StaticResource ExpanderRightHeaderStyle}" />
									</Trigger>
									<Trigger Property="ExpandDirection" Value="Up">
										<Setter Property="DockPanel.Dock" TargetName="ExpandSite" Value="Top" />
										<Setter Property="DockPanel.Dock" TargetName="HeaderSite" Value="Bottom" />
										<Setter Property="Style" TargetName="HeaderSite" Value="{StaticResource ExpanderUpHeaderStyle}" />
									</Trigger>
									<Trigger Property="ExpandDirection" Value="Left">
										<Setter Property="DockPanel.Dock" TargetName="ExpandSite" Value="Left" />
										<Setter Property="DockPanel.Dock" TargetName="HeaderSite" Value="Right" />
										<Setter Property="Style" TargetName="HeaderSite" Value="{StaticResource ExpanderLeftHeaderStyle}" />
									</Trigger>
									<Trigger Property="IsEnabled" Value="false">
										<Setter Property="Foreground" Value="{StaticResource ExpanderDisabledForegroundBrush}" />
									</Trigger>
								</ControlTemplate.Triggers>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style x:Key="ToggleButtonStyle" TargetType="{x:Type ToggleButton}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize"  Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="Padding" Value="10,0,10,2" />
					<Setter Property="MinHeight" Value="22" />
					<Setter Property="MinWidth" Value="22" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type ToggleButton}">
								<Grid>
									<VisualStateManager.VisualStateGroups>
										<VisualStateGroup x:Name="CommonStates">
											<VisualState x:Name="Normal" />
											<VisualState x:Name="MouseOver">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBackgroundBrush}" />
													</ObjectAnimationUsingKeyFrames>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonHoverBorderBrush}" />
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
											<VisualState x:Name="Pressed">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Fill">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBackgroundBrush}" />
													</ObjectAnimationUsingKeyFrames>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetName="Bd" Storyboard.TargetProperty="Stroke">
														<DiscreteObjectKeyFrame KeyTime="0" Value="{StaticResource ButtonPressedBorderBrush}" />
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
											<VisualState x:Name="Disabled">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="DisabledVisualElement">
														<DiscreteObjectKeyFrame KeyTime="0">
															<DiscreteObjectKeyFrame.Value>
																<Visibility>Visible</Visibility>
															</DiscreteObjectKeyFrame.Value>
														</DiscreteObjectKeyFrame>
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
										</VisualStateGroup>
										<VisualStateGroup x:Name="CheckStates">
											<VisualState x:Name="Checked">
												<Storyboard>
													<ObjectAnimationUsingKeyFrames Storyboard.TargetProperty="(UIElement.Visibility)" Storyboard.TargetName="checked">
														<DiscreteObjectKeyFrame KeyTime="0">
															<DiscreteObjectKeyFrame.Value>
																<Visibility>Visible</Visibility>
															</DiscreteObjectKeyFrame.Value>
														</DiscreteObjectKeyFrame>
													</ObjectAnimationUsingKeyFrames>
												</Storyboard>
											</VisualState>
											<VisualState x:Name="Unchecked" />
											<VisualState x:Name="Indeterminate" />
										</VisualStateGroup>
										<VisualStateGroup x:Name="FocusStates">
											<VisualState x:Name="Focused"/>
											<VisualState x:Name="Unfocused" />
										</VisualStateGroup>
									</VisualStateManager.VisualStateGroups>
									<Rectangle x:Name="Bd" Fill="{StaticResource ButtonBackgroundBrush}" Stroke="{StaticResource ButtonBorderBrush}" StrokeThickness="1" />
									<Rectangle x:Name="checked" Fill="{StaticResource ButtonPressedBackgroundBrush}" Stroke="{StaticResource ButtonPressedBackgroundBrush}" StrokeThickness="1" Visibility="Collapsed" />
									<ContentControl x:Name="ContentControl" Foreground="{TemplateBinding Foreground}" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}">
										<ContentPresenter x:Name="contentPresenter" />
									</ContentControl>
									<Rectangle x:Name="DisabledVisualElement" Fill="{StaticResource DisabledBackgroundBrush}" Visibility="Collapsed" />
								</Grid>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<BorderGapMaskConverter x:Key="BorderGapMaskConverter" />
				<Style x:Key="GroupBoxStyle" TargetType="{x:Type GroupBox}">
					<Setter Property="FontFamily" Value="Segoe UI" />
					<Setter Property="FontSize"  Value="12" />
					<Setter Property="Foreground" Value="{StaticResource ForegroundBrush}" />
					<Setter Property="BorderBrush" Value="{StaticResource GroupBoxBorderBrush}" />
					<Setter Property="BorderThickness" Value="1" />
					<Setter Property="Padding" Value="5" />
					<Setter Property="SnapsToDevicePixels" Value="True" />
					<Setter Property="Template">
						<Setter.Value>
							<ControlTemplate TargetType="{x:Type GroupBox}">
								<Grid SnapsToDevicePixels="true">
									<Grid.ColumnDefinitions>
										<ColumnDefinition Width="6" />
										<ColumnDefinition Width="Auto" />
										<ColumnDefinition Width="*" />
										<ColumnDefinition Width="6" />
									</Grid.ColumnDefinitions>
									<Grid.RowDefinitions>
										<RowDefinition Height="Auto" />
										<RowDefinition Height="Auto" />
										<RowDefinition Height="*" />
										<RowDefinition Height="6" />
									</Grid.RowDefinitions>
									<Border BorderBrush="{StaticResource TransparentBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" Grid.ColumnSpan="4" Grid.Column="0" Grid.Row="1" Grid.RowSpan="3" />
									<Border x:Name="Header" Grid.Column="1" Padding="10,0,10,0" Grid.Row="0" Grid.RowSpan="2">
										<ContentPresenter ContentSource="Header" Height="20" RecognizesAccessKey="True" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" />
									</Border>
									<ContentPresenter Grid.ColumnSpan="2" Grid.Column="1" Margin="{TemplateBinding Padding}" Grid.Row="2" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" />
									<Border Grid.ColumnSpan="4" Grid.Row="1" Grid.RowSpan="3">
										<Border.OpacityMask>
											<MultiBinding ConverterParameter="7" Converter="{StaticResource BorderGapMaskConverter}">
												<Binding ElementName="Header" Path="ActualWidth" />
												<Binding Path="ActualWidth" RelativeSource="{RelativeSource Self}" />
												<Binding Path="ActualHeight" RelativeSource="{RelativeSource Self}" />
											</MultiBinding>
										</Border.OpacityMask>
										<Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"/>
									</Border>
								</Grid>
							</ControlTemplate>
						</Setter.Value>
					</Setter>
				</Style>
				<Style BasedOn="{StaticResource ButtonStyle}" TargetType="{x:Type Button}" />
				<Style BasedOn="{StaticResource ScrollBarStyle}" TargetType="{x:Type ScrollBar}" />
				<Style BasedOn="{StaticResource ScrollViewerStyle}" TargetType="{x:Type ScrollViewer}" />
				<Style BasedOn="{StaticResource ComboBoxStyle}" TargetType="{x:Type ComboBox}" />
				<Style BasedOn="{StaticResource ComboBoxItemStyle}" TargetType="{x:Type ComboBoxItem}" />
				<Style BasedOn="{StaticResource TextBoxStyle}" TargetType="{x:Type TextBox}" />
				<Style BasedOn="{StaticResource ListBoxStyle}" TargetType="{x:Type ListBox}" />
				<Style BasedOn="{StaticResource ListBoxItemStyle}" TargetType="{x:Type ListBoxItem}" />
				<Style BasedOn="{StaticResource CheckBoxStyle}" TargetType="CheckBox">
					<Setter Property="VerticalContentAlignment" Value="Top" />
				</Style>
				<Style BasedOn="{StaticResource RadioButtonStyle}" TargetType="{x:Type RadioButton}" />
				<Style BasedOn="{StaticResource LabelStyle}" TargetType="{x:Type Label}" />
				<Style BasedOn="{StaticResource SliderStyle}" TargetType="{x:Type Slider}" />
				<Style BasedOn="{StaticResource RepeatButtonStyle}" TargetType="{x:Type RepeatButton}" />
				<Style BasedOn="{StaticResource GridSplitterStyle}" TargetType="{x:Type GridSplitter}" />
				<Style BasedOn="{StaticResource ProgressBarStyle}" TargetType="{x:Type ProgressBar}" />
				<Style BasedOn="{StaticResource PasswordBoxStyle}" TargetType="{x:Type PasswordBox}" />
				<Style BasedOn="{StaticResource ExpanderStyle}" TargetType="{x:Type Expander}" />
				<Style BasedOn="{StaticResource ToggleButtonStyle}" TargetType="{x:Type ToggleButton}" />
				<Style BasedOn="{StaticResource GroupBoxStyle}" TargetType="{x:Type GroupBox}" />
			</ResourceDictionary>
		</ResourceDictionary.MergedDictionaries>
	</ResourceDictionary>
</Window.Resources>

<Grid HorizontalAlignment="Left" VerticalAlignment="Top" Width="699" Height="315" Margin="3,-1,0,0">
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Profiles:" Margin="10,7,0,0" Name="lblProfiles"/>
<ListBox HorizontalAlignment="Left" BorderThickness="1" Height="199" VerticalAlignment="Top" Width="560" Margin="14,35,0,0" Background="#ffffff" Name="listProfiles"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Selected:" Margin="10,245,0,0" Name="lblSelected"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="(no profile selected)" Margin="63,245,0,0" Name="lblSelectedProfile" FontWeight="Bold"/>
<Button Content="Start" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="588,35,0,0" Name="btnStart"/>
<Button Content="Cache" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="588,65,0,0" Name="btnCache"/>
<Button Content="Location" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="588,95,0,0" Name="btnLocation"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="New profile:" Margin="10,285,0,0" Name="lblNewProfile"/>
<TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="90,283,0,0" Name="txtNewProfile" VerticalScrollBarVisibility="Disabled" FlowDirection="LeftToRight" Text=""/>
<Button Content="Create" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="588,285,0,0" Name="btnCreate"/>
<TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="23" Width="120" TextWrapping="Wrap" Margin="328.5,282.5875244140625,0,0" Name="txtSelectedProfile" Visibility="Hidden"/>
<ComboBox HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="290,242,0,0" Name="cmbAuth"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="AUTH:" Margin="247,245,0,0" Name="lblAuth"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="RING:" Margin="413,245,0,0" Name="lblRing"/>
<ComboBox HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="454,242,0,0" Name="cmbRing"/>
<Button Content="Delete" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="588,125,0,0" Name="btnDelete"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="DEV:" Margin="190,245,0,0" Name="lblDev"/>
<CheckBox HorizontalAlignment="Left" VerticalAlignment="Top" Content="" Margin="225,250,0,0" Name="chkDev"/>
</Grid>
</Window>
"@


#endregion

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Script Execution
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

#region Execution
$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

$customProfiles = Get-CustomProfiles
# $hooks = ''

$cmbAuth.Items.Add('WAM')
$cmbAuth.Items.Add('ADAL')
$cmbRing.Items.Add('Ring0')
$cmbRing.Items.Add('Ring1')
$cmbRing.Items.Add('Ring1_5')
$cmbRing.Items.Add('Ring2')
$cmbRing.Items.Add('Ring3')
$cmbRing.Items.Add('Ring3_6')
$cmbRing.Items.Add('Ring3_9')
$cmbRing.Items.Add('General')
$cmbAuth.SelectedIndex = $cmbAuth.Items.IndexOf('WAM')
$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('General')

if ($customProfiles) {
  foreach ($cp in $customProfiles) {
    $listProfiles.Items.Add($cp.Name)
  }

} else {
  $listProfiles.Items.Add("No custom profiles found. Please create one.")
}

if ($listProfiles.Items[0] -eq "No custom profiles found. Please create one.") {
	$btnStart.IsEnabled = $false
	$btnCache.IsEnabled = $false
	$btnLocation.IsEnabled = $false
	$btnDelete.IsEnabled = $false
	$listProfiles.IsEnabled = $false
	$cmbAuth.IsEnabled = $false
	$cmbRing.IsEnabled = $false
	$chkDev.IsEnabled = $false
}
#endregion

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Icon
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

#region Icon
$tmsIconBase64 = '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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8C////BP///wT///8E////Cv///xv///8b////G////xv///8/////P////z////8/////Tf///1L///9S////Uv///0r///9B////Qf///0H///85////G////xv///8b////G/7+/gX+/v4E/v7+BP7+/gT09PQF8fHxBvHx8Qbx8fEG4uLiDNzc3Bbc3NwW3NzcFtnZ2RjOzs4gzs7OIM7OziDOzs4g0NDQINDQ0CDQ0NAg0NDQINjY2B3e3t4b3t7eG97e3hvh4eEX6urqEerq6hHq6uoR6urqEfHx8Qfx8fEH8fHxB/Hx8Qfx8fED8fHxAvHx8QLx8fEC8fHxAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wT///8I////CP///wj///8V////Of///zn///85////Of///4b///+G////hv///4b///+k////r////6////+v////nv///4v///+L////i////3v///86////Ov///zr///86/v7+C/7+/gj+/v4I/v7+CPT09Avx8fEM8fHxDPHx8Qzi4uIa3NzcMNzc3DDc3Nww2dnZM87OzkTOzs5Ezs7ORM7OzkTQ0NBF0NDQRdDQ0EXQ0NBF2NjYPt7e3jne3t453t7eOeHh4TLq6uol6urqJerq6iXq6uok8fHxEPHx8RDx8fEQ8fHxEPHx8Qfx8fEF8fHxBfHx8QXx8fECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////BP///wj///8I////CP///xX///85////Of///zn///85////hv///4b///+G////hv///6T///+v////r////6////+e////i////4v///+L////e////zr///86////Ov///zr+/v4L/v7+CP7+/gj+/v4I9PT0C/Hx8Qzx8fEM8fHxDOLi4hrc3Nww3NzcMNzc3DDZ2dkzzs7ORM7OzkTOzs5Ezs7ORNDQ0EXQ0NBF0NDQRdDQ0EXY2Ng+3t7eOd7e3jne3t454eHhMurq6iXq6uol6urqJerq6iTx8fEQ8fHxEPHx8RDx8fEQ8fHxB/Hx8QXx8fEF8fHxBfHx8QIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8E////CP///wj///8I////Ff///zn///85////Of///zn///+G////hv///4b///+G////pP///6////+v////r////57///+L////i////4v///97////Ov///zr///86////Ov7+/gv+/v4I/v7+CP7+/gj09PQL8fHxDPHx8Qzx8fEM4uLiGtzc3DDc3Nww3NzcMNnZ2TPOzs5Ezs7ORM7OzkTOzs5E0NDQRdDQ0EXQ0NBF0NDQRdjY2D7e3t453t7eOd7e3jnh4eEy6urqJerq6iXq6uol6urqJPHx8RDx8fEQ8fHxEPHx8RDx8fEH8fHxBfHx8QXx8fEF8fHxAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUB9fX1AvX19QL19fUC9fX1Avb29gL29vYC9vb2Avb29gL19fUB9fX1AfX19QH19fUB9fX1AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wT///8I////CP///wj///8V////O////zv///87////O////4v///+L////i////4v///+t////uf///7n///+5////q////5r///+a////mv///4v///9O////Tv///07///9O////G////xf///8X////F/b29hby8vIV8vLyFfLy8hXj4+Mk29vbO9vb2zvb29s72NjYP8vLy1nLy8tZy8vLWcvLy1nLy8tey8vLXsvLy17Ly8te1NTUU9vb20zb29tM29vbTN7e3kLp6ekv6enpL+np6S/p6ekt8fHxEvHx8RLx8fES8fHxEvHx8Qjx8fEF8fHxBfHx8QXx8fECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPX19Qb19fUM9fX1DPX19Qz19fUM9vb2Cvb29gr29vYK9vb2CvX19QX19fUF9fX1BfX19QX19fUCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////BP///wf///8H////B////xb///9B////Qf///0H///9B////nv///57///+e////nv///87////g////4P///+D////c////2P///9j////Y////zf///5////+f////n////5////9Z////VP///1T///9U9/f3Q/Ly8jry8vI68vLyOuXl5Uza2tpm2traZtra2mbW1tZvxcXFq8XFxavFxcWrxcXFq8TExMHExMTExMTExMTExMTOzs6q1tbWmNbW1pjW1taY2tragubm5lbm5uZW5ubmVubm5lLx8fEa8fHxGvHx8Rrx8fEa8fHxCvLy8gby8vIG8vLyBvLy8gMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA9fX1BvX19Qz19fUM9fX1DPX19Qz29vYK9vb2Cvb29gr29vYK9fX1BfX19QX19fUF9fX1BfX19QIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8E////B////wf///8H////Fv///0H///9B////Qf///0H///+e////nv///57///+e////zv///+D////g////4P///9z////Y////2P///9j////N////n////5////+f////n////1n///9U////VP///1T39/dD8vLyOvLy8jry8vI65eXlTNra2mba2tpm2traZtbW1m/FxcWrxcXFq8XFxavFxcWrxMTEwcTExMTExMTExMTExM7OzqrW1taY1tbWmNbW1pja2tqC5ubmVubm5lbm5uZW5ubmUvHx8Rrx8fEa8fHxGvHx8Rrx8fEK8vLyBvLy8gby8vIG8vLyAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUG9fX1DPX19Qz19fUM9fX1DPb29gr29vYK9vb2Cvb29gr19fUF9fX1BfX19QX19fUF9fX1AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wT///8H////B////wf///8W////Qf///0H///9B////Qf///57///+e////nv///57////O////4P///+D////g////3P///9j////Y////2P///83///+f////n////5////+f////Wf///1T///9U////VPf390Py8vI68vLyOvLy8jrl5eVM2traZtra2mba2tpm1tbWb8XFxavFxcWrxcXFq8XFxavExMTBxMTExMTExMTExMTEzs7OqtbW1pjW1taY1tbWmNra2oLm5uZW5ubmVubm5lbm5uZS8fHxGvHx8Rrx8fEa8fHxGvHx8Qry8vIG8vLyBvLy8gby8vIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPX19Qb19fUM9fX1DPX19Qz19fUM9vb2Cvb29gr29vYK9vb2CvX19QX19fUF9fX1BfX19QX19fUCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////BP///wf///8H////B////xb///9B////Qf///0H///9B////nv///57///+e////nv///87////g////4P///+D////c////2P///9j////Y////zf///5////+f////n////5////9Z////VP///1T///9U9/f3Q/Ly8jry8vI68vLyOuXl5Uza2tpm2traZtra2mbW1tZvxcXFq8XFxavFxcWrxcXFq8TExMHExMTExMTExMTExMTOzs6q1tbWmNbW1pjW1taY2tragubm5lbm5uZW5ubmVubm5lLx8fEa8fHxGvHx8Rrx8fEa8fHxCvLy8gby8vIG8vLyBvLy8gMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA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///6////+v////z//////////////////////////////////////////////8H///+9////vf///736+vqa9vb2iPb29oj29vaI7u7ujePj45Tj4+OU4+PjlN/f35zLy8vTy8vL08vLy9PLy8vTxcXF5cTExOjExMToxMTE6MvLy8LS0tKp0tLSqdLS0qnW1taO5OTkWOTk5Fjk5ORY5OTkVPHx8Rbx8fEW8fHxFvHx8Rbx8fEI8vLyBPLy8gTy8vIE8vLyAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADa2to22tradNra2nTa2tp029vbedzc3Izc3NyM3NzcjNzc3Izi4uJi4+PjX+Pj41/j4+Nf5OTkL+jo6Bfo6OgX6OjoF+jo6A/m5uYC5ubmAubm5gLm5uYCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAO3t7QHt7e0C7e3tAu3t7QLv7+8T7+/vQO/v70Dv7+9A7+/vQPz8/Kj8/Pyo/Pz8qPz8/Kj+/v7k////+f////n////5/////P/////////////////////////+/////v////7////+////2v///9f////X////1/39/bn7+/up+/v7qfv7+6n39/ef7+/vkO/v75Dv7++Q7OzskNjY2JLY2NiS2NjYktjY2JLOzs6FzMzMg8zMzIPMzMyD0NDQZ9XV1VTV1dVU1dXVVNjY2EXk5OQm5OTkJuTk5Cbl5eUk8fHxCfHx8Qnx8fEJ8fHxCfHx8QPy8vIB8vLyAfLy8gHy8vIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANbW1kHW1taM1tbWjNbW1ozW1taS2NjYrNjY2KzY2Nis2NjYrN/f33rg4OB24ODgduDg4Hbi4uI75+fnHufn5x7n5+ce5+fnE+Tk5APk5OQD5OTkA+Tk5AMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5OTkAeTk5ALk5OQC5OTkAurq6hPq6upA6urqQOrq6kDq6upA+/v7qfv7+6n7+/up+/v7qf7+/uT////5////+f////n////8//////////////////////////7////+/////v////7////m////5P///+T////k/v7+yP39/br9/f26/f39uvv7+6j29vaO9vb2jvb29o709PSK5eXlceXl5XHl5eVx5eXlcdra2lTY2NhQ2NjYUNjY2FDZ2dk52traKtra2ira2toq3NzcIObm5g3m5uYN5ubmDebm5gzw8PAC8PDwAvDw8ALw8PAC8PDwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1tbWQdbW1ozW1taM1tbWjNbW1pLY2Nis2NjYrNjY2KzY2Nis39/feuDg4Hbg4OB24ODgduLi4jvn5+ce5+fnHufn5x7n5+cT5OTkA+Tk5APk5OQD5OTkAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADk5OQB5OTkAuTk5ALk5OQC6urqE+rq6kDq6upA6urqQOrq6kD7+/up+/v7qfv7+6n7+/up/v7+5P////n////5////+f////z//////////////////////////v////7////+/////v///+b////k////5P///+T+/v7I/f39uv39/br9/f26+/v7qPb29o729vaO9vb2jvT09Irl5eVx5eXlceXl5XHl5eVx2traVNjY2FDY2NhQ2NjYUNnZ2Tna2toq2traKtra2irc3Nwg5ubmDebm5g3m5uYN5ubmDPDw8ALw8PAC8PDwAvDw8ALw8PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADW1tZB1tbWjNbW1ozW1taM1tbWktjY2KzY2Nis2NjYrNjY2Kzf39964ODgduDg4Hbg4OB24uLiO+fn5x7n5+ce5+fnHufn5xPk5OQD5OTkA+Tk5APk5OQDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOTk5AHk5OQC5OTkAuTk5ALq6uoT6urqQOrq6kDq6upA6urqQPv7+6n7+/up+/v7qfv7+6n+/v7k////+f////n////5/////P/////////////////////////+/////v////7////+////5v///+T////k////5P7+/sj9/f26/f39uv39/br7+/uo9vb2jvb29o729vaO9PT0iuXl5XHl5eVx5eXlceXl5XHa2tpU2NjYUNjY2FDY2NhQ2dnZOdra2ira2toq2traKtzc3CDm5uYN5ubmDebm5g3m5uYM8PDwAvDw8ALw8PAC8PDwAvDw8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM7OzkfOzs6Zzs7Omc7OzpnOzs6hz8/PxM/Pz8TPz8/Ez8/PxNjY2JjZ2dmU2dnZlNnZ2ZTe3t5V5ubmNubm5jbm5uY25eXlJOPj4wjj4+MI4+PjCOPj4wcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADm5uYK5ubmDObm5gzm5uYM4eHhFt/f3x7f398e39/fHuHh4Svj4+NO4+PjTuPj407j4+NO+Pj4jvj4+I74+PiO+Pj4jv39/bL+/v7A/v7+wP7+/sD////B////w////8P////D////wv///8D////A////wP///8D///+8////vP///7z///+8/v7+tP7+/rD+/v6w/v7+sPz8/KX5+fmW+fn5lvn5+Zb4+PiP6urqZ+rq6mfq6upn6urqZ93d3T3Z2dk32dnZN9nZ2Tfa2tol2traGdra2hna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//8K////Cv///wr///8C////Af///wH///8B////GP///yP///8j////I////0H///9u////bv///27///9y////i////4v///+L////i/7+/mD9/f1a/f39Wv39/Vr9/f0n/f39Bf39/QX9/f0F/f39AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxsbGS8bGxqHGxsahxsbGocXFxa7Dw8Pgw8PD4MPDw+DDw8PgwcHB/MHBwf7BwcH+wcHB/sPDw/nExMT2xMTE9sTExPbHx8fizs7Ow87OzsPOzs7D0NDQt+Li4mfi4uJn4uLiZ+Li4mfn5+ci6+vrF+vr6xfr6+sX6+vrCQAAAAAAAAAAAAAAANjY2ALY2NgF2NjYBdjY2AXb29sK3t7eUd7e3lHe3t5R3t7eUdHR0afQ0NC80NDQvNDQ0LzKysrSxsbG5cbGxuXGxsblycnJ3NHR0cPR0dHD0dHRw9HR0cPu7u6W7u7ulu7u7pbu7u6W+fn5fP7+/nL+/v5y/v7+cv7+/l3///9G////Rv///0b///86////C////wv///8L////C////wEAAAAAAAAAAAAAAAD///8S////G////xv///8b////Ov///2j///9o////aP///23///+P////j////4////+P/v7+aP7+/mL+/v5i/v7+Yv7+/iv9/f0G/f39Bv39/Qb9/f0EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADGxsZLxsbGocbGxqHGxsahxcXFrsPDw+DDw8Pgw8PD4MPDw+DBwcH8wcHB/sHBwf7BwcH+w8PD+cTExPbExMT2xMTE9sfHx+LOzs7Dzs7Ow87OzsPQ0NC34uLiZ+Li4mfi4uJn4uLiZ+fn5yLr6+sX6+vrF+vr6xfr6+sJAAAAAAAAAAAAAAAA2NjYAtjY2AXY2NgF2NjYBdvb2wre3t5R3t7eUd7e3lHe3t5R0dHRp9DQ0LzQ0NC80NDQvMrKytLGxsblxsbG5cbGxuXJycnc0dHRw9HR0cPR0dHD0dHRw+7u7pbu7u6W7u7ulu7u7pb5+fl8/v7+cv7+/nL+/v5y/v7+Xf///0b///9G////Rv///zr///8L////C////wv///8L////AQAAAAAAAAAAAAAAAP///xL///8b////G////xv///86////aP///2j///9o////bf///4////+P////j////4/+/v5o/v7+Yv7+/mL+/v5i/v7+K/39/Qb9/f0G/f39Bv39/QQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMbGxkvGxsahxsbGocbGxqHFxcWuw8PD4MPDw+DDw8Pgw8PD4MHBwfzBwcH+wcHB/sHBwf7Dw8P5xMTE9sTExPbExMT2x8fH4s7OzsPOzs7Dzs7Ow9DQ0Lfi4uJn4uLiZ+Li4mfi4uJn5+fnIuvr6xfr6+sX6+vrF+vr6wkAAAAAAAAAAAAAAADY2NgC2NjYBdjY2AXY2NgF29vbCt7e3lHe3t5R3t7eUd7e3lHR0dGn0NDQvNDQ0LzQ0NC8ysrK0sbGxuXGxsblxsbG5cnJydzR0dHD0dHRw9HR0cPR0dHD7u7ulu7u7pbu7u6W7u7ulvn5+Xz+/v5y/v7+cv7+/nL+/v5d////Rv///0b///9G////Ov///wv///8L////C////wv///8BAAAAAAAAAAAAAAAA////Ev///xv///8b////G////zr///9o////aP///2j///9t////j////4////+P////j/7+/mj+/v5i/v7+Yv7+/mL+/v4r/f39Bv39/Qb9/f0G/f39BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzc3NRc3NzZTNzc2Uzc3NlMzMzKHIyMjYyMjI2MjIyNjIyMjYwsLC+8LCwv7CwsL+wsLC/sHBwfzAwMD7wMDA+8DAwPvDw8PxxsbG4sbGxuLGxsbix8fH2tLS0qXS0tKl0tLSpdLS0qXX19ds2NjYZNjY2GTY2Nhk19fXTtbW1kDW1tZA1tbWQNfX10LY2NhG2NjYRtjY2EbY2NhK1dXVidXV1YnV1dWJ1dXVicnJycvHx8fcx8fH3MfHx9zFxcXkw8PD68PDw+vDw8Prx8fH4dPT08TT09PE09PTxNPT08Tv7++s7+/vrO/v76zv7++s+vr6qP7+/qb+/v6m/v7+pv7+/pz///+R////kf///5H///+G////W////1v///9b////W////yr///8n////J////yf///8f////Gv///xr///8a////Mv///1T///9U////VP///1z///+P////j////4////+P////fP///3n///95////ef///z7///8X////F////xf///8R////A////wP///8D////AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADT09NB09PTi9PT04vT09OL0dHRmcvLy9LLy8vSy8vL0svLy9LDw8P7wsLC/sLCwv7CwsL+v7+//76+vv++vr7/vr6+/8DAwPzCwsL3wsLC98LCwvfDw8Pyzc3Nzs3Nzc7Nzc3Ozc3NztTU1J7W1taX1tbWl9bW1pfW1tZ91tbWa9bW1mvW1tZr19fXbdjY2HHY2Nhx2NjYcdfX13XS0tKu0tLSrtLS0q7S0tKuxcXF5MPDw/HDw8Pxw8PD8cLCwvDBwcHvwcHB78HBwe/FxcXk1NTUxdTU1MXU1NTF1NTUxe/v77vv7++77+/vu+/v77v6+vrF/v7+yf7+/sn+/v7J/v7+xv///8P////D////w////7n///+Q////kP///5D///+Q////Rv///0H///9B////Qf///yf///8a////Gv///xr///8s////R////0f///9H////Uf///4////+P////j////4////+J////iP///4j///+I////S////yP///8j////I////xn///8F////Bf///wX///8FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANPT00HT09OL09PTi9PT04vR0dGZy8vL0svLy9LLy8vSy8vL0sPDw/vCwsL+wsLC/sLCwv6/v7//vr6+/76+vv++vr7/wMDA/MLCwvfCwsL3wsLC98PDw/LNzc3Ozc3Nzs3Nzc7Nzc3O1NTUntbW1pfW1taX1tbWl9bW1n3W1tZr1tbWa9bW1mvX19dt2NjYcdjY2HHY2Nhx19fXddLS0q7S0tKu0tLSrtLS0q7FxcXkw8PD8cPDw/HDw8PxwsLC8MHBwe/BwcHvwcHB78XFxeTU1NTF1NTUxdTU1MXU1NTF7+/vu+/v77vv7++77+/vu/r6+sX+/v7J/v7+yf7+/sn+/v7G////w////8P////D////uf///5D///+Q////kP///5D///9G////Qf///0H///9B////J////xr///8a////Gv///yz///9H////R////0f///9R////j////4////+P////j////4n///+I////iP///4j///9L////I////yP///8j////Gf///wX///8F////Bf///wUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA09PTQdPT04vT09OL09PTi9HR0ZnLy8vSy8vL0svLy9LLy8vSw8PD+8LCwv7CwsL+wsLC/r+/v/++vr7/vr6+/76+vv/AwMD8wsLC98LCwvfCwsL3w8PD8s3Nzc7Nzc3Ozc3Nzs3Nzc7U1NSe1tbWl9bW1pfW1taX1tbWfdbW1mvW1tZr1tbWa9fX123Y2Nhx2NjYcdjY2HHX19d10tLSrtLS0q7S0tKu0tLSrsXFxeTDw8Pxw8PD8cPDw/HCwsLwwcHB78HBwe/BwcHvxcXF5NTU1MXU1NTF1NTUxdTU1MXv7++77+/vu+/v77vv7++7+vr6xf7+/sn+/v7J/v7+yf7+/sb////D////w////8P///+5////kP///5D///+Q////kP///0b///9B////Qf///0H///8n////Gv///xr///8a////LP///0f///9H////R////1H///+P////j////4////+P////if///4j///+I////iP///0v///8j////I////yP///8Z////Bf///wX///8F////BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADX19c719fXftfX137X19d+1dXVjc7OzsnOzs7Jzs7Oyc7OzsnExMT3w8PD+sPDw/rDw8P6wMDA/b6+vv++vr7/vr6+/7+/v/3BwcH6wcHB+sHBwfrBwcH2yMjI3sjIyN7IyMjeyMjI3szMzL7Nzc25zc3Nuc3NzbnPz8+h0dHRkdHR0ZHR0dGR0tLSk9PT05XT09OV09PTldLS0pnNzc3Fzc3Nxc3NzcXNzc3FwsLC7MDAwPbAwMD2wMDA9sDAwPHBwcHtwcHB7cHBwe3FxcXi1dXVxNXV1cTV1dXE1dXVxO/v77/v7++/7+/vv+/v77/6+vrR/v7+2P7+/tj+/v7Y/v7+1////9f////X////1////9D///+0////tP///7T///+0////a////2b///9m////Zv///0j///85////Of///zn///9G////Wv///1r///9a////Yv///5f///+X////l////5f///+O////jf///43///+N////Uv///yr///8q////Kv///x7///8G////Bv///wb///8FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOTk5C/k5ORk5OTkZOTk5GTf39901dXVttXV1bbV1dW21dXVtsfHx+/GxsbzxsbG88bGxvPBwcH7v7+//7+/v/+/v7//v7+//76+vv++vr7/vr6+/76+vv+/v7//v7+//7+/v/+/v7//wsLC/cPDw/3Dw8P9w8PD/cjIyOrMzMzezMzM3szMzN7Nzc3ezs7O3s7Ozt7Ozs7ezc3N38XFxfTFxcX0xcXF9MXFxfS9vb39u7u7/7u7u/+7u7v/vr6+88DAwOnAwMDpwMDA6cXFxd/X19fC19fXwtfX18LX19fC7+/vyO/v78jv7+/I7+/vyPv7++n+/v71/v7+9f7+/vX+/v76/////////////////////v////z////8/////P////z///+1////sP///7D///+w////iv///3f///93////d////3r///9/////f////3////+E////qP///6j///+o////qP///5n///+X////l////5f///9e////OP///zj///84////KP///wf///8H////B////wcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5OTkL+Tk5GTk5ORk5OTkZN/f33TV1dW21dXVttXV1bbV1dW2x8fH78bGxvPGxsbzxsbG88HBwfu/v7//v7+//7+/v/+/v7//vr6+/76+vv++vr7/vr6+/7+/v/+/v7//v7+//7+/v//CwsL9w8PD/cPDw/3Dw8P9yMjI6szMzN7MzMzezMzM3s3Nzd7Ozs7ezs7O3s7Ozt7Nzc3fxcXF9MXFxfTFxcX0xcXF9L29vf27u7v/u7u7/7u7u/++vr7zwMDA6cDAwOnAwMDpxcXF39fX18LX19fC19fXwtfX18Lv7+/I7+/vyO/v78jv7+/I+/v76f7+/vX+/v71/v7+9f7+/vr////////////////////+/////P////z////8/////P///7X///+w////sP///7D///+K////d////3f///93////ev///3////9/////f////4T///+o////qP///6j///+o////mf///5f///+X////l////17///84////OP///zj///8o////B////wf///8H////BwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADk5OQv5OTkZOTk5GTk5ORk39/fdNXV1bbV1dW21dXVttXV1bbHx8fvxsbG88bGxvPGxsbzwcHB+7+/v/+/v7//v7+//7+/v/++vr7/vr6+/76+vv++vr7/v7+//7+/v/+/v7//v7+//8LCwv3Dw8P9w8PD/cPDw/3IyMjqzMzM3szMzN7MzMzezc3N3s7Ozt7Ozs7ezs7O3s3Nzd/FxcX0xcXF9MXFxfTFxcX0vb29/bu7u/+7u7v/u7u7/76+vvPAwMDpwMDA6cDAwOnFxcXf19fXwtfX18LX19fC19fXwu/v78jv7+/I7+/vyO/v78j7+/vp/v7+9f7+/vX+/v71/v7++v////////////////////7////8/////P////z////8////tf///7D///+w////sP///4r///93////d////3f///96////f////3////9/////hP///6j///+o////qP///6j///+Z////l////5f///+X////Xv///zj///84////OP///yj///8H////B////wf///8HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOTk5C3k5ORh5OTkYeTk5GHg4OBy1dXVtNXV1bTV1dW01dXVtMfHx+7GxsbyxsbG8sbGxvLBwcH7v7+//7+/v/+/v7//v7+//76+vv++vr7/vr6+/76+vv+/v7//v7+//7+/v/+/v7//wsLC/cPDw/3Dw8P9w8PD/cjIyOzLy8vgy8vL4MvLy+DMzMzgzc3N4M3NzeDNzc3gzMzM4cXFxfXFxcX1xcXF9cXFxfW9vb39u7u7/7u7u/+7u7v/vr6+88DAwOnAwMDpwMDA6cXFxd7X19fC19fXwtfX18LX19fC7+/vyO/v78jv7+/I7+/vyPv7++j+/v70/v7+9P7+/vT+/v75/////////////////////v////z////8/////P////z///+5////tf///7X///+1////kf///3////9/////f////4L///+G////hv///4b///+L////q////6v///+r////q////5r///+X////l////5f///9e////OP///zj///84////KP///wf///8H////B////wYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA7+/vHe/v7z7v7+8+7+/vPujo6E/d3d2R3d3dkd3d3ZHd3d2RysrK28nJyeDJycngycnJ4MPDw/XAwMD/wMDA/8DAwP/AwMD/wcHB/8HBwf/BwcH/wcHB/8LCwv/CwsL/wsLC/8LCwv/CwsL+wsLC/sLCwv7CwsL+wcHB/cDAwP3AwMD9wMDA/cDAwP3BwcH9wcHB/cHBwf3BwcH9wMDA/sDAwP7AwMD+wMDA/ry8vP+7u7v/u7u7/7u7u/+/v7/xwsLC5cLCwuXCwsLlx8fH29fX18HX19fB19fXwdfX18Hv7+/C7+/vwu/v78Lv7+/C+vr62/7+/uT+/v7k/v7+5P7+/vH//////////////////////////v////7////+/////v////b////1////9f////X////w////7f///+3////t////7P///+v////r////6////+n////b////2////9v////b////n////5b///+W////lv///1z///81////Nf///zX///8l////Bv///wb///8G////BgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADv7+8d7+/vPu/v7z7v7+8+6OjoT93d3ZHd3d2R3d3dkd3d3ZHKysrbycnJ4MnJyeDJycngw8PD9cDAwP/AwMD/wMDA/8DAwP/BwcH/wcHB/8HBwf/BwcH/wsLC/8LCwv/CwsL/wsLC/8LCwv7CwsL+wsLC/sLCwv7BwcH9wMDA/cDAwP3AwMD9wMDA/cHBwf3BwcH9wcHB/cHBwf3AwMD+wMDA/sDAwP7AwMD+vLy8/7u7u/+7u7v/u7u7/7+/v/HCwsLlwsLC5cLCwuXHx8fb19fXwdfX18HX19fB19fXwe/v78Lv7+/C7+/vwu/v78L6+vrb/v7+5P7+/uT+/v7k/v7+8f/////////////////////////+/////v////7////+////9v////X////1////9f////D////t////7f///+3////s////6////+v////r////6f///9v////b////2////9v///+f////lv///5b///+W////XP///zX///81////Nf///yX///8G////Bv///wb///8GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAO/v7x3v7+8+7+/vPu/v7z7o6OhP3d3dkd3d3ZHd3d2R3d3dkcrKytvJycngycnJ4MnJyeDDw8P1wMDA/8DAwP/AwMD/wMDA/8HBwf/BwcH/wcHB/8HBwf/CwsL/wsLC/8LCwv/CwsL/wsLC/sLCwv7CwsL+wsLC/sHBwf3AwMD9wMDA/cDAwP3AwMD9wcHB/cHBwf3BwcH9wcHB/cDAwP7AwMD+wMDA/sDAwP68vLz/u7u7/7u7u/+7u7v/v7+/8cLCwuXCwsLlwsLC5cfHx9vX19fB19fXwdfX18HX19fB7+/vwu/v78Lv7+/C7+/vwvr6+tv+/v7k/v7+5P7+/uT+/v7x//////////////////////////7////+/////v////7////2////9f////X////1////8P///+3////t////7f///+z////r////6////+v////p////2////9v////b////2////5////+W////lv///5b///9c////Nf///zX///81////Jf///wb///8G////Bv///wYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA7+/vHe/v7z7v7+8+7+/vPujo6E/d3d2R3d3dkd3d3ZHd3d2RysrK28nJyeDJycngycnJ4MPDw/XAwMD/wMDA/8DAwP/AwMD/wcHB/8HBwf/BwcH/wcHB/8LCwv/CwsL/wsLC/8LCwv/CwsL+wsLC/sLCwv7CwsL+wcHB/cDAwP3AwMD9wMDA/cDAwP3BwcH9wcHB/cHBwf3BwcH9wMDA/sDAwP7AwMD+wMDA/ry8vP+7u7v/u7u7/7u7u/+/v7/xwsLC5cLCwuXCwsLlx8fH29fX18HX19fB19fXwdfX18Hv7+/C7+/vwu/v78Lv7+/C+vr62/7+/uT+/v7k/v7+5P7+/vH//////////////////////////v////7////+/////v////b////1////9f////X////w////7f///+3////t////7P///+v////r////6////+n////b////2////9v////b////n////5b///+W////lv///1z///81////Nf///zX///8l////Bv///wb///8G////BgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUP9fX1IPX19SD19fUg7+/vLejo6GHo6Ohh6OjoYejo6GHS0tK30dHRvtHR0b7R0dG+xcXF5cHBwfnBwcH5wcHB+cDAwPy/v7//v7+//7+/v//AwMD/wcHB/8HBwf/BwcH/wcHB/8LCwv/CwsL/wsLC/8LCwv/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/AwMD+wMDA/sDAwP7AwMD+v7+/8b+/v+6/v7/uv7+/7sTExNPKysq7ysrKu8rKyrvPz8+x4eHhluHh4Zbh4eGW4eHhlvX19bD19fWw9fX1sPX19bD9/f3U////4f///+H////h////7////////////////////////////////////////////////f////3////9/////f////z////7////+/////v////7////+/////v////7////+f///+v////r////6////+v///+o////nv///57///+e////YP///zf///83////N////yf///8H////B////wf///8GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPn5+Qv5+fkY+fn5GPn5+Rjz8/Mk7OzsVezs7FXs7OxV7OzsVdXV1a/U1NS11NTUtdTU1LXGxsbiwcHB+MHBwfjBwcH4wMDA+7+/v/+/v7//v7+//7+/v//BwcH/wcHB/8HBwf/BwcH/wsLC/8LCwv/CwsL/wsLC/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8DAwP7AwMD+wMDA/sDAwP7AwMDuwMDA6sDAwOrAwMDqxsbGy83NzbDNzc2wzc3NsNLS0qbk5OSL5OTki+Tk5Ivk5OSL9/f3q/f396v39/er9/f3q/39/dL////g////4P///+D////u///////////////////////////////////////////////////////////////////////////////////////////////////////////////9////7////+/////v////7////6v///+g////oP///6D///9i////OP///zj///84////KP///wf///8H////B////wcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+fn5C/n5+Rj5+fkY+fn5GPPz8yTs7OxV7OzsVezs7FXs7OxV1dXVr9TU1LXU1NS11NTUtcbGxuLBwcH4wcHB+MHBwfjAwMD7v7+//7+/v/+/v7//v7+//8HBwf/BwcH/wcHB/8HBwf/CwsL/wsLC/8LCwv/CwsL/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wMDA/sDAwP7AwMD+wMDA/sDAwO7AwMDqwMDA6sDAwOrGxsbLzc3NsM3NzbDNzc2w0tLSpuTk5Ivk5OSL5OTki+Tk5Iv39/er9/f3q/f396v39/er/f390v///+D////g////4P///+7///////////////////////////////////////////////////////////////////////////////////////////////////////////////3////v////7////+/////v////q////6D///+g////oP///2L///84////OP///zj///8o////B////wf///8H////BwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD5+fkL+fn5GPn5+Rj5+fkY8/PzJOzs7FXs7OxV7OzsVezs7FXV1dWv1NTUtdTU1LXU1NS1xsbG4sHBwfjBwcH4wcHB+MDAwPu/v7//v7+//7+/v/+/v7//wcHB/8HBwf/BwcH/wcHB/8LCwv/CwsL/wsLC/8LCwv/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/AwMD+wMDA/sDAwP7AwMD+wMDA7sDAwOrAwMDqwMDA6sbGxsvNzc2wzc3NsM3NzbDS0tKm5OTki+Tk5Ivk5OSL5OTki/f396v39/er9/f3q/f396v9/f3S////4P///+D////g////7v///////////////////////////////////////////////////////////////////////////////////////////////////////////////f///+/////v////7////+////+r////oP///6D///+g////Yv///zj///84////OP///yj///8H////B////wf///8HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPn5+QX5+fkM+fn5DPn5+Qz09PQU8PDwNvDw8Dbw8PA28PDwNtvb24vb29uR29vbkdvb25HLy8vLxsbG58bGxufGxsbnw8PD8MDAwP7AwMD+wMDA/sDAwP7AwMD/wMDA/8DAwP/AwMD/wsLC/8PDw//Dw8P/w8PD/8LCwv/CwsL/wsLC/8LCwv/CwsL/wcHB/8HBwf/BwcH/wcHB/8LCwvnCwsL5wsLC+cLCwvnFxcXWx8fHzcfHx83Hx8fNzMzMpdXV1YLV1dWC1dXVgtnZ2Xrq6upm6urqZurq6mbq6upm+/v7oPv7+6D7+/ug+/v7oP7+/tD////i////4v///+L////v///////////////////////////////////////////////////////////////////////////////////////////////////////////////9////8/////P////z////8////7L///+o////qP///6j///9p/v7+P/7+/j/+/v4//v7+Lvz8/Ar8/PwK/Pz8Cvz8/AkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v7+AP7+/gH+/v4B/v7+Afv7+wb6+voa+vr6Gvr6+hr6+voa5OTkbOTk5HLk5ORy5OTkcs/Pz7fKysrZysrK2crKytnGxsbnwMDA/cDAwP3AwMD9wMDA/b+/v/+/v7//v7+//7+/v//CwsL/w8PD/8PDw//Dw8P/w8PD/8PDw//Dw8P/w8PD/8LCwv/BwcH/wcHB/8HBwf/BwcH+xMTE9cTExPXExMT1xMTE9cvLy8DOzs6zzs7Os87OzrPV1dWD4uLiWeLi4lni4uJZ5ubmVPX19Ub19fVG9fX1RvX19Ub+/v6X/v7+l/7+/pf+/v6X////z////+P////j////4/////D///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////3////9/////f////3////uf///6////+v////r////3D+/v5G/v7+Rv7+/kb+/v4z+/v7DPv7+wz7+/sM+/v7CwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD+/v4A/v7+Af7+/gH+/v4B+/v7Bvr6+hr6+voa+vr6Gvr6+hrk5ORs5OTkcuTk5HLk5ORyz8/Pt8rKytnKysrZysrK2cbGxufAwMD9wMDA/cDAwP3AwMD9v7+//7+/v/+/v7//v7+//8LCwv/Dw8P/w8PD/8PDw//Dw8P/w8PD/8PDw//Dw8P/wsLC/8HBwf/BwcH/wcHB/8HBwf7ExMT1xMTE9cTExPXExMT1y8vLwM7OzrPOzs6zzs7Os9XV1YPi4uJZ4uLiWeLi4lnm5uZU9fX1RvX19Ub19fVG9fX1Rv7+/pf+/v6X/v7+l/7+/pf////P////4////+P////j////8P///////////////////////////////////////////////////////////////////////////////////////////////////////////////v////f////3////9/////f///+5////r////6////+v////cP7+/kb+/v5G/v7+Rv7+/jP7+/sM+/v7DPv7+wz7+/sLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7+/gD+/v4B/v7+Af7+/gH7+/sG+vr6Gvr6+hr6+voa+vr6GuTk5Gzk5ORy5OTkcuTk5HLPz8+3ysrK2crKytnKysrZxsbG58DAwP3AwMD9wMDA/cDAwP2/v7//v7+//7+/v/+/v7//wsLC/8PDw//Dw8P/w8PD/8PDw//Dw8P/w8PD/8PDw//CwsL/wcHB/8HBwf/BwcH/wcHB/sTExPXExMT1xMTE9cTExPXLy8vAzs7Os87OzrPOzs6z1dXVg+Li4lni4uJZ4uLiWebm5lT19fVG9fX1RvX19Ub19fVG/v7+l/7+/pf+/v6X/v7+l////8/////j////4////+P////w///////////////////////////////////////////////////////////////////////////////////////////////////////////////+////9/////f////3////9////7n///+v////r////6////9w/v7+Rv7+/kb+/v5G/v7+M/v7+wz7+/sM+/v7DPv7+wsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v7+AP7+/gH+/v4B/v7+Afv7+wT6+voT+vr6E/r6+hP6+voT5+fnXebm5mLm5uZi5ubmYtLS0qjNzc3Lzc3Ny83NzcvIyMjdwcHB+MHBwfjBwcH4wcHB+b+/v/+/v7//v7+//7+/v//CwsL/wsLC/8LCwv/CwsL/wsLC/8LCwv/CwsL/wsLC/8LCwv/AwMD/wMDA/8DAwP/BwcH+xcXF88XFxfPFxcXzxcXF883NzbXR0dGm0dHRptHR0abX19d05OTkSeTk5Enk5ORJ6OjoRfb29jz29vY89vb2PPb29jz+/v6W/v7+lv7+/pb+/v6W////0P///+X////l////5f////H///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////4////+P////j////4////vP///7P///+z////s/7+/nX9/f1M/f39TP39/Uz8/Pw3+Pj4Dvj4+A74+PgO+Pj4DQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADz8/Mz8/PzN/Pz8zfz8/M33NzcgNjY2KXY2Nil2NjYpc/Pz8HFxcXsxcXF7MXFxezExMTvvr6+/76+vv++vr7/vr6+/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wMDA/7+/v/+/v7//v7+//7+/v/7GxsbuxsbG7sbGxu7Gxsbu1NTUmNra2oLa2tqC2tragt/f30zy8vIc8vLyHPLy8hz29vYd////If///yH///8h////If///5T///+U////lP///5T////S////6f///+n////p////8////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////r////6////+v////r+/v7F/v7+vf7+/r3+/v69/Pz8g/r6+lz6+vpc+vr6XPn5+UTz8/MV8/PzFfPz8xXz8/MUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPPz8zPz8/M38/PzN/Pz8zfc3NyA2NjYpdjY2KXY2Nilz8/PwcXFxezFxcXsxcXF7MTExO++vr7/vr6+/76+vv++vr7/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/AwMD/v7+//7+/v/+/v7//v7+//sbGxu7GxsbuxsbG7sbGxu7U1NSY2tragtra2oLa2tqC39/fTPLy8hzy8vIc8vLyHPb29h3///8h////If///yH///8h////lP///5T///+U////lP///9L////p////6f///+n////z///////////////////////////////////////////////////////////////////////////////////////////////////////////////+////+v////r////6////+v7+/sX+/v69/v7+vf7+/r38/PyD+vr6XPr6+lz6+vpc+fn5RPPz8xXz8/MV8/PzFfPz8xQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8/PzM/Pz8zfz8/M38/PzN9zc3IDY2Nil2NjYpdjY2KXPz8/BxcXF7MXFxezFxcXsxMTE776+vv++vr7/vr6+/76+vv/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8DAwP+/v7//v7+//7+/v/+/v7/+xsbG7sbGxu7GxsbuxsbG7tTU1Jja2tqC2tragtra2oLf399M8vLyHPLy8hzy8vIc9vb2Hf///yH///8h////If///yH///+U////lP///5T///+U////0v///+n////p////6f////P///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////6////+v////r////6/v7+xf7+/r3+/v69/v7+vfz8/IP6+vpc+vr6XPr6+lz5+flE8/PzFfPz8xXz8/MV8/PzFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADz8/Mz8/PzN/Pz8zfz8/M33NzcgNjY2KXY2Nil2NjYpc/Pz8HFxcXsxcXF7MXFxezExMTvvr6+/76+vv++vr7/vr6+/8HBwf/BwcH/wcHB/8HBwf/BwcH/wcHB/8HBwf/BwcH/wMDA/7+/v/+/v7//v7+//7+/v/7GxsbuxsbG7sbGxu7Gxsbu1NTUmNra2oLa2tqC2tragt/f30zy8vIc8vLyHPLy8hz29vYd////If///yH///8h////If///5T///+U////lP///5T////S////6f///+n////p////8////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////r////6////+v////r+/v7F/v7+vf7+/r3+/v69/Pz8g/r6+lz6+vpc+vr6XPn5+UTz8/MV8/PzFfPz8xXz8/MUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPr6+gz6+voN+vr6Dfr6+g3p6ek46OjoTejo6E3o6OhN29vbdtLS0rTS0tK00tLStM/Pz73CwsL7wsLC+8LCwvvCwsL7vr6+/r29vf+9vb3/vb29/76+vv+/v7//v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//sXFxfDFxcXwxcXF8MXFxfDS0tKh19fXjdfX143X19eN3d3dVvDw8Cbw8PAm8PDwJvT09CX///8i////Iv///yL///8i////kP///5D///+Q////kP///87////l////5f///+X////x/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////7////+/////v39/dX9/f3P/f39z/39/c/7+/ua+fn5d/n5+Xf5+fl3+Pj4WfT09B309PQd9PT0HfT09BsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+vr6DPr6+g36+voN+vr6Denp6Tjo6OhN6OjoTejo6E3b29t20tLStNLS0rTS0tK0z8/PvcLCwvvCwsL7wsLC+8LCwvu+vr7+vb29/729vf+9vb3/vr6+/7+/v/+/v7//v7+//7+/v/+/v7//v7+//7+/v/+/v7/+xcXF8MXFxfDFxcXwxcXF8NLS0qHX19eN19fXjdfX143d3d1W8PDwJvDw8Cbw8PAm9PT0Jf///yL///8i////Iv///yL///+Q////kP///5D///+Q////zv///+X////l////5f////H////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/////v////7////+/f391f39/c/9/f3P/f39z/v7+5r5+fl3+fn5d/n5+Xf4+PhZ9PT0HfT09B309PQd9PT0GwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+voM+vr6Dfr6+g36+voN6enpOOjo6E3o6OhN6OjoTdvb23bS0tK00tLStNLS0rTPz8+9wsLC+8LCwvvCwsL7wsLC+76+vv69vb3/vb29/729vf++vr7/v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//7+/v/7FxcXwxcXF8MXFxfDFxcXw0tLSodfX143X19eN19fXjd3d3Vbw8PAm8PDwJvDw8Cb09PQl////Iv///yL///8i////Iv///5D///+Q////kP///5D////O////5f///+X////l////8f////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7////+/////v////79/f3V/f39z/39/c/9/f3P+/v7mvn5+Xf5+fl3+fn5d/j4+Fn09PQd9PT0HfT09B309PQbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPr6+gz6+voN+vr6Dfr6+g3p6ek46OjoTejo6E3o6OhN29vbdtLS0rTS0tK00tLStM/Pz73CwsL7wsLC+8LCwvvCwsL7vr6+/r29vf+9vb3/vb29/76+vv+/v7//v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//sXFxfDFxcXwxcXF8MXFxfDS0tKh19fXjdfX143X19eN3d3dVvDw8Cbw8PAm8PDwJvT09CX///8i////Iv///yL///8i////kP///5D///+Q////kP///87////l////5f///+X////x/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////7////+/////v39/dX9/f3P/f39z/39/c/7+/ua+fn5d/n5+Xf5+fl3+Pj4WfT09B309PQd9PT0HfT09BsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+vr6A/r6+gP6+voD+vr6A+zs7BXr6+sd6+vrHevr6x3f39892trabdra2m3a2tpt19fXecvLy8XLy8vFy8vLxcvLy8XDw8PrwsLC8cLCwvHCwsLxwcHB+cDAwP/AwMD/wMDA/7+/v/++vr7/vr6+/76+vv+/v7/+w8PD9sPDw/bDw8P2w8PD9srKysTNzc24zc3NuM3NzbjU1NSK39/fYt/f32Lf399i4+PjXfPz80/z8/NP8/PzT/Pz80/7+/ua+/v7mvv7+5r7+/ua/v7+z////+P////j////4/////D/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/v73/v7+9r7+/va+/v72vf397D09PSU9PT0lPT09JTz8/N47u7uQu7u7kLu7u5C7u7uPu3t7RLt7e0S7e3tEu3t7RLw8PAJ8vLyB/Ly8gfy8vIH8vLyAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8fHxCPHx8Qzx8fEM8fHxDOTk5Cjh4eFT4eHhU+Hh4VPd3d1gz8/Psc/Pz7HPz8+xz8/PscXFxeTExMTsxMTE7MTExOzCwsL3wMDA/8DAwP/AwMD/v7+//76+vv++vr7/vr6+/76+vv/CwsL4wsLC+MLCwvjCwsL4yMjI0crKysfKysrHysrKx9LS0p3d3d143d3deN3d3Xjh4eFx8fHxX/Hx8V/x8fFf8fHxX/r6+p76+vqe+vr6nvr6+p7+/v7Q////4v///+L////i////8P/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7+/vi+vr63vr6+t76+vre9vb2uPPz857z8/Oe8/PznvLy8oTt7e1P7e3tT+3t7U/t7e1L7e3tGO3t7Rjt7e0Y7e3tGPDw8Azy8vIJ8vLyCfLy8gny8vIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADx8fEI8fHxDPHx8Qzx8fEM5OTkKOHh4VPh4eFT4eHhU93d3WDPz8+xz8/Psc/Pz7HPz8+xxcXF5MTExOzExMTsxMTE7MLCwvfAwMD/wMDA/8DAwP+/v7//vr6+/76+vv++vr7/vr6+/8LCwvjCwsL4wsLC+MLCwvjIyMjRysrKx8rKysfKysrH0tLSnd3d3Xjd3d143d3deOHh4XHx8fFf8fHxX/Hx8V/x8fFf+vr6nvr6+p76+vqe+vr6nv7+/tD////i////4v///+L////w//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v7++L6+vre+vr63vr6+t729va48/PznvPz857z8/Oe8vLyhO3t7U/t7e1P7e3tT+3t7Uvt7e0Y7e3tGO3t7Rjt7e0Y8PDwDPLy8gny8vIJ8vLyCfLy8gQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPHx8Qjx8fEM8fHxDPHx8Qzk5OQo4eHhU+Hh4VPh4eFT3d3dYM/Pz7HPz8+xz8/Psc/Pz7HFxcXkxMTE7MTExOzExMTswsLC98DAwP/AwMD/wMDA/7+/v/++vr7/vr6+/76+vv++vr7/wsLC+MLCwvjCwsL4wsLC+MjIyNHKysrHysrKx8rKysfS0tKd3d3deN3d3Xjd3d144eHhcfHx8V/x8fFf8fHxX/Hx8V/6+vqe+vr6nvr6+p76+vqe/v7+0P///+L////i////4v////D/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/v74vr6+t76+vre+vr63vb29rjz8/Oe8/PznvPz857y8vKE7e3tT+3t7U/t7e1P7e3tS+3t7Rjt7e0Y7e3tGO3t7Rjw8PAM8vLyCfLy8gny8vIJ8vLyBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8fHxBPHx8Qbx8fEG8fHxBuTk5Bbh4eEv4eHhL+Hh4S/d3d0509PTgNPT04DT09OA09PTgMvLy8HKysrLysrKy8rKysvGxsbjxMTE9MTExPTExMT0wsLC97+/v/+/v7//v7+//7+/v/7BwcH7wcHB+8HBwfvBwcH7w8PD5sPDw+HDw8Phw8PD4cnJyb/Q0NCi0NDQotDQ0KLU1NSZ5eXlguXl5YLl5eWC5eXlgvb29qn29vap9vb2qfb29qn9/f3T////4v///+L////i////8P////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7////+/////v////76+vrk+fn54Pn5+eD5+fng9PT0we/v76zv7++s7+/vrO3t7Zfl5eVt5eXlbeXl5W3l5eVq5eXlNeXl5TXl5eU15eXlNe3t7R3x8fEX8fHxF/Hx8Rfx8fELAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAunp6QXp6ekF6enpBePj4w7g4OBH4ODgR+Dg4Efg4OBH1tbWmNXV1aXV1dWl1dXVpczMzM3IyMjnyMjI58jIyOfFxcXvwMDA/sDAwP7AwMD+wMDA/r+/v/+/v7//v7+//7+/v/+9vb3/vb29/729vf+9vb3/wsLC5sfHx9HHx8fRx8fH0czMzMbd3d2p3d3dqd3d3and3d2p8/PztvPz87bz8/O28/Pztvz8/Nb////i////4v///+L////w/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////P////z////8/////Pn5+eb4+Pjj+Pj44/j4+OPx8fHM6+vrvOvr67zr6+u86OjoreDg4JDg4OCQ4ODgkODg4Izj4+NW4+PjVuPj41bj4+NW7OzsMPHx8Sbx8fEm8fHxJvHx8RIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekC6enpBenp6QXp6ekF4+PjDuDg4Efg4OBH4ODgR+Dg4EfW1taY1dXVpdXV1aXV1dWlzMzMzcjIyOfIyMjnyMjI58XFxe/AwMD+wMDA/sDAwP7AwMD+v7+//7+/v/+/v7//v7+//729vf+9vb3/vb29/729vf/CwsLmx8fH0cfHx9HHx8fRzMzMxt3d3and3d2p3d3dqd3d3anz8/O28/PztvPz87bz8/O2/Pz81v///+L////i////4v////D////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8/////P////z////8+fn55vj4+OP4+Pjj+Pj44/Hx8czr6+u86+vrvOvr67zo6Oit4ODgkODg4JDg4OCQ4ODgjOPj41bj4+NW4+PjVuPj41bs7Oww8fHxJvHx8Sbx8fEm8fHxEgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QLp6ekF6enpBenp6QXj4+MO4ODgR+Dg4Efg4OBH4ODgR9bW1pjV1dWl1dXVpdXV1aXMzMzNyMjI58jIyOfIyMjnxcXF78DAwP7AwMD+wMDA/sDAwP6/v7//v7+//7+/v/+/v7//vb29/729vf+9vb3/vb29/8LCwubHx8fRx8fH0cfHx9HMzMzG3d3dqd3d3and3d2p3d3dqfPz87bz8/O28/PztvPz87b8/PzW////4v///+L////i////8P////////////////////////////////////////////////////////////////////////////////////////////////////////////////////z////8/////P////z5+fnm+Pj44/j4+OP4+Pjj8fHxzOvr67zr6+u86+vrvOjo6K3g4OCQ4ODgkODg4JDg4OCM4+PjVuPj41bj4+NW4+PjVuzs7DDx8fEm8fHxJvHx8Sbx8fESAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAunp6QTp6ekE6enpBOPj4wvg4OA84ODgPODg4Dzg4OA819fXhNbW1o/W1taP1tbWj87OzrrKysrWysrK1srKytbHx8fhwsLC+MLCwvjCwsL4wsLC+L+/v/+/v7//v7+//7+/v/+9vb3/vLy8/7y8vP+8vLz/wcHB6MbGxtXGxsbVxsbG1cvLy8rc3Nyt3Nzcrdzc3K3c3Nyt8vLyuPLy8rjy8vK48vLyuPz8/Nf////i////4v///+L////w////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/////v////7////+/n5+eb4+Pjj+Pj44/j4+OPw8PDN6urqv+rq6r/q6uq/5+fnsd7e3pfe3t6X3t7el97e3pPh4eFf4eHhX+Hh4V/h4eFf6urqN+/v7y3v7+8t7+/vLe/v7xUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5+fnAufn5w7n5+cO5+fnDufn5w7m5uYz5ubmOebm5jnm5uY53d3dbdra2pDa2tqQ2trakNPT06rLy8vfy8vL38vLy9/KysrhwMDA/8DAwP/AwMD/wMDA/7u7u/+6urr/urq6/7q6uv+9vb3wwMDA48DAwOPAwMDjxcXF2dfX173X19e919fXvdfX173w8PC/8PDwv/Dw8L/w8PC/+/v72f7+/uP+/v7j/v7+4/7+/vD///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////5////+f////n////5+vr65/n5+eT5+fnk+fn55O/v79Tn5+fJ5+fnyefn58ni4uLB19fXstfX17LX19ey19fXr9ra2oLa2tqC2tragtra2oLm5uZT7OzsR+zs7Efs7OxH7OzsIQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cC5+fnDufn5w7n5+cO5+fnDubm5jPm5uY55ubmOebm5jnd3d1t2trakNra2pDa2tqQ09PTqsvLy9/Ly8vfy8vL38rKyuHAwMD/wMDA/8DAwP/AwMD/u7u7/7q6uv+6urr/urq6/729vfDAwMDjwMDA48DAwOPFxcXZ19fXvdfX173X19e919fXvfDw8L/w8PC/8PDwv/Dw8L/7+/vZ/v7+4/7+/uP+/v7j/v7+8P///////////////////////////////////////////////////////////////////////////////////////////////////////////////v////n////5////+f////n6+vrn+fn55Pn5+eT5+fnk7+/v1Ofn58nn5+fJ5+fnyeLi4sHX19ey19fXstfX17LX19ev2tragtra2oLa2tqC2tragubm5lPs7OxH7OzsR+zs7Efs7OwhAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wLn5+cO5+fnDufn5w7n5+cO5ubmM+bm5jnm5uY55ubmOd3d3W3a2tqQ2trakNra2pDT09Oqy8vL38vLy9/Ly8vfysrK4cDAwP/AwMD/wMDA/8DAwP+7u7v/urq6/7q6uv+6urr/vb298MDAwOPAwMDjwMDA48XFxdnX19e919fXvdfX173X19e98PDwv/Dw8L/w8PC/8PDwv/v7+9n+/v7j/v7+4/7+/uP+/v7w///////////////////////////////////////////////////////////////////////////////////////////////////////////////+////+f////n////5////+fr6+uf5+fnk+fn55Pn5+eTv7+/U5+fnyefn58nn5+fJ4uLiwdfX17LX19ey19fXstfX16/a2tqC2tragtra2oLa2tqC5ubmU+zs7Efs7OxH7OzsR+zs7CEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5+fnAufn5w7n5+cO5+fnDufn5w7m5uYz5ubmOebm5jnm5uY53d3dbdra2pDa2tqQ2trakNPT06rLy8vfy8vL38vLy9/KysrhwMDA/8DAwP/AwMD/wMDA/7u7u/+6urr/urq6/7q6uv+9vb3wwMDA48DAwOPAwMDjxcXF2dfX173X19e919fXvdfX173w8PC/8PDwv/Dw8L/w8PC/+/v72f7+/uP+/v7j/v7+4/7+/vD///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////5////+f////n////5+vr65/n5+eT5+fnk+fn55O/v79Tn5+fJ5+fnyefn58ni4uLB19fXstfX17LX19ey19fXr9ra2oLa2tqC2tragtra2oLm5uZT7OzsR+zs7Efs7OxH7OzsIQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cA5+fnAefn5wHn5+cB5+fnAebm5gPm5uYE5ubmBObm5gTk5OQ65OTkX+Tk5F/k5ORf2trag9HR0c3R0dHN0dHRzc/Pz9G/v7//v7+//7+/v/+/v7//u7u7/7q6uv+6urr/urq6/729vfDAwMDjwMDA48DAwOPFxcXZ1tbWv9bW1r/W1ta/1tbWv+/v78Lv7+/C7+/vwu/v78L6+vrb/v7+5P7+/uT+/v7k/v7+8f///////////////////////////////////////////////////////////////////////////////////////////////////////////////v////n////5////+f////n7+/vc+/v72Pv7+9j7+/vY8fHxxenp6bjp6em46enpuOHh4brT09O+09PTvtPT077T09O90NDQq9DQ0KvQ0NCr0NDQq9vb233g4OBx4ODgceDg4HHg4OA1AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOXl5Tfl5eVb5eXlW+Xl5Vva2tqB0dHRzNHR0czR0dHM0NDQz7+/v/+/v7//v7+//7+/v/+7u7v/urq6/7q6uv+6urr/vb298MDAwOPAwMDjwMDA48XFxdnW1ta/1tbWv9bW1r/W1ta/7+/vwu/v78Lv7+/C7+/vwvr6+tv+/v7k/v7+5P7+/uT+/v7x///////////////////////////////////////////////////////////////////////////////////////////////////////////////+////+f////n////5////+fz8/Nz7+/vX+/v71/v7+9fx8fHE6enpt+np6bfp6em34eHhutPT07/T09O/09PTv9PT077Pz8+uz8/Prs/Pz67Pz8+u29vbgN/f33Tf399039/fdN/f3zYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5eXlN+Xl5Vvl5eVb5eXlW9ra2oHR0dHM0dHRzNHR0czQ0NDPv7+//7+/v/+/v7//v7+//7u7u/+6urr/urq6/7q6uv+9vb3wwMDA48DAwOPAwMDjxcXF2dbW1r/W1ta/1tbWv9bW1r/v7+/C7+/vwu/v78Lv7+/C+vr62/7+/uT+/v7k/v7+5P7+/vH///////////////////////////////////////////////////////////////////////////////////////////////////////////////7////5////+f////n////5/Pz83Pv7+9f7+/vX+/v71/Hx8cTp6em36enpt+np6bfh4eG609PTv9PT07/T09O/09PTvs/Pz67Pz8+uz8/Prs/Pz67b29uA39/fdN/f33Tf399039/fNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADl5eU35eXlW+Xl5Vvl5eVb2tragdHR0czR0dHM0dHRzNDQ0M+/v7//v7+//7+/v/+/v7//u7u7/7q6uv+6urr/urq6/729vfDAwMDjwMDA48DAwOPFxcXZ1tbWv9bW1r/W1ta/1tbWv+/v78Lv7+/C7+/vwu/v78L6+vrb/v7+5P7+/uT+/v7k/v7+8f///////////////////////////////////////////////////////////////////////////////////////////////////////////////v////n////5////+f////n8/Pzc+/v71/v7+9f7+/vX8fHxxOnp6bfp6em36enpt+Hh4brT09O/09PTv9PT07/T09O+z8/Prs/Pz67Pz8+uz8/Prtvb24Df399039/fdN/f33Tf3982AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QDp6ekB6enpAenp6QHp6ekB7OzsCezs7Avs7OwL7OzsC+Li4kPh4eFp4eHhaeHh4WnY2NiMzs7O0s7OztLOzs7Szc3N1b6+vv++vr7/vr6+/76+vv+7u7v/u7u7/7u7u/+7u7v/vr6+78LCwuDCwsLgwsLC4MfHx9bX19e719fXu9fX17vX19e77+/vwO/v78Dv7+/A7+/vwPr6+tr9/f3k/f395P39/eT+/v7x//////////////////////////////////////////////////////////////////////////////////////////7////9/////f////3////6////6P///+j////o////6Pz8/MP7+/u++/v7vvv7+77x8fGt6enpounp6aLp6emi4ODgrNLS0sDS0tLA0tLSwNHR0cHJycnDycnJw8nJycPJycnD0dHRldPT04rT09OK09PTitPT00AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAOnp6QHp6ekB6enpAenp6QHs7OwO7OzsEOzs7BDs7OwQ4eHhSuDg4HDg4OBw4ODgcNfX15LNzc3Vzc3N1c3NzdXMzMzYvr6+/76+vv++vr7/vr6+/7y8vP+7u7v/u7u7/7u7u/+/v7/uw8PD38PDw9/Dw8PfyMjI1djY2LnY2Ni52NjYudjY2Lnv7++/7+/vv+/v77/v7++/+vr62v39/eT9/f3k/f395P7+/vH//////////////////////////////////////////////////////////////////////////////////////////v////z////8/////P////j////f////3////9/////f/Pz8t/v7+7H7+/ux+/v7sfHx8aHp6emX6enpl+np6Zfg4OCl0dHRwdHR0cHR0dHB0NDQwsfHx87Hx8fOx8fHzsfHx87Nzc2gz8/Plc/Pz5XPz8+Vz8/PRgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekA6enpAenp6QHp6ekB6enpAezs7A7s7OwQ7OzsEOzs7BDh4eFK4ODgcODg4HDg4OBw19fXks3NzdXNzc3Vzc3N1czMzNi+vr7/vr6+/76+vv++vr7/vLy8/7u7u/+7u7v/u7u7/7+/v+7Dw8Pfw8PD38PDw9/IyMjV2NjYudjY2LnY2Ni52NjYue/v77/v7++/7+/vv+/v77/6+vra/f395P39/eT9/f3k/v7+8f/////////////////////////////////////////////////////////////////////////////////////////+/////P////z////8////+P///9/////f////3////9/8/Py3+/v7sfv7+7H7+/ux8fHxoenp6Zfp6emX6enpl+Dg4KXR0dHB0dHRwdHR0cHQ0NDCx8fHzsfHx87Hx8fOx8fHzs3NzaDPz8+Vz8/Plc/Pz5XPz89GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QDp6ekB6enpAenp6QHp6ekB7OzsDuzs7BDs7OwQ7OzsEOHh4Urg4OBw4ODgcODg4HDX19eSzc3N1c3NzdXNzc3VzMzM2L6+vv++vr7/vr6+/76+vv+8vLz/u7u7/7u7u/+7u7v/v7+/7sPDw9/Dw8Pfw8PD38jIyNXY2Ni52NjYudjY2LnY2Ni57+/vv+/v77/v7++/7+/vv/r6+tr9/f3k/f395P39/eT+/v7x//////////////////////////////////////////////////////////////////////////////////////////7////8/////P////z////4////3////9/////f////3/z8/Lf7+/ux+/v7sfv7+7Hx8fGh6enpl+np6Zfp6emX4ODgpdHR0cHR0dHB0dHRwdDQ0MLHx8fOx8fHzsfHx87Hx8fOzc3NoM/Pz5XPz8+Vz8/Plc/Pz0YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAOnp6QPp6ekD6enpA+np6QPp6ekf6enpI+np6SPp6ekj3d3dXtvb24Xb29uF29vbhdPT06PKysrgysrK4MrKyuDJycnivr6+/76+vv++vr7/vr6+/7y8vP+7u7v/u7u7/7u7u/+/v7/uw8PD38PDw9/Dw8PfyMjI1djY2LnY2Ni52NjYudjY2Lnv7++/7+/vv+/v77/v7++/+vr62/39/eT9/f3k/f395P7+/vH/////////////////////////////////////////////////////////////////////////////////////////+P///+7////u////7v///+f///+7////u////7v///+7+vr6l/n5+ZL5+fmS+fn5ku3t7ZTl5eWV5eXlleXl5ZXb29uozc3NzM3NzczNzc3MzMzMzcTExNvExMTbxMTE28TExNvJycmoysrKnMrKypzKysqcysrKSQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekB6enpB+np6Qfp6ekH6enpB+jo6Djo6Og/6OjoP+jo6D/a2tp81tbWpdbW1qXW1talz8/PvsbGxvDGxsbwxsbG8MXFxfG+vr7/vr6+/76+vv++vr7/vLy8/7y8vP+8vLz/vLy8/8DAwO7ExMTfxMTE38TExN/JycnV2NjYutjY2LrY2Ni62NjYuu/v78Dv7+/A7+/vwO/v78D6+vrb/f395f39/eX9/f3l/v7+8f/////////////////////////////////////////////////////////////////////////////////////////v////2P///9j////Y////zf///4T///+E////hP///4T39/dn9fX1Y/X19WP19fVj5ubmgN/f35Pf39+T39/fk9XV1azIyMjdyMjI3cjIyN3Hx8fev7+/7r+/v+6/v7/uv7+/7sPDw7TExMSmxMTEpsTExKbExMRNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QHp6ekH6enpB+np6Qfp6ekH6OjoOOjo6D/o6Og/6OjoP9ra2nzW1tal1tbWpdbW1qXPz8++xsbG8MbGxvDGxsbwxcXF8b6+vv++vr7/vr6+/76+vv+8vLz/vLy8/7y8vP+8vLz/wMDA7sTExN/ExMTfxMTE38nJydXY2Ni62NjYutjY2LrY2Ni67+/vwO/v78Dv7+/A7+/vwPr6+tv9/f3l/f395f39/eX+/v7x/////////////////////////////////////////////////////////////////////////////////////////+/////Y////2P///9j////N////hP///4T///+E////hPf392f19fVj9fX1Y/X19WPm5uaA39/fk9/f35Pf39+T1dXVrMjIyN3IyMjdyMjI3cfHx96/v7/uv7+/7r+/v+6/v7/uw8PDtMTExKbExMSmxMTEpsTExE0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAenp6Qfp6ekH6enpB+np6Qfo6Og46OjoP+jo6D/o6Og/2trafNbW1qXW1tal1tbWpc/Pz77GxsbwxsbG8MbGxvDFxcXxvr6+/76+vv++vr7/vr6+/7y8vP+8vLz/vLy8/7y8vP/AwMDuxMTE38TExN/ExMTfycnJ1djY2LrY2Ni62NjYutjY2Lrv7+/A7+/vwO/v78Dv7+/A+vr62/39/eX9/f3l/f395f7+/vH/////////////////////////////////////////////////////////////////////////////////////////7////9j////Y////2P///83///+E////hP///4T///+E9/f3Z/X19WP19fVj9fX1Y+bm5oDf39+T39/fk9/f35PV1dWsyMjI3cjIyN3IyMjdx8fH3r+/v+6/v7/uv7+/7r+/v+7Dw8O0xMTEpsTExKbExMSmxMTETQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADo6OgC6OjoDejo6A3o6OgN6OjoDeXl5UPl5eVL5eXlS+Xl5UvY2NiG1NTUrdTU1K3U1NStzs7OxMXFxfLFxcXyxcXF8sXFxfO+vr7/vr6+/76+vv++vr7/vLy8/7y8vP+8vLz/vLy8/8DAwO/ExMTgxMTE4MTExODIyMjX2NjYu9jY2LvY2Ni72NjYu+/v78Dv7+/A7+/vwO/v78D6+vrb/f395f39/eX9/f3l/v7+8f///////////////////////////////////////////////P////z////8/////P////j////1////9f////X////k////yv///8r////K////v////3f///93////d////3f39/de9fX1WvX19Vr19fVa5ubmet/f34/f39+P39/fj9XV1anIyMjdyMjI3cjIyN3Hx8fev7+/8L+/v/C/v7/wv7+/8MLCwrbDw8Oow8PDqMPDw6jDw8NOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wfn5+c15+fnNefn5zXn5+c13d3ditzc3Jfc3NyX3Nzcl9DQ0MPKysrgysrK4MrKyuDGxsbqwMDA/8DAwP/AwMD/wMDA/8DAwP/AwMD/wMDA/8DAwP+8vLz/u7u7/7u7u/+7u7v/v7+/9MLCwurCwsLqwsLC6sfHx+DW1tbE1tbWxNbW1sTW1tbE7u7uwu7u7sLu7u7C7u7uwvn5+dz9/f3m/f395v39/eb+/v7y///////////////////////////////////////////////q////6f///+n////p////yP///7f///+3////t////5r///9u////bv///27///9k////Jv///yb///8m////Jvb29iP09PQi9PT0IvT09CLj4+NU4ODgduDg4Hbg4OB21dXVmMnJydzJycncycnJ3MjIyN68vLz7vLy8+7y8vPu8vLz7vb29wb6+vrO+vr6zvr6+s76+vlQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5+fnB+fn5zXn5+c15+fnNefn5zXd3d2K3Nzcl9zc3Jfc3NyX0NDQw8rKyuDKysrgysrK4MbGxurAwMD/wMDA/8DAwP/AwMD/wMDA/8DAwP/AwMD/wMDA/7y8vP+7u7v/u7u7/7u7u/+/v7/0wsLC6sLCwurCwsLqx8fH4NbW1sTW1tbE1tbWxNbW1sTu7u7C7u7uwu7u7sLu7u7C+fn53P39/eb9/f3m/f395v7+/vL//////////////////////////////////////////////+r////p////6f///+n////I////t////7f///+3////mv///27///9u////bv///2T///8m////Jv///yb///8m9vb2I/T09CL09PQi9PT0IuPj41Tg4OB24ODgduDg4HbV1dWYycnJ3MnJydzJycncyMjI3ry8vPu8vLz7vLy8+7y8vPu9vb3Bvr6+s76+vrO+vr6zvr6+VAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cH5+fnNefn5zXn5+c15+fnNd3d3Yrc3NyX3Nzcl9zc3JfQ0NDDysrK4MrKyuDKysrgxsbG6sDAwP/AwMD/wMDA/8DAwP/AwMD/wMDA/8DAwP/AwMD/vLy8/7u7u/+7u7v/u7u7/7+/v/TCwsLqwsLC6sLCwurHx8fg1tbWxNbW1sTW1tbE1tbWxO7u7sLu7u7C7u7uwu7u7sL5+fnc/f395v39/eb9/f3m/v7+8v//////////////////////////////////////////////6v///+n////p////6f///8j///+3////t////7f///+a////bv///27///9u////ZP///yb///8m////Jv///yb29vYj9PT0IvT09CL09PQi4+PjVODg4Hbg4OB24ODgdtXV1ZjJycncycnJ3MnJydzIyMjevLy8+7y8vPu8vLz7vLy8+729vcG+vr6zvr6+s76+vrO+vr5UAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wfn5+c15+fnNefn5zXn5+c13d3ditzc3Jfc3NyX3Nzcl9DQ0MPKysrgysrK4MrKyuDGxsbqwMDA/8DAwP/AwMD/wMDA/8DAwP/AwMD/wMDA/8DAwP+8vLz/u7u7/7u7u/+7u7v/v7+/9MLCwurCwsLqwsLC6sfHx+DW1tbE1tbWxNbW1sTW1tbE7u7uwu7u7sLu7u7C7u7uwvn5+dz9/f3m/f395v39/eb+/v7y///////////////////////////////////////////////q////6f///+n////p////yP///7f///+3////t////5r///9u////bv///27///9k////Jv///yb///8m////Jvb29iP09PQi9PT0IvT09CLj4+NU4ODgduDg4Hbg4OB21dXVmMnJydzJycncycnJ3MjIyN68vLz7vLy8+7y8vPu8vLz7vb29wb6+vrO+vr6zvr6+s76+vlQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpA+np6QPp6ekD6enpA9/f3wjd3d0K3d3dCt3d3Qrg4OAU4uLiI+Li4iPi4uIj4ODgLt3d3Xnd3d153d3ded3d3XnQ0NDLzs7O2M7OztjOzs7Yx8fH7MLCwvnCwsL5wsLC+cHBwfu/v7//v7+//7+/v/+/v7//wcHB/8HBwf/BwcH/wcHB/729vfy8vLz8vLy8/Ly8vPy/v7/sw8PD3sPDw97Dw8PeyMjI1NjY2LrY2Ni62NjYutjY2Lrw8PDA8PDwwPDw8MDw8PDA+/v73f7+/uj+/v7o/v7+6P7+/vH////8/////P////z////3////4////+P////j////4////6v///+n////p////6f///9y////V////1f///9X////Pf///xf///8X////F////xX///8F////Bf///wX///8F9vb2DfX19Q719fUO9fX1Dunp6TXo6OhO6OjoTujo6E7d3d1w09PTs9PT07PT09Oz0tLStsXFxd/FxcXfxcXF38XFxd/ExMS0xMTEqcTExKnExMSpxMTETwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekE6enpBOnp6QTp6ekE39/fCd3d3Qzd3d0M3d3dDODg4Bfi4uIo4uLiKOLi4ijg4OA03NzchNzc3ITc3NyE3NzchM7OztXNzc3izc3N4s3NzeLFxcXywcHB/cHBwf3BwcH9wMDA/r+/v/+/v7//v7+//7+/v//BwcH/wcHB/8HBwf/BwcH/vb29/Ly8vPu8vLz7vLy8+8DAwOrDw8Pcw8PD3MPDw9zIyMjT2NjYudjY2LnY2Ni52NjYufDw8MDw8PDA8PDwwPDw8MD7+/vd/v7+6P7+/uj+/v7o/v7+8f////z////8/////P////b////f////3////9/////f////of///53///+d////nf///2T///9I////SP///0j///8v////Cv///wr///8K////CQAAAAAAAAAAAAAAAAAAAAD29vYK9vb2C/b29gv29vYL6+vrMOrq6kjq6upI6urqSN/f32rV1dWt1dXVrdXV1a3U1NSwxsbG28bGxtvGxsbbxsbG28XFxbHFxcWnxcXFp8XFxafFxcVOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QTp6ekE6enpBOnp6QTf398J3d3dDN3d3Qzd3d0M4ODgF+Li4iji4uIo4uLiKODg4DTc3NyE3NzchNzc3ITc3NyEzs7O1c3NzeLNzc3izc3N4sXFxfLBwcH9wcHB/cHBwf3AwMD+v7+//7+/v/+/v7//v7+//8HBwf/BwcH/wcHB/8HBwf+9vb38vLy8+7y8vPu8vLz7wMDA6sPDw9zDw8Pcw8PD3MjIyNPY2Ni52NjYudjY2LnY2Ni58PDwwPDw8MDw8PDA8PDwwPv7+93+/v7o/v7+6P7+/uj+/v7x/////P////z////8////9v///9/////f////3////9////+h////nf///53///+d////ZP///0j///9I////SP///y////8K////Cv///wr///8JAAAAAAAAAAAAAAAAAAAAAPb29gr29vYL9vb2C/b29gvr6+sw6urqSOrq6kjq6upI39/fatXV1a3V1dWt1dXVrdTU1LDGxsbbxsbG28bGxtvGxsbbxcXFscXFxafFxcWnxcXFp8XFxU4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpBOnp6QTp6ekE6enpBN/f3wnd3d0M3d3dDN3d3Qzg4OAX4uLiKOLi4iji4uIo4ODgNNzc3ITc3NyE3NzchNzc3ITOzs7Vzc3N4s3NzeLNzc3ixcXF8sHBwf3BwcH9wcHB/cDAwP6/v7//v7+//7+/v/+/v7//wcHB/8HBwf/BwcH/wcHB/729vfy8vLz7vLy8+7y8vPvAwMDqw8PD3MPDw9zDw8PcyMjI09jY2LnY2Ni52NjYudjY2Lnw8PDA8PDwwPDw8MDw8PDA+/v73f7+/uj+/v7o/v7+6P7+/vH////8/////P////z////2////3////9/////f////3////6H///+d////nf///53///9k////SP///0j///9I////L////wr///8K////Cv///wkAAAAAAAAAAAAAAAAAAAAA9vb2Cvb29gv29vYL9vb2C+vr6zDq6upI6urqSOrq6kjf399q1dXVrdXV1a3V1dWt1NTUsMbGxtvGxsbbxsbG28bGxtvFxcWxxcXFp8XFxafFxcWnxcXFTgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+Pj4APj4+AL4+PgC+Pj4Avj4+ALs7OwY7OzsGuzs7Brs7Owa39/fNN3d3UHd3d1B3d3dQdjY2FfU1NR41NTUeNTU1HjT09OCzc3Nws3NzcLNzc3Czc3NwsXFxe3ExMTzxMTE88TExPPAwMD6vb29/r29vf69vb3+vr6+/r6+vv++vr7/vr6+/76+vv/CwsL/wsLC/8LCwv/CwsL/wcHB7cHBwejBwcHowcHB6MbGxszLy8uzy8vLs8vLy7PPz8+s3t7emN7e3pje3t6Y3t7emPT09L709PS+9PT0vvT09L78/Pzi////7////+/////v////7f///+v////r////6////93///+k////pP///6T///+k////YP///1z///9c////XP///zf///8l////Jf///yX///8Y////BP///wT///8E////AwAAAAAAAAAAAAAAAAAAAAD09PQF9PT0BvT09Ab09PQG7OzsH+zs7C/s7Owv7OzsL+Pj40rd3d2B3d3dgd3d3YHc3NyE0tLSrdLS0q3S0tKt0tLSrdLS0pLR0dGL0dHRi9HR0YvR0dFBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD4+PgB+Pj4A/j4+AP4+PgD+Pj4A+zs7Cbs7Owo7OzsKOzs7Cjf399R3d3dZd3d3WXd3d1l19fXgtLS0q3S0tKt0tLSrdDQ0LXHx8fsx8fH7MfHx+zHx8fsv7+//L6+vv++vr7/vr6+/7y8vP+7u7v/u7u7/7u7u/+8vLz/vb29/729vf+9vb3/vb29/8PDw//Dw8P/w8PD/8PDw//FxcXjxcXF3MXFxdzFxcXcy8vLt9LS0pfS0tKX0tLSl9bW1pHk5OSC5OTkguTk5ILk5OSC9vb2vPb29rz29va89vb2vP39/eT////z////8/////P////q////3////9/////f////y////33///99////ff///33///81////MP///zD///8w////Gf///w3///8N////Df///wgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPDw8APw8PAD8PDwA/Dw8APu7u4T7u7uHu7u7h7u7u4e6enpNebm5mPm5uZj5ubmY+Xl5Wbe3t6O3t7ejt7e3o7e3t6O3d3dfd3d3Xnd3d153d3ded3d3TgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPj4+AH4+PgD+Pj4A/j4+AP4+PgD7OzsJuzs7Cjs7Owo7OzsKN/f31Hd3d1l3d3dZd3d3WXX19eC0tLSrdLS0q3S0tKt0NDQtcfHx+zHx8fsx8fH7MfHx+y/v7/8vr6+/76+vv++vr7/vLy8/7u7u/+7u7v/u7u7/7y8vP+9vb3/vb29/729vf+9vb3/w8PD/8PDw//Dw8P/w8PD/8XFxePFxcXcxcXF3MXFxdzLy8u30tLSl9LS0pfS0tKX1tbWkeTk5ILk5OSC5OTkguTk5IL29va89vb2vPb29rz29va8/f395P////P////z////8////+r////f////3////9/////L////ff///33///99////ff///zX///8w////MP///zD///8Z////Df///w3///8N////CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8PDwA/Dw8APw8PAD8PDwA+7u7hPu7u4e7u7uHu7u7h7p6ek15ubmY+bm5mPm5uZj5eXlZt7e3o7e3t6O3t7ejt7e3o7d3d193d3ded3d3Xnd3d153d3dOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+Pj4Afj4+AP4+PgD+Pj4A/j4+APs7Owm7OzsKOzs7Cjs7Owo39/fUd3d3WXd3d1l3d3dZdfX14LS0tKt0tLSrdLS0q3Q0NC1x8fH7MfHx+zHx8fsx8fH7L+/v/y+vr7/vr6+/76+vv+8vLz/u7u7/7u7u/+7u7v/vLy8/729vf+9vb3/vb29/729vf/Dw8P/w8PD/8PDw//Dw8P/xcXF48XFxdzFxcXcxcXF3MvLy7fS0tKX0tLSl9LS0pfW1taR5OTkguTk5ILk5OSC5OTkgvb29rz29va89vb2vPb29rz9/f3k////8/////P////z////6v///9/////f////3////8v///99////ff///33///99////Nf///zD///8w////MP///xn///8N////Df///w3///8IAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw8PAD8PDwA/Dw8APw8PAD7u7uE+7u7h7u7u4e7u7uHunp6TXm5uZj5ubmY+bm5mPl5eVm3t7ejt7e3o7e3t6O3t7ejt3d3X3d3d153d3ded3d3Xnd3d04AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPz8/AH8/PwC/Pz8Avz8/AL5+fkD9/f3Cff39wn39/cJ9/f3Cevr6zTq6uo36urqN+rq6jfd3d1k2traetra2nra2tp61NTUlc7Ozr7Ozs6+zs7OvszMzMTExMTvxMTE78TExO/ExMTvwMDA9MDAwPXAwMD1wMDA9cDAwPLAwMDwwMDA8MDAwPDAwMDuwsLC6cLCwunCwsLpwsLC6MbGxt7GxsbexsbG3sbGxt7Hx8e+x8fHtsfHx7bHx8e2zMzMlNPT03bT09N209PTdtfX13Pl5eVo5eXlaOXl5Wjl5eVo9/f3p/f396f39/en9/f3p/39/dX////m////5v///+b////g////2v///9r////a////x////3r///96////ev///3r///8v////Kv///yr///8q////FP///wn///8J////Cf///wUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPDw8ALw8PAC8PDwAvDw8ALu7u4N7u7uFe7u7hXu7u4V6urqJ+fn50vn5+dL5+fnS+bm5k7g4OBv4ODgb+Dg4G/g4OBv4ODgY+Dg4GDg4OBg4ODgYODg4C0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/Pz8Avz8/AX8/PwF/Pz8Bfn5+Qj39/cV9/f3Fff39xX39/cV6enpUOnp6VTp6elU6enpVNvb24nX19ek19fXpNfX16TPz8+8x8fH38fHx9/Hx8ffxsbG4r+/v/W/v7/1v7+/9b+/v/XCwsLkw8PD4cPDw+HDw8PhyMjI2MvLy9LLy8vSy8vL0s3NzcvQ0NC80NDQvNDQ0LzQ0NC60dHRnNHR0ZzR0dGc0dHRnM/Pz3POzs5pzs7Oac7OzmnS0tJN2NjYNdjY2DXY2Ng13d3dNerq6jTq6uo06urqNOrq6jT6+vp9+vr6ffr6+n36+vp9/v7+uP///83////N////zf///87////P////z////8////+9////df///3X///91////df///yP///8d////Hf///x3///8KAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPDw8ALw8PAD8PDwA/Dw8APu7u4L7u7uHO7u7hzu7u4c7u7uHe3t7TDt7e0w7e3tMO3t7TDu7u4u7u7uLu7u7i7u7u4u7u7uFQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwC/Pz8Bfz8/AX8/PwF+fn5CPf39xX39/cV9/f3Fff39xXp6elQ6enpVOnp6VTp6elU29vbidfX16TX19ek19fXpM/Pz7zHx8ffx8fH38fHx9/Gxsbiv7+/9b+/v/W/v7/1v7+/9cLCwuTDw8Phw8PD4cPDw+HIyMjYy8vL0svLy9LLy8vSzc3Ny9DQ0LzQ0NC80NDQvNDQ0LrR0dGc0dHRnNHR0ZzR0dGcz8/Pc87OzmnOzs5pzs7OadLS0k3Y2Ng12NjYNdjY2DXd3d016urqNOrq6jTq6uo06urqNPr6+n36+vp9+vr6ffr6+n3+/v64////zf///83////N////zv///8/////P////z////73///91////df///3X///91////I////x3///8d////Hf///woAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8PDwAvDw8APw8PAD8PDwA+7u7gvu7u4c7u7uHO7u7hzu7u4d7e3tMO3t7TDt7e0w7e3tMO7u7i7u7u4u7u7uLu7u7i7u7u4VAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPz8/AL8/PwF/Pz8Bfz8/AX5+fkI9/f3Fff39xX39/cV9/f3Fenp6VDp6elU6enpVOnp6VTb29uJ19fXpNfX16TX19ekz8/PvMfHx9/Hx8ffx8fH38bGxuK/v7/1v7+/9b+/v/W/v7/1wsLC5MPDw+HDw8Phw8PD4cjIyNjLy8vSy8vL0svLy9LNzc3L0NDQvNDQ0LzQ0NC80NDQutHR0ZzR0dGc0dHRnNHR0ZzPz89zzs7Oac7OzmnOzs5p0tLSTdjY2DXY2Ng12NjYNd3d3TXq6uo06urqNOrq6jTq6uo0+vr6ffr6+n36+vp9+vr6ff7+/rj////N////zf///83////O////z////8/////P////vf///3X///91////df///3X///8j////Hf///x3///8d////CgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw8PAC8PDwA/Dw8APw8PAD7u7uC+7u7hzu7u4c7u7uHO7u7h3t7e0w7e3tMO3t7TDt7e0w7u7uLu7u7i7u7u4u7u7uLu7u7hUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/Pz8Avz8/AX8/PwF/Pz8Bfn5+Qj39/cW9/f3Fvf39xb39/cW6enpUOnp6VTp6elU6enpVNra2onX19ej19fXo9fX16PP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6OgC6OjoAujo6ALo6OgC+/v7DPv7+wz7+/sM+/v7DP7+/hj///8c////HP///xz///8g////JP///yT///8k////Iv///xz///8c////HP///xz///8N////DP///wz///8M////BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA7e3tAO3t7QDt7e0A7e3tAO3t7QDt7e0A7e3tAO3t7QDt7e0A8fHxAPLy8gDy8vIA8vLyAPLy8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////gAAAAAAAAAA//////////4AAAAAAAAAAP/////////+AAAAAAAAAAD//////////gAAAAAAAAAA//8AA/////4AAAAAAAAAAP//AAP////+AAAAAAAAAAD//wAD/////gAAAAAAAAAA//8AA/////4AAAAAAAAAAP//AAP////+AAAAAAAAAAD//wAAA////gAAAAAAAAAA//8AAAP///4AAAAAAAAAAP//AAAD///+AAAAAAAAAAD//wAAA////gAAAAAAAAAA//8AAAP///4AAAAAAAAAAP//AAAD///+AAAAAAAAAA///wAAA////gAAAAAAAAAP//8AAAP///4AAAAAAAAAD///AAAD///gAAAAAAAAAA///wAAA///4AAAAAAAAf////8AAAP//+AAAAAAAAH/////AAAD///gAAAAAAAB/////wAAAB/8AAAAAAAAAf////8AAAAf/AAAAH+AAAH/////AAAAH/wAAAB/gAAB/////wAAAB/8AAAAf4AAAf////8AAAAf/AAAAH+AAAH/////AAAAAcAAAAAAAAAAH////wAAAAHAAAAAADgAAB////8AAAABwAAAAAA4AAAf////AAAAAcAAAAAAOAAAH////wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH///8AAAAAAAAAAAAAAAAB////AAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAH/////gAAAAAAAAAAAAAAB/////4AAAAAAAAAAAAAAAf////+AAAAAAAAAAAAAAAH/////gAAAAAAAAAAAAAAB/////4AAAAAAAAAAAAAAAf////+AAAAAAAAAAAAAAAH/////gAAAAAAAAAAAAAAB/////4AAAAAAAAAAAAAAAf////+AAAAAAAAAAAAAAAAA////+AAAAAAAAAAAAAAAAP////gAAAAAAAAAAAAAAAD////4AAAAAAAAAAAAAAAA////+AAAAAAAAAAAAAAAAP////+AAAAAAAAAAAAAAAD/////gAAAAAAAAAAAAAAA/////4AAAAAAAAAAAAAAAP////+AAAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP///////AAAAAAAAAAAAAD///////wAAAAAAAAAAAAA///////8AAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAA//////gAAAAAAAAAAAAAAP/////4AAAAAAAAAAAAAAD///+AAAAAAAAAAAAAAAAA////gAAAAAAAAAAAA8AAAP///4AAAAAAAAAAAAPAAAD///+AAAAAAAAAAAADwAAA///wAAAAAAAAAAAAA8AAAP//8AAAAAAAAAAAAD/AAAD///AAAAAAAAAAAAA/wAAA///wAAAAAAAAAAAAP8AAAP//AAAAAAAAAAAAAD/AAAD//wAAAAAAAAAAAAP//AAA//8AAAAAAAAAAAAD//wAAP//AAAAAAAAAAAAA//8AAD//wAAAAAAAAAAAAP//AAA//8AAAAAAADgAAAD///AAP//AAAAAAAA4AAAA///wAD//wAAAAAAAOAAAAP//8AA//8AAAAAAADgAAAD///AAP//AAAAAAAA4AAAA///wAD/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////KAAAAEAAAACAAAAAAQAgAAAAAAAAQAAAEwsAABMLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8C////Bv///wv///8q////Kv///2L///9i////fP///4D///9t////Zv///0L///8r////Gf7+/gb4+PgH8fHxCefn5w7c3Nwj29vbJM7OzjLOzs4y0NDQM9DQ0DPb29ss3t7eKuXl5SDq6uob7OzsE/Hx8Qzx8fEJ8fHxBPHx8QMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////Av///wj///8P////Of///zn///+G////hv///6r///+v////lf///4v///9a////Ov///yP+/v4I+Pj4CfHx8Qzn5+cT3NzcMNvb2zHOzs5Ezs7ORNDQ0EXQ0NBF29vbO97e3jnl5eUs6urqJezs7Brx8fEQ8fHxDPHx8QXx8fEEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUF9fX1B/b29gb29vYG9vb2BfX19QP19fUCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wL///8H////D////z7///8+////lP///5T////F////zP///77///+5////kf///3f///9Y////Nvv7+zHy8vIo6urqMNra2lDY2NhUx8fHgsfHx4LGxsaQxsbGkdPT03jY2Nhy4ODgUufn50Lq6uor8fHxFvHx8Q/y8vIG8vLyBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA9fX1CfX19Qz29vYL9vb2Cvb29gj19fUF9fX1AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8C////B////w////9B////Qf///57///+e////1////+D////a////2P///7b///+f////fP///1T8/PxL8vLyOuvr60Pa2tpm2NjYa8XFxavFxcWrxMTEwsTExMTS0tKh1tbWmN7e3mzm5uZW6enpNvHx8Rrx8fES8vLyBvLy8gQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAO7u7hzu7u4m7u7uKO7u7inv7+8h8PDwGfDw8BLx8fEF8fHxBPDw8ADw8PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/f39Af39/QX9/f0N/f39QP39/UD///+h////of///+L////s////6////+r////Y////zP///6v///+F/Pz8ePX19V7v7+9k39/fe93d3YDIyMi+yMjIvsTExNPExMTV0NDQq9TU1KDd3d1v5eXlV+jo6DXx8fEY8fHxEfLy8gXy8vIEAAAAAAAAAAAA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7++0/Pz8t/7+/rj///+u////qv///4r///91////V////zT///8r////Gv///yT///9O////Uv///4////+P////gf///4D///8x////Hf///wz///8E////AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANPT02bT09OLzc3NtsvLy9LGxsbnwsLC/sHBwf6+vr7/v7+//cLCwvfDw8P0zc3Nzs3Nzc7V1dWb1tbWl9bW1nTW1tZr19fXb9jY2HHU1NSS0tLSrsvLy8nDw8PxwsLC8MHBwe/Dw8Pp1NTUxdTU1MXv7++77+/vu/z8/Mf+/v7J////xf///8P///+k////kP///2v///9B////NP///xr///8j////R////0z///+P////j////4j///+I////N////yP///8P////Bf///wIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADd3d1T3d3dcdXV1aDR0dG/y8vL2cXFxffDw8P5v7+//7+/v/6/v7/8wMDA+8PDw+/Dw8Pvx8fH3MfHx9vMzMy/zs7OuM/Pz7nQ0NC6zMzMzMjIyN3ExMTpvr6++r6+vvbAwMDrw8PD5tbW1sPW1tbD7+/vxO/v78T8/Pzi/v7+5v///+r////r////4P///9j///+0////i////3r///9Y////XP///2z///9w////oP///6D///+T////kv///0T///8x////Ff///wb///8DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5OTkSeTk5GTZ2dmV1dXVts3NzdLGxsbzxMTE97+/v/+/v7//vr6+/76+vv+/v7//v7+//8PDw/3Dw8P9ysrK5MzMzN7Nzc3ezs7O3snJyerFxcX0wcHB+Lu7u/+8vLz5wMDA6cPDw+TX19fC19fXwu/v78jv7+/I/Pz87/7+/vX////8//////////3////8////2f///7D///+d////d////3n///9/////gv///6j///+o////mP///5f///9L////OP///xf///8H////AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6Trp6elQ3d3dgdnZ2aLPz8/DyMjI6cXFxfDAwMD/wMDA/8DAwP/AwMD/wcHB/8HBwf/CwsL+wsLC/sXFxfLFxcXvxsbG78fHx+/ExMT0wsLC+b+/v/y7u7v/vb29+cHBwefExMTi19fXwdfX18Hv7+/F7+/vxfz8/Of+/v7s////+v/////////+/////f///+r////V////y////7b///+2////uf///7n////D////w////5n///+W////Sv///zb///8W////Bv///wMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADv7+8t7+/vPuHh4XDd3d2R0tLStsnJyeDGxsbqwMDA/8DAwP/BwcH/wcHB/8LCwv/CwsL/wsLC/sLCwv7AwMD9wMDA/cHBwf3BwcH9wMDA/sDAwP6+vr7+u7u7/729vfjCwsLlxMTE4NfX18HX19fB7+/vwu/v78L8/Pzf/v7+5P////j//////////v////7////6////9f////L////t////7f///+v////q////2////9v///+b////lv///0j///81////Fv///wb///8DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8fHxIvHx8S/k5ORb4eHhedXV1aHNzc3PyMjI3sDAwPzAwMD9wMDA/8DAwP/CwsL/wsLC/8LCwv7CwsL+wcHB/sDAwP7BwcH+wcHB/sDAwP7AwMD+v7+/+729vfe/v7/sxsbG0MjIyMvb29ur29vbq/Ly8rny8vK5/f393f7+/uL////3///////////////+/////P////n////3////9P////T////z////8v///+P////j////n////5r///9K////Nv///xb///8G////AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPn5+RL5+fkY7u7uPezs7FXc3NyC1NTUtczMzMvBwcH4wcHB+b+/v/+/v7//wcHB/8HBwf/CwsL/wsLC/8HBwf/BwcH/wcHB/8HBwf/AwMD+wMDA/sDAwPbAwMDqw8PD283NzbDPz8+r5OTki+Tk5Iv39/er9/f3q/7+/tn////g////9/////////////////////////////////////////////////////7////v////7////6X///+g////Tf///zj///8X////B////wMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD5+fkN+fn5Eu/v7zHt7e1F3t7ecdfX16PPz8+9w8PD8MLCwvO/v7/+v7+//8DAwP/AwMD/wsLC/8LCwv/CwsL/wsLC/8HBwf/BwcH/wcHB/cHBwfzCwsLvw8PD28bGxsrQ0NCZ09PTlefn53nn5+d5+fn5pvn5+ab+/v7Z////4f////f////////////////////////////////////////////////////+////8f////H///+p////pP///1H///88/v7+Gf39/Qj9/f0EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v7+Af7+/gH6+voQ+vr6Gunp6UPk5ORy19fXlMrKytnIyMjgwMDA/cDAwP2/v7//v7+//8PDw//Dw8P/w8PD/8PDw//CwsL/wcHB/8PDw/rExMT1x8fH287OzrPR0dGb4uLiWeTk5Fb19fVG9fX1Rv7+/pf+/v6X////2f///+P////4/////////////////////////////////////////////////////v////f////3////tP///6/+/v5b/v7+Rv39/R/7+/sM+/v7BgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7+/gH+/v4B+vr6Dvr6+hfp6ek+5eXlatjY2I3Ly8vSycnJ2sHBwfvBwcH7v7+//7+/v//CwsL/w8PD/8PDw//Dw8P/wcHB/8HBwf/Dw8P5xMTE9MjIyNfPz8+s0tLSlOPj41Hl5eVP9vb2Qfb29kH+/v6X/v7+l////9r////k////+P////////////////////////////////////////////////////7////3////9////7b///+x/v7+Xv39/Un8/Pwh+fn5Dfn5+QYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8/PzGvPz8zfj4+Nc2NjYpdPT07PFxcXsxMTE7b6+vv++vr7/wcHB/8HBwf/BwcH/wcHB/8DAwP+/v7//w8PD9sbGxu7Ly8vD2tragtzc3Gfy8vIc9PT0Hf///yH///8h////lP///5T////e////6f////n/////////////////////////////////////////////////////////+v////r+/v7B/v7+vfv7+2/6+vpc+Pj4LfPz8xXz8/MKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPPz8xrz8/M34+PjXNjY2KXT09OzxcXF7MTExO2+vr7/vr6+/8HBwf/BwcH/wcHB/8HBwf/AwMD/v7+//8PDw/bGxsbuy8vLw9ra2oLc3Nxn8vLyHPT09B3///8h////If///5T///+U////3v///+n////5//////////////////////////////////////////////////////////r////6/v7+wf7+/r37+/tv+vr6XPj4+C3z8/MV8/PzCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+voG+vr6De3t7SLo6OhN4ODgYtLS0rTR0dG5wsLC+8LCwvu9vb3/vb29/7+/v/+/v7//v7+//7+/v//CwsL3xcXF8MrKysjX19eN2dnZcvDw8Cby8vIl////Iv///yL///+Q////kP///9r////l////+P/////////////////////////////////////////////////////////+/////v39/dL9/f3P+vr6ifn5+Xf39/c79PT0HfT09A4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+vr6Bvr6+g3t7e0i6OjoTeDg4GLS0tK00dHRucLCwvvCwsL7vb29/729vf+/v7//v7+//7+/v/+/v7//wsLC98XFxfDKysrI19fXjdnZ2XLw8PAm8vLyJf///yL///8i////kP///5D////a////5f////j//////////////////////////////////////////////////////////v////79/f3S/f39z/r6+on5+fl39/f3O/T09B309PQOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPr6+gH6+voC7u7uCO3t7RXk5OQk3d3dYNvb22bNzc27zc3Nu8TExOvDw8PvwMDA/MDAwP+/v7//vr6+/8DAwPvCwsL3xcXF4cvLy7/Ozs6p3t7ebeDg4Gry8vJX8vLyV/v7+5z7+/uc////2f///+L////3////////////////////////////////////////////////////////////////+/v73vr6+tz19fWm9PT0mfHx8WPt7e1I7e3tLe3t7RXu7u4Q8vLyCPLy8gYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPHx8QTx8fEM5+fnGuHh4VPf399Zz8/Psc/Pz7HFxcXoxMTE7MHBwfvAwMD/v7+//76+vv/AwMD7wsLC+MXFxeTKysrHzc3Nst3d3Xjf39918fHxX/Hx8V/6+vqe+vr6nv///9n////i////9/////////////////////////////////////////////////////////////////r6+uD6+vre9fX1q/Pz857w8PBp7e3tT+3t7TLt7e0Y7u7uEvLy8gny8vIHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADx8fEB8fHxA+fn5wji4uIa4ODgH9jY2GPY2Nhj0NDQss/Pz7jHx8fjxsbG7cHBwfm/v7/+wMDA/sDAwP3AwMD4wMDA8MLCwuHLy8u5zc3NtODg4JXg4OCV9fX1sPX19bD+/v7b////4v////f//////////////////////////////////////////////////////////f////35+fnj+fn54vDw8L3t7e205+fnkOLi4n/j4+Ng5OTkRefn5zbx8fEe8fHxFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekB6enpBeTk5Ang4OBH4ODgR9XV1Z/V1dWlysrK2sjIyOfDw8P2wMDA/r+/v/+/v7//vr6+/729vf+/v7/zx8fH0cnJyczd3d2p3d3dqfPz87bz8/O2/v7+3P///+L////3//////////////////////////////////////////////////////////z////8+fn55fj4+OPu7u7E6+vrvOTk5J/g4OCQ4eHhcePj41bm5uZD8fHxJvHx8RwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAOnp6QLl5eUE4uLiJeLi4iXb29tg29vbZNLS0qPR0dGzycnJ2cbGxuvDw8P2wMDA/76+vv+7u7v/vb299sPDw9zFxcXX2dnZtdnZ2bXx8fG78fHxu/39/d3+/v7j////9//////////////////////////////////////////////////////////6////+vn5+eX5+fnk7Ozsyunp6cTg4OCv2trapNvb24nd3d1w4eHhW+3t7Trt7e0qAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5+fnAefn5w7n5+cO5ubmNubm5jnb29t/2trakM/Pz8XLy8vfxcXF8MDAwP++vr7/urq6/7u7u/jAwMDjw8PD3tfX173X19e98PDwv/Dw8L/8/Pze/v7+4/////j/////////////////////////////////////////////////////////+f////n5+fnl+fn55Ovr687n5+fJ3d3dutfX17LY2NiY2tragt/f32rs7OxH7OzsNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wDn5+cH5+fnB+bm5h3m5uYe3t7eZd7e3nfR0dG3zs7O1sbGxuzAwMD/vb29/7q6uv+7u7v4wMDA48PDw97X19e+19fXvvDw8MDw8PDA/Pz83/7+/uP////4//////////////////////////////////////////////////////////n////5+vr64Pr6+t7s7OzG6Ojowdzc3LvV1dW41dXVptTU1JfZ2dl/5OTkXOTk5EMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOXl5Unl5eVb1dXVptHR0czGxsbnv7+//729vf+6urr/u7u7+MDAwOPDw8Pe1tbWv9bW1r/v7+/C7+/vwvz8/N/+/v7k////+P/////////////////////////////////////////////////////////5////+fv7+9n7+/vX7e3tvenp6bfa2tq809PTv9HR0bbPz8+u1NTUl9/f33Tf399VAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAOnp6QDp6ekA7OzsBezs7AXj4+NP4+PjYtPT06vQ0NDPxsbG6b+/v/+9vb3/urq6/7y8vPfBwcHiw8PD3dfX173X19e97+/vwe/v78H8/Pzf/v7+5P////j///////////////////////////////////////////////7////9////8P////D7+/vN+/v7yu3t7bLp6ems2dnZudLS0sDPz8+8zMzMudDQ0KLZ2dl/2dnZXQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QDp6ekB6enpAezs7A/s7OwQ4ODgXeDg4HDR0dGzzc3N1cTExOu+vr7/vb29/7u7u/+9vb32w8PD38XFxdrY2Ni52NjYue/v77/v7++/+/v73/39/eT////4//////////////////////////////////////////7////8////+v///9/////f+/v7tPv7+7Ht7e2c6enpl9jY2LPR0dHBzMzMyMfHx87Kysq3z8/Plc/Pz20AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekA6enpAunp6QLq6uoY6urqGd7e3mfd3d17z8/PusvLy9rExMTuvr6+/729vf+7u7v/vb299sPDw9/Gxsba2NjYudjY2Lnv7++/7+/vv/v7+9/9/f3k////+P/////////////////////////////////////////9////9f////L////N////zfv7+6T6+vqh6+vrmOfn55bW1ta2z8/Px8rKys7FxcXUyMjIvM3NzZjNzc1wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAOnp6Qfp6ekH6OjoO+jo6D/Y2NiR1tbWpcrKytfGxsbwwsLC+L6+vv+9vb3/vLy8/76+vvbExMTfxsbG2tjY2LrY2Ni67+/vwO/v78D7+/vg/f395f////j/////////////////////////////////////////9////9j////S////hP///4T29vZl9fX1Y+Li4onf39+Tzs7OxMjIyN3Dw8Pmv7+/7sHBwdHExMSmxMTEegAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOjo6AHo6OgK6OjoCubm5kHm5uZF19fXldXV1anKysrZxsbG8cLCwvi+vr7/vb29/7y8vP++vr73xMTE4MbGxtvY2Ni72NjYu+/v78Dv7+/A+/v74P39/eX////4/////////////////////v////7////8////+v////L////R////y////37///9+9vb2YfX19V/i4uKH39/fkc7OzsTIyMjdw8PD5r+/v+/AwMDSxMTEp8TExHoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cE5+fnNefn5zXc3NyQ3Nzcl83NzdHKysrgw8PD9cDAwP/AwMD/wMDA/76+vv+7u7v/vb29+cLCwurExMTl1tbWxNbW1sTu7u7C7u7uwvv7++H9/f3m////+P////////////////////X////p////2P///7f///+o////bv///2n///8m////JvX19SL09PQi4eHhZeDg4HbOzs66ycnJ3MLCwu28vLz7vb293r6+vrO+vr6DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5+fnBOfn5zXn5+c13NzckNzc3JfNzc3RysrK4MPDw/XAwMD/wMDA/8DAwP++vr7/u7u7/729vfnCwsLqxMTE5dbW1sTW1tbE7u7uwu7u7sL7+/vh/f395v////j////////////////////1////6f///9j///+3////qP///27///9p////Jv///yb19fUi9PT0IuHh4WXg4OB2zs7OusnJydzCwsLtvLy8+729vd6+vr6zvr6+gwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QLp6ekE4uLiBt3d3Qvf398Q4uLiJeHh4Svc3Nx/3Nzcf87OztfOzs7dxMTE9cLCwvvAwMD+v7+//8DAwP/BwcH/v7+//ry8vPu+vr7zw8PD3cXFxdjY2Ni62NjYuvDw8MDw8PDA/Pz84/7+/uj////3/////P///+z////h////xP///6L///+H////T////0P///8R////EP///wP///8D9vb2DPb29g3p6ek/6enpS9jY2I7U1NSwy8vLyMXFxd3FxcXIxcXFqMXFxXsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekC6enpBOLi4gfd3d0M39/fEuLi4ijh4eEu3NzchNzc3ITOzs7czc3N4sPDw/jBwcH9wMDA/r+/v//AwMD/wcHB/7+/v/28vLz7vr6+88PDw9zFxcXX2NjYudjY2Lnw8PDA8PDwwPz8/OP+/v7o////9/////z////r////3////8D///+d////gf///0j///88////Cv///wkAAAAAAAAAAPb29gr29vYL6urqPOrq6kjZ2dmL1dXVrczMzMbGxsbbxsbGxsXFxafFxcV6AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPj4+AH4+PgC7e3tEezs7CHk5OQy3d3dU9ra2mDT09OS0tLSl8rKytfKysrXwcHB98HBwfm9vb3+vLy8/729vf+9vb3/wMDA/8PDw//Dw8Pzw8PD4sXFxdLOzs6l0NDQouHh4Y3h4eGN9fX1vfX19b3+/v7q////8f///+j////l////sv///5H///9u////Rv///zf///8Z////FP///wL///8CAAAAAAAAAADz8/ME8/PzBe3t7SDt7e0m4+PjWeHh4XLb29uJ19fXndfX15PX19eC19fXXwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD4+PgC+Pj4A+3t7RTs7Owo5OTkPN3d3WXa2tpz0tLSrdHR0bHHx8fsx8fH7L+/v/6+vr7/vLy8/7u7u/+8vLz/vb29/8DAwP/Dw8P/xMTE8cXFxdzIyMjK0tLSl9TU1JTk5OSC5OTkgvb29rz29va8/v7+7P////P////k////3////6T///99////Wf///zD///8k////Df///woAAAAAAAAAAAAAAAAAAAAA8PDwA/Dw8APu7u4Z7u7uHufn50zm5uZj4eHhet7e3o7e3t6G3d3ded3d3VkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPz8/AL8/PwD+Pj4Cvf39w/s7Owo6urqReHh4V7Y2NiP1dXVnMrKys7JycnRwsLC8sLCwvLBwcHrwcHB68TExOPFxcXhx8fH18jIyNLKysrHy8vLvcrKyqvJycmPy8vLgNTU1FbX19dV5+fnTufn5074+PiS+Pj4kv7+/tD////a////1v///9T///+d////eP///1D///8j////Gf///wT///8DAAAAAAAAAAAAAAAAAAAAAPDw8AHw8PAB7u7uCu7u7gzp6ekm6enpNObm5kLk5ORP5OTkTOTk5Efk5OQ0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwE/Pz8Bfj4+A/39/cV7OzsMunp6VTg4OBv19fXpNPT07DHx8ffxsbG4L+/v/W/v7/1w8PD4sPDw+HJycnVy8vL0s7OzsPQ0NC80NDQq9HR0ZzQ0NCIzs7OadDQ0FvY2Ng12traNerq6jTq6uo0+vr6ffr6+n3////C////zf///87////P////mf///3X///9M////Hf///xMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPDw8ALw8PAD7u7uFO7u7hzt7e0n7e3tMO3t7S/u7u4u7u7uIgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/Pz8Bfz8/Af39/cS9vb2Gurq6jfm5uZY3t7eb9TU1J3R0dGkx8fHw8bGxsTBwcHNwcHBzcfHx7rIyMi40NDQqdLS0qbV1dWR1tbWhtXV1XLU1NRg0tLSUM7OzjjQ0NAw2NjYGdvb2xnq6uod6urqHfr6+ln6+vpZ////oP///6v///+6////wP///5r///+B////Wv///y7///8fAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw8PAB8PDwAe7u7gru7u4O7e3tE+3t7Rft7e0X7u7uF+7u7hEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPz8/Ab8/PwI9vb2FvX19R/p6ek75OTkW9vb22/R0dGWz8/PmsbGxqvGxsarxMTEqsTExKrNzc2Wzs7OldnZ2YPc3Nx/39/fZOLi4lfg4OBA3d3dK9vb2x/S0tIN0tLSCgAAAADo6OgB6OjoCejo6An7+/s6+/v7Ov///4L///+N////qf///7P///+c////jP///2f///89////KQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADt7e0B7e3tAe3t7QHt7e0B8PDwAfLy8gLy8vIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwE/Pz8Bfb29g319fUT6enpI+Tk5Dfb29tC0dHRWs/Pz13GxsZnxsbGZ8TExGbExMRmzc3NWs7OzlnZ2dlP3NzcTN/f3zzi4uI04ODgJt3d3Rrb29sT0tLSCNLS0gYAAAAA6OjoAejo6AXo6OgF+/v7I/v7+yP///9O////Vf///2X///9r////Xf///1T///8+////Jf///xgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA7e3tAO3t7QHt7e0B7e3tAfDw8AHy8vIB8vLyAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//////////////////////////////////////////////+AAAAAP////4AAAAA/wH//gAAAAD/Af/+AAAAAP8AH/4AAAAA/wAf/gAAAAD/AB/+AAAAAP8AH/4AAAAD/wAf+AAAAAP/AB/4AAAA//8AA+AAAAD//wAD4ABwAP//AAPgAHAA//8AAIAAAAA//wAAgAAEAD//AAAAAAAAD/8AAAAAAAAP/wAAAAAAAA//AAAAAAAAD/8AAAAAAAAP/wAAAAAAAA//AAAAAAAAD/8AAAAAAAAP/wAAAAAAAA//AAAAAAAAD/8AAAAAAAAP//AAAAAAAA//8AAAAAAAD//wAAAAAAAP//AAAAAAAA//8AAAAAAAAP/8AAAAAAAA//wAAAAAAAD//wAAAAAAAP//AAAAAAAA///AAAAAAAD//8AAAAAAAP///gAAAAAA///AAAAAAAD//8AAAAAAAP//wAAAAAAA///AAAAAAAD//8AAAAAAAP//wAAAAAAA///AAAAAAAD/8AAAAAAAAP/wAAAAABgA/8AAAAAAGAD/wAAAAAB4AP8AAAAAAHgA/wAAAAAB/gD/AAAAAAH+AP8AAACAAf+A/wAAAIAB/4D////////////////////////////////////////////////////////////////ygAAAAwAAAAYAAAAAEAIAAAAAAAACQAABMLAAATCwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wH///8G////Hv///y7///9r////eP///4z///91////Yv///y7///8W/f39B/Hx8Qni4uIV3NzcJtDQ0DPOzs430NDQN9jY2DHe3t4t6enpHuzs7Bfx8fEN8fHxBvHx8QMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUC9fX1Avb29gL29vYB9fX1AfX19QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wL///8I////Jv///zv///+L////nf///7n///+g////i////07///8t/v7+F/Ly8hXj4+Mk29vbO83NzVPLy8tay8vLXtTU1FPb29tL6OjoMOrq6iPx8fES8fHxCPHx8QQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUK9fX1DPb29gr29vYH9fX1BfX19QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wH///8H////Kv///0H///+e////uP///+D////a////zf///5////9y////U/Pz8zvl5eVM2traZsjIyJ3FxcWwxMTExM7OzqrW1taV5eXlWejo6D7x8fEa8fHxCvLy8gUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADt7e0k7e3tLu7u7jLv7+8m7+/vHvHx8Qfx8fEE8PDwAfDw8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP39/QH9/f0F/Pz8KPz8/ED+/v6i////wf////D////v////6////9n///+v////kfb29mvs7Oxz4ODggszMzLbIyMjIxMTE2szMzLjU1NSf4+PjWufn5z7x8fEY8fHxCfLy8gQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADq6uo46urqSOvr61Ds7Ow/7u7uMe/v7w3w8PAH7+/vAe/v7wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPj4+AH4+PgD+fn5J/n5+T/+/v6l/v7+x/////r////+///////////////Y////vPf394zv7++O5OTklM/Pz8PKysrTxMTE4svLy7zS0tKg4+PjWObm5jvx8fEV8fHxB/Ly8gMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADW1tZu19fXj9jY2Kjc3NyI4ODgcObm5iHn5+cT5OTkA+Tk5AEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOXl5QDl5eUC6+vrJ+vr60D7+/up/f39yf////n////+//////////7////t////4f39/br6+vqn9fX1jufn53rh4eFv1tbWVtfX1z/Z2dku5OTkEefn5wvw8PAD8fHxAfLy8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADOzs56zs7Ooc/Pz8TU1NSn2dnZkOTk5Drl5eUk4+PjCOPj4wIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5ubmCuPj4xDf398e4uLiO+Pj4074+PiO+/v7ov7+/sD////C////wv///8D///+9////u/7+/rD8/Pyl+fn5lu7u7nHo6Ohe2dnZN9ra2iXa2toY5eXlCefn5wXw8PAB8PDwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADFxcWKxcXFuMTExOjMzMzR0tLSvuPj417l5eU84+PjD+Pj4wMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5ubmGePj4yff399I3d3dWdzc3GTw8PBl9fX1Z/z8/Gr+/v5o////Z////2L///90////gf///5////+g/v7+off392fz8/NL5OTkEeTk5AcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBwcGKwMDAu76+vvLExMTuyMjI6djY2KTa2tp/3NzcS+Hh4R3m5uYOAAAAAAAAAAAAAAAAAAAAAODg4Ajg4OAU4eHhT97e3mnX19eW1tbWk9XV1ZDr6+tV7+/vRfv7+yz+/v4a////Ff///xT///8c////Jf///2H///94////l/z8/HT6+vpd8PDwIfDw8A0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBwcGIwMDAub29vfHCwsL1xcXF9dLS0sPU1NSg19fXb97e3jXk5OQf6+vrBevr6wLY2NgA2NjYAd/f3w/f398k3Nzca9nZ2YjS0tK209PTq9PT06Pr6+tf7+/vS/z8/C7+/v4U////DP///wL///8G////C////0b///9k////jP39/Xv8/Pxo9vb2Mfb29hT9/f0B/f39AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADGxsaBxcXFrsPDw+DCwsLywcHB/sTExPbHx8fizs7Ow9zc3Hni4uJX6+vrF+vr6wnY2NgA2NjYBd3d3SPe3t5R0dHRp87OzsTGxsblzMzM0dHR0cPu7u6W8/PziP7+/nL///9P////Ov///wv///8E////Af///xr///86////aP///4f///+G/v7+Yv7+/iv9/f0G/f39AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADNzc12zMzMocjIyNjExMTvwsLC/sDAwPzDw8PxxsbG4s/Pz7HT09OY2NjYZNfX107W1tZA2NjYRtbW1mHV1dWJycnJy8bGxt/Dw8PrzMzM1NPT08Tv7++s9fX1qv7+/qb///+V////hv///1v///88////Jv///xv///8y////VP///4P///+L////ef///z7///8X////BP///wIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADU1NRu0dHRmMvLy9HFxcXswsLC/r6+vv/AwMD8wsLC98rKytjOzs7F1dXVm9XV1YHV1dVw19fXddTU1I3R0dGxxcXF5cLCwvHBwcHvzMzM1tTU1MXv7++89fX1wv7+/sv////H////vP///5X///9l////RP///yD///8v////Sf///4L///+P////if///0z///8j////Bv///wMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADj4+NR39/fdtXV1bfLy8vbxsbG9L+/v/+/v7//vr6+/7+/v/3AwMD8w8PD+cjIyObMzMzZzs7O2crKyuPFxcXxvb29/Ly8vPrAwMDpzc3N0tfX18Lv7+/H9vb22f7+/vP////7/////P////j////K////qf///3X///93////ff///5////+k////lv///13///81////Cf///wQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+dE4uLiZdjY2KfMzMzQx8fH7MDAwP6/v7//v7+//8DAwP/BwcH/w8PD/cXFxfLHx8fqyMjI6sbGxvDDw8P4vb29/ry8vPrBwcHnzc3N0dfX18Lv7+/G9vb21v7+/u7////8//////////3////f////yv///6j///+o////qv///7n///+1////l////13///81////Cf///wQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADv7+8y6OjoT93d3ZHPz8/AycnJ4cDAwP7AwMD/wcHB/8LCwv/CwsL/wsLC/sHBwf3AwMD9wcHB/cHBwf3AwMD+vLy8/7y8vPrCwsLlzs7Oz9fX18Hv7+/C9vb20P7+/uT////6//////////7////5////9f///+3////s////6////97////N////lv///1z///8z////CP///wQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fUZ7+/vLejo6GHX19eZ0dHRwMHBwffAwMD8v7+//8HBwf/BwcH/wsLC/8HBwf/BwcH/wcHB/8HBwf7AwMD+v7+/8cHBweTKysq719fXpeHh4Zb19fWw+vr6w////+H////5///////////////+/////f////v////7////+////+7////c////nv///2D///81////Cf///wQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD5+fkQ8/PzHu3t7Unb29uC1dXVq8PDw+/BwcH3v7+//8DAwP/BwcH/wsLC/8LCwv/BwcH/wcHB/8HBwf7BwcH8wsLC5cTExNLPz8+f3Nzci+bm5n34+Pin+/v7vv///+H////5//////////////////////////////////////////P////h////o////2T///85/v7+Cv7+/gUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD+/v4B+/v7Bvr6+hrn5+dP4uLidsvLy9XGxsbnwMDA/b+/v//AwMD/w8PD/8PDw//Dw8P/wcHB/8LCwvvExMT1y8vLwNDQ0KHi4uJZ7OzsTvX19Ub+/v6X////tf///+P////5//////////////////////////////////////////n////p////r////3D+/v5E/Pz8Dvv7+wcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD+/v4A+/v7Avr6+grs7Owz6OjoU9LS0rXLy8vRw8PD87+/v/2/v7//wsLC/8LCwv/CwsL/wMDA/8LCwvnFxcXx0NDQqNbW1oLn5+c08vLyMvn5+TD///+V////tv///+f////6//////////////////////////////////////////r////s/v7+t/39/Xv7+/tQ9vb2FPX19QoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADz8/Mh8PDwPNjY2KDPz8/BxcXF7L+/v/u/v7//wcHB/8HBwf/BwcH/v7+//8LCwvjGxsbu1NTUmNvb227y8vIc+vr6H////yH///+U////tv///+n////7//////////////////////////////////////////v////u/v7+vfz8/IP6+vpZ9PT0GPPz8w0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+voI9vb2EOjo6Erb29t20tLStMTExO3BwcH8vb29/76+vv+/v7//v7+//8HBwfnFxcXw0tLSodnZ2Xjw8PAm+fn5JP///yL///+Q////sv///+X////6//////////////////////////////////////////7////1/f39z/v7+5r5+flz9fX1IfT09BEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+voF9vb2Cunp6THc3NxX1tbWjcjIyM3FxcXjwMDA98DAwPy/v7//v7+//8HBwfrExMTzzc3NtNLS0pLj4+NH7u7uP/b29jr9/f2W/v7+tf///+T////6///////////////////////////////////////////+/v72/Pz81fn5+ab29vaD8PDwNe/v7yHt7e0K8PDwBfLy8gMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8fHxAfHx8Qzk5OQo4eHhU9HR0Z7MzMy9xMTE7MLCwvfAwMD/vr6+/8DAwPzCwsL4yMjI0czMzLfd3d146OjoafHx8V/6+vqe/Pz8uf///+L////5///////////////////////////////////////////+/v74+vr63vb29rjz8/Ob7e3tUu3t7Tnt7e0Y8PDwDPLy8gcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8fHxAPHx8QLl5eUK4+PjFdra2k7X19du0dHRs8rKytXGxsbtwMDA/cDAwP7AwMD+v7+/9sHBwenKysq/1tbWqd/f35r09PSx+fn5xf///+L////5//////////////////////////////////////////3+/v73+Pj44vLy8sjs7Oy04uLiheLi4mzk5ORK7OzsKPHx8RoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekC6enpBODg4DDd3d1M1tbWj87OzrrKysrXwsLC9sHBwfu/v7//vb29/76+vvfGxsbV0tLSvdzc3K3y8vK4+Pj4yf///+L////5//////////////////////////////////////////z+/v73+Pj44/Dw8M3q6uq939/fmN/f34Dh4eFf6urqN+/v7yQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wvm5uYX5ubmOd3d3W3Z2dmTy8vL3MbGxuzAwMD/u7u7/7u7u/nAwMDjzc3NzNfX173w8PC/9vb2zf7+/uP////5//////////////////////////////////////////r+/v71+fn55O/v79Tm5ubI2NjYs9jY2J/a2tqC5ubmU+zs7DkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5wTm5uYJ5ubmF+Dg4Eze3t50z8/Pz8jIyOW/v7//u7u7/7u7u/nAwMDjzMzMzdbW1r7v7+/B9vb2z/7+/uT////6//////////////////////////////////////////r+/v7z+vr63PDw8Mrn5+e+1dXVutTU1K7T09Oc3t7ebuPj404AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QDr6+sA7OzsAeXl5Tfj4+Nh0dHRyMnJyeG/v7//u7u7/7u7u/nAwMDjzMzMzdbW1r/v7+/C9vb20P7+/uT////6//////////////////////////////////////////n+/v7x+/v71fHx8cLo6Oi21NTUv9HR0bnPz8+v2tragd7e3l4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QHr6+sE7OzsD+Hh4Unf399zzs7O0MbGxua+vr7/vLy8/7y8vPnDw8Pfz8/PyNjY2Lnv7++/9fX1zv39/eT////6///////////////////////////////+/////P///+b+/v7X+/v7s/Hx8aPo6Oia0tLSv83NzcbHx8fNzc3Nn9DQ0HYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QPp6ekK6enpI93d3V7a2tqJysrK3MXFxey+vr7/vLy8/729vfnDw8Pfz8/PyNjY2Lnv7++/9fX1zv39/eT////6///////////////////////////////4////7v///8X+/v6y+fn5ku3t7ZTk5OSYzs7OysnJydLExMTbycnJqMrKyn0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6Qbo6OgS6OjoP9ra2nzV1dWoxsbG7cPDw/a+vr7/vLy8/729vfnExMTfz8/PydjY2Lrv7+/A9fX1z/39/eX////6///////////////////////////////v////2P///5X9/f199fX1Y+bm5oDe3t6WycnJ2sTExOS/v7/uw8PDtMTExIUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOfn5yPj4+M+3d3dhdHR0bXLy8vWwsLC+sHBwf3AwMD/vLy8/729vfrCwsLozs7O0dbW1sLu7u7C9fX10P39/eb////6///////////////0////7P///8f///+r////g////0j9/f039PT0L+Tk5F3e3t6AycnJ2MTExOe9vb34vr6+v7+/v40AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekA6OjoAd3d3QLg4OAF4uLiCOPj4znf399Y2NjYps3NzczIyMjnwMDA/sDAwP/AwMD/vLy8/ry8vPrCwsLnzc3N0dbW1sLu7u7C9fX10P39/eb////6/////f////n////m////1////6P///+E////Wv///yr9/f0e9PT0HeTk5E3g4OBxy8vLzsXFxeC+vr71v7+/vr+/v40AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekC6OjoBN3d3Qzg4OAX4uLiKNzc3HLY2NiXzc3N4sXFxfLBwcH9v7+//8DAwP/BwcH/vb29/L29vfXDw8Pcz8/Px9jY2Lnw8PDA9vb20P7+/uj////4////9v///9////+3////mf///0z///8v////Cv///wL29vYC9vb2C+vr6zDo6OhM1dXVqc7Ozr/GxsbbxcXFscXFxYYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+Pj4APj4+ALs7OwQ6urqG93d3UDY2NhX1NTUeM7OzrPLy8vMxMTE88DAwPq9vb3+vr6+/8DAwP/CwsL/wcHB7cPDw97Ly8uz1tbWo97e3pj09PS++fn50f///+/////r////3f///6T///95////Wf///yf///8Y////BP///wH09PQB9PT0Buzs7B/q6uoy3d3dfdjY2JLS0tKt0tLSktHR0XAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwA+fn5Afj4+ATs7Owb6urqLN3d3WXX19eE0dHRr8jIyODFxcXwvr6+/r29vf28vLz9vr6+/MDAwPzDw8P7xcXF3sfHx8rS0tKT3Nzch+Tk5H/29va5+vr60P////H////i////y////33///9O////Lv///w7///8HAAAAAAAAAADw8PAB8PDwA+7u7hLt7e0g5ubmXeLi4nHe3t6K3d3det3d3V4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwE+fn5CPf39xTr6+s56OjoVdjY2J7Q0NC5x8fH3cHBwfDAwMDxw8PD4sfHx9rKysrTz8/PwM/Pz7PQ0NCgzs7OeM7OzmPX19c54uLiOOnp6Tf6+vqA/Pz8n////8/////P////vv///3X///9B////Hf///wL///8AAAAAAAAAAADw8PAA8PDwAO/v7wPv7+8F7e3tHuzs7Cfr6+s07OzsMuzs7CcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwF+fn5Cvb29hnp6ek+5ubmWtXV1ZvOzs6wx8fHysLCwtTCwsLTxsbGw8zMzLjQ0NCw1NTUldTU1IXT09Nv0NDQTc/Pzz3Y2Ngg4+PjIurq6iP6+vpi/f39g////7P////B////tv///37///9M////KP///wIAAAAAAAAAAAAAAAAAAAAAAAAAAPDw8AHv7+8C7u7uEe3t7Rbt7e0d7u7uHe7u7hcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwG+fn5DfX19R/n5+dD4+PjXdHR0ZTMzMyexsbGq8TExKrGxsamzs7OldbW1ojc3Nx94uLiWeHh4UXd3d0r19fXE9LS0goAAAAA6OjoBejo6An7+/s6/f39W////43///+r////q////4z///9d////Ov///wMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADt7e0A7e3tAe3t7QHt7e0B8fHxAvLy8gIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/PwB+fn5A/X19Qbn5+cN4+PjE9HR0R7MzMwgxsbGIsTExCLGxsYhzs7OHtbW1hvc3NwZ4uLiEuHh4Q7d3d0J19fXBNLS0gIAAAAA6OjoAejo6AL7+/sM/f39Ev///xz///8i////Iv///xz///8T////DP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADt7e0A7e3tAO3t7QDt7e0A8fHxAPLy8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///////8AAP///////wAA////////AAD///AAAAcAAOB/8AAABwAA4H/wAAAHAADgD/AAAAcAAOAP8AAABwAA4A/wAAAHAADgD+AAAA8AAOAP4AAB/wAA4AeAAAH/AADgAAAAAH8AAOAAAAAAfwAA4AAAAAA/AADgAAAAAD8AAOAAAAAAPwAA4AAAAAA/AADgAAAAAD8AAOAAAAAAPwAA4AAAAAA/AADgAAAAAD8AAOAAAAAAPwAA/AAAAAA/AAD8AAAAAD8AAPwAAAAABwAA/gAAAAAHAAD+AAAAAAcAAP+AAAAABwAA/+AAAAAHAAD/4AAAAAcAAP/gAAAABwAA/+AAAAAHAAD/4AAAAAcAAP/gAAAABwAA/+AAAAAHAAD8AAAAAAcAAPwAAAAABwAA8AAAAAAHAADgAAAAMAcAAOAAAAAwBwAA4AAAAHwHAADgAAQAfgcAAOAABAB+BwAA////////AAD///////8AAP///////wAA////////AAAoAAAAIAAAAEAAAAABACAAAAAAAAAQAAATCwAAEwsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8B////Cv///zH///90////lf///33///9A////EvT09Anf398d09PTM8/PzzvV1dU44eHhLOvr6xvx8fEM8fHxBAAAAAAAAAAAAAAAAAAAAAD19fUI9vb2CPX19QX19fUBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wH///8L////P////5n////S////yv///5f///9X9/f3N+Dg4ErNzc17xcXFoMvLy5za2tpy5+fnPvHx8RTy8vIFAAAAAAAAAAAAAAAAAAAAAO3t7S3t7e057+/vKvDw8BHx8fED8PDwAAAAAAAAAAAAAAAAAAAAAAAAAAAA/Pz8Afz8/Aj7+/tA/v7+o////+7////0////6P///7P5+fmC6enpgNLS0qrHx8fTycnJx9fX14vm5uZG8fHxE/Ly8gQAAAAAAAAAAAAAAAAAAAAA2traZNzc3Ifg4OBr5OTkL+jo6Avm5uYBAAAAAAAAAAAAAAAAAAAAAAAAAADt7e0A7+/vBu/v70D8/Pyo////9P////7////+////4f39/bn19fWa4+PjkdPT04vPz89w2NjYReXl5R7x8fEH8vLyAQAAAAAAAAAAAAAAAAAAAADLy8uKy8vLxtLS0q/d3d1j5eXlIePj4wUAAAAAAAAAAAAAAAAAAAAA5ubmBOTk5Bbf398v4ODgVvb29oD9/f2h////pP///6H///+m/v7+qvz8/KD19fV86OjoSNvb2yDc3NwN5+fnBPDw8AEAAAAAAAAAAAAAAAAAAAAAAAAAAMLCwpbAwMDiyMjI4tTU1Kbc3NxY39/fIObm5gYAAAAAAAAAAODg4ATh4eEZ4ODgT9jY2H3X19eB7e3tWvr6+kP+/v4z////Lv///zz///9m////jfz8/H739/dD7e3tEQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAw8PDkcDAwN7CwsL2ysrK39DQ0KjY2Nhh5OTkJevr6wbY2NgB3t7eD9vb20bV1dWZzs7OxNLS0q7s7Oxx+/v7SP///yX///8L////Bv///yj///9k/v7+f/z8/GL6+voo/f39AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADLy8uEx8fHzcPDw/XBwcH7xcXF5c7OzrLX19dw2dnZPtfX1y3X19dD09PTiMnJydTFxcXn0tLSxO7u7qX9/f2W////fP///0v///8k////Gv///0H///93////gf7+/kv///8M////AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANfX123Pz8+6xsbG7cDAwP3AwMD8xMTE68rKys3Pz8+p0tLSk9HR0aLKysrPwMDA9cLCwurV1dXE7+/vv/39/db////X////u////3v///9I////Tf///3v///+T////Zf///x7///8EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5ubmTtnZ2ZzKysrcwsLC+b+/v/+/v7//wcHB/sXFxfTJycnmyMjI68LCwvi8vLz8wsLC5dfX18Lv7+/G/f397v////3////9////0v///6X///+a////qv///6f///9x////J////wUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw8PAv4ODgdc/Pz8HDw8PxwMDA/sHBwf/CwsL/wcHB/sDAwP3BwcH+v7+//b29vfbFxcXY2dnZtvDw8L39/f3h////+/////7////5////8/////D////m////vv///3H///8m////BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPn5+RLt7e1C2dnZk8fHx9zAwMD6wMDA/8HBwf/CwsL/wcHB/8HBwf7BwcH4w8PD2tDQ0KLl5eWC+Pj4qP///93////7//////////////////////////f////M////eP///yn+/v4GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v7+Afr6+hTm5uZX0NDQs8TExO3AwMD+wcHB/8PDw//CwsL/wsLC/MbGxufQ0NCk4+PjVPX19UT+/v6X////3v////v/////////////////////////+////9b///+G/f39NPr6+gkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPPz8yjc3NyAy8vL0MHBwfa/v7//wcHB/8DAwP/BwcH6yMjI2Nvb23Tz8/Mc////If///5T////j/////P/////////////////////////8////3v39/Zb5+flE8/PzDwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+vr6Cunp6TjX19eLyMjI2sDAwP2+vr7/v7+//8HBwfvHx8fc2NjYf/Hx8Sb///8i////kP///9/////8//////////////////////////7+/v7o/Pz8rPj4+Fn09PQVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+voB7u7uC+Hh4TzT09OLyMjI0MLCwvS/v7//v7+//cTExO3MzMy43t7ecfHx8Vv6+vqd////3v////v///////////////////////////39/e/4+PjD8vLyge3t7T3t7e0U8vLyBwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADx8fEB5OTkCtzc3DXV1dV/zc3NxsTExPHAwMD+v7+//cDAwPHKysrD39/fn/T09LP+/v7f////+//////////////////////////+/Pz88PT09NHp6emo4eHheOXl5UXx8fEeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp6ekB4+PjDuDg4DLZ2dlw0NDQuMbGxuy/v7//u7u7+8PDw93Y2Ni58fHxvf39/eD////7//////////////////////////z8/Pzv8/Pz2OPj473Z2dme3d3dbu3t7TgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cC5ubmCeLi4jPY2NiMysrK3b6+vv+7u7v7wcHB4dbW1r7v7+/B/f394f////v//////////////////////////P39/ev09PTO4uLivNPT07XU1NSX4eHhWgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QDs7OwF4+PjMNjY2IzJycnevr6+/7y8vPvDw8Pe19fXu+/v78D9/f3i////+/////////////////////7////y/f391PT09LLg4OCsz8/PwcvLy7jT09N4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6enpAunp6Rfe3t5U0tLSrMbGxuy+vr7/vb29+8XFxd3Y2Ni67+/vwPz8/OL////7////////////////////8P///8X8/PyX7+/vitnZ2anJycnWw8PD1MjIyIoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADn5+cR4eHhRNbW1pHKysrWwsLC+r6+vv+8vLz8xMTE4tfX17/u7u7B/Pz84/////z/////////9v///+H///+2////dvv7+0ro6Ohb1dXVocXFxeO+vr7nwcHBlgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOnp6QHf398E4eHhDeDg4DnY2NiHzc3Nz8PDw/PAwMD/v7+//7y8vPrExMTh19fXv+/v78H9/f3k////+/////P////R////mf///1r///8o+vr6Fujo6DXZ2dmCysrK0MDAwODBwcGWAAAAAAAAAAAAAAAAAAAAAAAAAAD4+PgB7OzsDt/f3ybY2NhL0tLSiMvLy8vDw8P0vr6+/r+/v//BwcH8wMDA6MnJyb7c3Nyj8vLyvv7+/un////w////w////4T///9G////F////wP19fUE7e3tG+Hh4VXW1tabzc3NtM3NzYEAAAAAAAAAAAAAAAAAAAAA/Pz8Aff39wjr6+sq3d3dZNHR0aPIyMjYwsLC8sDAwPPAwMDuw8PD5sbGxtbIyMit1NTUdeXl5Wj39/en////4v///9v///+N////P////xT///8DAAAAAPDw8AHu7u4K6urqJ+Xl5VXg4OBs4ODgUwAAAAAAAAAAAAAAAAAAAAD8/PwF9/f3FOnp6UXZ2dmHzMzMvsPDw9rCwsLYycnJxs/Pz7PS0tKY0tLSdc/Pz0vZ2dkn6urqKfr6+mv///+3////xv///4r///88////DQAAAAAAAAAAAAAAAPDw8AHu7u4I7u7uGe3t7SPu7u4eAAAAAAAAAAAAAAAAAAAAAPz8/Ab19fUV5ubmPNXV1WjKysqCxcXFiMjIyIDT09Nw3t7eW+Hh4Tzc3Nwe0tLSCejo6ADo6OgH+/v7Lv///2z///+L////dv///0L///8QAAAAAAAAAAAAAAAAAAAAAO3t7QDt7e0B7+/vAfLy8gEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP////////////gAA8P4AAPA+AADwPgAA8DwAAfAYAA/wAAAH8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAD/AAAA/wAAAP8AAAA/gAAAP8AAAD/gAAA/4AAAP+AAAD/gAAA/AAAAPgAAADwAABA8AAA4PAAAPD////////////////KAAAABAAAAAgAAAAAQAgAAAAAAAABAAAEwsAABMLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA9fX1BPX19QIAAAAAAAAAAAAAAAD///8A////If///53///+I/Pz8K9XV1UXLy8ts4eHhPvHx8QoAAAAAAAAAAODg4FTl5eU16urqBAAAAAAAAAAA9vb2APX19SP+/v7L////9v39/bTk5OSVy8vLpdzc3E3x8fEIAAAAAAAAAADGxsay0dHRpt/f3yfm5uYC4ODgAeHh4SHa2tph9/f3cP///2r///98+/v7iuvr6y/e3t4E8PDwAAAAAAAAAAAAxMTEsMTExPHNzc2o2traNtjY2CDR0dGPzc3Nx/T09H3///8+////G////2f+/v5W/v7+BAAAAAAAAAAAAAAAANfX14TExMTwwMDA+cfHx9rMzMzBwsLC7svLy9X39/fS////4////47///+D////hP///xQAAAAAAAAAAAAAAADp6ek+y8vLyMDAwP7CwsL/wcHB/sDAwPHT09Ot+vr6yf////3////6////8////53///8WAAAAAAAAAAAAAAAA+vr6Bdvb223ExMTswcHB/8HBwf3MzMy27+/vNf///7v////9//////////3+/v60+vr6JAAAAAAAAAAAAAAAAAAAAADs7OwT0dHRi8LCwvC/v7/9ysrKwOvr60X+/v66/////f///////////Pz80fPz80vv7+8HAAAAAAAAAAAAAAAA8fHxAN/f3xPU1NR6xsbG5b6+vvrQ0NC++fn5zP////3//////////vj4+OLi4uKf5eXlQgAAAAAAAAAAAAAAAAAAAADn5+cB4+PjHM/Pz7W9vb39zMzMzvf399H////9//////////v5+fnQ2dnZt9PT04gAAAAAAAAAAAAAAAAAAAAA5+fnBdzc3FDIyMjavb29/c3Nzc729vbR/////f////X///+49PT0cc7OzsHCwsK3AAAAAAAAAAD4+PgA4+PjDtfX10bLy8vFwMDA/L+/v/fPz8/A+Pj40////+j///+N////J+3t7RrU1NSRxsbGqwAAAAAAAAAA+Pj4CeDg4FfKysrEw8PD4cjIyMfKysqR3d3dS/z8/Kv///+u////J////wHv7+8D6OjoJ+Pj40AAAAAAAAAAAPf39wfb29spx8fHQ83NzTzf398m2traCujo6AL+/v4n////QP///xQAAAAAAAAAAO3t7QDx8fEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wAAnAEAAIwBAACAAQAAgAMAAIADAACAAwAAgAMAAMABAADAAQAA4AEAAOABAACAAQAAgAEAAIAZAAD//wAA'


$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($tmsIconBase64)
$bitmap.EndInit()
$bitmap.Freeze()

$Window.Icon = $bitmap
#endregion

# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #
#----Event Handlers
# ...- --- .. -.. - .... . ...- .. .-.. .-.. .- .. -. #

#region Events
$listProfiles.Add_SelectionChanged({
	$txtSelectedProfile.text = $listProfiles.selectedItem
  $lblSelectedProfile.content = $txtSelectedProfile.text
	$hooks = ''
	$hooksExist = Test-Path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

	if (!$hooksExist -AND $txtSelectedProfile.text -ne '') {
		$hooks = @{
			tms = 'ninja'
		}

		$hooks | convertto-json | set-content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

		write-host "Created tms-ninja hooks.json for profile $($txtSelectedProfile.text)"
	}
	
	if ($txtSelectedProfile.text -ne '') {
		$cpFiles = Get-ChildItem -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams"

		foreach ($cpf in $cpFiles) {
			if ($cpf.Name -eq 'hooks.json') {
				$hooks = Get-Content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($lblSelectedProfile.content)\AppData\Roaming\Microsoft\Teams\hooks.json" | ConvertFrom-Json
			}
		}
	}

	# Write-Host $hooks
	# DEV
	if ($hooks.developerMode -eq $true -AND $hooks.devMenuExtensionsEnabled -eq $true -AND $hooks.forceDebugMenuEnable -eq $true -AND $hooks.debugMenuDisabledV2 -eq $false) {
		$chkDev.IsChecked = $true
	} else {
		$chkDev.IsChecked = $false
	}
	
	# AUTH
	if ($hooks.authHoldUserOnAdal -eq $true -AND $hooks.authMigrationRevertToAdal -eq $true) {
		$cmbAuth.SelectedIndex = $cmbAuth.Items.IndexOf('ADAL')
	} else {
		$cmbAuth.SelectedIndex = $cmbAuth.Items.IndexOf('WAM')
	}

	# RING
	if ($hooks.settingsForWebApp -eq "ring=general" -OR $hooks.settingsForWebApp -eq $null) {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('General')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring3_6") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring3_6')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring3_9") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring3_9')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring0") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring0')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring1") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring1')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring1_5") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring1_5')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring2") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring2')
	} elseif ($hooks.settingsForWebApp -eq "ring=ring3") {
		$cmbRing.SelectedIndex = $cmbRing.Items.IndexOf('Ring3')
	} 
})

$chkDev.Add_Checked({
	write-host 'Dev checked'
	$path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

	if ($txtSelectedProfile.text -eq '') {
		Write-Host 'No profile selected to enable Dev for.'
	} else {
		Write-Host "Enabling Dev for profile $($txtSelectedProfile.text)"
		$hooks = Get-Content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json" | ConvertFrom-Json

		try {
			$hooks.developerMode = $true
			$hooks.devMenuExtensionsEnabled = $true
			$hooks.forceDebugMenuEnable = $true
			$hooks.debugMenuDisabledV2 = $false
		} catch {
			$hooks | Add-Member -MemberType NoteProperty -Name 'developerMode' -Value $true
			$hooks | Add-Member -MemberType NoteProperty -Name 'devMenuExtensionsEnabled' -Value $true
			$hooks | Add-Member -MemberType NoteProperty -Name 'forceDebugMenuEnable' -Value $true
			$hooks | Add-Member -MemberType NoteProperty -Name 'debugMenuDisabledV2' -Value $false
		} finally {
			$hooks | ConvertTo-Json | Set-Content $path
		}
	}
})

$chkDev.Add_UnChecked({
	write-host 'Dev unchecked'

	$path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

	if ($txtSelectedProfile.text -eq '') {
		Write-Host 'No profile selected to disable Dev for.'
	} else {
		Write-Host "Disabling Dev for profile $($txtSelectedProfile.text)"
		$hooks = Get-Content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json" | ConvertFrom-Json

		try {
			$hooks.developerMode = $false
			$hooks.devMenuExtensionsEnabled = $false
			$hooks.forceDebugMenuEnable = $false
			$hooks.debugMenuDisabledV2 = $true
		} catch {
			$hooks | Add-Member -MemberType NoteProperty -Name 'developerMode' -Value $false
			$hooks | Add-Member -MemberType NoteProperty -Name 'devMenuExtensionsEnabled' -Value $false
			$hooks | Add-Member -MemberType NoteProperty -Name 'forceDebugMenuEnable' -Value $false
			$hooks | Add-Member -MemberType NoteProperty -Name 'debugMenuDisabledV2' -Value $true
		} finally {
			$hooks | ConvertTo-Json | Set-Content $path
		}
	}
})

$cmbAuth.Add_SelectionChanged({
	write-host "Auth changed"
	$path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

	if ($txtSelectedProfile.text -eq '') {
		Write-Host 'No profile selected to change auth stack for.'
	} else {
		Write-Host "Changing auth stack to $($cmbAuth.SelectedItem) for profile $($txtSelectedProfile.text)"
		$hooks = Get-Content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json" | ConvertFrom-Json

		if ($cmbAuth.SelectedItem -eq 'WAM') {
			write-host 'wam'

			try {
				$hooks.authHoldUserOnAdal = $false
				$hooks.authMigrationRevertToAdal = $false
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'authHoldUserOnAdal' -Value $false
				$hooks | Add-Member -MemberType NoteProperty -Name 'authMigrationRevertToAdal' -Value $false
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks
		} elseif ($cmbAuth.selectedItem -eq 'ADAL') {
			write-host 'adal'

			try {
				$hooks.authHoldUserOnAdal = $true
				$hooks.authMigrationRevertToAdal = $true
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'authHoldUserOnAdal' -Value $true
				$hooks | Add-Member -MemberType NoteProperty -Name 'authMigrationRevertToAdal' -Value $true
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks
		}
	}
})

$cmbRing.Add_SelectionChanged({
	write-host 'Ring changed'
	$path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json"

	if ($txtSelectedProfile.text -eq '') {
		Write-Host 'No profile selected to change the ring for.'
	} else {
		Write-Host "Changing ring to $($cmbRing.SelectedItem) for profile $($txtSelectedProfile.text)"
		$hooks = Get-Content -path "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams\hooks.json" | ConvertFrom-Json
		
		if ($cmbRing.SelectedItem -eq 'General') {
			write-host 'General'
	
			try {
				$hooks.settingsForWebApp = "ring=general"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=general'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks
		} elseif ($cmbRing.SelectedItem -eq 'Ring3_6') {
			write-host 'Ring3_6'

			try {
				$hooks.settingsForWebApp = "ring=ring3_6"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring3_6'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring3_9') {
			write-host 'Ring3_9'

			try {
				$hooks.settingsForWebApp = "ring=ring3_9"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring3_9'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring0') {
			write-host 'Ring0'

			try {
				$hooks.settingsForWebApp = "ring=ring0"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring0'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring1') {
			write-host 'Ring1'

			try {
				$hooks.settingsForWebApp = "ring=ring1"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring1'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring1_5') {
			write-host 'Ring1_5'

			try {
				$hooks.settingsForWebApp = "ring=ring1_5"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring1_5'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring2') {
			write-host 'Ring2'

			try {
				$hooks.settingsForWebApp = "ring=ring2"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring2'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		} elseif ($cmbRing.SelectedItem -eq 'Ring3') {
			write-host 'Ring3'

			try {
				$hooks.settingsForWebApp = "ring=ring3"
			} catch {
				$hooks | Add-Member -MemberType NoteProperty -Name 'settingsForWebApp' -Value 'ring=ring3'
			} finally {
				$hooks | ConvertTo-Json | Set-Content $path
			}

			write-host $hooks 
		}
	}
})

$btnStart.Add_Click({
  if ($txtSelectedProfile.text -eq "") {
    Write-Host 'No profile selected to start.'
  } else {
    Write-Host "Starting profile $($txtSelectedProfile.text)"
    New-CustomProfile $txtSelectedProfile.text
  } 
})

$btnCache.Add_Click({
  $path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)\AppData\Roaming\Microsoft\Teams"

  if ($txtSelectedProfile.text -eq "") {
    Write-Host 'No profile selected to clear cache.'
  } else {
    gci -path $path | foreach { Remove-Item $_.FullName -Recurse -Force }
    Write-Host "Cleared cache for profile $($txtSelectedProfile.text)"
  } 
})

$btnLocation.Add_Click({
  if ($txtSelectedProfile.text -eq "") {
    Write-Host 'No profile selected to open location.'
  } else {
    Invoke-Item "$($env:localappdata)\Microsoft\Teams\CustomProfiles\$($txtSelectedProfile.text)"
    Write-Host "Location opened for profile $($txtSelectedProfile.text)"
  }
})

$btnDelete.Add_Click({
	write-host 'delete'

	if ($txtSelectedProfile.text -eq "") {
		write-host 'No profile selected to delete.'
	} else {
		$path = "$($env:localappdata)\Microsoft\Teams\CustomProfiles"

		gci -path $path | foreach {
			if ($_.Name -eq $txtSelectedProfile.text) {
				Remove-Item $_.FullName -Recurse -Force
			}
		}

		write-host "Deleted profile $($txtSelectedProfile.text)"
		$listProfiles.Items.Remove($listProfiles.selectedItem)
		$txtSelectedProfile.text = ''

		if (!$listProfiles.Items[0]) {
			write-host 'Deleted all profiles'
			$listProfiles.Items.Add("No custom profiles found. Please create one.")
			$btnStart.IsEnabled = $false
			$btnCache.IsEnabled = $false
			$btnLocation.IsEnabled = $false
			$btnDelete.IsEnabled = $false
			$listProfiles.IsEnabled = $false
			$cmbAuth.IsEnabled = $false
			$cmbRing.IsEnabled = $false
			$chkDev.IsEnabled = $false
		}
	}
})

$btnCreate.Add_Click({
  $profileName = $txtNewProfile.Text

	if ($listProfiles.Items[0] -eq "No custom profiles found. Please create one.") {
		$listProfiles.Items.Clear()
		$btnStart.IsEnabled = $true
		$btnCache.IsEnabled = $true
		$btnLocation.IsEnabled = $true
		$btnDelete.IsEnabled = $true
		$listProfiles.IsEnabled = $true
		$cmbAuth.IsEnabled = $true
		$cmbRing.IsEnabled = $true
		$chkDev.IsEnabled = $true
	}

  if ($profileName -eq "") {
    Write-Host 'No profile name to create profile.'
  } else {
    write-host "Created profile $($txtNewProfile.Text)"
    $listProfiles.Items.Add($profileName)
    New-CustomProfile $profileName
		$txtNewProfile.Text = ''
  }
})
#endregion 

$Window.ShowDialog()