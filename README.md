# WinToolbox

This utility is a Toolbox that helps me every day. I Download my everyday applications and tweak the most important settings on my windows machines using ShellUtil.

## Usage

Shellutil has to run with administrative privileges, to achieve this, open PowerShell or Windows Terminal as an administrator and run the launch-command.

### Launch Command

#### Simple way

```
irm https://mdiana.dev/win | iex
```
or: 
```
iwr -useb https://mdiana.dev/win | iex
```

if for some reason the website is not accessible, use the following command:

```
irm https://raw.githubusercontent.com/mydrift-user/wintoolbox/main/start.ps1 | iex
```

## Issue:

- Windows Security (formerly Defender) and other anti-virus software are known to block the script. The script gets flagged due to the fact that it requires administrator privileges & makes drastic system changes.