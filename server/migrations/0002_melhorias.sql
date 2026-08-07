-- 0002_melhorias.sql
-- Campos: terceiro envolvido, historico do solicitante, notificacoes, anexos

-- ── 1. Terceiro envolvido no chamado ─────────────────────────────────────────
ALTER TABLE chamados
  ADD COLUMN IF NOT EXISTS envolve_terceiro boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS nome_terceiro    text;

-- ── 2. Historico do solicitante ──────────────────────────────────────────────
-- Tornar usuario_responsavel_id nullable e adicionar tipo_registro
ALTER TABLE chamado_historico
  ALTER COLUMN usuario_responsavel_id DROP NOT NULL;

ALTER TABLE chamado_historico
  ADD COLUMN IF NOT EXISTS usuario_solicitante_id bigint
    REFERENCES usuarios(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS tipo_registro text NOT NULL DEFAULT 'ATENDIMENTO'
    CHECK (tipo_registro IN ('ATENDIMENTO', 'RETORNO_SOLICITANTE'));

-- Garantir consistencia: exatamente um autor preenchido
ALTER TABLE chamado_historico
  DROP CONSTRAINT IF EXISTS chk_historico_autor;
ALTER TABLE chamado_historico
  ADD CONSTRAINT chk_historico_autor CHECK (
    (tipo_registro = 'ATENDIMENTO'          AND usuario_responsavel_id IS NOT NULL AND usuario_solicitante_id IS NULL) OR
    (tipo_registro = 'RETORNO_SOLICITANTE'  AND usuario_solicitante_id IS NOT NULL AND usuario_responsavel_id IS NULL)
  );

-- ── 3. Notificacoes ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notificacoes (
  id          bigserial PRIMARY KEY,
  usuario_id  bigint NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  chamado_id  bigint NOT NULL REFERENCES chamados(id) ON DELETE CASCADE,
  tipo        text NOT NULL,
  mensagem    text NOT NULL,
  lida        boolean NOT NULL DEFAULT false,
  criada_em   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario
  ON notificacoes(usuario_id, lida, criada_em DESC);

-- ── 4. Anexos ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chamado_anexos (
  id              bigserial PRIMARY KEY,
  chamado_id      bigint NOT NULL REFERENCES chamados(id) ON DELETE CASCADE,
  historico_id    bigint REFERENCES chamado_historico(id) ON DELETE CASCADE,
  usuario_id      bigint NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  nome_arquivo    text NOT NULL,
  tamanho_bytes   bigint NOT NULL,
  mime_type       text NOT NULL,
  caminho         text NOT NULL,
  criado_em       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chamado_anexos_chamado
  ON chamado_anexos(chamado_id);
CREATE INDEX IF NOT EXISTS idx_chamado_anexos_historico
  ON chamado_anexos(historico_id);
