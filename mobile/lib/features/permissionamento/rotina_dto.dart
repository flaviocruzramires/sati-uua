/// Espelha o modelo `Rotina` do servidor (rotina 11). A árvore vem aninhada:
/// rotinas pai (`isPai = true`) trazem [filhos]; folhas têm [filhos] vazio.
///
/// Consumido pela tela de permissionamento (rotina 12) e pelo menu dinâmico
/// (rotina 13).
class RotinaDto {
  const RotinaDto({
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
  final List<RotinaDto> filhos;

  factory RotinaDto.fromJson(Map<String, dynamic> json) => RotinaDto(
        id: json['id'] as int,
        chave: json['chave'] as String,
        nome: json['nome'] as String,
        isPai: json['isPai'] as bool,
        rotinaPaiId: json['rotinaPaiId'] as int?,
        isCrud: json['isCrud'] as bool,
        isChamado: json['isChamado'] as bool,
        rota: json['rota'] as String?,
        ordem: json['ordem'] as int,
        icone: json['icone'] as String?,
        filhos: ((json['filhos'] as List?) ?? const [])
            .map((e) => RotinaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
