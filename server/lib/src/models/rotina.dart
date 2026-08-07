/// Rotina (tela/menu) do sistema — cadastro da rotina 11.
///
/// A árvore é montada pelo [RotinaRepository]: rotinas pai (`isPai = true`)
/// carregam seus [filhos] em [filhos]; folhas têm [filhos] vazio.
class Rotina {
  const Rotina({
    required this.id,
    required this.chave,
    required this.nome,
    required this.isPai,
    required this.rotinaPaiId,
    required this.isCrud,
    required this.isChamado,
    required this.rota,
    required this.ordem,
    required this.icone,
    this.filhos = const [],
  });

  final int id;
  final String chave;
  final String nome;
  final bool isPai;
  final int? rotinaPaiId;
  final bool isCrud;
  final bool isChamado;
  final String? rota;
  final int ordem;
  final String? icone;
  final List<Rotina> filhos;

  Rotina withFilhos(List<Rotina> filhos) => Rotina(
        id: id,
        chave: chave,
        nome: nome,
        isPai: isPai,
        rotinaPaiId: rotinaPaiId,
        isCrud: isCrud,
        isChamado: isChamado,
        rota: rota,
        ordem: ordem,
        icone: icone,
        filhos: filhos,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chave': chave,
        'nome': nome,
        'isPai': isPai,
        'rotinaPaiId': rotinaPaiId,
        'isCrud': isCrud,
        'isChamado': isChamado,
        'rota': rota,
        'ordem': ordem,
        'icone': icone,
        'filhos': filhos.map((f) => f.toJson()).toList(),
      };
}
