variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token (e.g., terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (set to true for self-signed certificates)"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Target Proxmox node name for both containers"
  type        = string
}

variable "proxmox_host_default_pwd" {
  description = "The root user password for the containers"
  type        = string
  sensitive   = true
}

variable "static_ips" {
  description = "Map of static IP addresses (keys: prometheus, grafana)"
  type        = map(string)
}

variable "gateway" {
  description = "Default gateway IP address for LXC containers"
  type        = string
  default     = "192.168.86.1"
}

variable "file-system" {
  description = "Datastore ID for the container disks"
  type        = string
  default     = "local-zfs"
}

variable "template_file_id" {
  description = "Proxmox template file ID for LXC containers"
  type        = string
}

variable "os_type" {
  description = "Operating system type for LXC containers"
  type        = string
  default     = "debian"
}
