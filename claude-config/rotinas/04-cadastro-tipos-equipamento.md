# Rotina 04 — Cadastro de Tipos de Equipamento

## Objetivo

CRUD dos tipos de equipamento (Notebook, Impressora, Periférico, ...), usado
como referência pelo cadastro de Equipamentos.

## Depende de

`00-fundacao-infra.md` apenas.

## Pode rodar em paralelo com

`01-autenticacao.md`, `02-cadastro-setores.md`, `06-servicos-ti.md`.

## Bloqueia (parcialmente)

`05-cadastro-equipamentos.md` precisa apenas do `GET /tipos-equipamento`
funcionando para popular seu combo.

## Escopo — Banco

Tabela `tipos_equipamento (id, nome)` já criada na rotina 00.

## Escopo — Servidor

- `GET /tipos-equipamento` (paginado ou lista simples — volume baixo).
- `POST /tipos-equipamento` — nome único.
- `PUT /tipos-equipamento/:id`
- `DELETE /tipos-equipamento/:id` — falha com erro claro se houver
  equipamento vinculado (`ON DELETE RESTRICT`).

## Escopo — Mobile

- Feature `tipos_equipamento/` (pode viver como sub-tela dentro da feature
  `equipamentos/` se preferir menos telas soltas): CRUD simples, restrito a
  `ADMIN`/`ATENDENTE`.

## Critérios de aceite

- [ ] Nome único validado.
- [ ] Exclusão com equipamento vinculado tratada na UI.
- [ ] Endpoint sem `SELECT *`.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`.
