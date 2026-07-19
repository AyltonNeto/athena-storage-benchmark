-- =============================================================================
--  05_layouts_unicos_gzip.sql
--  Teste de causalidade: isolar a fragmentação de arquivos do particionamento.
-- =============================================================================
--  Objetivo:
--    Os layouts particionados são gravados com 10 arquivos por partição (360 no
--    total), efeito do paralelismo de escrita do motor. Este script cria dois
--    layouts equivalentes em GZIP, porém consolidados em um único arquivo por
--    partição, permitindo verificar quanto da diferença observada se deve à
--    fragmentação e quanto ao particionamento em si.
--
--  Quarteto de comparação (os dois primeiros são criados no script 03):
--    parquet_gzip            não particionado | 10 arquivos
--    parquet_gzip_part       particionado     | 360 arquivos
--    parquet_gzip_unico      não particionado | 1 arquivo       (este script)
--    parquet_gzip_part_unico particionado     | 36 arquivos     (este script)
--
--  Método (bucketing):
--    A documentação da AWS indica o bucketing como forma de controlar o número
--    de arquivos de saída de um CTAS. Com bucket_count = 1 obtém-se um arquivo
--    por partição (ou um arquivo único, quando não há partição). A chave de
--    bucket não pode coincidir com a chave de partição; utiliza-se
--    nome_orgao_superior. Com bucket_count = 1 todas as linhas caem no mesmo
--    bucket, de modo que a cardinalidade da chave é irrelevante para o número
--    de arquivos de saída — a coluna serve apenas para satisfazer a exigência
--    de sintaxe do CTAS.
--
--  Limite do Athena: no máximo 100 combinações de partição/bucket por CTAS.
--    parquet_gzip_part_unico: 36 partições × 1 bucket = 36 (dentro do limite).
--
--  Observação: a AWS registra que o número de arquivos pode não corresponder
--  exatamente ao bucket_count; a contagem real deve ser conferida no S3.
--
--  As colunas e a lógica são idênticas às do script 03. As seis consultas de
--  benchmark (script 04) permanecem inalteradas — muda apenas o nome da tabela.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- parquet_gzip_unico  —  Parquet, não particionado, GZIP, arquivo único
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip_unico
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://<bucket>/09-parquet-gzip-unico/',
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
-- parquet_gzip_part_unico  —  Parquet, particionado, GZIP, 1 arquivo/partição
-- Quando se combinam partição e bucketing, o particionamento define as pastas e
-- o bucketing atua dentro de cada uma; com bucket_count = 1, cada uma das 36
-- partições recebe um arquivo (36 no total).
-- -----------------------------------------------------------------------------
CREATE TABLE projeto_despesas.parquet_gzip_part_unico
WITH (
  format = 'PARQUET',
  write_compression = 'GZIP',
  external_location = 's3://<bucket>/10-parquet-gzip-part-unico/',
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
--  Validação de integridade — 2381305 linhas e a soma de controle em ambos.
-- =============================================================================
SELECT 'parquet_gzip_unico'      AS layout, COUNT(*) AS linhas, SUM(valor_pago) AS soma
FROM projeto_despesas.parquet_gzip_unico
UNION ALL
SELECT 'parquet_gzip_part_unico', COUNT(*), SUM(valor_pago)
FROM projeto_despesas.parquet_gzip_part_unico;

-- Para o layout particionado, caso retorne 0 linhas logo após a criação:
--   MSCK REPAIR TABLE projeto_despesas.parquet_gzip_part_unico;


-- =============================================================================
--  Conferência no S3 (contagem de arquivos de dados, ignorando o marcador de pasta):
--    09-parquet-gzip-unico/       -> esperado: 1 arquivo
--    10-parquet-gzip-part-unico/  -> esperado: 36 arquivos (1 por ano=XXXX/mes=YY)
-- =============================================================================


-- =============================================================================
--  Benchmark — executar as seis consultas do script 04 sobre os dois layouts,
--  trocando apenas o nome da tabela. Cinco execuções por consulta, com o cache
--  do Athena desabilitado; registrar tempo e volume varrido.
-- =============================================================================

-- Q1
SELECT /* Q1_parquet_gzip_unico */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip_unico;
SELECT /* Q1_parquet_gzip_part_unico */ nome_orgao_superior, nome_funcao, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico;

-- Q2
SELECT /* Q2_parquet_gzip_unico */ * FROM projeto_despesas.parquet_gzip_unico;
SELECT /* Q2_parquet_gzip_part_unico */ * FROM projeto_despesas.parquet_gzip_part_unico;

-- Q3
SELECT /* Q3_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico WHERE ano = '2024' AND mes = '03';
SELECT /* Q3_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico WHERE ano = '2024' AND mes = '03';

-- Q4
SELECT /* Q4_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico WHERE ano = '2024';
SELECT /* Q4_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico WHERE ano = '2024';

-- Q5
SELECT /* Q5_parquet_gzip_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_unico WHERE nome_orgao_superior = 'Ministério da Educação';
SELECT /* Q5_parquet_gzip_part_unico */ nome_orgao_superior, valor_pago
FROM projeto_despesas.parquet_gzip_part_unico WHERE nome_orgao_superior = 'Ministério da Educação';

-- Q6
SELECT /* Q6_parquet_gzip_unico */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip_unico GROUP BY nome_orgao_superior ORDER BY total_pago DESC;
SELECT /* Q6_parquet_gzip_part_unico */ nome_orgao_superior, SUM(valor_pago) AS total_pago, COUNT(*) AS qtd_registros
FROM projeto_despesas.parquet_gzip_part_unico GROUP BY nome_orgao_superior ORDER BY total_pago DESC;
