#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização de Buckets no MinIO
# ==============================================================================
set -euo pipefail

MINIO_HOST="${MINIO_HOST:-localhost}"
MINIO_PORT="${MINIO_PORT:-9000}"
MINIO_USER="${MINIO_ROOT_USER:-admin_lakehouse}"
MINIO_PASSWORD="${MINIO_ROOT_PASSWORD:-lakehouse_secret_key}"
BUCKET_NAME="${MINIO_BUCKET_NAME:-lakehouse-audit}"

echo "=== Configurando Buckets MinIO em http://${MINIO_HOST}:${MINIO_PORT} ==="

mc alias set localminio "http://${MINIO_HOST}:${MINIO_PORT}" "${MINIO_USER}" "${MINIO_PASSWORD}"
mc mb --ignore-existing "localminio/${BUCKET_NAME}"
mc anonymous set download "localminio/${BUCKET_NAME}"

echo "[OK] Bucket '${BUCKET_NAME}' pronto para uso."
