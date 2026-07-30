import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/chamados/chamado_repository.dart';
import 'package:chamados/features/chamados/view_model/chamados_list_view_model.dart';

class MockChamadoRepo extends Mock implements ChamadoRepositoryBase {}

final _empty = PaginatedResult<ChamadoDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

void main() {
  late MockChamadoRepo repo;

  setUpAll(() {
    registerFallbackValue(SituacaoChamado.aberto);
  });

  setUp(() {
    repo = MockChamadoRepo();
    when(() => repo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          situacao: any(named: 'situacao'),
          solicitanteId: any(named: 'solicitanteId'),
          responsavelId: any(named: 'responsavelId'),
        )).thenAnswer((_) async => _empty);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [chamadoRepositoryProvider.overrideWithValue(repo)],
      );

  test('load popula listState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(chamadosListViewModelProvider.notifier).load();
    expect(
      c.read(chamadosListViewModelProvider).listState,
      isA<AsyncData<PaginatedResult<ChamadoDto>>>(),
    );
  });

  test('setFiltroSituacao aplica filtro e reinicia página', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(chamadosListViewModelProvider.notifier);
    await vm.load();
    vm.setFiltroSituacao(SituacaoChamado.aberto);
    await vm.load();
    expect(
      c.read(chamadosListViewModelProvider).filtroSituacao,
      SituacaoChamado.aberto,
    );
    expect(c.read(chamadosListViewModelProvider).page, 1);
  });

  test('setFiltroSituacao com null limpa filtro', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(chamadosListViewModelProvider.notifier);
    await vm.load();
    vm.setFiltroSituacao(SituacaoChamado.aberto);
    vm.setFiltroSituacao(null);
    expect(c.read(chamadosListViewModelProvider).filtroSituacao, isNull);
  });

  test('setPage muda página e recarrega', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(chamadosListViewModelProvider.notifier);
    await vm.load();
    vm.setPage(3);
    expect(c.read(chamadosListViewModelProvider).page, 3);
  });
}
