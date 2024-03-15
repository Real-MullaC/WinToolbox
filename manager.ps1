# Check if the current instance is running as administrator
$currentPid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = new-object System.Security.Principal.WindowsPrincipal($currentPid)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator


if ($principal.IsInRole($adminRole))
{
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Admin)"
    clear-host
}
else
{
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    break
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
Write-Host ""
Write-Host "=====Powershell Toolbox====="
Write-Host "=======Managing Device======"
Write-Host ""
Write-Host ""


# Check the system's theme from the registry
$theme = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme'
if ($theme.AppsUseLightTheme -eq 1) {
    $isLightTheme = $true
    $backgroundColor = "White" 
    $textColor = "Black" 
    $accentColor = "Blue"
} else {
    $isLightTheme = $false
    $backgroundColor = "#White" 
    $textColor = "Black" 
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
            <TabItem Header="Windows">
                <!-- Nested TabControl for the three new tabs -->
                <TabControl>
                    <TabItem Header="Applications">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="appspanel">
                                <!-- Apps --> 
                            </StackPanel>
                        </ScrollViewer>
                    </TabItem>
                    <TabItem Header="Tweaks">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="tweakspanel">
                                <!-- Apps -->
                            </StackPanel>
                        </ScrollViewer>
                    </TabItem>
                </TabControl>
            </TabItem>
            <TabItem Header="Sources">
                <StackPanel Margin="10">
                    <DockPanel LastChildFill="False">
                        <TextBox Name="txtNewSource" DockPanel.Dock="Left" Width="200" Margin="0,0,5,10"/>
                        <ComboBox Name="cmbSourceType" Width="120" Margin="0,0,5,10">
                            <ComboBoxItem Content="Application"/>
                            <ComboBoxItem Content="Tweak"/>
                        </ComboBox>
                        <Button Name="btnAddSource" Content="Add" Width="75" Margin="5,0,0,10"/>
                    </DockPanel>
                    <TextBlock Margin="0,20,0,0" FontWeight="Bold">Current Sources:</TextBlock>
                    <ScrollViewer VerticalScrollBarVisibility="Visible">
                        <StackPanel Name="panelSources" />
                    </ScrollViewer>
                    <Button Name="btnDeleteSource" Content="Delete Source" Margin="10"/>
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
$txtNewSource = $window.FindName("txtNewSource")
$cmbSourceType = $window.FindName("cmbSourceType")
$btnAddSource = $window.FindName("btnAddSource")
$lstSources = $window.FindName("lstSources")
$panelSources = $window.FindName("panelSources")
$btnDeleteSource = $window.FindName("btnDeleteSource")
$btnAddSource.Add_Click({ Add-Source })
$btnDeleteSource.Add_Click({ Remove-Source })
$btnAdd.Add_Click({ Add-Device })
$btnRemove.Add_Click({ Remove-Device })

$jsonUrls = @(
    "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/applications.json"
    #"https://raw.githubusercontent.com/MyDrift-user/WinToolbox/main/apps.json"
)


$configPath = "C:\Windows\WinToolBox.config"
if (Test-Path $configPath) {
    $savedSourceEntries = Get-Content $configPath
    foreach ($entry in $savedSourceEntries) {
        $lstSources.Items.Add($entry)
    }
}



# Initialize a hashtable to store applications by category
$appsByCategory = @{}

# Iterate over the URLs and fetch JSON content from each
foreach ($jsonUrl in $jsonUrls) {
    $jsonContent = Invoke-WebRequest -Uri $jsonUrl -UseBasicParsing | ConvertFrom-Json

    # Organize applications by category
    foreach ($app in $jsonContent.PSObject.Properties) {
        $category = $app.Value.category
        if (-not $category) {
            $category = "Uncategorized" # Assign a default category if null or empty
        }

        if (-not $appsByCategory.ContainsKey($category)) {
            $appsByCategory[$category] = @()
        }
        $appsByCategory[$category] += $app
    }
}

# Correct XML manipulation
$appspanel = $window.FindName("appspanel")



# Clear existing items in appspanel to avoid duplicates
$appspanel.Children.Clear()

# Populate the appspanel with categories and their applications, each in an Expander
foreach ($category in $appsByCategory.Keys) {
    $expander = New-Object System.Windows.Controls.Expander
    $expander.Header = $category
    $expander.IsExpanded = $true

    $stackPanel = New-Object System.Windows.Controls.StackPanel

    # Add application checkboxes under this category
    foreach ($app in $appsByCategory[$category]) {
        $checkBox = New-Object System.Windows.Controls.CheckBox

        # Create a StackPanel to hold the text and the hyperlink
        $innerStackPanel = New-Object System.Windows.Controls.StackPanel
        $innerStackPanel.Orientation = "Horizontal"

        # Create a TextBlock for the app's content
        $textBlock = New-Object System.Windows.Controls.TextBlock
        $textBlock.Text = $app.Value.content

        # Add the TextBlock to the inner StackPanel
        $innerStackPanel.Children.Add($textBlock)

        # Optional: Add a Hyperlink to the TextBlock if needed

        # Add ToolTip if needed
        $toolTip = New-Object System.Windows.Controls.ToolTip
        $toolTip.Content = $app.Value.description
        $checkBox.ToolTip = $toolTip

        $checkBox.Content = $innerStackPanel
        $checkBox.Margin = New-Object System.Windows.Thickness(5)
        $stackPanel.Children.Add($checkBox)

                # Create the hyperlink
        $hyperlink = New-Object System.Windows.Documents.Hyperlink
        $hyperlink.Inlines.Add(" ?")
        $hyperlink.NavigateUri = New-Object System.Uri($app.Value.link)

        # Attach an event handler to the hyperlink
        $hyperlink.Add_RequestNavigate({
            param($sender, $e)
            Start-Process $e.Uri.AbsoluteUri
        })
        
        # Add the Hyperlink to the TextBlock
        $textBlock.Inlines.Add($hyperlink)

        # Remove the underline from the hyperlink
        $hyperlink.TextDecorations = $null
    }

    $expander.Content = $stackPanel
    $appspanel.Children.Add($expander)
}


# Window-level event handler for hyperlink clicks
$window.Add_PreviewMouseLeftButtonDown({
    $pos = [Windows.Input.Mouse]::GetPosition($window)
    $hitTestResult = [Windows.Media.VisualTreeHelper]::HitTest($window, $pos)

    if ($hitTestResult -and $hitTestResult.VisualHit -is [System.Windows.Documents.Hyperlink]) {
        $hyperlink = $hitTestResult.VisualHit
        if ($hyperlink.NavigateUri) {
            Start-Process $hyperlink.NavigateUri.AbsoluteUri
        }
    }
})


function Add-Source {
    $newSource = $txtNewSource.Text
    if (-not $newSource) { return }  # Check if the new source is not empty

    # Add the new source to the configuration file
    Add-Content -Path "C:\Windows\WinToolBox.config" -Value $newSource

    # Create a new CheckBox for the new source
    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.Content = $newSource
    $checkbox.Margin = New-Object System.Windows.Thickness(5)

    # Add the CheckBox to the StackPanel for sources
    $panelSources.Children.Add($checkbox)

    # Clear the input field after adding the source
    $txtNewSource.Text = ""
}






function Remove-Source {
    # Create an array to hold sources that will remain
    $remainingSources = @()

    # Iterate backwards through the StackPanel children because we'll be modifying the collection
    for ($i = $panelSources.Children.Count - 1; $i -ge 0; $i--) {
        $item = $panelSources.Children[$i]
        if ($item.IsChecked) {
            # If the item is checked, remove it from the StackPanel
            $panelSources.Children.RemoveAt($i)
        } else {
            # If not checked, this source should remain in the configuration file
            $remainingSources += $item.Content
        }
    }

    # Update the configuration file with remaining sources
    Set-Content -Path "C:\Windows\WinToolBox.config" -Value $remainingSources
}





# Device management functions
function Add-Device {
    $hostname = $txtHostname.Text
    if (-not $hostname) { return }
    if (-not (Test-Connection $hostname -Quiet -Count 1)) { return }

    if (-not (Test-WSMan -ComputerName $hostname)) {
        Write-Host "PowerShell remoting is not enabled on $hostname." 
        return
    }


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

$btnRun.Add_Click({
    # Collect the selected devices
    $selectedDevices = @()
    foreach ($deviceCheckBox in $panelDevices.Children) {
        if ($deviceCheckBox.IsChecked -eq $true) {
            $selectedDevices += $deviceCheckBox.Content
        }
    }
    Write-Host "Selected devices: $selectedDevices"
})


# Add the current device to the list of devices
$checkbox = New-Object System.Windows.Controls.CheckBox
$checkbox.Content = $env:COMPUTERNAME
$checkbox.Margin = New-Object System.Windows.Thickness(5)
$panelDevices.Children.Add($checkbox)
Write-Host "Connected with: $env:COMPUTERNAME"



# Show the GUI
$window.ShowDialog() | Out-Null
