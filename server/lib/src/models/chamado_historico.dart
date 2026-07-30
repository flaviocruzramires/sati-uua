class ChamadoHistorico {
  const ChamadoHistorico({
    required this.id,
    required this.chamadoId,
    required this.responsavelId,
    required this.responsavelNome,
    required this.dataRetorno,
    required this.descricao,
    required this.marcaEncerramento,
  });

  final int id;
  final int chamadoId;
  final int responsavelId;
  final String responsavelNome;
  final DateTime dataRetorno;
  final String descricao;
  final bool marcaEncerramento;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chamadoId': chamadoId,
        'responsavelId': responsavelId,
        'responsavelNome': responsavelNome,
        'dataRetorno': dataRetorno.toIso8601String(),
        'descricao': descricao,
        'marcaEncerramento': marcaEncerramento,
      };
}
