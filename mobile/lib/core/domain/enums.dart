enum SituacaoChamado { aberto, emAndamento, aguardandoSolicitante, encerrado }

enum PapelUsuario { solicitante, gerencia, atendente, admin }

extension PapelUsuarioApi on PapelUsuario {
  /// Valor enviado/recebido pela API (enum `papel_usuario` do servidor).
  String get apiValue => switch (this) {
    PapelUsuario.admin => 'ADMIN',
    PapelUsuario.atendente => 'ATENDENTE',
    PapelUsuario.gerencia => 'GERENCIA',
    PapelUsuario.solicitante => 'SOLICITANTE',
  };
}

enum StatusAtivo { ativo, inativo }
