-- 0001_init.sql — Schema completo do SATI-UUA.
-- Fonte: claude-config/skills/postgres-schema-chamados/SKILL.md
-- Regra: nenhuma query deste projeto usa SELECT * (ver mesma skill).

CREATE TYPE papel_usuario AS ENUM ('SOLICITANTE', 'ATENDENTE', 'ADMIN');
CREATE TYPE situacao_chamado AS ENUM ('ABERTO', 'EM_ANDAMENTO', 'AGUARDANDO_SOLICITANTE', 'ENCERRADO');

CREATE TABLE setores (
  id           bigserial PRIMARY KEY,
  nome         text NOT NULL UNIQUE
);

CREATE TABLE usuarios (
  id            bigserial PRIMARY KEY,
  nome          text NOT NULL,
  email         text NOT NULL UNIQUE,
  login         text NOT NULL UNIQUE,
  senha_hash    text NOT NULL,
  setor_id      bigint NOT NULL REFERENCES setores(id) ON DELETE RESTRICT,
  papel         papel_usuario NOT NULL DEFAULT 'SOLICITANTE',
  ativo         boolean NOT NULL DEFAULT true,
  criado_em     timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tipos_equipamento (
  id           bigserial PRIMARY KEY,
  nome         text NOT NULL UNIQUE
);

CREATE TABLE equipamentos (
  id                   bigserial PRIMARY KEY,
  descricao            text NOT NULL,
  tipo_equipamento_id  bigint NOT NULL REFERENCES tipos_equipamento(id) ON DELETE RESTRICT,
  setor_id             bigint REFERENCES setores(id) ON DELETE SET NULL,
  ativo                boolean NOT NULL DEFAULT true
);

CREATE TABLE servicos (
  id           bigserial PRIMARY KEY,
  descricao    text NOT NULL
);

CREATE TABLE chamados (
  id                        bigserial PRIMARY KEY,
  descricao                 text NOT NULL,
  usuario_solicitante_id    bigint NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  usuario_responsavel_id    bigint REFERENCES usuarios(id) ON DELETE SET NULL,
  equipamento_id            bigint REFERENCES equipamentos(id) ON DELETE SET NULL,
  servico_id                bigint REFERENCES servicos(id) ON DELETE SET NULL,
  situacao                  situacao_chamado NOT NULL DEFAULT 'ABERTO',
  data_abertura             timestamptz NOT NULL DEFAULT now(),
  data_fechamento           timestamptz
);

CREATE TABLE chamado_historico (
  id                        bigserial PRIMARY KEY,
  chamado_id                bigint NOT NULL REFERENCES chamados(id) ON DELETE CASCADE,
  usuario_responsavel_id    bigint NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  data_retorno              timestamptz NOT NULL DEFAULT now(),
  descricao                 text NOT NULL,
  marca_encerramento        boolean NOT NULL DEFAULT false
);

CREATE TABLE configuracoes (
  chave          text PRIMARY KEY,
  valor          text NOT NULL,
  descricao      text,
  tipo           text NOT NULL DEFAULT 'string', -- string | int | bool
  atualizado_em  timestamptz NOT NULL DEFAULT now(),
  atualizado_por bigint REFERENCES usuarios(id)
);

-- Índices essenciais para o módulo de relatórios/dashboard
-- (ver claude-config/rotinas/08-relatorios.md e docs-design/03-dashboard.md).
CREATE INDEX idx_chamados_situacao ON chamados(situacao);
CREATE INDEX idx_chamados_solicitante ON chamados(usuario_solicitante_id);
CREATE INDEX idx_chamados_responsavel ON chamados(usuario_responsavel_id);
CREATE INDEX idx_chamados_equipamento ON chamados(equipamento_id);
CREATE INDEX idx_chamados_servico ON chamados(servico_id);
CREATE INDEX idx_chamados_data_abertura ON chamados(data_abertura);
CREATE INDEX idx_chamados_data_fechamento ON chamados(data_fechamento);
CREATE INDEX idx_chamado_historico_chamado ON chamado_historico(chamado_id);

-- View de apoio ao módulo de relatórios/dashboard — colunas explícitas,
-- nunca SELECT * (mesma regra de todo o projeto).
CREATE VIEW vw_chamados_relatorio AS
SELECT
  c.id, c.situacao, c.data_abertura, c.data_fechamento,
  c.usuario_solicitante_id, us.nome AS solicitante_nome, us.setor_id AS solicitante_setor_id,
  c.usuario_responsavel_id, ur.nome AS responsavel_nome,
  c.equipamento_id, e.descricao AS equipamento_descricao,
  te.id AS tipo_equipamento_id, te.nome AS tipo_equipamento_nome,
  c.servico_id, s.descricao AS servico_descricao
FROM chamados c
JOIN usuarios us ON us.id = c.usuario_solicitante_id
LEFT JOIN usuarios ur ON ur.id = c.usuario_responsavel_id
LEFT JOIN equipamentos e ON e.id = c.equipamento_id
LEFT JOIN tipos_equipamento te ON te.id = e.tipo_equipamento_id
LEFT JOIN servicos s ON s.id = c.servico_id;
