# -*- coding: utf-8 -*-
"""
Limpeza e consolidação dos dados brutos (Despesas — Portal da Transparência).

Lê os CSVs mensais de Despesas (2023–2025), corrige os problemas de origem
(codificação ISO-8859-1, separador ';', valores monetários no padrão brasileiro),
deriva as colunas de partição (ano, mes) e gera um único CSV consolidado em UTF-8.

Esse arquivo é o baseline do experimento: todos os demais layouts são gerados a
partir dele no Athena, o que garante dado idêntico entre eles.

Ao final, imprime um relatório de validação com contagem de linhas, número de
partições e a soma de controle de valor_pago, usada para verificar a integridade
nas etapas seguintes.

Pré-requisito: pip install pandas
"""

import pandas as pd
import glob
import os

# ----------------------------------------------------------------------------
# Configuração de caminhos
# ----------------------------------------------------------------------------
PASTA_BRUTOS = r"dados_brutos"   # ajuste para o diretório dos 36 CSVs mensais

# Pasta de saída (será criada ao lado da pasta de brutos, se não existir).
PASTA_SAIDA = r"dados_limpos"    # diretório de saída do baseline consolidado

# Nome do arquivo baseline final.
ARQUIVO_SAIDA = os.path.join(PASTA_SAIDA, "despesas_baseline.csv")

# ----------------------------------------------------------------------------
# Parâmetros de leitura (características do CSV de origem)
# ----------------------------------------------------------------------------
ENCODING_ORIGEM = "latin-1"   # os arquivos vêm em ISO-8859-1, não UTF-8
SEPARADOR = ";"               # colunas separadas por ponto-e-vírgula

# Nome EXATO da coluna de data no arquivo (formato dos valores: "2025/01").
COLUNA_DATA = "Ano e mês do lançamento"

# As 6 colunas de VALOR que estão como texto ("14400,00") e precisam virar número.
# Só estas serão convertidas — todo o resto permanece como texto para preservar
# códigos com zero à esquerda.
COLUNAS_VALOR = [
    "Valor Empenhado (R$)",
    "Valor Liquidado (R$)",
    "Valor Pago (R$)",
    "Valor Restos a Pagar Inscritos (R$)",
    "Valor Restos a Pagar Cancelado (R$)",
    "Valor Restos a Pagar Pagos (R$)",
]

# ----------------------------------------------------------------------------
# Função auxiliar: conversão de valor monetário brasileiro para float
# ----------------------------------------------------------------------------
def valor_br_para_float(serie: pd.Series) -> pd.Series:
    """
    Converte uma coluna de texto no padrão brasileiro para float.
    Ex.: "1.234.567,89" -> 1234567.89 | "14400,00" -> 14400.0

    Passos:
      1. remove o ponto (separador de milhar), se houver
      2. troca a vírgula (decimal) por ponto
      3. converte para número; valores inválidos viram NaN (errors='coerce')
    """
    return (
        serie.astype(str)
             .str.replace(".", "", regex=False)   # tira separador de milhar
             .str.replace(",", ".", regex=False)   # vírgula decimal -> ponto
             .pipe(pd.to_numeric, errors="coerce")  # texto -> float
    )

# ----------------------------------------------------------------------------
# Localização dos arquivos de origem
# ----------------------------------------------------------------------------
# Padrão dos nomes: AAAAMM_Despesas.csv  (ex.: 202501_Despesas.csv)
padrao = os.path.join(PASTA_BRUTOS, "*_Despesas.csv")
arquivos = sorted(glob.glob(padrao))

if not arquivos:
    raise FileNotFoundError(
        f"Nenhum arquivo encontrado em:\n{PASTA_BRUTOS}\n"
        f"Confira se o caminho está correto e se os CSVs estão lá."
    )

print(f"Encontrados {len(arquivos)} arquivos para processar.\n")

# ----------------------------------------------------------------------------
# Leitura e limpeza de cada arquivo mensal
# ----------------------------------------------------------------------------
lista_dataframes = []  # acumula cada mês para concatenação ao final

for caminho in arquivos:
    nome = os.path.basename(caminho)

    # LEITURA: dtype=str força TODAS as colunas a serem lidas como texto.
    # Isso preserva códigos com zero à esquerda (ex.: "08" não vira 8).
    df = pd.read_csv(
        caminho,
        sep=SEPARADOR,
        encoding=ENCODING_ORIGEM,
        dtype=str,
    )

    # CONVERSÃO das 6 colunas de valor para número.
    for coluna in COLUNAS_VALOR:
        df[coluna] = valor_br_para_float(df[coluna])

    # DERIVAÇÃO das colunas de partição a partir de "2025/01":
    #   ano = "2025"  |  mes = "01"
    # Mantemos como texto de 2 dígitos no mês para ordenar corretamente depois.
    df["ano"] = df[COLUNA_DATA].str.split("/").str[0]
    df["mes"] = df[COLUNA_DATA].str.split("/").str[1]

    lista_dataframes.append(df)
    print(f"  OK: {nome}  ->  {len(df):,} linhas".replace(",", "."))

# ----------------------------------------------------------------------------
# Consolidação em um único conjunto
# ----------------------------------------------------------------------------
print("\nConsolidando todos os meses em um único conjunto...")
df_final = pd.concat(lista_dataframes, ignore_index=True)

# ----------------------------------------------------------------------------
# Gravação do baseline consolidado (UTF-8)
# ----------------------------------------------------------------------------
os.makedirs(PASTA_SAIDA, exist_ok=True)  # cria a pasta de saída se não existir

df_final.to_csv(
    ARQUIVO_SAIDA,
    sep=SEPARADOR,        # mantém ';' (nomes de órgãos contêm vírgulas)
    encoding="utf-8",     # agora em UTF-8 (acentos corretos no Athena)
    index=False,          # não gravar o índice do pandas como coluna
)

# ----------------------------------------------------------------------------
# Relatório de validação
# ----------------------------------------------------------------------------
tamanho_mb = os.path.getsize(ARQUIVO_SAIDA) / (1024 * 1024)

print("\n" + "=" * 70)
print(" RELATÓRIO DE VALIDAÇÃO — BASELINE LIMPO")
print("=" * 70)
print(f" Arquivos lidos ............: {len(arquivos)}")
print(f" Total de linhas ...........: {len(df_final):,}".replace(",", "."))
print(f" Total de colunas ..........: {df_final.shape[1]}")
print(f" Tamanho do arquivo (MB) ...: {tamanho_mb:,.1f}".replace(",", "."))
print(f" Anos presentes ............: {sorted(df_final['ano'].unique())}")
print(f" Nº de partições (ano/mes) .: {df_final.groupby(['ano','mes']).ngroups}")
print("-" * 70)
print(" Soma de controle (para conferência posterior no Athena):")
total_pago = df_final["Valor Pago (R$)"].sum()
print(f"   Soma de 'Valor Pago (R$)': {total_pago:,.2f}".replace(",", "@").replace(".", ",").replace("@", "."))
print("-" * 70)
print(" Amostra (5 primeiras linhas, colunas selecionadas):")
print(df_final[["ano", "mes", "Nome Órgão Superior", "Valor Pago (R$)"]].head())
print("=" * 70)
print(f"\nArquivo baseline salvo em:\n{ARQUIVO_SAIDA}")