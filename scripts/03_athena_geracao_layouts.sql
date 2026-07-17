-- =============================================================================
--  03_athena_geracao_layouts.sql
--  Geração dos sete layouts derivados do CSV base, via CTAS.
-- =============================================================================
--  Todos os layouts derivam de projeto_despesas.csv_base, garantindo dado
--  idêntico entre eles. As colunas de partição (ano, mes) são re-derivadas de
--  ano_mes_lancamento dentro de cada CTAS.
--
--  O desenho isola três variáveis, uma por vez: formato (CSV vs. Parquet),
--  particionamento (presente vs. ausente) e codec (Snappy, GZIP, ZSTD).
--
--  Layouts gerados (csv_base já foi criado no script 02):
--    csv_particionado      CSV     | particionado     | sem compressão
--    parquet_snappy        Parquet | não particionado | Snappy
--    parquet_snappy_part   Parquet | particionado     | Snappy
--    parquet_gzip          Parquet | não particionado | GZIP
--    parquet_gzip_part     Parquet | particionado     | GZIP
--    parquet_zstd          Parquet | não particionado | ZSTD
--    parquet_zstd_part     Parquet | particionado     | ZSTD
--
--  Execução: um bloco por vez. Cada CTAS lê o CSV base (~1,7 GB) uma vez.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- csv_particionado  —  CSV particionado por ano/mês
-- Isola o efeito do particionamento, sem alterar o formato.
-- write_compression = 'NONE' é obrigatório: sem essa declaração, o Athena aplica
-- GZIP por padrão à saída, o que alteraria duas variáveis ao mesmo tempo
-- (particionamento + compressão) e invalidaria a comparação com o csv_base.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.csv_particionado
WITH (
  format = 'TEXTFILE',
  field_delimiter = ';',
  write_compression = 'NONE',
  external_location = 's3://<bucket>/02-csv-particionado/',
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
-- parquet_snappy  —  Parquet, não particionado, Snappy
-- Isola o efeito do formato colunar (comparado ao csv_base).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_snappy
WITH (
  format = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://<bucket>/03-parquet-snappy/'
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
-- parquet_snappy_part  —  Parquet, particionado, Snappy
-- Isola o efeito do particionamento sobre o formato colunar.
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_snappy_part
WITH (
  format = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://<bucket>/04-parquet-snappy-particionado/',
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
-- parquet_gzip  —  Parquet, não particionado, GZIP
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://<bucket>/05-parquet-gzip/'
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
-- parquet_gzip_part  —  Parquet, particionado, GZIP
-- Codec de referência nas comparações de particionamento (padrão do Athena).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip_part
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://<bucket>/06-parquet-gzip-particionado/',
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
-- parquet_zstd  —  Parquet, não particionado, ZSTD
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_zstd
WITH (
  format = 'PARQUET',
  write_compression = 'ZSTD',
  external_location = 's3://<bucket>/07-parquet-zstd/'
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
-- parquet_zstd_part  —  Parquet, particionado, ZSTD
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_zstd_part
WITH (
  format = 'PARQUET',
  write_compression = 'ZSTD',
  external_location = 's3://<bucket>/08-parquet-zstd-particionado/',
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
--  Validação de integridade — executar após os CTAS.
--  Todas as tabelas devem retornar 2381305 linhas e a mesma soma de controle
--  (~13483863145256.05; variações na última casa decimal são arredondamento de
--  ponto flutuante). Para tabelas particionadas que retornem 0 linhas logo após
--  a criação, executar: MSCK REPAIR TABLE projeto_despesas.<tabela>;
-- =============================================================================
SELECT 'csv_particionado'    AS layout, COUNT(*) AS linhas, SUM(valor_pago) AS soma FROM projeto_despesas.csv_particionado
UNION ALL SELECT 'parquet_snappy',        COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_snappy
UNION ALL SELECT 'parquet_snappy_part',   COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_snappy_part
UNION ALL SELECT 'parquet_gzip',          COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_gzip
UNION ALL SELECT 'parquet_gzip_part',     COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_gzip_part
UNION ALL SELECT 'parquet_zstd',          COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_zstd
UNION ALL SELECT 'parquet_zstd_part',     COUNT(*), SUM(valor_pago) FROM projeto_despesas.parquet_zstd_part;
