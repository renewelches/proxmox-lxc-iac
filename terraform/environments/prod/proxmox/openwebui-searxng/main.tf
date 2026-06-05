provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

resource "proxmox_virtual_environment_container" "open-webui-container" {
  node_name = var.proxmox_nodes.openwebui
  tags      = ["open-webui", "ai", "docker"]

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "open-webui"

    user_account {
      password = var.proxmox_host_default_pwd
    }

    ip_config {
      ipv4 {
        address = "${var.static_ips.open_webui}/24" #fixed IP address
        #address = "dhcp"
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = var.network_interface_name
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  disk {
    datastore_id = var.file-system
    size         = var.openwebui_disk_size
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = var.openwebui_memory_dedicated
    swap      = var.openwebui_memory_swap
  }

}

resource "proxmox_virtual_environment_container" "searxng-container" {
  node_name = var.proxmox_nodes.searxng
  tags      = ["searxng", "search", "docker"]

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "searxng"

    user_account {
      password = var.proxmox_host_default_pwd
    }

    ip_config {
      ipv4 {
        address = "${var.static_ips.searxng}/24"
        #address = "dhcp"
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = var.network_interface_name
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  disk {
    datastore_id = var.file-system
    size         = var.searxng_disk_size
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = var.searxng_memory_dedicated
    swap      = var.searxng_memory_swap
  }
}



resource "proxmox_replication" "open-webui" {
  count    = var.enable_replication ? 1 : 0
  id       = "${proxmox_virtual_environment_container.open-webui-container.vm_id}-0"
  type     = "local"
  target   = var.replication_target
  schedule = "*/15"
}

resource "proxmox_replication" "searxng" {
  count    = var.enable_replication ? 1 : 0
  id       = "${proxmox_virtual_environment_container.searxng-container.vm_id}-0"
  type     = "local"
  target   = var.replication_target
  schedule = "*/15"
}

# Generate Ansible inventory from container IPs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../../../../ansible/inventory/prod/proxmox/openwebui-searxng/inventory.tpl", {
    containers = {
      "open-webui" = split("/", proxmox_virtual_environment_container.open-webui-container.initialization[0].ip_config[0].ipv4[0].address)[0]
      "searxng"    = split("/", proxmox_virtual_environment_container.searxng-container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
    ollama_host = var.ollama_host
  })
  filename = "${path.module}/../../../../../ansible/inventory/prod/proxmox/openwebui-searxng/inventory.ini"
}

