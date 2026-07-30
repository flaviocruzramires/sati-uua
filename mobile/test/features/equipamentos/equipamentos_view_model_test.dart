import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/combo_item.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/equipamentos/equipamento_repository.dart';
import 'package:chamados/features/equipamentos/view_model/equipamentos_view_model.dart';
import 'package:chamados/features/tipos_equipamento/tipo_equipamento_repository.dart';

class MockEquipRepo extends Mock implements EquipamentoRepositoryBase {}

class MockTipoRepo extends Mock implements TipoEquipamentoRepositoryBase {}

final emptyResult = PaginatedResult<EquipamentoDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

const kEq = EquipamentoDto(
  id: 1,
  descricao: 'Notebook Dell',
  tipoEquipamentoId: 1,
  tipoEquipamentoNome: 'Notebook',
  ativo: true,
);

void main() {
  late MockEquipRepo eqRepo;
  late MockTipoRepo tipoRepo;

  setUp(() {
    eqRepo = MockEquipRepo();
    tipoRepo = MockTipoRepo();
    when(
      () => eqRepo.list(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        tipoEquipamentoId: any(named: 'tipoEquipamentoId'),
      ),
    ).thenAnswer((_) async => emptyResult);
    when(
      () => tipoRepo.combo(),
    ).thenAnswer((_) async => [const ComboItem<int>(1, 'Notebook')]);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      equipamentoRepositoryProvider.overrideWithValue(eqRepo),
      tipoEquipamentoRepositoryProvider.overrideWithValue(tipoRepo),
    ],
  );

  test('init carrega lista e combo de tipos', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(equipamentosViewModelProvider.notifier);
    await vm.load();
    final state = c.read(equipamentosViewModelProvider);
    expect(state.listState, isA<AsyncData<PaginatedResult<EquipamentoDto>>>());
  });

  test('create retorna true', () async {
    when(
      () => eqRepo.create(
        descricao: any(named: 'descricao'),
        tipoEquipamentoId: any(named: 'tipoEquipamentoId'),
        setorId: any(named: 'setorId'),
      ),
    ).thenAnswer((_) async => kEq);
    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(equipamentosViewModelProvider.notifier)
        .create(descricao: 'Notebook Dell', tipoEquipamentoId: 1);
    expect(ok, isTrue);
  });

  test('update retorna true', () async {
    when(
      () => eqRepo.update(
        id: any(named: 'id'),
        descricao: any(named: 'descricao'),
        tipoEquipamentoId: any(named: 'tipoEquipamentoId'),
        setorId: any(named: 'setorId'),
        ativo: any(named: 'ativo'),
      ),
    ).thenAnswer((_) async => kEq);
    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(equipamentosViewModelProvider.notifier)
        .update(
          id: 1,
          descricao: 'Notebook Dell',
          tipoEquipamentoId: 1,
          ativo: true,
        );
    expect(ok, isTrue);
  });

  test('delete retorna true', () async {
    when(() => eqRepo.delete(1)).thenAnswer((_) async {});
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(equipamentosViewModelProvider.notifier);
    await vm.load();
    final ok = await vm.delete(1);
    expect(ok, isTrue);
    verify(() => eqRepo.delete(1)).called(1);
  });

  test('setFiltroTipo filtra e recarrega', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(equipamentosViewModelProvider.notifier);
    await vm.load();
    vm.setFiltroTipo(1);
    await vm.load();
    expect(c.read(equipamentosViewModelProvider).filtroTipoId, 1);
  });
}
