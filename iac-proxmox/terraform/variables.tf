variable "proxmox_api_url" {
  description = "URL da API do Proxmox VE (ex: https://192.168.1.2:8006/api2/json)"
  type        = string
  default     = "https://192.168.1.2:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "ID do Token de API do Proxmox (ex: root@pam!terraform)"
  type        = string
  default     = "root@pam!terraform"
}

variable "proxmox_api_token_secret" {
  description = "Secret do Token de API do Proxmox"
  type        = string
  sensitive   = true
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "proxmox_tls_insecure" {
  description = "Desabilita checagem de certificado SSL autoassinado"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Nome do nó físico Proxmox VE"
  type        = string
  default     = "pve"
}

variable "storage_pool" {
  description = "Pool de armazenamento para os discos dos contêineres"
  type        = string
  default     = "local-lvm"
}

variable "ubuntu_template" {
  description = "Caminho do template Ubuntu 24.04 LTS"
  type        = string
  default     = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "bridge_interface" {
  description = "Interface de rede bridge privada"
  type        = string
  default     = "vmbr0"
}

variable "gateway_ip" {
  description = "Gateway da rede privada"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_server" {
  description = "Servidor DNS"
  type        = string
  default     = "192.168.1.1"
}

variable "default_password" {
  description = "Senha padrão do usuário root nos contêineres"
  type        = string
  sensitive   = true
  default     = "ProxmoxTCC2026!"
}

variable "ssh_public_key_path" {
  description = "Caminho local da chave pública SSH para injeção nos contêineres"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
