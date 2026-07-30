---
name: flutter-mvvm-arquitetura
description: Use this skill whenever writing or reviewing Flutter code (Views, ViewModels, Repositories, Services, widgets, providers) in the Chamados de TI project. Provides the official Flutter app-architecture (MVVM) conventions, Riverpod state-management/DI patterns, folder structure, naming rules, and responsive/clean-UI guidance to follow consistently across the mobile/web app.
---

# Arquitetura MVVM (Flutter App Architecture) + Riverpod

Base: [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture) —
arquitetura em camadas recomendada oficialmente pelo Google para apps Flutter.

## Camadas

```
UI layer            View  ←→  ViewModel
                            (expõe estado via Riverpod Notifier/AsyncNotifier)
Data layer           Repository  →  Service
                     (Repository decide de onde vêm os dados; Service fala com a API HTTP)
```

- **View**: widget "burro". Só lê estado do ViewModel (`ref.watch`) e chama métodos do
  ViewModel em resposta a interação do usuário. Nunca contém lógica de negócio,
  nunca chama `Repository`/`Service` diretamente.
- **ViewModel**: um `Notifier`/`AsyncNotifier` do Riverpod por tela (ou por
  seção de tela complexa). Contém o estado da UI e a lógica de apresentação.
  Depende de `Repository`(s) injetado(s) via provider — nunca instanciado com `new`.
- **Repository**: fonte única de verdade de um tipo de dado (ex.: `ChamadoRepository`).
  Decide cache/estratégia; para este projeto, delega ao `Service` HTTP.
- **Service**: encapsula a chamada HTTP ao servidor Dart (usar `dio` ou `http`),
  serialização/deserialização de DTOs.

## Injeção de dependência e estado com Riverpod

- Todo `Service`/`Repository`/`ViewModel` é exposto por um `Provider`/`NotifierProvider`.
- Nunca instancie uma dependência dentro de um widget (`ChamadoService()` dentro de
  `build()` é proibido) — sempre via `ref.watch(chamadoRepositoryProvider)`.
- Preferir `AsyncNotifier`/`FutureProvider` para dados vindos da API (loading/error/data
  tratados de forma consistente com `AsyncValue`).
- Estado local puramente visual (ex.: um `TextEditingController`, se um `ExpansionTile`
  está aberto) pode usar `StatefulWidget`/`setState` — estado de **negócio** nunca.

## Estrutura de pastas por feature

```
lib/
  core/
    theme/            # ThemeData, design tokens (cores, spacing, tipografia)
    router/           # go_router ou similar
    network/          # cliente HTTP base, interceptors, tratamento de erro comum
  data/
    dto/              # modelos de transporte (JSON ↔ objeto)
  features/
    <feature>/
      view/            # Widgets (Screens)
      view_model/      # Notifier/AsyncNotifier + estado
      widgets/         # componentes específicos da feature
      <feature>_repository.dart
      <feature>_service.dart
```

Features do projeto: `auth`, `usuarios`, `setores`, `equipamentos`, `servicos`,
`chamados` (inclui histórico de atendimento como sub-seção), `relatorios`,
`configuracoes`.

## Responsividade

- Use `LayoutBuilder` ou uma classe `Breakpoints` central (`core/theme/breakpoints.dart`)
  com três faixas: mobile (`< 600`), tablet (`600–1024`), web/desktop (`> 1024`).
- Listas que em mobile são `ListView` viram `DataTable`/grid em telas largas quando
  fizer sentido (ex.: lista de chamados, relatórios).
- Formulários (cadastro de usuário, equipamento, etc.) usam layout de coluna única
  em mobile e duas colunas em telas largas — nunca largura fixa em pixels.
- Nunca usar `MediaQuery` espalhado pelos widgets para decisões de layout — centralizar
  na classe `Breakpoints` para manter consistência ("visual clean").

## Visual "clean"

- Um único `ThemeData` (`core/theme/app_theme.dart`) define paleta de cores, escala
  tipográfica e escala de espaçamento (ex.: múltiplos de 4/8px). Nenhum widget usa
  `Color(0xFF...)` ou `EdgeInsets.all(<número mágico>)` fora do tema.
- Preferir Material 3 (`useMaterial3: true`) como base, com poucos componentes
  customizados — consistência > originalidade visual.
- Estados vazios, de erro e de carregamento têm um padrão único reutilizável
  (ex.: um widget `AsyncStateView` que trata `AsyncValue.when(...)`).

## Testabilidade

- ViewModels devem ser testáveis sem Flutter widgets: injete repositórios fake
  (`mocktail`) via `ProviderScope(overrides: [...])` nos testes.
- Nenhuma lógica de negócio relevante deve existir apenas dentro de um `build()`.

## Checklist rápido antes de considerar uma tela pronta

- [ ] View só depende do seu ViewModel.
- [ ] Nenhuma instância direta de Repository/Service em widgets.
- [ ] Nenhum `setState` de estado de negócio.
- [ ] Testada em pelo menos 3 larguras.
- [ ] Usa apenas cores/espaçamentos do tema central.
