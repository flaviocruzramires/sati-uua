class SetorDto {
  const SetorDto({required this.id, required this.nome});

  final int id;
  final String nome;

  factory SetorDto.fromJson(Map<String, dynamic> json) =>
      SetorDto(id: json['id'] as int, nome: json['nome'] as String);
}
