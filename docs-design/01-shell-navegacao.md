# 01 — Shell e Navegação (responsivo)

Esqueleto que envolve **todas as telas internas** (autenticadas). Não repetir
lógica de navegação em cada tela — implementar um único shell responsivo
(ex.: `core/widgets/app_shell.dart`) e injetar o conteúdo da rota.

Referência visual: qualquer mockup interno, ex. `Dashboard.dc.html`,
`Chamado Listagem.dc.html`.

## Breakpoints

| Faixa | Largura | Layout |
|---|---|---|
| Mobile | < 768px | App bar no topo + **bottom navigation** (4 itens) |
| Tablet | 768–1080px | Sidebar recolhível (ícones) + topbar |
| Desktop/Web | > 1080px | **Sidebar fixa (248px)** + topbar |

## Desktop/Web

### Sidebar (248px, fundo `surface`, borda direita 2px `divider`)
- **Topo (marca):** logo `imagens/logo_sati_uua.jpg` 34×34 (fundo branco, padding 3px)
  + "SATI-UUA" (h5/800) + "UEMS Aquidauana" (10px, uppercase, tracking .08em, opacidade .7).
  Borda inferior 2px.
- **Itens de navegação** (18px ícone Lucide + label 13.5px, padding 10×12):
  - `Dashboard` (layout-grid)
  - `Chamados` (ticket)
  - Grupo **CADASTROS** (rótulo 10px uppercase neutral-600):
    `Setores` (building-2), `Tipos de Equipamento` (layers),
    `Equipamentos` (monitor), `Serviços` (sliders-horizontal), `Usuários` (users)
  - Grupo **ANÁLISE**: `Relatórios` (bar-chart-2), `Configurações` (settings)
  - **Item ativo:** fundo sólido `accent` (navy), texto `bg`, **sem canto
    arredondado, sem borda-esquerda** (bloco chapado, flush left). Hover
    (inativo): tint `text` 6%.
- **Rodapé (usuário):** borda superior 2px. Avatar 34×34 quadrado (fundo
  accent-200, iniciais accent-800/800) + nome (13/600) + tag do papel + ícone
  `log-out`.

### Topbar (altura 64px, borda inferior 2px `divider`, padding 0×28)
- Título da tela (h4) à esquerda; subtítulo opcional (12px muted).
- Ações contextuais à direita (ex.: botão primário "Abrir Chamado", seletor de
  período no dashboard), ícone `bell`, e/ou avatar mini.
- Botão `arrow-left` (voltar) à esquerda em telas de detalhe/formulário.

## Mobile

- **App bar** no topo (título h4 + ação primária como `btn-icon` à direita;
  `arrow-left` em telas de detalhe). Borda inferior 2px.
- **Bottom navigation** (borda superior 2px, fundo `surface`), 4 itens
  ícone+label (9.5px): **Dashboard**, **Chamados**, **Cadastros**, **Mais**.
  Item ativo em `accent` (navy); inativos em neutral-600.
- Sidebar **não** aparece no mobile; o menu de Cadastros/Análise vira a aba
  "Cadastros"/"Mais".

## Papéis (visibilidade)

Mockups mostram a **visão ADMIN** (acesso total). Ajustar por papel:
- `SOLICITANTE`: vê `Dashboard` (próprios), `Chamados` (Meus Chamados), abertura
  de chamado, Meu Perfil. **Sem** grupo Cadastros/Usuários/Configurações.
- `ATENDENTE`: acima + fila de atendimento, registro de andamento, Cadastros
  operacionais (Tipos, Equipamentos, Serviços).
- `ADMIN`: tudo, incluindo Usuários, Setores e Configurações.

Aplicar via guarda de rota (rotina 01) — ocultar itens não permitidos, não só
bloquear a rota.

## Mapeamento Flutter

- `LayoutBuilder`/`MediaQuery` para alternar `NavigationRail`/Drawer fixo (web) e
  `NavigationBar` (mobile) — Material 3.
- Item ativo: fundo navy chapado (`indicatorShape: RoundedRectangleBorder(zero)`).
- Estado de navegação via Riverpod + `go_router` (shell route).
