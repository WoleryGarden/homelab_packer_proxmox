variable "proxmox_url" {
  type = string
}
variable "node" {
  type = string
}
variable "username" {
  type = string
}
variable "token" {
  type      = string
  sensitive = true
  default   = env("PROXMOX_TOKEN")
}
variable "insecure_skip_tls_verify" {
  type = string
}
variable "storage_pool" {
  type = string
}
variable "vm_name" {
  type = string
}
variable "os" {
  type = string
}
variable "cpus" {
  type = string
}
variable "memory" {
  type = string
}
variable "disk_size" {
  type = string
}
variable "vlan_tag" {
  type = string
}
variable "iso_path" {
  type = string
}
variable "http_ip" {
  type    = string
  default = env("HTTP_IP")
}
variable "http_port" {
  type = string
}
variable "communicator" {
  type = string
}
variable "ssh_username" {
  type = string
}
variable "ssh_password" {
  type = string
}
variable "ssh_timeout" {
  type = string
}
variable "http_directory" {
  type = string
}
variable "tags" {
  type = string
}
variable "bridge" {
  type = string
}
variable "cloud_init_storage_pool" {
  type = string
}
