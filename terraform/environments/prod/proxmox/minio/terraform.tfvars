# Copy this file to terraform.tfvars and fill in your actual values
# DO NOT commit terraform.tfvars to version control

proxmox_api_url      = "https://proxmox.grumples.home:8006/api2/json"
proxmox_tls_insecure = false # Set to false if using valid SSL certificate
template_file_id     = "pve-cluster:vztmpl/debian13-docker_v29-template.tar.gz"
proxmox_node         = "minis"
static_ip            = "192.168.86.215"
minio_root_user      = "rene"
minio_root_password  = "ma:de3108"
enable_replication   = true    # Set to true for multi-node clusters
replication_target   = "morfi" # e.g. "pve2"

