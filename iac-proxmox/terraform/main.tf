terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# LXC 101 - Origem Transacional (PostgreSQL)
resource "proxmox_lxc" "lxc_101_origem" {
  target_node  = var.proxmox_node
  vmid         = 101
  hostname     = "lxc-origem-pg"
  ostemplate   = var.ubuntu_template
  unprivileged = true
  start        = true

  cores  = 4
  memory = 8192
  swap   = 2048

  rootfs {
    storage = var.storage_pool
    size    = "50G"
  }

  network {
    name   = "eth0"
    bridge = var.bridge_interface
    ip     = "192.168.1.110/24"
    gw     = var.gateway_ip
  }

  nameserver = var.dns_server
  password   = var.default_password
  ssh_public_keys = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : null
}

# LXC 102 - Ingestão e Processamento (Kafka, Debezium, Spark)
resource "proxmox_lxc" "lxc_102_ingestao" {
  target_node  = var.proxmox_node
  vmid         = 102
  hostname     = "lxc-ingestao-spark"
  ostemplate   = var.ubuntu_template
  unprivileged = true
  start        = true

  cores  = 8
  memory = 24576
  swap   = 4096

  rootfs {
    storage = var.storage_pool
    size    = "100G"
  }

  network {
    name   = "eth0"
    bridge = var.bridge_interface
    ip     = "192.168.1.120/24"
    gw     = var.gateway_ip
  }

  features {
    nesting = true
    keyctl  = true
  }

  nameserver = var.dns_server
  password   = var.default_password
  ssh_public_keys = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : null
}

# LXC 103 - Camada de Persistência (MinIO, HDFS, NFS)
resource "proxmox_lxc" "lxc_103_storage" {
  target_node  = var.proxmox_node
  vmid         = 103
  hostname     = "lxc-storage-lakehouse"
  ostemplate   = var.ubuntu_template
  unprivileged = true
  start        = true

  cores  = 8
  memory = 32768
  swap   = 8192

  rootfs {
    storage = var.storage_pool
    size    = "300G"
  }

  network {
    name   = "eth0"
    bridge = var.bridge_interface
    ip     = "192.168.1.130/24"
    gw     = var.gateway_ip
  }

  features {
    nesting = true
    keyctl  = true
  }

  nameserver = var.dns_server
  password   = var.default_password
  ssh_public_keys = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : null
}
