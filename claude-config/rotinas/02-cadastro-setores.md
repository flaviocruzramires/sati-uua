# Rotina 02 — Cadastro de Setores

## Objetivo

CRUD do cadastro de Setores (campo: nome), usado como referência por
Usuários e Equipamentos.

## Depende de

`00-fundacao-infra.md` apenas.

## Pode rodar em paralelo com

`01-autenticacao.md`, `04-cadastro-tipos-equipamento.md`, `06-servicos-ti.md`.

## Bloqueia (parcialmente)

`03-cadastro-usuarios.md` e `05-cadastro-equipamentos.md` precisam apenas do
endpoint `GET /setores` funcionando (não do CRUD completo) para popular seus
combos — priorize esse endpoint se outras rotinas já estiverem em andamento.

## Escopo — Banco

Tabela `setores (id, nome)` já criada na rotina 00. Nenhuma migração nova.

## Escopo — Servidor

- `GET /setores` (paginado, `?page=&pageSize=`), colunas explícitas (`id, nome`).
- `POST /setores` — valida nome único (retorna `409` em conflito).
- `PUT /setores/:id`
- `DELETE /setores/:id` — como `usuarios.setor_id` é `ON DELETE RESTRICT`,
  a exclusão falha (e deve retornar erro claro) se houver usuário vinculado.

## Escopo — Mobile

- Feature `setores/`: lista + formulário simples (um único campo: nome).
- Tela de gestão (criar/editar/excluir) restrita ao papel `ADMIN`; a
  **leitura** (`GET /setores`) é usada livremente por outras telas como combo
  (ex.: formulário de usuário).

## Critérios de aceite

- [ ] Nome único validado no client (feedback imediato) e no servidor (fonte
      da verdade).
- [ ] Tentativa de excluir setor com usuário vinculado retorna erro tratado
      na UI (não um crash/erro genérico).
- [ ] Tela responsiva em 3 larguras.
- [ ] Repositório sem `SELECT *`.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`.
