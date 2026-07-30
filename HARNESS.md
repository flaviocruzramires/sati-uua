# Harness de Desenvolvimento e Verificação — Chamados de TI

Este documento descreve como rodar, testar e verificar localmente o app Flutter
(mobile/web) e o servidor Dart, além do checklist objetivo dos requisitos técnicos.
Complementa `PLANO_IMPLEMENTACAO.md`.

## 1. Ambiente local

### 1.1 PostgreSQL via Docker

```yaml
# docker-compose.yml (raiz do projeto)
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: chamados
      POSTGRES_PASSWORD: chamados
      POSTGRES_DB: chamados
    ports:
      - "5432:5432"
    volumes:
      - chamados_pgdata:/var/lib/postgresql/data
volumes:
  chamados_pgdata:
```

```
docker compose up -d
```

### 1.2 Variáveis de ambiente (`server/.env.example`)

```
APP_ENV=development
HTTP_PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_NAME=chamados
DB_USER=chamados
DB_PASSWORD=chamados
JWT_SECRET=troque-em-producao
LOG_LEVEL=INFO
```

Copie para `server/.env` e ajuste. Valores de `configuracoes` (tela 6.1) sobrepõem
em runtime apenas parâmetros não sensíveis (ex.: `LOG_LEVEL`, mensagens padrão,
paginação); credenciais de banco e `JWT_SECRET` nunca são editáveis pela UI.

### 1.3 Rodando o servidor

```
cd server
dart pub get
dart run bin/server.dart
```

### 1.4 Rodando as migrações

```
cd server
dart run tool/migrate.dart   # aplica migrations/*.sql em ordem, registrando em schema_migrations
```

### 1.5 Rodando o app Flutter

```
cd mobile
flutter pub get
flutter run -d chrome        # web
flutter run                  # dispositivo/emulador mobile
```

## 2. Pirâmide de testes

| Camada | Ferramenta | O que cobrir |
|---|---|---|
| Unit (servidor) | `test` | services, regras de negócio (ex.: encerramento de chamado), validações |
| Integration (servidor) | `test` + banco de teste (`chamados_test`) | repositórios contra Postgres real, endpoints via `shelf_test`/http client |
| Unit (Flutter) | `flutter_test` | ViewModels com repositórios fake/mocados (`mocktail`) |
| Widget (Flutter) | `flutter_test` | telas críticas: login, formulário de chamado, lista de chamados, relatórios |
| Integration (Flutter) | `integration_test` | fluxo completo: login → abrir chamado → atender → encerrar |

Banco de teste isolado (`chamados_test`) recriado a cada execução via as mesmas
migrações de `server/migrations`, nunca aponta para o banco de desenvolvimento.

## 3. Lint e formatação

```
# servidor
cd server && dart analyze && dart format --set-exit-if-changed .

# mobile
cd mobile && flutter analyze && dart format --set-exit-if-changed .
```

## 4. Checklist de verificação dos requisitos técnicos

Use este checklist ao final de cada fase (agent `qa-tester-chamados`):

- [ ] **Responsivo**: telas principais testadas em pelo menos 3 larguras (mobile ~375px,
      tablet ~768px, desktop/web ~1280px), sem overflow, sem scroll horizontal indevido.
- [ ] **Servidor em Dart**: `dart run bin/server.dart` sobe sem erro e responde `GET /health`.
- [ ] **PostgreSQL**: todas as tabelas do modelo de domínio existem via migrações versionadas
      (nenhum `CREATE TABLE` manual fora de `migrations/`).
- [ ] **Visual clean**: tema único (`ThemeData`) aplicado em 100% das telas, sem cores/estilos
      "hardcoded" fora dos design tokens.
- [ ] **Log**: toda requisição HTTP gera uma linha de log estruturada (método, rota, status,
      duração, request id); erros não tratados são logados com stack trace.
- [ ] **Sem `SELECT *`**: `grep -ri "select \*" server/lib` retorna vazio.
- [ ] **Injeção de dependência**: nenhuma `Repository`/`Service` é instanciada diretamente
      dentro de um widget ou handler — sempre via provider (Flutter) ou composition root (servidor).
- [ ] **Gerenciamento de estado**: nenhuma tela usa `setState` para estado de negócio
      (apenas para estado puramente visual/local, se necessário).
- [ ] **MVVM**: toda tela (`View`) depende apenas do seu `ViewModel`; nenhum `Widget` chama
      `Repository`/`Service` diretamente.
- [ ] Testes das camadas relevantes à fase passam (`dart test`, `flutter test`).

## 5. CI sugerida (referência, a implementar quando houver repositório Git remoto)

Pipeline com dois jobs paralelos (`server`, `mobile`), cada um rodando:
setup do SDK → `pub get` → `analyze` → `format --set-exit-if-changed` → `test`.
Job do servidor sobe um serviço Postgres efêmero para os testes de integração.

## 6. Observando logs localmente

- Servidor: saída padrão (stdout) em desenvolvimento; em produção, redirecionar para arquivo
  rotacionado (`server/logs/app.log`) — nunca logar senha, token JWT ou variáveis sensíveis.
- Flutter: pacote `logger`, com nível reduzido (`warning`+) em builds de release.
