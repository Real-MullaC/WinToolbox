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

# Access the controls
$txtHostname = $window.FindName("txtHostname")
$btnAdd = $window.FindName("btnAdd")
$btnRemove = $window.FindName("btnRemove")
$listDevices = $window.FindName("listDevices")
$chkOption1 = $window.FindName("chkOption1")
$chkOption2 = $window.FindName("chkOption2")
$btnRun = $window.FindName("btnRun")

# Device Management Functions
function Add-Device {
    $hostname = $txtHostname.Text
    if (-not $hostname) {
        [System.Windows.MessageBox]::Show("Please enter a hostname.")
        return
    }

    # Check if the hostname is reachable
    if (-not (Test-Connection $hostname -Quiet -Count 1)) {
        [System.Windows.MessageBox]::Show("Hostname is not reachable.")
        return
    }

    # Check if the device is running Windows 10/11
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $hostname | Select-Object -ExpandProperty Caption
        if ($os -notlike "*Windows 10*" -and $os -notlike "*Windows 11*") {
            [System.Windows.MessageBox]::Show("The device is not running Windows 10/11.")
            return
        }
    } catch {
        [System.Windows.MessageBox]::Show("Failed to retrieve OS information. Make sure you have the necessary permissions.")
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