# SATI-UUA — Sistema de Atendimento de TI (UEMS Aquidauana)

Aplicativo Flutter (mobile + web) para gerenciamento de chamados do Setor de
TI, com servidor próprio em Dart (Shelf) e PostgreSQL.

## Documentação de planejamento

- [`PLANO_IMPLEMENTACAO.md`](./PLANO_IMPLEMENTACAO.md) — visão geral, modelo
  de domínio, arquitetura, roadmap.
- [`HARNESS.md`](./HARNESS.md) — como rodar/testar localmente, checklist de
  requisitos técnicos.
- [`SEQUENCIA-IMPLEMENTACAO.md`](./SEQUENCIA-IMPLEMENTACAO.md) — sequência de
  implementação por blocos (execução solo, sessão a sessão).
- [`claude-config/`](./claude-config/) — agents, skills e rotinas para o
  fluxo de trabalho com Claude Code.
- [`docs-design/`](./docs-design/) — especificação de UI/UX, design tokens,
  catálogo de componentes reutilizáveis e os mockups aprovados
  (`docs-design/mockups/*.dc.html`).

## Estrutura do repositório

```
server/       # servidor Dart (Shelf) — ver server/README.md
mobile/       # app Flutter (mobile + web) — criado no bloco 2 da sequência
docs-design/  # especificação visual + mockups
claude-config/  # agents/skills/rotinas do Claude Code
```

## Estado atual

Bloco 1 da sequência (`SEQUENCIA-IMPLEMENTACAO.md`) — **Fundação: Banco +
Servidor** — implementado: schema completo do PostgreSQL, servidor Shelf
com middlewares base e `/health`, composition root pronto para as próximas
rotinas. Ver `server/README.md` para como rodar e para a nota sobre o que
ainda falta verificar (compilar/rodar o Dart num ambiente com acesso a
pub.dev).

Próximo bloco: **Fundação — Mobile bootstrap + tema** (bloco 2).
