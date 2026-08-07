class Notificacao {
  const Notificacao({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuarioId': usuarioId,
        'chamadoId': chamadoId,
        'tipo': tipo,
        'mensagem': mensagem,
        'lida': lida,
        'criadaEm': criadaEm.toIso8601String(),
      };
}
