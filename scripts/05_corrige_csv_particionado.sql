-- =============================================================================
--  06_corrige_csv_particionado.sql
--  CORRECAO: recriar o csv_particionado SEM compressao automatica
-- =============================================================================
--  PROBLEMA IDENTIFICADO:
--    O CTAS anterior gerou o CSV particionado com compressao GZIP automatica
--    (arquivos .gz no S3). Isso mudou DUAS variaveis de uma vez (particionamento
--    + compressao), invalidando a comparacao "baseline vs particionamento puro".
--
--  CORRECAO:
--    Declarar write_compression = 'NONE' para que o CSV saia cru, isolando
--    apenas o efeito do particionamento.
--
--  ANTES DE RODAR:
--    1) Apague a tabela antiga:
--         DROP TABLE projeto_despesas.csv_particionado;
--    2) ESVAZIE a pasta no S3 (o CTAS nao escreve em pasta com dado):
--         s3://projeto-mbed4/02-csv-particionado/
-- =============================================================================


-- Passo 1: remover a tabela antiga
DROP TABLE IF EXISTS projeto_despesas.csv_particionado;


-- Passo 2: (fazer manualmente no console S3) esvaziar a pasta
--          s3://projeto-mbed4/02-csv-particionado/


-- Passo 3: recriar SEM compressao
CREATE TABLE projeto_despesas.csv_particionado
WITH (
  format = 'TEXTFILE',
  field_delimiter = ';',
  write_compression = 'NONE',          -- <<< A CORRECAO: CSV cru, sem gzip
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


-- Passo 4: validar (deve dar 2381305 linhas e a soma de controle)
SELECT COUNT(*) AS linhas, SUM(valor_pago) AS soma
FROM projeto_despesas.csv_particionado;


-- Passo 5: CONFERIR NO S3 que os arquivos agora sao .csv (ou sem extensao),
--          e NAO .gz. Se ainda vierem .gz, me avise.


-- =============================================================================
--  DEPOIS DE RECRIAR: refazer as 6 queries SO para o layout csv_particionado
--  e atualizar a planilha (linhas do layout 2 em cada bloco de query).
-- =============================================================================
