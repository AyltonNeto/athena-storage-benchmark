# Impacto do particionamento e do formato de armazenamento no custo e no desempenho de consultas analíticas em data lakes na AWS

Repositório de reprodutibilidade do artigo de conclusão do MBA em Engenharia de Dados (Escola Politécnica / UFRJ).

Estudo experimental que mede, de forma controlada, como o **formato de armazenamento** (CSV vs. Apache Parquet), o **particionamento** e o **codec de compressão** (Snappy, GZIP, ZSTD) afetam o **custo** e o **tempo de execução** de consultas no **Amazon Athena**.

---

## Principal achado

**Custo e desempenho não respondem proporcionalmente às mesmas otimizações.**

A conversão para formato colunar reduz o volume varrido — e, portanto, o custo — em até **99,8%**, de forma consistente. Mas essa economia **não se traduz automaticamente em consultas mais rápidas**: o ganho de tempo só aparece quando a consulta ativa os mecanismos de poda (*partition pruning* / *column pruning*). Em consultas sem filtro, o tempo permaneceu indistinguível do CSV, apesar da redução massiva de bytes lidos.

Um teste complementar de consolidação de arquivos mostrou ainda que o *small files problem* é um **fenômeno dependente de escala**: penaliza o armazenamento de forma consistente, mas seu efeito sobre o tempo só se manifesta em volumes grandes.

---

## Desenho experimental

- **Dataset:** Despesas (Execução da Despesa) do [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao) — 2023 a 2025.
- **Volume:** 2.381.305 registros, 47 colunas, ~1,7 GB.
- **8 layouts** combinando formato × particionamento × codec, mais **2 layouts consolidados** para o teste de causalidade.
- **6 consultas** desenhadas para isolar cada mecanismo (leitura colunar, poda de partição, agregação), incluindo duas contraprovas deliberadas.
- **240 medições de tempo** (48 combinações × 5 execuções), reportadas por mediana e desvio-padrão.
- **Custo total do experimento:** inferior a US$ 1.

### Matriz de layouts

| Layout | Formato | Particionado | Codec |
|---|---|---|---|
| csv_base | CSV | Não | — |
| csv_particionado | CSV | Sim | — |
| parquet_snappy | Parquet | Não | Snappy |
| parquet_snappy_part | Parquet | Sim | Snappy |
| parquet_gzip | Parquet | Não | GZIP |
| parquet_gzip_part | Parquet | Sim | GZIP |
| parquet_zstd | Parquet | Não | ZSTD |
| parquet_zstd_part | Parquet | Sim | ZSTD |
| parquet_gzip_unico | Parquet | Não | GZIP (1 arquivo) |
| parquet_gzip_part_unico | Parquet | Sim | GZIP (1 arq/partição) |

---

## Estrutura do repositório

```
.
├── scripts/
│   ├── 01_limpeza_dados_brutos.py      Consolidação e limpeza dos 36 CSVs (Python/pandas)
│   ├── 02_athena_setup_baseline.sql    Database + tabela externa do CSV base
│   ├── 03_athena_geracao_layouts.sql   CTAS dos 8 layouts (formato × partição × codec)
│   ├── 04_athena_benchmark_marcado.sql As 6 consultas × 8 layouts, com marcadores
│   ├── 05_corrige_csv_particionado.sql Correção do CSV particionado (compressão nula)
│   └── 06_layouts_unicos_gzip.sql      Teste de consolidação (bucketing, 2 layouts)
├── resultados/
│   ├── medicoes_completas.csv          As 5 execuções de cada combinação (60 linhas)
│   └── resumo_medianas.csv             Mediana e desvio por combinação
├── figuras/                            As 6 figuras do artigo
├── docs/
│   └── ambiente_aws.md                 Região, bucket, salvaguardas e protocolo
├── LICENSE
└── README.md
```

---

## Como reproduzir

### 1. Obter os dados
Baixe os arquivos mensais de Despesas — Execução da Despesa em
<https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao>
para o período de janeiro/2023 a dezembro/2025 (36 arquivos CSV).

> Os dados brutos não são versionados neste repositório por serem públicos e volumosos (~1,7 GB). O script de preparação assume os CSVs mensais como entrada.

### 2. Preparar os dados
```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .\.venv\Scripts\activate
pip install pandas pyarrow
python scripts/01_limpeza_dados_brutos.py
```
Isso consolida os 36 arquivos, corrige o encoding (ISO-8859-1 → UTF-8), normaliza os valores monetários e deriva as colunas de partição. Saída: um CSV consolidado com soma de controle **R$ 13.483.863.145.256,05** (âncora de integridade).

### 3. Configurar o ambiente AWS
Veja [`docs/ambiente_aws.md`](docs/ambiente_aws.md) para região, bucket, salvaguardas de custo e configuração do Athena.

### 4. Gerar os layouts e executar o benchmark
Execute, na ordem, os scripts SQL de `scripts/` no editor do Athena. Cada consulta reporta o volume varrido e o tempo; registre-os conforme o protocolo (cache desabilitado, 5 execuções por combinação).

---

## Stack

`Python (pandas, pyarrow)` · `Amazon S3` · `Amazon Athena (Presto/Trino)` · `Apache Parquet` · `SQL`

---

## Autor

**Aylton Vieira Da Silva Neto**
MBA em Engenharia de Dados — Escola Politécnica / UFRJ
Orientador: Prof. Manoel Villas Boas Júnior, D. Sc.

## Licença

Código sob licença MIT (ver `LICENSE`). Os dados de origem são públicos, disponibilizados pela Controladoria-Geral da União no Portal da Transparência.
