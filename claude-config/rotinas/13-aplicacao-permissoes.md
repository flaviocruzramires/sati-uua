# Rotina 13 — Aplicação das permissões (login, menu e telas)

## Objetivo

Fazer o sistema **obedecer** à matriz configurada na rotina 12: ao logar, carregar
as permissões do papel do usuário e, com elas, montar o menu, liberar/bloquear as
listagens e mostrar/esconder os botões + (novo), Editar e Excluir. Substitui os
`visibleForPapeis` estáticos e os `isAdmin` espalhados pelas telas.

## Depende de

`10`, `11` e `12` — precisa do papel Gerência, da árvore de rotinas e da matriz
persistida.

## Pode rodar em paralelo com

Nada; é o fechamento do bloco.

## Escopo — Servidor

- `GET /me/permissoes` — retorna a matriz **efetiva do usuário logado** (resolve
  o papel do JWT → permissões daquele papel). Admin recebe tudo `true` (bypass).
  Chamado logo após o login pelo mobile.
  - Formato sugerido: mapa `chave da rotina → {ver, incluir, alterar, excluir}`,
    já normalizado pelas regras 2/4/6.
- **Defesa em profundidade** (não confiar só no menu do cliente): trocar, nas
  rotas de CRUD, o `requirePapel(...)` legado por uma checagem de permissão:
  - helper `requirePermissao(req, chave, acao)` que lê o papel do JWT, consulta a
    matriz e lança 403 se faltar a ação. Ex.: `POST /setores` →
    `requirePermissao(req, 'cadastros.setores', Acao.incluir)`.
  - Endpoints de chamado que são atendimento (assumir/responder) **continuam** no
    `requirePapel(Papel.atendente)` — não são CRUD nem entram na matriz.
- O filtro meus×todos (`chamados_route.dart`) **não muda** aqui — já foi tratado
  na rotina 10 e é independente.

## Escopo — Mobile

- `core/auth/permissoes_provider.dart`:
  - Ao autenticar, chama `GET /me/permissoes` e guarda num provider
    (`Map<String, PermissaoRotina>`, chave = `chave` da rotina).
  - Helpers: `podeVer(chave)`, `podeIncluir(chave)`, `podeAlterar(chave)`,
    `podeExcluir(chave)`. Admin → sempre `true`.
  - Limpar no logout.
- **Menu dinâmico** (`app_shell.dart`): parar de usar `kNavEntries` estático com
  `visibleForPapeis`. Montar as entradas a partir de `GET /rotinas` filtrando por
  `podeVer(chave)`:
  - Regra 9: rotina sem `ver` → item não aparece.
  - Grupo (pai) só aparece se tiver ao menos uma folha visível.
  - Sair e Notificações continuam fixos, **fora** do controle (regras 10/11).
- **Guarda de rota** (`app_router.dart`): ao navegar para uma rota, se
  `!podeVer(chave)` correspondente → redirecionar/negar (impede deep-link para
  tela sem permissão).
- **Botões de ação nas telas CRUD** (regra 8) — hoje as views usam `isAdmin`
  (ex. `setores_view.dart:33`, `:108`, `:203`). Trocar por permissão da rotina:
  - listagem: só entra se `podeVer('cadastros.setores')`.
  - botão **+ Novo**: `podeIncluir('cadastros.setores')`.
  - botão **Editar**: `podeAlterar('cadastros.setores')`.
  - botão **Excluir**: `podeExcluir('cadastros.setores')`.
  - Aplicar o mesmo padrão em: setores, tipos_equipamento, equipamentos,
    servicos, usuarios. Em chamados: Abertura gated por `podeIncluir`, listagem
    por `podeVer`.
- **Tela pós-login**: hoje `initialLocation`/`'/'` cai no Dashboard. Se o papel
  não tiver `podeVer('dashboard')` (ex. Solicitante), redirecionar para a
  primeira rotina visível do menu (ex. Abertura de Chamado) — ajuste geral 1 do
  pedido.

## Regras de negócio

- Regra 7: no login o sistema identifica o papel e carrega ver/alterar/... daquele
  papel.
- Regra 8: CRUD=Sim e Chamado=Não → listagem por Ver; + por Incluir; Editar por
  Alterar; Excluir por Excluir.
- Regra 9: rotina sem permissão não aparece no menu (e não é navegável).
- Regras 10/11: Sair e Notificações nunca são controlados.
- O permissionamento **não** interfere no "ver só os meus × ver todos" de chamados
  (rotina 10). São dois eixos independentes: um decide *se a tela aparece*, o
  outro decide *quais registros ela lista*.

## Critérios de aceite

- [ ] Logar como Gerência mostra no menu exatamente as rotinas com `ver` marcado
      para Gerência; nenhuma a mais.
- [ ] Tirar `incluir` de Setores para Atendente some com o botão + para ele, e
      `POST /setores` passa a retornar 403 (servidor barra, não só a UI).
- [ ] Solicitante sem `ver` de Dashboard cai, após login, na primeira tela
      permitida — não numa tela em branco/negada.
- [ ] Deep-link para `/usuarios` sem permissão é bloqueado.
- [ ] Gerência vê **todos** os chamados (filtro da rotina 10) mesmo que o
      permissionamento só conceda `ver` — os dois controles coexistem.
- [ ] Sair e sininho funcionam para todos os papéis, independentemente da matriz.

## Consultar

Skills: `dart-shelf-server`, `flutter-mvvm-arquitetura`.
Rotinas: `10-papel-gerencia.md`, `11-cadastro-rotinas.md`,
`12-permissionamento-admin.md`.
