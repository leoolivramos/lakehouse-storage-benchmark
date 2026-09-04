#!/usr/bin/env bash
# ==============================================================================
# Script de Registro e Validação do Conector Debezium PostgreSQL via REST API
# PoC de Auditoria Contínua - Nó LXC 102 (Ingestão)
# ==============================================================================
set -euo pipefail

DEBEZIUM_HOST="${DEBEZIUM_HOST:-localhost}"
DEBEZIUM_PORT="${DEBEZIUM_PORT:-8083}"
CONNECTOR_NAME="postgres-audit-connector"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/postgres-connector.json"

echo "=== Registrando Conector CDC no Debezium Connect (${DEBEZIUM_HOST}:${DEBEZIUM_PORT}) ==="

# 1. Aguarda a disponibilidade da API REST do Debezium
echo "Aguardando o serviço Debezium Connect responder..."
until curl -s -o /dev/null -w "%{http_code}" "http://${DEBEZIUM_HOST}:${DEBEZIUM_PORT}/connectors" | grep -q "200"; do
    echo "Debezium Connect ainda indisponível. Aguardando 5 segundos..."
    sleep 5
done
echo "[OK] Debezium Connect operacional."

# 2. Resolução de variáveis de ambiente no JSON de configuração
POSTGRES_HOST="${POSTGRES_HOST:-192.168.1.110}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

RENDERED_CONFIG=$(sed -e "s/\${POSTGRES_HOST:-192.168.1.110}/${POSTGRES_HOST}/g" \
                      -e "s/\${POSTGRES_PORT:-5432}/${POSTGRES_PORT}/g" \
                      "${CONFIG_FILE}")

# 3. Verifica se o conector já existe
EXISTING=$(curl -s "http://${DEBEZIUM_HOST}:${DEBEZIUM_PORT}/connectors/${CONNECTOR_NAME}" | grep -o '"name":' || true)

if [ -n "${EXISTING}" ]; then
    echo "Conector ${CONNECTOR_NAME} já existe. Atualizando configuração..."
    CONFIG_PAYLOAD=$(echo "${RENDERED_CONFIG}" | grep -v '"name":' | sed '1s/{//' | sed '$s/}//')
    # Extrai apenas o objeto config para o endpoint PUT
    CONFIG_ONLY=$(python3 -c "import sys, json; print(json.dumps(json.loads(sys.stdin.read())['config']))" <<< "${RENDERED_CONFIG}")
    curl -i -X PUT -H "Content-Type: application/json" \
         --data "${CONFIG_ONLY}" \
         "http://${DEBEZIUM_HOST}:${DEBEZIUM_PORT}/connectors/${CONNECTOR_NAME}/config"
else
    echo "Registrando novo conector ${CONNECTOR_NAME}..."
    curl -i -X POST -H "Content-Type: application/json" \
         --data "${RENDERED_CONFIG}" \
         "http://${DEBEZIUM_HOST}:${DEBEZIUM_PORT}/connectors"
fi

echo -e "\n=== Status do Conector ==="
curl -s "http://${DEBEZIUM_HOST}:${DEBEZIUM_PORT}/connectors/${CONNECTOR_NAME}/status" | python3 -m json.tool || true
