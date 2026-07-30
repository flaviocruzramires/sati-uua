import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/features/relatorios/relatorio_repository.dart';
import 'package:chamados/features/relatorios/view_model/relatorio_view_model.dart';
import 'package:chamados/core/domain/enums.dart';

class _MockRelatorioRepository extends Mock
    implements RelatorioRepositoryBase {}

RelatorioResultDto _fakeResult({int total = 0}) => RelatorioResultDto(
  data: const [],
  total: total,
  page: 1,
  pageSize: 20,
  resumo: const RelatorioResumoDto(
    total: 0,
    abertos: 0,
    emAndamento: 0,
    aguardandoSolicitante: 0,
    encerrados: 0,
    tempoMedioMinutos: 0,
  ),
);

void main() {
  late _MockRelatorioRepository repo;

  setUpAll(() {
    registerFallbackValue(SituacaoChamado.aberto);
  });

  setUp(() {
    repo = _MockRelatorioRepository();
    when(
      () => repo.chamados(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        situacao: any(named: 'situacao'),
        aberturaDe: any(named: 'aberturaDe'),
        aberturaAte: any(named: 'aberturaAte'),
        fechamentoDe: any(named: 'fechamentoDe'),
        fechamentoAte: any(named: 'fechamentoAte'),
      ),
    ).thenAnswer((_) async => _fakeResult());
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [relatorioRepositoryProvider.overrideWithValue(repo)],
    );
  }

  test('buscar emite data', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(relatorioViewModelProvider.notifier).buscar();
    expect(
      c.read(relatorioViewModelProvider).resultState,
      isA<AsyncData<RelatorioResultDto>>(),
    );
  });

  test('aplicarFiltros atualiza filtros e busca', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(relatorioViewModelProvider.notifier);
    await vm.buscar();
    vm.aplicarFiltros(
      const RelatorioFiltros(situacao: SituacaoChamado.encerrado),
    );
    await Future.microtask(() {});
    final state = c.read(relatorioViewModelProvider);
    expect(state.filtros.situacao, SituacaoChamado.encerrado);
    expect(state.page, 1);
  });

  test('limparFiltros reseta filtros', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(relatorioViewModelProvider.notifier);
    await vm.buscar();
    vm.aplicarFiltros(const RelatorioFiltros(situacao: SituacaoChamado.aberto));
    await Future.microtask(() {});
    vm.limparFiltros();
    await Future.microtask(() {});
    final state = c.read(relatorioViewModelProvider);
    expect(state.filtros.hasAnyFilter, isFalse);
  });

  test('setPage avança página', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(relatorioViewModelProvider.notifier);
    await vm.buscar();
    vm.setPage(3);
    await Future.microtask(() {});
    expect(c.read(relatorioViewModelProvider).page, 3);
  });

  test('hasAnyFilter retorna verdadeiro com filtro ativo', () {
    const filtros = RelatorioFiltros(situacao: SituacaoChamado.emAndamento);
    expect(filtros.hasAnyFilter, isTrue);
  });
}
