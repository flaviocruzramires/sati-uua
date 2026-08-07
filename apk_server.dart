import 'dart:io';

void main() async {
  final apkFile = File(
      r'D:\desenvolvimento\flutter\chamados\mobile\build\app\outputs\flutter-apk\app-debug.apk');

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 9090);
  print('APK disponivel em: http://192.168.101.6:9090/sati-uua.apk');
  print('Pressione Ctrl+C para parar.');

  await for (final req in server) {
    if (req.uri.path == '/sati-uua.apk' || req.uri.path == '/') {
      req.response.headers
        ..contentType = ContentType('application', 'vnd.android.package-archive')
        ..add('Content-Disposition', 'attachment; filename="sati-uua.apk"')
        ..contentLength = await apkFile.length();
      await apkFile.openRead().pipe(req.response);
    } else {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('''<!DOCTYPE html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SATI-UUA</title>
<style>body{font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#f5f5f5}
.card{background:#fff;border-radius:12px;padding:32px;box-shadow:0 2px 12px rgba(0,0,0,.1);text-align:center;max-width:360px;width:90%}
h1{font-size:22px;margin:0 0 8px}p{color:#666;font-size:14px;margin:0 0 24px}
a{display:block;background:#2563eb;color:#fff;padding:14px 24px;border-radius:8px;text-decoration:none;font-size:16px;font-weight:600}
a:hover{background:#1d4ed8}.note{font-size:12px;color:#999;margin-top:16px}
</style></head><body>
<div class="card">
  <h1>SATI-UUA</h1>
  <p>Sistema de Atendimento de TI</p>
  <a href="/sati-uua.apk">⬇ Baixar APK</a>
  <p class="note">Habilite "Fontes desconhecidas" nas configurações do Android antes de instalar.</p>
</div></body></html>''');
      await req.response.close();
    }
  }
}
