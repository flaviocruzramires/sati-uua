class ChamadoHistoricoDto {
  const ChamadoHistoricoDto({
    required this.id,
    required this.chamadoId,
    this.responsavelId,
    this.responsavelNome,
    this.solicitanteId,
    this.solicitanteNome,
    required this.dataRetorno,
    required this.descricao,
    required this.marcaEncerramento,
    required this.tipoRegistro,
    this.dataPrevistaRetorno,
  });

  final int id;
  final int chamadoId;
  final int? responsavelId;
  final String? responsavelNome;
  final int? solicitanteId;
  final String? solicitanteNome;
  final DateTime dataRetorno;
  final String descricao;
  final bool marcaEncerramento;
  final String tipoRegistro; // 'ATENDIMENTO' | 'RETORNO_SOLICITANTE'
  final DateTime? dataPrevistaRetorno;

  String get autorNome => responsavelNome ?? solicitanteNome ?? '—';
  bool get eRetornoSolicitante => tipoRegistro == 'RETORNO_SOLICITANTE';

  factory ChamadoHistoricoDto.fromJson(Map<String, dynamic> json) =>
      ChamadoHistoricoDto(
        id: json['id'] as int,
        chamadoId: json['chamadoId'] as int,
        responsavelId: json['responsavelId'] as int?,
        responsavelNome: json['responsavelNome'] as String?,
        solicitanteId: json['solicitanteId'] as int?,
        solicitanteNome: json['solicitanteNome'] as String?,
        dataRetorno: DateTime.parse(json['dataRetorno'] as String),
        descricao: json['descricao'] as String,
        marcaEncerramento: json['marcaEncerramento'] as bool,
        tipoRegistro: json['tipoRegistro'] as String? ?? 'ATENDIMENTO',
        dataPrevistaRetorno: json['dataPrevistaRetorno'] != null
            ? DateTime.tryParse(json['dataPrevistaRetorno'] as String)
            : null,
      );
}
