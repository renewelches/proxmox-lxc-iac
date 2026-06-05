# proxmox-prod / openwebui-searxng

Provisions two LXC containers on Proxmox VE for Open WebUI and SearXNG. Generates the Ansible inventory at `ansible/inventory/prod/proxmox/openwebui-searxng/inventory.ini`.

## Containers

| Service    | Hostname     | Cores | RAM    | Swap   | Disk  | Port |
| ---------- | ------------ | ----- | ------ | ------ | ----- | ---- |
| Open WebUI | `open-webui` | 2     | 1.5 GB | 768 MB | 50 GB | 443  |
| SearXNG    | `searxng`    | 1     | 512 MB | 256 MB | 30 GB | 443  |

## Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values. Sensitive variables should be set via environment variables:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

Key variables:

| Variable                 | Description                                                      |
| ------------------------ | --------------------------------------------------------------- |
| `proxmox_nodes`          | Map of node names (`openwebui`, `searxng`)                      |
| `static_ips`             | Map of static IPs (`open_webui`, `searxng`)                     |
| `gateway`                | Default gateway (default `192.168.86.1`)                        |
| `network_bridge`         | Proxmox bridge for the NICs (default `vmbr0`; `vmbr1` for VLAN) |
| `network_interface_name` | Guest NIC name (default `eth0`)                                 |
| `ollama_host`            | URL of your remote Ollama instance                              |
| `template_file_id`       | Proxmox LXC template file ID                                    |

### Network bridge / VLAN isolation

By default the containers attach to `vmbr0` (flat, untagged network). To place them
on an isolated VLAN/lab segment, point `network_bridge` at a dedicated bridge:

```hcl
network_bridge = "vmbr1"   # e.g. an OPNsense LAN / lab bridge
```

If your isolated segment lives on a single VLAN-aware bridge instead of a dedicated
one, set `network_bridge = "vmbr0"` and add a VLAN tag in `main.tf`'s
`network_interface` block (`vlan_id = <id>`). The container's `gateway` must point at
the router for that segment.

## Deploy

```bash
# From this directory
terraform init
terraform plan
terraform apply
# Generates: ansible/inventory/prod/proxmox/openwebui-searxng/inventory.ini

# From repo root
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/openwebui-searxng/inventory.ini \
  ansible/deploy-openwebui-searxng.yml
```
