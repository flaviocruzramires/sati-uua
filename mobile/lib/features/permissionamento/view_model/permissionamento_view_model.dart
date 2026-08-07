import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../permissao_repository.dart';
import '../rotina_repository.dart';

/// Estado da tela de permissionamento (rotina 12): papel selecionado, catálogo
/// de rotinas (carregado uma vez), matriz do papel (por `rotinaId`) e flags de
/// carregamento/salvamento/alterações-não-salvas.
class PermissionamentoState {
  const PermissionamentoState({
    this.papel = PapelUsuario.gerencia,
    this.carregando = true,
    this.erro,
    this.rotinas = const [],
    this.matriz = const {},
    this.dirty = false,
    this.saving = false,
  });

  final PapelUsuario papel;
  final bool carregando;
  final Object? erro;
  final List<RotinaDto> rotinas;
  final Map<int, PermissaoRotinaDto> matriz;
  final bool dirty;
  final bool saving;

  PermissaoRotinaDto permissao(int rotinaId) =>
      matriz[rotinaId] ??
      PermissaoRotinaDto(
        rotinaId: rotinaId,
        ver: false,
        incluir: false,
        alterar: false,
        excluir: false,
      );

  PermissionamentoState copyWith({
    PapelUsuario? papel,
    bool? carregando,
    Object? erro,
    bool clearErro = false,
    List<RotinaDto>? rotinas,
    Map<int, PermissaoRotinaDto>? matriz,
    bool? dirty,
    bool? saving,
  }) =>
      PermissionamentoState(
        papel: papel ?? this.papel,
        carregando: carregando ?? this.carregando,
        erro: clearErro ? null : (erro ?? this.erro),
        rotinas: rotinas ?? this.rotinas,
        matriz: matriz ?? this.matriz,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
      );
}

class PermissionamentoViewModel extends Notifier<PermissionamentoState> {
  @override
  PermissionamentoState build() {
    Future.microtask(_carregarTudo);
    return const PermissionamentoState();
  }

  RotinaRepositoryBase get _rotinaRepo => ref.read(rotinaRepositoryProvider);
  PermissaoRepositoryBase get _permRepo => ref.read(permissaoRepositoryProvider);

  Future<void> _carregarTudo() async {
    state = state.copyWith(carregando: true, clearErro: true);
    try {
      final rotinas = await _rotinaRepo.listar();
      final matriz = await _carregarMatriz(state.papel);
      state = state.copyWith(
        carregando: false,
        rotinas: rotinas,
        matriz: matriz,
        dirty: false,
      );
    } catch (e) {
      state = state.copyWith(carregando: false, erro: e);
    }
  }

  Future<Map<int, PermissaoRotinaDto>> _carregarMatriz(
    PapelUsuario papel,
  ) async {
    final lista = await _permRepo.matriz(papel);
    return {for (final p in lista) p.rotinaId: p};
  }

  Future<void> selecionarPapel(PapelUsuario papel) async {
    if (papel == state.papel) return;
    state = state.copyWith(
      papel: papel,
      carregando: true,
      dirty: false,
      clearErro: true,
    );
    try {
      final matriz = await _carregarMatriz(papel);
      state = state.copyWith(carregando: false, matriz: matriz);
    } catch (e) {
      state = state.copyWith(carregando: false, erro: e);
    }
  }

  /// Alterna uma ação. Regra 4/5: desmarcar `Ver` zera as demais (feedback
  /// imediato; o servidor normaliza de novo no salvar).
  void alternar(int rotinaId, AcaoPermissao acao, bool valor) {
    final atual = state.permissao(rotinaId);
    final novo = switch (acao) {
      AcaoPermissao.ver => valor
          ? atual.copyWith(ver: true)
          : PermissaoRotinaDto(
              rotinaId: rotinaId,
              ver: false,
              incluir: false,
              alterar: false,
              excluir: false,
            ),
      AcaoPermissao.incluir => atual.copyWith(incluir: valor),
      AcaoPermissao.alterar => atual.copyWith(alterar: valor),
      AcaoPermissao.excluir => atual.copyWith(excluir: valor),
    };
    final matriz = Map<int, PermissaoRotinaDto>.from(state.matriz)
      ..[rotinaId] = novo;
    state = state.copyWith(matriz: matriz, dirty: true);
  }

  Future<void> descartar() async {
    state = state.copyWith(carregando: true, clearErro: true);
    try {
      final matriz = await _carregarMatriz(state.papel);
      state = state.copyWith(carregando: false, matriz: matriz, dirty: false);
    } catch (e) {
      state = state.copyWith(carregando: false, erro: e);
    }
  }

  Future<bool> salvar() async {
    state = state.copyWith(saving: true, clearErro: true);
    try {
      final normalizada =
          await _permRepo.salvarLote(state.papel, state.matriz.values.toList());
      state = state.copyWith(
        saving: false,
        dirty: false,
        matriz: {for (final p in normalizada) p.rotinaId: p},
      );
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, erro: e);
      return false;
    }
  }
}

final permissionamentoViewModelProvider =
    NotifierProvider<PermissionamentoViewModel, PermissionamentoState>(
  PermissionamentoViewModel.new,
);
