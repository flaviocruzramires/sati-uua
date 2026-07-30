import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chamado_repository.dart';

class ChamadoDetalheState {
  const ChamadoDetalheState({
    this.detalheState = const AsyncValue.loading(),
    this.saving = false,
    this.saveError,
  });

  final AsyncValue<ChamadoDetalheDto> detalheState;
  final bool saving;
  final String? saveError;

  ChamadoDetalheState copyWith({
    AsyncValue<ChamadoDetalheDto>? detalheState,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) =>
      ChamadoDetalheState(
        detalheState: detalheState ?? this.detalheState,
        saving: saving ?? this.saving,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
      );
}

class ChamadoDetalheViewModel extends FamilyNotifier<ChamadoDetalheState, int> {
  @override
  ChamadoDetalheState build(int chamadoId) {
    Future.microtask(() => load(chamadoId));
    return const ChamadoDetalheState();
  }

  ChamadoRepositoryBase get _repo => ref.read(chamadoRepositoryProvider);

  Future<void> load(int chamadoId) async {
    state = state.copyWith(detalheState: const AsyncValue.loading());
    try {
      final detalhe = await _repo.findDetalhe(chamadoId);
      state = state.copyWith(detalheState: AsyncValue.data(detalhe));
    } catch (e, st) {
      state = state.copyWith(detalheState: AsyncValue.error(e, st));
    }
  }

  Future<bool> registrarAtendimento({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
    required bool marcaEncerramento,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final detalhe = await _repo.registrarHistorico(
        chamadoId: chamadoId,
        descricao: descricao,
        dataRetorno: dataRetorno,
        marcaEncerramento: marcaEncerramento,
      );
      state = state.copyWith(
          saving: false, detalheState: AsyncValue.data(detalhe));
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> assumirChamado({
    required int chamadoId,
    required int responsavelId,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.atribuirResponsavel(
          id: chamadoId, responsavelId: responsavelId);
      await load(chamadoId);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  void clearSaveError() => state = state.copyWith(clearSaveError: true);
}

final chamadoDetalheViewModelProvider = NotifierProviderFamily<
    ChamadoDetalheViewModel, ChamadoDetalheState, int>(
  ChamadoDetalheViewModel.new,
);
