# 05 — Abertura de Chamado

Requisito: **Item 3**. Papel: `SOLICITANTE` (ADMIN/ATENDENTE também podem abrir).
Mockup: `Chamado Abertura.dc.html`.

## Objetivo
Criar um chamado. `POST /chamados` com `descricao`, `equipamento_id` (opcional),
`servico_id` (opcional); `usuario_solicitante_id` = usuário autenticado;
`situacao` inicial = **ABERTO**.

## Layout Web
Topbar: botão `arrow-left` (voltar) + título "Abrir Chamado". Conteúdo centralizado
em duas colunas:
- **Card do formulário (600px):**
  - Título "Descreva o problema" + subtítulo muted.
  - **Descrição do problema** — `textarea` (5 linhas), **obrigatório**.
  - Grid 2 colunas: **Equipamento (opcional)** select ("Nenhum / não se aplica" +
    lista); **Serviço (opcional)** select ("Selecione um serviço" + lista).
  - Régua `hr` + ações à direita: **Cancelar** (secundário) / **Abrir Chamado** (primário).
- **Card lateral (280px, fundo `surface`) "Como funciona":** 3 passos numerados
  (quadrado accent-100/accent-700): 1 descreva; 2 atendente notificado; 3 acompanhe
  em "Meus Chamados".

## Layout Mobile
App bar com voltar. Campos empilhados (Descrição textarea, Equipamento, Serviço),
card "Como funciona" compacto. Botão primário **"Abrir Chamado"** fixo no rodapé
(barra com borda superior 2px).

## Campos
| Campo | Tipo | Obrigatório | Origem do combo |
|---|---|---|---|
| descricao | textarea | sim | — |
| equipamento_id | select | não | `GET /equipamentos` |
| servico_id | select | não | `GET /servicos` |

## Estados
Validação: descrição não-vazia. Salvando: botão em loading. Sucesso: redireciona
ao detalhe do chamado criado (ver `06`) ou à lista com toast.

## Flutter
`AbrirChamadoView` + `ViewModel` (Riverpod). Combos via providers dos repositórios
de equipamentos/serviços. Sem `setState` para estado de negócio.
