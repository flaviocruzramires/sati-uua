class KpiResumoDto {
  const KpiResumoDto({
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

  factory KpiResumoDto.fromJson(Map<String, dynamic> j) => KpiResumoDto(
        abertos: j['abertos'] as int,
        emAndamento: j['emAndamento'] as int,
        aguardandoSolicitante: j['aguardandoSolicitante'] as int,
        encerrados: j['encerrados'] as int,
        semAtendente: j['semAtendente'] as int,
        tempoMedioMinutos: (j['tempoMedioMinutos'] as num).toDouble(),
      );

  String get tempoMedioFormatado {
    final h = (tempoMedioMinutos / 60).floor();
    final m = (tempoMedioMinutos % 60).round();
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

class BarItemDto {
  const BarItemDto({required this.label, required this.total});
  final String label;
  final int total;
  factory BarItemDto.fromJson(Map<String, dynamic> j) =>
      BarItemDto(label: j['label'] as String, total: j['total'] as int);
}

class MesItemDto {
  const MesItemDto(
      {required this.mes, required this.abertos, required this.encerrados});
  final String mes;
  final int abertos;
  final int encerrados;
  factory MesItemDto.fromJson(Map<String, dynamic> j) => MesItemDto(
        mes: j['mes'] as String,
        abertos: j['abertos'] as int,
        encerrados: j['encerrados'] as int,
      );
}

class AtendenteResumoDto {
  const AtendenteResumoDto({
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
  factory AtendenteResumoDto.fromJson(Map<String, dynamic> j) =>
      AtendenteResumoDto(
        nome: j['nome'] as String,
        setorNome: j['setorNome'] as String,
        ativos: j['ativos'] as int,
        encerrados: j['encerrados'] as int,
        tempoMedioMinutos: (j['tempoMedioMinutos'] as num).toDouble(),
      );
}

class DashboardDto {
  const DashboardDto({
    required this.kpi,
    required this.porSituacao,
    required this.porSetor,
    required this.porTipoEquipamento,
    required this.porServico,
    required this.evolucaoMensal,
    required this.porAtendente,
  });

  final KpiResumoDto kpi;
  final List<BarItemDto> porSituacao;
  final List<BarItemDto> porSetor;
  final List<BarItemDto> porTipoEquipamento;
  final List<BarItemDto> porServico;
  final List<MesItemDto> evolucaoMensal;
  final List<AtendenteResumoDto> porAtendente;

  factory DashboardDto.fromJson(Map<String, dynamic> j) => DashboardDto(
        kpi: KpiResumoDto.fromJson(j['kpi'] as Map<String, dynamic>),
        porSituacao: _barList(j['porSituacao']),
        porSetor: _barList(j['porSetor']),
        porTipoEquipamento: _barList(j['porTipoEquipamento']),
        porServico: _barList(j['porServico']),
        evolucaoMensal: (j['evolucaoMensal'] as List)
            .map((e) => MesItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        porAtendente: (j['porAtendente'] as List)
            .map((e) =>
                AtendenteResumoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static List<BarItemDto> _barList(dynamic raw) => (raw as List)
      .map((e) => BarItemDto.fromJson(e as Map<String, dynamic>))
      .toList();
}
