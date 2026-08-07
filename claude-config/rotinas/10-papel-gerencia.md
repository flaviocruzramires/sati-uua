# Rotina 10 — Novo papel: Gerência

## Objetivo

Introduzir o papel `GERENCIA` no sistema (hoje só existem `SOLICITANTE`,
`ATENDENTE`, `ADMIN`) e garantir que ele **enxergue todos os chamados**, igual a
`ATENDENTE`/`ADMIN` — sem, por enquanto, ganhar as ações de atendimento
(assumir/responder), que continuam restritas a `ATENDENTE`.

Este é o alicerce do bloco de permissionamento (rotinas 11 a 13): sem o papel
existir de ponta a ponta (enum servidor + enum mobile + JWT + seed), as telas de
permissão não têm o que configurar.

## Depende de

`01-autenticacao.md` (JWT com `papel`). Nada mais.

## Pode rodar em paralelo com

`11-cadastro-rotinas.md` (a tabela de rotinas não depende do papel). **Bloqueia**
`12-permissionamento-admin.md` e `13-aplicacao-permissoes.md`, que precisam
listar/selecionar `GERENCIA`.

## Escopo — Banco

- Migration nova (próximo número livre, ex. `0005_papel_gerencia.sql`).
- Hoje `usuarios.papel` é string (`'SOLICITANTE' | 'ATENDENTE' | 'ADMIN'`). Se a
  coluna tiver `CHECK`/enum no banco, **estender** para aceitar `'GERENCIA'`. Se
  for texto livre validado só na aplicação, não há mudança de schema — apenas a
  validação da aplicação muda.
- Opcional: criar 1 usuário `GERENCIA` de seed para teste (em
  `migrations/seed/`), seguindo o padrão do `0001_seed_admin.sql`.
- **Não** compilar/rodar migration sem pedido explícito (ver `feedback_migrations`).

## Escopo — Servidor

- `server/lib/src/models/usuario.dart`:
  - Adicionar `gerencia` ao enum `Papel`.
  - `papelFromString`: aceitar `'GERENCIA' => Papel.gerencia`.
  - `papelToString`: `Papel.gerencia => 'GERENCIA'`.
- `requirePapel` (em `auth_middleware.dart`) usa uma **escada linear**
  `[solicitante, atendente, admin]`. Gerência não encaixa numa escada (vê tudo de
  chamado como atendente, mas não atende). Decisão desta rotina:
  - Reordenar para `[solicitante, gerencia, atendente, admin]`. Assim
    `requirePapel(Papel.atendente)` **continua bloqueando** Gerência nos endpoints
    de assumir/responder chamado (comportamento desejado), e Gerência fica acima
    de Solicitante.
  - Tratar essa escada como **legado**: a partir da rotina 13, a autorização real
    das rotinas de CRUD passa a vir da matriz de permissões, não da escada.
- **Filtro "ver só os meus" vs "ver todos"** — `chamados_route.dart:25`:
  ```dart
  // ANTES
  final solicitanteId = payload.papel == Papel.solicitante
      ? payload.userId
      : (int.tryParse(params['solicitanteId'] ?? ''));
  ```
  Trocar a condição por um **conjunto** de papéis que veem tudo, incluindo
  Gerência:
  ```dart
  const veemTodos = {Papel.atendente, Papel.gerencia, Papel.admin};
  final solicitanteId = veemTodos.contains(payload.papel)
      ? (int.tryParse(params['solicitanteId'] ?? ''))
      : payload.userId; // solicitante: sempre só os próprios
  ```
  Esse é o **único** ponto do controle "meus × todos". Ele é ortogonal ao
  permissionamento das rotinas 11-13 e não deve ser misturado com ele.

## Escopo — Mobile

- `mobile/lib/core/domain/enums.dart`: adicionar `gerencia` a `PapelUsuario`.
- `current_user.dart` → `_parsePapel`: mapear `'GERENCIA' => PapelUsuario.gerencia`
  (hoje o `default` cai em `solicitante`; sem esse caso, um gerente logado seria
  tratado como solicitante e perderia acesso).
- Qualquer lugar que faça `switch` exaustivo em `PapelUsuario` (tags de papel,
  rótulos) precisa cobrir `gerencia` — rodar o analisador para achar todos.
- **Não** mexer aqui na visibilidade de menu por papel; isso sai do estático e
  passa para a matriz na rotina 13.

## Regras de negócio

- Gerência vê **todos** os chamados (como Admin/Atendente); Solicitante continua
  vendo só os que abriu. Esse controle é **separado** do permissionamento.
- Gerência **não** assume nem responde chamados por padrão (endpoints seguem
  exigindo `ATENDENTE`). Se no futuro precisar, será via matriz, não pela escada.

## Critérios de aceite

- [ ] Login de um usuário `GERENCIA` retorna JWT com `papel = GERENCIA` e o mobile
      o reconhece (não cai em solicitante).
- [ ] `GET /chamados` autenticado como Gerência retorna chamados de **todos** os
      solicitantes; como Solicitante, só os próprios.
- [ ] Endpoints de assumir/responder chamado continuam retornando 403 para
      Gerência.
- [ ] `dart analyze` (servidor) e `flutter analyze` (mobile) sem erros de switch
      não-exaustivo sobre o novo papel.

## Consultar

Skills: `dart-shelf-server` (Autenticação/Autorização), `flutter-mvvm-arquitetura`.
Rotinas: `11-cadastro-rotinas.md`, `12-permissionamento-admin.md`,
`13-aplicacao-permissoes.md`.
