vm_name                 = "template-debian-12"
os                      = "l26"
http_directory          = "http"
iso_path                = "local:iso/debian-12.8.0-amd64-netinst.iso"
cloud_init_storage_pool = "local-lvm"

communicator = "ssh"
ssh_username = "debian"
ssh_password = "debian"
ssh_timeout  = "20m"
http_port    = "8805"
cpus         = "1"
memory       = "2048"
disk_size    = "10G"

proxmox_url              = "https://proxmox.bat.nz:8006/api2/json"
node                     = "proxmox"
username                 = "packer@pve!automation"
insecure_skip_tls_verify = false
tags                     = "template"
storage_pool             = "local-lvm"
vlan_tag                 = 41
bridge                   = "vmbr0"