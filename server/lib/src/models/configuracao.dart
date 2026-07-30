class Configuracao {
  const Configuracao({
    required this.chave,
    required this.valor,
    this.descricao,
    required this.tipo,
    required this.atualizadoEm,
    this.atualizadoPorNome,
  });

  final String chave;
  final String valor;
  final String? descricao;
  final String tipo; // string | int | bool
  final DateTime atualizadoEm;
  final String? atualizadoPorNome;

  Map<String, dynamic> toJson() => {
        'chave': chave,
        'valor': valor,
        'descricao': descricao,
        'tipo': tipo,
        'atualizadoEm': atualizadoEm.toUtc().toIso8601String(),
        'atualizadoPorNome': atualizadoPorNome,
      };
}
