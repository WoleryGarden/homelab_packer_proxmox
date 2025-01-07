Write-Host "Enabling File and Printer Sharing..."
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
Write-Host "Done Enabling File and Printer Sharing"
