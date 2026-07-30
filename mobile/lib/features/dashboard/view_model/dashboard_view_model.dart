import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard_repository.dart';

class DashboardState {
  const DashboardState({
    this.resumoState = const AsyncValue.loading(),
    this.dias = 30,
  });

  final AsyncValue<DashboardDto> resumoState;
  final int dias;

  DashboardState copyWith({
    AsyncValue<DashboardDto>? resumoState,
    int? dias,
  }) =>
      DashboardState(
        resumoState: resumoState ?? this.resumoState,
        dias: dias ?? this.dias,
      );
}

class DashboardViewModel extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(load);
    return const DashboardState();
  }

  DashboardRepositoryBase get _repo => ref.read(dashboardRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(resumoState: const AsyncValue.loading());
    try {
      final resumo = await _repo.resumo(state.dias);
      state = state.copyWith(resumoState: AsyncValue.data(resumo));
    } catch (e, st) {
      state = state.copyWith(resumoState: AsyncValue.error(e, st));
    }
  }

  void setPeriodo(int dias) {
    state = state.copyWith(dias: dias);
    load();
  }
}

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardState>(
        DashboardViewModel.new);
