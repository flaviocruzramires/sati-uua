# Rotina 05 — Cadastro de Equipamentos

## Objetivo

CRUD de Equipamentos (descrição, tipo, setor opcional).

## Depende de

- `00-fundacao-infra.md`
- `04-cadastro-tipos-equipamento.md` — precisa do `GET /tipos-equipamento`
  para o combo de tipo (campo obrigatório).
- `02-cadastro-setores.md` — precisa do `GET /setores` para o combo de setor
  (campo opcional).

## Pode rodar em paralelo com

`03-cadastro-usuarios.md`, `06-servicos-ti.md`.

## Bloqueia

`07-chamados.md` (chamado referencia um equipamento).

## Escopo — Banco

Tabela `equipamentos (id, descricao, tipo_equipamento_id, setor_id, ativo)`
já criada na rotina 00.

## Escopo — Servidor

- `GET /equipamentos` (paginado; filtro opcional por `tipo_equipamento_id`),
  com join leve para trazer o nome do tipo e do setor (colunas explícitas,
  nunca `SELECT *`).
- `POST /equipamentos`, `PUT /equipamentos/:id` — `tipo_equipamento_id`
  obrigatório, `setor_id` opcional.
- `DELETE`/inativação (`ativo=false`) — considerar que `chamados.equipamento_id`
  é `ON DELETE SET NULL`, então excluir um equipamento com chamados antigos
  não quebra o histórico, mas avalie se inativar é preferível a excluir.

## Escopo — Mobile

- Feature `equipamentos/`: lista com filtro por tipo, formulário com os dois
  combos (tipo obrigatório, setor opcional).

## Critérios de aceite

- [ ] Combo de tipo obrigatório e validado.
- [ ] Combo de setor opcional funciona (permite "sem setor").
- [ ] Lista filtrável por tipo.
- [ ] Sem `SELECT *`; tela responsiva.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`, `postgres-schema-chamados`.
