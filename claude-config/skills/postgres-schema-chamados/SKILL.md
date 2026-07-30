---
name: postgres-schema-chamados
description: Use this skill whenever designing or modifying the PostgreSQL schema, writing migrations, or writing SQL queries for the Chamados de TI project — covers the full data model (usuários, setores, equipamentos, tipos de equipamento, serviços, chamados, histórico de atendimento, configurações) plus indexing for reports.
---

# Schema PostgreSQL — Chamados de TI

## Convenção de migrações

- Arquivos SQL numerados em `server/migrations/`, ex.: `0001_init.sql`,
  `0002_add_configuracoes.sql`. Nunca editar uma migração já aplicada — sempre
  criar uma nova.
- Uma tabela `schema_migrations (version text primary key, applied_at timestamptz)`
  controla o que já rodou.
- Seeds de desenvolvimento em `server/migrations/seed/`, sempre idempotentes
  (`INSERT ... ON CONFLICT DO NOTHING`).

## Modelo de dados

```sql
CREATE TYPE papel_usuario AS ENUM ('SOLICITANTE', 'ATENDENTE', 'ADMIN');
CREATE TYPE situacao_chamado AS ENUM ('ABERTO', 'EM_ANDAMENTO', 'AGUARDANDO_SOLICITANTE', 'ENCERRADO');

CREATE TABLE setores (
  id           bigserial PRIMARY KEY,
  nome         text NOT NULL UNIQUE
);

CREATE TABLE usuarios (
  id           bigserial PRIMARY KEY,
  nome         text NOT NULL,
  email        text NOT NULL UNIQUE,
  login        text NOT NULL UNIQUE,
  senha_hash   text NOT NULL,
  setor_id     bigint NOT NULL REFERENCES setores(id) ON DELETE RESTRICT,
  papel        papel_usuario NOT NULL DEFAULT 'SOLICITANTE',
  ativo        boolean NOT NULL DEFAULT true,
  criado_em    timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tipos_equipamento (
  id           bigserial PRIMARY KEY,
  nome         text NOT NULL UNIQUE          -- Notebook, Impressora, Periférico...
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
```

### Regra de negócio: encerramento de chamado

Ao inserir em `chamado_historico` com `marca_encerramento = true`, na mesma
transação: `UPDATE chamados SET situacao = 'ENCERRADO', data_fechamento = now()
WHERE id = @chamado_id`. Isso é responsabilidade do `ChamadoService` (não do
banco via trigger, para manter a regra visível e testável em Dart) — mas
pode-se avaliar uma trigger apenas como rede de segurança adicional.

## Índices (essenciais para o módulo de relatórios)

```sql
CREATE INDEX idx_chamados_situacao ON chamados(situacao);
CREATE INDEX idx_chamados_solicitante ON chamados(usuario_solicitante_id);
CREATE INDEX idx_chamados_responsavel ON chamados(usuario_responsavel_id);
CREATE INDEX idx_chamados_equipamento ON chamados(equipamento_id);
CREATE INDEX idx_chamados_servico ON chamados(servico_id);
CREATE INDEX idx_chamados_data_abertura ON chamados(data_abertura);
CREATE INDEX idx_chamados_data_fechamento ON chamados(data_fechamento);
CREATE INDEX idx_chamado_historico_chamado ON chamado_historico(chamado_id);
```

Essas colunas correspondem exatamente às dimensões de relatório pedidas pelo
cliente (situação, solicitante, atendente, equipamento, serviço, período de
abertura/fechamento) — ver skill `relatorios-chamados`.

## Regra inegociável: nunca `SELECT *`

Nenhuma migração de seed, nenhuma view, nenhum script auxiliar usa `SELECT *`.
Views de suporte a relatório, se criadas, também listam colunas explicitamente:

```sql
-- Exemplo de view de apoio a relatório (opcional, ver skill relatorios-chamados)
CREATE VIEW vw_chamados_relatorio AS
SELECT
  c.id, c.situacao, c.data_abertura, c.data_fechamento,
  c.usuario_solicitante_id, us.nome AS solicitante_nome,
  c.usuario_responsavel_id, ur.nome AS responsavel_nome,
  c.equipamento_id, e.descricao AS equipamento_descricao,
  c.servico_id, s.descricao AS servico_descricao
FROM chamados c
JOIN usuarios us ON us.id = c.usuario_solicitante_id
LEFT JOIN usuarios ur ON ur.id = c.usuario_responsavel_id
LEFT JOIN equipamentos e ON e.id = c.equipamento_id
LEFT JOIN servicos s ON s.id = c.servico_id;
```
