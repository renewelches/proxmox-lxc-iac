# proxmox-prod / prometheus-grafana

Provisions two LXC containers on Proxmox VE for the monitoring stack. Generates the Ansible inventory at `ansible/inventory/prod/proxmox/prometheus-grafana/inventory.ini`.

## Containers

| Service    | Hostname     | Cores | RAM  | Disk  | Port |
| ---------- | ------------ | ----- | ---- | ----- | ---- |
| Prometheus | `prometheus` | 2     | 2 GB | 50 GB | 9090 |
| Grafana    | `grafana`    | 1     | 1 GB | 25 GB | 3000 |

## Prometheus Scrape Targets

The IPs of services that Prometheus scrapes are not part of the Terraform configuration. They are defined per-environment in Ansible `group_vars`:

```text
ansible/inventory/prod/proxmox/prometheus-grafana/group_vars/all.yml
ansible/inventory/dev/proxmox/prometheus-grafana/group_vars/all.yml
```

Edit the appropriate `group_vars/all.yml` to add or update scrape targets before running the Ansible playbook.

## Variables

Copy `terraform.tfvars.example` to `terraform.tfvars`. Sensitive variables via environment variables:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

Key variables:

| Variable           | Description                              |
| ------------------ | ---------------------------------------- |
| `proxmox_nodes`    | Node names per container                 |
| `static_ips`       | Static IPs per container                 |
| `gateway`          | Default gateway (default `192.168.86.1`) |
| `template_file_id` | Proxmox LXC template file ID             |

## Deploy

```bash
# From this directory
terraform init
terraform plan
terraform apply
# Generates: ansible/inventory/prod/proxmox/prometheus-grafana/inventory.ini

# From repo root
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/prometheus-grafana/inventory.ini \
  ansible/deploy-prometheus-grafana.yml
```
