#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

# ====================== CONFIG ======================

# This should match the Packer 'vm_name'
$vmName = "template-debian-12"

# ================== Helper Functions =================

function Test-ProcessHasScriptGroupId {
    param(
        [Parameter(Mandatory = $true)]
        [int] $targetPid,

        [Parameter(Mandatory = $true)]
        [string] $ExpectedValue
    )

    $procDir = "/proc/$targetPid"

    # /proc/<pid> must exist
    if (-not (Test-Path -LiteralPath $procDir)) {
        Write-Warning "Path '$procDir' does not exist"
        return $false
    }

    # Only consider processes owned by the same UID
    try {
        $procUid = (& stat -c '%u' $procDir 2>$null).Trim()
    }
    catch {
        Write-Warning "Failed getting UID from '$procDir'"
        return $false
    }

    if ($procUid -ne $currentUid) {
        return $false
    }

    # Read /proc/<pid>/environ (null-separated environment)
    $environPath = "$procDir/environ"
    if (-not (Test-Path -LiteralPath $environPath)) {
        Write-Warning "Path '$environPath' does not exist"
        return $false
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($environPath)
    }
    catch {
        Write-Warning "Could not read '$environPath'"
        # Often not readable for other users / special processes; just skip
        return $false
    }

    if ($bytes.Length -eq 0) {
        return $false
    }

    $envString = [System.Text.Encoding]::UTF8.GetString($bytes)
    $entries = $envString -split "`0"

    # Look for exact "SCRIPT_GROUP_ID=<ExpectedValue>" match
    $targetEntry = "SCRIPT_GROUP_ID=$ExpectedValue"
    foreach ($entry in $entries) {
        if ($entry -eq $targetEntry) {
            return $true
        }
    }

    return $false
}

function Invoke-ProxmoxApi {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Path,

        [hashtable]$Body
    )

    $baseUrl = $env:PROXMOX_URL
    if (-not $baseUrl) { throw "PROXMOX_URL environment variable is not set." }
    $baseUrl = $baseUrl.TrimEnd('/')

    $user = $env:PROXMOX_USERNAME
    $token = $env:PROXMOX_TOKEN
    if (-not $user -or -not $token) {
        throw "PROXMOX_USERNAME or PROXMOX_TOKEN environment variable is not set."
    }

    # Proxmox API token syntax: PVEAPIToken <user>@<realm>!<tokenid>=<value>
    $authHeader = "Authorization: PVEAPIToken $user=$token"
    $url = "$baseUrl$Path"

    $targetArgs = @(
        $url,
        '-sS',       # silent but show errors
        '-f',        # fail on HTTP errors
        '-X', $Method,
        '-H', $authHeader,
        '-H', 'Accept: application/json'
    )

    if ($Body) {
        # Proxmox expects urlencoded form data by default
        $pairs = @()
        foreach ($kv in $Body.GetEnumerator()) {
            $k = [Uri]::EscapeDataString([string]$kv.Key)
            $v = [Uri]::EscapeDataString([string]$kv.Value)
            $pairs += "$k=$v"
        }
        $formString = $pairs -join '&'
        $targetArgs += @('-H', 'Content-Type: application/x-www-form-urlencoded', '--data', $formString)
    }

    $result = & curl @targetArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Proxmox API call $Method $Path failed with exit code $LASTEXITCODE."
    }

    if ($result) {
        return $result | ConvertFrom-Json
    }

    return $null
}

function Get-ProxmoxVmByName {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $resp = Invoke-ProxmoxApi -Method 'GET' -Path "/cluster/resources?type=vm"
    # cluster/resources returns: data[].name, .vmid, .type ('qemu'/'lxc'), .node, .template, etc.
    $vm = $resp.data | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    return $vm
}

function Rename-ProxmoxVm {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Vm,

        [Parameter(Mandatory)]
        [string]$NewName
    )

    switch ($Vm.type) {
        'qemu' {
            $path = "/nodes/$($Vm.node)/qemu/$($Vm.vmid)/config"
        }
        'lxc' {
            $path = "/nodes/$($Vm.node)/lxc/$($Vm.vmid)/config"
        }
        default {
            throw "Unsupported VM type '$($Vm.type)' for rename."
        }
    }

    Invoke-ProxmoxApi -Method 'PUT' -Path $path -Body @{ name = $NewName } | Out-Null
}

function Remove-ProxmoxVm {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Vm
    )

    switch ($Vm.type) {
        'qemu' {
            $path = "/nodes/$($Vm.node)/qemu/$($Vm.vmid)"
        }
        'lxc' {
            $path = "/nodes/$($Vm.node)/lxc/$($Vm.vmid)/config"
        }
        default {
            throw "Unsupported VM type '$($Vm.type)' for delete."
        }
    }

    Invoke-ProxmoxApi -Method 'DELETE' -Path $path | Out-Null
}

