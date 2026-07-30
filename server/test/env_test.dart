import 'dart:io';

import 'package:sati_uua_server/src/config/env.dart';
import 'package:test/test.dart';

void main() {
  group('Env', () {
    late File tempEnvFile;

    setUp(() {
      tempEnvFile = File('.env.test_tmp')
        ..writeAsStringSync('''
APP_ENV=test
HTTP_PORT=9999
DB_NAME=chamados_test
DB_USER=chamados
DB_PASSWORD=chamados
JWT_SECRET=segredo-de-teste
''');
    });

    tearDown(() {
      if (tempEnvFile.existsSync()) tempEnvFile.deleteSync();
    });

    test('carrega valores do arquivo .env informado', () {
      final env = Env.load(path: tempEnvFile.path);
      expect(env.appEnv, 'test');
      expect(env.httpPort, 9999);
      expect(env.dbName, 'chamados_test');
      expect(env.jwtSecret, 'segredo-de-teste');
    });

    test('usa valores default quando a chave é opcional e não está presente', () {
      final env = Env.load(path: tempEnvFile.path);
      expect(env.httpHost, '0.0.0.0');
      expect(env.logLevel, 'INFO');
    });

    test('lança StateError quando uma chave obrigatória está ausente', () {
      final emptyFile = File('.env.empty_tmp')..writeAsStringSync('APP_ENV=test\n');
      addTearDown(() => emptyFile.deleteSync());

      final env = Env.load(path: emptyFile.path);
      expect(() => env.dbName, throwsA(isA<StateError>()));
    });
  });
}
