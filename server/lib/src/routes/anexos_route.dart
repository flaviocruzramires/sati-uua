import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../di/app_container.dart';
import '../errors/app_exception.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

const _uuid = Uuid();
const _maxBytes = 10 * 1024 * 1024; // 10 MB
const _allowedMimes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'application/pdf',
};

Router anexosRouter(AppContainer container, String uploadsDir) {
  final router = Router();
  final repo = container.anexoRepository;

  // ── Upload ────────────────────────────────────────────────────────────────
  router.post('/chamados/<chamadoId>/anexos', (
    Request req,
    String chamadoId,
  ) async {
    final payload = requireAuth(req);
    final cId = int.tryParse(chamadoId);
    if (cId == null) return _badRequest('chamadoId inválido');

    final form = req.formData();
    if (form == null) return _badRequest('Requisição deve ser multipart/form-data');

    int? historicoId;
    String? nomeArquivo;
    String? mimeType;
    List<int>? bytes;

    await for (final field in form.formData) {
      if (field.name == 'historicoId') {
        historicoId = int.tryParse(await field.part.readString());
      } else if (field.filename != null) {
        nomeArquivo = _sanitizeFilename(field.filename!);
        final rawBytes = await field.part.readBytes();
        bytes = rawBytes;

        // Detecta MIME pelo conteúdo (mais seguro que confiar no cliente)
        mimeType = lookupMimeType(nomeArquivo, headerBytes: rawBytes.take(12).toList())
            ?? 'application/octet-stream';
      }
    }

    if (bytes == null || nomeArquivo == null) {
      return _badRequest('Nenhum arquivo enviado');
    }
    if (bytes.length > _maxBytes) {
      return _badRequest('Arquivo excede o limite de 10 MB');
    }
    if (!_allowedMimes.contains(mimeType)) {
      return _badRequest('Tipo de arquivo não permitido. Use imagem ou PDF.');
    }

    // Salva o arquivo em disco
    final ext = nomeArquivo.contains('.') ? '.${nomeArquivo.split('.').last}' : '';
    final nomeUnico = '${_uuid.v4()}$ext';
    final dir = Directory('$uploadsDir/chamado_$cId');
    await dir.create(recursive: true);
    final caminho = '${dir.path}/$nomeUnico';
    await File(caminho).writeAsBytes(bytes);

    final anexo = await repo.criar(
      chamadoId: cId,
      historicoId: historicoId,
      usuarioId: payload.userId,
      nomeArquivo: nomeArquivo,
      tamanhoBytes: bytes.length,
      mimeType: mimeType!,
      caminho: caminho,
    );

    return Response(201,
        body: jsonEncode(anexo.toJson()),
        headers: {'content-type': 'application/json'});
  });

  // ── Listar por chamado ────────────────────────────────────────────────────
  router.get('/chamados/<chamadoId>/anexos', (
    Request req,
    String chamadoId,
  ) async {
    requireAuth(req);
    final cId = int.tryParse(chamadoId);
    if (cId == null) return _badRequest('chamadoId inválido');

    final anexos = await repo.listByChamado(cId);
    return _ok(anexos.map((a) => a.toJson()).toList());
  });

  // ── Download do arquivo ─────────────────────────────────────────────────
  // Rota pública (aberta direto no navegador/dispositivo, sem header
  // Authorization). Usa o token UUID não-adivinhável em vez do id sequencial,
  // impedindo enumeração de anexos por curiosos na intranet.
  router.get('/anexos/<token>/arquivo', (Request req, String token) async {
    if (!_isUuid(token)) return _badRequest('Token inválido');

    final anexo = await repo.findByToken(token);
    if (anexo == null) return _notFound('Anexo não encontrado');

    final file = File(anexo.caminho);
    if (!file.existsSync()) return _notFound('Arquivo não encontrado em disco');

    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': anexo.mimeType,
        'content-disposition':
            'inline; filename="${_encodeFilename(anexo.nomeArquivo)}"',
        'content-length': anexo.tamanhoBytes.toString(),
      },
    );
  });

  // ── Deletar ───────────────────────────────────────────────────────────────
  router.delete('/anexos/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    final nId = int.tryParse(id);
    if (nId == null) return _badRequest('ID inválido');

    final anexo = await repo.findById(nId);
    if (anexo == null) return _notFound('Anexo não encontrado');

    // Somente quem enviou ou admin pode deletar
    if (anexo.usuarioId != payload.userId && payload.papel != Papel.admin) {
      throw const AppException.forbidden();
    }

    // Remove do disco (ignora se já não existe)
    final file = File(anexo.caminho);
    if (file.existsSync()) await file.delete();

    await repo.deletar(nId);
    return _ok({'ok': true});
  });

  return router;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isUuid(String s) => _uuidRegex.hasMatch(s);

String _sanitizeFilename(String name) {
  // Remove path separators e caracteres perigosos
  return name.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'[^\w.\-]'), '_');
}

String _encodeFilename(String name) => Uri.encodeComponent(name);

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String msg) => Response(
      400,
      body: jsonEncode({'error': msg}),
      headers: {'content-type': 'application/json'},
    );

Response _notFound(String msg) => Response.notFound(
      jsonEncode({'error': msg}),
      headers: {'content-type': 'application/json'},
    );
