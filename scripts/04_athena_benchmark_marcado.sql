-- =============================================================================
--  05_athena_benchmark_marcado.sql
--  48 queries (6 queries x 8 layouts), cada uma com marcador identificador.
--  Rode UMA POR VEZ. Anote 'Dados verificados' (MB) e 'Tempo (s)' na planilha.
--  O marcador /* ... */ aparece no historico (Consultas recentes) do Athena,
--  permitindo rastrear cada execucao depois, se precisar.
-- =============================================================================


-- #########################################################################
--  Q1 — SELECT poucas colunas, sem filtro (column pruning)
-- #########################################################################

SELECT /* Q1_csv_base */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.csv_base;

SELECT /* Q1_csv_particionado */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.csv_particionado;

SELECT /* Q1_parquet_snappy */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_snappy;

SELECT /* Q1_parquet_snappy_part */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_snappy_part;

SELECT /* Q1_parquet_gzip */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip;

SELECT /* Q1_parquet_gzip_part */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip_part;

SELECT /* Q1_parquet_zstd */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_zstd;

SELECT /* Q1_parquet_zstd_part */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_zstd_part;

-- #########################################################################
--  Q2 — SELECT * (todas as colunas), sem filtro (anti-caso do colunar)
-- #########################################################################

SELECT /* Q2_csv_base */ *
FROM projeto_despesas.csv_base;

SELECT /* Q2_csv_particionado */ *
FROM projeto_despesas.csv_particionado;

SELECT /* Q2_parquet_snappy */ *
FROM projeto_despesas.parquet_snappy;

SELECT /* Q2_parquet_snappy_part */ *
FROM projeto_despesas.parquet_snappy_part;

SELECT /* Q2_parquet_gzip */ *
FROM projeto_despesas.parquet_gzip;

SELECT /* Q2_parquet_gzip_part */ *
FROM projeto_despesas.parquet_gzip_part;

SELECT /* Q2_parquet_zstd */ *
FROM projeto_despesas.parquet_zstd;

SELECT /* Q2_parquet_zstd_part */ *
FROM projeto_despesas.parquet_zstd_part;

-- #########################################################################
--  Q3 — Filtro 1 mes (partition pruning fino)
-- #########################################################################

SELECT /* Q3_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd
WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part
WHERE ano = '2024' AND mes = '03';

-- #########################################################################
--  Q4 — Filtro 1 ano (partition pruning grosso)
-- #########################################################################

SELECT /* Q4_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base
WHERE ano = '2024';

SELECT /* Q4_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado
WHERE ano = '2024';

SELECT /* Q4_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy
WHERE ano = '2024';

SELECT /* Q4_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part
WHERE ano = '2024';

SELECT /* Q4_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip
WHERE ano = '2024';

SELECT /* Q4_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part
WHERE ano = '2024';

SELECT /* Q4_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd
WHERE ano = '2024';

SELECT /* Q4_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part
WHERE ano = '2024';

-- #########################################################################
--  Q5 — Filtro por orgao (coluna NAO particionada)
-- #########################################################################

SELECT /* Q5_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd
WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part
WHERE nome_orgao_superior = 'Ministério da Educação';

-- #########################################################################
--  Q6 — GROUP BY (carga analitica tipica)
-- #########################################################################

SELECT /* Q6_csv_base */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.csv_base
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_csv_particionado */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.csv_particionado
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_snappy */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_snappy
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_snappy_part */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_snappy_part
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_gzip */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_gzip
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_gzip_part */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_gzip_part
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_zstd */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_zstd
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;

SELECT /* Q6_parquet_zstd_part */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago,
       COUNT(*)        AS qtd_registros
FROM projeto_despesas.parquet_zstd_part
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;
