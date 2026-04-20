#!/bin/bash
# Generate Termix JSON import file from Proxmox dynamic inventory
# Usage: ./generate-termix-import.sh [inventory-path]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default inventory path
INVENTORY_PATH="${1:-$REPO_ROOT/ansible/inventory/prod/proxmox/termix}"

# Validate that pve.proxmox.yml exists
if [[ ! -f "$INVENTORY_PATH/pve.proxmox.yml" ]]; then
    echo "❌ Error: Proxmox inventory not found at $INVENTORY_PATH/pve.proxmox.yml"
    exit 1
fi

# Check that required environment variables are set for Proxmox auth
if [[ -z "$PROXMOX_URL" && -z "$PROXMOX_TOKEN_ID" ]]; then
    echo "❌ Error: Proxmox credentials not set."
    echo "   Either set PROXMOX_PASSWORD + PROXMOX_USER + PROXMOX_URL"
    echo "   Or set PROXMOX_TOKEN_SECRET + PROXMOX_TOKEN_ID + PROXMOX_URL"
    exit 1
fi

echo "📋 Generating Termix JSON import file..."
echo "   Inventory: $INVENTORY_PATH"

cd "$REPO_ROOT/ansible"

# Run the playbook
ansible-playbook \
    -i "$INVENTORY_PATH/pve.proxmox.yml" \
    generate-termix-json.yml

echo ""
echo "✅ Done! JSON file generated at:"
echo "   $INVENTORY_PATH/termix-hosts.json"
echo ""
echo "📥 Next steps:"
echo "   1. Review the generated termix-hosts.json file"
echo "   2. Log in to Termix at https://termix.grumples.home"
echo "   3. Go to Settings → Import"
echo "   4. Upload termix-hosts.json or paste its contents"
