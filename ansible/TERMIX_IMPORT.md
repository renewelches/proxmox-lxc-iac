# Termix JSON Import from Proxmox Dynamic Inventory

This workflow generates a Termix JSON import file from your Proxmox infrastructure, allowing you to bulk-import all your LXC containers and VMs as Termix hosts.

## Overview

The process uses three components:

1. **`inventory/prod/proxmox/termix/pve.proxmox.yml`** — Proxmox dynamic inventory plugin configuration
   - Queries the Proxmox API for running containers/VMs
   - Filters by status and tags
   - Auto-discovers IPs and names

2. **`inventory/prod/proxmox/termix/group_vars/all.yml`** — Termix-specific variables
   - Default values for termix UI settings (folder, tags, auth type)
   - Merged with discovered hosts

3. **`templates/termix/termix-hosts.json.j2`** — Jinja2 template
   - Renders the dynamic inventory as Termix JSON format
   - Includes all required fields: name, IP, port, user, auth type, folder, tags

## Prerequisites

1. **Proxmox API access** — Set environment variables:

   ```bash
   # Option A: API Token (recommended)
   export PROXMOX_URL=https://<your proxmox domain name>:8006
   export PROXMOX_TOKEN_ID=ansible@pam!token-name
   export PROXMOX_TOKEN_SECRET=<uuid>

   # Option B: Username/Password
   export PROXMOX_URL=https://<your proxmox domain name>:8006
   export PROXMOX_USER=root@pam
   export PROXMOX_PASSWORD=<password>
   ```

   ### Setting Up a Dedicated Ansible User (Recommended for Least Privilege)

   For security, create a dedicated Proxmox user and token with **read-only permissions** (separate from provisioning tokens):

   **In Proxmox, create the user:**

   ```bash
   pveum user add ansible@pve --password <password>
   ```

   **Create an API token:**

   ```bash
   pveum token add ansible@pve!ansible-token --privsep 1
   ```

   Save the token ID and secret immediately — the secret won't be shown again.

   **Grant minimal read-only permissions:**

   ```bash
   pveum acl modify / -user ansible@pve -role Sys.Audit
   pveum acl modify /vms -user ansible@pve -role Vm.Audit
   ```

   These permissions allow:
   - Listing and querying running containers/VMs
   - Reading IP addresses, tags, and container properties
   - **No** create/modify/delete permissions

   **Use the token in your environment:**

   ```bash
   export PROXMOX_URL=https://<your proxmox domain name>:8006
   export PROXMOX_TOKEN_ID=ansible@pve!ansible-token
   export PROXMOX_TOKEN_SECRET=<token-secret-uuid>
   ```

   Keep this separate from your Terraform provisioning token for least-privilege access control.

2. **Ansible installed** (for running the playbook)

3. **Proxmox tags on containers** (optional but recommended)
   - The dynamic inventory filters and groups by tags
   - Example tag: `termix` or `ssh-enabled`

## Usage

### Generate the JSON File

```bash
cd ansible/
ansible-playbook \
  -i inventory/prod/proxmox/termix/pve.proxmox.yml \
  generate-termix-json.yml
```

This will:

- Query the Proxmox dynamic inventory for all running LXC containers and VMs
- Auto-discover container IPs (handles both static and DHCP-assigned addresses)
- Generate `termix-hosts.json` at `inventory/prod/proxmox/termix/termix-hosts.json`
- **Exclude Proxmox nodes** (physical hardware) — only containers/VMs are included
- Display a preview of the generated file

## Configuration

### SSH Key Configuration

By default, the template includes SSH key authentication. Configure the key path in `inventory/prod/proxmox/termix/group_vars/all.yml`:

```yaml
termix_key_path: "~/.ssh/id_rsa"  # Path to your private SSH key
```

The key path is included in the generated JSON and used by Termix for authentication. Ensure:

- The key exists on your Termix device
- The key can authenticate as `root` on all containers
- The key is added to each container's `/root/.ssh/authorized_keys`

### Customize Per-Host Variables

