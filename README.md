# proxmox-lxc-iac

Infrastructure-as-code for self-hosted services on Proxmox VE using LXC containers.

## How It Works

Two-tier workflow:

1. **Terraform** provisions LXC containers on Proxmox and writes an `inventory.ini` file for Ansible to use.
2. **Ansible** deploys Docker containers into those LXC containers using the generated inventory.

## Environments

| Environment | Path                                   | State Backend       |
| ----------- | -------------------------------------- | ------------------- |
| prod        | `terraform/environments/prod/proxmox/` | Local or S3 (MinIO) |
| dev         | `terraform/environments/dev/proxmox/`  | Local               |

Both environments provision real Proxmox LXC containers. Dev containers use reduced resources and `-dev` hostname suffixes.

## Stacks

Each stack is fully independent with its own Terraform state. They can be deployed individually in any order, à la carte.

A stack consists of:

- A Terraform directory at `terraform/environments/<env>/proxmox/<stack>/` that provisions one or more LXC containers and outputs an `ansible/inventory/<env>/proxmox/<stack>/inventory.ini`.
- An Ansible playbook at `ansible/deploy-<service>.yml` that configures Docker and deploys the service into the provisioned containers.
- A `.tfvars` file (git-ignored) that supplies stack-specific variables like IPs, credentials, and hostnames.

| Stack                | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `openwebui-searxng`  | Open WebUI (LLM frontend) + SearXNG (private search) |
| `prometheus-grafana` | Prometheus metrics collection + Grafana dashboards   |
| `claude-code`        | Claude Code CLI environment                          |
| `termix`             | Web-based terminal manager (HTTPS)                   |
| `forgejo`            | Self-hosted Git service (HTTPS + SSH)                |
| `minio`              | S3-compatible object storage                         |
| `n8n`                | Workflow automation platform                         |

## Certificates

All stacks need certificates for HTTPS/TLS. If you want to use self signed certificate you can follow [homelab self-signed certificate setup](https://github.com/renewelches/homelab-self-signed-cert-setup).

## terraform.tfstate Backend

I recommend to use minio as backend for your terraform.tfstate files. Deploy minio first (with local terraform.tfstate backend).

### 1. Install the MinIO CLI

#### macOS (Homebrew)

```bash
brew install minio/stable/mc
```

#### Ubuntu / Debian

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries
```

#### RHEL / CentOS / Fedora

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries
```

#### Generic Linux

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries
```

#### Windows (PowerShell)

```powershell
cd $env:USERPROFILE
Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" -OutFile "mc.exe"

# Add to PATH or run from current directory
.\mc.exe --version
```

#### Docker

```bash
docker run -it --entrypoint=mc minio/mc:latest alias ls
```

### 2. Create Terraform state bucket

```bash
# Setup an alias
mc alias set homelab https://<minio IP|URL> <admin-user> <admin-pwd>

#Create Terraform state bucket
mc mb homelab/terraform-state
mc version enable homelab/terraform-state # enables state locking via versioning

```

### 3. Create a dedicated service account

```bash
mc admin user add homelab tf-user <strong-password>
mc admin policy attach homelab readwrite --user tf-user
```

Get Credentials for the backend file

```bash
mc admin user svcacct add homelab tf-user
```

Copy the credentials over into you backend.tf files (next step).

### 4. Add the backend.tf files to your stack

Create a `backend.tf` file in your stack directory e.g. `environments/proxmox/claude-code/backend.tf` with the following content:

```HCL
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "proxmox/forgejo/terraform.tfstate"
    #DUMMY REGION, WILL BE IGNORED BY MINIO
    region = "us-east-1"

    endpoints = {
      s3 = "https://<your minio IP or DNS>:9000"
    }

    access_key = "<copied key>"
    secret_key = "<copied key>"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    use_lockfile = true
  }
}
```

### Terraform init

Execute a `terraform init` in you stack folder and verify that the tfstate file is available in your minio bucket (e.g. via UI).

## Quick Start

```bash
# 1. Provision a stack (creates LXC container + writes inventory.ini)
cd terraform/environments/<env>/proxmox/<stack>
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform apply

# 2. Deploy services onto the container
ansible-playbook -i ansible/inventory/<env>/proxmox/<stack>/inventory.ini \
  ansible/deploy-<service>.yml
```

## Docs

- [terraform/README.md](terraform/README.md) — Terraform structure, stacks, and variables
- [ansible/README.md](ansible/README.md) — Ansible playbooks, inventory, and usage
