import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/combo_item.dart';
import '../../../features/equipamentos/equipamento_repository.dart';
import '../../../features/servicos/servico_repository.dart';
import '../chamado_repository.dart';

class AbrirChamadoState {
  const AbrirChamadoState({
    this.equipamentosCombo = const AsyncValue.loading(),
    this.servicosCombo = const AsyncValue.loading(),
    this.saving = false,
    this.saveError,
    this.chamadoCriadoId,
  });

  final AsyncValue<List<ComboItem<int?>>> equipamentosCombo;
  final AsyncValue<List<ComboItem<int?>>> servicosCombo;
  final bool saving;
  final String? saveError;
  final int? chamadoCriadoId;

  AbrirChamadoState copyWith({
    AsyncValue<List<ComboItem<int?>>>? equipamentosCombo,
    AsyncValue<List<ComboItem<int?>>>? servicosCombo,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
    int? chamadoCriadoId,
  }) => AbrirChamadoState(
    equipamentosCombo: equipamentosCombo ?? this.equipamentosCombo,
    servicosCombo: servicosCombo ?? this.servicosCombo,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : (saveError ?? this.saveError),
    chamadoCriadoId: chamadoCriadoId ?? this.chamadoCriadoId,
  );
}

class AbrirChamadoViewModel extends Notifier<AbrirChamadoState> {
  @override
  AbrirChamadoState build() {
    Future.microtask(_init);
    return const AbrirChamadoState();
  }

  EquipamentoRepositoryBase get _equipamentoRepo =>
      ref.read(equipamentoRepositoryProvider);
  ServicoRepositoryBase get _servicoRepo => ref.read(servicoRepositoryProvider);
  ChamadoRepositoryBase get _repo => ref.read(chamadoRepositoryProvider);

  Future<void> _init() async {
    await Future.wait([_loadEquipamentos(), _loadServicos()]);
  }

  Future<void> _loadEquipamentos() async {
    try {
      final result = await _equipamentoRepo.list(pageSize: 200);
      final items = <ComboItem<int?>>[
        const ComboItem(null, 'Nenhum / não se aplica'),
        ...result.data.map((e) => ComboItem<int?>(e.id, e.descricao)),
      ];
      state = state.copyWith(equipamentosCombo: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(equipamentosCombo: AsyncValue.error(e, st));
    }
  }

  Future<void> _loadServicos() async {
    try {
      final result = await _servicoRepo.list(pageSize: 200);
      final items = <ComboItem<int?>>[
        const ComboItem(null, 'Selecione um serviço'),
        ...result.data.map((s) => ComboItem<int?>(s.id, s.descricao)),
      ];
      state = state.copyWith(servicosCombo: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(servicosCombo: AsyncValue.error(e, st));
    }
  }

  Future<bool> abrir({
    required String descricao,
    int? equipamentoId,
    int? servicoId,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      final chamado = await _repo.create(
        descricao: descricao,
        equipamentoId: equipamentoId,
        servicoId: servicoId,
      );
      state = state.copyWith(saving: false, chamadoCriadoId: chamado.id);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  void clearSaveError() => state = state.copyWith(clearSaveError: true);
}

final abrirChamadoViewModelProvider =
    NotifierProvider<AbrirChamadoViewModel, AbrirChamadoState>(
      AbrirChamadoViewModel.new,
    );
