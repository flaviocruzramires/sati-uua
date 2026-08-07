# Índice de Planejamento — SATI-UUA

**Última atualização:** 2026-07-31

---

## Documentos de planejamento

| # | Documento | Tipo | Status |
|---|-----------|------|--------|
| 01 | [Anexos e Imagens em Chamados](01-anexos-imagens.md) | Melhoria | Aguardando validação |
| 02 | [Campo "Envolve Terceiro"](02-terceiro-envolvido.md) | Melhoria | Aguardando validação |
| 03 | [Retorno do Solicitante](03-retorno-solicitante.md) | Melhoria | Aguardando validação |
| 04 | [Notificações — Sininho](04-notificacoes-sininho.md) | Melhoria | Aguardando validação |
| 05 | [Bug: Listagem não atualiza após encerrar](05-bug-listagem-nao-atualiza.md) | Bug | Aguardando validação |

---

## Dependências entre os documentos

```
01 (Anexos)
  └── depende de: nenhum

02 (Terceiro)
  └── depende de: nenhum

03 (Retorno Solicitante)
  └── depende de: schema do historico (migration 0003)
  └── integra com: 04 (gera notificação RETORNO_SOLICITANTE)

04 (Notificações)
  └── depende de: 03 (evento retorno solicitante)
  └── integra com: 01 (upload gera notificação), 02 (sem notificação direta)

05 (Bug Listagem)
  └── depende de: nenhum — fix isolado
  └── deve ser feito PRIMEIRO (simples, corrige UX imediata)
```

---

## Ordem de implementação sugerida

1. **05 — Bug listagem** (15 min — impacto imediato, zero risco)
2. **02 — Terceiro envolvido** (migration simples + campos novos)
3. **03 — Retorno do solicitante** (schema + endpoint + widget novo)
4. **04 — Notificações** (maior esforço — banco + server + tela nova)
5. **01 — Anexos** (maior esforço técnico — upload de arquivos)

---

## Pontos abertos que precisam de decisão do usuário

| Doc | Questão |
|-----|---------|
| 01 | Armazenamento local ou S3? Tipos além de imagem (PDF)? Limite de tamanho ok? |
| 02 | Solicitante também pode indicar terceiro ao abrir? Múltiplos terceiros? |
| 03 | Ao solicitante responder, situação volta para EM_ANDAMENTO automaticamente? |
| 04 | Polling (30s) ou WebSocket? Retenção 90 dias? NOVO_CHAMADO notifica todos atendentes ou só admins? |
