# WinToolbox

This utility is a Toolbox that should helps me every day. The Plan is to Download my everyday applications and tweak the most important settings on my windows machines fast & at one place.

## Launch Command (not working rn)

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
irm https://raw.githubusercontent.com/mydrift-user/wintoolbox/main/manager.ps1 | iex
```

## Issue:

- Windows Security (formerly Defender) and other anti-virus software are known to block the script. The script gets flagged due to the fact that it requires administrator privileges & makes drastic system changes.


- Sources Are not being applied and window looks ugly

- Add Device & connecting are not working (kind of)

- Applications can't be installed rn


## Plans

- Dynamically add device that have Powershell remote sessions enabled

- check the ones you want to run the stuff on

- install all essential apps at one place

- Tweak your system and Debloat annoying stuff


### Contribute

If you have suggestions, give it a try!
