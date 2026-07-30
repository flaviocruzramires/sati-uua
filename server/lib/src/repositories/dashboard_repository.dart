import 'package:postgres/postgres.dart';

class KpiResumo {
  const KpiResumo({
    required this.abertos,
    required this.emAndamento,
    required this.aguardandoSolicitante,
    required this.encerrados,
    required this.semAtendente,
    required this.tempoMedioMinutos,
  });

  final int abertos;
  final int emAndamento;
  final int aguardandoSolicitante;
  final int encerrados;
  final int semAtendente;
  final double tempoMedioMinutos;

  Map<String, dynamic> toJson() => {
        'abertos': abertos,
        'emAndamento': emAndamento,
        'aguardandoSolicitante': aguardandoSolicitante,
        'encerrados': encerrados,
        'semAtendente': semAtendente,
        'tempoMedioMinutos': tempoMedioMinutos,
      };
}

class BarItem {
  const BarItem({required this.label, required this.total});
  final String label;
  final int total;
  Map<String, dynamic> toJson() => {'label': label, 'total': total};
}

class MesItem {
  const MesItem(
      {required this.mes, required this.abertos, required this.encerrados});
  final String mes; // 'YYYY-MM'
  final int abertos;
  final int encerrados;
  Map<String, dynamic> toJson() =>
      {'mes': mes, 'abertos': abertos, 'encerrados': encerrados};
}

class AtendendteResumo {
  const AtendendteResumo({
    required this.nome,
    required this.setorNome,
    required this.ativos,
    required this.encerrados,
    required this.tempoMedioMinutos,
  });
  final String nome;
  final String setorNome;
  final int ativos;
  final int encerrados;
  final double tempoMedioMinutos;
  Map<String, dynamic> toJson() => {
        'nome': nome,
        'setorNome': setorNome,
        'ativos': ativos,
        'encerrados': encerrados,
        'tempoMedioMinutos': tempoMedioMinutos,
      };
}

class DashboardResumo {
  const DashboardResumo({
    required this.kpi,
    required this.porSituacao,
    required this.porSetor,
    required this.porTipoEquipamento,
    required this.porServico,
    required this.evolucaoMensal,
    required this.porAtendente,
  });

  final KpiResumo kpi;
  final List<BarItem> porSituacao;
  final List<BarItem> porSetor;
  final List<BarItem> porTipoEquipamento;
  final List<BarItem> porServico;
  final List<MesItem> evolucaoMensal;
  final List<AtendendteResumo> porAtendente;

  Map<String, dynamic> toJson() => {
        'kpi': kpi.toJson(),
        'porSituacao': porSituacao.map((e) => e.toJson()).toList(),
        'porSetor': porSetor.map((e) => e.toJson()).toList(),
        'porTipoEquipamento':
            porTipoEquipamento.map((e) => e.toJson()).toList(),
        'porServico': porServico.map((e) => e.toJson()).toList(),
        'evolucaoMensal': evolucaoMensal.map((e) => e.toJson()).toList(),
        'porAtendente': porAtendente.map((e) => e.toJson()).toList(),
      };
}

class DashboardRepository {
  const DashboardRepository(this._db);
  final Connection _db;

  Future<DashboardResumo> resumo(int diasPeriodo) async {
    final desde = DateTime.now().toUtc().subtract(Duration(days: diasPeriodo));

    final results = await Future.wait([
      _kpi(desde),
      _porSituacao(desde),
      _porSetor(desde),
      _porTipoEquipamento(desde),
      _porServico(desde),
      _evolucaoMensal(),
      _porAtendente(desde),
    ]);

    return DashboardResumo(
      kpi: results[0] as KpiResumo,
      porSituacao: results[1] as List<BarItem>,
      porSetor: results[2] as List<BarItem>,
      porTipoEquipamento: results[3] as List<BarItem>,
      porServico: results[4] as List<BarItem>,
      evolucaoMensal: results[5] as List<MesItem>,
      porAtendente: results[6] as List<AtendendteResumo>,
    );
  }

