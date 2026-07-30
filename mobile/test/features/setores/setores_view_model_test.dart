import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/setores/setor_repository.dart';
import 'package:chamados/features/setores/view_model/setores_view_model.dart';

class _MockSetorRepository extends Mock implements SetorRepositoryBase {}

final _emptyResult = PaginatedResult<SetorDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

final _oneResult = PaginatedResult<SetorDto>(
  data: const [SetorDto(id: 1, nome: 'TI')],
  total: 1,
  page: 1,
  pageSize: 20,
);

void main() {
  late _MockSetorRepository repo;

  setUp(() {
    repo = _MockSetorRepository();
    when(() => repo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          busca: any(named: 'busca'),
        )).thenAnswer((_) async => _emptyResult);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [setorRepositoryProvider.overrideWithValue(repo)],
      );

  test('load popula listState com AsyncData', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(setoresViewModelProvider.notifier);
    await vm.load();
    final state = c.read(setoresViewModelProvider);
    expect(state.listState, isA<AsyncData<PaginatedResult<SetorDto>>>());
    expect(state.listState.value?.total, 0);
  });

  test('create retorna true e recarrega lista', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    when(() => repo.create('TI'))
        .thenAnswer((_) async => const SetorDto(id: 1, nome: 'TI'));
    when(() => repo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          busca: any(named: 'busca'),
        )).thenAnswer((_) async => _oneResult);

    final vm = c.read(setoresViewModelProvider.notifier);
    final ok = await vm.create('TI');

    expect(ok, isTrue);
    expect(c.read(setoresViewModelProvider).listState.value?.total, 1);
  });

  test('create retorna false em erro e guarda saveError', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(setoresViewModelProvider.notifier);
    await vm.load();

    when(() => repo.create(any())).thenThrow(Exception('Conflict'));
    final ok = await vm.create('TI');

    expect(ok, isFalse);
    expect(c.read(setoresViewModelProvider).saveError, isNotNull);
    expect(
      c.read(setoresViewModelProvider).listState,
      isA<AsyncData<PaginatedResult<SetorDto>>>(),
    );
  });

  test('delete retorna true e chama repo.delete', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    when(() => repo.delete(1)).thenAnswer((_) async {});

    final vm = c.read(setoresViewModelProvider.notifier);
    final ok = await vm.delete(1);

    expect(ok, isTrue);
    verify(() => repo.delete(1)).called(1);
  });

  test('setBusca reinicia página e recarrega', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(setoresViewModelProvider.notifier);
    await vm.load();
    vm.setPage(3);
    vm.setBusca('abc');
    await vm.load();

    expect(c.read(setoresViewModelProvider).busca, 'abc');
    expect(c.read(setoresViewModelProvider).page, 1);
  });
}
