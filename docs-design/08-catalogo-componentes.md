# 08 — Catálogo de Componentes Reutilizáveis (Flutter)

Levantamento de **todo widget que aparece em mais de uma tela** nos mockups
(`*.dc.html`) e nos docs `01`–`07`, para não ser reimplementado tela a tela.
Cada componente referencia a classe CSS do design system Modernist
(`_ds/modernist-.../styles.css`) que ele reproduz em Flutter, além do CSS
próprio de cada mockup (`sidenav-item`, `bar-row`, `tl-item`, `pg-btn`,
`step`) que **não está** em `styles.css` — foi escrito ad-hoc em cada tela e
por isso também precisa virar componente único (senão cada rotina reinventa).

> Regra herdada de `00-design-tokens.md` e `HARNESS.md`: nenhum destes
> widgets usa cor/espaçamento fora de `AppColors`/`AppSpacing`/`AppTheme`
> (`docs-design/app_theme.dart`). Ver ordem de construção em
> `10-guia-construcao-componentes.md`.

Local sugerido: `mobile/lib/core/widgets/<categoria>/`.

## 1. Navegação e layout

### `AppShell`
- **Base:** estrutura descrita em `01-shell-navegacao.md` (sidebar 248px web,
  bottom nav mobile).
- **Usado em:** todas as telas autenticadas (rotinas 01–09).
- **Props:** `title`, `subtitle?`, `actions?` (slot de widgets à direita da
  topbar, ex. segmented de período no Dashboard, botão "Abrir Chamado"),
  `child` (conteúdo da rota), `currentRoute` (para destacar item ativo).
- **Variantes/estados:** desktop (sidebar fixa + topbar 64px), tablet
  (sidebar recolhida a ícones), mobile (app bar + `NavigationBar` 4 itens).
  Oculta itens de menu conforme papel (ver `SidebarNavItem`).
- **Notas:** um único widget — nenhuma tela deve montar sidebar/topbar/bottom
  nav manualmente. Usa `LayoutBuilder` + breakpoints de
  `core/theme/breakpoints.dart`.

### `SidebarNavItem` / `SidebarNavGroup`
- **Base:** classes ad-hoc `.sidenav-item`/`.sidenav-item.active`/`.sidenav-group`
  (repetidas em Dashboard, Cadastro Usuário, Chamado Atendimento/Abertura/Listagem).
- **Props (`SidebarNavItem`):** `icon` (Lucide), `label`, `active`, `onTap`,
  `visibleForPapeis` (lista de papéis que veem o item — ver `01-shell-navegacao.md`
  seção "Papéis").
- **`SidebarNavGroup`:** apenas `label` (kicker uppercase 10px), agrupa itens
  ("CADASTROS", "ANÁLISE").
- **Estados:** ativo (fundo `accent` chapado, texto `bg`, sem borda/raio),
  hover (tint `text` 6%).

### `UserFooterTile`
- **Base:** bloco de rodapé da sidebar (avatar quadrado + nome + tag de papel
  + ícone `log-out`), repetido em todas as telas web.
- **Props:** `nome`, `papel` (usa `PapelUsuarioTag`), `iniciais` (calculadas
  do nome), `onLogout`.

### `BottomNavBar` (mobile)
- **Base:** barra inferior de 4 itens (Dashboard/Chamados/Cadastros/Mais) do
  `01-shell-navegacao.md`. Item ativo em `accent`.
- **Props:** `currentIndex`, `onTap`, `itemsVisiveisPorPapel`.

### `BackIconButton`
- **Base:** `btn btn-icon btn-secondary` com seta esquerda, usado em telas de
  detalhe/formulário (Abertura de Chamado, Detalhe/Atendimento).
- **Props:** `onPressed` (default: `Navigator.pop`).

## 2. Ações e formulário

