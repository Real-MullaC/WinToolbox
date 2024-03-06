# Check if the current instance is running as administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
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


# Requires -RunAsAdministrator

# Create and start an HttpListener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()

# Load applications from JSON
$jsonPath = "C:\Users\gamin\Documents\GitHub\WinToolbox\apps.json"  # Update this path to where your JSON file is located
$appList = Get-Content $jsonPath | ConvertFrom-Json



$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Checkbox Tabs</title>
    <style>
        /* Basic tab styling */
        .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
        }

        /* Style the buttons inside the tab */
        .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
        }

        /* Change background color of buttons on hover */
        .tab button:hover {
            background-color: #ddd;
        }

        /* Create an active/current tablink class */
        .tab button.active {
            background-color: #ccc;
        }

        /* Style the tab content */
        .tabcontent {
            display: none;
            padding: 6px 12px;
            border: 1px solid #ccc;
            border-top: none;
        }

        /* Style for checkboxes */
        .checkbox-list label {
            margin-right: 10px;
        }
    </style>
</head>
<body>

<div class="tab">
    <button class="tablinks" onclick="openTab(event, 'Tab1')">Store</button>
    <button class="tablinks" onclick="openTab(event, 'Tab2')">Tweaks</button>
    <button class="tablinks" onclick="openTab(event, 'Tab3')">temp</button>
</div>

<div id="Tab1" class="tabcontent">
    <h3>Applications</h3>
    <button type="button" onclick="submitForm('install')">Install</button>
    <button type="button" onclick="submitForm('update')">Update</button>
    <button type="button" onclick="submitForm('uninstall')">Uninstall</button>
    <div class="checkbox-list">
"@

# Dynamically add checkbox inputs for each application
foreach ($app in $appList) {
    $html += "<label title=`"$($app.description)`"><input type='checkbox' value=`"$($app.wingetId)`"> $($app.name)</label><br>"
}

# End of the HTML string
$html += @"
    </div>
</div>

<div id="Tab2" class="tabcontent">
    <h3>Tab 2</h3>
    <div class="checkbox-list">
        <label><input type="checkbox"> Option 4</label>
        <label><input type="checkbox"> Option 5</label>
        <label><input type="checkbox"> Option 6</label>
    </div>
</div>

<div id="Tab3" class="tabcontent">
    <h3>Tab 3</h3>
    <div class="checkbox-list">
        <label><input type="checkbox"> Option 7</label>
        <label><input type="checkbox"> Option 8</label>
        <label><input type="checkbox"> Option 9</label>
    </div>
</div>

<script>
function openTab(evt, tabName) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    document.getElementById(tabName).style.display = "block";
    evt.currentTarget.className += " active";
}

// Click on the first tab by default
document.getElementsByClassName("tablinks")[0].click();

</script>

</body>
</html>
"@




function ToggleSystemTheme {
    # Get current theme setting from the registry
    $currentTheme = Get-ItemPropertyValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme

    # Toggle the theme setting
    $newTheme = if ($currentTheme -eq 1) { 0 } else { 1 }
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value $newTheme
}

# Automatically open the default web browser at the server's URL
Start-Process "http://localhost:8080/"

Write-Host "Listening on http://localhost:8080/ ..."

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    if ($request.Url.LocalPath -eq '/toggle-theme') {
        # Call the function to toggle the system theme
        ToggleSystemTheme
        $response.StatusCode = 200
    } else {
        # Serve the HTML content
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }

    $response.OutputStream.Close()
}

$listener.Stop()
