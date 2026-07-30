import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/paginated_result.dart';
import '../setor_repository.dart';

class SetoresState {
  const SetoresState({
    this.listState = const AsyncValue.loading(),
    this.busca = '',
    this.page = 1,
    this.pageSize = 20,
    this.saving = false,
    this.saveError,
  });

  final AsyncValue<PaginatedResult<SetorDto>> listState;
  final String busca;
  final int page;
  final int pageSize;
  final bool saving;
  final String? saveError;

  SetoresState copyWith({
    AsyncValue<PaginatedResult<SetorDto>>? listState,
    String? busca,
    int? page,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) => SetoresState(
    listState: listState ?? this.listState,
    busca: busca ?? this.busca,
    page: page ?? this.page,
    pageSize: pageSize,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : (saveError ?? this.saveError),
  );
}

class SetoresViewModel extends Notifier<SetoresState> {
  @override
  SetoresState build() {
    Future.microtask(load);
    return const SetoresState();
  }

  SetorRepositoryBase get _repo => ref.read(setorRepositoryProvider);

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

final setoresViewModelProvider =
    NotifierProvider<SetoresViewModel, SetoresState>(SetoresViewModel.new);
