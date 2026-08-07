import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notificacao_repository.dart';

class NotificacoesState {
  const NotificacoesState({
    this.listState = const AsyncValue.loading(),
    this.marking = false,
  });

  final AsyncValue<List<NotificacaoDto>> listState;
  final bool marking;

  NotificacoesState copyWith({
    AsyncValue<List<NotificacaoDto>>? listState,
    bool? marking,
  }) => NotificacoesState(
    listState: listState ?? this.listState,
    marking: marking ?? this.marking,
  );
}

class NotificacoesViewModel extends Notifier<NotificacoesState> {
  @override
  NotificacoesState build() {
    Future.microtask(load);
    return const NotificacoesState();
  }

  NotificacaoRepositoryBase get _repo =>
      ref.read(notificacaoRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final items = await _repo.list();
      state = state.copyWith(listState: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  Future<void> marcarLida(int id) async {
    await _repo.marcarLida(id);
    final current = state.listState.valueOrNull;
    if (current != null) {
      state = state.copyWith(
        listState: AsyncValue.data(
          current.map((n) => n.id == id ? _markRead(n) : n).toList(),
        ),
      );
    }
  }

  Future<void> marcarTodasLidas() async {
    state = state.copyWith(marking: true);
    try {
      await _repo.marcarTodasLidas();
      final current = state.listState.valueOrNull;
      if (current != null) {
        state = state.copyWith(
          marking: false,
          listState: AsyncValue.data(current.map(_markRead).toList()),
        );
      } else {
        state = state.copyWith(marking: false);
      }
    } catch (_) {
      state = state.copyWith(marking: false);
    }
  }

  static NotificacaoDto _markRead(NotificacaoDto n) => NotificacaoDto(
    id: n.id,
    usuarioId: n.usuarioId,
    chamadoId: n.chamadoId,
    tipo: n.tipo,
    mensagem: n.mensagem,
    lida: true,
    criadaEm: n.criadaEm,
  );
}

final notificacoesViewModelProvider =
    NotifierProvider<NotificacoesViewModel, NotificacoesState>(
      NotificacoesViewModel.new,
    );

// Badge counter — polls every 30 seconds
final notificacoesBadgeProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(notificacaoRepositoryProvider);

  Future<int> fetch() async {
    try {
      return await repo.countNaoLidas();
    } catch (_) {
      return 0;
    }
  }

  yield await fetch();

  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    yield await fetch();
  }
});
