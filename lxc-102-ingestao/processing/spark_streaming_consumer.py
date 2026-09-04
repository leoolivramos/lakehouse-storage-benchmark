#!/usr/bin/env python3
"""
Job Apache Spark Structured Streaming para Ingestão Contínua de Eventos CDC
Consome eventos do Apache Kafka e persiste paralelamente nas camadas de armazenamento:
1. MinIO (S3 Object Storage - Parquet)
2. Apache Hadoop HDFS
3. NFS (Network File System)

Coleta métricas de latência ponta a ponta e vazão de processamento para o benchmark empírico.
Autor: Leonardo Ramos (TCC UFMT)
"""

import os
import sys
import time
import json
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, current_timestamp, expr
from pyspark.sql.types import (
    StructType, StructField, StringType, LongType, DoubleType, IntegerType, TimestampType
)

# Configurações de Ambiente
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:29092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "lakehouse.public.empenhos")
CHECKPOINT_DIR = os.getenv("CHECKPOINT_DIR", "/tmp/spark-checkpoints")

# Destinos de Persistência (LXC 103)
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://192.168.1.130:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ROOT_USER", "admin_lakehouse")
MINIO_SECRET_KEY = os.getenv("MINIO_ROOT_PASSWORD", "lakehouse_secret_key")
MINIO_BUCKET = os.getenv("MINIO_BUCKET_NAME", "lakehouse-audit")

HDFS_NAMENODE = os.getenv("HDFS_NAMENODE", "hdfs://192.168.1.130:9000")
NFS_TARGET_DIR = os.getenv("NFS_TARGET_DIR", "/mnt/lakehouse-nfs/empenhos")
METRICS_OUTPUT_FILE = os.getenv("METRICS_OUTPUT_FILE", "/tmp/spark_batch_metrics.jsonl")

# Definição do Esquema do Registro CDC de Empenhos
payload_after_schema = StructType([
    StructField("id", LongType(), True),
    StructField("numero_empenho", StringType(), True),
    StructField("ano_exercicio", IntegerType(), True),
    StructField("orgao_id", IntegerType(), True),
    StructField("credor_id", IntegerType(), True),
    StructField("modalidade_licitacao", StringType(), True),
    StructField("numero_processo", StringType(), True),
    StructField("valor_empenhado", DoubleType(), True),
    StructField("valor_anulado", DoubleType(), True),
    StructField("descricao_objeto", StringType(), True),
    StructField("status", StringType(), True),
    StructField("data_emissao", StringType(), True),
    StructField("atualizado_em", StringType(), True)
])

debezium_envelope_schema = StructType([
    StructField("before", payload_after_schema, True),
    StructField("after", payload_after_schema, True),
    StructField("op", StringType(), True),
    StructField("ts_ms", LongType(), True)
])

def create_spark_session():
    builder = (
        SparkSession.builder
        .appName("LakehouseContinuousIngestion-CDC")
        .master(os.getenv("SPARK_MASTER_URL", "local[*]"))
        # Dependências de Pacotes (Kafka + S3A Hadoop)
        .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,org.apache.hadoop:hadoop-aws:3.3.4")
        .config("spark.sql.streaming.forceDeleteTempCheckpointLocation", "true")
        .config("spark.sql.shuffle.partitions", "4")
        # Configurações Hadoop S3A para MinIO
        .config("spark.hadoop.fs.s3a.endpoint", MINIO_ENDPOINT)
        .config("spark.hadoop.fs.s3a.access.key", MINIO_ACCESS_KEY)
        .config("spark.hadoop.fs.s3a.secret.key", MINIO_SECRET_KEY)
        .config("spark.hadoop.fs.s3a.path.style.access", "true")
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false")
    )
    return builder.getOrCreate()

