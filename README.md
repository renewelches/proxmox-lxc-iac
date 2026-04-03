# proxmox-lxc-iac

Infrastructure-as-code for self-hosted services on Proxmox VE using LXC containers.

## How It Works

Two-tier workflow:

1. **Terraform** provisions LXC containers on Proxmox and writes an `inventory.ini` file for Ansible to use.
2. **Ansible** deploys Docker containers into those LXC containers using the generated inventory.

Keeping these two concerns separate means you can re-provision infrastructure without touching service config, and re-deploy services without touching Proxmox.

## Environments

| Environment | Path                                   | State Backend |
| ----------- | -------------------------------------- | ------------- |
| prod        | `terraform/environments/prod/proxmox/` | S3 (MinIO)    |
| dev         | `terraform/environments/dev/proxmox/`  | Local         |

Both environments provision real Proxmox LXC containers — dev is not mocked or local-only. Dev containers use reduced resources (1 CPU, 512–1024 MB RAM, 8–10 GB disk) and get `-dev` hostname suffixes so they can coexist with prod on the same cluster.

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

I decided to go full in on TLS with my home lab. Hence, most stacks require TLS certificates (`termix`, `forgejo`, `minio`, `n8n`, `openwebui-searxng`). The playbooks will fail if the cert files are not present before running. If you want to use self-signed certificates you can follow [homelab self-signed certificate setup](https://github.com/renewelches/homelab-self-signed-cert-setup).

If you work with self-signed certificates, make sure that you install the ROOT CA on your host machines (see [add CA to trust store for Linux](https://github.com/renewelches/homelab-self-signed-cert-setup?tab=readme-ov-file#linux)). Ansible will mount the host store into the LXC from where it can be exposed to Docker. This is required for example by the Open WebUI container for communicating via TLS with the SearXNG LXC/Docker. If you miss this part the web search feature in Open WebUI will not work.

Place the `.crt` and `.key` files in `ansible/files/<stack>/` before running the playbook. The `openwebui-searxng` stack needs two pairs — one for `openwebui/` and one for `searxng/`.

## terraform.tfstate Backend

I recommend using MinIO as a backend for your Terraform state files — it gives you remote state, locking via versioning, and keeps everything self-hosted. Deploy MinIO first using a local Terraform state backend, then migrate the other stacks to S3 once MinIO is up.

Before provisioning, create your certificates for MinIO as described above and copy them to `ansible/files/minio/`.

```bash
cd terraform/environments/<env>/proxmox/minio
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform apply
```

Check that the MinIO LXC is available in Proxmox. Then configure it with Ansible:

```bash
ansible-playbook -i ansible/inventory/prod/proxmox/minio/inventory.ini ansible/deploy-minio.yml
```

Verify MinIO is available at `https://<IP>:9001`, where `<IP>` is the IP you entered in your `terraform.tfvars`.

### 1. Install the MinIO CLI

#### macOS (Homebrew)

```bash
brew install minio/stable/mc
```

#### Linux

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

### 2. Create the Terraform state bucket

```bash
# Set up an alias
mc alias set homelab https://<minio IP|URL> <admin-user> <admin-pwd>

# Create Terraform state bucket
mc mb homelab/terraform-state
mc version enable homelab/terraform-state # enables state locking via versioning
```

### 3. Create a dedicated service account

Don't use your admin credentials in the backend — create a dedicated user for Terraform instead.

```bash
mc admin user add homelab tf-user <strong-password>
mc admin policy attach homelab readwrite --user tf-user
```

Get the access/secret key pair for the backend file:

```bash
mc admin user svcacct add homelab tf-user
```

Copy those credentials into your `backend.tf` files (next step).

### 4. Add backend.tf to each stack

Create a `backend.tf` file in each stack directory, e.g. `terraform/environments/prod/proxmox/<stack>/backend.tf`. This file is git-ignored — it lives only on disk and holds your MinIO credentials.

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "proxmox/<stack>/terraform.tfstate"
    # DUMMY REGION, WILL BE IGNORED BY MINIO
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

### 5. Reinitialize Terraform

Run `terraform init` in your stack folder and verify that the state file lands in your MinIO bucket (e.g. via the UI at `https://<IP>:9001`).

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
