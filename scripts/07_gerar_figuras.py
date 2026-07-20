"""
07_gerar_figuras.py — Gera as seis figuras do artigo a partir de
resultados/medicoes_completas.csv e resultados/armazenamento_s3.csv, de modo
que qualquer alteração nos dados se propague às imagens.

  Figura 1 — poda de partições no layout csv_particionado: volume varrido por
             consulta, em escala logarítmica, contra a linha do csv_base.
  Figura 2 — comparação entre os três codecs nos layouts particionados:
             painel A com volume varrido, painel B com tempo de execução.
  Figura 3 — volume varrido e tempo de execução para o par controlado em GZIP
             e o CSV de referência, painel A em escala logarítmica.
  Figura 4 — efeito isolado do particionamento sobre o tempo, com razão das
             medianas e valor-p do teste de Mann-Whitney anotados em cada
             consulta. A cor do rótulo distingue três casos: cor cheia para
             p < 0,05, cor esmaecida para p = 0,056 (o menor valor não
             significativo possível com n = 5) e cinza para os demais; verde
             indica consulta mais rápida com particionamento, vermelho, mais
             lenta.
  Figura 5 — efeito do particionamento sobre o espaço em disco, por codec,
             com a inflação percentual anotada em cada par.
  Figura 6 — teste de causalidade da consolidação: tempo por consulta em
             quatro graus de fragmentação e armazenamento físico total, com
             colchetes ligando os pares comparados.


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
CINZA = "#95a5a6"        # sem evidência de diferença
VERDE_FRACO = "#7cb342"  # significância no limiar (p = 0,056)
VERMELHO_FRACO = "#e57373"
F6 = ["#a8c4e5", "#4472c4", "#e9967a", "#b22222"]
# paleta das Figuras 1, 2 e 5
CINZA_BARRA = "#bdbdbd"      # consulta sem poda de partição
VERDE_ESCURO = "#1e7a34"     # poda máxima (um mês)
VERDE_MEDIO = "#63c073"      # poda parcial (um ano)
VERMELHO_ESCURO = "#a02020"  # linha de referência e rótulos de inflação
AZUL_CODEC = "#3d6fc4"
VERDE_CODEC = "#5aa64b"
AMARELO_CODEC = "#f5b800"

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


def milhar(valor):
    """1751.04 -> '1.751'; 47.73 -> '48' (formato dos rótulos da Figura 1)."""
    return f"{valor:,.0f}".replace(",", ".")


def virgula(valor, casas=2):
    return f"{valor:.{casas}f}".replace(".", ",")


# --------------------------------------------------------------------------
# Figura 1 — poda de partições no layout csv_particionado
# --------------------------------------------------------------------------
def figura_1(d):
    mb = serie(d, "csv_particionado", "mb_varrido")
    referencia = serie(d, "csv_base", "mb_varrido")[0]
    # a poda só atua nas consultas que filtram pelas chaves de partição
    poda = {"Q3": VERDE_ESCURO, "Q4": VERDE_MEDIO}

    fig, ax = plt.subplots(figsize=(14.08, 7.35))
    x = np.arange(len(CONSULTAS))
    cores = [poda.get(q, CINZA_BARRA) for q in CONSULTAS]

    ax.bar(x, mb, 0.62, color=cores, edgecolor="black", linewidth=0.8)
    ax.axhline(referencia, color=VERMELHO_ESCURO, linestyle="--", linewidth=2.2,
               label=f"csv_base (referência) = {milhar(referencia)} MB")

    ax.set_yscale("log")
    ax.set_ylim(1, referencia * 6)
    ax.set_ylabel("MB varridos (escala logarítmica)")
    ax.set_xticks(x)
    ax.set_xticklabels(ROTULOS)
    ax.legend(loc="center right", framealpha=0.95)
    ax.set_axisbelow(True)

    for xi, valor in zip(x, mb):
        ax.text(xi, valor * 1.18, milhar(valor), ha="center", va="bottom",
                fontweight="bold", fontsize=12)

    ax.text(0.055, 0.94, "Poda inativa — varre quase tudo",
            transform=ax.transAxes, color="#666666", fontsize=12)
    ax.annotate("Poda ATIVA\n(filtro casa com a partição)",
                xy=(0.5, 0.62), xycoords="axes fraction",
                ha="center", va="center", color=VERDE_ESCURO,
                fontweight="bold", fontsize=13,
                bbox={"boxstyle": "round,pad=0.5", "facecolor": "#eef7ee",
                      "edgecolor": VERDE_MEDIO, "linewidth": 1.5})

    fig.tight_layout()
    destino = SAIDA / "Figura1_pruning_csv.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: poda ativa na Q3 e na Q4, inativa nas demais")


# --------------------------------------------------------------------------
# Figura 2 — comparação entre codecs nos layouts particionados
# --------------------------------------------------------------------------
def figura_2(d):
    codecs = [("parquet_snappy_part", "Snappy", AZUL_CODEC),
              ("parquet_gzip_part", "GZIP", VERDE_CODEC),
              ("parquet_zstd_part", "ZSTD", AMARELO_CODEC)]

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14.08, 11.81))
    x = np.arange(len(CONSULTAS))
    largura = 0.26

    for i, (lay, rot, cor) in enumerate(codecs):
        ax1.bar(x + (i - 1) * largura, serie(d, lay, "mb_varrido"), largura,
                label=rot, color=cor, edgecolor="black", linewidth=0.4)
    ax1.set_yscale("log")
    ax1.set_ylabel("MB varridos (escala log)")
    ax1.set_title("A) Volume varrido por codec", loc="left")
    ax1.set_xticks(x)
    ax1.set_xticklabels(ROTULOS)
    ax1.legend(loc="upper right", framealpha=0.95)
    ax1.set_axisbelow(True)

    for i, (lay, rot, cor) in enumerate(codecs):
        ax2.bar(x + (i - 1) * largura, serie(d, lay, "mediana_s"), largura,
                yerr=serie(d, lay, "desvio_s"), capsize=3,
                label=rot, color=cor, edgecolor="black", linewidth=0.4,
                error_kw={"linewidth": 1.2})
    ax2.set_ylabel("Tempo — mediana de 5 exec. (s)")
    ax2.set_title("B) Tempo de execução por codec (barras de erro = desvio-padrão)",
                  loc="left")
    ax2.set_xticks(x)
    ax2.set_xticklabels(ROTULOS)
    ax2.legend(loc="upper right", framealpha=0.95)
    ax2.set_axisbelow(True)

    fig.tight_layout()
    destino = SAIDA / "Figura2_codecs.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: Snappy, GZIP e ZSTD nos layouts particionados")


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

    fig.tight_layout()
    destino = SAIDA / "Figura3_custo_vs_tempo.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    print(f"  {destino.name}: painéis A (bytes, log) e B (tempo) sem anotações")


# --------------------------------------------------------------------------
# Figura 4 — efeito do particionamento, colorido por significância
# --------------------------------------------------------------------------
def figura_4(d):
    a, b = "parquet_gzip", "parquet_gzip_part"
    med_a, med_b = serie(d, a, "mediana_s"), serie(d, b, "mediana_s")
    dp_a, dp_b = serie(d, a, "desvio_s"), serie(d, b, "desvio_s")
    ps = np.array([valor_p(d, a, b, q) for q in CONSULTAS])
    razoes = med_b / med_a

    LIMIAR = 0.056  # menor valor-p não significativo possível com n = 5

    def cor_do_rotulo(razao, p):
        piorou = razao > 1
        if p < ALFA:
            return VERMELHO if piorou else "#2e7d32"
        if abs(p - LIMIAR) < 1e-9:
            return VERMELHO_FRACO if piorou else VERDE_FRACO
        return CINZA

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
    legenda_series = ax.legend(loc="upper right", framealpha=0.95)
    ax.set_axisbelow(True)

    topo = np.maximum(med_a + dp_a, med_b + dp_b)
    for i, (razao, p) in enumerate(zip(razoes, ps)):
        ax.text(x[i], topo[i] * 1.42,
                f"{virgula(razao)}×\np = {virgula(p, 3)}",
                ha="center", va="bottom", color=cor_do_rotulo(razao, p),
                fontweight="bold", fontsize=11, linespacing=1.3)

    from matplotlib.patches import Patch
    chave = [
        Patch(facecolor=VERDE_FRACO, edgecolor="none",
              label="mais rápida · limiar (p = 0,056)"),
        Patch(facecolor=CINZA, edgecolor="none",
              label="sem evidência de diferença"),
        Patch(facecolor=VERMELHO_FRACO, edgecolor="none",
              label="mais lenta · limiar (p = 0,056)"),
        Patch(facecolor=VERMELHO, edgecolor="none",
              label="mais lenta · significativa (p < 0,05)"),
    ]
    legenda_cores = ax.legend(
        handles=chave, loc="upper center", bbox_to_anchor=(0.5, -0.13),
        ncol=4, frameon=False, fontsize=10.5, handlelength=1.4,
        handleheight=1.0, columnspacing=2.0,
        title="Cor do rótulo — sentido do efeito e força da evidência "
              "(0,056 é o menor valor-p não significativo possível com n = 5)")
    legenda_cores.get_title().set_fontsize(10.5)
    legenda_cores.get_title().set_color("#555555")
    for texto in legenda_cores.get_texts():
        texto.set_color("#555555")
    ax.add_artist(legenda_series)

    ax.set_ylim(top=ax.get_ylim()[1] * 1.9)
    fig.tight_layout()
    destino = SAIDA / "Figura4_efeito_particionamento.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    n_sig = int((ps < ALFA).sum())
    n_lim = int(np.isclose(ps, LIMIAR).sum())
    print(f"  {destino.name}: {n_sig} significativa(s), {n_lim} no limiar")


# --------------------------------------------------------------------------
# Figura 5 — efeito do particionamento sobre o armazenamento, por codec
# --------------------------------------------------------------------------
def figura_5(s):
    pares = [("Snappy", "parquet_snappy", "parquet_snappy_part"),
             ("GZIP", "parquet_gzip", "parquet_gzip_part"),
             ("ZSTD", "parquet_zstd", "parquet_zstd_part")]
    tam = s.set_index("layout")["tamanho_mb"]

    fig, ax = plt.subplots(figsize=(13.34, 7.34))
    x = np.arange(len(pares))
    largura = 0.38

    nao_part = [tam[a] for _, a, _ in pares]
    part = [tam[b] for _, _, b in pares]

    ax.bar(x - largura / 2, nao_part, largura, label="Não particionado (10 arquivos)",
           color=AZUL_CLARO, edgecolor="black", linewidth=0.8)
    ax.bar(x + largura / 2, part, largura, label="Particionado (360 arquivos)",
           color=AZUL_ESCURO, edgecolor="black", linewidth=0.8)

    ax.set_ylabel("Tamanho no S3 (MB)")
    ax.set_xticks(x)
    ax.set_xticklabels([nome for nome, _, _ in pares])
    ax.set_ylim(0, max(part) * 1.28)
    ax.legend(loc="upper right", framealpha=0.95)
    ax.set_axisbelow(True)

    folga = max(part) * 0.015
    for xi, (a, b) in enumerate(zip(nao_part, part)):
        ax.text(xi - largura / 2, a + folga, virgula(a, 1).replace(",", "."),
                ha="center", va="bottom", fontweight="bold", fontsize=12)
        ax.text(xi + largura / 2, b + folga, virgula(b, 1).replace(",", "."),
                ha="center", va="bottom", fontweight="bold", fontsize=12)
        ax.text(xi, b * 1.10, f"+{100 * (b / a - 1):.0f}%", ha="center", va="bottom",
                color=VERMELHO_ESCURO, fontweight="bold", fontsize=14)

    fig.tight_layout()
    destino = SAIDA / "Figura5_paradoxo_armazenamento.png"
    fig.savefig(destino, dpi=100, facecolor="white")
    plt.close(fig)
    inflacoes = [f"+{100 * (b / a - 1):.0f}%" for a, b in zip(nao_part, part)]
    print(f"  {destino.name}: inflação de {', '.join(inflacoes)} por codec")

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
    figura_1(d)
    figura_2(d)
    figura_3(d)
    figura_4(d)
    figura_5(s)
    figura_6(d, s)


if __name__ == "__main__":
    main()
