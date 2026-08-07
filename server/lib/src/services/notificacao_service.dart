import 'package:postgres/postgres.dart';

import '../repositories/notificacao_repository.dart';

class NotificacaoService {
  const NotificacaoService(this._repo, this._db);
  final NotificacaoRepository _repo;
  final Connection _db;

  // Busca IDs de todos os atendentes e admins ativos
  Future<List<int>> _atendenteEAdminIds() async {
    final rows = await _db.execute(
      Sql.named(
        "SELECT id FROM usuarios WHERE papel IN ('ATENDENTE','ADMIN') AND ativo = true",
      ),
    );
    return rows.map((r) => r[0] as int).toList();
  }

  Future<int?> _solicitanteId(int chamadoId) async {
    final rows = await _db.execute(
      Sql.named('SELECT usuario_solicitante_id FROM chamados WHERE id = @id'),
      parameters: {'id': chamadoId},
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as int?;
  }

  Future<int?> _responsavelId(int chamadoId) async {
    final rows = await _db.execute(
      Sql.named('SELECT usuario_responsavel_id FROM chamados WHERE id = @id'),
      parameters: {'id': chamadoId},
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as int?;
  }

  Future<List<int>> _adminIds() async {
    final rows = await _db.execute(
      Sql.named(
        "SELECT id FROM usuarios WHERE papel = 'ADMIN' AND ativo = true",
      ),
    );
    return rows.map((r) => r[0] as int).toList();
  }

  /// Chamado ao criar novo chamado
  Future<void> novoChamado(int chamadoId, String descricao) async {
    final ids = await _atendenteEAdminIds();
    final msg = _truncar(descricao, 80);
    await _repo.criar(
      usuarioIds: ids,
      chamadoId: chamadoId,
      tipo: 'NOVO_CHAMADO',
      mensagem: 'Novo chamado #$chamadoId: $msg',
    );
  }

  /// Chamado ao atribuir responsável
  Future<void> chamadoAssumido(int chamadoId, String atendenteNome) async {
    final solId = await _solicitanteId(chamadoId);
    if (solId == null) return;
    await _repo.criar(
      usuarioIds: [solId],
      chamadoId: chamadoId,
      tipo: 'CHAMADO_ASSUMIDO',
      mensagem:
          'Seu chamado #$chamadoId foi assumido por $atendenteNome',
    );
  }

  /// Chamado ao registrar histórico de atendimento
  Future<void> retornoAtendente(int chamadoId, String atendenteNome) async {
    final solId = await _solicitanteId(chamadoId);
    if (solId == null) return;
    await _repo.criar(
      usuarioIds: [solId],
      chamadoId: chamadoId,
      tipo: 'RETORNO_ATENDENTE',
      mensagem:
          '$atendenteNome registrou um retorno no chamado #$chamadoId',
    );
  }

  /// Chamado quando solicitante envia retorno
  Future<void> retornoSolicitante(
      int chamadoId, String solicitanteNome) async {
    final respId = await _responsavelId(chamadoId);
    final admins = await _adminIds();
    final ids = {
      if (respId != null) respId,
      ...admins,
    }.toList();
    await _repo.criar(
      usuarioIds: ids,
      chamadoId: chamadoId,
      tipo: 'RETORNO_SOLICITANTE',
      mensagem:
          '$solicitanteNome enviou informações no chamado #$chamadoId',
    );
  }

  /// Chamado quando chamado é encerrado
  Future<void> chamadoEncerrado(int chamadoId) async {
    final solId = await _solicitanteId(chamadoId);
    if (solId == null) return;
    await _repo.criar(
      usuarioIds: [solId],
      chamadoId: chamadoId,
      tipo: 'CHAMADO_ENCERRADO',
      mensagem: 'Seu chamado #$chamadoId foi encerrado',
    );
  }

  String _truncar(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
