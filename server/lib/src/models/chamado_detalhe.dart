import 'chamado.dart';
import 'chamado_historico.dart';

class ChamadoDetalhe {
  const ChamadoDetalhe({
    required this.chamado,
    required this.historico,
  });

  final Chamado chamado;
  final List<ChamadoHistorico> historico;

  Map<String, dynamic> toJson() => {
        ...chamado.toJson(),
        'historico': historico.map((h) => h.toJson()).toList(),
      };
}
