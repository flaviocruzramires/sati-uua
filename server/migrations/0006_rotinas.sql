-- 0006_rotinas.sql — Rotina 11: cadastro das rotinas (telas/menus) do sistema.
--
-- Fonte da verdade que a tela de permissionamento (rotina 12) percorre e que o
-- runtime (rotina 13) usa para montar o menu dinâmico. Ver
-- claude-config/rotinas/11-cadastro-rotinas.md.
--
-- Regras de integridade:
--  * Rotina pai (is_pai = true) é agrupador de submenu: não tem pai
--    (rotina_pai_id IS NULL), nem rota, nem CRUD.
--  * Rotina pai tem is_crud = false e is_chamado = false.
--  * Logout e Notificações (sininho) NÃO entram na tabela (regras 10/11).

CREATE TABLE rotinas (
  id            bigserial PRIMARY KEY,
  chave         text NOT NULL UNIQUE,
  nome          text NOT NULL,
  is_pai        boolean NOT NULL DEFAULT false,
  rotina_pai_id bigint REFERENCES rotinas(id) ON DELETE CASCADE,
  is_crud       boolean NOT NULL DEFAULT false,
  is_chamado    boolean NOT NULL DEFAULT false,
  rota          text,
  ordem         integer NOT NULL DEFAULT 0,
  icone         text,
  -- Pai não tem pai; pai não é CRUD nem chamado.
  CONSTRAINT rotinas_pai_sem_pai CHECK (NOT is_pai OR rotina_pai_id IS NULL),
  CONSTRAINT rotinas_pai_sem_crud CHECK (NOT is_pai OR (NOT is_crud AND NOT is_chamado))
);

CREATE INDEX idx_rotinas_pai ON rotinas (rotina_pai_id);

-- ── Seed da árvore de rotinas ────────────────────────────────────────────────
-- Idempotente (ON CONFLICT (chave) DO NOTHING). Pais primeiro; filhos referenciam
-- o pai pela `chave` (o id é bigserial gerado). Mapeado a partir do kNavEntries
-- do app_shell.dart + subrotas de chamado.

-- Raízes: 1 folha (Dashboard) + 3 grupos (pais).
INSERT INTO rotinas (chave, nome, is_pai, rotina_pai_id, is_crud, is_chamado, rota, ordem, icone) VALUES
  ('dashboard', 'Dashboard', false, NULL, false, false, '/', 1, 'layout-grid'),
  ('chamados',  'Chamados',  true,  NULL, false, false, NULL, 2, 'ticket'),
  ('cadastros', 'Cadastros', true,  NULL, false, false, NULL, 3, 'folder'),
  ('analise',   'Análise',   true,  NULL, false, false, NULL, 4, 'bar-chart-2')
ON CONFLICT (chave) DO NOTHING;

-- Filhos de "chamados" (is_chamado = true → só Ver/Incluir na tela de permissão).
INSERT INTO rotinas (chave, nome, is_pai, rotina_pai_id, is_crud, is_chamado, rota, ordem, icone)
SELECT v.chave, v.nome, false, p.id, v.is_crud, v.is_chamado, v.rota, v.ordem, v.icone
FROM (VALUES
  ('chamados.consulta', 'Consulta de Chamados', true, true, '/chamados',       1, 'ticket'),
  ('chamados.abertura', 'Abertura de Chamado',  true, true, '/chamados/abrir',  2, 'ticket-plus')
) AS v(chave, nome, is_crud, is_chamado, rota, ordem, icone)
CROSS JOIN (SELECT id FROM rotinas WHERE chave = 'chamados') AS p
ON CONFLICT (chave) DO NOTHING;

-- Filhos de "cadastros" (CRUD normal → quarteto completo Ver/Incluir/Alterar/Excluir).
INSERT INTO rotinas (chave, nome, is_pai, rotina_pai_id, is_crud, is_chamado, rota, ordem, icone)
SELECT v.chave, v.nome, false, p.id, v.is_crud, v.is_chamado, v.rota, v.ordem, v.icone
FROM (VALUES
  ('cadastros.setores',  'Setores',              true, false, '/setores',           1, 'building-2'),
  ('cadastros.tipos',    'Tipos de Equipamento', true, false, '/tipos-equipamento', 2, 'layers'),
  ('cadastros.equip',    'Equipamentos',         true, false, '/equipamentos',      3, 'monitor'),
  ('cadastros.servicos', 'Serviços',             true, false, '/servicos',          4, 'sliders-horizontal'),
  ('cadastros.usuarios', 'Usuários',             true, false, '/usuarios',          5, 'users')
) AS v(chave, nome, is_crud, is_chamado, rota, ordem, icone)
CROSS JOIN (SELECT id FROM rotinas WHERE chave = 'cadastros') AS p
ON CONFLICT (chave) DO NOTHING;

-- Filhos de "analise": Relatórios (CRUD=Não → só Ver) e Configurações (CRUD=Sim).
INSERT INTO rotinas (chave, nome, is_pai, rotina_pai_id, is_crud, is_chamado, rota, ordem, icone)
SELECT v.chave, v.nome, false, p.id, v.is_crud, v.is_chamado, v.rota, v.ordem, v.icone
FROM (VALUES
  ('analise.relatorios', 'Relatórios',    false, false, '/relatorios',    1, 'bar-chart-2'),
  ('analise.config',     'Configurações', true,  false, '/configuracoes', 2, 'settings')
) AS v(chave, nome, is_crud, is_chamado, rota, ordem, icone)
CROSS JOIN (SELECT id FROM rotinas WHERE chave = 'analise') AS p
ON CONFLICT (chave) DO NOTHING;
