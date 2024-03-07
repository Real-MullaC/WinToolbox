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
    $backgroundColor = "#1e1e1e" # Dark mode background color, using a common dark theme color
    $textColor = "White" # Dark mode text color
    $accentColor = "Blue"
}

# Load WPF and XAML libraries
Add-Type -AssemblyName PresentationFramework

# WPF GUI Design
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PowerShell Remote Manager" Height="450" Width="800">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*" />
            <ColumnDefinition Width="2*" />
        </Grid.ColumnDefinitions>
        
        <StackPanel Grid.Column="0" Margin="10">
            <TextBox Name="txtHostname" />
            <Button Name="btnAdd" Content="Add" />
            <Button Name="btnRemove" Content="Remove" />
            <ListBox Name="listDevices" />
        </StackPanel>

        <TabControl Grid.Column="1" Margin="10">
            <TabItem Header="Options">
                <StackPanel>
                    <CheckBox Name="chkOption1" Content="Option 1" />
                    <CheckBox Name="chkOption2" Content="Option 2" />
                    <!-- Add more options as needed -->
                    <Button Name="btnRun" Content="Run" />
                </StackPanel>
            </TabItem>
            <!-- Add more tabs if needed -->
        </TabControl>
    </Grid>
</Window>
"@

# Parse the XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)


# Set the background color of the window
$window.Background = [System.Windows.Media.Brushes]::$backgroundColor  # Example, replace with actual logic to use theme color

# For other elements, access them by name and set their properties similarly
$txtHostname.Background = [System.Windows.Media.Brushes]::White  # Example

# Access the controls
$txtHostname = $window.FindName("txtHostname")
$btnAdd = $window.FindName("btnAdd")
$btnRemove = $window.FindName("btnRemove")
$listDevices = $window.FindName("listDevices")
$chkOption1 = $window.FindName("chkOption1")
$chkOption2 = $window.FindName("chkOption2")
$btnRun = $window.FindName("btnRun")

$listDevices.Items.Add($env:COMPUTERNAME)
Write-Host "Connected with: {$env:COMPUTERNAME}"

# Device Management Functions
function Add-Device {
    $hostname = $txtHostname.Text
    if (-not $hostname) {
        #[System.Windows.MessageBox]::Show("Please enter a hostname.")
        return
    }

    if ($hostname = $env:COMPUTERNAME) {
        #[System.Windows.MessageBox]::Show("Please enter a hostname.")
        return
    }

    # Check if the hostname is reachable
    if (-not (Test-Connection $hostname -Quiet -Count 1)) {
        [System.Windows.MessageBox]::Show("Hostname is not reachable.")
        return
    }


    $portCheck = Test-NetConnection -ComputerName $hostname -Port 8080
    if (-not $portCheck.TcpTestSucceeded) {
        [System.Windows.MessageBox]::Show("run start.ps1 first")
        return
    }

    # Add the device to the list if all checks pass
    $listDevices.Items.Add($hostname)
}

function Remove-Device {
    if ($listDevices.SelectedItem -ne $null) {
        $listDevices.Items.Remove($listDevices.SelectedItem)
    } else {
        [System.Windows.MessageBox]::Show("Please select a device to remove.")
    }
}

# Event Handlers
$btnAdd.Add_Click({
    Add-Device
})

$btnRemove.Add_Click({
    Remove-Device
})

$btnRun.Add_Click({
    # Iterate through the checked devices and options to perform selected actions
    # Implement the logic based on selected options and devices
    [System.Windows.MessageBox]::Show("Run action not implemented yet.")
})

# Show the GUI
$window.ShowDialog() | Out-Null

