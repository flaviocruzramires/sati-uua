class ServicoDto {
  const ServicoDto({required this.id, required this.descricao});

  final int id;
  final String descricao;

  factory ServicoDto.fromJson(Map<String, dynamic> json) => ServicoDto(
        id: json['id'] as int,
        descricao: json['descricao'] as String,
      );
}