### `AppButton`
- **Base:** `.btn` + `.btn-primary`/`.btn-secondary`/`.btn-ghost`/`.btn-block`.
- **Props:** `label`, `onPressed`, `variant` (`primary|secondary|ghost`),
  `icon?`, `block` (largura total), `loading` (mostra spinner, desabilita).
- **Regra de estilo:** rótulo **alinhado à esquerda** quando o botão é mais
  largo que o texto (não centralizar) — exceto quando o mockup explicitamente
  centraliza (ex.: botão "Entrar" do login, `justify-content:center`) →
  expor via prop `centerLabel: bool`.

### `IconActionButton`
- **Base:** `.btn.btn-icon.btn-secondary` usado nas colunas "Ações" das
  tabelas (editar `pencil`, excluir `trash-2`) e no botão de voltar.
- **Props:** `icon`, `onPressed`, `tooltip?`.

### `AppTextField` / `AppTextArea`
- **Base:** `.field` + `label` + `.input` (e `textarea.input`).
- **Props:** `label`, `controller`, `obrigatorio` (mostra indicador), `hint?`,
  `obscure` (senha), `errorText?` (vem da validação client **e** do erro do
  servidor, ex. 409 de unicidade), `maxLines` (textarea: 3–5 conforme tela).

### `AppSelect<T>`
- **Base:** `<select class="input">` usado em todo combo (Setor, Tipo de
  Equipamento, Equipamento, Serviço, Atendente, Papel-como-filtro).
