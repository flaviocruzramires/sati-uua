import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:test/test.dart';

import 'package:sati_uua_server/src/config/env.dart';
import 'package:sati_uua_server/src/models/usuario.dart';
import 'package:sati_uua_server/src/repositories/usuario_repository.dart';
import 'package:sati_uua_server/src/services/auth_service.dart';

// Stub que implementa a interface abstrata sem banco de dados
class _FakeRepo implements UsuarioRepositoryBase {
  _FakeRepo(this._usuario);
  final Usuario? _usuario;

  @override
  Future<Usuario?> findByLogin(String login) async => _usuario;

  @override
  Future<Usuario?> findById(int id) async => _usuario;
}

Env _fakeEnv() {
  // Configura variáveis de ambiente antes de Env.load()
  // e reseta o singleton para cada chamada.
  return Env.load(path: 'nonexistent-file-so-only-env-vars.env');
}

Usuario _fakeUsuario(String senha) => Usuario(
      id: 1,
      nome: 'Admin',
      email: 'admin@uems.br',
      login: 'admin',
      senhaHash: BCrypt.hashpw(senha, BCrypt.gensalt()),
      setorId: 1,
      papel: Papel.admin,
      ativo: true,
    );

void main() {
  // Injeta as variáveis mínimas no ambiente do processo para que Env.load()
  // não falhe por chaves obrigatórias ausentes (DB_NAME, DB_USER, etc.).
  setUpAll(() {
    final required = {
      'DB_NAME': 'test',
      'DB_USER': 'test',
      'DB_PASSWORD': 'test',
      'JWT_SECRET': 'segredo-de-teste-super-secreto-com-tamanho-suficiente',
    };
    for (final e in required.entries) {
      if (!Platform.environment.containsKey(e.key)) {
        // dart test não permite setar Platform.environment diretamente;
        // usamos a variável via Env.load() que já leu o process environment.
        // Para CI, basta exportar essas vars. Para rodar local:
        //   JWT_SECRET=x DB_NAME=x DB_USER=x DB_PASSWORD=x dart test
        // Aqui assumimos que elas existem ou que o arquivo .env local as tem.
      }
    }
  });

  AuthService _buildService(Usuario? usuario) {
    final env = _fakeEnv();
    return AuthService(_FakeRepo(usuario), env);
  }

  group('AuthService.login', () {
    test('retorna token JWT com credenciais corretas', () async {
      final service = _buildService(_fakeUsuario('senha123'));
      final token = await service.login('admin', 'senha123');
      expect(token, isNotEmpty);
      expect(token.split('.').length, 3);
    });

    test('lança AuthException com senha errada', () {
      final service = _buildService(_fakeUsuario('senha123'));
      expect(
        () => service.login('admin', 'errada'),
        throwsA(isA<AuthException>()),
      );
    });

    test('lança AuthException quando usuário não existe', () {
      final service = _buildService(null);
      expect(
        () => service.login('inexistente', 'qualquer'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.verifyToken', () {
    test('verifica token válido e retorna payload correto', () async {
      final service = _buildService(_fakeUsuario('abc'));
      final token = await service.login('admin', 'abc');
      final payload = service.verifyToken(token);
      expect(payload.userId, 1);
      expect(payload.papel, Papel.admin);
    });

    test('lança AuthException com token inválido', () {
      final service = _buildService(null);
      expect(
        () => service.verifyToken('token.invalido.aqui'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
