-- 0007_rotina_permissoes.sql — Rotina 12: matriz papel × rotina.
--
-- Persiste o quarteto Ver/Incluir/Alterar/Excluir por (papel, rotina). O Admin
-- NÃO é configurável (acesso total implícito) e nunca é gravado — garantido pelo
-- CHECK. Rotina sem linha ⇒ tudo false. Ver
-- claude-config/rotinas/12-permissionamento-admin.md.

CREATE TABLE rotina_permissoes (
  papel      papel_usuario NOT NULL,
  rotina_id  bigint NOT NULL REFERENCES rotinas(id) ON DELETE CASCADE,
  ver        boolean NOT NULL DEFAULT false,
  incluir    boolean NOT NULL DEFAULT false,
  alterar    boolean NOT NULL DEFAULT false,
  excluir    boolean NOT NULL DEFAULT false,
  PRIMARY KEY (papel, rotina_id),
  -- Admin tem acesso total implícito; nunca deve ter linha aqui.
  CONSTRAINT rotina_permissoes_sem_admin CHECK (papel <> 'ADMIN')
);

-- ── Seed padrão (estado inicial; o Admin ajusta depois na tela) ───────────────
-- Só insere linhas com ao menos uma ação true ("—" no design = sem linha).
-- Idempotente. Referencia a rotina pela `chave`.

INSERT INTO rotina_permissoes (papel, rotina_id, ver, incluir, alterar, excluir)
SELECT v.papel::papel_usuario, r.id, v.ver, v.incluir, v.alterar, v.excluir
FROM (VALUES
  -- SOLICITANTE
  ('SOLICITANTE', 'chamados.consulta',  true,  false, false, false),
  ('SOLICITANTE', 'chamados.abertura',  true,  true,  false, false),
  -- ATENDENTE
  ('ATENDENTE',   'dashboard',          true,  false, false, false),
  ('ATENDENTE',   'chamados.consulta',  true,  false, false, false),
  ('ATENDENTE',   'chamados.abertura',  true,  true,  false, false),
  ('ATENDENTE',   'cadastros.tipos',    true,  true,  true,  false),
  ('ATENDENTE',   'cadastros.equip',    true,  true,  true,  false),
  ('ATENDENTE',   'cadastros.servicos', true,  true,  true,  false),
  ('ATENDENTE',   'analise.relatorios', true,  false, false, false),
  -- GERENCIA
  ('GERENCIA',    'dashboard',          true,  false, false, false),
  ('GERENCIA',    'chamados.consulta',  true,  false, false, false),
  ('GERENCIA',    'chamados.abertura',  true,  true,  false, false),
  ('GERENCIA',    'cadastros.setores',  true,  false, false, false),
  ('GERENCIA',    'cadastros.tipos',    true,  false, false, false),
  ('GERENCIA',    'cadastros.equip',    true,  false, false, false),
  ('GERENCIA',    'cadastros.servicos', true,  false, false, false),
  ('GERENCIA',    'cadastros.usuarios', true,  false, false, false),
  ('GERENCIA',    'analise.relatorios', true,  false, false, false)
) AS v(papel, chave, ver, incluir, alterar, excluir)
JOIN rotinas r ON r.chave = v.chave
ON CONFLICT (papel, rotina_id) DO NOTHING;
