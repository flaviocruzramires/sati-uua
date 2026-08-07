/// Ações do quarteto de permissionamento.
enum AcaoPermissao { ver, incluir, alterar, excluir }

/// Uma linha da matriz de permissionamento: quarteto de uma rotina para o papel
/// selecionado (rotina 12). Indexada por [rotinaId].
class PermissaoRotinaDto {
  const PermissaoRotinaDto({
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

  factory PermissaoRotinaDto.fromJson(Map<String, dynamic> json) =>
      PermissaoRotinaDto(
        rotinaId: json['rotinaId'] as int,
        ver: json['ver'] as bool? ?? false,
        incluir: json['incluir'] as bool? ?? false,
        alterar: json['alterar'] as bool? ?? false,
        excluir: json['excluir'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'rotinaId': rotinaId,
        'ver': ver,
        'incluir': incluir,
        'alterar': alterar,
        'excluir': excluir,
      };

  PermissaoRotinaDto copyWith({
    bool? ver,
    bool? incluir,
    bool? alterar,
    bool? excluir,
  }) =>
      PermissaoRotinaDto(
        rotinaId: rotinaId,
        ver: ver ?? this.ver,
        incluir: incluir ?? this.incluir,
        alterar: alterar ?? this.alterar,
        excluir: excluir ?? this.excluir,
      );
}

/// Permissão efetiva do usuário logado sobre uma rotina (`GET /me/permissoes`,
/// rotina 13). Já normalizada pelo servidor.
class PermissaoEfetivaDto {
  const PermissaoEfetivaDto({
    required this.ver,
    required this.incluir,
    required this.alterar,
    required this.excluir,
  });

  final bool ver;
  final bool incluir;
  final bool alterar;
  final bool excluir;

  factory PermissaoEfetivaDto.fromJson(Map<String, dynamic> json) =>
      PermissaoEfetivaDto(
        ver: json['ver'] as bool? ?? false,
        incluir: json['incluir'] as bool? ?? false,
        alterar: json['alterar'] as bool? ?? false,
        excluir: json['excluir'] as bool? ?? false,
      );
}
