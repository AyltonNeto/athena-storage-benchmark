-- =============================================================================
--  03_athena_geracao_layouts.sql
--  GERAÇÃO DOS 8 LAYOUTS A PARTIR DO CSV BASE (via CTAS)
-- =============================================================================
--  Todos derivam de projeto_despesas.csv_base -> dado idêntico garantido.
--  ano/mes são RE-DERIVADOS de ano_mes_lancamento (coluna limpa), evitando
--  qualquer resíduo de '\r' do fim de linha do Windows.
--
--  MATRIZ DE LAYOUTS:
--    NÚCLEO (6) — rodar todos:
--      1. csv_base                 CSV   | não part. | —        (já criado no setup)
--      2. csv_particionado         CSV   | part.     | —
--      3. parquet_snappy           PARQ  | não part. | SNAPPY
--      4. parquet_snappy_part      PARQ  | part.     | SNAPPY
--      5. parquet_gzip_part        PARQ  | part.     | GZIP
--      6. parquet_zstd_part        PARQ  | part.     | ZSTD
--    OPCIONAIS (2) — rodar se sobrar tempo (completam a matriz codec × partição):
--      7. parquet_gzip             PARQ  | não part. | GZIP
--      8. parquet_zstd             PARQ  | não part. | ZSTD
--
--  Rode um bloco por vez. Cada CTAS lê o CSV base (~1,71 GB) uma vez.
--  Custo total dos 7 CTAS ≈ 7 × US$0,008 ≈ US$0,06 (centavos).
-- =============================================================================

-- Bloco reutilizável de colunas (todas menos ano/mes, que são re-derivadas).
-- Mantido inline em cada CTAS para facilitar copiar/colar bloco a bloco.


-- -----------------------------------------------------------------------------
-- LAYOUT 2 — csv_particionado  (CSV particionado por ano/mes)
-- Isola: o efeito do PARTICIONAMENTO PURO, sem trocar o formato.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.csv_particionado
WITH (
  format = 'TEXTFILE',
  field_delimiter = ';',
  external_location = 's3://projeto-mbed4/02-csv-particionado/',
  partitioned_by = ARRAY['ano', 'mes']
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- -----------------------------------------------------------------------------
-- LAYOUT 3 — parquet_snappy  (Parquet, não particionado, SNAPPY)
-- Isola: o efeito do FORMATO COLUNAR.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_snappy
WITH (
  format = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://projeto-mbed4/03-parquet-snappy/'
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- -----------------------------------------------------------------------------
-- LAYOUT 4 — parquet_snappy_part  (Parquet, particionado, SNAPPY)
-- Isola: o efeito do PARTITION PRUNING (vs. Layout 3).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_snappy_part
WITH (
  format = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://projeto-mbed4/04-parquet-snappy-particionado/',
  partitioned_by = ARRAY['ano', 'mes']
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- -----------------------------------------------------------------------------
-- LAYOUT 5 — parquet_gzip_part  (Parquet, particionado, GZIP)
-- Isola: o CODEC (GZIP vs SNAPPY), com formato e partição constantes.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip_part
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://projeto-mbed4/06-parquet-gzip-particionado/',
  partitioned_by = ARRAY['ano', 'mes']
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- -----------------------------------------------------------------------------
-- LAYOUT 6 — parquet_zstd_part  (Parquet, particionado, ZSTD)
-- Isola: o CODEC (ZSTD vs SNAPPY e GZIP), com formato e partição constantes.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_zstd_part
WITH (
  format = 'PARQUET',
  write_compression = 'ZSTD',
  external_location = 's3://projeto-mbed4/08-parquet-zstd-particionado/',
  partitioned_by = ARRAY['ano', 'mes']
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- =============================================================================
--  OPCIONAIS — rodar só se sobrar tempo (completam a matriz codec × partição)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAYOUT 7 — parquet_gzip  (Parquet, NÃO particionado, GZIP)
-- Permite comparar GZIP com e sem partição (vs. Layout 5).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://projeto-mbed4/05-parquet-gzip/'
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- -----------------------------------------------------------------------------
-- LAYOUT 8 — parquet_zstd  (Parquet, NÃO particionado, ZSTD)
-- Permite comparar ZSTD com e sem partição (vs. Layout 6).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_zstd
WITH (
  format = 'PARQUET',
  write_compression = 'ZSTD',
  external_location = 's3://projeto-mbed4/07-parquet-zstd/'
) AS
SELECT
  ano_mes_lancamento, codigo_orgao_superior, nome_orgao_superior,
  codigo_orgao_subordinado, nome_orgao_subordinado, codigo_unidade_gestora,
  nome_unidade_gestora, codigo_gestao, nome_gestao, codigo_unidade_orcamentaria,
  nome_unidade_orcamentaria, codigo_funcao, nome_funcao, codigo_subfuncao,
  nome_subfuncao, codigo_programa_orcamentario, nome_programa_orcamentario,
  codigo_acao, nome_acao, codigo_plano_orcamentario, plano_orcamentario,
  codigo_programa_governo, nome_programa_governo, uf, municipio,
  codigo_subtitulo, nome_subtitulo, codigo_localizador, nome_localizador,
  sigla_localizador, descricao_complementar_localizador, codigo_autor_emenda,
  nome_autor_emenda, codigo_categoria_economica, nome_categoria_economica,
  codigo_grupo_despesa, nome_grupo_despesa, codigo_elemento_despesa,
  nome_elemento_despesa, codigo_modalidade_despesa, modalidade_despesa,
  valor_empenhado, valor_liquidado, valor_pago, valor_restos_pagar_inscritos,
  valor_restos_pagar_cancelado, valor_restos_pagar_pagos,
  split(ano_mes_lancamento, '/')[1] AS ano,
  split(ano_mes_lancamento, '/')[2] AS mes
FROM projeto_despesas.csv_base;


-- =============================================================================
--  VALIDAÇÃO — rodar após cada CTAS. Todas devem retornar:
--    total_linhas = 2381305 | soma_valor_pago ≈ 13483863145256.05
--  (pequenas variações de arredondamento float na última casa são normais)
--
--  Se uma tabela particionada retornar 0 linhas logo após criar, rode:
--    MSCK REPAIR TABLE projeto_despesas.<nome_da_tabela>;
-- =============================================================================

SELECT 'csv_particionado'    AS layout, COUNT(*) AS linhas, SUM(valor_pago) AS soma FROM projeto_despesas.csv_particionado
UNION ALL SELECT 'parquet_snappy',        COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_snappy
UNION ALL SELECT 'parquet_snappy_part',   COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_snappy_part
UNION ALL SELECT 'parquet_gzip_part',     COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_gzip_part
UNION ALL SELECT 'parquet_zstd_part',     COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_zstd_part
UNION ALL SELECT 'parquet_gzip',          COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_gzip
UNION ALL SELECT 'parquet_zstd',          COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_zstd;
