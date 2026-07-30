# 03 — Dashboard (quantitativos de chamados)

Requisito: **Item 6** — números quantitativos de chamados categorizados pelos
campos do cadastro de chamado. Mockup: `Dashboard.dc.html`.

## Objetivo
Visão geral operacional: KPIs no topo + gráficos por categoria. Filtro de período
(7/30/90 dias) que recalcula tudo. Todos os agregados vêm do backend
(`GET /relatorios/chamados` → bloco `resumo`, calculado sobre o filtro completo,
nunca sobre a página).

## Topbar
Título "Dashboard" + subtítulo "Visão geral dos chamados de TI"; à direita
segmented control **7 dias / 30 dias / 90 dias** (default 30) + ícone `bell`.

## Conteúdo Web (grid, gap 24)

### 1. Linha de KPIs (5 cards `.card.elev-sm`)
Cada card: kicker (uppercase) + número 36px/800 + meta 11px.
| KPI | Valor exemplo | Meta/sub |
|---|---|---|
| Abertos | 18 | +3 hoje |
| Em andamento | 24 | 6 sem atendente |
| Aguardando solicitante | 9 | retorno pendente |
| Encerrados (mês) | 142 | 94% dentro do SLA |
| Tempo médio de resolução | 6h40 | meta: 8h |

### 2. Duas colunas (1.6fr / 1fr)
- **Chamados por Situação** — 4 barras horizontais (label = `tag` colorida por
  situação + trilha neutral-200 + preenchimento na cor do papel + contagem):
  Aberto (accent), Em andamento (accent-2), Aguard. solicitante (neutral-500),
  Encerrado (neutral-700).
- **Abertos × Encerrados — últimos 6 meses** — gráfico de barras agrupadas
  (2 séries: Abertos navy, Encerrados verde), 6 meses no eixo X + legenda.

### 3. Três colunas (categorias do cadastro do chamado)
Listas de barras (label + trilha + preenchimento + contagem):
- **Por Setor Solicitante** (barras navy) — Secretaria Acad. 34, Coord. de Curso 28,
  Biblioteca 21, Financeiro 17, RH 14, Almoxarifado 12.
- **Por Tipo de Equipamento** (barras verde) — Notebook 46, Impressora 31,
  Desktop 27, Periférico 19, Projetor 8, Rede/Switch 6.
- **Por Serviço** (barras neutral-700) — Suporte Sist. Acad. 39, Rede e Internet 29,
  Impressão 23, E-mail institucional 17, Instalação Software 13, Manut. Hardware 11.

### 4. Tabela — Por Atendente (`.table`)
Colunas: Atendente · Setor · Ativos · Encerrados (mês) · Tempo médio.

## Conteúdo Mobile
Empilhado + bottom nav. Segmented de período full-width; KPIs em grid 2×2
(número 26px); "Por Situação" (3 barras principais); "Por Tipo de Equipamento"
(3 barras); "Por Atendente" como lista compacta (nome + "N ativos · N encerrados").

## Categorizações exigidas (todas presentes)
Situação, Setor solicitante, Tipo de equipamento, Serviço, Atendente, e evolução
temporal (abertos × encerrados). São exatamente os campos do cadastro de chamado.

## Flutter
- Barras: `fl_chart` (BarChart) ou barras próprias com `FractionallySizedBox` (raio 0).
- `DashboardViewModel` (Riverpod `AsyncNotifier`) recebe `periodo`; refaz a query
  ao trocar o segmented. Nenhum agregado calculado no client sobre página.
