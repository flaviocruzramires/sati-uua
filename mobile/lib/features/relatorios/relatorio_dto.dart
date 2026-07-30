import '../../../core/domain/enums.dart';

class RelatorioResumoDto {
  const RelatorioResumoDto({
    required this.total,
    required this.abertos,
    required this.emAndamento,
    required this.aguardandoSolicitante,
    required this.encerrados,
    required this.tempoMedioMinutos,
  });

  final int total;
  final int abertos;
  final int emAndamento;
  final int aguardandoSolicitante;
  final int encerrados;
  final double tempoMedioMinutos;

  factory RelatorioResumoDto.fromJson(Map<String, dynamic> j) =>
      RelatorioResumoDto(
        total: j['total'] as int,
        abertos: j['abertos'] as int,
        emAndamento: j['emAndamento'] as int,
        aguardandoSolicitante: j['aguardandoSolicitante'] as int,
        encerrados: j['encerrados'] as int,
        tempoMedioMinutos: (j['tempoMedioMinutos'] as num).toDouble(),
      );

  String get tempoMedioFormatado {
    if (tempoMedioMinutos <= 0) return '—';
    final h = (tempoMedioMinutos / 60).floor();
    final m = (tempoMedioMinutos % 60).round();
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

class RelatorioItemDto {
  const RelatorioItemDto({
    required this.id,
    required this.situacao,
    required this.dataAbertura,
    this.dataFechamento,
    required this.solicitanteNome,
    required this.solicitanteSetor,
    this.responsavelNome,
    this.equipamentoDescricao,
    this.tipoEquipamentoNome,
    this.servicoDescricao,
  });

  final int id;
  final SituacaoChamado situacao;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String solicitanteNome;
  final String solicitanteSetor;
  final String? responsavelNome;
  final String? equipamentoDescricao;
  final String? tipoEquipamentoNome;
  final String? servicoDescricao;

  factory RelatorioItemDto.fromJson(Map<String, dynamic> j) =>
      RelatorioItemDto(
        id: j['id'] as int,
        situacao: _parseSituacao(j['situacao'] as String),
        dataAbertura: DateTime.parse(j['dataAbertura'] as String),
        dataFechamento: j['dataFechamento'] != null
            ? DateTime.parse(j['dataFechamento'] as String)
            : null,
        solicitanteNome: j['solicitanteNome'] as String,
        solicitanteSetor: (j['solicitanteSetor'] as String?) ?? '—',
        responsavelNome: j['responsavelNome'] as String?,
        equipamentoDescricao: j['equipamentoDescricao'] as String?,
        tipoEquipamentoNome: j['tipoEquipamentoNome'] as String?,
        servicoDescricao: j['servicoDescricao'] as String?,
      );

  static SituacaoChamado _parseSituacao(String s) => switch (s) {
        'ABERTO' => SituacaoChamado.aberto,
        'EM_ANDAMENTO' => SituacaoChamado.emAndamento,
        'AGUARDANDO_SOLICITANTE' => SituacaoChamado.aguardandoSolicitante,
        _ => SituacaoChamado.encerrado,
      };
}

class RelatorioResultDto {
  const RelatorioResultDto({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.resumo,
  });

  final List<RelatorioItemDto> data;
  final int total;
  final int page;
  final int pageSize;
  final RelatorioResumoDto resumo;

  factory RelatorioResultDto.fromJson(Map<String, dynamic> j) =>
      RelatorioResultDto(
        data: (j['data'] as List)
            .map((e) =>
                RelatorioItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
        page: j['page'] as int,
        pageSize: j['pageSize'] as int,
        resumo: RelatorioResumoDto.fromJson(
            j['resumo'] as Map<String, dynamic>),
      );
}
