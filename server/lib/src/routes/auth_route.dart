import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../services/auth_service.dart';

Router authRouter(AppContainer container) {
  final router = Router();

  router.post('/auth/login', (Request request) async {
    final body =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final login = body['login'] as String?;
    final senha = body['senha'] as String?;

    if (login == null ||
        login.trim().isEmpty ||
        senha == null ||
        senha.trim().isEmpty) {
      return Response(
        400,
        body: jsonEncode({'error': 'login e senha são obrigatórios'}),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final token = await container.authService.login(login.trim(), senha);
      return Response.ok(
        jsonEncode({'token': token}),
        headers: {'content-type': 'application/json'},
      );
    } on AuthException {
      // Mensagem genérica — não revela se foi login ou senha.
      return Response(
        401,
        body: jsonEncode({'error': 'Login ou senha inválidos'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
