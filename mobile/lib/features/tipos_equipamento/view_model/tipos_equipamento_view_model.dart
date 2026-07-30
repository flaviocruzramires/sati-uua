import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/paginated_result.dart';
import '../tipo_equipamento_repository.dart';

class TiposEquipamentoState {
  const TiposEquipamentoState({
    this.listState = const AsyncValue.loading(),
    this.busca = '',
    this.page = 1,
    this.pageSize = 20,
    this.saving = false,
    this.saveError,
  });

  final AsyncValue<PaginatedResult<TipoEquipamentoDto>> listState;
  final String busca;
  final int page;
  final int pageSize;
  final bool saving;
  final String? saveError;

  TiposEquipamentoState copyWith({
    AsyncValue<PaginatedResult<TipoEquipamentoDto>>? listState,
    String? busca,
    int? page,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) => TiposEquipamentoState(
    listState: listState ?? this.listState,
    busca: busca ?? this.busca,
    page: page ?? this.page,
    pageSize: pageSize,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : (saveError ?? this.saveError),
  );
}

class TiposEquipamentoViewModel extends Notifier<TiposEquipamentoState> {
  @override
  TiposEquipamentoState build() {
    Future.microtask(load);
    return const TiposEquipamentoState();
  }

  TipoEquipamentoRepositoryBase get _repo =>
      ref.read(tipoEquipamentoRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final result = await _repo.list(
        page: state.page,
        pageSize: state.pageSize,
        busca: state.busca.isEmpty ? null : state.busca,
      );
      state = state.copyWith(listState: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  void setBusca(String value) {
    state = state.copyWith(busca: value, page: 1);
    load();
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    load();
  }

  Future<bool> create(String nome) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.create(nome);
      state = state.copyWith(saving: false, page: 1);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> update(int id, String nome) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.update(id, nome);
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

final tiposEquipamentoViewModelProvider =
    NotifierProvider<TiposEquipamentoViewModel, TiposEquipamentoState>(
      TiposEquipamentoViewModel.new,
    );