Edit `inventory/prod/proxmox/termix/group_vars/all.yml` to change defaults:

```yaml
termix_folder: "Production" # Change default folder
termix_key_path: "~/.ssh/id_rsa" # SSH key for authentication
termix_tags:
  - "homelab"
  - "managed"
termix_docker: true # Enable Docker for all hosts
```

For **per-host overrides**, create `host_vars/`:

```bash
mkdir -p ansible/inventory/prod/proxmox/termix/host_vars
```

Then create files like `host_vars/container-name.yml`:

```yaml
---
termix_name: "My Custom Name"
termix_folder: "Special Folder"
termix_key_path: "~/.ssh/id_ed25519"  # Different key for this host
termix_docker: true
termix_tags:
  - "docker-enabled"
  - "critical"
```

### Customize Proxmox Filters

Edit `pve.proxmox.yml` to change what containers are discovered:

```yaml
filters:
  - proxmox_status == "running"
  - proxmox_tags_parsed[0] == "termix" # Only containers tagged "termix"
```

Useful filter examples:

- `proxmox_node == "pve"` — Only from a specific PVE node
- `proxmox_type == "lxc"` — Only containers (not VMs)
- `proxmox_tags_parsed[0] is match('^prod.*')` — Tags matching a regex

## Output Format

The generated `termix-hosts.json` follows the [Termix import format](https://docs.termix.site/json-import/):

```json
{
  "hosts": [
    {
      "name": "container-name",
      "ip": "192.168.1.100",
      "port": 22,
      "username": "root",
      "authType": "key",
      "key": "~/.ssh/id_rsa",
      "folder": "Homelab",
      "tags": ["proxmox", "homelab"],
      "enableTerminal": true,
      "enableFileManager": true,
      "enableDocker": false
    }
  ]
}
```

## Importing into Termix

1. **Generate the JSON file** (see Usage above)
   - Generated file location: `ansible/inventory/prod/proxmox/termix/termix-hosts.json`
2. **Log in to Termix** at `https://termix.grumples.home`
3. **Go to Settings → Import**
4. **Upload** the JSON file or paste its contents
5. **Confirm** the import preview
6. **Click Import** to add all hosts

## Troubleshooting

### "Proxmox credentials not set"

```bash
# Set your credentials
export PROXMOX_URL=https://<your proxmox domain name>:8006
export PROXMOX_TOKEN_ID=ansible@pam!mytoken
export PROXMOX_TOKEN_SECRET=<uuid>

# Or use API endpoint to test connectivity
curl -k -X GET "${PROXMOX_URL}/api2/json/nodes" \
  -H "Authorization: PVEAPIToken=${PROXMOX_TOKEN_ID}:${PROXMOX_TOKEN_SECRET}"
```

### "No inventory found"

```bash
# Verify the file exists
ls -la ansible/inventory/prod/proxmox/termix/pve.proxmox.yml
```

### "Empty hosts list in JSON"

The dynamic inventory may have returned no hosts. Verify:

- Containers are **running** (filter checks `proxmox_status == "running"`)
- You have permission to read them (check Proxmox user/token permissions)
- IPs are discoverable (QEMU guest agent, static config, or dhcp)

Debug with:

```bash
ansible-inventory \
  -i ansible/inventory/prod/proxmox/termix/pve.proxmox.yml \
  --list | jq '.all.hosts'
```

### "SSH key authentication fails"

The generated JSON includes the SSH key path in the `"key"` field. Ensure:

1. The SSH key exists at the path specified by `termix_key_path` (default: `~/.ssh/id_rsa`)
2. The key can authenticate as `root` on all containers
3. The public key is in `/root/.ssh/authorized_keys` on each container

If using password authentication instead:

1. Change `termix_auth_type: "password"` in `group_vars/all.yml`
2. Remove the `key` field from the template (or update it to include password field)
3. Configure password authentication in Termix when importing

## Next Steps

- Monitor containers in Termix dashboard
- Set up SSH key forwarding if not already done
- Use Termix tags to organize containers by environment (prod/dev)
- Enable Docker metrics scraping for container monitoring
