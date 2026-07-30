# Sequência de Implementação — passo a passo, por sessão

Complementa `PLANO_IMPLEMENTACAO.md`, `HARNESS.md`, `claude-config/rotinas/`
e `docs-design/`. Aqui a implementação (componentes + rotinas) é organizada
em **blocos pequenos e autocontidos**, na ordem em que devem ser feitos por
**uma única sessão de cada vez** — pensado para caber no plano Pro sem parar
no meio de uma implementação quando o limite de uso do dia é atingido.

## Aviso importante sobre limites de uso

A Anthropic **não publica** um número fixo de tokens/mensagens por dia para
o plano Pro, e o valor efetivo varia (janelas de uso, mudanças de política,
tamanho do modelo usado). Este documento **não assume** um número exato —
em vez disso, cada bloco abaixo é dimensionado para ser pequeno o bastante
para, na prática, caber com folga numa sessão, e principalmente para
**terminar num ponto seguro** (código funcionando, testado e commitado)
antes de parar, seja qual for o motivo da parada.

Regras práticas:

1. **Um bloco = uma sessão** (ou menos). Não comece o próximo bloco na mesma
   sessão "só para aproveitar" se isso significa arriscar parar no meio dele.
2. **Nunca pare no meio de um bloco de propósito.** Se perceber que o uso
   está próximo do limite (o indicador de uso do app mostra isso) e ainda
   falta trabalho do bloco atual, prefira: (a) reduzir o escopo do bloco
   restante para algo committável agora, ou (b) reverter o que não compila/
   não passa nos testes e deixar o bloco marcado como "em andamento" para a
   próxima sessão — nunca deixar `main`/a branch de trabalho quebrada.
3. **Ao final de cada bloco:** rodar os testes daquele escopo (ver
   `HARNESS.md`), commitar, e só então parar.
4. **Calibre o tamanho ao longo do tempo:** depois das primeiras sessões, dá
   para perceber se os blocos "P" (pequenos) estão terminando com uso de
   sobra (então dá para juntar 2 num dia) ou se um bloco "M" já usa quase
   tudo (então vale quebrá-lo em dois na próxima vez). Pode usar a skill
   `explain-usage` ao final de uma sessão para ver onde o uso foi.
5. Esta é a sequência para **execução solo** (uma sessão, um agent por vez).
   Para paralelizar entre vários agents ao mesmo tempo (consome mais tokens
   de uma vez, mas é mais rápido em wall-clock) use as "ondas" descritas em
   `claude-config/rotinas/README.md` — os dois documentos descrevem o mesmo
   trabalho, organizado de duas formas diferentes.

Tamanho relativo de cada bloco:
- **P (pequeno):** um componente ou um endpoint isolado — cabe folgado.
- **M (médio):** uma tela completa (web+mobile) ou um grupo pequeno de
  componentes relacionados — normalmente enche uma sessão comum.
- **G (grande):** evitado neste plano — todo bloco que naturalmente seria
  "G" já foi quebrado em 2+ blocos M/P abaixo.

## Nota de escopo

O Dashboard (`docs-design/03-dashboard.md`) não tinha rotina própria — foi
somado à sequência (bloco 15) por ser uma tela adicional que consome o mesmo
endpoint agregado da rotina 08 (relatórios). Ver `docs-design/README.md`
seção "Nota de escopo" para detalhes.

## Sequência

