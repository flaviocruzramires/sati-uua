class Anexo {
  const Anexo({
    required this.id,
    required this.token,
    required this.chamadoId,
    this.historicoId,
    required this.usuarioId,
    required this.usuarioNome,
    required this.nomeArquivo,
    required this.tamanhoBytes,
    required this.mimeType,
    required this.caminho,
    required this.criadoEm,
  });

  final int id;

  /// Identificador público (UUID) usado na URL de download.
  final String token;
  final int chamadoId;
  final int? historicoId;
  final int usuarioId;
  final String usuarioNome;
  final String nomeArquivo;
  final int tamanhoBytes;
  final String mimeType;
  final String caminho;
  final DateTime criadoEm;

  bool get isImagem => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'chamadoId': chamadoId,
        'historicoId': historicoId,
        'usuarioId': usuarioId,
        'usuarioNome': usuarioNome,
        'nomeArquivo': nomeArquivo,
        'tamanhoBytes': tamanhoBytes,
        'mimeType': mimeType,
        'criadoEm': criadoEm.toUtc().toIso8601String(),
      };
}
