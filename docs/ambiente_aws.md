# Ambiente AWS

Configuração utilizada no experimento. Ajuste os nomes de bucket/região conforme seu ambiente.

## Serviços e região
- **Região:** us-east-1 (Norte da Virgínia)
- **Armazenamento:** Amazon S3
- **Motor de consulta:** Amazon Athena (baseado em Presto/Trino)
- **Formato de cobrança:** US$ 5,00 por terabyte de dados varrido

## Origem dos dados

Os 36 arquivos mensais de Despesas — Execução da Despesa são obtidos no Portal da
Transparência, no período de janeiro/2023 a dezembro/2025.

![Página de download dos dados no Portal da Transparência](img/dados_origem.png)

Após o download, os arquivos brutos ficam em um diretório local, ainda em ISO-8859-1 e com
separador `;` — o script `01_limpeza_dados_brutos.py` consolida e trata esse conjunto.

![Arquivos CSV mensais baixados, antes do tratamento](img/dados_brutos.png)

## Bucket e organização
```
s3://<seu-bucket>/
├── 01-raw-csv/                     CSV consolidado (baseline)
├── 02-csv-particionado/            CSV particionado por ano/mês
├── 03-parquet-snappy/
├── 04-parquet-snappy-particionado/
├── 05-parquet-gzip/
├── 06-parquet-gzip-particionado/
├── 07-parquet-zstd/
├── 08-parquet-zstd-particionado/
├── 09-parquet-gzip-unico/          teste de consolidação (1 arquivo)
├── 10-parquet-gzip-part-unico/     teste de consolidação (1 arq/partição)
└── athena-results/                 saída das consultas
```

Um prefixo por layout, o que permite conferir tamanho e número de objetos de cada arranjo
diretamente no console do S3.

![Prefixos do bucket, um por layout](img/bucket.png)

Nos layouts não particionados, os arquivos de dados ficam diretamente sob o prefixo do layout
(10 arquivos, resultado do paralelismo de escrita do motor).

![Objetos de um layout não particionado](img/bucket_file.png)

Nos layouts particionados, o CTAS grava a estrutura hierárquica `ano=XXXX/mes=YY/` — 36
partições no total, cada uma com 10 arquivos.

![Estrutura de diretórios de um layout particionado](img/bucket_partition.png)

## Salvaguardas de custo (recomendado)
- **AWS Budget mensal** com alerta automático (ex.: US$ 10).
- **Data scanned limit por consulta** no grupo de trabalho do Athena (ex.: 2 GB), para cancelar automaticamente qualquer consulta que exceda o limite. Protege contra varreduras acidentais.

![Configurações de consulta do Athena com o limite de dados varridos](img/athena_config.png)

## Protocolo de medição
- **Cache desabilitado:** desligar "Reutilizar resultados da consulta" no editor do Athena antes de medir tempos. Com o cache ativo, execuções repetidas retornam resultados pré-computados e os tempos não refletem processamento real.
- **5 execuções por combinação**, consecutivas, na mesma sessão. Reporta-se mediana e desvio-padrão.
- **Volume varrido** é determinístico (uma medição basta); apenas o **tempo** é repetido.

Após a execução dos scripts 02, 03 e 05, o database `projeto_despesas` contém as dez tabelas
do experimento.

![Tabelas do database projeto_despesas](img/athena_tables.png)

Cada consulta é executada no editor com o marcador de identificação em comentário (ver script 04)…

![Execução de uma consulta de benchmark](img/athena_query.png)

…e o painel de resultados informa as duas métricas primárias: tempo de execução e volume de
dados varrido.

![Painel de resultados com tempo e volume varrido](img/athena_results.png)

## Verificação de integridade
Após materializar cada layout, confirmar:
- Contagem de registros = **2.381.305**
- Soma de controle (`SUM(valor_pago)`) = **R$ 13.483.863.145.256,05**
  (variações na última casa decimal são arredondamento de ponto flutuante, não perda de dado)

Para tabelas particionadas que retornem 0 linhas logo após a criação:
```sql
MSCK REPAIR TABLE projeto_despesas.<nome_da_tabela>;
```
