provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

resource "proxmox_virtual_environment_container" "minio-container" {
  node_name    = var.proxmox_node
  unprivileged = true
  features {
    nesting = true
  }
  initialization {
    hostname = "minio-dev"
    user_account {
      password = var.proxmox_host_default_pwd
    }
    ip_config {
      ipv4 {
        address = "${var.static_ip}/24"
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
    dedicated = 512
    swap      = 256
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../../../../ansible/inventory/dev/proxmox/minio/inventory.tpl", {
    ip                  = split("/", proxmox_virtual_environment_container.minio-container.initialization[0].ip_config[0].ipv4[0].address)[0]
    minio_root_user     = var.minio_root_user
    minio_root_password = var.minio_root_password
  })
  filename = "${path.module}/../../../../../ansible/inventory/dev/proxmox/minio/inventory.ini"
}
