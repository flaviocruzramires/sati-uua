import '../../core/domain/enums.dart';

class ChamadoDto {
  const ChamadoDto({
    required this.id,
    required this.descricao,
    required this.solicitanteId,
    required this.solicitanteNome,
    this.solicitanteSetorNome,
    this.responsavelId,
    this.responsavelNome,
    this.equipamentoId,
    this.equipamentoDescricao,
    this.servicoId,
    this.servicoNome,
    required this.situacao,
    required this.dataAbertura,
    this.dataFechamento,
    required this.envolveTerceiro,
    this.nomeTerceiro,
    this.dataPrevistaRetorno,
    this.ultimoRetorno,
  });

  final int id;
  final String descricao;
  final int solicitanteId;
  final String solicitanteNome;
  final String? solicitanteSetorNome;
  final int? responsavelId;
  final String? responsavelNome;
  final int? equipamentoId;
  final String? equipamentoDescricao;
  final int? servicoId;
  final String? servicoNome;
  final SituacaoChamado situacao;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final bool envolveTerceiro;
  final String? nomeTerceiro;
  final DateTime? dataPrevistaRetorno;
  final DateTime? ultimoRetorno;

  factory ChamadoDto.fromJson(Map<String, dynamic> json) => ChamadoDto(
    id: json['id'] as int,
    descricao: json['descricao'] as String,
    solicitanteId: json['solicitanteId'] as int,
    solicitanteNome: json['solicitanteNome'] as String,
    solicitanteSetorNome: json['solicitanteSetorNome'] as String?,
    responsavelId: json['responsavelId'] as int?,
    responsavelNome: json['responsavelNome'] as String?,
    equipamentoId: json['equipamentoId'] as int?,
    equipamentoDescricao: json['equipamentoDescricao'] as String?,
    servicoId: json['servicoId'] as int?,
    servicoNome: json['servicoNome'] as String?,
    situacao: _parseSituacao(json['situacao'] as String),
    dataAbertura: DateTime.parse(json['dataAbertura'] as String),
    dataFechamento: json['dataFechamento'] != null
        ? DateTime.parse(json['dataFechamento'] as String)
        : null,
    envolveTerceiro: json['envolveTerceiro'] as bool? ?? false,
    nomeTerceiro: json['nomeTerceiro'] as String?,
    dataPrevistaRetorno: json['dataPrevistaRetorno'] != null
        ? DateTime.tryParse(json['dataPrevistaRetorno'] as String)
        : null,
    ultimoRetorno: json['ultimoRetorno'] != null
        ? DateTime.tryParse(json['ultimoRetorno'] as String)
        : null,
  );

  static SituacaoChamado _parseSituacao(String s) => switch (s) {
    'ABERTO' => SituacaoChamado.aberto,
    'EM_ANDAMENTO' => SituacaoChamado.emAndamento,
    'AGUARDANDO_SOLICITANTE' => SituacaoChamado.aguardandoSolicitante,
    _ => SituacaoChamado.encerrado,
  };
}
