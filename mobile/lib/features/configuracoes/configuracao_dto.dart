class ConfiguracaoDto {
  const ConfiguracaoDto({
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

  factory ConfiguracaoDto.fromJson(Map<String, dynamic> j) => ConfiguracaoDto(
        chave: j['chave'] as String,
        valor: j['valor'] as String,
        descricao: j['descricao'] as String?,
        tipo: j['tipo'] as String,
        atualizadoEm: DateTime.parse(j['atualizadoEm'] as String),
        atualizadoPorNome: j['atualizadoPorNome'] as String?,
      );

  ConfiguracaoDto copyWith({String? valor}) => ConfiguracaoDto(
        chave: chave,
        valor: valor ?? this.valor,
        descricao: descricao,
        tipo: tipo,
        atualizadoEm: atualizadoEm,
        atualizadoPorNome: atualizadoPorNome,
      );
}
