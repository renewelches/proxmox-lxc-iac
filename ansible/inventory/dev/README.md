# ansible/inventory/dev

Ansible configuration and inventory templates for the Proxmox development environment.

## proxmox/

Contains per-stack inventory templates and configuration for dev LXC containers provisioned via `terraform/environments/dev/proxmox/`.

### ansible.cfg

```ini
[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no
```

Disables host key checking — safe for short-lived dev containers.

### Inventories

Each stack has its own subdirectory with an `inventory.tpl` (Terraform template) and a generated `inventory.ini` (git-ignored):

| Stack               | Ansible user | Host auth |
| ------------------- | ------------ | --------- |
| openwebui-searxng   | `root`       | SSH agent |
| prometheus-grafana  | `root`       | SSH agent |
| claude-code         | `root`       | SSH agent |
| termix              | `root`       | SSH agent |
| forgejo             | `root`       | SSH agent |
| minio               | `root`       | SSH agent |
| n8n                 | `root`       | SSH agent |

`inventory.ini` is generated automatically by Terraform's `local_file` resource after `terraform apply`. Example:

```ini
[all]
open-webui-dev ansible_host=192.168.86.160

[all:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3.13
```

### group_vars

`prometheus-grafana/group_vars/all.yml` defines the Prometheus scrape targets. Update IPs to match your dev container assignments.

## Workflow

```bash
cd terraform/environments/dev/proxmox/<stack>
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init && terraform apply              # provisions container + writes inventory.ini

ansible-playbook -i ansible/inventory/dev/proxmox/<stack>/inventory.ini \
  ansible/deploy-<service>.yml
```
