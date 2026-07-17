# Ambiente AWS

Configuração utilizada no experimento. Ajuste os nomes de bucket/região conforme seu ambiente.

## Serviços e região
- **Região:** us-east-1 (Norte da Virgínia)
- **Armazenamento:** Amazon S3
- **Motor de consulta:** Amazon Athena (baseado em Presto/Trino)
- **Formato de cobrança:** US$ 5,00 por terabyte de dados varrido

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

## Salvaguardas de custo (recomendado)
- **AWS Budget mensal** com alerta automático (ex.: US$ 10).
- **Data scanned limit por consulta** no grupo de trabalho do Athena (ex.: 2 GB), para cancelar automaticamente qualquer consulta que exceda o limite. Protege contra varreduras acidentais.

## Protocolo de medição
- **Cache desabilitado:** desligar "Reutilizar resultados da consulta" no editor do Athena antes de medir tempos. Com o cache ativo, execuções repetidas retornam resultados pré-computados e os tempos não refletem processamento real.
- **5 execuções por combinação**, consecutivas, na mesma sessão. Reporta-se mediana e desvio-padrão.
- **Volume varrido** é determinístico (uma medição basta); apenas o **tempo** é repetido.

## Verificação de integridade
Após materializar cada layout, confirmar:
- Contagem de registros = **2.381.305**
- Soma de controle (`SUM(valor_pago)`) = **R$ 13.483.863.145.256,05**
  (variações na última casa decimal são arredondamento de ponto flutuante, não perda de dado)

Para tabelas particionadas que retornem 0 linhas logo após a criação:
```sql
MSCK REPAIR TABLE projeto_despesas.<nome_da_tabela>;
```
