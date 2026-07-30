# 04 — Cadastros CRUD + Listagem paginada

Requisitos: **Item 1** (modelos de telas de cadastro CRUD) e **Item 2** (listagem
com paginação). Três modelos de complexidade crescente — servem de molde para os
demais cadastros (Setores, Tipos de Equipamento seguem o modelo "simples").

Mockups: `Cadastro Servico.dc.html`, `Cadastro Equipamento.dc.html`,
`Cadastro Usuario.dc.html`.

## Padrão comum (todos os cadastros)

### Listagem (Web = tabela; Mobile = cards)
- Topbar: título + subtítulo + botão primário **"+ Novo …"**.
- Barra de ferramentas: campo de **busca** (ícone `search`) à esquerda; filtros
  (selects) quando houver; contagem total à direita.
- **Tabela `.table`** com colunas de dados + coluna **Ações** (`btn-icon`
  secundário: `pencil` editar, `trash-2` excluir).
- **Rodapé de paginação:** "Mostrando X–Y de N" à esquerda; controles à direita
  (`chevron-left`, páginas, `…`, `chevron-right`; página atual em fundo navy).
- **Mobile:** cada registro é um `.card.elev-sm` (título + meta + tag de status);
  paginação centralizada compacta. (Regra `rotinas/07`: tabela no web, cards no mobile.)

### Formulário (modal `.dialog` — ou drawer lateral no Usuário)
- `dialog-title` "Novo …/Editar …" + campos `.field` + `dialog-actions`
  (**Cancelar** secundário / **Salvar** primário).
- Validação client (feedback imediato) + servidor (fonte da verdade). Conflito de
  unicidade → **409** tratado com mensagem clara na UI.
- Exclusão com vínculo (FK RESTRICT) → erro tratado, nunca crash.

## Modelo A — Serviço (CRUD simples, 1 campo)
- Tabela: **Descrição** · Ações. Paginação (ex.: 1–8 de 23).
- Form: único campo **Descrição** (`input`). Base para Setores e Tipos de Equipamento.
- Endpoints: `GET/POST/PUT/DELETE /servicos`.

## Modelo B — Equipamento (CRUD com combos)
- Barra: busca + filtro **Tipo** (select). Contagem à direita.
- Tabela: **Descrição · Tipo · Setor · Status · Ações**. Status = tag
  (Ativo=accent-2 / Inativo=neutral). Paginação (1–6 de 57, com `…`).
- Form: **Descrição** (input); **Tipo de Equipamento** (select, obrigatório);
  **Setor** (select, opcional — inclui "Sem setor"); checkbox **Ativo**.
- Endpoints: `GET/POST/PUT /equipamentos` (join leve p/ nome de tipo/setor),
  `DELETE`/inativação.

## Modelo C — Usuário (CRUD completo — restrito a ADMIN)
- Layout master-detail: **lista à esquerda** + **form em drawer lateral (360px)**
  à direita (mobile: form full-screen). Linha selecionada destacada (tint navy 6%).
- Barra: busca + filtro **Papel** (select).
- Tabela: **Nome · E-mail · Setor · Papel · Status · Ações**. Papel = tag
  (ADMIN=accent / ATENDENTE=accent-2 / SOLICITANTE=neutral).
- Form: **Nome completo**, **E-mail**, **Login**, **Senha** (placeholder "Deixe em
  branco para manter" na edição; força mín. 8 no cadastro), **Setor** (select),
  **Papel** (segmented Solicitante/Atendente/Admin — troca só por ADMIN),
  checkbox **Ativo**.
- Regras: e-mail e login únicos (409); **`senha_hash` nunca** em resposta/JSON/log;
  inativação lógica (`ativo=false`) se houver chamados vinculados (não apagar histórico).
- Endpoints: `GET/POST/PUT /usuarios` (restrito ADMIN; variante enxuta id/nome/papel
  para combos).

## Estados (todos)
Loading (skeleton/spinner na tabela), vazio ("Nenhum registro"), erro (mensagem
clara), salvando (botão em loading), sucesso (fecha modal + refresh + toast).

## Flutter
- `DataTable`/`PaginatedDataTable` no web; `ListView` de `Card` no mobile
  (`LayoutBuilder`). Paginação server-side (`?page=&pageSize=`).
- Cada cadastro: `feature/<nome>/` com `view/`, `view_model/` (Riverpod
  `AsyncNotifier`), `widgets/`. Form em `showDialog` (modal) ou painel lateral (Usuário).
- Combos alimentados por API real (nunca lista fixa).
