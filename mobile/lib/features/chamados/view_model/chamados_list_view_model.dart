import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/paginated_result.dart';
import '../chamado_repository.dart';

class ChamadosListState {
  const ChamadosListState({
    this.listState = const AsyncValue.loading(),
    this.filtroSituacao,
    this.filtroResponsavelId,
    this.dataAberturaInicio,
    this.dataAberturaFim,
    this.page = 1,
    this.pageSize = 20,
  });

  final AsyncValue<PaginatedResult<ChamadoDto>> listState;
  final SituacaoChamado? filtroSituacao;
  final int? filtroResponsavelId;
  final DateTime? dataAberturaInicio;
  final DateTime? dataAberturaFim;
  final int page;
  final int pageSize;

  ChamadosListState copyWith({
    AsyncValue<PaginatedResult<ChamadoDto>>? listState,
    SituacaoChamado? filtroSituacao,
    bool clearFiltroSituacao = false,
    int? filtroResponsavelId,
    bool clearFiltroResponsavel = false,
    DateTime? dataAberturaInicio,
    bool clearDataInicio = false,
    DateTime? dataAberturaFim,
    bool clearDataFim = false,
    int? page,
  }) => ChamadosListState(
    listState: listState ?? this.listState,
    filtroSituacao: clearFiltroSituacao
        ? null
        : (filtroSituacao ?? this.filtroSituacao),
    filtroResponsavelId: clearFiltroResponsavel
        ? null
        : (filtroResponsavelId ?? this.filtroResponsavelId),
    dataAberturaInicio: clearDataInicio
        ? null
        : (dataAberturaInicio ?? this.dataAberturaInicio),
    dataAberturaFim: clearDataFim
        ? null
        : (dataAberturaFim ?? this.dataAberturaFim),
    page: page ?? this.page,
    pageSize: pageSize,
  );
}

class ChamadosListViewModel extends Notifier<ChamadosListState> {
  @override
  ChamadosListState build() {
    Future.microtask(load);
    return const ChamadosListState();
  }

  ChamadoRepositoryBase get _repo => ref.read(chamadoRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(listState: const AsyncValue.loading());
    try {
      final result = await _repo.list(
        page: state.page,
        pageSize: state.pageSize,
        situacao: state.filtroSituacao,
        responsavelId: state.filtroResponsavelId,
        dataAberturaInicio: state.dataAberturaInicio,
        dataAberturaFim: state.dataAberturaFim,
      );
      state = state.copyWith(listState: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(listState: AsyncValue.error(e, st));
    }
  }

  void setFiltroSituacao(SituacaoChamado? situacao) {
    state = state.copyWith(
      filtroSituacao: situacao,
      clearFiltroSituacao: situacao == null,
      page: 1,
    );
    load();
  }

  void setFiltroResponsavel(int? id) {
    state = state.copyWith(
      filtroResponsavelId: id,
      clearFiltroResponsavel: id == null,
      page: 1,
    );
    load();
  }

  void setDataAberturaInicio(DateTime? d) {
    state = state.copyWith(
      dataAberturaInicio: d,
      clearDataInicio: d == null,
      page: 1,
    );
    load();
  }

  void setDataAberturaFim(DateTime? d) {
    state = state.copyWith(
      dataAberturaFim: d,
      clearDataFim: d == null,
      page: 1,
    );
    load();
  }

  void limparFiltros() {
    state = state.copyWith(
      clearFiltroSituacao: true,
      clearFiltroResponsavel: true,
      clearDataInicio: true,
      clearDataFim: true,
      page: 1,
    );
    load();
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    load();
  }
}

final chamadosListViewModelProvider =
    NotifierProvider<ChamadosListViewModel, ChamadosListState>(
      ChamadosListViewModel.new,
    );
