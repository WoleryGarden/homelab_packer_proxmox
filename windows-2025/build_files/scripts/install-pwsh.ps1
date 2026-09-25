. C:\Windows\Temp\invoke-with-retry.ps1

Write-Host "Installing PowerShell..."
Invoke-WithRetry "Installing PowerShell" {
  iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
}
"Done installing PowerShell." | Write-Host
