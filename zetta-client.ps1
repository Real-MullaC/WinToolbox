if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If not elevated, relaunch the script in a new elevated PowerShell session
    $escapedCommand = 'irm mdiana.dev/zetta | iex'
    Start-Process PowerShell -ArgumentList "-Command", $escapedCommand -Verb RunAs
    exit
}

function Set-Wallpaper {
    param (
        [string]$wallpaperPath
    )

    # Set the wallpaper path in the registry
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name Wallpaper -Value $wallpaperPath

    # Use SystemParametersInfo to update the wallpaper
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@

    # SPI_SETDESKWALLPAPER = 0x14
    # SPIF_UPDATEINIFILE = 0x01
    # SPIF_SENDWININICHANGE = 0x02
    $SPI_SETDESKWALLPAPER = 0x14
    $SPIF_UPDATEINIFILE = 0x01
    $SPIF_SENDWININICHANGE = 0x02

    # Call the SystemParametersInfo function to set the new wallpaper
    [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $wallpaperPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)
}

# Function to Pin or Unpin apps from the taskbar
function Set-TaskbarShortcut {
    param (
        [string]$action,  # "pin" or "unpin"
        [string]$appName  # App Name
    )

    $shell = New-Object -ComObject Shell.Application
    $folderPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    $folder = $shell.Namespace($folderPath)
    $items = $folder.Items()

    foreach ($item in $items) {
        if ($item.Name -like "*$appName*") {
            if ($action -eq "unpin") {
                $item.InvokeVerb('Unpin from taskbar')
            } elseif ($action -eq "pin") {
                $item.InvokeVerb('Pin to taskbar')
            }
        }
    }
}


function Set-Phase {
    $directoryPath = "C:\ZETTA"
    if (-Not (Test-Path $directoryPath)) {
        New-Item -Path $directoryPath -ItemType Directory | Out-Null
    }

    $phaseFilePath = Join-Path -Path $directoryPath -ChildPath "phase.json"

    # Define the initial JSON content with phase value set to 1
    $jsonContent = @{ "phase" = 1 }

    # Convert the hashtable to a JSON string and write it safely
    $jsonContent | ConvertTo-Json | Set-Content -Path $phaseFilePath -Force
}

function Update-Phase ($newPhase) {
    $directoryPath = "C:\ZETTA"
    $phaseFilePath = Join-Path -Path $directoryPath -ChildPath "phase.json"

    if (Test-Path $phaseFilePath) {
        try {
            $jsonContent = Get-Content -Path $phaseFilePath -Raw | ConvertFrom-Json
            $jsonContent.phase = $newPhase
            $jsonContent | ConvertTo-Json | Set-Content -Path $phaseFilePath -Force
        } catch {
            Write-Host "Failed to update phase file: $_"
        }
    } else {
        Write-Host "Phase file does not exist, creating new."
        $jsonContent = @{ "phase" = $newPhase }
        $jsonContent | ConvertTo-Json | Set-Content -Path $phaseFilePath -Force
    }
}


Set-Phase

$ScriptPath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Clientmanager.ps1"

$ScriptContent = @"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If not elevated, relaunch the script in a new elevated PowerShell session
    $escapedCommand = 'irm mdiana.dev/zetta | iex'
    Start-Process PowerShell -ArgumentList "-Command", $escapedCommand -Verb RunAs
    exit
}

# Define the file path
$filePath = "C:\ZETTA\phase.json"

