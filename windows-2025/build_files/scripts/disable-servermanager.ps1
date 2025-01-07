Write-Host "Disabling Server Manager startup on logon..."
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Write-Host "Done Disabling Server Manager startup on logon"
