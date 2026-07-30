import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/features/configuracoes/configuracao_repository.dart';
import 'package:chamados/features/configuracoes/view_model/configuracoes_view_model.dart';

class _MockConfiguracaoRepository extends Mock
    implements ConfiguracaoRepositoryBase {}

final _kConfig = ConfiguracaoDto(
  chave: 'LOG_LEVEL',
  valor: 'INFO',
  descricao: 'Nível de log do servidor',
  tipo: 'string',
  atualizadoEm: DateTime.utc(2025, 1, 1),
);

void main() {
  late _MockConfiguracaoRepository repo;

  setUp(() {
    repo = _MockConfiguracaoRepository();
    when(() => repo.list()).thenAnswer((_) async => [_kConfig]);
    when(
      () => repo.update(any(), any()),
    ).thenAnswer((_) async => _kConfig.copyWith(valor: 'DEBUG'));
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [configuracaoRepositoryProvider.overrideWithValue(repo)],
  );

  test('load popula listState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(configuracoesViewModelProvider.notifier).load();
    final state = c.read(configuracoesViewModelProvider);
    expect(state.listState, isA<AsyncData<List<ConfiguracaoDto>>>());
    expect(state.listState.valueOrNull?.length, 1);
  });

  test('load com erro popula AsyncError', () async {
    when(() => repo.list()).thenThrow(Exception('network'));
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(configuracoesViewModelProvider.notifier).load();
    expect(
      c.read(configuracoesViewModelProvider).listState,
      isA<AsyncError<List<ConfiguracaoDto>>>(),
    );
  });

  test('save retorna true e atualiza lista', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(configuracoesViewModelProvider.notifier);
    await vm.load();
    final ok = await vm.save('LOG_LEVEL', 'DEBUG');
    expect(ok, isTrue);
    final configs = c
        .read(configuracoesViewModelProvider)
        .listState
        .valueOrNull;
    expect(configs?.first.valor, 'DEBUG');
  });

  test('save retorna false em erro e salva saveError', () async {
    when(() => repo.update(any(), any())).thenThrow(Exception('server error'));
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(configuracoesViewModelProvider.notifier);
    await vm.load();
    final ok = await vm.save('LOG_LEVEL', 'DEBUG');
    expect(ok, isFalse);
    expect(c.read(configuracoesViewModelProvider).saveError, isNotNull);
  });
}
