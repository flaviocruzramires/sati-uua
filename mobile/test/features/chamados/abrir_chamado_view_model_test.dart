import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/combo_item.dart';
import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/chamados/chamado_repository.dart';
import 'package:chamados/features/chamados/view_model/abrir_chamado_view_model.dart';
import 'package:chamados/features/equipamentos/equipamento_repository.dart';
import 'package:chamados/features/servicos/servico_repository.dart';

class MockChamadoRepo extends Mock implements ChamadoRepositoryBase {}

class MockEquipamentoRepo extends Mock implements EquipamentoRepositoryBase {}

class MockServicoRepo extends Mock implements ServicoRepositoryBase {}

final kChamado = ChamadoDto(
  id: 1,
  descricao: 'Computador não liga',
  solicitanteId: 1,
  solicitanteNome: 'Ana',
  situacao: SituacaoChamado.aberto,
  dataAbertura: DateTime.utc(2026, 7, 30),
);

void main() {
  late MockChamadoRepo repo;
  late MockEquipamentoRepo equipRepo;
  late MockServicoRepo servicoRepo;

  setUp(() {
    repo = MockChamadoRepo();
    equipRepo = MockEquipamentoRepo();
    servicoRepo = MockServicoRepo();

    when(() => equipRepo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          tipoEquipamentoId: any(named: 'tipoEquipamentoId'),
        )).thenAnswer((_) async => PaginatedResult(
          data: const [],
          total: 0,
          page: 1,
          pageSize: 200,
        ));

    when(() => servicoRepo.list(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          busca: any(named: 'busca'),
        )).thenAnswer((_) async => PaginatedResult(
          data: const [],
          total: 0,
          page: 1,
          pageSize: 200,
        ));
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          chamadoRepositoryProvider.overrideWithValue(repo),
          equipamentoRepositoryProvider.overrideWithValue(equipRepo),
          servicoRepositoryProvider.overrideWithValue(servicoRepo),
        ],
      );

  test('init carrega combos de equipamentos e serviços', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(abrirChamadoViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    expect(
      c.read(abrirChamadoViewModelProvider).equipamentosCombo,
      isA<AsyncData<List<ComboItem<int?>>>>(),
    );
  });

  test('abrir retorna true e guarda chamadoCriadoId', () async {
    when(() => repo.create(
          descricao: any(named: 'descricao'),
          equipamentoId: any(named: 'equipamentoId'),
          servicoId: any(named: 'servicoId'),
        )).thenAnswer((_) async => kChamado);

    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(abrirChamadoViewModelProvider.notifier)
        .abrir(descricao: 'Computador não liga');
    expect(ok, isTrue);
    expect(c.read(abrirChamadoViewModelProvider).chamadoCriadoId, 1);
  });

  test('abrir retorna false em erro e salva saveError', () async {
    when(() => repo.create(
          descricao: any(named: 'descricao'),
          equipamentoId: any(named: 'equipamentoId'),
          servicoId: any(named: 'servicoId'),
        )).thenThrow(Exception('500'));

    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(abrirChamadoViewModelProvider.notifier)
        .abrir(descricao: 'Teste');
    expect(ok, isFalse);
    expect(c.read(abrirChamadoViewModelProvider).saveError, isNotNull);
  });
}
