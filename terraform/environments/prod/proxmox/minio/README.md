# proxmox-prod / minio

Provisions one LXC container on Proxmox VE for [MinIO](https://min.io/) — S3-compatible object storage. Generates the Ansible inventory at `ansible/inventory/prod/proxmox/minio/inventory.ini`.

## Container

| Service | Hostname | Cores | RAM  | Swap  | Disk   |
| ------- | -------- | ----- | ---- | ----- | ------ |
| MinIO   | `minio`  | 2     | 2 GB | 1 GB  | 100 GB |

## Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values. Sensitive variables should be set via environment variables:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

Key variables:

| Variable             | Description                              |
| -------------------- | ---------------------------------------- |
| `proxmox_node`       | Target Proxmox node name                 |
| `static_ip`          | Static IP (without CIDR)                 |
| `gateway`            | Default gateway (default `192.168.86.1`) |
| `minio_root_user`    | MinIO admin username                     |
| `minio_root_password` | MinIO admin password                    |
| `template_file_id`   | Proxmox LXC template file ID             |

## Deploy

```bash
# From this directory
terraform init
terraform plan
terraform apply
# Generates: ansible/inventory/prod/proxmox/minio/inventory.ini

# From repo root
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/minio/inventory.ini \
  ansible/deploy-minio.yml
```

MinIO console is accessible at `http://<minio-ip>:9001`. S3 API endpoint is at port `9000`.