def process_batch(batch_df, batch_id):
    """
    Função foreachBatch para medir latência e persistir em múltiplos destinos.
    """
    record_count = batch_df.count()
    if record_count == 0:
        return

    start_write_time = time.time()
    current_time_ms = int(time.time() * 1000)

    # Adiciona colunas de auditoria e cálculo de latência CDC
    enriched_df = (
        batch_df
        .withColumn("lakehouse_ingested_at", current_timestamp())
        .withColumn("cdc_lag_ms", expr(f"{current_time_ms} - ts_ms"))
    )

    # Persistência 1: MinIO (S3)
    s3_path = f"s3a://{MINIO_BUCKET}/empenhos_parquet/"
    t0_s3 = time.time()
    try:
        enriched_df.write.mode("append").parquet(s3_path)
        s3_duration_ms = (time.time() - t0_s3) * 1000
    except Exception as e:
        s3_duration_ms = -1
        print(f"[WARN] Falha ao persistir no MinIO: {e}")

    # Persistência 2: HDFS
    hdfs_path = f"{HDFS_NAMENODE}/lakehouse/empenhos/"
    t0_hdfs = time.time()
    try:
        enriched_df.write.mode("append").parquet(hdfs_path)
        hdfs_duration_ms = (time.time() - t0_hdfs) * 1000
    except Exception as e:
        hdfs_duration_ms = -1
        print(f"[WARN] Falha ao persistir no HDFS: {e}")

    # Persistência 3: NFS / Filesystem Direto
    t0_nfs = time.time()
    try:
        enriched_df.write.mode("append").parquet(NFS_TARGET_DIR)
        nfs_duration_ms = (time.time() - t0_nfs) * 1000
    except Exception as e:
        nfs_duration_ms = -1
        print(f"[WARN] Falha ao persistir no NFS: {e}")

    total_batch_duration_ms = (time.time() - start_write_time) * 1000

    # Gravação das métricas do micro-batch para o benchmark
    metric = {
        "timestamp": datetime.utcnow().isoformat(),
        "batch_id": batch_id,
        "record_count": record_count,
        "total_batch_duration_ms": round(total_batch_duration_ms, 2),
        "s3_duration_ms": round(s3_duration_ms, 2),
        "hdfs_duration_ms": round(hdfs_duration_ms, 2),
        "nfs_duration_ms": round(nfs_duration_ms, 2),
    }

    try:
        with open(METRICS_OUTPUT_FILE, "a") as f:
            f.write(json.dumps(metric) + "\n")
    except Exception as err:
        print(f"Erro ao salvar métrica: {err}")

    print(f"[{datetime.now().strftime('%H:%M:%S')}] Micro-batch {batch_id}: {record_count} registros processados | Total: {total_batch_duration_ms:.1f}ms (S3: {s3_duration_ms:.1f}ms, HDFS: {hdfs_duration_ms:.1f}ms, NFS: {nfs_duration_ms:.1f}ms)")

def main():
    print("=== Iniciando Pipeline PySpark de Ingestão Contínua (CDC) ===")
    spark = create_spark_session()
    spark.sparkContext.setLogLevel("WARN")

    # Leitura do fluxo contínuo a partir do Apache Kafka
    kafka_stream = (
        spark.readStream
        .format("kafka")
        .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP_SERVERS)
        .option("subscribe", KAFKA_TOPIC)
        .option("startingOffsets", "latest")
        .option("failOnDataLoss", "false")
        .load()
    )

    # Conversão do Payload JSON do Debezium
    parsed_stream = (
        kafka_stream
        .selectExpr("CAST(value AS STRING) as json_value")
        .select(from_json(col("json_value"), debezium_envelope_schema).alias("data"))
        .select(
            col("data.op").alias("cdc_operation"),
            col("data.ts_ms").alias("ts_ms"),
            col("data.after.*")
        )
        .filter(col("id").isNotNull())
    )

    # Escrita contínua via foreachBatch com checkpoints
    query = (
        parsed_stream.writeStream
        .foreachBatch(process_batch)
        .option("checkpointLocation", f"{CHECKPOINT_DIR}/empenhos")
        .trigger(processingTime="2 seconds")
        .start()
    )

    print(f"[OK] Pipeline ativo consumindo de '{KAFKA_TOPIC}' via '{KAFKA_BOOTSTRAP_SERVERS}'.")
    query.awaitTermination()

if __name__ == "__main__":
    main()
