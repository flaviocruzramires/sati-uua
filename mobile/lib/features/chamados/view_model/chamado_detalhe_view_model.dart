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
  }) => ChamadoDetalheState(
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
    DateTime? dataPrevistaRetorno,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final detalhe = await _repo.registrarHistorico(
        chamadoId: chamadoId,
        descricao: descricao,
        dataRetorno: dataRetorno,
        marcaEncerramento: marcaEncerramento,
        dataPrevistaRetorno: dataPrevistaRetorno,
      );
      state = state.copyWith(
        saving: false,
        detalheState: AsyncValue.data(detalhe),
      );
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
        id: chamadoId,
        responsavelId: responsavelId,
      );
      await load(chamadoId);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> atualizarTerceiro({
    required int chamadoId,
    required bool envolveTerceiro,
    String? nomeTerceiro,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final chamado = await _repo.atualizarTerceiro(
        id: chamadoId,
        envolveTerceiro: envolveTerceiro,
        nomeTerceiro: nomeTerceiro,
      );
      final atual = state.detalheState.valueOrNull;
      if (atual != null) {
        state = state.copyWith(
          saving: false,
          detalheState: AsyncValue.data(
            ChamadoDetalheDto(chamado: chamado, historico: atual.historico),
          ),
        );
      } else {
        state = state.copyWith(saving: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> enviarRetornoSolicitante({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final detalhe = await _repo.enviarRetornoSolicitante(
        chamadoId: chamadoId,
        descricao: descricao,
        dataRetorno: dataRetorno,
      );
      state = state.copyWith(
        saving: false,
        detalheState: AsyncValue.data(detalhe),
      );
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  void adicionarAnexo(AnexoDto anexo) {
    final atual = state.detalheState.valueOrNull;
    if (atual == null) return;
    state = state.copyWith(
      detalheState: AsyncValue.data(
        ChamadoDetalheDto(
          chamado: atual.chamado,
          historico: atual.historico,
          anexos: [...atual.anexos, anexo],
        ),
      ),
    );
  }

  void removerAnexo(int anexoId) {
    final atual = state.detalheState.valueOrNull;
    if (atual == null) return;
    state = state.copyWith(
      detalheState: AsyncValue.data(
        ChamadoDetalheDto(
          chamado: atual.chamado,
          historico: atual.historico,
          anexos: atual.anexos.where((a) => a.id != anexoId).toList(),
        ),
      ),
    );
  }

  void clearSaveError() => state = state.copyWith(clearSaveError: true);
}

final chamadoDetalheViewModelProvider =
    NotifierProviderFamily<ChamadoDetalheViewModel, ChamadoDetalheState, int>(
      ChamadoDetalheViewModel.new,
    );
