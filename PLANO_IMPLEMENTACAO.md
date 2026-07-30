# Plano de Implementação — Sistema de Chamados de TI

> Documento mestre de planejamento. Serve tanto como referência humana quanto como
> ponto de entrada para o fluxo multi-agente do Claude Code configurado em `.claude/`.

## 1. Visão geral

Aplicativo Flutter (mobile + web) para gerenciamento de chamados do Setor de TI,
com backend próprio em Dart e persistência em PostgreSQL.

Decisões técnicas confirmadas com o solicitante:

| Decisão | Escolha | Motivo |
|---|---|---|
| Framework do servidor | **Shelf + shelf_router** | Controle total sobre roteamento, middlewares e injeção de dependência; sem "mágica" de framework, mais fácil de auditar em um projeto pequeno/médio. |
| Gerenciamento de estado (Flutter) | **Riverpod** | Recomendação atual do time do Flutter; integra-se naturalmente à arquitetura MVVM oficial (App Architecture Guide) e também resolve injeção de dependência via providers. |
| Arquitetura mobile | **MVVM (Flutter App Architecture)** | Exigência do cliente; é a arquitetura em camadas documentada oficialmente pelo Google para apps Flutter. |
| Banco de dados | **PostgreSQL** | Exigência do cliente. |
| Uso destes .md | **Ambos**: convenções reais de `agents`/`skills` do Claude Code **e** documentação legível para humanos. | Permite tanto orientar o time quanto ser consumido diretamente por Claude Code. |

## 2. Modelo de domínio

Baseado nas rotinas descritas pelo cliente, com campos técnicos adicionados
onde necessário (chaves, timestamps, papéis de usuário). Detalhamento completo
de tipos/constraints está na skill `postgres-schema-chamados`.

### 2.1 Usuário
- id, nome, email (único), login (único), senha (hash, nunca em texto puro), setor_id (FK Setor)
- **Campo adicional proposto:** `papel` (ENUM: `SOLICITANTE`, `ATENDENTE`, `ADMIN`) — necessário porque o
  spec distingue "usuário solicitante" de "usuário responsável pelo atendimento"; sem um papel,
  não há como restringir quem pode ser atribuído a um chamado nem proteger a tela de Configurações.
- ativo (bool), criado_em, atualizado_em

### 2.2 Setor
- id, nome (único)

### 2.3 Tipo de Equipamento
- id, nome (Notebook, Impressora, Periférico, ...)
- **Adicionado como tabela própria** (não enum fixo no código) para permitir cadastro de novos
  tipos sem deploy — o spec já sugere isso com "...".

### 2.4 Equipamento
- id, descricao, tipo_equipamento_id (FK), setor_id (FK, opcional), ativo

### 2.5 Serviço
- id, descricao

### 2.6 Chamado
- id, descricao, usuario_solicitante_id (FK Usuario), data_abertura, data_fechamento (nullable)
- situacao (ENUM: `ABERTO`, `EM_ANDAMENTO`, `AGUARDANDO_SOLICITANTE`, `ENCERRADO`)
- usuario_responsavel_id (FK Usuario, nullable — atribuído ao aceitar o chamado)
- equipamento_id (FK, nullable), servico_id (FK, nullable)

### 2.7 Histórico de Atendimento (1:N com Chamado)
- id, chamado_id (FK), usuario_responsavel_id (FK), data_retorno, descricao, marca_encerramento (bool)
- Regra de negócio: quando um registro de histórico é gravado com `marca_encerramento = true`,
  o Chamado pai deve ter `situacao = ENCERRADO` e `data_fechamento` preenchida (transação única).

### 2.8 Configuração
- Em vez de reescrever o arquivo `.env` em disco (inseguro e inviável em produção/containers),
  a tela de Configurações lê/grava uma tabela `configuracoes (chave, valor, descricao, tipo, atualizado_em, atualizado_por)`
  que **sobrepõe** os valores padrão do `.env` em tempo de execução, restrita a usuários `ADMIN`,
  com log de auditoria de cada alteração. Isso atende ao requisito funcional sem comprometer segredos
  sensíveis (ex.: credenciais do banco continuam apenas no `.env`, não editáveis pela tela).

## 3. Requisitos técnicos → como serão atendidos

