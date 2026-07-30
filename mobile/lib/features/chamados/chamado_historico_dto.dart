class ChamadoHistoricoDto {
  const ChamadoHistoricoDto({
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

  factory ChamadoHistoricoDto.fromJson(Map<String, dynamic> json) =>
      ChamadoHistoricoDto(
        id: json['id'] as int,
        chamadoId: json['chamadoId'] as int,
        responsavelId: json['responsavelId'] as int,
        responsavelNome: json['responsavelNome'] as String,
        dataRetorno: DateTime.parse(json['dataRetorno'] as String),
        descricao: json['descricao'] as String,
        marcaEncerramento: json['marcaEncerramento'] as bool,
      );
}
