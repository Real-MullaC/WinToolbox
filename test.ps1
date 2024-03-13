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
                    <TextBlock Margin="10,20,0,0" FontWeight="Bold">Current Sources:</TextBlock>
                    <ListBox Name="lstSources" />
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
$btnDeleteSource = $window.FindName("btnDeleteSource")



$jsonUrls = @(
    "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/applications.json",
    "https://raw.githubusercontent.com/MyDrift-user/WinToolbox/main/apps.json"
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
    $selectedType = $cmbSourceType.SelectedItem.Content
    if (-not $newSource -or -not $selectedType) { return }

    # Create a combined string that includes the type and the source URL
    $sourceEntry = "$newSource"

    # Add the new source entry to the list in the UI under the correct group
    $lstSources.Items.Add($sourceEntry)

    # Write the new source entry to the config file
    Add-Content -Path "C:\Windows\WinToolBox.config" -Value $sourceEntry
}

# Bind the Add-Source function to the Add Source button click event
$btnAddSource.Add_Click({ Add-Source })


function Delete-Source {
    $selectedItem = $lstSources.SelectedItem
    if ($selectedItem -eq $null) { return }

    # Remove the selected item from the list in the UI
    $lstSources.Items.Remove($selectedItem)

    # Rebuild the source list excluding the deleted item
    $updatedSources = @()
    foreach ($item in $lstSources.Items) {
        $updatedSources += $item
    }

    # Overwrite the config file with the updated list
    Set-Content -Path "C:\Windows\WinToolBox.config" -Value $updatedSources
}

# Bind the Delete-Source function to the Delete button click event
$btnDeleteSource.Add_Click({ Delete-Source })



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

# Event handlers
$btnAdd.Add_Click({ Add-Device })
$btnRemove.Add_Click({ Remove-Device })

$btnRun.Add_Click({
    # Collect the selected devices
    $selectedDevices = @()
    foreach ($deviceCheckBox in $panelDevices.Children) {
        if ($deviceCheckBox.IsChecked -eq $true) {
            $selectedDevices += $deviceCheckBox.Content
        }
    }

    # Invoke the command on the selected devices
    Invoke-Command -ComputerName $selectedDevices -ScriptBlock {
        Try {
        $wingetVersion = winget --version
        Write-Host "winget is installed."
        Write-Host "Version: $wingetVersion"
        write-host ""
    } Catch {
        Write-Host "winget is not installed."

        $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
                Select-Object -ExpandProperty "assets" |
                Where-Object "browser_download_url" -Match '.msixbundle' |
                Select-Object -ExpandProperty "browser_download_url"

        Invoke-WebRequest -Uri $URL -OutFile "Setup.msix" -UseBasicParsing
        Add-AppxPackage -Path "Setup.msix"
        Remove-Item "Setup.msix"
    }


    Try {
        $chocoversion = choco -v
        Write-Host "chocolatey is installed."
        write-host "Version: $chocoversion"
        write-host ""
    } Catch {
        Write-Host "chocolatey is not installed."

        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    }
})

$checkbox = New-Object System.Windows.Controls.CheckBox
$checkbox.Content = $env:COMPUTERNAME
$checkbox.Margin = New-Object System.Windows.Thickness(5)
$panelDevices.Children.Add($checkbox)
Write-Host "Connected with: $env:COMPUTERNAME"







# Show the GUI
$window.ShowDialog() | Out-Null