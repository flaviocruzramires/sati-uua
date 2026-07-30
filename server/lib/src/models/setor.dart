class Setor {
  const Setor({required this.id, required this.nome});
  final int id;
  final String nome;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};
}
