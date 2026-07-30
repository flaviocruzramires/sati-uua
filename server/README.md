# SATI-UUA — Servidor (Dart / Shelf)

Servidor HTTP do Sistema de Atendimento de TI da UEMS Aquidauana. Ver
`claude-config/skills/dart-shelf-server/SKILL.md` (arquitetura) e
`claude-config/rotinas/00-fundacao-infra.md` (o que este bloco entrega).

## Pré-requisitos

- Dart SDK >= 3.4 (`dart --version`)
- PostgreSQL 16 (local ou via `docker compose up -d` na raiz do projeto)

## Como rodar

```bash
cd server
cp .env.example .env        # ajuste se necessário
dart pub get
dart run tool/migrate.dart --seed   # cria o schema + seed de desenvolvimento
dart run bin/server.dart
```

Verifique: `curl http://localhost:8080/health` deve responder
`{"status":"ok","db":"ok"}`.

**Login de desenvolvimento (seed):** `admin.ti` / `admin123` — só existe
localmente, nunca use em produção. Ver `migrations/seed/0001_seed_admin.sql`.

## Testes

```bash
dart test
```

## Estrutura

```
bin/server.dart            # entrypoint: monta middlewares + rotas + sobe o servidor
lib/src/config/env.dart    # leitura do .env (sem dependência externa)
lib/src/di/app_container.dart  # composition root (conexão com o banco, repositórios/serviços)
lib/src/middlewares/       # request id, logging, tratamento de erro, CORS
lib/src/errors/            # AppException + formato JSON padronizado de erro
lib/src/routes/            # GET /health (rotina 00); demais rotas chegam nas próximas rotinas
migrations/                # SQL numerado, aplicado por tool/migrate.dart
migrations/seed/           # dados de desenvolvimento (não roda em produção)
tool/migrate.dart          # runner de migrações
test/                      # testes unitários (Env, AppException por enquanto)
```

## O que ESTE bloco (00 — fundação) entrega

- [x] Schema completo do banco (todas as tabelas do modelo de domínio).
- [x] Servidor sobe e responde `/health`.
- [x] Composition root pronto para receber repositórios/serviços das
      próximas rotinas (nunca instanciados diretamente nos handlers).
- [x] Middlewares base (request id, logging, erro padronizado, CORS).
- [ ] Autenticação (JWT) — rotina 01, próximo bloco.
- [ ] Endpoints de negócio (usuários, setores, equipamentos, serviços,
      chamados, relatórios, configurações) — rotinas 02-09.

## Nota sobre verificação neste ambiente

O schema (`migrations/0001_init.sql`) e o seed (`migrations/seed/0001_seed_admin.sql`)
**foram testados de fato** contra um PostgreSQL 16 real durante a criação
deste código (aplicados com `psql`, tabelas e view conferidas). O código Dart
em si (`bin/server.dart`, middlewares, `tool/migrate.dart`) **não pôde ser
compilado/rodado** no ambiente onde foi escrito, porque esse ambiente não
tem acesso de rede a `pub.dev`/`storage.googleapis.com` para instalar o Dart
SDK e baixar os pacotes. Rode `dart pub get` e `dart run bin/server.dart` no
seu computador (ou em CI) antes de considerar este bloco fechado — é o
primeiro passo real de verificação que falta.
