import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/combo_item.dart';
import '../../../core/domain/paginated_result.dart';
import '../../../features/tipos_equipamento/tipo_equipamento_repository.dart';
import '../equipamento_repository.dart';

class EquipamentosState {
  const EquipamentosState({
    this.listState = const AsyncValue.loading(),
    this.tiposCombo = const AsyncValue.loading(),
    this.setoresCombo = const [],
    this.filtroTipoId,
    this.page = 1,
    this.pageSize = 20,
    this.saving = false,
    this.saveError,
  });

  final AsyncValue<PaginatedResult<EquipamentoDto>> listState;
  final AsyncValue<List<ComboItem<int>>> tiposCombo;
  final List<ComboItem<int?>> setoresCombo;
  final int? filtroTipoId;
  final int page;
  final int pageSize;
  final bool saving;
  final String? saveError;

  EquipamentosState copyWith({
    AsyncValue<PaginatedResult<EquipamentoDto>>? listState,
    AsyncValue<List<ComboItem<int>>>? tiposCombo,
    List<ComboItem<int?>>? setoresCombo,
    int? filtroTipoId,
    bool clearFiltroTipo = false,
    int? page,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) => EquipamentosState(
    listState: listState ?? this.listState,
    tiposCombo: tiposCombo ?? this.tiposCombo,
    setoresCombo: setoresCombo ?? this.setoresCombo,
    filtroTipoId: clearFiltroTipo ? null : (filtroTipoId ?? this.filtroTipoId),
    page: page ?? this.page,
    pageSize: pageSize,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : (saveError ?? this.saveError),
  );
}

class EquipamentosViewModel extends Notifier<EquipamentosState> {
  @override
  EquipamentosState build() {
    Future.microtask(_init);
    return const EquipamentosState();
  }

  EquipamentoRepositoryBase get _repo =>
      ref.read(equipamentoRepositoryProvider);
  TipoEquipamentoRepositoryBase get _tiposRepo =>
      ref.read(tipoEquipamentoRepositoryProvider);

  Future<void> _init() async {
    await Future.wait([_loadTiposCombo(), load()]);
  }

  Future<void> _loadTiposCombo() async {
    try {
      final items = await _tiposRepo.combo();
      state = state.copyWith(tiposCombo: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(tiposCombo: AsyncValue.error(e, st));
    }
  }

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final result = await _repo.list(
        page: state.page,
        pageSize: state.pageSize,
        tipoEquipamentoId: state.filtroTipoId,
      );
      state = state.copyWith(listState: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  void setFiltroTipo(int? tipoId) {
    state = state.copyWith(
      filtroTipoId: tipoId,
      clearFiltroTipo: tipoId == null,
      page: 1,
    );
    load();
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    load();
  }

  Future<bool> create({
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.create(
        descricao: descricao,
        tipoEquipamentoId: tipoEquipamentoId,
        setorId: setorId,
      );
      state = state.copyWith(saving: false, page: 1);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> update({
    required int id,
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
    required bool ativo,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.update(
        id: id,
        descricao: descricao,
        tipoEquipamentoId: tipoEquipamentoId,
        setorId: setorId,
        ativo: ativo,
      );
      state = state.copyWith(saving: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.delete(id);
      state = state.copyWith(saving: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  void clearSaveError() => state = state.copyWith(clearSaveError: true);
}

final equipamentosViewModelProvider =
    NotifierProvider<EquipamentosViewModel, EquipamentosState>(
      EquipamentosViewModel.new,
    );
