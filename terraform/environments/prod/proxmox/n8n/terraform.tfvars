proxmox_api_url      = "https://proxmox.grumples.home:8006/api2/json"
proxmox_tls_insecure = false # Set to false if using valid SSL certificate
proxmox_node         = "minis"
template_file_id     = "pve-cluster:vztmpl/debian13-docker_v29-template.tar.gz"
static_ip            = "192.168.86.59"
enable_replication   = true     # Set to true for multi-node clusters
replication_target   = "gmktec" # e.g. "pve2"
