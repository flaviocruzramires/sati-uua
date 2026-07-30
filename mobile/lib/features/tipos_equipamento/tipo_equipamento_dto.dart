class TipoEquipamentoDto {
  const TipoEquipamentoDto({required this.id, required this.nome});

  final int id;
  final String nome;

  factory TipoEquipamentoDto.fromJson(Map<String, dynamic> json) =>
      TipoEquipamentoDto(id: json['id'] as int, nome: json['nome'] as String);
}
