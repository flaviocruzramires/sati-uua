# 06 — Registro de Andamento do Chamado

Requisito: **Item 4**. Papel: `ATENDENTE`/`ADMIN`. Mockup: `Chamado Atendimento.dc.html`.

## Objetivo
Tela de detalhe do chamado: cabeçalho + **linha do tempo do histórico** +
formulário **"Registrar Atendimento"**. `GET /chamados/:id` traz o detalhe e a
lista `chamado_historico` ordenada por `data_retorno`.

## Layout Web
Topbar: `arrow-left` + "Chamado #1024" + **tag de situação** (ex.: Em Andamento = accent-2).

### 1. Card de resumo (`.card`)
Grid de 5 colunas com kicker+valor: **Solicitante, Setor, Equipamento, Serviço,
Aberto em**. Régua `hr`. Bloco **Descrição** (kicker + texto do problema).

### 2. Duas colunas (1.3fr / 1fr)
- **Histórico de atendimento (timeline):** cada item = coluna de marcador
  (quadrado accent 10px + linha `divider` 2px) + data/autor (12px muted) +
  descrição. Último item pode indicar estado atual ("Aguardando novo retorno",
  marcador accent-300).
- **Registrar Atendimento (`.card.elev-md`):**
  - `dialog-title` "Registrar Atendimento".
  - **Descrição do atendimento** — `textarea` (4 linhas), obrigatório.
  - **Data de retorno** — `input type=datetime-local`.
  - Checkbox **"Marcar como encerrado"**.
  - Ações: **Cancelar** / **Salvar Atendimento** (primário).

## Layout Mobile
App bar com voltar. Card-resumo compacto (título + tag + meta). Card "Histórico"
(timeline reduzida). Card "Registrar Atendimento" com textarea, data de retorno,
checkbox e botão primário block.

## Regras de negócio (críticas — `rotinas/07`)
- `POST /chamados/:id/historico`: `usuario_responsavel_id`=autenticado,
  `data_retorno`, `descricao`, `marca_encerramento`.
- **Transação obrigatória:** se `marca_encerramento=true`, na **mesma transação**
  `UPDATE chamados SET situacao='ENCERRADO', data_fechamento=now()`.
- A situação **nunca** é alterada diretamente — só via novo histórico
  (`marca_encerramento`) ou pela atribuição de atendente (→ `EM_ANDAMENTO`).
- **Chamado sem atendente atribuído não pode ser encerrado** — bloquear com erro
  claro. Mostrar botão "Assumir/Atribuir" quando não houver responsável
  (`PUT /chamados/:id`, só ATENDENTE/ADMIN).

## Estados
- Sem atendente: form de encerramento desabilitado + CTA "Assumir chamado".
- Encerrado: form some/desabilita; situação vira `tag-neutral` "Encerrado";
  timeline ganha item final de encerramento.

## Flutter
`ChamadoDetalheView` + `ViewModel`. Timeline como `ListView` de itens custom
(marcador quadrado, raio 0). Encerramento chama endpoint transacional; UI reflete
o novo `situacao` retornado (sempre espelha o último histórico relevante).
