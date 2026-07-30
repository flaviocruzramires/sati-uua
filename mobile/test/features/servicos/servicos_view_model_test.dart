import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/servicos/servico_repository.dart';
import 'package:chamados/features/servicos/view_model/servicos_view_model.dart';

class _MockServicoRepository extends Mock implements ServicoRepositoryBase {}

final _emptyResult = PaginatedResult<ServicoDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

final _oneResult = PaginatedResult<ServicoDto>(
  data: const [ServicoDto(id: 1, descricao: 'Suporte')],
  total: 1,
  page: 1,
  pageSize: 20,
);

void main() {
  late _MockServicoRepository repo;

  setUp(() {
    repo = _MockServicoRepository();
    when(
      () => repo.list(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        busca: any(named: 'busca'),
      ),
    ).thenAnswer((_) async => _emptyResult);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [servicoRepositoryProvider.overrideWithValue(repo)],
  );

  test('load popula listState com AsyncData', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(servicosViewModelProvider.notifier);
    await vm.load();
    final state = c.read(servicosViewModelProvider);
    expect(state.listState, isA<AsyncData<PaginatedResult<ServicoDto>>>());
    expect(state.listState.value?.total, 0);
  });

  test('create retorna true e recarrega lista', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    when(
      () => repo.create('Suporte'),
    ).thenAnswer((_) async => const ServicoDto(id: 1, descricao: 'Suporte'));
    when(
      () => repo.list(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        busca: any(named: 'busca'),
      ),
    ).thenAnswer((_) async => _oneResult);

    final vm = c.read(servicosViewModelProvider.notifier);
    final ok = await vm.create('Suporte');

    expect(ok, isTrue);
    expect(c.read(servicosViewModelProvider).listState.value?.total, 1);
  });

  test('create retorna false em erro e guarda saveError', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(servicosViewModelProvider.notifier);
    await vm.load();

    when(() => repo.create(any())).thenThrow(Exception('Erro'));
    final ok = await vm.create('X');

    expect(ok, isFalse);
    expect(c.read(servicosViewModelProvider).saveError, isNotNull);
    expect(
      c.read(servicosViewModelProvider).listState,
      isA<AsyncData<PaginatedResult<ServicoDto>>>(),
    );
  });

  test('delete retorna true e chama repo.delete', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    when(() => repo.delete(1)).thenAnswer((_) async {});

    final vm = c.read(servicosViewModelProvider.notifier);
    final ok = await vm.delete(1);

    expect(ok, isTrue);
    verify(() => repo.delete(1)).called(1);
  });

  test('update retorna true e recarrega lista', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    when(
      () => repo.update(1, 'Suporte v2'),
    ).thenAnswer((_) async => const ServicoDto(id: 1, descricao: 'Suporte v2'));

    final vm = c.read(servicosViewModelProvider.notifier);
    final ok = await vm.update(1, 'Suporte v2');

    expect(ok, isTrue);
    verify(() => repo.update(1, 'Suporte v2')).called(1);
  });
}
