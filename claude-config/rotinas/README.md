# Rotinas — contextos menores para execução paralela

Este diretório quebra `PLANO_IMPLEMENTACAO.md` em um `.md` por rotina funcional.
Cada arquivo é **autocontido**: traz só o que um agent precisa para implementar
aquela rotina (banco + servidor + mobile + critérios de aceite), sem precisar
carregar o plano inteiro. Isso permite abrir várias sessões/agents em paralelo,
um por rotina, desde que respeitem as dependências abaixo.

## Ondas de execução (o que pode rodar em paralelo)

```
Onda 0 (pré-requisito de tudo, não paraleliza)
  00-fundacao-infra.md

Onda 1 (paralelo entre si, dependem só da Onda 0)
  01-autenticacao.md
  02-cadastro-setores.md
  04-cadastro-tipos-equipamento.md
  06-servicos-ti.md

Onda 2 (paralelo entre si, dependem de partes específicas da Onda 1)
  03-cadastro-usuarios.md      → precisa de 01 (login) e 02 (combo de setor)
  05-cadastro-equipamentos.md  → precisa de 04 (combo de tipo) e 02 (combo de setor)

Onda 3 (ponto de convergência)
  07-chamados.md                → precisa de 03, 05 e 06

Onda 4 (paralelo entre si)
  08-relatorios.md               → precisa de 07
  09-configuracoes.md            → precisa de 01 (e 03 para papel ADMIN)

Onda 5 (bloco de permissionamento — cadeia, ver dependências internas)
  10-papel-gerencia.md           → precisa de 01 | paraleliza com 11
  11-cadastro-rotinas.md         → precisa de 00 | paraleliza com 10
  12-permissionamento-admin.md   → precisa de 10 e 11
  13-aplicacao-permissoes.md     → precisa de 10, 11 e 12 (fecha o bloco)
```

O bloco de permissionamento (10-13) troca a autorização estática de hoje
(`visibleForPapeis` no menu + `requirePapel`/`isAdmin` nas telas) por uma matriz
papel×rotina configurável pelo Admin. Dois eixos permanecem **independentes**: o
permissionamento decide *se a tela/menu aparece*; o filtro "meus × todos" de
chamados (rotina 10) decide *quais registros a tela lista*.

Dentro de cada rotina, o trabalho de servidor e de mobile também pode ser
paralelizado entre dois agents (`dart-server-dev` e `flutter-mobile-dev`),
desde que o contrato de API (rotas/payloads) descrito no arquivo da rotina
seja tratado como fonte da verdade por ambos.

## Como usar

1. Rode `00-fundacao-infra.md` sozinho, até os critérios de aceite passarem.
2. Dispare os agents da Onda 1 em paralelo, um por arquivo de rotina.
3. Ao concluir os pré-requisitos de cada item da Onda 2, dispare-os em paralelo.
4. Siga assim até `09-configuracoes.md`.
5. Cada rotina termina só quando o agent `qa-tester-chamados` validar os
   critérios de aceite listados no próprio arquivo da rotina (não o checklist
   inteiro de `HARNESS.md` — apenas a fatia relevante).

## Convenção de cada arquivo de rotina

- **Objetivo** — o que essa rotina entrega.
- **Depende de** — o que precisa existir antes.
- **Pode rodar em paralelo com** — outras rotinas sem dependência mútua.
- **Escopo banco / servidor / mobile** — o suficiente para implementar sem
  abrir os outros arquivos (com referência às skills para detalhes que se
  repetem em todas as rotinas, como a regra de nunca usar `SELECT *`).
- **Regras de negócio específicas**.
- **Critérios de aceite** — o que precisa estar verde para considerar pronto.

Skills compartilhadas (não duplicadas em cada rotina, mas referenciadas):
`flutter-mvvm-arquitetura`, `dart-shelf-server`, `postgres-schema-chamados`,
`relatorios-chamados` (em `claude-config/skills/`).
