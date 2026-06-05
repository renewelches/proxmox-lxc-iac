variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token, use environment variable or secure vault (e.g. terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (set to true for self-signed certificates)"
  type        = bool
  default     = false
}

variable "proxmox_nodes" {
  description = "Target Proxmox node names per container (keys: openwebui, searxng)"
  type        = map(string)
}


variable "proxmox_host_default_pwd" {
  description = "The root user password for the host"
  type        = string
  sensitive   = true
}

variable "static_ips" {
  description = "Map of static IP addresses for resources"
  type        = map(string)
}

variable "gateway" {
  description = "Default gateway IP address for LXC containers"
  type        = string
  default     = "192.168.86.1"
}

variable "file-system" {
  description = "The default file system to be used for the container or VM"
  type        = string
  default     = "local-zfs"
}

variable "openwebui_disk_size" {
  description = "Disk size in GB for the Open WebUI container"
  type        = number
  default     = 50
}

variable "searxng_disk_size" {
  description = "Disk size in GB for the SearXNG container"
  type        = number
  default     = 30
}

variable "network_bridge" {
  description = "Proxmox bridge the container network interfaces attach to. Use vmbr0 for a flat/untagged network, or a dedicated bridge (e.g. vmbr1) for an isolated VLAN/lab segment."
  type        = string
  default     = "vmbr0"
}

variable "network_interface_name" {
  description = "Name of the container network interface (as seen inside the guest, e.g. eth0)."
  type        = string
  default     = "eth0"
}
variable "ollama_host" {
  description = "The remote URL of ollama. Ollama must run with 'Expose Ollam to the network' setting."
  type        = string
}

variable "template_file_id" {
  description = "The Proxmox template file ID for LXC containers (e.g., pve-cluster:vztmpl/debian13-docker-template.tar.gz)"
  type        = string
}

variable "os_type" {
  description = "The operating system type for LXC containers (e.g., debian, ubuntu, centos)"
  type        = string
  default     = "debian"
}

variable "openwebui_memory_dedicated" {
  description = "Dedicated RAM in MB for the Open WebUI container"
  type        = number
  default     = 1536
}

variable "openwebui_memory_swap" {
  description = "Swap in MB for the Open WebUI container"
  type        = number
  default     = 768
}

variable "searxng_memory_dedicated" {
  description = "Dedicated RAM in MB for the SearXNG container"
  type        = number
  default     = 512
}

variable "searxng_memory_swap" {
  description = "Swap in MB for the SearXNG container"
  type        = number
  default     = 256
}

variable "enable_replication" {
  description = "Enable replication to another Proxmox node (requires multi-node cluster)"
  type        = bool
  default     = false
}

variable "replication_target" {
  description = "Target Proxmox node for replication (required if enable_replication = true)"
  type        = string
  default     = ""
}
