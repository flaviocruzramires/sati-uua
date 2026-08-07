import '../../core/domain/enums.dart';

class UsuarioDto {
  const UsuarioDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.login,
    required this.setorId,
    this.setorNome,
    required this.papel,
    required this.ativo,
  });

  final int id;
  final String nome;
  final String email;
  final String login;
  final int setorId;
  final String? setorNome;
  final PapelUsuario papel;
  final bool ativo;

  factory UsuarioDto.fromJson(Map<String, dynamic> json) => UsuarioDto(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String,
    login: json['login'] as String,
    setorId: json['setorId'] as int,
    setorNome: json['setorNome'] as String?,
    papel: _parsePapel(json['papel'] as String),
    ativo: json['ativo'] as bool,
  );

  static PapelUsuario _parsePapel(String s) => switch (s.toUpperCase()) {
    'ADMIN' => PapelUsuario.admin,
    'ATENDENTE' => PapelUsuario.atendente,
    'GERENCIA' => PapelUsuario.gerencia,
    _ => PapelUsuario.solicitante,
  };
}