# Check if the file exists
if (Test-Path $filePath) {
    # Read the JSON file content
    $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json

    # Use a switch statement to handle different phase values
    switch ($jsonContent.phase) {
        1 {
            Set-Wallpaper -wallpaperPath "C:\Windows\Web\ZETTA\zetta.png"

            Write-Host "Phase 1 detected: Initialization phase."
            # Define the path to the Dell Command Update directory
            $dcuPath = "C:\Program Files\Dell\CommandUpdate"

            # Change directory to DCU path
            Set-Location -Path $dcuPath

            # Define each command to execute
            $commands = @(
                "dcu-cli /version",
                "dcu-cli /scan",
                "dcu-cli /applyUpdates"
            )

            # Execute each command in the command prompt
            foreach ($command in $commands) {
                Start-Process cmd.exe -ArgumentList "/c $command" -NoNewWindow -Wait
            }
            Write-Host "All updates have been applied. The system will now automatically restart."

            Update-Phase 2

            # Get updates and install them, if available
            $Updates = Get-WindowsUpdate -AcceptAll -Install

            # Check if updates were installed
            if ($Updates.IsInstalled -contains $true) {
                # If updates were installed, the system will auto reboot if you include -AutoReboot in the Get-WindowsUpdate command
                Write-Host "Updates installed, system will reboot automatically."
            } else {
                # If no updates were installed, reboot the system manually
                Write-Host "No updates installed, initiating reboot."
                Restart-Computer
            }
        }
        2 {
            Write-Host "Phase 2 detected: Configuration phase."
            # Check if Chrome is installed by querying the registry
            $chromeInstalled = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                            Where-Object { $_.DisplayName -like '*Google Chrome*' }

            if (-Not $chromeInstalled) {
                # Chrome is not installed, proceed with download and installation
                Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:USERPROFILE\Downloads\chrome_installer.exe"
                Start-Process -FilePath "$env:USERPROFILE\Downloads\chrome_installer.exe" -Args "/silent /install" -Verb RunAs -Wait
                Remove-Item -Path "$env:USERPROFILE\Downloads\chrome_installer.exe"
            } else {
                # Chrome is already installed, output a message
                Write-Output "Google Chrome is already installed on this system."
            }

            # Unpin Microsoft Store from the Taskbar
            Set-TaskbarShortcut -action "unpin" -appName "Store"

            # Pin Google Chrome to the Taskbar
            Set-TaskbarShortcut -action "pin" -appName "Chrome"

            # Pin Microsoft Word to the Taskbar
            Set-TaskbarShortcut -action "pin" -appName "Word"

            # Pin Microsoft Excel to the Taskbar
            Set-TaskbarShortcut -action "pin" -appName "Excel"

            Write-Host "Taskbar icons updated!"

            #uninstall some apps
            $apps = @("LinkedIn", "Alarm & Uhr", "Camo Studio", "Spotify", "Xbox", "Outlook (new)", "Film & Video", "Feedback-Hub", "Microsoft Solitaire Collection", "Microsoft News", "Microsoft To-Do", "Microsoft Whiteboard", "Microsoft Sticky Notes", "Microsoft Paint 3D")
            foreach ($app in $apps) {
                Get-AppxPackage -Name $app | Remove-AppxPackage
            }

            # end explorer, replace start menu file & start explorer
            Stop-Process -Name explorer -Force
            Copy-Item -Path "C:\ZETTA\startmenu.xml" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\startmenu.xml"
            Start-Process explorer
        }

        Update-Phase 3

        Restart-Computer -Force

        3 {
            Write-Host "Phase 3 detected: Completion phase."
            # remove the phase file
            Remove-Item -Path $filePath

            # Remove Script from Startup
            $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $ScriptPath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Clientmanager.ps1"
            Remove-Item -Path $ScriptPath -Force
        }
        default {
            Write-Host "Unexpected phase value $($jsonContent.phase). It must be 1, 2, or 3."
        }
    }
} else {
    Write-Host "File $filePath does not exist."
}

"@
Set-Content -Path $ScriptPath -Value $ScriptContent

Install-Module -Name PSWindowsUpdate
# Get updates and install them, if available
$Updates = Get-WindowsUpdate -AcceptAll -Install

# Check if updates were installed
if ($Updates.IsInstalled -contains $true) {
    # If updates were installed, the system will auto reboot if you include -AutoReboot in the Get-WindowsUpdate command
    Write-Host "Updates installed, system will reboot automatically."
} else {
    # If no updates were installed, reboot the system manually
    Write-Host "No updates installed, initiating reboot."
    Restart-Computer
}