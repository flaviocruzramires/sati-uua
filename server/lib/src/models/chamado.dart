class Chamado {
  const Chamado({
    required this.id,
    required this.descricao,
    required this.solicitanteId,
    required this.solicitanteNome,
    this.solicitanteSetorNome,
    this.responsavelId,
    this.responsavelNome,
    this.equipamentoId,
    this.equipamentoDescricao,
    this.servicoId,
    this.servicoNome,
    required this.situacao,
    required this.dataAbertura,
    this.dataFechamento,
    this.envolveTerceiro = false,
    this.nomeTerceiro,
    this.dataPrevistaRetorno,
    this.ultimoRetorno,
  });

  final int id;
  final String descricao;
  final int solicitanteId;
  final String solicitanteNome;
  final String? solicitanteSetorNome;
  final int? responsavelId;
  final String? responsavelNome;
  final int? equipamentoId;
  final String? equipamentoDescricao;
  final int? servicoId;
  final String? servicoNome;
  final String situacao;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final bool envolveTerceiro;
  final String? nomeTerceiro;
  final DateTime? dataPrevistaRetorno;
  final DateTime? ultimoRetorno;

  Map<String, dynamic> toJson() => {
        'id': id,
        'descricao': descricao,
        'solicitanteId': solicitanteId,
        'solicitanteNome': solicitanteNome,
        'solicitanteSetorNome': solicitanteSetorNome,
        'responsavelId': responsavelId,
        'responsavelNome': responsavelNome,
        'equipamentoId': equipamentoId,
        'equipamentoDescricao': equipamentoDescricao,
        'servicoId': servicoId,
        'servicoNome': servicoNome,
        'situacao': situacao,
        'dataAbertura': dataAbertura.toIso8601String(),
        'dataFechamento': dataFechamento?.toIso8601String(),
        'envolveTerceiro': envolveTerceiro,
        'nomeTerceiro': nomeTerceiro,
        'dataPrevistaRetorno':
            dataPrevistaRetorno?.toIso8601String().substring(0, 10),
        'ultimoRetorno': ultimoRetorno?.toIso8601String(),
      };
}
