import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/combo_item.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/tipos_equipamento/tipo_equipamento_repository.dart';
import 'package:chamados/features/tipos_equipamento/view_model/tipos_equipamento_view_model.dart';

class MockTipoRepo extends Mock implements TipoEquipamentoRepositoryBase {}

final emptyResult = PaginatedResult<TipoEquipamentoDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

void main() {
  late MockTipoRepo repo;

  setUp(() {
    repo = MockTipoRepo();
    when(() => repo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          busca: any(named: 'busca'),
        )).thenAnswer((_) async => emptyResult);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [tipoEquipamentoRepositoryProvider.overrideWithValue(repo)],
      );

  test('load popula listState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(tiposEquipamentoViewModelProvider.notifier).load();
    expect(
      c.read(tiposEquipamentoViewModelProvider).listState,
      isA<AsyncData<PaginatedResult<TipoEquipamentoDto>>>(),
    );
  });

  test('combo retorna lista de ComboItem', () async {
    when(() => repo.combo()).thenAnswer((_) async => [
          const ComboItem<int>(1, 'Notebook'),
        ]);
    final c = makeContainer();
    addTearDown(c.dispose);
    final items = await c.read(tipoEquipamentoRepositoryProvider).combo();
    expect(items.length, 1);
    expect(items.first.label, 'Notebook');
  });

  test('create retorna true', () async {
    when(() => repo.create('Notebook')).thenAnswer(
        (_) async => const TipoEquipamentoDto(id: 1, nome: 'Notebook'));
    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(tiposEquipamentoViewModelProvider.notifier)
        .create('Notebook');
    expect(ok, isTrue);
  });

  test('delete com erro salva saveError', () async {
    when(() => repo.delete(1)).thenThrow(Exception('FK'));
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(tiposEquipamentoViewModelProvider.notifier);
    await vm.load();
    final ok = await vm.delete(1);
    expect(ok, isFalse);
    expect(c.read(tiposEquipamentoViewModelProvider).saveError, isNotNull);
  });
}
