# Check if the current instance is running as administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch the script with administrator rights
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}


Write-Host ""
Write-Host "MMMMMMMM               MMMMMMMM    DDDDDDDDDDDDDD        "
Write-Host "M:::::::M             M:::::::M    D:::::::::::::DDD     "
Write-Host "M::::::::M           M::::::::M    D::::::::::::::::DD   "
Write-Host "M:::::::::M         M:::::::::M    DDD:::::DDDDD::::::D  "
Write-Host "M::::::::::M       M::::::::::M       D:::::D   D::::::D "
Write-Host "M:::::::::::M     M:::::::::::M       D:::::D    D::::::D"
Write-Host "M:::::::M::::M   M::::M:::::::M       D:::::D     D::::::D"
Write-Host "M::::::M M::::M M::::M M::::::M       D:::::D     D::::::D"
Write-Host "M::::::M  M::::M::::M  M::::::M       D:::::D     D::::::D"
Write-Host "M::::::M   M:::::::M   M::::::M       D:::::D     D::::::D"
Write-Host "M::::::M    M:::::M    M::::::M       D:::::D    D::::::D"
Write-Host "M::::::M     MMMMM     M::::::M       D:::::D   D::::::D "
Write-Host "M::::::M               M::::::M    DDD:::::DDDDD::::::D  "
Write-Host "M::::::M               M::::::M    D::::::::::::::::DD   "
Write-Host "M::::::M               M::::::M    D:::::::::::::DDD     "
Write-Host "MMMMMMMM               MMMMMMMM    DDDDDDDDDDDDDD        "

Write-Host ""
Write-Host "========Mattia Diana========"
Write-Host "=====Powershell Toolbox====="



# Check the system's theme from the registry
$theme = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme'
if ($theme.AppsUseLightTheme -eq 1) {
    $isLightTheme = $true
    $backgroundColor = "White" # Light mode background color
    $textColor = "Black" # Dark mode text color
    $accentColor = "Blue"
} else {
    $isLightTheme = $false
    $backgroundColor = "#2D2D30" # Dark mode background color, using a common dark theme color
    $textColor = "White" # Dark mode text color
    $accentColor = "Blue"
}

# Load WPF and XAML libraries
Add-Type -AssemblyName PresentationFramework


# WPF GUI Design in XAML
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell Remote Manager" Height="450" Width="800">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*" />
            <ColumnDefinition Width="2*" />
        </Grid.ColumnDefinitions>
        
        <Grid Grid.Column="0">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" /> <!-- For static controls: TextBox and Buttons -->
                <RowDefinition Height="*" /> <!-- For ScrollViewer, will take up remaining space -->
            </Grid.RowDefinitions>

            <StackPanel Grid.Row="0" Margin="10">
                <TextBox Name="txtHostname" />
                <Button Name="btnAdd" Content="Add" />
                <Button Name="btnRemove" Content="Remove" />
            </StackPanel>

            <!-- ScrollViewer in a separate row, taking up the remaining space -->
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Visible">
                <StackPanel Name="panelDevices" />
            </ScrollViewer>
        </Grid>



        <TabControl Grid.Column="1" Margin="10">
            <TabItem Header="Options">
                <StackPanel>
                    <CheckBox Name="chkOption1" Content="Option 1" />
                    <CheckBox Name="chkOption2" Content="Option 2" />
                    <Button Name="btnRun" Content="Run" />
                </StackPanel>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# Parse the XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Access controls from the parsed XAML
$txtHostname = $window.FindName("txtHostname")
$btnAdd = $window.FindName("btnAdd")
$btnRemove = $window.FindName("btnRemove")
$panelDevices = $window.FindName("panelDevices")
$btnRun = $window.FindName("btnRun")




# Set window background
$window.Background = [System.Windows.Media.Brushes]::$backgroundColor

# Update controls' colors
$txtHostname.Background = [System.Windows.Media.Brushes]::$backgroundColor
$txtHostname.Foreground = [System.Windows.Media.Brushes]::$textColor

$btnAdd.Background = [System.Windows.Media.Brushes]::$accentColor
$btnAdd.Foreground = [System.Windows.Media.Brushes]::$textColor

$btnRemove.Background = [System.Windows.Media.Brushes]::$accentColor
$btnRemove.Foreground = [System.Windows.Media.Brushes]::$textColor

$listDevices.Background = [System.Windows.Media.Brushes]::$backgroundColor
$listDevices.Foreground = [System.Windows.Media.Brushes]::$textColor

$chkOption1.Foreground = [System.Windows.Media.Brushes]::$textColor
$chkOption2.Foreground = [System.Windows.Media.Brushes]::$textColor

$btnRun.Background = [System.Windows.Media.Brushes]::$accentColor
$btnRun.Foreground = [System.Windows.Media.Brushes]::$textColor








# Device management functions
function Add-Device {
    $hostname = $txtHostname.Text
    if (-not $hostname) { return }
    if (-not (Test-Connection $hostname -Quiet -Count 1)) { return }

    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.Content = $hostname
    $checkbox.Margin = New-Object System.Windows.Thickness(5)
    $panelDevices.Children.Add($checkbox)
}

function Remove-Device {
    $selectedDevices = $panelDevices.Children | Where-Object { $_.IsChecked -eq $true }
    foreach ($device in $selectedDevices) {
        $panelDevices.Children.Remove($device)
    }
}

# Event handlers
$btnAdd.Add_Click({ Add-Device })
$btnRemove.Add_Click({ Remove-Device })
$btnRun.Add_Click({
    $selectedDevices = @()
    foreach ($deviceCheckBox in $panelDevices.Children) {
        if ($deviceCheckBox.IsChecked -eq $true) {
            $selectedDevices += $deviceCheckBox.Content
        }
    }
    foreach ($hostname in $selectedDevices) {
        Write-Host "Selected device: $hostname"
        # Implement the desired actions here
    }
    [System.Windows.MessageBox]::Show("Actions have been performed on the selected devices.")
})




$listDevices.Items.Add($env:COMPUTERNAME)
Write-Host "Connected with: {$env:COMPUTERNAME}"







# Show the GUI
$window.ShowDialog() | Out-Null