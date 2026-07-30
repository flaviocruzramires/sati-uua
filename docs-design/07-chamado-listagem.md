# 07 — Listagem de Chamados

Requisito: **Item 5**. Fila de atendimento / Meus chamados. Mockup:
`Chamado Listagem.dc.html`. `GET /chamados` paginado, com filtros combináveis.

## Objetivo
Listar chamados com filtros (situação, atendente, período) + busca + paginação.
Web = tabela; Mobile = cards (regra `rotinas/07`).

## Topbar
Título "Chamados" + subtítulo "Fila de atendimento" + botão primário "Abrir Chamado".

## Barra de filtros (card)
- **Segmented por situação:** Todos / Aberto / Em andamento / Aguard. solicitante /
  Encerrado (default Todos).
- **Select Atendente** ("Todos os atendentes" + lista — para "fila" vs "meus").
- **Período:** dois `input type=date` (abertura de / até).
- **Busca** (ícone `search`) à direita.

## Tabela (Web) — `.table`
Colunas: **Nº · Descrição · Solicitante · Setor · Situação · Atendente · Aberto em**.
- Situação = `tag` colorida por status (ver `00-design-tokens.md`).
- Atendente vazio ("—" muted) quando não atribuído.
- Linha clicável → detalhe (`06`).
- **Paginação:** "Mostrando 1–8 de 193" + controles (`chevron`, páginas, `…`,
  página atual navy).

## Cards (Mobile)
Chips de situação roláveis no topo. Cada chamado = `.card.elev-sm`:
título "#Nº · descrição curta" + tag de situação; meta (solicitante · setor ·
atendente); data. Paginação compacta centralizada.

## Filtros → API (rotina 08/07)
`situacao`, `solicitante_id`, `atendente_id`, `abertura_de`/`abertura_ate`,
`page`, `pageSize`. Combináveis. Contagem total independente da página.

## Estados
Loading (skeleton de linhas), vazio ("Nenhum chamado para este filtro"), erro.
Filtros ativos refletidos na URL/estado para deep-link.

## Flutter
`ChamadosListView` + `ViewModel` (Riverpod `AsyncNotifier` com filtros no estado).
`PaginatedDataTable` (web) × `ListView` de cards (mobile) via `LayoutBuilder`.
Paginação e filtros **server-side** (nunca filtrar só no client).
