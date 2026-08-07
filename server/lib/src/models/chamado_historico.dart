class ChamadoHistorico {
  const ChamadoHistorico({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'chamadoId': chamadoId,
        'responsavelId': responsavelId,
        'responsavelNome': responsavelNome,
        'solicitanteId': solicitanteId,
        'solicitanteNome': solicitanteNome,
        'dataRetorno': dataRetorno.toIso8601String(),
        'descricao': descricao,
        'marcaEncerramento': marcaEncerramento,
        'tipoRegistro': tipoRegistro,
        'dataPrevistaRetorno':
            dataPrevistaRetorno?.toIso8601String().substring(0, 10),
      };
}
