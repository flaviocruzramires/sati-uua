import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/chamados/chamado_detalhe_dto.dart';
import 'package:chamados/features/chamados/chamado_dto.dart';
import 'package:chamados/features/chamados/chamado_repository.dart';
import 'package:chamados/features/chamados/view_model/chamado_detalhe_view_model.dart';

class MockChamadoRepo extends Mock implements ChamadoRepositoryBase {}

final _kChamado = ChamadoDto(
  id: 1,
  descricao: 'Impressora não funciona',
  solicitanteId: 2,
  solicitanteNome: 'Maria',
  situacao: SituacaoChamado.aberto,
  dataAbertura: DateTime.utc(2026, 7, 30),
);

final _kDetalhe = ChamadoDetalheDto(
  chamado: _kChamado,
  historico: const [],
);

final _kDetalheEncerrado = ChamadoDetalheDto(
  chamado: ChamadoDto(
    id: 1,
    descricao: 'Impressora não funciona',
    solicitanteId: 2,
    solicitanteNome: 'Maria',
    responsavelId: 3,
    responsavelNome: 'Carlos',
    situacao: SituacaoChamado.encerrado,
    dataAbertura: DateTime.utc(2026, 7, 30),
    dataFechamento: DateTime.utc(2026, 7, 30, 14),
  ),
  historico: const [],
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
        )).thenAnswer((_) async =>
        PaginatedResult(data: const [], total: 0, page: 1, pageSize: 20));
    when(() => repo.findDetalhe(any()))
        .thenAnswer((_) async => _kDetalhe);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [chamadoRepositoryProvider.overrideWithValue(repo)],
      );

  test('load popula detalheState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(chamadoDetalheViewModelProvider(1).notifier)
        .load(1);
    expect(
      c.read(chamadoDetalheViewModelProvider(1)).detalheState,
      isA<AsyncData<ChamadoDetalheDto>>(),
    );
  });

  test('registrarAtendimento retorna true e atualiza detalhe', () async {
    when(() => repo.registrarHistorico(
          chamadoId: any(named: 'chamadoId'),
          descricao: any(named: 'descricao'),
          dataRetorno: any(named: 'dataRetorno'),
          marcaEncerramento: any(named: 'marcaEncerramento'),
        )).thenAnswer((_) async => _kDetalheEncerrado);

    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(chamadoDetalheViewModelProvider(1).notifier).load(1);

    final ok = await c
        .read(chamadoDetalheViewModelProvider(1).notifier)
        .registrarAtendimento(
          chamadoId: 1,
          descricao: 'Resolvido',
          dataRetorno: DateTime.utc(2026, 7, 30, 14),
          marcaEncerramento: true,
        );
    expect(ok, isTrue);
    final state = c.read(chamadoDetalheViewModelProvider(1));
    expect(
      state.detalheState.valueOrNull?.chamado.situacao,
      SituacaoChamado.encerrado,
    );
  });

  test('registrarAtendimento retorna false em erro e salva saveError',
      () async {
    when(() => repo.registrarHistorico(
          chamadoId: any(named: 'chamadoId'),
          descricao: any(named: 'descricao'),
          dataRetorno: any(named: 'dataRetorno'),
          marcaEncerramento: any(named: 'marcaEncerramento'),
        )).thenThrow(Exception('400 Chamado sem atendente'));

    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(chamadoDetalheViewModelProvider(1).notifier).load(1);

    final ok = await c
        .read(chamadoDetalheViewModelProvider(1).notifier)
        .registrarAtendimento(
          chamadoId: 1,
          descricao: 'Teste',
          dataRetorno: DateTime.utc(2026, 7, 30),
          marcaEncerramento: false,
        );
    expect(ok, isFalse);
    expect(
        c.read(chamadoDetalheViewModelProvider(1)).saveError, isNotNull);
  });
}
