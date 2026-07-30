# Rotina 06 — Serviços Suportados pela TI

## Objetivo

CRUD de Serviços (campo: descrição), usado como referência pelo cadastro
de Chamados.

## Depende de

`00-fundacao-infra.md` apenas.

## Pode rodar em paralelo com

`01-autenticacao.md`, `02-cadastro-setores.md`, `04-cadastro-tipos-equipamento.md`,
`03-cadastro-usuarios.md`, `05-cadastro-equipamentos.md`.

## Bloqueia (parcialmente)

`07-chamados.md` precisa do `GET /servicos` para o combo de serviço no
formulário de abertura de chamado.

## Escopo — Banco

Tabela `servicos (id, descricao)` já criada na rotina 00.

## Escopo — Servidor

- `GET /servicos` (paginado ou lista simples), `POST /servicos`,
  `PUT /servicos/:id`, `DELETE /servicos/:id` (falha com erro claro se
  houver chamado vinculado, já que `chamados.servico_id` é `ON DELETE SET NULL`
  — nesse caso a exclusão é permitida, mas avalie se o negócio prefere
  inativação).

## Escopo — Mobile

- Feature `servicos/`: CRUD simples, restrito a `ADMIN`/`ATENDENTE`; leitura
  livre para popular o combo na abertura de chamado.

## Critérios de aceite

- [ ] CRUD funcional e simples (é a rotina mais simples do projeto — bom
      candidato para validar o "molde" de feature usado nas demais).
- [ ] Sem `SELECT *`; tela responsiva.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`.
