-- =============================================================================
--  04_athena_benchmark_marcado.sql
--  As seis consultas de referência, executadas sobre os oito layouts (48 no total).
-- =============================================================================
--  Cada consulta traz um marcador em comentário (/* Qn_layout */) que aparece no
--  histórico de "Consultas recentes" do Athena, permitindo rastrear cada execução.
--
--  Protocolo de coleta:
--    - Executar uma consulta por vez.
--    - Desabilitar a reutilização de resultados em cache antes de medir.
--    - Registrar o volume varrido (determinístico, uma medição) e o tempo de
--      execução (cinco execuções por combinação; reportar mediana e desvio).
--
--  Mecanismo avaliado por consulta:
--    Q1  SELECT de 3 colunas, sem filtro      -> leitura seletiva de colunas
--    Q2  SELECT *, sem filtro                 -> limite da vantagem colunar
--    Q3  filtro por 1 mês (chave de partição) -> poda de partições (fina)
--    Q4  filtro por 1 ano (chave de partição) -> poda de partições (grossa)
--    Q5  filtro por órgão (não particionado)  -> filtro sem poda de partição
--    Q6  agregação com GROUP BY               -> carga analítica representativa
-- =============================================================================


-- #########################################################################
--  Q1 — SELECT de poucas colunas, sem filtro (leitura seletiva de colunas)
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

SELECT /* Q2_csv_base */ * FROM projeto_despesas.csv_base;
SELECT /* Q2_csv_particionado */ * FROM projeto_despesas.csv_particionado;
SELECT /* Q2_parquet_snappy */ * FROM projeto_despesas.parquet_snappy;
SELECT /* Q2_parquet_snappy_part */ * FROM projeto_despesas.parquet_snappy_part;
SELECT /* Q2_parquet_gzip */ * FROM projeto_despesas.parquet_gzip;
SELECT /* Q2_parquet_gzip_part */ * FROM projeto_despesas.parquet_gzip_part;
SELECT /* Q2_parquet_zstd */ * FROM projeto_despesas.parquet_zstd;
SELECT /* Q2_parquet_zstd_part */ * FROM projeto_despesas.parquet_zstd_part;


-- #########################################################################
--  Q3 — Filtro por 1 mês (poda de partições, máxima seletividade)
-- #########################################################################

SELECT /* Q3_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd WHERE ano = '2024' AND mes = '03';

SELECT /* Q3_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part WHERE ano = '2024' AND mes = '03';


-- #########################################################################
--  Q4 — Filtro por 1 ano (poda de partições, seletividade parcial)
-- #########################################################################

SELECT /* Q4_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base WHERE ano = '2024';

SELECT /* Q4_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado WHERE ano = '2024';

SELECT /* Q4_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy WHERE ano = '2024';

SELECT /* Q4_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part WHERE ano = '2024';

SELECT /* Q4_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip WHERE ano = '2024';

SELECT /* Q4_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part WHERE ano = '2024';

SELECT /* Q4_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd WHERE ano = '2024';

SELECT /* Q4_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part WHERE ano = '2024';


-- #########################################################################
--  Q5 — Filtro por órgão (coluna não particionada; não aciona poda)
-- #########################################################################

SELECT /* Q5_csv_base */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_base WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_csv_particionado */ nome_orgao_superior, valor_pago
FROM projeto_despesas.csv_particionado WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_snappy */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_snappy_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_snappy_part WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_gzip */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_gzip_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_zstd */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd WHERE nome_orgao_superior = 'Ministério da Educação';

SELECT /* Q5_parquet_zstd_part */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_zstd_part WHERE nome_orgao_superior = 'Ministério da Educação';


-- #########################################################################
--  Q6 — Agregação com GROUP BY (carga analítica representativa)
-- #########################################################################

SELECT /* Q6_csv_base */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.csv_base GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_csv_particionado */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.csv_particionado GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_snappy */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_snappy GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_snappy_part */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_snappy_part GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_gzip */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_gzip_part */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip_part GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_zstd */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_zstd GROUP BY nome_orgao_superior ORDER BY total_pago DESC;

SELECT /* Q6_parquet_zstd_part */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_zstd_part GROUP BY nome_orgao_superior ORDER BY total_pago DESC;
