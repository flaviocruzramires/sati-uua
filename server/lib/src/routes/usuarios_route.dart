import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router usuariosRouter(AppContainer container) {
  final router = Router();
  final repo = container.usuarioRepository;

  router.get('/usuarios', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final page = int.tryParse(req.url.queryParameters['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(req.url.queryParameters['pageSize'] ?? '20') ?? 20;
    final papelStr = req.url.queryParameters['papel'];
    Papel? papel;
    if (papelStr != null) {
      try {
        papel = papelFromString(papelStr);
      } catch (_) {
        return _badRequest('papel inválido');
      }
    }

    final result = await repo.list(page: page, pageSize: pageSize, papel: papel);
    return _ok({
      'data': result.data.map((u) => u.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  router.post('/usuarios', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim() ?? '';
    final login = (body['login'] as String?)?.trim() ?? '';
    final senha = body['senha'] as String? ?? '';
    final setorId = body['setorId'] as int?;
    final papelStr = body['papel'] as String? ?? 'SOLICITANTE';

    if (nome.isEmpty) return _badRequest('nome é obrigatório');
    if (email.isEmpty) return _badRequest('email é obrigatório');
    if (login.isEmpty) return _badRequest('login é obrigatório');
    if (senha.length < 8) return _badRequest('senha deve ter no mínimo 8 caracteres');
    if (setorId == null) return _badRequest('setorId é obrigatório');

    Papel papel;
    try {
      papel = papelFromString(papelStr);
    } catch (_) {
      return _badRequest('papel inválido');
    }

    if (await repo.existsByEmail(email)) {
      return _conflict('E-mail já cadastrado');
    }
    if (await repo.existsByLogin(login)) {
      return _conflict('Login já cadastrado');
    }

    final senhaHash = BCrypt.hashpw(senha, BCrypt.gensalt());
    final usuario = await repo.create(
      nome: nome,
      email: email,
      login: login,
      senhaHash: senhaHash,
      setorId: setorId,
      papel: papel,
    );
    return Response(201,
        body: jsonEncode(usuario.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/usuarios/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final uid = int.tryParse(id);
    if (uid == null) return _badRequest('id inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim() ?? '';
    final setorId = body['setorId'] as int?;
    final papelStr = body['papel'] as String? ?? 'SOLICITANTE';
    final ativo = body['ativo'] as bool? ?? true;
    final senha = body['senha'] as String?;

    if (nome.isEmpty) return _badRequest('nome é obrigatório');
    if (email.isEmpty) return _badRequest('email é obrigatório');
    if (setorId == null) return _badRequest('setorId é obrigatório');
    if (senha != null && senha.isNotEmpty && senha.length < 8) {
      return _badRequest('senha deve ter no mínimo 8 caracteres');
    }

    Papel papel;
    try {
      papel = papelFromString(papelStr);
    } catch (_) {
      return _badRequest('papel inválido');
    }

    if (await repo.existsByEmail(email, excludeId: uid)) {
      return _conflict('E-mail já cadastrado');
    }

    String? senhaHash;
    if (senha != null && senha.isNotEmpty) {
      senhaHash = BCrypt.hashpw(senha, BCrypt.gensalt());
    }

    final usuario = await repo.update(
      id: uid,
      nome: nome,
      email: email,
      setorId: setorId,
      papel: papel,
      ativo: ativo,
      senhaHash: senhaHash,
    );
    if (usuario == null) return _notFound('Usuário não encontrado');
    return _ok(usuario.toJson());
  });

  return router;
}

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String msg) => Response(400,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

Response _notFound(String msg) => Response(404,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

Response _conflict(String msg) => Response(409,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});
