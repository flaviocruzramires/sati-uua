class NotificacaoDto {
  const NotificacaoDto({
    required this.id,
    required this.usuarioId,
    required this.chamadoId,
    required this.tipo,
    required this.mensagem,
    required this.lida,
    required this.criadaEm,
  });

  final int id;
  final int usuarioId;
  final int chamadoId;
  final String tipo;
  final String mensagem;
  final bool lida;
  final DateTime criadaEm;

  factory NotificacaoDto.fromJson(Map<String, dynamic> json) => NotificacaoDto(
    id: json['id'] as int,
    usuarioId: json['usuarioId'] as int,
    chamadoId: json['chamadoId'] as int,
    tipo: json['tipo'] as String,
    mensagem: json['mensagem'] as String,
    lida: json['lida'] as bool,
    criadaEm: DateTime.parse(json['criadaEm'] as String),
  );
}
