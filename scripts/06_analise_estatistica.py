"""
06_analise_estatistica.py — Reproduz os números derivados do artigo a partir de
resultados/medicoes_completas.csv.

Gera:
  (1) Tabela 2  — custo das seis consultas por layout, nos dois regimes
                  (proporcional aos bytes varridos e faturado, com arredondamento
                  para o MB superior e mínimo de 10 MB por consulta)
  (2) Tabela 4  — efeito do particionamento no par controlado em GZIP, com valor-p
  (3) Seção 5.1 — CSV de referência vs. Parquet (par com parquet_gzip)
  (4) Seção 4.5 — efeito da consolidação de arquivos
  (5) Seção 4.2 — comparação entre todos os pares de codecs (36 comparações)
  (6) Seção 4.2 — coeficiente de variação das 48 combinações do desenho principal

Todos os testes são Mann-Whitney bilaterais sobre as 5 execuções de cada combinação
(scipy.stats.mannwhitneyu, alternative="two-sided", sem correção de continuidade —
o padrão do scipy para o teste exato com amostras pequenas e sem empates).

Nota sobre o poder do teste: com n = 5 por grupo, o menor valor-p bilateral atingível
é 2/252 ≈ 0,008. Valores-p elevados indicam ausência de evidência de diferença, e não
equivalência demonstrada.

Uso:
    pip install pandas scipy
    python scripts/06_analise_estatistica.py
"""

import math
from pathlib import Path

import pandas as pd
from scipy.stats import mannwhitneyu

PRECO_USD_POR_TB = 5.00
MB_POR_TB = 1024 ** 2          # base binária: 1 TB = 1.048.576 MB
MINIMO_MB_POR_CONSULTA = 10    # cobrança mínima praticada pelo serviço

EXEC = [f"exec{i}_s" for i in range(1, 6)]
CONSULTAS = ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6"]
LAYOUTS_PRINCIPAIS = [
    "csv_base", "csv_particionado",
    "parquet_snappy", "parquet_snappy_part",
    "parquet_gzip", "parquet_gzip_part",
    "parquet_zstd", "parquet_zstd_part",
]

RAIZ = Path(__file__).resolve().parent.parent
CSV = RAIZ / "resultados" / "medicoes_completas.csv"


def carregar():
    d = pd.read_csv(CSV)
    faltando = set(EXEC) - set(d.columns)
    if faltando:
        raise SystemExit(f"colunas ausentes em {CSV.name}: {sorted(faltando)}")
    return d


def execucoes(d, layout, consulta):
    linha = d[(d.layout == layout) & (d.consulta == consulta)]
    if linha.empty:
        raise KeyError(f"combinação inexistente: {layout} / {consulta}")
    return linha[EXEC].values[0]


def teste(d, layout_a, layout_b, consulta):
    """Mediana de cada layout, razão b/a e valor-p bilateral."""
    a, b = execucoes(d, layout_a, consulta), execucoes(d, layout_b, consulta)
    _, p = mannwhitneyu(a, b, alternative="two-sided")
    med_a, med_b = float(pd.Series(a).median()), float(pd.Series(b).median())
    return med_a, med_b, med_b / med_a, p


def custo(volumes_mb, faturado):
    """Custo em US$ das seis consultas de um layout."""
    if faturado:
        total = sum(max(MINIMO_MB_POR_CONSULTA, math.ceil(v)) for v in volumes_mb)
    else:
        total = sum(volumes_mb)
    return total / MB_POR_TB * PRECO_USD_POR_TB


def titulo(t):
    print(f"\n{t}\n{'=' * len(t)}")


def tabela_2(d):
    titulo("(1) TABELA 2 — custo das seis consultas, por layout (US$ 5,00/TB)")
    vol = d.pivot(index="layout", columns="consulta", values="mb_varrido")
    base_prop = custo(vol.loc["csv_base", CONSULTAS], faturado=False)
    base_fat = custo(vol.loc["csv_base", CONSULTAS], faturado=True)

    print(f"{'layout':<26}{'varrido(MB)':>12}{'proporcional':>14}"
          f"{'faturado':>11}{'redução':>10}")
    for lay in LAYOUTS_PRINCIPAIS:
        v = vol.loc[lay, CONSULTAS]
        c_prop, c_fat = custo(v, False), custo(v, True)
        red = "—" if lay == "csv_base" else f"{100 * (1 - c_fat / base_fat):.1f}%"
        print(f"{lay:<26}{sum(v):>12.2f}{c_prop:>14.6f}{c_fat:>11.6f}{red:>10}")

    print(f"\n  Referência: custo proporcional {base_prop:.6f} / faturado {base_fat:.6f}")
    print("  O piso de 10 MB por consulta separa as duas colunas. Exemplo da seção 4.1:")
    q3 = vol.loc["parquet_gzip_part", "Q3"]
    base_q3 = math.ceil(vol.loc["csv_base", "Q3"])
    print(f"    Q3 / parquet_gzip_part varre {q3:.2f} MB e é faturada como "
          f"{max(MINIMO_MB_POR_CONSULTA, math.ceil(q3))} MB")
    print(f"    redução de volume  {100 * (1 - q3 / vol.loc['csv_base', 'Q3']):.2f}%")
    print(f"    redução faturada   {100 * (1 - MINIMO_MB_POR_CONSULTA / base_q3):.2f}%")


