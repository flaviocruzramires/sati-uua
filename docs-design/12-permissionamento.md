# 12 — Permissionamento (Admin)

Requisito: **Rotina 12** — tela onde o Admin monta a matriz papel × rotina.
Papel: `ADMIN` (endpoints e menu restritos). Mockup: `Permissionamento.dc.html`.
Depende de `10-papel-gerencia.md` e `11-cadastro-rotinas.md`; bloqueia
`13-aplicacao-permissoes.md`.

## Objetivo
Selecionar um papel (Solicitante / Atendente / Gerência) e marcar, por rotina,
**Visualização / Inclusão / Alteração / Exclusão**. Persiste em
`rotina_permissoes` que o runtime (rotina 13) aplica. **Admin não é
configurável** — acesso total implícito e **não aparece** no seletor.

## Layout Web
- Shell padrão (ver `01-shell-navegacao.md`) com grupo de menu **ADMINISTRAÇÃO →
  Permissionamento** (ícone Lucide `shield`), visível só para Admin.
- Topbar: título "Permissionamento" + subtítulo + ações **Descartar**
  (secundário) e **Salvar** (primário, ícone `save`).
- Card de contexto: **segmented de Papel** (Solicitante/Atendente/Gerência) +
  nota das regras + tag de estado ("Alterações não salvas" / "Tudo salvo").
- **Tabela** (`.table`): coluna **Rotina** + 4 colunas de checkbox
  (Visualização / Inclusão / Alteração / Exclusão). Linhas de **grupo pai**
  (fundo neutral-100, negrito, sem checkbox → "—"); **folhas** indentadas 26px.
- Legenda inferior: "—" = coluna não se aplica; checkbox esmaecido = travado.

## Layout Mobile
App bar com voltar. Segmented de papel full-width. Cada rotina folha = `.card`
(nome + linha de checkboxes Ver/Incluir/Alterar/Excluir); grupos viram
`card-kicker`. Rodapé fixo com **Descartar** / **Salvar**.

## Colunas × dados
Catálogo de rotinas vem de `GET /rotinas` (rotina 11). Cada rotina traz
`is_crud` e `is_chamado`, que **governam quais colunas aparecem**:

| Flag da rotina | Efeito nas colunas |
|---|---|
| `is_crud = false` | mostra só **Visualização**; Incluir/Alterar/Excluir → "—" (Regra 2) |
| `is_chamado = true` | mostra **Visualização + Inclusão**; Alterar/Excluir → "—" (Regra 6) |
| CRUD normal | mostra as 4 colunas |

## Regras aplicadas na UI (feedback imediato) e no servidor (fonte da verdade)
- **Regra 4/5:** `Ver` desmarcado → desabilita **e zera** Incluir/Alterar/Excluir.
- **Regra 2:** Dashboard e Relatórios (CRUD=Não) → só `Ver`.
- **Regra 6:** Consulta e Abertura de Chamado → só `Ver`/`Incluir`.
- Admin nunca no seletor e nunca gravado.
- A tela **não** toca no filtro meus×todos (rotina 10).

> A UI aplica as regras para dar feedback, mas o servidor **normaliza de novo** no
> `PUT` — não confiar só no cliente.

## Seed padrão (estado inicial; Admin depois ajusta)
| rotina \ papel | SOLICITANTE | ATENDENTE | GERENCIA |
|---|---|---|---|
| dashboard | — | ver | ver |
| chamados.consulta | ver | ver | ver |
| chamados.abertura | ver, incluir | ver, incluir | ver, incluir |
| cadastros.setores | — | — | ver |
| cadastros.tipos | — | ver, incluir, alterar | ver |
| cadastros.equip | — | ver, incluir, alterar | ver |
| cadastros.servicos | — | ver, incluir, alterar | ver |
| cadastros.usuarios | — | — | ver |
| analise.relatorios | — | ver | ver |
| analise.config | — | — | — |

## Endpoints (todos restritos a ADMIN → 403 caso contrário)
- `GET /permissoes?papel=GERENCIA` — matriz do papel (rotinas + quarteto;
  rotina sem linha ⇒ tudo `false`).
- `PUT /permissoes?papel=GERENCIA` — grava em lote (upsert
  `ON CONFLICT (papel, rotina_id)`), aplicando a normalização das regras 2/4/6.

## Flutter
Feature `features/permissionamento/`:
- `PermissionamentoView` + `PermissionamentoViewModel` (Riverpod `AsyncNotifier`).
  Estado = `{ papel, matriz, dirty }`; trocar papel recarrega `GET /permissoes`.
- Tabela (web) × cards (mobile) via `LayoutBuilder` (ver `01`).
- Lógica de exibição de coluna e trava por papel espelha a do mockup
  (`Permissionamento.dc.html` → `renderVals`): `is_crud`/`is_chamado` decidem
  colunas; `ver=false` desabilita e zera as demais.
- `salvarLote(papel, itens)` no repositório → `PUT /permissoes`.
- Item de menu visível só para Admin (`visibleForPapeis: [admin]` por ora;
  passa a ser matriz na rotina 13).

## Critérios de aceite (rotina 12)
- [ ] Selecionar Gerência carrega a matriz; salvar e recarregar mantém o marcado.
- [ ] Desmarcar `Ver` de `cadastros.setores` zera e desabilita os outros 3 (UI e persistência).
- [ ] Rotinas de chamado sem Alterar/Excluir; Dashboard/Relatórios só com Ver.
- [ ] `GET/PUT /permissoes` retornam 403 para não-Admin.
- [ ] Admin não é opção no seletor de papel.
