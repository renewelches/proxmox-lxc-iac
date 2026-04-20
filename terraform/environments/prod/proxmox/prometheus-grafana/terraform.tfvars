# Copy this file to terraform.tfvars and fill in your actual values
# DO NOT commit terraform.tfvars to version control

proxmox_api_url      = "https://proxmox.grumples.home:8006/api2/json"
proxmox_tls_insecure = false # Set to false if using valid SSL certificate
proxmox_nodes = {
  prometheus = "minis",
  grafana    = "gmktec",
}
template_file_id = "pve-cluster:vztmpl/debian13-docker_v29-template.tar.gz"
static_ips = {
  prometheus = "192.168.86.151",
  grafana    = "192.168.86.101",
}
