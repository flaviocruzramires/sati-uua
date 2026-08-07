/// Ações possíveis sobre uma rotina (quarteto do permissionamento).
enum Acao { ver, incluir, alterar, excluir }

/// Permissão de um papel sobre uma rotina (uma linha da matriz, rotina 12).
class PermissaoRotina {
  const PermissaoRotina({
    required this.rotinaId,
    required this.ver,
    required this.incluir,
    required this.alterar,
    required this.excluir,
  });

  final int rotinaId;
  final bool ver;
  final bool incluir;
  final bool alterar;
  final bool excluir;

  bool pode(Acao acao) => switch (acao) {
        Acao.ver => ver,
        Acao.incluir => incluir,
        Acao.alterar => alterar,
        Acao.excluir => excluir,
      };

  Map<String, dynamic> toJson() => {
        'rotinaId': rotinaId,
        'ver': ver,
        'incluir': incluir,
        'alterar': alterar,
        'excluir': excluir,
      };
}

/// Normaliza o quarteto pelas regras 2/4/6 — usado no PUT (fonte da verdade)
/// e no cálculo da matriz efetiva. A UI aplica as mesmas regras só para
/// feedback imediato; o servidor nunca confia no cliente.
///
/// - Regra 2: `is_crud = false` ⇒ só Ver (zera incluir/alterar/excluir).
/// - Regra 6: `is_chamado = true` ⇒ só Ver/Incluir (zera alterar/excluir).
/// - Regra 4/5: sem Ver ⇒ zera todas as demais.
({bool ver, bool incluir, bool alterar, bool excluir}) normalizarQuarteto({
  required bool ver,
  required bool incluir,
  required bool alterar,
  required bool excluir,
  required bool isCrud,
  required bool isChamado,
}) {
  if (!isCrud) {
    incluir = false;
    alterar = false;
    excluir = false;
  }
  if (isChamado) {
    alterar = false;
    excluir = false;
  }
  if (!ver) {
    incluir = false;
    alterar = false;
    excluir = false;
  }
  return (ver: ver, incluir: incluir, alterar: alterar, excluir: excluir);
}