def tabela_4(d):
    titulo("(2) TABELA 4 — efeito do particionamento (par controlado em GZIP)")
    print(f"{'consulta':<10}{'parquet_gzip':>14}{'_part':>10}{'razão':>9}{'p':>9}")
    for q in CONSULTAS:
        a, b, razao, p = teste(d, "parquet_gzip", "parquet_gzip_part", q)
        print(f"{q:<10}{a:>14.3f}{b:>10.3f}{razao:>8.2f}×{p:>9.3f}")
    print("\n  Significativo a 5% apenas na Q6; Q3 e Q5 no limiar (seção 4.3).")


def secao_5_1(d):
    titulo("(3) SEÇÃO 5.1 — CSV de referência vs. Parquet (par com parquet_gzip)")
    print(f"{'consulta':<10}{'csv_base':>11}{'parquet_gzip':>14}{'p':>9}")
    for q in CONSULTAS:
        a, b, _, p = teste(d, "csv_base", "parquet_gzip", q)
        print(f"{q:<10}{a:>11.3f}{b:>14.3f}{p:>9.3f}")
    print("\n  Parquet mais rápido em Q3–Q6 (p = 0,008, o mínimo atingível com n = 5).")
    print("  Sem diferença na Q1 e na Q2 — as duas consultas que devolvem 2,38 milhões")
    print("  de linhas, em que a materialização do resultado domina a latência.")


def secao_4_5(d):
    titulo("(4) SEÇÃO 4.5 — efeito da consolidação de arquivos")
    for a, b, rotulo in [
        ("parquet_gzip_part", "parquet_gzip_part_unico", "particionado: 360 → 36 arquivos"),
        ("parquet_gzip", "parquet_gzip_unico", "não particionado: 10 → 1 arquivo"),
    ]:
        print(f"\n  {rotulo}")
        print(f"    {'consulta':<10}{'antes':>9}{'depois':>9}{'p':>9}")
        ps = []
        for q in CONSULTAS:
            m_a, m_b, _, p = teste(d, a, b, q)
            ps.append(p)
            print(f"    {q:<10}{m_a:>9.3f}{m_b:>9.3f}{p:>9.3f}")
        print(f"    menor valor-p: {min(ps):.3f}")

    vol = d.pivot(index="layout", columns="consulta", values="mb_varrido")
    antes = sum(vol.loc["parquet_gzip_part", CONSULTAS])
    depois = sum(vol.loc["parquet_gzip_part_unico", CONSULTAS])
    print(f"\n  Volume varrido no par particionado: {antes:.2f} → {depois:.2f} MB "
          f"({100 * (1 - depois / antes):.1f}%)")
    c_a = custo(vol.loc["parquet_gzip_part", CONSULTAS], True)
    c_b = custo(vol.loc["parquet_gzip_part_unico", CONSULTAS], True)
    print(f"  Custo faturado das seis consultas: {100 * (1 - c_b / c_a):.1f}% menor")


def codecs(d):
    titulo("(5) SEÇÃO 4.2 — comparação entre codecs (todos os pares, todas as consultas)")
    grupos = {
        "não particionados": ["parquet_gzip", "parquet_snappy", "parquet_zstd"],
        "particionados": ["parquet_gzip_part", "parquet_snappy_part", "parquet_zstd_part"],
    }
    todos = []
    for nome, layouts in grupos.items():
        print(f"\n  {nome}")
        print(f"    {'par':<44}{'menor p':>9}")
        for i in range(len(layouts)):
            for j in range(i + 1, len(layouts)):
                a, b = layouts[i], layouts[j]
                ps = [teste(d, a, b, q)[3] for q in CONSULTAS]
                todos += ps
                print(f"    {a + ' vs ' + b:<44}{min(ps):>9.3f}")

    print(f"\n  comparações: {len(todos)}")
    print(f"  menor valor-p global: {min(todos):.3f}")
    print(f"  com p < 0,05: {sum(1 for p in todos if p < 0.05)}")
    print(f"  com p = 1,000 (postos coincidentes): "
          f"{sum(1 for p in todos if abs(p - 1.0) < 1e-9)}")
    print("\n  Nenhuma comparação atinge significância antes de qualquer correção para")
    print("  múltiplos testes; como correções apenas elevam os valores-p, aplicá-las")
    print("  não alteraria a conclusão.")


def secao_4_2(d):
    titulo("(6) SEÇÃO 4.2 — coeficiente de variação (48 combinações do desenho principal)")
    p = d[d.layout.isin(LAYOUTS_PRINCIPAIS)].copy()
    p["media"] = p[EXEC].mean(axis=1)
    p["desvio"] = p[EXEC].std(axis=1, ddof=1)
    p["cv"] = 100 * p.desvio / p.media
    pior = p.loc[p.cv.idxmax()]
    print(f"  combinações: {len(p)}")
    print(f"  CV mediano:  {p.cv.median():.1f}%")
    print(f"  CV máximo:   {p.cv.max():.1f}%  ({pior.layout} / {pior.consulta})")
    print(f"    média {pior.media:.3f} s contra mediana {pior[EXEC].median():.3f} s")
    print("\n  A margem de resolução do experimento decorre daqui: diferenças de tempo")
    print("  abaixo de ~15% não são distinguíveis da variabilidade do serviço.")


def main():
    d = carregar()
    print(f"Fonte: {CSV.relative_to(RAIZ)} — {len(d)} combinações × 5 execuções "
          f"= {len(d) * 5} medições")
    tabela_2(d)
    tabela_4(d)
    secao_5_1(d)
    secao_4_5(d)
    codecs(d)
    secao_4_2(d)
    print()


if __name__ == "__main__":
    main()
