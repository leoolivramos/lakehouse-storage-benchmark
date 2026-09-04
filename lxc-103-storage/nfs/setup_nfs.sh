#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação e Configuração do Servidor NFS no LXC 103 (Ubuntu 24.04)
# PoC de Auditoria Contínua - Nó LXC 103 (Storage)
# ==============================================================================
set -euo pipefail

EXPORT_DIR="${1:-/data/lakehouse-nfs}"
ALLOWED_NETWORK="${2:-192.168.1.0/24}"

echo "=== Configurando Servidor NFS no LXC 103 ==="

if [[ $EUID -ne 0 ]]; then
   echo "[ERRO] Este script deve ser executado como root." 
   exit 1
fi

echo "1. Instalando pacote nfs-kernel-server..."
apt-get update && apt-get install -y nfs-kernel-server

echo "2. Criando diretório de persistência: ${EXPORT_DIR}..."
mkdir -p "${EXPORT_DIR}"
chown -R nobody:nogroup "${EXPORT_DIR}"
chmod 777 "${EXPORT_DIR}"

echo "3. Configurando /etc/exports..."
EXPORT_LINE="${EXPORT_DIR} ${ALLOWED_NETWORK}(rw,sync,no_subtree_check,no_root_squash,insecure)"

if ! grep -q "${EXPORT_DIR}" /etc/exports 2>/dev/null; then
    echo "${EXPORT_LINE}" >> /etc/exports
else
    echo "Diretório já presente no /etc/exports."
fi

echo "4. Aplicando exportações e reiniciando o serviço NFS..."
exportfs -rav
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

echo "=== Servidor NFS Configurado com Sucesso ==="
exportfs -v
