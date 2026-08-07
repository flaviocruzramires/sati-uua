-- 0005_papel_gerencia.sql — Rotina 10: introduz o papel GERENCIA.
--
-- Estende o enum `papel_usuario` para aceitar 'GERENCIA' (hoje só existem
-- 'SOLICITANTE', 'ATENDENTE', 'ADMIN'). Gerência enxerga todos os chamados
-- (como Atendente/Admin), mas NÃO assume/responde por padrão — ver
-- claude-config/rotinas/10-papel-gerencia.md.
--
-- Observação: ALTER TYPE ... ADD VALUE não pode ser usado no MESMO bloco de
-- transação em que é criado; o runner (tool/migrate.dart) aplica cada arquivo
-- via psql em autocommit, então roda sem problema. IF NOT EXISTS torna a
-- migração idempotente.

ALTER TYPE papel_usuario ADD VALUE IF NOT EXISTS 'GERENCIA';
