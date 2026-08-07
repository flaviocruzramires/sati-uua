enum Papel { solicitante, gerencia, atendente, admin }

Papel papelFromString(String s) => switch (s.toUpperCase()) {
      'SOLICITANTE' => Papel.solicitante,
      'GERENCIA' => Papel.gerencia,
      'ATENDENTE' => Papel.atendente,
      'ADMIN' => Papel.admin,
      _ => throw ArgumentError('Papel desconhecido: $s'),
    };

String papelToString(Papel p) => switch (p) {
      Papel.solicitante => 'SOLICITANTE',
      Papel.gerencia => 'GERENCIA',
      Papel.atendente => 'ATENDENTE',
      Papel.admin => 'ADMIN',
    };

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.login,
    required this.senhaHash,
    required this.setorId,
    required this.papel,
    required this.ativo,
  });

  final int id;
  final String nome;
  final String email;
  final String login;
  final String senhaHash;
  final int setorId;
  final Papel papel;
  final bool ativo;
}
