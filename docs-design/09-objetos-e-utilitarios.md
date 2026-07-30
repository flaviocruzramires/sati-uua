# 09 — Objetos e Utilitários Reutilizáveis (não visuais)

Complementa `08-catalogo-componentes.md`: aqui ficam os **modelos e
utilitários** que várias telas/ViewModels compartilham — não são widgets,
mas evitam duplicar a mesma classe/lógica em cada `feature/`.

Local sugerido: `mobile/lib/core/domain/`, `mobile/lib/core/validators/`,
`mobile/lib/core/formatters/`, `mobile/lib/core/network/`.

## 1. Modelos genéricos

### `ComboItem<T>`
```dart
class ComboItem<T> {
  final T id;
  final String label;
  const ComboItem(this.id, this.label);
}
```
Usado por **todo** `AppSelect<T>` (Setor, Tipo de Equipamento, Equipamento,
Serviço, Atendente, Papel). Cada `Repository` expõe um método
`Future<List<ComboItem<int>>> comboOptions()` além do CRUD completo, para não
buscar/desserializar colunas a mais do que o necessário (alinhado à regra de
nunca usar `SELECT *` no servidor — o endpoint "enxuto" citado em
`rotinas/03-cadastro-usuarios.md` para o combo de atendente é o mesmo
padrão).

### `PaginatedResult<T>`
```dart
class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int page;
  final int pageSize;
  const PaginatedResult({required this.data, required this.total, required this.page, required this.pageSize});
}
```
Retorno padrão de **toda** chamada de listagem (`GET /setores`, `GET
/usuarios`, `GET /chamados`, `GET /relatorios/chamados`, ...). Consumido por
`PaginationBar` (calcula "Mostrando X–Y de N") e pelos `AsyncNotifier` de
cada listagem.

### Enums de domínio compartilhados
`SituacaoChamado` e o mapeamento de cores (`StatusColors.situacao`) **já
existem** em `docs-design/app_theme.dart` — mover tal qual para
`core/domain/enums.dart` em vez de recriar. Adicionar ao mesmo arquivo:
```dart
enum PapelUsuario { solicitante, atendente, admin }
enum StatusAtivo { ativo, inativo }
```
com os mapeamentos de tag descritos em `00-design-tokens.md` (ADMIN=accent,
ATENDENTE=accent-2, SOLICITANTE=neutral; Ativo=accent-2, Inativo=neutral).

## 2. Filtros por tela (um objeto por listagem, não um genérico só)

Cada listagem tem um filtro próprio (evita um "filtro genérico" frágil):
```dart
class ChamadoFiltro {
  final SituacaoChamado? situacao;
  final int? solicitanteId;
  final int? atendenteId;
  final DateTime? aberturaDe, aberturaAte;
  final DateTime? fechamentoDe, fechamentoAte;
  final String? busca;
  const ChamadoFiltro({...});
  ChamadoFiltro copyWith({...});
}
```
Análogo para `EquipamentoFiltro` (tipoEquipamentoId, busca),
`UsuarioFiltro` (papel, busca). Vivem junto ao `ViewModel` da respectiva
feature (`features/chamados/view_model/chamado_filtro.dart`), não em
`core/`, pois são específicos de cada tela — só o **padrão** (imutável,
`copyWith`, alimenta `FilterBar`) é compartilhado.

## 3. Validadores (client-side; servidor é sempre a fonte da verdade)

```dart
class Validators {
  static String? obrigatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;
  static String? email(String? v) => ...; // formato básico
  static String? senhaMinima(String? v, {int min = 8}) => ...;
}
```
Usados nos `TextFormField`/`AppTextField` de Login (rotina 01), Usuários
(rotina 03) e qualquer campo obrigatório das rotinas 02/04/05/06/07.
Conflitos de unicidade (email/login duplicado, nome de setor duplicado)
**não** são validados aqui — vêm do erro `409` do servidor e são exibidos via
`errorText` do campo (ver `08-catalogo-componentes.md`, `AppTextField`).

## 4. Formatadores

- `dataPtBr(DateTime)` / `dataHoraPtBr(DateTime)` — via `intl`, usado em
  toda exibição de `data_abertura`, `data_fechamento`, `data_retorno`.
- `paginacaoLabel(page, pageSize, total)` → `"Mostrando 1–8 de 193"` — usado
  por `PaginationBar` em todas as listagens.
- `tempoResolucao(Duration)` → `"6h40"` — usado no Dashboard (KPI "Tempo
  médio de resolução") e na tabela "Por Atendente".

## 5. Tratamento de erro de API (interceptor + wrapper)

- `AppException {codigo, mensagem}` — mapeia o formato padronizado do
  servidor (`{"error":{"code":...,"message":...}}`, ver skill
  `dart-shelf-server`) para um objeto único usado em todo `catch` de
  ViewModel.
- Interceptor do `dio` (`core/network/dio_client.dart`): injeta o token JWT
  em toda requisição e trata `401` globalmente (desloga e redireciona ao
  login) — descrito também em `claude-config/rotinas/01-autenticacao.md`.

## 6. Padrão de estado assíncrono (`AsyncStateView`)

Wrapper usado por **toda** tela que consome `AsyncNotifier`:
```dart
class AsyncStateView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget Function()? empty; // opcional: quando data é uma lista vazia
  // usa LoadingSkeleton / ErrorState / EmptyState do catálogo (08)
}
```
Isso garante que loading/erro/vazio tenham a mesma aparência em todas as
telas, em vez de cada `ViewModel`/`View` decidir isoladamente — mesmo
espírito do "visual clean" do `HARNESS.md`.
