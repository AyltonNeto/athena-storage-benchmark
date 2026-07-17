-- =============================================================================
--  09_layouts_unicos_gzip.sql
--  TESTE DE CAUSALIDADE - isolar FRAGMENTACAO de PARTICIONAMENTO
--  Codec: GZIP (padrao do Athena). Cria 2 layouts consolidados (1 arquivo).
--  Metodo: BUCKETING (bucket_count = 1) - recomendado pela documentacao AWS.
-- =============================================================================
--  QUARTETO DE COMPARACAO (2 ja existem, 2 criados aqui):
--    parquet_gzip            ja existe   | nao part. | 10 arquivos
--    parquet_gzip_part       ja existe   | part.     | 360 arquivos
--    parquet_gzip_unico      NOVO (09)   | nao part. | 1 arquivo
--    parquet_gzip_part_unico NOVO (10)   | part.     | 36 arquivos (1/particao)
--
--  METODO - por que bucketing:
--    A AWS documenta o bucketing como a forma de controlar o numero de arquivos
--    de saida de um CTAS. Com bucket_count = 1 pedimos 1 arquivo por particao
--    (ou 1 arquivo total, se nao particionado). A chave de bucket deve ser uma
--    coluna de ALTA CARDINALIDADE e NAO pode ser coluna de particao - usamos
--    nome_orgao_superior (dezenas de valores distintos, bem distribuido).
--
--  LIMITE RESPEITADO:
--    Athena permite no maximo 100 particoes/buckets por CTAS.
--    Layout 10: 36 particoes x 1 bucket = 36  (OK, <= 100).
--    Layout 09: 0 particoes  x 1 bucket = 1   (OK).
--
--  RESSALVA (documentada pela AWS): o numero de arquivos criados pode nao
--  corresponder EXATAMENTE ao bucket_count. Por isso conferimos no S3 (ver fim).
--
--  As COLUNAS e a logica sao IDENTICAS ao 03_athena_geracao_layouts.sql.
--  As 6 queries de benchmark NAO mudam - so troca o nome da tabela.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LAYOUT 09 - parquet_gzip_unico  (Parquet, NAO particionado, GZIP, 1 arquivo)
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip_unico
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://projeto-mbed4/09-parquet-gzip-unico/',
  bucketed_by = ARRAY['nome_orgao_superior'],
  bucket_count = 1
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
-- LAYOUT 10 - parquet_gzip_part_unico  (Parquet, particionado, GZIP, 1 arq/part)
-- -----------------------------------------------------------------------------
-- NOTA: quando se combina particao + bucketing, o particionamento vem primeiro
-- (define as pastas) e o bucketing atua DENTRO de cada particao. Com bucket_count
-- = 1, cada uma das 36 particoes recebe 1 arquivo -> 36 arquivos no total.
CREATE TABLE projeto_despesas.parquet_gzip_part_unico
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://projeto-mbed4/10-parquet-gzip-part-unico/',
  partitioned_by = ARRAY['ano', 'mes'],
  bucketed_by = ARRAY['nome_orgao_superior'],
  bucket_count = 1
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
--  VALIDACAO DE INTEGRIDADE (rodar apos criar) - deve dar 2381305 e a soma ancora
-- =============================================================================
SELECT 'parquet_gzip_unico'      AS layout, COUNT(*) AS linhas, SUM(valor_pago) AS soma
FROM projeto_despesas.parquet_gzip_unico
UNION ALL
SELECT 'parquet_gzip_part_unico', COUNT(*), SUM(valor_pago)
FROM projeto_despesas.parquet_gzip_part_unico;

-- Se o particionado retornar 0 linhas logo apos criar:
--   MSCK REPAIR TABLE projeto_despesas.parquet_gzip_part_unico;


-- =============================================================================
--  CONFERENCIA NO S3 (contagem de arquivos de dados, ignorando o marcador de pasta)
--    09-parquet-gzip-unico/       -> esperado: 1 arquivo
--    10-parquet-gzip-part-unico/  -> esperado: 36 arquivos (1 por ano=XXXX/mes=YY)
--
--  Se as contagens nao baterem exatamente (a AWS avisa que bucket_count nem
--  sempre e exato), me avise - mas mesmo 1-2 arquivos por particao ja reduz
--  drasticamente a fragmentacao de 10/particao e serve ao teste.
-- =============================================================================


-- =============================================================================
--  BENCHMARK - as MESMAS 6 queries do 05, trocando so o nome da tabela.
--  5 execucoes cada, cache DESLIGADO. Anotar tempo e MB varrido na planilha.
-- =============================================================================

-- Q1
SELECT /* Q1_parquet_gzip_unico */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip_unico;
SELECT /* Q1_parquet_gzip_part_unico */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico;

-- Q2
SELECT /* Q2_parquet_gzip_unico */ *
FROM projeto_despesas.parquet_gzip_unico;
SELECT /* Q2_parquet_gzip_part_unico */ *
FROM projeto_despesas.parquet_gzip_part_unico;

-- Q3
SELECT /* Q3_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico
WHERE ano = '2024' AND mes = '03';
SELECT /* Q3_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico
WHERE ano = '2024' AND mes = '03';

-- Q4
SELECT /* Q4_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico
WHERE ano = '2024';
SELECT /* Q4_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico
WHERE ano = '2024';

-- Q5
SELECT /* Q5_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico
WHERE nome_orgao_superior = 'Ministério da Educação';
SELECT /* Q5_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico
WHERE nome_orgao_superior = 'Ministério da Educação';

-- Q6
SELECT /* Q6_parquet_gzip_unico */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip_unico
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;
SELECT /* Q6_parquet_gzip_part_unico */ nome_orgao_superior,
       SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip_part_unico
GROUP BY nome_orgao_superior
ORDER BY total_pago DESC;
