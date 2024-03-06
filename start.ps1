# Check if the current instance is running as administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Relaunch the script with administrator rights
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}

# PowerShell GUI
Add-Type -AssemblyName PresentationFramework

$window = New-Object Windows.Window
$window.Title = "WinToolbox"
$window.Width = 300
$window.Height = 200

$label = New-Object Windows.Controls.Label
$label.Content = "WinToolbox"
$label.HorizontalAlignment = 'Center'
$label.VerticalAlignment = 'Center'

$window.Content = $label
$window.ShowDialog()
