import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuracao_repository.dart';

class ConfiguracoesState {
  const ConfiguracoesState({
    this.listState = const AsyncValue.loading(),
    this.saveError,
    this.saving = false,
  });

  final AsyncValue<List<ConfiguracaoDto>> listState;
  final String? saveError;
  final bool saving;

  ConfiguracoesState copyWith({
    AsyncValue<List<ConfiguracaoDto>>? listState,
    String? saveError,
    bool clearSaveError = false,
    bool? saving,
  }) =>
      ConfiguracoesState(
        listState: listState ?? this.listState,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
        saving: saving ?? this.saving,
      );
}

class ConfiguracoesViewModel extends Notifier<ConfiguracoesState> {
  @override
  ConfiguracoesState build() {
    Future.microtask(load);
    return const ConfiguracoesState();
  }

  ConfiguracaoRepositoryBase get _repo =>
      ref.read(configuracaoRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final list = await _repo.list();
      state = state.copyWith(listState: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  Future<bool> save(String chave, String valor) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final updated = await _repo.update(chave, valor);
      final current = state.listState.valueOrNull ?? [];
      final next = current
          .map((c) => c.chave == chave ? updated : c)
          .toList();
      state = state.copyWith(
        listState: AsyncValue.data(next),
        saving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }
}

final configuracoesViewModelProvider =
    NotifierProvider<ConfiguracoesViewModel, ConfiguracoesState>(
        ConfiguracoesViewModel.new);
