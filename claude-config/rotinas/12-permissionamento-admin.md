  # Rotina 12 — Tela de Permissionamento (Admin)

## Objetivo

Dar ao **Admin** uma tela para gerenciar o que cada **papel** pode fazer em cada
**rotina** do sistema: selecionar um papel, ver a lista de rotinas e marcar
Ver / Incluir / Alterar / Excluir. Persiste a matriz de permissões que o runtime
(rotina 13) aplica.

## Depende de

- `10-papel-gerencia.md` (papel `GERENCIA` precisa existir para ser selecionável).
- `11-cadastro-rotinas.md` (`GET /rotinas` e a árvore populada).

## Pode rodar em paralelo com

Nada do bloco — é o meio da cadeia. **Bloqueia** `13-aplicacao-permissoes.md`,
que consome a matriz que esta rotina grava.

## Escopo — Banco

Migration nova (ex. `0007_rotina_permissoes.sql`). Tabela `rotina_permissoes`:

| Coluna        | Tipo                    | Observação                          |
|---------------|-------------------------|-------------------------------------|
| `id`          | SERIAL PK               |                                     |
| `papel`       | TEXT                    | `SOLICITANTE\|ATENDENTE\|GERENCIA` (Admin não entra — ver regra) |
| `rotina_id`   | INT FK→rotinas(id) ON DELETE CASCADE |                        |
| `pode_ver`    | BOOLEAN NOT NULL DEFAULT false |                              |
| `pode_incluir`| BOOLEAN NOT NULL DEFAULT false |                              |
| `pode_alterar`| BOOLEAN NOT NULL DEFAULT false |                              |
| `pode_excluir`| BOOLEAN NOT NULL DEFAULT false |                              |

- `UNIQUE (papel, rotina_id)` — uma linha por par papel×rotina.
- **Admin não é configurável**: Admin tem acesso total sempre (bypass no código,
  rotina 13). Não gravar linhas de Admin, e a tela **não** oferece Admin no
  seletor de papel — evita o admin se trancar para fora do sistema.

### Seed de permissões padrão

Popular um padrão inicial coerente com o comportamento atual (o admin depois
ajusta na tela). Sugestão (`true` = marcado):

| rotina \ papel        | SOLICITANTE           | ATENDENTE              | GERENCIA               |
|-----------------------|-----------------------|------------------------|------------------------|
| dashboard             | —                     | ver                    | ver                    |
| chamados.consulta     | ver (só os próprios¹) | ver                    | ver                    |
| chamados.abertura     | ver, incluir          | ver, incluir           | ver, incluir           |
| cadastros.setores     | —                     | —                      | ver                    |
| cadastros.tipos       | —                     | ver, incluir, alterar  | ver                    |
| cadastros.equip       | —                     | ver, incluir, alterar  | ver                    |
| cadastros.servicos    | —                     | ver, incluir, alterar  | ver                    |
| cadastros.usuarios    | —                     | —                      | ver                    |
| analise.relatorios    | —                     | ver                    | ver                    |
| analise.config        | —                     | —                      | —                      |

¹ "só os próprios" **não** é uma permissão desta tabela — é o filtro meus×todos
da rotina 10. Aqui `pode_ver` só decide se a rotina Chamados aparece no menu.

## Escopo — Servidor

- `models/rotina_permissao.dart` — modelo do quarteto por papel×rotina.
- `repositories/rotina_permissao_repository.dart`:
  - `listarPorPapel(Papel papel)` — colunas explícitas.
  - `salvarLote(Papel papel, List<RotinaPermissao> itens)` — upsert
    (`INSERT ... ON CONFLICT (papel, rotina_id) DO UPDATE`).
- `routes/permissoes_route.dart` (todas restritas a `ADMIN`):
  - `GET /permissoes?papel=GERENCIA` — devolve a matriz do papel (rotinas +
    quarteto). Rotina sem linha → tudo `false`.
  - `PUT /permissoes?papel=GERENCIA` — grava a matriz do papel (lote).
- **Normalização no servidor** (fonte da verdade, não confie só na UI):
  - Regra 4: se `pode_ver = false` → zera incluir/alterar/excluir.
  - Regra 2: se a rotina tem `is_crud = false` → incluir/alterar/excluir = false.
  - Regra 6: se `is_chamado = true` → alterar/excluir = false (só ver/incluir).

## Escopo — Mobile

Feature nova `features/permissionamento/`:
- Rota `/permissionamento`, item de menu visível só para Admin (por ora estático
  `visibleForPapeis: [admin]`; passa a ser matriz na rotina 13).
- `PermissionamentoView` + `PermissionamentoViewModel` (Riverpod):
  - Seletor de **papel** no topo (Solicitante / Atendente / Gerência).
  - Ao escolher o papel: carrega `GET /permissoes?papel=`.
  - Tabela de rotinas (agrupadas por pai, folhas indentadas) com 4 checkboxes:
    Visualização / Inclusão / Alteração / Exclusão.
  - Aplicar as regras **também na UI** (feedback imediato):
    - Ver desmarcado → desabilita e zera os outros 3 (regra 4/5).
    - `is_crud = false` → some com as colunas Incluir/Alterar/Excluir (regra 2).
    - `is_chamado = true` → some com Alterar/Excluir (regra 6).
  - Botão Salvar → `PUT /permissoes?papel=`.
- Responsiva nas 3 larguras (tabela no desktop, cards/lista no mobile).

## Regras de negócio

- Regra 4/5: Ver = Não zera e trava os demais; Ver = Sim libera o admin a marcar
  incluir/alterar/excluir.
- Regra 2: Dashboard/Relatórios (CRUD=Não) só têm Ver.
- Regra 6: Chamado (Consulta/Abertura) só têm Ver/Incluir.
- Admin nunca aparece no seletor e nunca é gravado (acesso total implícito).
- A tela mexe **só** no permissionamento; não toca no filtro meus×todos.

## Critérios de aceite

- [ ] Selecionar Gerência carrega a matriz atual; salvar e recarregar mantém o
      que foi marcado.
- [ ] Desmarcar Ver de `cadastros.setores` zera e desabilita incluir/alterar/
      excluir (na UI e no que é persistido).
- [ ] Rotinas de chamado não exibem Alterar/Excluir; Dashboard/Relatórios não
      exibem Incluir/Alterar/Excluir.
- [ ] Endpoints `GET/PUT /permissoes` retornam 403 para não-Admin.
- [ ] Admin não é opção no seletor de papel.

## Consultar

Skills: `dart-shelf-server`, `postgres-schema-chamados`, `flutter-mvvm-arquitetura`.
Rotinas: `11-cadastro-rotinas.md`, `13-aplicacao-permissoes.md`.
