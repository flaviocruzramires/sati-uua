import 'dart:convert';

import '../domain/enums.dart';

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.nome,
    required this.papel,
  });

  final int id;
  final String nome;
  final PapelUsuario papel;

  static CurrentUser? fromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final json =
          jsonDecode(utf8.decode(base64Url.decode(payload)))
              as Map<String, dynamic>;
      return CurrentUser(
        id: int.parse(json['sub'].toString()),
        nome: json['nome'] as String,
        papel: _parsePapel(json['papel'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static PapelUsuario _parsePapel(String s) => switch (s.toUpperCase()) {
    'ADMIN' => PapelUsuario.admin,
    'ATENDENTE' => PapelUsuario.atendente,
    'GERENCIA' => PapelUsuario.gerencia,
    _ => PapelUsuario.solicitante,
  };
}
