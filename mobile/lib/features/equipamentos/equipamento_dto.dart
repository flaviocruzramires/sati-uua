class EquipamentoDto {
  const EquipamentoDto({
    required this.id,
    required this.descricao,
    required this.tipoEquipamentoId,
    required this.tipoEquipamentoNome,
    this.setorId,
    this.setorNome,
    required this.ativo,
  });

  final int id;
  final String descricao;
  final int tipoEquipamentoId;
  final String tipoEquipamentoNome;
  final int? setorId;
  final String? setorNome;
  final bool ativo;

  factory EquipamentoDto.fromJson(Map<String, dynamic> json) => EquipamentoDto(
    id: json['id'] as int,
    descricao: json['descricao'] as String,
    tipoEquipamentoId: json['tipoEquipamentoId'] as int,
    tipoEquipamentoNome: json['tipoEquipamentoNome'] as String,
    setorId: json['setorId'] as int?,
    setorNome: json['setorNome'] as String?,
    ativo: json['ativo'] as bool,
  );
}
