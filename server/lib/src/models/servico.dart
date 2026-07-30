class Servico {
  const Servico({required this.id, required this.descricao});
  final int id;
  final String descricao;

  Map<String, dynamic> toJson() => {'id': id, 'descricao': descricao};
}
