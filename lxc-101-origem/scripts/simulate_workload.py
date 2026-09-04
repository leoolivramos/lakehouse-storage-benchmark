#!/usr/bin/env python3
"""
Simulador de Carga Transacional Governamental (Workload Generator)
Gera inserções, atualizações e estornos contínuos no PostgreSQL para estressar a esteira CDC.
Autor: Leonardo Ramos (TCC UFMT)
"""

import os
import sys
import time
import random
import psycopg2
from datetime import datetime

# Configurações de Conexão com o PostgreSQL
DB_HOST = os.getenv("POSTGRES_HOST", "192.168.1.110")
DB_PORT = int(os.getenv("POSTGRES_PORT", 5432))
DB_NAME = os.getenv("POSTGRES_DB", "gestao_publica")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "postgres_secure_pwd")

def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

def generate_random_empenho(conn, cur, iteration):
    ano = 2026
    num_empenho = f"2026NE{random.randint(100000, 999999)}"
    orgao_id = random.randint(1, 5)
    credor_id = random.randint(1, 5)
    modalidade = random.choice(["PREGÃO ELETRÔNICO", "CONCORRÊNCIA", "DISPENSA DE LICITAÇÃO", "INEXIGIBILIDADE"])
    processo = f"PRO-{random.randint(10000, 99999)}/{ano}"
    valor = round(random.uniform(5000.0, 500000.0), 2)
    descricao = f"Despesa gerada pelo simulador contínuo - Lote {iteration} empenho {num_empenho}"

    cur.execute("""
        INSERT INTO empenhos (numero_empenho, ano_exercicio, orgao_id, credor_id, modalidade_licitacao, numero_processo, valor_empenhado, descricao_objeto, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'EMITIDO')
        RETURNING id;
    """, (num_empenho, ano, orgao_id, credor_id, modalidade, processo, valor, descricao))
    empenho_id = cur.fetchone()[0]

    # Simula se haverá liquidação imediata (80% chance)
    if random.random() < 0.8:
        num_liq = f"2026NL{random.randint(100000, 999999)}"
        num_nf = f"NFE-{random.randint(10000, 99999)}"
        cur.execute("""
            INSERT INTO liquidacoes (numero_liquidacao, empenho_id, valor_liquidado, numero_nota_fiscal, atestado_por)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id;
        """, (num_liq, empenho_id, valor, num_nf, f"Fiscal Matrícula {random.randint(1000, 9999)}"))
        liq_id = cur.fetchone()[0]

        cur.execute("UPDATE empenhos SET status = 'LIQUIDADO', atualizado_em = CURRENT_TIMESTAMP WHERE id = %s;", (empenho_id,))

        # Simula se haverá pagamento (70% das liquidadas)
        if random.random() < 0.7:
            num_ob = f"2026OB{random.randint(100000, 999999)}"
            cur.execute("""
                INSERT INTO pagamentos (numero_ordem_bancaria, liquidacao_id, valor_pago, status)
                VALUES (%s, %s, %s, 'EFETIVADO');
            """, (num_ob, liq_id, valor))
            cur.execute("UPDATE empenhos SET status = 'PAGO', atualizado_em = CURRENT_TIMESTAMP WHERE id = %s;", (empenho_id,))

    conn.commit()
    return num_empenho, valor

def main():
    rate = float(os.getenv("RATE_PER_SEC", 10.0)) # taxa de transações por segundo
    total_events = int(os.getenv("TOTAL_EVENTS", 1000))
    delay = 1.0 / rate if rate > 0 else 0.1

    print(f"=== Iniciando Gerador de Carga Transacional (PostgreSQL CDC) ===")
    print(f"Destino: {DB_HOST}:{DB_PORT}/{DB_NAME}")
    print(f"Alvo: {total_events} transações @ ~{rate} eventos/s")

    try:
        conn = get_connection()
        cur = conn.cursor()
        print("[OK] Conexão com PostgreSQL estabelecida com sucesso.")
    except Exception as e:
        print(f"[ERRO] Falha ao conectar no banco: {e}")
        sys.exit(1)

    start_time = time.time()
    for i in range(1, total_events + 1):
        try:
            num_emp, val = generate_random_empenho(conn, cur, i)
            if i % 50 == 0 or i == total_events:
                elapsed = time.time() - start_time
                avg_eps = i / elapsed if elapsed > 0 else 0
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Transações emitidas: {i}/{total_events} | Vazão média: {avg_eps:.2f} tx/s | Último empenho: {num_emp} (R$ {val:,.2f})")
            time.sleep(delay)
        except KeyboardInterrupt:
            print("\nExecução interrompida pelo usuário.")
            break
        except Exception as e:
            print(f"[ERRO] Falha na iteração {i}: {e}")
            conn.rollback()

    cur.close()
    conn.close()
    total_time = time.time() - start_time
    print(f"=== Simulação Concluída em {total_time:.2f}s ===")

if __name__ == "__main__":
    main()
