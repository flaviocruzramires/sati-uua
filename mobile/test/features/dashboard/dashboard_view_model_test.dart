import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/features/dashboard/dashboard_repository.dart';
import 'package:chamados/features/dashboard/view_model/dashboard_view_model.dart';

class MockDashboardRepo extends Mock implements DashboardRepositoryBase {}

final _kDashboard = DashboardDto(
  kpi: const KpiResumoDto(
    abertos: 5,
    emAndamento: 3,
    aguardandoSolicitante: 1,
    encerrados: 20,
    semAtendente: 2,
    tempoMedioMinutos: 400,
  ),
  porSituacao: const [],
  porSetor: const [],
  porTipoEquipamento: const [],
  porServico: const [],
  evolucaoMensal: const [],
  porAtendente: const [],
);

void main() {
  late MockDashboardRepo repo;

  setUp(() {
    repo = MockDashboardRepo();
    when(() => repo.resumo(any())).thenAnswer((_) async => _kDashboard);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
      );

  test('load popula resumoState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(dashboardViewModelProvider.notifier).load();
    expect(
      c.read(dashboardViewModelProvider).resumoState,
      isA<AsyncData<DashboardDto>>(),
    );
  });

  test('setPeriodo muda dias e recarrega', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(dashboardViewModelProvider.notifier);
    await vm.load();
    vm.setPeriodo(7);
    expect(c.read(dashboardViewModelProvider).dias, 7);
  });

  test('load com erro popula AsyncError', () async {
    when(() => repo.resumo(any())).thenThrow(Exception('500'));
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(dashboardViewModelProvider.notifier).load();
    expect(
      c.read(dashboardViewModelProvider).resumoState,
      isA<AsyncError<DashboardDto>>(),
    );
  });

  test('KpiResumoDto.tempoMedioFormatado formata corretamente', () {
    const kpi = KpiResumoDto(
      abertos: 0, emAndamento: 0, aguardandoSolicitante: 0,
      encerrados: 0, semAtendente: 0, tempoMedioMinutos: 400,
    );
    expect(kpi.tempoMedioFormatado, '6h40');
  });
}
