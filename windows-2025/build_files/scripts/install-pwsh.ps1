Write-Host "Installing PowerShell..."
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
"Done installing PowerShell." | Write-Host
