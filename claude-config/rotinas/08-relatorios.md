# Rotina 08 — Relatórios de Acompanhamento

## Objetivo

Relatórios de chamados filtráveis por situação, solicitante, atendente,
equipamento, serviço e período (abertura e fechamento).

## Depende de

- `00-fundacao-infra.md`
- `07-chamados.md` — precisa haver dados reais de chamados para relatar.
- Usa os combos já existentes de `03-cadastro-usuarios.md`,
  `05-cadastro-equipamentos.md`, `06-servicos-ti.md` para os filtros
  (nenhuma dependência funcional nova além do `GET` de cada um).

## Pode rodar em paralelo com

`09-configuracoes.md` (sem dependência mútua).

## Escopo — Servidor

- View de apoio `vw_chamados_relatorio` (ver skill `postgres-schema-chamados`),
  colunas explícitas via joins com `usuarios`, `equipamentos`, `servicos`.
- `GET /relatorios/chamados` com todos os filtros combináveis (opcionais):
  `situacao`, `solicitante_id`, `atendente_id`, `equipamento_id`, `servico_id`,
  `abertura_de`/`abertura_ate`, `fechamento_de`/`fechamento_ate`, mais
  `page`/`pageSize`.
- Resposta inclui `data` (página atual), `total` (contagem do filtro completo)
  e `resumo` (contagem por situação + tempo médio de resolução), calculado
  sobre o conjunto filtrado, não sobre a página. Ver contrato completo na
  skill `relatorios-chamados`.

## Escopo — Mobile

- Feature `relatorios/`: painel de filtros (combos alimentados pelos
  endpoints reais de usuários/equipamentos/serviços, nunca lista fixa),
  resultado em tabela paginada + cabeçalho de resumo.

## Critérios de aceite

- [ ] Cada filtro testado isoladamente e em combinação (ex.: situação +
      período).
- [ ] `resumo` calculado sobre o filtro completo, não sobre a página exibida.
- [ ] Consultas usam os índices da rotina 00 (verificar `EXPLAIN` se o volume
      de dados de teste permitir).
- [ ] Sem `SELECT *`.

## Consultar

Skills: `relatorios-chamados`, `postgres-schema-chamados`, `dart-shelf-server`,
`flutter-mvvm-arquitetura`.
