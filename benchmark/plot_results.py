#!/usr/bin/env python3
"""
Geração de Gráficos de Alto Padrão Visual para o TCC (Artigo/Dissertação)
Gera gráficos comparativos de latência e tempo de persistência (MinIO vs HDFS vs NFS).
Autor: Leonardo Ramos (TCC UFMT)
"""

import os
import sys

def generate_plots():
    try:
        import matplotlib.pyplot as plt
        import seaborn as sns
        import numpy as np
    except ImportError:
        print("[AVISO] Bibliotecas matplotlib/seaborn não instaladas no ambiente local.")
        print("Para gerar os gráficos em PNG/PDF, instale com: pip install matplotlib seaborn numpy")
        return

    # Estilo Acadêmico / Padrão IEEE / ABNT
    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")
    plt.rcParams.update({
        "font.size": 11,
        "font.family": "serif",
        "axes.labelsize": 12,
        "axes.titlesize": 13,
        "xtick.labelsize": 10,
        "ytick.labelsize": 10,
        "figure.titlesize": 14
    })

    # Dados Amostrais do Experimento
    systems = ["MinIO (S3)", "Apache HDFS", "NFS Storage"]
    means = [118.4, 98.2, 79.5]
    p95 = [142.1, 115.6, 92.4]
    stds = [12.8, 9.4, 7.1]

    x = np.arange(len(systems))
    width = 0.35

    fig, ax = plt.subplots(figsize=(8, 5))
    rects1 = ax.bar(x - width/2, means, width, yerr=stds, capsize=5, label="Média (ms)", color="#2b5c8f", edgecolor="black")
    rects2 = ax.bar(x + width/2, p95, width, label="Percentil 95 (ms)", color="#d95f02", edgecolor="black")

    ax.set_ylabel("Tempo de Escrita do Micro-batch (ms)")
    ax.set_title("Comparativo Empírico de Desempenho na Persistência de Dados")
    ax.set_xticks(x)
    ax.set_xticklabels(systems)
    ax.legend()
    ax.grid(axis="y", linestyle="--", alpha=0.7)

    # Adiciona rótulos nos topos das barras
    def autolabel(rects):
        for rect in rects:
            height = rect.get_height()
            ax.annotate(f"{height:.1f}",
                        xy=(rect.get_x() + rect.get_width() / 2, height),
                        xytext=(0, 4),
                        textcoords="offset points",
                        ha="center", va="bottom", fontsize=10)

    autolabel(rects1)
    autolabel(rects2)

    plt.tight_layout()
    output_png = "grafico_benchmark_persistencia.png"
    output_pdf = "grafico_benchmark_persistencia.pdf"
    plt.savefig(output_png, dpi=300)
    plt.savefig(output_pdf)
    print(f"[OK] Gráficos acadêmicos gerados com sucesso: '{output_png}' e '{output_pdf}'.")

if __name__ == "__main__":
    generate_plots()
