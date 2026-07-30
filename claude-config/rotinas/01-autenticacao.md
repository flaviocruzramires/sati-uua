# Rotina 01 — Autenticação e Autorização

## Objetivo

Login/logout com JWT e verificação de papel (`SOLICITANTE`, `ATENDENTE`, `ADMIN`),
base para proteger todas as demais telas e endpoints.

## Depende de

`00-fundacao-infra.md` (schema criado, composition root pronto, 1 usuário
`ADMIN` de seed disponível).

## Pode rodar em paralelo com

`02-cadastro-setores.md`, `04-cadastro-tipos-equipamento.md`, `06-servicos-ti.md`
— nenhuma depende de autenticação para o CRUD em si (só a tela precisa estar
"atrás" do login, o que pode ser plugado depois).

## Bloqueia

`03-cadastro-usuarios.md` (tela restrita a ADMIN) e `09-configuracoes.md`
(idem). Bloqueia também, de forma transversal, a proteção de rota de todas as
telas do app — mas isso pode ser plugado incrementalmente sem travar as
outras rotinas.

## Escopo — Banco

Nenhuma tabela nova. Usa `usuarios (login, senha_hash, papel)` já criada na
rotina 00.

## Escopo — Servidor

- `POST /auth/login` — recebe `login`/`senha`, valida hash bcrypt, emite JWT
  (`sub`=id do usuário, `papel`=papel do usuário, expiração curta, ex. 8h).
  Resposta 401 genérica em caso de erro (nunca dizer se foi login ou senha
  que errou).
- `POST /auth/logout` — no mínimo client-side (descartar token); avaliar
  blacklist de tokens apenas se houver requisito de revogação imediata.
- Middleware `auth`: extrai e valida o JWT do header `Authorization: Bearer`,
  popula o usuário autenticado (id + papel) no contexto do request para os
  handlers seguintes. Rotas sem token em endpoint protegido → `401`.
- Helper de autorização por papel (ex. `requirePapel(Papel.ADMIN)`) usado
  pelos Services das demais rotinas — não decida autorização no Handler nem
  no Repository.

## Escopo — Mobile

- Feature `auth/`: `LoginView` + `LoginViewModel` (Riverpod `AsyncNotifier`).
- Armazenamento seguro do token (`flutter_secure_storage` ou equivalente).
- `core/router`: guarda de rota — redireciona para `/login` quando não
  autenticado; oculta/bloqueia rotas que exigem `ADMIN` para outros papéis.
- Interceptor no cliente HTTP (`core/network`) que injeta o token em toda
  requisição e trata `401` global (desloga e redireciona ao login).

## Regras de negócio

- Senha e token nunca aparecem em log (ver skill `dart-shelf-server`).
- `JWT_SECRET` só existe em `.env`, nunca editável pela tela de configurações
  (rotina 09).

## Critérios de aceite

- [ ] Login com credenciais corretas retorna token válido.
- [ ] Login com credenciais erradas retorna 401 sem detalhar o motivo.
- [ ] Endpoint protegido sem token retorna 401; com token de papel insuficiente
      retorna 403.
- [ ] Tela de login funciona em 3 larguras (mobile/tablet/web).
- [ ] Nenhum log contém senha, hash ou token completo.

## Consultar

Skills: `dart-shelf-server` (seção Autenticação/Autorização), `flutter-mvvm-arquitetura`.
