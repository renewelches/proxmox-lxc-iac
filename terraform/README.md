# Terraform

Terraform provisions Proxmox LXC containers and generates the Ansible inventory files.

## Structure

```text
terraform/
└── environments/
    ├── prod/
    │   └── proxmox/    # Production: Proxmox LXC containers (S3/MinIO backend)
    │       ├── openwebui-searxng/
    │       ├── prometheus-grafana/
    │       ├── claude-code/
    │       ├── termix/
    │       ├── forgejo/
    │       ├── minio/
    │       └── n8n/
    └── dev/
        └── proxmox/    # Dev: same cluster, reduced resources, -dev hostnames (local backend)
            ├── openwebui-searxng/
            ├── prometheus-grafana/
            ├── claude-code/
            ├── termix/
            ├── forgejo/
            ├── minio/
            └── n8n/
```

Each stack directory is an independent Terraform root module with its own state. Run all Terraform commands from within the stack directory.

## Providers

| Provider                                                                    | Version                          |
| --------------------------------------------------------------------------- | -------------------------------- |
| [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest) | `>= 0.99.0`                      |
| `hashicorp/local`                                                           | writes generated `inventory.ini` |

## Inventory Generation

Each `terraform apply` writes an `inventory.ini` into the corresponding `ansible/inventory/<env>/proxmox/<stack>/` directory via a `local_file` resource. The path is hardcoded relative to the stack directory, so Terraform must be run from within the stack directory.

## Environment Details

### Production (`prod/proxmox/`)

Uses a remote S3 backend (MinIO). Each stack requires a `backend.tf` created locally before `terraform init` — this file is git-ignored.

#### Production Stacks

| Stack                | Containers          | Description           |
| -------------------- | ------------------- | --------------------- |
| Open WebUI + SearXNG | Open WebUI, SearXNG | LLM frontend + search |
| Prometheus + Grafana | Prometheus, Grafana | Monitoring            |
| Claude Code          | Claude Code         | Claude Code CLI       |
| Termix               | Termix, guacd       | Web-based terminal    |
| Forgejo              | Forgejo             | Self-hosted Git       |
| MinIO                | MinIO               | S3-compatible storage |
| n8n                  | n8n                 | Workflow automation   |

Each stack directory has its own README with full deployment instructions.

### Dev (`dev/proxmox/`)

Uses a local backend (`terraform.tfstate` in the stack directory). No `backend.tf` needed.

Dev containers use 1 CPU / 512 MB–1 GB RAM / 8–10 GB disk and get `-dev` hostname suffixes.

#### Dev Stacks

| Stack                | Containers          | Description           |
| -------------------- | ------------------- | --------------------- |
| Open WebUI + SearXNG | Open WebUI, SearXNG | LLM frontend + search |
| Prometheus + Grafana | Prometheus, Grafana | Monitoring            |
| Claude Code          | Claude Code         | Claude Code CLI       |
| Termix               | Termix, guacd       | Web-based terminal    |
| Forgejo              | Forgejo             | Self-hosted Git       |
| MinIO                | MinIO               | S3-compatible storage |
| n8n                  | n8n                 | Workflow automation   |

Each stack directory has its own README with full deployment instructions.

## Common Variables

All stacks share these variables:

| Variable                   | Description                              |
| -------------------------- | ---------------------------------------- |
| `proxmox_api_url`          | Proxmox API URL                          |
| `proxmox_api_token`        | API token (`user@pve!token=uuid`)        |
| `proxmox_tls_insecure`     | Skip TLS verification (default `false`)  |
| `proxmox_node`             | Target Proxmox node name                 |
| `proxmox_host_default_pwd` | Root password for the container          |
| `template_file_id`         | Proxmox LXC template file ID             |
| `static_ip`                | Static IP (without CIDR)                 |
| `gateway`                  | Default gateway (default `192.168.86.1`) |

Set sensitive variables via environment variables to avoid storing them in `terraform.tfvars`:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

## Deploy Workflow

```bash
cd terraform/environments/<env>/proxmox/<stack>
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform apply
# Generates: ansible/inventory/<env>/proxmox/<stack>/inventory.ini
```
