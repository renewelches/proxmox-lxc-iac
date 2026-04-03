# proxmox-prod / claude-code

Provisions one LXC container on Proxmox VE for the Claude Code CLI environment. Generates the Ansible inventory at `ansible/inventory/prod/proxmox/claude-code/inventory.ini`.

## Container

| Service     | Hostname      | Cores | RAM  | Swap | Disk  |
| ----------- | ------------- | ----- | ---- | ---- | ----- |
| Claude Code | `claude-code` | 2     | 2 GB | 1 GB | 20 GB |

## Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values. Sensitive variables should be set via environment variables:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

Key variables:

| Variable           | Description                              |
| ------------------ | ---------------------------------------- |
| `proxmox_node`     | Target Proxmox node name                 |
| `static_ip`        | Static IP (without CIDR)                 |
| `gateway`          | Default gateway (default `192.168.86.1`) |
| `template_file_id` | Proxmox LXC template file ID             |

## Deploy

```bash
# From this directory
terraform init
terraform plan
terraform apply
# Generates: ansible/inventory/prod/proxmox/claude-code/inventory.ini

# From repo root
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/claude-code/inventory.ini \
  ansible/deploy-claude-code.yml

# After deploying, set the API key on the container before running claude:
#   export ANTHROPIC_API_KEY=sk-ant-...
```
