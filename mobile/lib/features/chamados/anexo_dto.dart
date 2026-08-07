class AnexoDto {
  const AnexoDto({
    required this.id,
    required this.token,
    required this.chamadoId,
    this.historicoId,
    required this.usuarioId,
    required this.usuarioNome,
    required this.nomeArquivo,
    required this.tamanhoBytes,
    required this.mimeType,
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
  final DateTime criadoEm;

  bool get isImagem => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get tamanhoLegivel {
    if (tamanhoBytes < 1024) return '${tamanhoBytes}B';
    if (tamanhoBytes < 1024 * 1024) return '${(tamanhoBytes / 1024).toStringAsFixed(1)}KB';
    return '${(tamanhoBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory AnexoDto.fromJson(Map<String, dynamic> json) => AnexoDto(
        id: json['id'] as int,
        token: json['token'] as String,
        chamadoId: json['chamadoId'] as int,
        historicoId: json['historicoId'] as int?,
        usuarioId: json['usuarioId'] as int,
        usuarioNome: json['usuarioNome'] as String,
        nomeArquivo: json['nomeArquivo'] as String,
        tamanhoBytes: json['tamanhoBytes'] as int,
        mimeType: json['mimeType'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );
}
