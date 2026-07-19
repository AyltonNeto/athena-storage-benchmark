# Impacto do particionamento e do formato de armazenamento no custo e no desempenho de consultas analíticas em data lakes na AWS

Repositório de reprodutibilidade do artigo de conclusão do MBA em Engenharia de Dados (Escola Politécnica / UFRJ).

Estudo experimental que mede, de forma controlada, como o **formato de armazenamento** (CSV vs. Apache Parquet), o **particionamento** e o **codec de compressão** (Snappy, GZIP, ZSTD) afetam o **custo** e o **tempo de execução** de consultas no **Amazon Athena**.

---

## Principal achado

**Custo e desempenho não respondem proporcionalmente às mesmas otimizações.**

A conversão para formato colunar reduz o volume varrido — e, portanto, o custo — em **99,2% a 99,99%** nas consultas com seletividade de colunas, de forma consistente. Mas essa economia **não se traduz automaticamente em consultas mais rápidas**: o ganho de tempo só aparece quando a leitura ainda responde por parcela dominante do tempo de execução. Nas consultas que devolvem milhões de linhas (Q1 e Q2), o tempo permaneceu indistinguível do CSV apesar da redução massiva de bytes lidos, porque a materialização do resultado — indiferente ao formato de origem — passa a dominar a latência. A consulta de agregação percorre os mesmos 2,38 milhões de registros e, ainda assim, executou 3,4× mais rápido em Parquet: o que separa os dois grupos é o tamanho do resultado, não o volume percorrido.

**O custo também tem um piso.** O Athena arredonda o volume varrido para o megabyte superior e cobra no mínimo 10 MB por consulta. Nos layouts particionados, as consultas mais seletivas caem abaixo desse limiar: a redução de 99,99% no volume varrido da Q3 converte-se em 99,43% no valor faturado. A economia proporcional aos bytes lidos é determinística acima de 10 MB por consulta e nula abaixo disso.

Um teste complementar de consolidação de arquivos mostrou ainda que a fragmentação **penaliza o armazenamento de forma consistente e mensurável** (consolidar reduziu 25,6% do espaço e 20,1% do volume varrido no layout particionado), mas **não produziu efeito detectável sobre o tempo** na escala avaliada — nenhuma das seis consultas apresentou diferença significativa (p ≥ 0,095). A interpretação proposta é que o *small files problem* seja um fenômeno dependente de escala, previsão que este experimento não tem porte para verificar.

---

## Desenho experimental

- **Dataset:** Despesas (Execução da Despesa) do [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao) — 2023 a 2025.
- **Volume:** 2.381.305 registros, 47 colunas originais (49 após a derivação de `ano` e `mes`), ~1,7 GB.
- **8 layouts** combinando formato × particionamento × codec, mais **2 layouts consolidados** para o teste de causalidade da fragmentação.
- **6 consultas** desenhadas para isolar cada mecanismo (leitura colunar, poda de partição, agregação), incluindo duas contraprovas deliberadas.
- **300 medições de tempo** (60 combinações × 5 execuções), reportadas por mediana e desvio-padrão, com teste de Mann-Whitney nas comparações controladas.
- **Ambiente:** Amazon Athena **engine version 3**, região us-east-1, cache de resultados desabilitado.
- **Custo total do experimento:** inferior a US$ 1.

### Matriz de layouts

| Layout | Formato | Particionado | Codec | Arquivos |
|---|---|---|---|---|
| csv_base | CSV | Não | — | 1 |
| csv_particionado | CSV | Sim | — | 360 |
| parquet_snappy | Parquet | Não | Snappy | 10 |
| parquet_snappy_part | Parquet | Sim | Snappy | 360 |
| parquet_gzip | Parquet | Não | GZIP | 10 |
| parquet_gzip_part | Parquet | Sim | GZIP | 360 |
| parquet_zstd | Parquet | Não | ZSTD | 10 |
| parquet_zstd_part | Parquet | Sim | ZSTD | 360 |
| parquet_gzip_unico | Parquet | Não | GZIP | 1 |
| parquet_gzip_part_unico | Parquet | Sim | GZIP | 36 |

Os dois últimos pertencem ao teste de consolidação (isolam a fragmentação em arquivos).

---

## Estrutura do repositório

```
.
├── scripts/
│   ├── 01_limpeza_dados_brutos.py      Consolidação e limpeza dos 36 CSVs (Python/pandas)
│   ├── 02_athena_setup_baseline.sql    Database + tabela externa do CSV base
│   ├── 03_athena_geracao_layouts.sql   CTAS dos 8 layouts (formato × partição × codec)
│   ├── 04_athena_benchmark_marcado.sql As 6 consultas × 8 layouts, com marcadores
│   └── 05_layouts_unicos_gzip.sql      Teste de causalidade da fragmentação (bucketing)
├── resultados/
│   ├── medicoes_completas.csv          As 5 execuções de cada combinação (60 linhas)
│   ├── resumo_medianas.csv             Mediana e desvio por combinação (Tabelas 1, 3 e 7)
│   └── armazenamento_s3.csv            Tamanho no S3 e nº de arquivos por layout (Tabelas 5 e 6)
├── figuras/                            As 6 figuras do artigo
├── docs/
│   ├── ambiente_aws.md                 Região, bucket, salvaguardas e protocolo
│   └── img/                            Capturas de tela do ambiente (evidências de execução)
├── LICENSE
└── README.md
```

