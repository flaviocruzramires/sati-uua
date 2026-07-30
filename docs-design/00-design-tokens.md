# 00 — Design Tokens

Todos os valores visuais do app saem daqui. Fonte canônica no design system:
`_ds/modernist-.../styles.css` (bloco `:root`). Abaixo, os mesmos tokens já
mapeados para Flutter (`ThemeData` / `ColorScheme`).

> Regra: **nenhuma cor/tamanho/fonte "hardcoded" fora do tema**. Se um valor não
> existe aqui, ele não deve aparecer na UI.

## 1. Paleta (derivada do logo `imagens/logo_sati_uua.jpg`)

Marca bicolor: **navy UEMS** (ação primária, navegação, links) + **verde campus**
(secundário / status positivo). Cada papel tem rampa 100–900.

### Accent — Navy (primária)
| Token | Hex |
|---|---|
| accent (base UI) | `#1C3F6E` |
| accent-100 | `#EAF0F8` |
| accent-200 | `#CBDAEC` |
| accent-300 | `#9EBAD9` |
| accent-400 | `#6089B8` |
| accent-500 | `#2C5085` |
| accent-600 (hover) | `#1C3F6E` |
| accent-700 (pressed / texto sobre tint) | `#142E52` |
| accent-800 | `#0D2038` |
| accent-900 | `#081526` |

### Accent-2 — Verde (secundária / status positivo)
| Token | Hex |
|---|---|
| accent-2 (base) | `#3E7A34` |
| accent-2-100 | `#EAF3E7` |
| accent-2-200 | `#CDE3C6` |
| accent-2-300 | `#A3CC98` |
| accent-2-400 | `#6FAD5F` |
| accent-2-500 | `#4E8F42` |
| accent-2-600 | `#3E7A34` |
| accent-2-700 | `#2F5F28` |
| accent-2-800 | `#23481E` |
| accent-2-900 | `#17300F` |

### Neutros / superfícies
| Token | Hex | Uso |
|---|---|---|
| bg | `#F4F5F7` | fundo da página / `Scaffold` |
| surface | `#E9EBEF` | cards, inputs, sidebar |
| text | `#1B1E24` | texto principal |
| divider | `#1B1E24` @ 40% | réguas 2px, bordas |
| neutral-100 | `#F5F6F8` | tint claro |
| neutral-200 | `#E7E9ED` | trilha de barra / fundo canvas |
| neutral-300 | `#D3D7DE` | borda sutil |
| neutral-400 | `#B3B9C4` | — |
| neutral-500 | `#8B93A3` | ícone/texto desabilitado |
| neutral-600 | `#6B7385` | texto secundário/meta |
| neutral-700 | `#4F5563` | rótulos, texto muted forte |
| neutral-800 | `#383C46` | — |
| neutral-900 | `#23262D` | — |

### Cores de status do chamado (situação)
Não inventar novas cores — usar os papéis acima via os componentes `tag`:
| Situação | Tag | Cor |
|---|---|---|
| `ABERTO` | `tag-accent` | fundo accent-100, texto accent-800 |
| `EM_ANDAMENTO` | `tag-accent-2` | fundo accent-2-100, texto accent-2-800 |
| `AGUARDANDO_SOLICITANTE` | `tag-outline` | borda accent, texto accent |
| `ENCERRADO` | `tag-neutral` | fundo neutral-100, texto neutral-800 |
Status de cadastro: **Ativo** = `tag-accent-2`; **Inativo** = `tag-neutral`/`tag-outline`.
Papel: **ADMIN** = `tag-accent`; **ATENDENTE** = `tag-accent-2`; **SOLICITANTE** = `tag-neutral`.

## 2. Tipografia

- Família única: **Archivo** (headings 800, body 400). Adicionar `google_fonts`
  ou fonte empacotada em `pubspec.yaml`.
- Escala (line-height headings ~1.12, letter-spacing -0.015em; body 15px/1.55):
| Papel | Tamanho / peso |
|---|---|
| h1 | 42 / 800 |
| h2 | 32 / 800 |
| h3 | 25 / 800 |
| h4 | 20 / 800 |
| h5 | 16 / 800 |
| h6 (kicker) | 13 / 800, UPPERCASE, tracking 0.08em |
| body | 15 / 400 |
| label de campo | 12 / 400, neutral-700 |
| meta/caption | 11–12 / 400, neutral-600 |

## 3. Espaçamento, raio, elevação

- Spacing (px): 4 / 8 / 12 / 16 / 24 / 32 (`space-1..8`).
- **Raio: 0 em tudo** (`--radius-*: 0`). Nada de `BorderRadius` arredondado.
- Réguas/bordas de seção: **2px** sólidas em `divider`. Bordas de linha de tabela: 1px.
- Elevação (sombras suaves tintadas de tinta):
  - sm: `0 1px 2px rgba(35,38,45,.14)`
  - md: `0 3px 10px rgba(35,38,45,.16)`
  - lg: `0 12px 32px rgba(35,38,45,.22)`

## 4. Ícones

**Lucide** (https://lucide.dev). No Flutter usar `lucide_icons` (ou equivalente).
Ícones usados nas telas: `layout-grid` (dashboard), `ticket` (chamados),
`building-2` (setores), `layers` (tipos de equipamento), `monitor` (equipamentos),
`sliders-horizontal` (serviços), `users` (usuários), `bar-chart-2` (relatórios),
`settings` (configurações), `log-out`, `search`, `plus`, `pencil` (editar),
`trash-2` (excluir), `chevron-left`/`chevron-right` (paginação), `bell`,
`arrow-left` (voltar), `menu`. Traço 2px, cantos arredondados no traço apenas.

## 5. Mapeamento Flutter (referência)

```dart
// core/theme/app_colors.dart
class AppColors {
  static const navy      = Color(0xFF1C3F6E); // accent
  static const navyHover = Color(0xFF142E52); // accent-700
  static const green     = Color(0xFF3E7A34); // accent-2
  static const bg        = Color(0xFFF4F5F7);
  static const surface   = Color(0xFFE9EBEF);
  static const text      = Color(0xFF1B1E24);
  static const divider   = Color(0x661B1E24); // 40%
  static const muted     = Color(0xFF6B7385); // neutral-600
  static const label     = Color(0xFF4F5563); // neutral-700
  // ...demais steps das rampas conforme tabelas acima
}

// core/theme/app_theme.dart — pontos-chave
ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.green,
    surface: AppColors.surface,
    background: AppColors.bg,
  ),
  fontFamily: 'Archivo',
  // raio 0 em botões/inputs/cards:
  cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
    filled: true, fillColor: AppColors.surface,
  ),
  elevatedButtonTheme: /* fundo navy, texto bg, raio 0, label à esquerda */,
  dividerColor: AppColors.divider, // usar espessura 2px nas seções
)
```

> Botões: **rótulo alinhado à esquerda** (não centralizado) quando o botão é mais
> largo que o texto — característica do Modernist.
