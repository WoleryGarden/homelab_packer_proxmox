Write-Host "Installing telnet..."
# Install-WindowsFeature -name Telnet-Client
dism /online /Enable-Feature /FeatureName:TelnetClient
# pkgmgr /iu:"TelnetClient"
"Done installing telnet." | Write-Host