### Capturas do ambiente (`docs/img/`)

Registros visuais das etapas executadas no console da AWS. Não fazem parte do artigo:
servem como evidência de execução e apoio à reprodução por terceiros. Estão referenciadas
em contexto no documento [`docs/ambiente_aws.md`](docs/ambiente_aws.md).

| Arquivo | Etapa registrada |
|---|---|
| `dados_origem.png` | Página de download dos dados no Portal da Transparência |
| `dados_brutos.png` | Os 36 arquivos CSV mensais baixados, antes do tratamento |
| `bucket.png` | Organização dos prefixos do bucket S3 (um por layout) |
| `bucket_file.png` | Objetos de um layout não particionado |
| `bucket_partition.png` | Estrutura de diretórios `ano=XXXX/mes=YY` de um layout particionado |
| `athena_engine.png` | Grupo de trabalho e mecanismo de análise em uso (Athena engine version 3) |
| `athena_config.png` | Configuração do grupo de trabalho (limite de dados varridos e cache desabilitado) |
| `athena_tables.png` | Tabelas do database `projeto_despesas` após a geração dos layouts |
| `athena_query.png` | Execução de uma consulta de benchmark no editor |
| `athena_results.png` | Painel de resultados com volume varrido e tempo de execução |
| `bucket_tamanhos.png` | Tamanho no S3 de cada prefixo de layout (origem da Tabela 5) |
| `bucket_particionado_calculo.png` | Cálculo do tamanho total do layout `csv_particionado`, por ano |
| `baseline_propriedades.png` | Propriedades do arquivo `despesas_baseline.csv` (tamanho exato em bytes) |

### Origem dos dados de armazenamento

Os valores de `resultados/armazenamento_s3.csv` foram coletados no console do Amazon S3 e
correspondem às Tabelas 5 e 6 do artigo. Duas observações sobre a precisão:

- Os tamanhos são reportados pelo console com **uma casa decimal**, e o arquivo preserva essa
  precisão — nenhum valor foi refinado além do que a fonte oferece.
- Para `csv_base`, o console exibe apenas "1.7 GB" no nível do prefixo. O valor de 1748,4 MB foi
  obtido das propriedades do arquivo `despesas_baseline.csv` (1.833.378.156 bytes ÷ 1.048.576),
  que é o único objeto sob `01-raw-csv/`. O mesmo critério vale para `csv_particionado`, cujo
  total resulta da soma dos três prefixos anuais.

---

## Como reproduzir

### 1. Obter os dados
Baixe os arquivos mensais de Despesas — Execução da Despesa em
<https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao>
para o período de janeiro/2023 a dezembro/2025 (36 arquivos CSV).

> Os dados brutos não são versionados neste repositório por serem públicos e volumosos (~1,7 GB).

### 2. Preparar os dados
```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .\.venv\Scripts\activate
pip install pandas
python scripts/01_limpeza_dados_brutos.py
```
Consolida os 36 arquivos, corrige o encoding (ISO-8859-1 → UTF-8), normaliza os valores monetários e deriva as colunas de partição. Soma de controle esperada (valor_pago): **R$ 13.483.863.145.256,05**.

### 3. Configurar o ambiente AWS
Veja [`docs/ambiente_aws.md`](docs/ambiente_aws.md) para região, bucket, salvaguardas de custo e protocolo de medição. Os scripts SQL usam `<bucket>` como marcador — substitua pelo nome do seu bucket.

### 4. Executar no Athena
Rode os scripts SQL na ordem (02 → 03 → 04 → 05). Cada consulta de benchmark reporta o volume varrido e o tempo; registre-os conforme o protocolo (cache desabilitado, 5 execuções por combinação).

> Os tempos reportados aqui foram obtidos na **Athena engine version 3**. Versões distintas do
> motor adotam estratégias diferentes de planejamento, paralelismo e leitura de arquivos
> colunares — confirme a versão do seu grupo de trabalho antes de comparar resultados.

---

## Stack

`Python (pandas)` · `Amazon S3` · `Amazon Athena (Presto/Trino)` · `Apache Parquet` · `SQL`

---

## Autor

**Aylton Vieira Da Silva Neto**
MBA em Engenharia de Dados — Escola Politécnica / UFRJ
Orientador: Prof. Manoel Villas Boas Júnior, D. Sc.

## Licença

Código sob licença MIT (ver `LICENSE`). Os dados de origem são públicos, disponibilizados pela Controladoria-Geral da União no Portal da Transparência.
