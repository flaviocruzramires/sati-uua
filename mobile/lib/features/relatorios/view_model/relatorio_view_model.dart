import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../relatorio_repository.dart';

class RelatorioFiltros {
  const RelatorioFiltros({
    this.situacao,
    this.solicitanteId,
    this.atendenteId,
    this.equipamentoId,
    this.servicoId,
    this.aberturaDe,
    this.aberturaAte,
    this.fechamentoDe,
    this.fechamentoAte,
  });

  final SituacaoChamado? situacao;
  final int? solicitanteId;
  final int? atendenteId;
  final int? equipamentoId;
  final int? servicoId;
  final DateTime? aberturaDe;
  final DateTime? aberturaAte;
  final DateTime? fechamentoDe;
  final DateTime? fechamentoAte;

  RelatorioFiltros copyWith({
    SituacaoChamado? situacao,
    bool clearSituacao = false,
    int? solicitanteId,
    bool clearSolicitante = false,
    int? atendenteId,
    bool clearAtendente = false,
    int? equipamentoId,
    bool clearEquipamento = false,
    int? servicoId,
    bool clearServico = false,
    DateTime? aberturaDe,
    bool clearAberturaDe = false,
    DateTime? aberturaAte,
    bool clearAberturaAte = false,
    DateTime? fechamentoDe,
    bool clearFechamentoDe = false,
    DateTime? fechamentoAte,
    bool clearFechamentoAte = false,
  }) => RelatorioFiltros(
    situacao: clearSituacao ? null : (situacao ?? this.situacao),
    solicitanteId: clearSolicitante
        ? null
        : (solicitanteId ?? this.solicitanteId),
    atendenteId: clearAtendente ? null : (atendenteId ?? this.atendenteId),
    equipamentoId: clearEquipamento
        ? null
        : (equipamentoId ?? this.equipamentoId),
    servicoId: clearServico ? null : (servicoId ?? this.servicoId),
    aberturaDe: clearAberturaDe ? null : (aberturaDe ?? this.aberturaDe),
    aberturaAte: clearAberturaAte ? null : (aberturaAte ?? this.aberturaAte),
    fechamentoDe: clearFechamentoDe
        ? null
        : (fechamentoDe ?? this.fechamentoDe),
    fechamentoAte: clearFechamentoAte
        ? null
        : (fechamentoAte ?? this.fechamentoAte),
  );

  bool get hasAnyFilter =>
      situacao != null ||
      solicitanteId != null ||
      atendenteId != null ||
      equipamentoId != null ||
      servicoId != null ||
      aberturaDe != null ||
      aberturaAte != null ||
      fechamentoDe != null ||
      fechamentoAte != null;
}

class RelatorioState {
  const RelatorioState({
    this.resultState = const AsyncValue.loading(),
    this.filtros = const RelatorioFiltros(),
    this.page = 1,
    this.pageSize = 20,
  });

  final AsyncValue<RelatorioResultDto> resultState;
  final RelatorioFiltros filtros;
  final int page;
  final int pageSize;

  RelatorioState copyWith({
    AsyncValue<RelatorioResultDto>? resultState,
    RelatorioFiltros? filtros,
    int? page,
  }) => RelatorioState(
    resultState: resultState ?? this.resultState,
    filtros: filtros ?? this.filtros,
    page: page ?? this.page,
    pageSize: pageSize,
  );
}

class RelatorioViewModel extends Notifier<RelatorioState> {
  @override
  RelatorioState build() {
    Future.microtask(buscar);
    return const RelatorioState();
  }

  RelatorioRepositoryBase get _repo => ref.read(relatorioRepositoryProvider);

  Future<void> buscar() async {
    state = state.copyWith(resultState: const AsyncValue.loading());
    try {
      final f = state.filtros;
      final result = await _repo.chamados(
        page: state.page,
        pageSize: state.pageSize,
        situacao: f.situacao,
        solicitanteId: f.solicitanteId,
        atendenteId: f.atendenteId,
        equipamentoId: f.equipamentoId,
        servicoId: f.servicoId,
        aberturaDe: f.aberturaDe,
        aberturaAte: f.aberturaAte,
        fechamentoDe: f.fechamentoDe,
        fechamentoAte: f.fechamentoAte,
      );
      state = state.copyWith(resultState: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(resultState: AsyncValue.error(e, st));
    }
  }

  void aplicarFiltros(RelatorioFiltros filtros) {
    state = state.copyWith(filtros: filtros, page: 1);
    buscar();
  }

  void limparFiltros() {
    state = state.copyWith(filtros: const RelatorioFiltros(), page: 1);
    buscar();
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    buscar();
  }
}

final relatorioViewModelProvider =
    NotifierProvider<RelatorioViewModel, RelatorioState>(
      RelatorioViewModel.new,
    );
