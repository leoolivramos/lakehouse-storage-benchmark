#!/usr/bin/env python3
"""
Suíte de Execução de Benchmark de Ingestão Contínua (CDC)
Mede vazão, latência ponta a ponta e taxa de entrega de eventos CDC.
Autor: Leonardo Ramos (TCC UFMT)
"""

import os
import sys
import time
import json
import statistics
from datetime import datetime
import psycopg2
from kafka import KafkaConsumer

# Configurações
PG_HOST = os.getenv("POSTGRES_HOST", "localhost")
PG_PORT = int(os.getenv("POSTGRES_PORT", 5432))
PG_DB = os.getenv("POSTGRES_DB", "gestao_publica")
PG_USER = os.getenv("POSTGRES_USER", "postgres")
PG_PASS = os.getenv("POSTGRES_PASSWORD", "postgres_secure_pwd")

KAFKA_HOST = os.getenv("KAFKA_HOST", "localhost")
KAFKA_PORT = os.getenv("KAFKA_PORT", "9092")
KAFKA_BOOTSTRAP = f"{KAFKA_HOST}:{KAFKA_PORT}"
TOPIC = "lakehouse.public.empenhos"

def run_e2e_latency_test(num_events=200):
    print(f"\n=== Iniciando Teste de Latência Ponta a Ponta ({num_events} eventos) ===")
    print(f"PostgreSQL: {PG_HOST}:{PG_PORT} | Kafka: {KAFKA_BOOTSTRAP} | Tópico: {TOPIC}")

    try:
        conn = psycopg2.connect(host=PG_HOST, port=PG_PORT, dbname=PG_DB, user=PG_USER, password=PG_PASS)
        conn.autocommit = True
        cur = conn.cursor()
    except Exception as e:
        print(f"[ERRO] Falha ao conectar no PostgreSQL: {e}")
        return

    try:
        consumer = KafkaConsumer(
            TOPIC,
            bootstrap_servers=[KAFKA_BOOTSTRAP],
            auto_offset_reset="latest",
            enable_auto_commit=True,
            value_deserializer=lambda x: json.loads(x.decode("utf-8")),
            consumer_timeout_ms=10000
        )
    except Exception as e:
        print(f"[ERRO] Falha ao conectar no Kafka: {e}")
        return

    latencies_ms = []
    print("Enviando transações e medindo tempo até chegada no Kafka...")

    for i in range(1, num_events + 1):
        num_emp = f"BENCH_{int(time.time()*1000)}_{i}"
        val = 1000.0 + i

        t_insert_start = time.time()
        # Inserção no PostgreSQL
        cur.execute("""
            INSERT INTO empenhos (numero_empenho, ano_exercicio, orgao_id, credor_id, modalidade_licitacao, numero_processo, valor_empenhado, descricao_objeto, status)
            VALUES (%s, 2026, 1, 1, 'PREGÃO', 'BENCH-01', %s, 'Benchmark CDC Latency Test', 'EMITIDO')
            RETURNING id;
        """, (num_emp, val))
        t_db_committed = time.time()

        # Consumo da mensagem correspondente no Kafka
        found = False
        t_deadline = time.time() + 10.0
        while time.time() < t_deadline:
            msg_pack = consumer.poll(timeout_ms=500)
            for tp, messages in msg_pack.items():
                for msg in messages:
                    payload = msg.value
                    after = payload.get("after") or {}
                    if after.get("numero_empenho") == num_emp:
                        t_kafka_received = time.time()
                        # Latência calculada a partir do momento do commit até o recebimento no broker
                        latency = (t_kafka_received - t_db_committed) * 1000.0
                        latencies_ms.append(latency)
                        found = True
                        break
                if found:
                    break
            if found:
                break

        if not found:
            print(f"[AVISO] Timeout aguardando evento {num_emp}")

        if i % 25 == 0:
            current_avg = statistics.mean(latencies_ms) if latencies_ms else 0
            print(f"Progresso: {i}/{num_events} | Latência Média Atual: {current_avg:.2f} ms")

    cur.close()
    conn.close()
    consumer.close()

    if latencies_ms:
        print("\n=== Resultados da Avaliação de Latência CDC ===")
        print(f"Total de Amostras: {len(latencies_ms)}")
        print(f"Latência Mínima:   {min(latencies_ms):.2f} ms")
        print(f"Latência Média:    {statistics.mean(latencies_ms):.2f} ms")
        print(f"Latência Mediana:  {statistics.median(latencies_ms):.2f} ms")
        print(f"Percentil 95 (P95):{statistics.quantiles(latencies_ms, n=20)[18]:.2f} ms")
        print(f"Percentil 99 (P99):{statistics.quantiles(latencies_ms, n=100)[98]:.2f} ms")
        print(f"Latência Máxima:   {max(latencies_ms):.2f} ms")

        # Salva resultados em JSON
        res = {
            "benchmark": "cdc_end_to_end_latency",
            "samples": len(latencies_ms),
            "min_ms": round(min(latencies_ms), 2),
            "mean_ms": round(statistics.mean(latencies_ms), 2),
            "median_ms": round(statistics.median(latencies_ms), 2),
            "p95_ms": round(statistics.quantiles(latencies_ms, n=20)[18], 2),
            "p99_ms": round(statistics.quantiles(latencies_ms, n=100)[98], 2),
            "max_ms": round(max(latencies_ms), 2),
            "timestamp": datetime.utcnow().isoformat()
        }
        with open("benchmark_latency_results.json", "w", encoding="utf-8") as f:
            json.dump(res, f, indent=2)
        print("Resultados salvos em 'benchmark_latency_results.json'.")

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    run_e2e_latency_test(num_events=n)
