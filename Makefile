# ==============================================================================
# Makefile - Orquestração e Reprodutibilidade da PoC do TCC
# PoC de Auditoria Contínua baseada em CDC e Persistência Lakehouse
# Autor: Leonardo Ramos (UFMT)
# ==============================================================================

SHELL := /bin/bash
COMPOSE_ALL := docker compose -f docker-compose.all-in-one.yml
PYTHON := python3

.PHONY: help setup start-all-in-one stop-all-in-one register-cdc simulate benchmark evaluate plot clean

help:
	@echo "====================================================================="
	@echo "    PoC Auditoria Contínua & Benchmark de Persistência Lakehouse     "
	@echo "====================================================================="
	@echo "Comandos disponíveis:"
	@echo "  make setup              - Cria arquivos .env e valida pré-requisitos"
	@echo "  make start-all-in-one   - Sobe todos os contêineres em modo unificado"
	@echo "  make stop-all-in-one    - Para e remove contêineres do modo unificado"
	@echo "  make register-cdc       - Registra conector PostgreSQL no Debezium"
	@echo "  make simulate           - Executa simulador de transações governamentais"
	@echo "  make benchmark          - Roda teste de latência ponta a ponta (CDC)"
	@echo "  make evaluate           - Calcula estatísticas e gera tabela LaTeX"
	@echo "  make plot               - Gera gráficos de desempenho em PNG/PDF"
	@echo "  make clean              - Limpa artefatos temporários e métricas"
	@echo "====================================================================="

setup:
	@if [ ! -f .env ]; then cp .env.example .env && echo "[OK] Arquivo .env criado a partir de .env.example"; fi
	@echo "[OK] Ambiente preparado."

start-all-in-one: setup
	$(COMPOSE_ALL) up -d
	@echo "Aguardando inicialização dos serviços..."
	@sleep 15
	@$(MAKE) register-cdc

stop-all-in-one:
	$(COMPOSE_ALL) down -v

register-cdc:
	@echo "Registrando conector CDC no Debezium..."
	DEBEZIUM_HOST=localhost DEBEZIUM_PORT=8083 POSTGRES_HOST=postgres POSTGRES_PORT=5432 bash lxc-102-ingestao/connectors/register_postgres_cdc.sh

simulate:
	@echo "Iniciando simulação de mutações transacionais..."
	$(PYTHON) lxc-101-origem/scripts/simulate_workload.py

benchmark:
	@echo "Executando benchmark de latência ponta a ponta..."
	$(PYTHON) benchmark/run_benchmark.py 100

evaluate:
	@echo "Gerando análise comparativa e tabela LaTeX..."
	$(PYTHON) benchmark/evaluate_persistence.py

plot:
	@echo "Gerando figuras acadêmicas..."
	$(PYTHON) benchmark/plot_results.py

clean:
	rm -f benchmark_latency_results.json tabela_resultados_tcc.tex grafico_benchmark_persistencia.png grafico_benchmark_persistencia.pdf
	@echo "[OK] Artefatos temporários removidos."
