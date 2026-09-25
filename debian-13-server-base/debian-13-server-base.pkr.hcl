packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1"
    }
  }
}

source "proxmox-iso" "linux-debian" {
  node = "${var.node}"
  boot_iso {
    type     = "scsi"
    iso_file = "${var.iso_path}"
    unmount  = true
  }
  proxmox_url              = "${var.proxmox_url}"
  insecure_skip_tls_verify = "${var.insecure_skip_tls_verify}"
  username                 = "${var.username}"
  token                    = "${var.token}"
  tags                     = "${var.tags}"
  vm_name                  = "${var.vm_name}"
  template_name            = "${var.vm_name}"
  template_description     = "Created on: ${timestamp()}"
  os                       = "${var.os}"
  cores                    = "${var.cpus}"
  memory                   = "${var.memory}"

  cloud_init              = true
  cloud_init_storage_pool = var.cloud_init_storage_pool

  disks {
    disk_size    = "${var.disk_size}"
    type         = "scsi"
    storage_pool = "${var.storage_pool}"
    format       = "raw"
  }
  network_adapters {
    model    = "virtio"
    bridge   = "${var.bridge}"
    vlan_tag = "${var.vlan_tag}"
    firewall = true
  }

  http_directory = "${var.http_directory}"
  http_port_min  = "${var.http_port}"
  http_port_max  = "${var.http_port}"
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://${var.http_ip}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US <wait>",
    "auto <wait>",
    "net.ifnames=0 <wait>",
    "biosdevname=0 <wait>",
    "locale=en_US <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/choose_interface=eth0 <wait>",
    "netcfg/get_hostname=debian <wait>",
    "netcfg/get_domain=bat.nz <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]
  communicator = "${var.communicator}"
  ssh_username = "${var.ssh_username}"
  ssh_password = "${var.ssh_password}"
  ssh_timeout  = "${var.ssh_timeout}"
}

build {
  sources = ["source.proxmox-iso.linux-debian"]

  provisioner "shell" {
    environment_vars = [
      "SSH_USERNAME=${var.ssh_username}",
    ]
    execute_command   = "echo 'debian' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts = [
      "./scripts/baseline.sh",
      "./scripts/user.sh",
      "./scripts/add-space.sh",
    ]
  }
}
