provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

resource "proxmox_virtual_environment_container" "open-webui-container" {
  node_name    = var.proxmox_node
  unprivileged = true
  features {
    nesting = true
  }
  initialization {
    hostname = "open-webui-dev"
    user_account {
      password = var.proxmox_host_default_pwd
    }
    ip_config {
      ipv4 {
        address = "${var.static_ips.open_webui}/24"
        gateway = var.gateway
      }
    }
  }
  network_interface {
    name = "eth0"
  }
  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }
  disk {
    datastore_id = var.file-system
    size         = 10
  }
  cpu {
    cores = 1
  }
  memory {
    dedicated = 1024
    swap      = 512
  }
}

resource "proxmox_virtual_environment_container" "searxng-container" {
  node_name    = var.proxmox_node
  unprivileged = true
  features {
    nesting = true
  }
  initialization {
    hostname = "searxng-dev"
    user_account {
      password = var.proxmox_host_default_pwd
    }
    ip_config {
      ipv4 {
        address = "${var.static_ips.searxng}/24"
        gateway = var.gateway
      }
    }
  }
  network_interface {
    name = "eth0"
  }
  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }
  disk {
    datastore_id = var.file-system
    size         = 8
  }
  cpu {
    cores = 1
  }
  memory {
    dedicated = 512
    swap      = 256
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../../../../ansible/inventory/dev/proxmox/openwebui-searxng/inventory.tpl", {
    containers = {
      "open-webui" = split("/", proxmox_virtual_environment_container.open-webui-container.initialization[0].ip_config[0].ipv4[0].address)[0]
      "searxng"    = split("/", proxmox_virtual_environment_container.searxng-container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
    ollama_host = var.ollama_host
  })
  filename = "${path.module}/../../../../../ansible/inventory/dev/proxmox/openwebui-searxng/inventory.ini"
}
