import 'package:sati_uua_server/src/errors/app_exception.dart';
import 'package:test/test.dart';

void main() {
  group('AppException', () {
    test('unauthorized() gera status 401 e code unauthorized', () {
      const exception = AppException.unauthorized();
      expect(exception.statusCode, 401);
      expect(exception.code, 'unauthorized');
    });

    test('conflict() gera status 409 com a mensagem informada', () {
      const exception = AppException.conflict('E-mail já cadastrado');
      expect(exception.statusCode, 409);
      expect(exception.code, 'conflict');
      expect(exception.message, 'E-mail já cadastrado');
    });

    test('toJson() segue o formato padronizado {error: {code, message}}', () {
      const exception = AppException.notFound();
      final json = exception.toJson();
      expect(json['error'], isA<Map>());
      expect(json['error']['code'], 'not_found');
      expect(json['error']['message'], isNotEmpty);
    });
  });
}
