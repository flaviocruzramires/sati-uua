# Rotina 03 — Cadastro de Usuários

## Objetivo

CRUD de Usuários (nome, email, login, senha, setor) com papel
(`SOLICITANTE`/`ATENDENTE`/`ADMIN`).

## Depende de

- `00-fundacao-infra.md`
- `01-autenticacao.md` — a tela é restrita a `ADMIN`; endpoints usam o
  middleware/autorização de lá.
- `02-cadastro-setores.md` — precisa, no mínimo, do `GET /setores` para o
  combo de setor no formulário.

## Pode rodar em paralelo com

`05-cadastro-equipamentos.md`, `06-servicos-ti.md`, `04-cadastro-tipos-equipamento.md`
(assim que 01 e 02 tiverem o mínimo necessário prontos).

## Bloqueia

`07-chamados.md` (precisa de usuários reais para solicitante/atendente) e
`09-configuracoes.md` (papel ADMIN).

## Escopo — Banco

Tabela `usuarios` já criada na rotina 00
(`id, nome, email, login, senha_hash, setor_id, papel, ativo, criado_em, atualizado_em`).

## Escopo — Servidor

- `GET /usuarios` (paginado; filtro opcional `?papel=ATENDENTE`, útil para o
  combo de "atendente" na rotina 07) — restrito a `ADMIN`, exceto a variante
  usada só para popular combos (avaliar um endpoint mais enxuto ou o mesmo
  endpoint liberando apenas `id`/`nome`/`papel` para não-ADMIN).
- `POST /usuarios` — hash bcrypt da senha; valida e-mail e login únicos;
  restrito a `ADMIN`.
- `PUT /usuarios/:id` — edição de dados; troca de papel só por `ADMIN`;
  qualquer usuário autenticado pode editar o próprio nome/email (não o papel).
- Inativação lógica (`ativo=false`) em vez de `DELETE` físico se o usuário já
  tiver chamados vinculados (nunca apagar histórico).
- **Nunca** retornar `senha_hash` em nenhuma resposta JSON.

## Escopo — Mobile

- Feature `usuarios/`: tela de gestão (lista + formulário) restrita a `ADMIN`,
  com combo de Setor (via 02) e combo de Papel.
- Tela "Meu perfil": qualquer usuário autenticado edita os próprios dados
  básicos (não o papel).

## Regras de negócio

- E-mail e login únicos (erro 409 tratado na UI).
- Senha nunca aparece em nenhuma resposta da API nem em log.
- Validação de força mínima de senha no client (ex.: 8+ caracteres).

## Critérios de aceite

- [ ] Conflito de e-mail/login tratado com mensagem clara na UI.
- [ ] `senha_hash` nunca presente em nenhuma resposta JSON (verificar
      manualmente ou por teste automatizado).
- [ ] Combo de setor populado via API real (não hardcoded).
- [ ] Troca de papel só possível por `ADMIN`.
- [ ] Tela responsiva.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`, `postgres-schema-chamados`.