  Future<KpiResumo> _kpi(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        "SELECT "
        "  COUNT(*) FILTER (WHERE situacao = 'ABERTO') AS abertos, "
        "  COUNT(*) FILTER (WHERE situacao = 'EM_ANDAMENTO') AS em_andamento, "
        "  COUNT(*) FILTER (WHERE situacao = 'AGUARDANDO_SOLICITANTE') AS aguardando, "
        "  COUNT(*) FILTER (WHERE situacao = 'ENCERRADO') AS encerrados, "
        "  COUNT(*) FILTER (WHERE usuario_responsavel_id IS NULL AND situacao != 'ENCERRADO') AS sem_atendente, "
        "  COALESCE(AVG(EXTRACT(EPOCH FROM (data_fechamento - data_abertura)) / 60) "
        "    FILTER (WHERE situacao = 'ENCERRADO'), 0) AS tempo_medio "
        "FROM chamados "
        "WHERE data_abertura >= @desde",
      ),
      parameters: {'desde': desde},
    );
    final r = rows.first;
    return KpiResumo(
      abertos: (r[0] as int?) ?? 0,
      emAndamento: (r[1] as int?) ?? 0,
      aguardandoSolicitante: (r[2] as int?) ?? 0,
      encerrados: (r[3] as int?) ?? 0,
      semAtendente: (r[4] as int?) ?? 0,
      tempoMedioMinutos: (r[5] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<List<BarItem>> _porSituacao(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT situacao::text, COUNT(*) '
        'FROM chamados WHERE data_abertura >= @desde '
        'GROUP BY situacao ORDER BY COUNT(*) DESC',
      ),
      parameters: {'desde': desde},
    );
    return rows
        .map((r) => BarItem(label: r[0] as String, total: r[1] as int))
        .toList();
  }

  Future<List<BarItem>> _porSetor(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT s.nome, COUNT(*) '
        'FROM chamados c '
        'JOIN usuarios u ON u.id = c.usuario_solicitante_id '
        'JOIN setores s ON s.id = u.setor_id '
        'WHERE c.data_abertura >= @desde '
        'GROUP BY s.nome ORDER BY COUNT(*) DESC LIMIT 8',
      ),
      parameters: {'desde': desde},
    );
    return rows
        .map((r) => BarItem(label: r[0] as String, total: r[1] as int))
        .toList();
  }

  Future<List<BarItem>> _porTipoEquipamento(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT te.nome, COUNT(*) '
        'FROM chamados c '
        'JOIN equipamentos e ON e.id = c.equipamento_id '
        'JOIN tipos_equipamento te ON te.id = e.tipo_equipamento_id '
        'WHERE c.data_abertura >= @desde AND c.equipamento_id IS NOT NULL '
        'GROUP BY te.nome ORDER BY COUNT(*) DESC LIMIT 8',
      ),
      parameters: {'desde': desde},
    );
    return rows
        .map((r) => BarItem(label: r[0] as String, total: r[1] as int))
        .toList();
  }

  Future<List<BarItem>> _porServico(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT s.descricao, COUNT(*) '
        'FROM chamados c '
        'JOIN servicos s ON s.id = c.servico_id '
        'WHERE c.data_abertura >= @desde AND c.servico_id IS NOT NULL '
        'GROUP BY s.descricao ORDER BY COUNT(*) DESC LIMIT 8',
      ),
      parameters: {'desde': desde},
    );
    return rows
        .map((r) => BarItem(label: r[0] as String, total: r[1] as int))
        .toList();
  }

  Future<List<MesItem>> _evolucaoMensal() async {
    final rows = await _db.execute(
      Sql.named(
        "SELECT to_char(data_abertura, 'YYYY-MM') AS mes, "
        "  COUNT(*) FILTER (WHERE situacao != 'ENCERRADO') AS abertos, "
        "  COUNT(*) FILTER (WHERE situacao = 'ENCERRADO') AS encerrados "
        'FROM chamados '
        "WHERE data_abertura >= date_trunc('month', now()) - interval '5 months' "
        "GROUP BY mes ORDER BY mes ASC",
      ),
    );
    return rows
        .map((r) => MesItem(
              mes: r[0] as String,
              abertos: (r[1] as int?) ?? 0,
              encerrados: (r[2] as int?) ?? 0,
            ))
        .toList();
  }

  Future<List<AtendendteResumo>> _porAtendente(DateTime desde) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT u.nome, s.nome AS setor, '
        "  COUNT(*) FILTER (WHERE c.situacao != 'ENCERRADO') AS ativos, "
        "  COUNT(*) FILTER (WHERE c.situacao = 'ENCERRADO' AND c.data_abertura >= @desde) AS encerrados, "
        '  COALESCE(AVG(EXTRACT(EPOCH FROM (c.data_fechamento - c.data_abertura)) / 60) '
        "    FILTER (WHERE c.situacao = 'ENCERRADO'), 0) AS tempo_medio "
        'FROM chamados c '
        'JOIN usuarios u ON u.id = c.usuario_responsavel_id '
        'JOIN setores s ON s.id = u.setor_id '
        'WHERE c.usuario_responsavel_id IS NOT NULL '
        'GROUP BY u.nome, s.nome ORDER BY ativos DESC LIMIT 10',
      ),
      parameters: {'desde': desde},
    );
    return rows
        .map((r) => AtendendteResumo(
              nome: r[0] as String,
              setorNome: r[1] as String,
              ativos: (r[2] as int?) ?? 0,
              encerrados: (r[3] as int?) ?? 0,
              tempoMedioMinutos: (r[4] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }
}