| # | Bloco | Tam. | Depende de | Entrega ao final (checkpoint seguro) | Refs. |
|---|---|---|---|---|---|
| 1 | Fundação — Banco + Servidor | M | — | `docker compose up` sobe Postgres; migração `0001_init.sql` cria todo o schema; `dart run bin/server.dart` responde `200` em `/health`; seed (1 setor, 1 admin) aplicado. | `rotinas/00-fundacao-infra.md` |
| 2 | Fundação — Mobile bootstrap + tema | M | 1 | `main.dart` com `ProviderScope`; `AppTheme`/`AppColors`/`AppSpacing`/`Breakpoints` criados a partir de `docs-design/app_theme.dart`; cliente HTTP base (`core/network`); app roda (`flutter run -d chrome`) numa tela placeholder usando o tema. | `rotinas/00-fundacao-infra.md`, `docs-design/00-design-tokens.md` |
| 3 | Componentes base — ações e tags | P | 2 | `AppButton`, `IconActionButton`, `AppTag` (+ variantes), `AppCard`, `SectionDivider` implementados com 1 widget test cada. | `docs-design/08-catalogo-componentes.md` §1–4 |
| 4 | Componentes base — campos de formulário | P | 2 | `AppTextField`, `AppTextArea`, `AppSelect<T>`, `AppDateField`, `AppDateTimeField`, `AppCheckboxRow`, `AppSegmentedControl<T>`, `SearchField` implementados e testados isoladamente (dados fake, sem API). | `docs-design/08-catalogo-componentes.md` §2, `09-objetos-e-utilitarios.md` §1/3 |
| 5 | Componentes de estado e listagem genérica | M | 3, 4 | `EmptyState`, `ErrorState`, `LoadingSkeleton`, `AsyncStateView`, `PaginationBar`, `FilterBar`, `AppDataTable<T>`, `AppCardListItem<T>` prontos e testados com dados fake (sem tela real ainda). | `docs-design/08` §5, `09` §2/6 |
| 6 | Componentes de modal/formulário CRUD | P | 3, 4 | `AppFormDialog`, `AppSidePanelForm` prontos (usados por qualquer cadastro a partir do bloco 9). | `docs-design/08` §6 |
| 7 | Autenticação (rotina 01) | M | 1, 2, 3, 4 | Login funcional web+mobile (JWT), token em `flutter_secure_storage`, middleware de auth no servidor, interceptor 401 no client. | `rotinas/01-autenticacao.md` |
| 8 | Shell/Navegação (componentes de layout) | M | 3, 7 | `AppShell`, `SidebarNavItem/Group`, `UserFooterTile`, `BottomNavBar`, `BackIconButton` prontos; app autenticado navega entre 2–3 rotas placeholder respeitando papel. | `docs-design/08` §1, `01-shell-navegacao.md` |
| 9 | Cadastro de Setores + Serviços | M | 5, 6, 8 | CRUD completo (servidor+mobile) das duas rotinas mais simples, feitas juntas por reaproveitarem exatamente o mesmo molde (Modelo A). | `rotinas/02-cadastro-setores.md`, `rotinas/06-servicos-ti.md`, `docs-design/04-cadastros-crud.md` (Modelo A) |
| 10 | Cadastro de Tipos de Equipamento + Equipamentos | M | 9 | CRUD completo das duas rotinas de Modelo B (com combos), na ordem (tipos antes, pois equipamentos depende do combo). | `rotinas/04-cadastro-tipos-equipamento.md`, `rotinas/05-cadastro-equipamentos.md`, `docs-design/04` (Modelo B) |
| 11 | Cadastro de Usuários | M | 9, 10, 7 | CRUD completo master-detail (Modelo C, `AppSidePanelForm`), restrito a ADMIN, combo de setor e segmented de papel. | `rotinas/03-cadastro-usuarios.md`, `docs-design/04` (Modelo C) |
| 12 | Abertura de Chamado | P | 5, 6, 10, 11 | Tela de abertura funcional (`StepList`), `POST /chamados` operante. | `rotinas/07-chamados.md` (parte 1), `docs-design/05-chamado-abertura.md` |
| 13 | Listagem de Chamados | M | 5, 12 | Fila de atendimento / meus chamados, filtros (`FilterBar`) + tabela/cards + paginação, tudo server-side. | `rotinas/07-chamados.md` (parte 2), `docs-design/07-chamado-listagem.md` |
| 14 | Atendimento / Detalhe do Chamado | M | 6, 13 | `TimelineList`, `ResumoChamadoGrid`, registro de atendimento com a transação crítica de encerramento (histórico + situação + data_fechamento), regra "sem atendente não encerra". | `rotinas/07-chamados.md` (parte 3, regras críticas), `docs-design/06-chamado-atendimento.md` |
| 15 | Dashboard (novo, ver nota de escopo) | M | 14 | KPIs (`KpiCard`), barras de categoria (`BarRow`), gráfico agrupado (`MiniGroupedBarChart`/`fl_chart`), tabela "Por Atendente"; endpoint de resumo agregado no servidor. | `docs-design/03-dashboard.md` |
| 16 | Relatórios (rotina 08) | M | 15 | Painel de filtros completo + tabela paginada + resumo (reaproveita `FilterBar`/`AppDataTable`/`KpiCard`/`BarRow` já prontos do Dashboard). | `rotinas/08-relatorios.md`, `docs-design/relatorios-chamados` (skill) |
| 17 | Configurações | P | 7, 11 | Tela ADMIN de parâmetros não sensíveis, com auditoria; chaves sensíveis nunca expostas. | `rotinas/09-configuracoes.md` |
| 18 | Polimento e QA final | M | todos | Checklist completo de `HARNESS.md` §4 verificado (responsividade, sem `SELECT *`, logs, DI, MVVM, estado), testes de integração/widget cobrindo as regras críticas, revisão visual final contra os mockups `*.dc.html`. | `HARNESS.md`, `claude-config/agents/qa-tester-chamados.md` |

## Como retomar após parar no meio de um bloco (se acontecer)

1. Releia só o bloco atual nesta tabela + o(s) arquivo(s) de referência
   listados — não é preciso reler o plano inteiro.
2. Rode os testes existentes antes de continuar (garante que a base ainda
   está íntegra).
3. Complete só o que falta do bloco, rode os testes de novo, commite, e só
   então siga para o próximo bloco da tabela.

## Diferença para `claude-config/rotinas/README.md`

Aquele documento organiza o mesmo trabalho em **ondas paralelas** (vários
agents ao mesmo tempo) para quando o objetivo é velocidade e há orçamento de
tokens para isso. Este documento organiza o trabalho em **uma fila linear**
(um bloco de cada vez) para execução solo dentro de um plano com uso
limitado por sessão/dia. Os blocos 9–17 aqui correspondem às mesmas rotinas
02–09 de lá — só a forma de agendar o trabalho muda.
