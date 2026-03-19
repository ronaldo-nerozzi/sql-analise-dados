-- ============================================================
-- Análise de Fundos de Investimento — Dados Públicos CVM
-- Autor: Ronaldo Nerozzi
-- GitHub: github.com/ronaldo-nerozzi
-- Descrição: Consultas SQL para análise exploratória de fundos
-- ============================================================


-- ============================================================
-- 1. VISÃO GERAL — Total de fundos por tipo
-- ============================================================
SELECT
    TP_FUNDO          AS tipo_fundo,
    COUNT(*)          AS total_fundos
FROM cadastro_fundos
GROUP BY TP_FUNDO
ORDER BY total_fundos DESC;


-- ============================================================
-- 2. FUNDOS ATIVOS vs CANCELADOS
-- ============================================================
SELECT
    SIT               AS situacao,
    COUNT(*)          AS total
FROM cadastro_fundos
GROUP BY SIT
ORDER BY total DESC;


-- ============================================================
-- 3. TOP 10 GESTORES com mais fundos cadastrados
-- ============================================================
SELECT
    NM_GESTOR         AS gestor,
    COUNT(*)          AS total_fundos
FROM cadastro_fundos
WHERE SIT = 'EM FUNCIONAMENTO NORMAL'
GROUP BY NM_GESTOR
ORDER BY total_fundos DESC
LIMIT 10;


-- ============================================================
-- 4. PATRIMÔNIO LÍQUIDO — Top 10 fundos por patrimônio
-- ============================================================
SELECT
    f.DENOM_SOCIAL            AS nome_fundo,
    f.TP_FUNDO                AS tipo,
    i.VL_PATRIM_LIQ           AS patrimonio_liquido
FROM informes_diarios i
JOIN cadastro_fundos f ON i.CNPJ_FUNDO = f.CNPJ_FUNDO
WHERE i.DT_COMPTC = (SELECT MAX(DT_COMPTC) FROM informes_diarios)
ORDER BY i.VL_PATRIM_LIQ DESC
LIMIT 10;


-- ============================================================
-- 5. CAPTAÇÃO LÍQUIDA — Fundos com maior entrada de recursos
--    (Captação = Ingressos - Resgates)
-- ============================================================
SELECT
    f.DENOM_SOCIAL                        AS nome_fundo,
    SUM(i.VL_CAPTC_LIQ)                  AS captacao_liquida_total
FROM informes_diarios i
JOIN cadastro_fundos f ON i.CNPJ_FUNDO = f.CNPJ_FUNDO
WHERE EXTRACT(YEAR FROM i.DT_COMPTC) = 2024
GROUP BY f.DENOM_SOCIAL
ORDER BY captacao_liquida_total DESC
LIMIT 10;


-- ============================================================
-- 6. EVOLUÇÃO MENSAL do patrimônio de um fundo específico
--    (substituir o CNPJ pelo fundo desejado)
-- ============================================================
SELECT
    DATE_TRUNC('month', DT_COMPTC)        AS mes,
    AVG(VL_PATRIM_LIQ)                    AS patrimonio_medio_mensal
FROM informes_diarios
WHERE CNPJ_FUNDO = '00.000.000/0001-00'  -- substituir pelo CNPJ real
GROUP BY mes
ORDER BY mes;


-- ============================================================
-- 7. NÚMERO DE COTISTAS por tipo de fundo (média)
-- ============================================================
SELECT
    f.TP_FUNDO                    AS tipo_fundo,
    AVG(i.NR_COTST)               AS media_cotistas,
    MAX(i.NR_COTST)               AS max_cotistas,
    MIN(i.NR_COTST)               AS min_cotistas
FROM informes_diarios i
JOIN cadastro_fundos f ON i.CNPJ_FUNDO = f.CNPJ_FUNDO
WHERE i.DT_COMPTC = (SELECT MAX(DT_COMPTC) FROM informes_diarios)
GROUP BY f.TP_FUNDO
ORDER BY media_cotistas DESC;


-- ============================================================
-- 8. FUNDOS SEM MOVIMENTAÇÃO nos últimos 90 dias
--    (possíveis candidatos a encerramento)
-- ============================================================
SELECT
    f.DENOM_SOCIAL        AS nome_fundo,
    f.CNPJ_FUNDO,
    MAX(i.DT_COMPTC)      AS ultima_data_informe
FROM informes_diarios i
JOIN cadastro_fundos f ON i.CNPJ_FUNDO = f.CNPJ_FUNDO
WHERE f.SIT = 'EM FUNCIONAMENTO NORMAL'
GROUP BY f.DENOM_SOCIAL, f.CNPJ_FUNDO
HAVING MAX(i.DT_COMPTC) < CURRENT_DATE - INTERVAL '90 days'
ORDER BY ultima_data_informe;
