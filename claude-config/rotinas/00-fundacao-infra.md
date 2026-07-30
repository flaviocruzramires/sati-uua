# Rotina 00 — Fundação e Infraestrutura

## Objetivo

Preparar toda a base técnica compartilhada antes de qualquer rotina funcional
ser implementada. Nenhuma outra rotina começa antes desta terminar.

## Depende de

Nada. É o ponto de partida.

## Pode rodar em paralelo com

Nada — bloqueia todas as demais rotinas (00 → 01/02/04/06 → ...).
Internamente, banco/servidor/mobile desta própria rotina podem ser feitos por
agents diferentes em paralelo, pois não dependem uns dos outros até o final.

## Escopo — Banco

- Criar `docker-compose.yml` com serviço PostgreSQL (ver `HARNESS.md` seção 1.1).
- Escrever a migração inicial `server/migrations/0001_init.sql` com **todo** o
  schema (todas as tabelas, enums e índices) descrito na skill
  `postgres-schema-chamados` — não faz sentido dividir a criação de tabelas por
  rotina, já que o modelo de dados já está todo definido; cada rotina depois só
  implementa CRUD/regra de negócio sobre tabelas que já existem.
- Criar tabela `schema_migrations` e o script `server/tool/migrate.dart` que
  aplica migrações pendentes em ordem.
- Seed mínimo de desenvolvimento (`server/migrations/seed/0001_seed_admin.sql`):
  1 setor ("TI"), 1 usuário `ADMIN` com senha conhecida em ambiente de dev.

## Escopo — Servidor (Dart/Shelf)

- `bin/server.dart`: sobe o Shelf, lê `.env`, monta o `AppContainer`
  (composition root vazio, pronto para receber repositórios/serviços — ver
  skill `dart-shelf-server`).
- Middlewares base, nessa ordem: request id → logging → error handling → CORS.
  (o middleware de auth entra na rotina 01, mas o "encaixe" no pipeline já deve
  existir aqui, mesmo que passe tudo direto por enquanto.)
- Endpoint `GET /health` retornando `200 {"status":"ok"}`.
- `.env.example` com todas as chaves (ver `HARNESS.md` seção 1.2).

## Escopo — Mobile (Flutter)

- `main.dart` com `ProviderScope` (Riverpod).
- `core/theme/app_theme.dart`: `ThemeData` único (Material 3), paleta e escala
  de espaçamento — nenhuma outra rotina deve criar cores/espaçamentos soltos.
- `core/theme/breakpoints.dart`: mobile `<600`, tablet `600–1024`, web `>1024`.
- `core/network/`: cliente HTTP base (dio ou http) com tratamento de erro comum
  e injeção do token (usado a partir da rotina 01).
- `core/router/`: esqueleto de rotas (mesmo que só com uma tela placeholder).

## Critérios de aceite

- [ ] `docker compose up -d` sobe o Postgres.
- [ ] `dart run tool/migrate.dart` cria todas as tabelas do modelo sem erro.
- [ ] `dart run bin/server.dart` responde `200` em `GET /health`.
- [ ] `flutter run -d chrome` abre uma tela usando o tema central (nenhuma cor
      hardcoded).
- [ ] Seed de desenvolvimento aplicado (1 setor, 1 usuário ADMIN).

## Consultar

Skills: `postgres-schema-chamados`, `dart-shelf-server`, `flutter-mvvm-arquitetura`.
