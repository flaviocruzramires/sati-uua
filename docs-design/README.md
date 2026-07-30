# docs-design — Especificação de UI/UX do SATI-UUA

Documentação de **design de interface** do SATI-UUA (Sistema de Atendimento de
Tecnologia da Informação — UEMS Aquidauana), para ser consumida pelo Claude Code
(agents `flutter-mobile-dev`) ao implementar as telas em Flutter (MVVM + Riverpod).

> **Fonte da verdade visual.** Estes arquivos descrevem **exatamente** o layout
> aprovado. Ao implementar, **não invente** cores, espaçamentos, componentes ou
> telas fora do que está aqui. Toda cor/tipografia/spacing sai dos **design
> tokens** de `00-design-tokens.md` (nada de valores "hardcoded" avulsos), como
> exige o `HARNESS.md` (checklist "Visual clean").

## Como usar

1. Leia **`00-design-tokens.md`** primeiro e crie o `ThemeData` único do app a
   partir dele (`mobile/lib/core/theme/`). Nenhuma tela pode usar cor/estilo fora
   desses tokens.
2. Leia **`01-shell-navegacao.md`** — o esqueleto (shell) responsivo que envolve
   todas as telas internas (sidebar+topbar no web/desktop, app bar + bottom nav
   no mobile).
3. Para cada tela, leia o `.md` correspondente. Cada um traz: objetivo, papel de
   usuário, layout web, layout mobile, componentes do design system usados,
   campos/colunas, estados e o mapeamento para widgets Flutter.
4. Cada doc referencia o **mockup HTML aprovado** (arquivos `*.dc.html` na raiz
   do projeto de design) — abra-o como referência pixel a pixel.

## Índice

| Doc | Tela | Requisito do cliente | Mockup |
|---|---|---|---|
| `00-design-tokens.md` | Design tokens (cor, tipografia, spacing, ícones) | — | `styles.css` |
| `01-shell-navegacao.md` | Shell/navegação responsiva | — | (todas) |
| `02-login.md` | Login | Acesso (rotina 01) | `Login.dc.html` |
| `03-dashboard.md` | Dashboard com quantitativos | Item 6 | `Dashboard.dc.html` |
| `04-cadastros-crud.md` | Modelos de CRUD + listagem paginada | Itens 1 e 2 | `Cadastro Servico/Equipamento/Usuario.dc.html` |
| `05-chamado-abertura.md` | Abertura de chamado | Item 3 | `Chamado Abertura.dc.html` |
| `06-chamado-atendimento.md` | Registro de andamento | Item 4 | `Chamado Atendimento.dc.html` |
| `07-chamado-listagem.md` | Listagem de chamados | Item 5 | `Chamado Listagem.dc.html` |

## Convenções

- **Design system:** Modernist (flat, sem cantos arredondados, réguas de 2px,
  fonte Archivo, alinhamento à esquerda). Paleta re-seedada com as cores do logo
  (navy UEMS + verde). Ver `00-design-tokens.md`.
- **Responsivo:** breakpoints em `01-shell-navegacao.md`. Regra geral de listas:
  **tabela (`DataTable`) no web, cards no mobile** (conforme `rotinas/07-chamados.md`).
- **Sem `SELECT *`, DI via Riverpod, MVVM** — inalterado, ver `HARNESS.md`.
