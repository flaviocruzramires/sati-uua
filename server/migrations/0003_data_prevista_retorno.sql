-- 0003_data_prevista_retorno.sql
-- Adiciona campo de data prevista de retorno ao historico de atendimento

ALTER TABLE chamado_historico
  ADD COLUMN IF NOT EXISTS data_prevista_retorno date;
