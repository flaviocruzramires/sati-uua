---
name: relatorios-chamados
description: Use this skill whenever building the reporting/analytics features (backend endpoints or Flutter screens) for Chamados de TI — filtering and grouping by situação, solicitante, atendente, equipamento, serviço, and período (abertura/fechamento).
---

# Relatórios de acompanhamento de chamados

## Dimensões exigidas pelo cliente

- Situação
- Solicitante
- Atendente (usuário responsável)
- Equipamento
- Serviço
- Período — abertura e fechamento (duas datas distintas, não uma só)

## Contrato de API sugerido

Um único endpoint flexível, em vez de um endpoint por dimensão:

```
GET /relatorios/chamados
  ?situacao=ENCERRADO
  &solicitante_id=123
  &atendente_id=456
  &equipamento_id=789
  &servico_id=10
  &abertura_de=2026-07-01&abertura_ate=2026-07-31
  &fechamento_de=2026-07-01&fechamento_ate=2026-07-31
  &page=1&pageSize=50
```

Todos os filtros são opcionais e combináveis (AND). Resposta:

```json
{
  "data": [
    {
      "id": 1,
      "descricao": "...",
      "situacao": "ENCERRADO",
      "solicitante": {"id": 123, "nome": "..."},
      "atendente": {"id": 456, "nome": "..."},
      "equipamento": {"id": 789, "descricao": "..."},
      "servico": {"id": 10, "descricao": "..."},
      "data_abertura": "2026-07-05T10:00:00Z",
      "data_fechamento": "2026-07-06T14:00:00Z"
    }
  ],
  "total": 137,
  "resumo": {
    "por_situacao": {"ABERTO": 12, "EM_ANDAMENTO": 5, "ENCERRADO": 120},
    "tempo_medio_resolucao_horas": 18.4
  }
}
```

- Query usa a view `vw_chamados_relatorio` (ou os joins equivalentes) definida
  na skill `postgres-schema-chamados`, sempre com colunas explícitas.
- Filtros de data usam os índices `idx_chamados_data_abertura`/`idx_chamados_data_fechamento`.
- `resumo.por_situacao` é um `GROUP BY situacao` sobre o mesmo conjunto filtrado
  (antes da paginação), não sobre a página atual.

## Tela de Relatórios (Flutter)

- Painel de filtros (situação, solicitante, atendente, equipamento, serviço,
  período de abertura, período de fechamento) — combos alimentados pelos
  mesmos endpoints de cadastro (`/usuarios?papel=ATENDENTE`, `/equipamentos`,
  `/servicos`), nunca uma lista hardcoded no app.
- Resultado em tabela (`DataTable` em telas largas, lista de cards em mobile —
  ver breakpoints na skill `flutter-mvvm-arquitetura`), com paginação.
- Um resumo/cabeçalho com as contagens por situação e o tempo médio de
  resolução, vindos de `resumo` na resposta da API (não recalculado no cliente).
- ViewModel de relatórios (`RelatorioChamadosViewModel`, `AsyncNotifier`)
  depende de `RelatorioRepository` — segue as mesmas regras de MVVM/DI das
  demais telas.

## Extensões futuras (fora do escopo inicial, deixar preparado)

- Exportação em CSV/PDF do resultado filtrado.
- Gráfico de evolução de chamados abertos/fechados por período.
