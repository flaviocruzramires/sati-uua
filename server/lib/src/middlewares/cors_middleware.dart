import 'package:shelf/shelf.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
      'Origin, Content-Type, Authorization, $requestIdHeaderName',
};

const requestIdHeaderName = 'X-Request-Id';

/// CORS simples: necessário porque o Flutter web (rodando em outra origem em
/// desenvolvimento) consome esta API. Ajustar `Access-Control-Allow-Origin`
/// para o domínio real antes de ir para produção.
Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}
