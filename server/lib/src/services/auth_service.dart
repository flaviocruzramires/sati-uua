import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';

import '../config/env.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart' show UsuarioRepositoryBase;

final _log = Logger('AuthService');

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class TokenPayload {
  const TokenPayload({required this.userId, required this.papel});
  final int userId;
  final Papel papel;
}

class AuthService {
  const AuthService(this._repo, this._env);

  final UsuarioRepositoryBase _repo;
  final Env _env;

  Future<String> login(String login, String senha) async {
    final usuario = await _repo.findByLogin(login);
    if (usuario == null) {
      _log.warning(
          'Tentativa de login: usuário não encontrado (login omitido)');
      throw const AuthException('Credenciais inválidas');
    }

    final valid = BCrypt.checkpw(senha, usuario.senhaHash);
    if (!valid) {
      _log.warning('Tentativa de login: senha incorreta (login omitido)');
      throw const AuthException('Credenciais inválidas');
    }

    final jwt = JWT(
      {
        'sub': usuario.id,
        'papel': papelToString(usuario.papel),
        'nome': usuario.nome,
      },
    );

    // JWT_SECRET nunca vai para log.
    return jwt.sign(
      SecretKey(_env.jwtSecret),
      expiresIn: const Duration(hours: 8),
    );
  }

  TokenPayload verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_env.jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      return TokenPayload(
        userId: payload['sub'] as int,
        papel: papelFromString(payload['papel'] as String),
      );
    } on JWTExpiredException {
      throw const AuthException('Token expirado');
    } on JWTException catch (e) {
      throw AuthException('Token inválido: ${e.message}');
    }
  }
}
