import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'anexo_dto.dart';

export 'anexo_dto.dart';

abstract class AnexoRepositoryBase {
  Future<List<AnexoDto>> listByChamado(int chamadoId);

  Future<AnexoDto> upload({
    required int chamadoId,
    int? historicoId,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  Future<void> deletar(int id);

  String urlArquivo(String token);
}

class AnexoRepository implements AnexoRepositoryBase {
  const AnexoRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<AnexoDto>> listByChamado(int chamadoId) async {
    final res = await _client.get<List<dynamic>>('/chamados/$chamadoId/anexos');
    return (res.data as List)
        .map((e) => AnexoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AnexoDto> upload({
    required int chamadoId,
    int? historicoId,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    // Usa bytes (não caminho de arquivo) — funciona igual na web e no mobile.
    final formData = FormData.fromMap({
      'arquivo': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
      if (historicoId != null) 'historicoId': historicoId.toString(),
    });

    final res = await _client.post<Map<String, dynamic>>(
      '/chamados/$chamadoId/anexos',
      data: formData,
    );
    return AnexoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deletar(int id) async {
    await _client.delete<void>('/anexos/$id');
  }

  @override
  String urlArquivo(String token) => '${ApiClient.baseUrl}/anexos/$token/arquivo';
}

final anexoRepositoryProvider = Provider<AnexoRepositoryBase>((ref) {
  return AnexoRepository(ref.watch(apiClientProvider));
});
