import 'chamado_dto.dart';
import 'chamado_historico_dto.dart';

export 'chamado_historico_dto.dart';

class ChamadoDetalheDto {
  const ChamadoDetalheDto({required this.chamado, required this.historico});

  final ChamadoDto chamado;
  final List<ChamadoHistoricoDto> historico;

  factory ChamadoDetalheDto.fromJson(Map<String, dynamic> json) =>
      ChamadoDetalheDto(
        chamado: ChamadoDto.fromJson(json),
        historico: (json['historico'] as List)
            .map((e) => ChamadoHistoricoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