function Wait-ProxmoxVmRename {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Vm,

        [Parameter(Mandatory)]
        [string]$OldName,

        [Parameter(Mandatory)]
        [string]$NewName,

        [int]$TimeoutSeconds = 60,
        [int]$PollIntervalSeconds = 2
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    Write-Host "Waiting for VMID $($Vm.vmid) rename '$OldName' -> '$NewName' to propagate..."

    while ((Get-Date) -lt $deadline) {
        $old = Get-ProxmoxVmByName -Name $OldName
        $new = Get-ProxmoxVmByName -Name $NewName

        # We consider it "done" when:
        # - there is no VM with OldName, and
        # - there is a VM with NewName, and it has the same VMID
        if (-not $old -and $new -and $new.vmid -eq $Vm.vmid) {
            Write-Host "Rename propagated: VMID $($Vm.vmid) now appears as '$NewName'."
            return
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    throw "Timed out waiting for VMID $($Vm.vmid) to be renamed from '$OldName' to '$NewName'."
}

function Restore-OriginalVm {
    param(
        [pscustomobject]$OriginalVm,
        [string]$RenamedName,
        [string]$OriginalName
    )

    if (-not $OriginalVm -or -not $RenamedName) {
        return
    }

    try {
        Write-Host "Attempting to restore original VM/template name '$OriginalName'..."
        $tmpVm = Get-ProxmoxVmByName -Name $RenamedName
        if ($tmpVm) {
            Rename-ProxmoxVm -Vm $tmpVm -NewName $OriginalName
        }
        else {
            Write-Warning "Could not find VM with temporary name '$RenamedName' to restore."
        }
    }
    catch {
        Write-Warning "Failed to restore original VM/template name: $_"
    }
}

# ====================== Working Around Semaphore issue ======================
# https://github.com/semaphoreui/semaphore/issues/3512

if ($IsLinux) {
    $env:SCRIPT_GROUP_ID = $vmName
    $selfPid = $PID
    # Current user's numeric UID (e.g. 1000)
    try {
        $currentUid = (& id -u).Trim()
    }
    catch {
        Write-Error "Failed to determine current UID via 'id -u'. Are you on Linux?"
        exit 1
    }

    Get-ChildItem -LiteralPath /proc -Directory |
    Where-Object { $_.Name -match '^\d+$' } |   # numeric PIDs only
    ForEach-Object {
        $targetPid = [int]$_.Name

        # Don't kill ourselves
        if ($targetPid -eq $selfPid) {
            return
        }

        if (Test-ProcessHasScriptGroupId -targetPid $targetPid -ExpectedValue $env:SCRIPT_GROUP_ID) {
            Write-Host "Killing PID $targetPid (same user, SCRIPT_GROUP_ID=$env:SCRIPT_GROUP_ID)..."

            try {
                # Send SIGKILL (9)
                & kill -9 -- $targetPid 2>$null
            }
            catch {
                Write-Warning "Failed to kill PID $targetPid`: $_"
            }
        }
    }
}

# ====================== Main Logic ======================


Write-Host "Checking for existing VM/template named '$vmName' in Proxmox..."

$existing = Get-ProxmoxVmByName -Name $vmName

if ($existing) {
    $originalVm = $existing
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $renamedVmName = "$vmName-old-$timestamp"

    Write-Host "Found existing VM/template:"
    Write-Host "  vmid : $($existing.vmid)"
    Write-Host "  node : $($existing.node)"
    Write-Host "  type : $($existing.type)"
    Write-Host "Renaming to '$renamedVmName' before Packer build..."

    Rename-ProxmoxVm -Vm $existing -NewName $renamedVmName

    # Wait until the rename is visible in the cluster view
    Wait-ProxmoxVmRename -Vm $existing -OldName $vmName -NewName $renamedVmName
}
else {
    Write-Host "No existing VM/template named '$vmName' found. Proceeding with Packer build."
}

Set-Location $PSScriptRoot

try {

    # ---- Run packer init ----
    Write-Host "Running 'packer init .'..."
    & packer init .
    if ($LASTEXITCODE -ne 0) {
        $buildExitCode = $LASTEXITCODE
        throw "packer init failed with exit code $buildExitCode."
    }

    # ---- Run packer build ----
    Write-Host "Running 'packer build -force .'..."
    & packer build -force .
    if ($LASTEXITCODE -ne 0) {
        $buildExitCode = $LASTEXITCODE
        throw "packer build failed with exit code $buildExitCode."
    }

    Write-Host "Packer build completed successfully."

}
catch {
    Write-Host "Unexpected error: $_"
    Restore-OriginalVm -OriginalVm $originalVm -RenamedName $renamedVmName -OriginalName $vmName

    if ($buildExitCode) {
        exit $buildExitCode
    }

    exit 1
}

if ($originalVm -and $renamedVmName) {
    Write-Host "Deleting old renamed VM/template '$renamedVmName' (vmid=$($originalVm.vmid))..."
    Remove-ProxmoxVm -Vm $originalVm
}

