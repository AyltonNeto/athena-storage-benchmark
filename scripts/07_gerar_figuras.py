"""
07_gerar_figuras.py — Regenera as Figuras 3, 4 e 6 do artigo a partir de
resultados/medicoes_completas.csv e resultados/armazenamento_s3.csv.

Motivação: as três figuras traziam anotações que afirmavam mais do que os dados
sustentam. Este script as reconstrói a partir da fonte primária, de modo que
qualquer alteração nos dados se propague às imagens.

  Figura 3 — a anotação do painel B indicava "-99% em bytes" apontando para a Q2,
             cuja redução é de 94,8%. Corrigida para a faixa real das duas
             consultas sem filtro.
  Figura 4 — as barras eram coloridas por sentido da razão das medianas
             ("melhorou"/"piorou"), o que atribuía diferença a casos sem suporte
             estatístico (a Q4, por exemplo, tem p = 0,222). Passam a ser
             coloridas por significância, com o valor-p anotado em cada consulta.
  Figura 6 — a anotação de -25,6% cobria o rótulo da barra de 360 arquivos.
             Substituída por colchetes ligando os pares comparados, com o -7,4%
             do par não particionado agora também explicitado.

Uso:
    pip install pandas scipy matplotlib
    python scripts/07_gerar_figuras.py
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import mannwhitneyu

RAIZ = Path(__file__).resolve().parent.parent
RESULTADOS = RAIZ / "resultados"
SAIDA = RAIZ / "figuras"

EXEC = [f"exec{i}_s" for i in range(1, 6)]
CONSULTAS = ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6"]
ROTULOS = ["Q1\n3 colunas", "Q2\nSELECT *", "Q3\nfiltro mês",
           "Q4\nfiltro ano", "Q5\nfiltro órgão", "Q6\nGROUP BY"]

# paleta extraída das figuras originais, para manter a consistência do conjunto
VERMELHO = "#c0392b"     # csv_base (referência)
AZUL_CLARO = "#5b9bd5"   # não particionado
AZUL_ESCURO = "#2e5b8a"  # particionado
CINZA = "#95a5a6"        # sem diferença estatisticamente detectável
F6 = ["#a8c4e5", "#4472c4", "#e9967a", "#b22222"]

ALFA = 0.05  # nível de significância adotado no artigo

plt.rcParams.update({
    "font.size": 11,
    "axes.titlesize": 12,
    "axes.titleweight": "bold",
    "axes.grid": True,
    "grid.alpha": 0.3,
    "grid.linestyle": "-",
})


def carregar():
    d = pd.read_csv(RESULTADOS / "medicoes_completas.csv")
    s = pd.read_csv(RESULTADOS / "armazenamento_s3.csv")
    return d, s


def serie(d, layout, coluna):
    p = d.pivot(index="layout", columns="consulta", values=coluna)
    return np.array([p.loc[layout, q] for q in CONSULTAS], dtype=float)


def execucoes(d, layout, consulta):
    return d[(d.layout == layout) & (d.consulta == consulta)][EXEC].values[0]


def valor_p(d, a, b, consulta):
    return mannwhitneyu(execucoes(d, a, consulta), execucoes(d, b, consulta),
                        alternative="two-sided")[1]


def virgula(valor, casas=2):
    return f"{valor:.{casas}f}".replace(".", ",")


# --------------------------------------------------------------------------
# Figura 3 — volume varrido vs. tempo, par controlado e referência
# --------------------------------------------------------------------------
def figura_3(d):
    layouts = [("csv_base", "csv_base (referência)", VERMELHO),
               ("parquet_gzip", "parquet_gzip", AZUL_CLARO),
               ("parquet_gzip_part", "parquet_gzip_part", AZUL_ESCURO)]

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14.15, 11.54))
    x = np.arange(len(CONSULTAS))
    largura = 0.26

    for i, (lay, rot, cor) in enumerate(layouts):
        ax1.bar(x + (i - 1) * largura, serie(d, lay, "mb_varrido"), largura,
                label=rot, color=cor, edgecolor="black", linewidth=0.4)
    ax1.set_yscale("log")
    ax1.set_ylabel("MB varridos (escala log)")
    ax1.set_title("A) Volume varrido: cai em todas as consultas com Parquet", loc="left")
    ax1.set_xticks(x)
    ax1.set_xticklabels(ROTULOS)
    ax1.legend(loc="upper right", framealpha=0.95)
    ax1.set_axisbelow(True)

    for i, (lay, rot, cor) in enumerate(layouts):
        ax2.bar(x + (i - 1) * largura, serie(d, lay, "mediana_s"), largura,
                yerr=serie(d, lay, "desvio_s"), capsize=3,
                label=rot, color=cor, edgecolor="black", linewidth=0.4,
                error_kw={"linewidth": 1.2})
    ax2.set_ylabel("Tempo: mediana de 5 exec. (s)")
    ax2.set_title("B) Tempo: o ganho desaparece nas consultas sem filtro (Q1 e Q2)",
                  loc="left")
    ax2.set_xticks(x)
    ax2.set_xticklabels(ROTULOS)
    ax2.legend(loc="upper right", framealpha=0.95)
    ax2.set_axisbelow(True)

    # faixa real de redução de bytes nas duas consultas sem filtro
    mb = d.pivot(index="layout", columns="consulta", values="mb_varrido")
    reducoes = [100 * (1 - mb.loc[lay, q] / mb.loc["csv_base", q])
                for q in ("Q1", "Q2") for lay in ("parquet_gzip", "parquet_gzip_part")]
    texto = (f"sem filtro: tempos\nindistinguíveis do CSV,\n"
             f"apesar de −{min(reducoes):.0f}% a −{max(reducoes):.0f}% em bytes")
    ax2.annotate(texto,
                 xy=(x[1] + largura, serie(d, "parquet_gzip_part", "mediana_s")[1]),
                 xytext=(x[1] + 0.75, serie(d, "csv_base", "mediana_s")[1] * 0.88),
                 color=VERMELHO, fontweight="bold", fontsize=11,
                 arrowprops={"arrowstyle": "->", "color": VERMELHO, "linewidth": 1.6})

    fig.tight_layout()
    destino = SAIDA / "Figura3_custo_vs_tempo.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: anotação com a faixa real "
          f"(−{min(reducoes):.0f}% a −{max(reducoes):.0f}%)")


# --------------------------------------------------------------------------
# Figura 4 — efeito do particionamento, colorido por significância
# --------------------------------------------------------------------------
def figura_4(d):
    a, b = "parquet_gzip", "parquet_gzip_part"
    med_a, med_b = serie(d, a, "mediana_s"), serie(d, b, "mediana_s")
    dp_a, dp_b = serie(d, a, "desvio_s"), serie(d, b, "desvio_s")
    ps = np.array([valor_p(d, a, b, q) for q in CONSULTAS])
    razoes = med_b / med_a

    fig, ax = plt.subplots(figsize=(14.15, 8.31))
    x = np.arange(len(CONSULTAS))
    largura = 0.36

    ax.bar(x - largura / 2, med_a, largura, yerr=dp_a, capsize=3,
           label=f"{a} (10 arquivos)", color=AZUL_CLARO,
           edgecolor="black", linewidth=0.4, error_kw={"linewidth": 1.2})
    ax.bar(x + largura / 2, med_b, largura, yerr=dp_b, capsize=3,
           label=f"{b} (360 arquivos)", color=AZUL_ESCURO,
           edgecolor="black", linewidth=0.4, error_kw={"linewidth": 1.2})

    ax.set_yscale("log")
    ax.set_ylabel("Tempo: mediana de 5 exec. (s), escala log")
    ax.set_xticks(x)
    ax.set_xticklabels(ROTULOS)
    ax.legend(loc="upper right", framealpha=0.95)
    ax.set_axisbelow(True)

    # rótulo por consulta: razão e valor-p; cor apenas quando há significância
    topo = np.maximum(med_a + dp_a, med_b + dp_b)
    for i, (razao, p) in enumerate(zip(razoes, ps)):
        significativo = p < ALFA
        cor = VERMELHO if (significativo and razao > 1) else (
              "#2e7d32" if significativo else CINZA)
        ax.text(x[i], topo[i] * 1.30,
                f"{virgula(razao)}×\np = {virgula(p, 3)}",
                ha="center", va="bottom", color=cor,
                fontweight="bold", fontsize=11, linespacing=1.3)

    n_sig = int((ps < ALFA).sum())
    ax.text(0.012, 0.975,
            "Razão particionado/não particionado. A cor indica significância "
            f"estatística (Mann-Whitney, p < {virgula(ALFA)});\n"
            f"cinza = diferença não detectável. {n_sig} de {len(CONSULTAS)} "
            "comparações atingem significância.",
            transform=ax.transAxes, ha="left", va="top",
            color="#555555", fontsize=10.5, linespacing=1.4)

    ax.set_ylim(top=ax.get_ylim()[1] * 2.6)
    fig.tight_layout()
    destino = SAIDA / "Figura4_efeito_particionamento.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: {n_sig} de 6 coloridas por significância "
          f"({', '.join(q for q, p in zip(CONSULTAS, ps) if p < ALFA)})")


# --------------------------------------------------------------------------
# Figura 6 — teste de consolidação de arquivos
# --------------------------------------------------------------------------
def figura_6(d, s):
    ordem = ["parquet_gzip_unico", "parquet_gzip", "parquet_gzip_part_unico",
             "parquet_gzip_part"]
    rotulos = ["não part. · 1 arquivo", "não part. · 10 arquivos",
               "particionado · 36 arquivos", "particionado · 360 arquivos"]
    curtos = ["1 arq", "10 arq", "36 arq", "360 arq"]

    fig, (ax1, ax2) = plt.subplots(
        1, 2, figsize=(22.34, 8.13), gridspec_kw={"width_ratios": [2.05, 1]})
    fig.suptitle("Teste de causalidade: consolidação de arquivos (GZIP) — "
                 "o efeito no armazenamento não se reproduz no tempo",
                 fontsize=14, fontweight="bold")

    x = np.arange(len(CONSULTAS))
    largura = 0.2
    for i, (lay, rot) in enumerate(zip(ordem, rotulos)):
        ax1.bar(x + (i - 1.5) * largura, serie(d, lay, "mediana_s"), largura,
                label=rot, color=F6[i], edgecolor="black", linewidth=0.4)
    ax1.set_ylabel("Tempo — mediana de 5 execuções (s)")
    ax1.set_title("A) Tempo de execução — consolidar não produziu ganho detectável "
                  "(p ≥ 0,095)", loc="center")
    ax1.set_xticks(x)
    ax1.set_xticklabels(ROTULOS)
    ax1.legend(ncol=2, loc="upper right", framealpha=0.95, fontsize=10)
    ax1.set_axisbelow(True)

    tam = s.set_index("layout")["tamanho_mb"].reindex(ordem).values
    barras = ax2.bar(curtos, tam, color=F6, edgecolor="black", linewidth=0.4,
                     width=0.62)
    ax2.set_ylabel("Tamanho no S3 (MB)")
    ax2.set_title("B) Armazenamento — consolidar reduz de forma clara", loc="center")
    ax2.set_axisbelow(True)
    ax2.set_ylim(0, max(tam) * 1.42)

    for barra, valor in zip(barras, tam):
        ax2.text(barra.get_x() + barra.get_width() / 2, valor + max(tam) * 0.015,
                 virgula(valor, 1), ha="center", va="bottom", fontweight="bold")

    # colchetes ligando os pares comparados, fora das barras
    def colchete(i, j, altura, texto, cor):
        y = max(tam) * altura
        ax2.plot([i, i, j, j], [y - max(tam) * 0.022, y, y, y - max(tam) * 0.022],
                 color=cor, linewidth=1.6, clip_on=False)
        ax2.text((i + j) / 2, y + max(tam) * 0.012, texto, ha="center", va="bottom",
                 color=cor, fontweight="bold", fontsize=12)

    colchete(2, 3, 1.20, f"−{virgula(100 * (1 - tam[2] / tam[3]), 1)}%", "#2e7d32")
    colchete(0, 1, 1.02, f"−{virgula(100 * (1 - tam[0] / tam[1]), 1)}%", "#2e7d32")

    fig.tight_layout(rect=(0, 0, 1, 0.955))
    destino = SAIDA / "Figura6_teste_consolidacao.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: colchetes nos pares 36↔360 "
          f"(−{100 * (1 - tam[2] / tam[3]):.1f}%) e 1↔10 "
          f"(−{100 * (1 - tam[0] / tam[1]):.1f}%)")


def main():
    d, s = carregar()
    SAIDA.mkdir(exist_ok=True)
    print(f"Fonte: {len(d)} combinações × 5 execuções")
    figura_3(d)
    figura_4(d)
    figura_6(d, s)
    print("\nFiguras 1, 2 e 5 não são regeneradas por este script: "
          "não apresentavam inconsistências.")


if __name__ == "__main__":
    main()
