# 10 — Guia de Construção dos Componentes

Como e em que ordem construir o que está catalogado em `08` e `09`, para que
nenhuma rotina funcional (`claude-config/rotinas/02`–`09`) comece a
implementar uma tela sem ter o componente pronto (e para não construir
componentes fora de ordem, criando dependência circular).

## Estrutura de pastas (mobile)

```
mobile/lib/core/
  theme/            # já previsto na rotina 00 (AppColors, AppSpacing, AppTheme, Breakpoints)
  domain/
    enums.dart              # SituacaoChamado, PapelUsuario, StatusAtivo (+ StatusColors)
    combo_item.dart
    paginated_result.dart
  network/
    dio_client.dart         # interceptor de token + tratamento 401
    app_exception.dart
  validators/
    validators.dart
  formatters/
    formatters.dart
  widgets/
    navigation/   # AppShell, SidebarNavItem, SidebarNavGroup, UserFooterTile, BottomNavBar, BackIconButton
    buttons/      # AppButton, IconActionButton
    fields/       # AppTextField, AppTextArea, AppSelect, AppDateField, AppDateTimeField, AppCheckboxRow, AppSegmentedControl, SearchField
    cards/        # AppCard, KpiCard, InfoField, SectionDivider
    tags/         # AppTag, StatusChamadoTag, PapelUsuarioTag, AtivoTag
    tables/       # AppDataTable, AppCardListItem, PaginationBar, FilterBar
    states/       # EmptyState, ErrorState, LoadingSkeleton, AsyncStateView
    dialogs/      # AppFormDialog, AppSidePanelForm
    charts/       # BarRow, BarTrack/BarFill, MiniGroupedBarChart
    domain/       # TimelineList, TimelineItem, StepList, StepItem, ResumoChamadoGrid
```

## Ordem de construção (grafo de dependência)

```
Nível 0 — primitivos (sem dependência entre si, testáveis isolados)
  core/theme (rotina 00) → core/domain/enums, combo_item, paginated_result
  → AppButton, IconActionButton, AppTag, AppCard, SectionDivider
  → AppTextField, AppTextArea, AppSelect, AppDateField, AppDateTimeField,
    AppCheckboxRow, AppSegmentedControl, SearchField
  → Validators, Formatters

Nível 1 — compostos (dependem só do Nível 0)
  → StatusChamadoTag, PapelUsuarioTag, AtivoTag (dependem de AppTag + enums)
  → KpiCard, InfoField (dependem de AppCard)
  → EmptyState, ErrorState, LoadingSkeleton → AsyncStateView
  → PaginationBar (depende de Formatters)
  → AppFormDialog, AppSidePanelForm (dependem de AppButton + campos)
  → BarRow/BarTrack/BarFill, StepList/StepItem, TimelineList/TimelineItem

Nível 2 — listagem genérica (depende do Nível 0/1)
  → FilterBar (depende de SearchField + AppSelect + AppSegmentedControl)
  → AppDataTable, AppCardListItem (dependem de AppTag/StatusChamadoTag quando aplicável)

Nível 3 — navegação (depende de rotina 01 para o guard de papel)
  → SidebarNavItem/Group, UserFooterTile, BottomNavBar, BackIconButton
  → AppShell (compõe os itens acima)

Nível 4 — domínio específico
  → ResumoChamadoGrid (depende de InfoField)
  → MiniGroupedBarChart (depende de fl_chart + tokens de cor)
```

**Regra prática:** um componente de nível N só é implementado depois que
todos os de nível N-1 dos quais depende existirem — mas isso não bloqueia
paralelismo *dentro* do mesmo nível (ex.: `AppButton` e `AppTextField` podem
ser feitos ao mesmo tempo por agents/sessões diferentes).

## Onde construir vs. onde consumir

- Os componentes em si (`core/widgets/...`) **não** conhecem nenhuma rotina
  específica — não importam `ChamadoRepository`, não sabem o que é um
  "chamado". Recebem tudo por parâmetro (strings, enums, callbacks).
- Cada `feature/<rotina>/view/` apenas **consome** os componentes prontos.
  Se uma tela parecer precisar de "quase" um componente que já existe mas
  com uma pequena diferença visual, o certo é generalizar o componente
  existente (novo parâmetro/variant), nunca duplicar o widget dentro da
  feature — isso é o que garante o "visual clean" e evita divergência entre
  telas com o tempo.

## Testes

Todo componente de Nível 0/1 ganha pelo menos um `flutter test` de widget
isolado (sem `ProviderScope`/API, só o widget com dados fake) — são rápidos
e baratos, bom encaixe para sessões curtas (ver
`SEQUENCIA-IMPLEMENTACAO.md` na raiz do projeto).

## Consultar

`08-catalogo-componentes.md` (o que construir), `09-objetos-e-utilitarios.md`
(modelos/utilitários), `00-design-tokens.md` + `app_theme.dart` (tokens),
`claude-config/skills/flutter-mvvm-arquitetura/SKILL.md` (onde os
componentes se encaixam na arquitetura MVVM).
