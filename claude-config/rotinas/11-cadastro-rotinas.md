# Rotina 11 — Cadastro de Rotinas do sistema

## Objetivo

Criar o **registro das rotinas (telas/menus) do sistema** numa tabela, populada
pelo servidor via migration/seed. Esse cadastro é a fonte da verdade que a tela
de permissionamento (rotina 12) percorre para o admin marcar quem vê/edita cada
rotina, e que o runtime (rotina 13) usa para montar o menu.

## Depende de

`00-fundacao-infra.md`. Independe do papel Gerência.

## Pode rodar em paralelo com

`10-papel-gerencia.md`. **Bloqueia** `12-permissionamento-admin.md` e
`13-aplicacao-permissoes.md`.

## Escopo — Banco

Migration nova (ex. `0006_rotinas.sql`). Tabela `rotinas`:

| Coluna          | Tipo        | Origem no pedido do usuário            |
|-----------------|-------------|----------------------------------------|
| `id`            | SERIAL PK   | ID inteiro                             |
| `nome`          | TEXT        | Nome                                   |
| `is_pai`        | BOOLEAN     | Indicativo de Rotina Pai (Sim/Não)     |
| `rotina_pai_id` | INT FK→rotinas(id) NULL | Rotina Pai                 |
| `is_crud`       | BOOLEAN     | Indicativo de rotina de CRUD (Sim/Não) |
| `is_chamado`    | BOOLEAN     | Indicativo de rotina de chamado (Sim/Não) |

**Colunas adicionais recomendadas** (não estão no pedido mínimo, mas são
necessárias para o menu/roteamento funcionar de fato — documentar e incluir):

| Coluna    | Tipo    | Por quê                                                       |
|-----------|---------|--------------------------------------------------------------|
| `chave`   | TEXT UNIQUE | Slug estável (`'setores'`, `'chamados.abertura'`) para o código referenciar a rotina sem depender do `id` gerado. |
| `rota`    | TEXT NULL   | Path do go_router (`'/setores'`); NULL para rotina pai (grupo). |
| `ordem`   | INT         | Ordenação dentro do grupo no menu.                            |
| `icone`   | TEXT NULL   | Nome do ícone Lucide, para o menu dinâmico da rotina 13.      |

Restrições/integridade:
- `rotina_pai_id` só é preenchido quando `is_pai = false`; rotina pai tem
  `rotina_pai_id IS NULL` e `is_pai = true` (opcional: `CHECK`).
- Uma rotina pai (grupo) tem `is_crud = false` e `is_chamado = false` (é só
  agrupador de submenu — regra 1 do pedido).

### Seed das rotinas (via migration/seed)

O servidor **popula** a tabela. Mapeamento a partir do `kNavEntries` atual
(`app_shell.dart`) + subrotas de chamado. Referência (o dev ajusta chaves/ícones):

| chave                | nome                  | is_pai | pai        | is_crud | is_chamado | rota                |
|----------------------|-----------------------|:------:|------------|:-------:|:----------:|---------------------|
| `dashboard`          | Dashboard             |  Não   | —          |   Não   |    Não     | `/`                 |
| `chamados`           | Chamados              |  Sim   | —          |   Não   |    Não     | —                   |
| `chamados.consulta`  | Consulta de Chamados  |  Não   | chamados   |   Sim   |    Sim     | `/chamados`         |
| `chamados.abertura`  | Abertura de Chamado   |  Não   | chamados   |   Sim   |    Sim     | `/chamados/abrir`   |
| `cadastros`          | Cadastros             |  Sim   | —          |   Não   |    Não     | —                   |
| `cadastros.setores`  | Setores               |  Não   | cadastros  |   Sim   |    Não     | `/setores`          |
| `cadastros.tipos`    | Tipos de Equipamento  |  Não   | cadastros  |   Sim   |    Não     | `/tipos-equipamento`|
| `cadastros.equip`    | Equipamentos          |  Não   | cadastros  |   Sim   |    Não     | `/equipamentos`     |
| `cadastros.servicos` | Serviços              |  Não   | cadastros  |   Sim   |    Não     | `/servicos`         |
| `cadastros.usuarios` | Usuários              |  Não   | cadastros  |   Sim   |    Não     | `/usuarios`         |
| `analise`            | Análise               |  Sim   | —          |   Não   |    Não     | —                   |
| `analise.relatorios` | Relatórios            |  Não   | analise    |   Não   |    Não     | `/relatorios`       |
| `analise.config`     | Configurações         |  Não   | analise    |   Sim   |    Não     | `/configuracoes`    |

Fora do cadastro (regras 10 e 11 do pedido — **não** entram na tabela nem no
permissionamento): **Sair/Logout** e **Notificações (sininho)**.

## Escopo — Servidor

- `models/rotina.dart`: modelo `Rotina` (campos acima). Sem `SELECT *`.
- `repositories/rotina_repository.dart`:
  - `listarTodas()` — colunas explícitas, ordenado por pai e `ordem`, montando a
    árvore (pai → filhos).
- `routes/rotinas_route.dart`:
  - `GET /rotinas` — retorna a árvore de rotinas. Usado pela tela de
    permissionamento (rotina 12) e, indiretamente, pelo runtime.
  - Somente `ADMIN` (via `requirePapel` ou matriz) — é dado de configuração.

## Escopo — Mobile

Nenhuma tela nova nesta rotina. Só o DTO/repositório que a rotina 12 vai
consumir:
- `features/permissionamento/rotina_dto.dart` — espelha `Rotina` (inclui
  `chave`, `nome`, `isPai`, `rotinaPaiId`, `isCrud`, `isChamado`, `rota`,
  `icone`, `ordem`).
- `features/permissionamento/rotina_repository.dart` — `GET /rotinas`.

## Regras de negócio

1. Rotina Pai = Sim são agrupadores de submenu (`Cadastros`, `Chamados`,
   `Análise`); não têm rota nem CRUD (regra 1).
2. `is_crud = false` (Dashboard, Relatórios) → **não** existe incluir/alterar/
   excluir; a permissão dessas rotinas é só Ver (regra 2).
3. `is_crud = true` são telas de input (Setores, Abertura...) → têm o quarteto
   Ver/Incluir/Alterar/Excluir (regra 3), respeitando a exceção de chamado
   abaixo.
4. `is_chamado = true` (Consulta/Abertura de Chamado): como não há edição nem
   exclusão de chamado, só fazem sentido **Ver** e **Incluir** (regra 6). A tela
   de permissão (rotina 12) esconde Alterar/Excluir para essas rotinas.

## Critérios de aceite

- [ ] Migration cria `rotinas` e o seed insere a árvore completa (grupos + folhas).
- [ ] `GET /rotinas` retorna a hierarquia (pai com seus filhos) com colunas
      explícitas (sem `SELECT *`).
- [ ] Nenhuma linha viola: pai com `rotina_pai_id` preenchido, ou folha sem pai.
- [ ] Logout e Notificações **não** aparecem na tabela.

## Consultar

Skills: `dart-shelf-server`, `postgres-schema-chamados`, `flutter-mvvm-arquitetura`.
Rotinas: `12-permissionamento-admin.md`, `13-aplicacao-permissoes.md`.
