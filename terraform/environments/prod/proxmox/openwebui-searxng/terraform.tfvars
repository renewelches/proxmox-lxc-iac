# Copy this file to terraform.tfvars and fill in your actual values
# DO NOT commit terraform.tfvars to version control

proxmox_api_url      = "https://proxmox.grumples.home:8006/api2/json"
proxmox_tls_insecure = false # Set to false if using valid SSL certificate
proxmox_nodes = {
  openwebui = "gmktec",
  searxng   = "gmktec",
}
template_file_id = "pve-cluster:vztmpl/debian13-docker_v29-template.tar.gz"
static_ips = {
  searxng    = "192.168.86.60",
  open_webui = "192.168.86.64",
}
ollama_host        = "https://ollama.grumples.home"
enable_replication = true    # Set to true for multi-node clusters
replication_target = "minis" # e.g. "pve2"

