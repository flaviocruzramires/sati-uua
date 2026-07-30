# Rotina 07 — Chamados (núcleo do sistema)

## Objetivo

Abertura de chamado, atribuição de atendente, histórico de atendimento,
encerramento e acompanhamento da situação — o coração funcional do sistema.

## Depende de

- `00-fundacao-infra.md`
- `03-cadastro-usuarios.md` — solicitante e atendente são usuários reais.
- `05-cadastro-equipamentos.md` — combo de equipamento.
- `06-servicos-ti.md` — combo de serviço.

## Pode rodar em paralelo com

Nenhuma outra rotina de cadastro está no mesmo nível — esta é o ponto de
convergência das anteriores. **Dentro** desta rotina, porém, servidor e
mobile podem ser feitos em paralelo por dois agents assim que o contrato de
API abaixo estiver fechado.

## Bloqueia

`08-relatorios.md` (relatórios consultam dados de chamados).

## Escopo — Banco

Tabelas `chamados` e `chamado_historico` já criadas na rotina 00. Confirmar
que os índices existem (`postgres-schema-chamados`):
`idx_chamados_situacao`, `idx_chamados_solicitante`, `idx_chamados_responsavel`,
`idx_chamados_equipamento`, `idx_chamados_servico`, `idx_chamados_data_abertura`,
`idx_chamados_data_fechamento`, `idx_chamado_historico_chamado`.

## Escopo — Servidor

- `POST /chamados` — abre chamado: `descricao`, `equipamento_id` (opcional),
  `servico_id` (opcional); `usuario_solicitante_id` = usuário autenticado;
  `situacao` inicial = `ABERTO`.
- `GET /chamados` — lista paginada; filtros: `situacao`, `solicitante_id`,
  `atendente_id` (para "meus chamados" e "fila de atendimento").
- `GET /chamados/:id` — detalhe completo, incluindo lista de
  `chamado_historico` ordenada por `data_retorno`.
- `PUT /chamados/:id` — atribuir/trocar `usuario_responsavel_id` (só
  `ATENDENTE`/`ADMIN`).
- `POST /chamados/:id/historico` — cria registro
  (`usuario_responsavel_id`=autenticado, `data_retorno`, `descricao`,
  `marca_encerramento`). **Transação obrigatória**: se `marca_encerramento=true`,
  na mesma transação faz
  `UPDATE chamados SET situacao='ENCERRADO', data_fechamento=now() WHERE id=...`.

## Escopo — Mobile

- Feature `chamados/`:
  - Tela "Meus chamados" (papel `SOLICITANTE`): lista + botão "Abrir chamado"
    (formulário com descrição, equipamento, serviço).
  - Tela "Fila de atendimento" (papel `ATENDENTE`/`ADMIN`): lista filtrável por
    situação, ação de assumir/atribuir.
  - Tela de detalhe: linha do tempo do histórico + formulário "Registrar
    atendimento" (descrição, data de retorno, checkbox "Marcar como encerrado").

## Regras de negócio críticas

- A situação do chamado **nunca** é alterada diretamente — só como efeito de
  um novo registro em `chamado_historico` com `marca_encerramento=true`, ou
  pela atribuição de atendente (`EM_ANDAMENTO` ao atribuir).
- Um chamado sem atendente atribuído não pode ser encerrado.
- `data_fechamento` só é preenchida no momento do encerramento (nunca setada
  manualmente por outro fluxo).

## Critérios de aceite

- [ ] Transação de encerramento coberta por teste de integração (histórico +
      atualização de chamado atômicos).
- [ ] Situação do chamado sempre reflete o último histórico relevante.
- [ ] Tentativa de encerrar sem atendente atribuído é bloqueada com erro claro.
- [ ] Sem `SELECT *`.
- [ ] Telas responsivas (lista em `DataTable` na web, cards em mobile).

## Consultar

Skills: `dart-shelf-server`, `postgres-schema-chamados`, `flutter-mvvm-arquitetura`.
