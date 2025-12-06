vm_name            = "template-windows-2025"
os                 = "win11"
windows_iso        = "local:iso/en-us_windows_server_2025_updated_nov_2025_x64_dvd_2cfcca22.iso"
iso_storage        = "local"
efi_storage        = "local-lvm"
cloud_init_storage = "local-lvm"

winrm_user     = "Administrator"
winrm_password = "vagrant"
cores          = 4
socket         = 1
memory         = 4096
disk_storage   = "local-lvm"
disk_size_gb   = "60G"

proxmox_url              = "https://proxmox.bat.nz:8006/api2/json"
node                     = "proxmox"
username                 = "packer@pve!automation"
insecure_skip_tls_verify = false
tags                     = "template"
storage_pool             = "local-lvm"
vlan                     = 41
bridge                   = "vmbr0"
