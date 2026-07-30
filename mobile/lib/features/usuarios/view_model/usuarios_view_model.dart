import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/combo_item.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/paginated_result.dart';
import '../../../features/setores/setor_repository.dart';
import '../usuario_repository.dart';

class UsuariosState {
  const UsuariosState({
    this.listState = const AsyncValue.loading(),
    this.setoresCombo = const AsyncValue.loading(),
    this.filtroPapel,
    this.page = 1,
    this.pageSize = 20,
    this.selectedId,
    this.saving = false,
    this.saveError,
  });

  final AsyncValue<PaginatedResult<UsuarioDto>> listState;
  final AsyncValue<List<ComboItem<int>>> setoresCombo;
  final PapelUsuario? filtroPapel;
  final int page;
  final int pageSize;
  final int? selectedId;
  final bool saving;
  final String? saveError;

  UsuariosState copyWith({
    AsyncValue<PaginatedResult<UsuarioDto>>? listState,
    AsyncValue<List<ComboItem<int>>>? setoresCombo,
    PapelUsuario? filtroPapel,
    bool clearFiltroPapel = false,
    int? page,
    int? selectedId,
    bool clearSelected = false,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) =>
      UsuariosState(
        listState: listState ?? this.listState,
        setoresCombo: setoresCombo ?? this.setoresCombo,
        filtroPapel:
            clearFiltroPapel ? null : (filtroPapel ?? this.filtroPapel),
        page: page ?? this.page,
        pageSize: pageSize,
        selectedId: clearSelected ? null : (selectedId ?? this.selectedId),
        saving: saving ?? this.saving,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
      );

  UsuarioDto? selectedUser(List<UsuarioDto> data) =>
      data.where((u) => u.id == selectedId).firstOrNull;
}

class UsuariosViewModel extends Notifier<UsuariosState> {
  @override
  UsuariosState build() {
    Future.microtask(_init);
    return const UsuariosState();
  }

  UsuarioRepositoryBase get _repo => ref.read(usuarioRepositoryProvider);
  SetorRepositoryBase get _setorRepo => ref.read(setorRepositoryProvider);

  Future<void> _init() async {
    await Future.wait([_loadSetoresCombo(), load()]);
  }

  Future<void> _loadSetoresCombo() async {
    try {
      final result = await _setorRepo.list(pageSize: 200);
      final items = result.data
          .map((s) => ComboItem<int>(s.id, s.nome))
          .toList();
      state = state.copyWith(setoresCombo: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(setoresCombo: AsyncValue.error(e, st));
    }
  }

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final result = await _repo.list(
        page: state.page,
        pageSize: state.pageSize,
        papel: state.filtroPapel,
      );
      state = state.copyWith(listState: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  void setFiltroPapel(PapelUsuario? papel) {
    state = state.copyWith(
      filtroPapel: papel,
      clearFiltroPapel: papel == null,
      page: 1,
    );
    load();
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    load();
  }

  void selectUser(int? id) {
    state = state.copyWith(
      selectedId: id,
      clearSelected: id == null,
      clearSaveError: true,
    );
  }

  Future<bool> create({
    required String nome,
    required String email,
    required String login,
    required String senha,
    required int setorId,
    required PapelUsuario papel,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.create(
        nome: nome,
        email: email,
        login: login,
        senha: senha,
        setorId: setorId,
        papel: papel,
      );
      state = state.copyWith(saving: false, page: 1, clearSelected: true);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString());
      return false;
    }
  }

  Future<bool> update({
    required int id,
    required String nome,
    required String email,
    required int setorId,
    required PapelUsuario papel,
    required bool ativo,
    String? senha,
  }) async {
    state = state.copyWith(saving: true, clearSaveError: true);
    try {
      await _repo.update(
        id: id,
        nome: nome,
        email: email,
        setorId: setorId,
        papel: papel,
        ativo: ativo,
        senha: senha,
      );
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

final usuariosViewModelProvider =
    NotifierProvider<UsuariosViewModel, UsuariosState>(UsuariosViewModel.new);
