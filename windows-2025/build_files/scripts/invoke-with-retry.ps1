# Dot-sourced by the provisioning scripts that download from the internet. Packer uploads it to
# C:\Windows\Temp before they run, and removes it again before sysprep.

# Runs $ScriptBlock, retrying if it fails. The downloads run after an hour or more of Windows
# updates, so ride out a DNS or network blip rather than throwing the whole build away
function Invoke-WithRetry {
  param(
    [Parameter(Mandatory)] [string] $Activity,
    [Parameter(Mandatory)] [scriptblock] $ScriptBlock,
    [int] $Attempts = 10,
    [int] $DelaySeconds = 30
  )

  # Turn every error inside $ScriptBlock into an exception, so it can be caught and retried
  $ErrorActionPreference = "Stop"

  for ($i = 1; $i -le $Attempts; $i++) {
    try {
      & $ScriptBlock
      return
    }
    catch {
      Write-Host "$Activity, attempt $i of $Attempts failed: $($_.Exception.Message)"
      if ($i -eq 1) {
        # Capture the network state at the first failure, so the cause is visible even if a retry succeeds
        ipconfig /all | Out-String | Write-Host
      }
      if ($i -eq $Attempts) {
        throw
      }
      Start-Sleep -Seconds $DelaySeconds
    }
  }
}
