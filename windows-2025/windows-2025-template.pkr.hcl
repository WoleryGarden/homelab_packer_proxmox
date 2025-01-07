packer {
  required_plugins {
    windows-update = {
      version = "0.16.8"
      source  = "github.com/rgl/windows-update"
    }
    proxmox = {
      #version = "~> 1"
      version = "1.2.1" # https://github.com/hashicorp/packer-plugin-proxmox/issues/307
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "windows2025" {

  # Proxmox Host Conection
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = var.insecure_skip_tls_verify
  username                 = var.username
  token                    = var.token
  node                     = var.node

  # BIOS - UEFI
  bios = "ovmf"

  # Machine type
  # Q35 less resource overhead and newer chipset
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.efi_storage
    pre_enrolled_keys = true
    efi_type          = "4m"
  }

  # Windows Server ISO File
  boot_iso {
    type     = "ide"
    iso_file = "${var.windows_iso}"
    unmount  = true
    index    = 2
  }
  boot = "order=ide2;scsi0"

  additional_iso_files {
    cd_files = ["./build_files/drivers/*", "./build_files/scripts/ConfigureRemotingForAnsible.ps1", "./build_files/software/virtio-win-guest-tools.exe", "./build_files/scripts/BTServer.bgi"]
    cd_content = {
      "autounattend.xml" = templatefile("./build_files/templates/unattend.pkrtpl", { password = var.winrm_password, cdrom_drive = var.cdrom_drive })
    }
    cd_label         = "Unattend"
    iso_storage_pool = var.iso_storage
    unmount          = true
    type  = "ide"
    index = 0
  }

  template_name           = var.vm_name
  template_description    = "Created on: ${timestamp()}"
  vm_name                 = var.vm_name
  memory                  = var.memory
  cores                   = var.cores
  sockets                 = var.socket
  cpu_type                = "host"
  os                      = "win11"
  scsi_controller         = "virtio-scsi-single"
  cloud_init              = true
  cloud_init_storage_pool = var.cloud_init_storage

  # Network
  network_adapters {
    model    = "virtio"
    bridge   = var.bridge
    vlan_tag = var.vlan
  }

  # Storage
  disks {
    storage_pool = var.disk_storage
    type      = "scsi"
    disk_size = var.disk_size_gb
    io_thread = true
    cache_mode = "writeback"
    format = "raw"
  }

  # WinRM
  communicator   = "winrm"
  winrm_username = var.winrm_user
  winrm_password = var.winrm_password
  winrm_timeout  = "12h"
  winrm_port     = "5986"
  winrm_use_ssl  = true
  winrm_insecure = true

  # Boot
  boot_wait = "7s"
  boot_command = [
    "<enter>"
  ]

}

build {
  name    = "Proxmox Build"
  sources = ["source.proxmox-iso.windows2025"]

  provisioner "windows-restart" {
  }

  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "exclude:$_.InstallationBehavior.CanRequestUserInput",
      "include:$true",
    ]
    update_limit = 25
  }

  provisioner "powershell" {
    script       = "./build_files/scripts/InstallCloudBase.ps1"
    pause_before = "1m"
  }

  provisioner "file" {
    source      = "./build_files/config/"
    destination = "C://Program Files//Cloudbase Solutions//Cloudbase-Init//conf"
  }

  provisioner "powershell" {
    inline = [
      "Set-Service cloudbase-init -StartupType Manual",
      "Stop-Service cloudbase-init -Force -Confirm:$false"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "./build_files/scripts/enable-rdp.ps1",
      "./build_files/scripts/adjust-timezone.ps1",
      "./build_files/scripts/disable-screensaver.ps1",
      "./build_files/scripts/disable-servermanager.ps1",
      "./build_files/scripts/enable-sharing.ps1",
      "./build_files/scripts/install-bginfo.ps1",
      "./build_files/scripts/install-pwsh.ps1",
      "./build_files/scripts/install-scoop.ps1",
      "./build_files/scripts/install-telnet.ps1"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Set-Location -Path \"C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\"",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /unattend:unattend.xml"
    ]
  }
}