- **Props:** `label`, `items: List<ComboItem<T>>` (ver `09-objetos-e-utilitarios.md`),
  `value`, `onChanged`, `placeholder` ("Nenhum / não se aplica", "Todos os
  atendentes", etc.), `loading` (enquanto busca a lista via API).
- **Regra:** `items` **sempre** vem de um provider de repositório real —
  nunca lista fixa no widget (repetido em `04`, `05`, `07`, `08`).

### `AppDateField` / `AppDateTimeField`
- **Base:** `input type=date` (filtro de período) e `input type=datetime-local`
  (data de retorno do atendimento).
- **Props:** `label`, `value`, `onChanged`, `firstDate/lastDate?`.

### `AppCheckboxRow`
- **Base:** `<label><input type=checkbox>texto</label>` (Lembrar-me, Ativo,
  Marcar como encerrado).
- **Props:** `label`, `value`, `onChanged`.

### `AppSegmentedControl<T>`
- **Base:** `.seg` + `.seg-opt` (período do Dashboard, papel no form de
  Usuário, situação no filtro de Chamados).
- **Props:** `options: List<SegmentedOption<T>>`, `value`, `onChanged`,
  `fullWidth` (mobile usa `flex:1` em cada opção).

### `SearchField`
- **Base:** `.input` com ícone `search` posicionado à esquerda (Cadastro de
  Usuários/Equipamentos/Serviços, Listagem de Chamados).
- **Props:** `hint`, `onChanged` (debounce sugerido 300ms antes de disparar
  busca server-side).

## 3. Conteúdo e superfícies

### `AppCard`
- **Base:** `.card` + `.elev-sm/md/lg`.
- **Props:** `elevation` (`none|sm|md`), `background?` (default `surface`),
  `padding?`, `child`.

### `KpiCard`
- **Base:** card do Dashboard (`card-kicker` + número 36px/800 + `card-meta`).
- **Props:** `kicker`, `valor` (String, ex. "18", "6h40"), `meta?`.
- **Usado em:** Dashboard (5 no web, grid 2×2 no mobile).

### `InfoField`
- **Base:** par kicker+valor do "Card de resumo" do Chamado
  (Solicitante/Setor/Equipamento/Serviço/Aberto em) e das linhas de
  formulário read-only.
- **Props:** `kicker`, `valor`.

### `SectionDivider`
- **Base:** `.hr` (régua 2px). Widget trivial, mas centralizado para nunca
  aparecer com espessura/cor diferente do token.

## 4. Tags / status

### `AppTag` (base)
- **Base:** `.tag` + `.tag-accent/-accent-2/-neutral/-outline`.
- **Props:** `label`, `variant` (`accent|accent2|neutral|outline`).

### `StatusChamadoTag`
- **Base:** mapeamento de `SituacaoChamado` (ver `09-objetos-e-utilitarios.md`
  e `app_theme.dart` → `StatusColors.situacao`) para `AppTag`.
- **Props:** `situacao: SituacaoChamado`. Internamente escolhe o `variant`
  correto — **nenhuma tela escolhe a cor manualmente**.

### `PapelUsuarioTag` / `AtivoTag`
- **Base:** mapeia `PapelUsuario` (ADMIN=accent, ATENDENTE=accent-2,
  SOLICITANTE=neutral) e status Ativo/Inativo (accent-2/neutral) da mesma
  forma — mesma regra de "nunca recolorir ad-hoc".

## 5. Listagem, filtro e paginação

### `AppDataTable<T>`
- **Base:** `.table` (web) usado em Setores/Tipos/Equipamentos/Serviços/
  Usuários/Chamados/Dashboard "Por Atendente".
- **Props:** `columns: List<String>`, `rows: List<T>`,
  `rowBuilder(T) → List<Widget>`, `onRowTap?`, `actionsBuilder(T)?` (coluna
  de ações). Paginação **não** embutida aqui — combinar com `PaginationBar`.

### `AppCardListItem<T>`
- **Base:** equivalente mobile de cada linha de tabela (`.card.elev-sm` com
  título+tag+meta), usado em todas as listagens no mobile (regra
  `rotinas/07`: tabela no web, cards no mobile).
- **Props:** `titulo`, `tagSlot?` (widget, ex. `StatusChamadoTag`),
  `metaLines: List<String>`, `onTap?`.

### `PaginationBar`
- **Base:** rodapé "Mostrando X–Y de N" + `pg-btn` (chevrons, páginas,
  `…`, página atual em `accent`) — CSS `pg-btn` não está em `styles.css`,
  é próprio de cada mockup, então **fica só aqui**.
- **Props:** `page`, `pageSize`, `total`, `onPageChanged`. Usa
  `PaginacaoFormatter` (ver `09-objetos-e-utilitarios.md`) para o texto
  "Mostrando X–Y de N".

### `FilterBar`
- **Base:** barra de ferramentas com busca + selects + segmented, presente
  (com variações) em `04-cadastros-crud.md` e `07-chamado-listagem.md`.
- **Props:** `search?` (`SearchField`), `filters: List<Widget>` (selects,
  datas, segmented — cada tela injeta os filtros que precisa),
  `trailing?` (ex. contagem "31 usuários cadastrados").
- **Responsivo:** `Wrap`/`LayoutBuilder` — os filhos quebram linha em telas
  estreitas em vez de espremer.

### `EmptyState` / `ErrorState` / `LoadingSkeleton`
- **Base:** estados descritos em "Estados" de `04`, `07` e implícitos nas
  demais telas (loading/vazio/erro, citados em `HARNESS.md`).
- **Props (`EmptyState`):** `mensagem` (ex. "Nenhum chamado para este filtro"),
  `icon?`. **(`ErrorState`):** `mensagem`, `onRetry?`.
  **(`LoadingSkeleton`):** `tipo` (`tabela|lista|cards`), `linhas`.
- **Regra:** todo `AsyncNotifier` de listagem usa esse trio via
  `AsyncStateView` (ver `09-objetos-e-utilitarios.md`) — nunca um
  `CircularProgressIndicator` solto por tela.

## 6. Modais e formulários CRUD

### `AppFormDialog`
- **Base:** `.dialog-backdrop` + `.dialog` (+ `-title`/`-actions`), usado nos
  cadastros simples/com combo (Serviço, Setor, Tipo de Equipamento,
  Equipamento) via `showDialog`.
- **Props:** `title`, `fields: List<Widget>`, `onCancel`, `onSave`,
  `saving` (estado de loading no botão Salvar).

### `AppSidePanelForm`
- **Base:** painel lateral 360px do Cadastro de Usuário (master-detail) —
  mobile vira formulário full-screen.
- **Props:** iguais ao `AppFormDialog`, mas renderizado como painel fixo ao
  lado da lista (web) ou tela cheia (mobile), conforme `LayoutBuilder`.

## 7. Componentes específicos do domínio "Chamado"

### `TimelineList` / `TimelineItem`
- **Base:** `.tl-item`/`.tl-dot-col`/`.tl-dot`/`.tl-line` do histórico de
  atendimento (`06-chamado-atendimento.md`) — CSS ad-hoc, só existe nesse
  mockup, por isso vira componente único usado por qualquer tela que precise
  mostrar uma linha do tempo.
- **Props (`TimelineItem`):** `dataAutor` (texto "24/07/2026 10:40 · Carlos
  Menezes"), `descricao`, `dotColor?` (default `accent`; último item em
  aberto usa `accent-300` — ver mockup), `isLast` (omite a linha após o
  ponto).

### `StepList` / `StepItem`
- **Base:** `.step`/`.step-num` do card "Como funciona" (Abertura de
  Chamado).
- **Props (`StepItem`):** `numero`, `texto`.
- **Reutilização futura:** qualquer outro wizard/onboarding do app.

### `ResumoChamadoGrid`
- **Base:** grid de 5 `InfoField` (Solicitante/Setor/Equipamento/
  Serviço/Aberto em) do card-resumo em `06-chamado-atendimento.md`.
- **Props:** `chamado` (DTO do chamado detalhado).

### `BarRow` + `BarTrack`/`BarFill`
- **Base:** `.bar-row`/`.bar-track`/`.bar-fill` — barras horizontais de
  categoria no Dashboard ("Por Situação", "Por Setor", "Por Tipo de
  Equipamento", "Por Serviço"). CSS ad-hoc, só no Dashboard.
- **Props:** `label` (texto ou `AppTag`), `valor`, `percentual` (0–1),
  `cor`.

### `MiniGroupedBarChart`
- **Base:** gráfico "Abertos × Encerrados — últimos 6 meses" (duas séries).
- **Implementação:** usar `fl_chart` (`BarChart`) conforme
  `03-dashboard.md` — não reimplementar do zero; este item do catálogo é só
  o wrapper (`props`: `meses`, `serieAbertos`, `serieEncerrados`, `legenda`)
  que aplica as cores/tokens do tema em vez de default do `fl_chart`.

## Tabela-resumo: onde cada componente é usado

| Componente | Rotinas que usam |
|---|---|
| `AppShell`, `SidebarNavItem/Group`, `UserFooterTile`, `BottomNavBar` | todas (01–09) |
| `AppButton`, `IconActionButton`, `AppCard` | todas |
| `AppTextField/TextArea/Select/DateField/CheckboxRow/SegmentedControl` | 01, 02, 03, 04, 05, 06, 07, 09 |
| `SearchField`, `FilterBar`, `PaginationBar`, `AppDataTable`, `AppCardListItem` | 02, 03, 04, 05, 06, 07, 08 |
| `AppFormDialog` | 02, 04, 05, 06 |
| `AppSidePanelForm` | 03 |
| `StatusChamadoTag`, `TimelineList/Item`, `ResumoChamadoGrid` | 07 |
| `PapelUsuarioTag`, `AtivoTag` | 03, 05, 06 |
| `StepList/Item` | 07 (abertura) |
| `KpiCard`, `BarRow`, `MiniGroupedBarChart` | Dashboard (novo, item 6), 08 (relatórios) |
| `EmptyState/ErrorState/LoadingSkeleton` | todas as listagens |