| Requisito | Como é atendido | Onde verificar |
|---|---|---|
| Responsivo | `LayoutBuilder`/breakpoints no Flutter, layouts adaptativos mobile/web | skill `flutter-mvvm-arquitetura` |
| Servidor em Dart | Shelf + shelf_router | skill `dart-shelf-server` |
| Banco PostgreSQL | Schema completo versionado em migrações SQL | skill `postgres-schema-chamados` |
| Visual clean | Design tokens (cores, spacing, tipografia) via `ThemeData`, Material 3 | skill `flutter-mvvm-arquitetura` |
| Log | `package:logging` no servidor (request id, nível, sink em arquivo/stdout); `logger` no Flutter para erros de UI/rede | skill `dart-shelf-server`, HARNESS.md |
| Nunca `SELECT *` | Repositórios sempre com lista explícita de colunas; checklist de code review | skill `postgres-schema-chamados`, `dart-shelf-server` |
| Injeção de dependência | Riverpod providers (Flutter); composition root manual (servidor) | skills `flutter-mvvm-arquitetura` e `dart-shelf-server` |
| Gerenciamento de estado | Riverpod (`Notifier`/`AsyncNotifier` por ViewModel) | skill `flutter-mvvm-arquitetura` |
| Arquitetura MVVM (Google) | UI layer (View + ViewModel) / Data layer (Repository + Service) | skill `flutter-mvvm-arquitetura` |

## 4. Arquitetura geral

```
┌───────────────────────────┐        HTTPS/JSON        ┌──────────────────────────┐        SQL        ┌────────────┐
│   Flutter App (mobile/web)│ ───────────────────────▶ │  Servidor Dart (Shelf)   │ ─────────────────▶ │ PostgreSQL │
│  View ↔ ViewModel (Riverpod)                          │  Router → Handler →      │                    └────────────┘
│  Repository → Service (HTTP client)                   │  Service → Repository    │
└───────────────────────────┘                            └──────────────────────────┘
```

## 5. Estrutura de pastas proposta

```
chamados/
├── mobile/                     # app Flutter (mobile + web)
│   └── lib/
│       ├── core/               # theme, router, DI (providers globais), config
│       ├── data/                # repositories + services (HTTP)
│       ├── features/
│       │   ├── auth/
│       │   ├── usuarios/
│       │   ├── setores/
│       │   ├── equipamentos/
│       │   ├── servicos/
│       │   ├── chamados/
│       │   ├── relatorios/
│       │   └── configuracoes/
│       │       (cada feature: view/, view_model/, widgets/)
│       └── main.dart
├── server/                     # servidor Dart (Shelf)
│   ├── bin/server.dart
│   ├── lib/
│   │   ├── src/
│   │   │   ├── routes/
│   │   │   ├── handlers/
│   │   │   ├── services/
│   │   │   ├── repositories/
│   │   │   ├── middlewares/
│   │   │   ├── models/
│   │   │   └── di/            # composition root
│   │   └── server.dart
│   └── migrations/             # SQL numerado
├── .claude/
│   ├── agents/
│   └── skills/
├── HARNESS.md
└── PLANO_IMPLEMENTACAO.md
```

## 6. Fases do projeto (roadmap)

1. **Fase 0 — Fundacão**: repositórios criados, docker-compose com Postgres, `.env.example`,
   migração inicial (schema completo), composition root do servidor, tema/design tokens no Flutter,
   configuração de Riverpod e roteamento. *(agents: database-architect, dart-server-dev, flutter-mobile-dev)*
2. **Fase 1 — Autenticação e cadastros base**: login/logout (JWT), CRUD de Usuários e Setores.
3. **Fase 2 — Cadastros operacionais**: CRUD de Tipos de Equipamento, Equipamentos e Serviços.
4. **Fase 3 — Chamados**: abertura de chamado, atribuição de atendente, histórico de atendimento,
   encerramento, listagem/filtro por situação.
5. **Fase 4 — Relatórios**: endpoints e tela de relatórios (situação, solicitante, atendente,
   equipamento, serviço, período de abertura/fechamento). *(skill: relatorios-chamados)*
6. **Fase 5 — Configurações via tela**: tabela `configuracoes` + tela admin com auditoria.
7. **Fase 6 — Polimento e verificação**: responsividade em todas as telas, revisão de logs,
   varredura por `SELECT *`, testes automatizados, checklist final de requisitos técnicos.
   *(agent: qa-tester-chamados, ver HARNESS.md)*

Cada fase deve ser encerrada apenas depois que o agent `qa-tester-chamados` validar o
checklist de requisitos técnicos relevante àquela fase.

## 7. Como usar os agents e skills

- Use o agent **orchestrator-chamados** para decidir qual especialista aciona cada tarefa e
  para manter este plano atualizado à medida que fases avançam.
- Use **flutter-mobile-dev** para qualquer código em `mobile/lib/`.
- Use **dart-server-dev** para qualquer código em `server/`.
- Use **database-architect** antes de qualquer alteração de schema/migração.
- Use **qa-tester-chamados** ao final de cada feature/fase.
- Os agents carregam automaticamente as skills relevantes (`flutter-mvvm-arquitetura`,
  `dart-shelf-server`, `postgres-schema-chamados`, `relatorios-chamados`) — não é necessário
  invocá-las manualmente, mas elas também podem ser lidas diretamente como documentação.

Consulte `HARNESS.md` para como rodar, testar e verificar o projeto localmente.
