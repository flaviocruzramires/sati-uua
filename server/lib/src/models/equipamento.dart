class Equipamento {
  const Equipamento({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'descricao': descricao,
        'tipoEquipamentoId': tipoEquipamentoId,
        'tipoEquipamentoNome': tipoEquipamentoNome,
        'setorId': setorId,
        'setorNome': setorNome,
        'ativo': ativo,
      };
}
