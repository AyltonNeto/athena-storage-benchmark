-- =============================================================================
--  02_athena_setup_baseline.sql
--  SETUP DO EXPERIMENTO — database + tabela do CSV base (recomeço limpo)
-- =============================================================================
--  Pré-requisitos:
--    - Região: us-east-1
--    - Local de resultados do Athena: s3://projeto-mbed4/athena-results/
--    - O CSV base já está em: s3://projeto-mbed4/01-raw-csv/despesas_baseline.csv
--
--  IMPORTANTE (limpeza do experimento anterior):
--    Se você recriou o bucket ou moveu o CSV, ajuste o LOCATION abaixo.
--    Se ainda existirem as tabelas antigas, remova-as antes (opcional):
--      DROP TABLE IF EXISTS projeto_despesas.despesas_csv;
--      DROP TABLE IF EXISTS projeto_despesas.despesas_parquet_simples;
--      DROP TABLE IF EXISTS projeto_despesas.despesas_parquet_particionado;
--      DROP TABLE IF EXISTS projeto_despesas.despesas_parquet_zstd;
--    E esvazie as pastas 01 a 05 no S3 (o CTAS não sobrescreve pasta com dado).
-- =============================================================================


-- 1) Database (namespace) do projeto.
CREATE DATABASE IF NOT EXISTS projeto_despesas;


-- 2) Tabela do CSV base (Layout 1). Só lê o arquivo, não copia dado.
--    Tipagem: códigos/nomes como STRING (preserva zeros à esquerda);
--             as 6 colunas de valor como DOUBLE.
CREATE EXTERNAL TABLE IF NOT EXISTS projeto_despesas.csv_base (
  ano_mes_lancamento                  string,
  codigo_orgao_superior               string,
  nome_orgao_superior                 string,
  codigo_orgao_subordinado            string,
  nome_orgao_subordinado              string,
  codigo_unidade_gestora              string,
  nome_unidade_gestora                string,
  codigo_gestao                       string,
  nome_gestao                         string,
  codigo_unidade_orcamentaria         string,
  nome_unidade_orcamentaria           string,
  codigo_funcao                       string,
  nome_funcao                         string,
  codigo_subfuncao                    string,
  nome_subfuncao                      string,
  codigo_programa_orcamentario        string,
  nome_programa_orcamentario          string,
  codigo_acao                         string,
  nome_acao                           string,
  codigo_plano_orcamentario           string,
  plano_orcamentario                  string,
  codigo_programa_governo             string,
  nome_programa_governo               string,
  uf                                  string,
  municipio                           string,
  codigo_subtitulo                    string,
  nome_subtitulo                      string,
  codigo_localizador                  string,
  nome_localizador                    string,
  sigla_localizador                   string,
  descricao_complementar_localizador  string,
  codigo_autor_emenda                 string,
  nome_autor_emenda                   string,
  codigo_categoria_economica          string,
  nome_categoria_economica            string,
  codigo_grupo_despesa                string,
  nome_grupo_despesa                  string,
  codigo_elemento_despesa             string,
  nome_elemento_despesa               string,
  codigo_modalidade_despesa           string,
  modalidade_despesa                  string,
  valor_empenhado                     double,
  valor_liquidado                     double,
  valor_pago                          double,
  valor_restos_pagar_inscritos        double,
  valor_restos_pagar_cancelado        double,
  valor_restos_pagar_pagos            double,
  ano                                 string,
  mes                                 string
)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ';'
LOCATION 's3://projeto-mbed4/01-raw-csv/'
TBLPROPERTIES ('skip.header.line.count'='1');


-- 3) Validação do baseline. Deve retornar:
--    total_linhas = 2381305 | soma_valor_pago = 13483863145256.05
SELECT COUNT(*) AS total_linhas, SUM(valor_pago) AS soma_valor_pago
FROM projeto_despesas.csv_base;
