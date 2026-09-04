#!/usr/bin/env bash
# ==============================================================================
# Script de Provisionamento IaC para Proxmox VE 9.1.7
# PoC de Auditoria Contínua baseada em CDC e Persistência Lakehouse
# Autor: Leonardo Ramos (TCC UFMT)
# ==============================================================================
set -euo pipefail

# Cores para feedback no terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}===================================================================${NC}"
echo -e "${BLUE} Proxmox VE IaC - Provisionamento dos Contêineres LXC do Experimento${NC}"
echo -e "${BLUE}===================================================================${NC}"

# Validação de execução no Proxmox como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERRO] Este script deve ser executado como root diretamente no host Proxmox VE.${NC}" 
   exit 1
fi

# Configurações do Ambiente e Template
STORAGE_POOL="${STORAGE_POOL:-local-lvm}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
UBUNTU_TEMPLATE="${UBUNTU_TEMPLATE:-ubuntu-24.04-standard_24.04-2_amd64.tar.zst}"
BRIDGE_NET="${BRIDGE_NET:-vmbr0}"
GATEWAY="${GATEWAY:-192.168.1.1}"
DNS="${DNS:-192.168.1.1}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-ProxmoxTCC2026!}"
SSH_PUB_KEY="${SSH_PUB_KEY:-/root/.ssh/id_rsa.pub}"

# 1. Download do Template Ubuntu 24.04 LTS caso não exista
echo -e "\n${YELLOW}[1/4] Verificando existência do template Ubuntu 24.04 LTS...${NC}"
if ! pveam list "${TEMPLATE_STORAGE}" | grep -q "${UBUNTU_TEMPLATE}"; then
    echo -e "Atualizando lista de templates de contêineres..."
    pveam update
    echo -e "Baixando template ${UBUNTU_TEMPLATE}..."
    pveam download "${TEMPLATE_STORAGE}" "${UBUNTU_TEMPLATE}"
else
    echo -e "${GREEN}Template encontrado em ${TEMPLATE_STORAGE}:${UBUNTU_TEMPLATE}.${NC}"
fi

TEMPLATE_PATH="${TEMPLATE_STORAGE}:vztmpl/${UBUNTU_TEMPLATE}"

# Função para criar e configurar contêiner LXC
provision_lxc() {
    local CT_ID=$1
    local CT_HOSTNAME=$2
    local CT_CORES=$3
    local CT_RAM=$4
    local CT_SWAP=$5
    local CT_DISK=$6
    local CT_IP=$7
    local ENABLE_NESTING=$8

    echo -e "\n${YELLOW}Provisionando LXC ${CT_ID} (${CT_HOSTNAME})...${NC}"

    if pct status "${CT_ID}" &>/dev/null; then
        echo -e "${YELLOW}Aviso: O contêiner ${CT_ID} já existe. Pulando criação...${NC}"
        return 0
    fi

    # Criação do LXC
    pct create "${CT_ID}" "${TEMPLATE_PATH}" \
        --hostname "${CT_HOSTNAME}" \
        --cores "${CT_CORES}" \
        --memory "${CT_RAM}" \
        --swap "${CT_SWAP}" \
        --rootfs "${STORAGE_POOL}:${CT_DISK}" \
        --net0 "name=eth0,bridge=${BRIDGE_NET},ip=${CT_IP}/24,gw=${GATEWAY}" \
        --nameserver "${DNS}" \
        --ostype ubuntu \
        --password "${DEFAULT_PASSWORD}" \
        --unprivileged 1 \
        --start 0

    # Habilitação de Nesting e Keyctl (necessário para execução do Docker Engine dentro de LXC não-privilegiado)
    if [[ "${ENABLE_NESTING}" == "true" ]]; then
        echo -e "Configurando recursos de conteinerização (nesting=1, keyctl=1)..."
        pct set "${CT_ID}" --features nesting=1,keyctl=1
    fi

    # Injeção de chave pública SSH (se existir)
    if [[ -f "${SSH_PUB_KEY}" ]]; then
        echo -e "Adicionando chave pública SSH..."
        pct push "${CT_ID}" "${SSH_PUB_KEY}" /root/.ssh/authorized_keys -perms 600 || true
    fi

    echo -e "Iniciando contêiner ${CT_ID}..."
    pct start "${CT_ID}"
    
    # Aguarda inicialização de rede
    sleep 5

    echo -e "${GREEN}LXC ${CT_ID} (${CT_HOSTNAME}) inicializado com sucesso em ${CT_IP}.${NC}"
}

# ==============================================================================
# Provisionamento dos nós conforme definido no TCC:
# LXC 101: Origem Transacional (4 vCPUs, 8 GB RAM, 50 GB Disco)
# LXC 102: Ingestão e Processamento (8 vCPUs, 24 GB RAM, 100 GB Disco, Docker)
# LXC 103: Camada de Persistência (8 vCPUs, 32 GB RAM, 300 GB Disco, Docker/Storage)
# ==============================================================================

echo -e "\n${YELLOW}[2/4] Criando contêineres conforme dimensionamento experimental...${NC}"

# LXC 101: Origem Transacional
provision_lxc 101 "lxc-origem-pg" 4 8192 2048 50 "192.168.1.110" "false"

# LXC 102: Ingestão e Processamento
provision_lxc 102 "lxc-ingestao-spark" 8 24576 4096 100 "192.168.1.120" "true"

# LXC 103: Persistência / Storage
provision_lxc 103 "lxc-storage-lakehouse" 8 32768 8192 300 "192.168.1.130" "true"

# ==============================================================================
# Instalação automatizada do Docker Engine no LXC 102 e LXC 103
# ==============================================================================
echo -e "\n${YELLOW}[3/4] Instalando pacotes básicos e Docker Engine nos nós 102 e 103...${NC}"

install_docker_in_lxc() {
    local CT_ID=$1
    echo -e "Instalando Docker Engine no LXC ${CT_ID}..."
    pct exec "${CT_ID}" -- bash -c "
        apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release htop iotop net-tools
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    "
    echo -e "${GREEN}Docker Engine instalado com sucesso no LXC ${CT_ID}.${NC}"
}

install_docker_in_lxc 102
install_docker_in_lxc 103

# Instalação do PostgreSQL nativo ou dependências no LXC 101
echo -e "\n${YELLOW}[4/4] Preparando LXC 101 (Origem Transacional)...${NC}"
pct exec 101 -- bash -c "
    apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release postgresql-common htop iotop
    install -d /etc/apt/keyrings
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg --yes
    echo 'deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main' | tee /etc/apt/sources.list.d/pgdg.list
    apt-get update
    apt-get install -y postgresql-16 postgresql-client-16
"

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} Provisionamento concluído com sucesso!${NC}"
echo -e "${GREEN} Nós provisionados na rede ${SUBNET_CIDR}:${NC}"
echo -e "${GREEN} - LXC 101: 192.168.1.110 (PostgreSQL 16)${NC}"
echo -e "${GREEN} - LXC 102: 192.168.1.120 (Kafka, Debezium, Spark)${NC}"
echo -e "${GREEN} - LXC 103: 192.168.1.130 (MinIO, HDFS, NFS)${NC}"
echo -e "${GREEN}===================================================================${NC}"
