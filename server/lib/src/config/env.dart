import 'dart:io';

/// Configuração de runtime lida do arquivo `.env` (segredos e parâmetros de
/// infraestrutura) — ver claude-config/skills/dart-shelf-server/SKILL.md,
/// seção "Configuração via .env + tabela configuracoes".
///
/// Implementação sem dependência externa (parser simples de `.env`) para não
/// depender de um pacote de terceiros só para isso. Variáveis já presentes em
/// [Platform.environment] (ex.: definidas pelo ambiente/CI) têm prioridade
/// sobre o arquivo `.env`.
class Env {
  Env._(this._values);

  final Map<String, String> _values;

  static Env? _instance;

  static Env get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('Env.load() precisa ser chamado antes de Env.instance.');
    }
    return instance;
  }

  /// Carrega o `.env` do diretório atual (ou do caminho informado) e mescla
  /// com as variáveis de ambiente do processo.
  static Env load({String path = '.env'}) {
    final values = <String, String>{};

    final file = File(path);
    if (file.existsSync()) {
      for (final rawLine in file.readAsLinesSync()) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final separatorIndex = line.indexOf('=');
        if (separatorIndex == -1) continue;
        final key = line.substring(0, separatorIndex).trim();
        var value = line.substring(separatorIndex + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        values[key] = value;
      }
    }

    // Variáveis de ambiente do processo têm prioridade sobre o arquivo.
    values.addAll(Platform.environment);

    final env = Env._(values);
    _instance = env;
    return env;
  }

  String _require(String key) {
    final value = _values[key];
    if (value == null || value.isEmpty) {
      throw StateError('Variável de ambiente obrigatória ausente: $key');
    }
    return value;
  }

  String _optional(String key, String fallback) => _values[key] ?? fallback;

  /// Conexão parseada de `DATABASE_URL`, quando presente. Neon e Render expõem
  /// os dados do banco como uma única URL no formato
  /// `postgres://user:senha@host:porta/dbname?sslmode=require`. Quando essa
  /// variável existe, ela tem prioridade sobre os campos `DB_*` individuais.
  Uri? get _databaseUri {
    final url = _values['DATABASE_URL'];
    if (url == null || url.isEmpty) return null;
    return Uri.parse(url);
  }

  String get appEnv => _optional('APP_ENV', 'development');
  String get httpHost => _optional('HTTP_HOST', '0.0.0.0');

  /// Porta HTTP. O Render injeta `PORT` automaticamente; damos prioridade a ela
  /// e caímos para `HTTP_PORT` (uso local) e por fim 8080.
  int get httpPort =>
      int.parse(_values['PORT'] ?? _optional('HTTP_PORT', '8080'));

  String get dbHost => _databaseUri?.host ?? _optional('DB_HOST', 'localhost');
  int get dbPort {
    final uriPort = _databaseUri?.port;
    if (uriPort != null && uriPort != 0) return uriPort;
    return int.parse(_optional('DB_PORT', '5432'));
  }

  String get dbName {
    final path = _databaseUri?.pathSegments;
    if (path != null && path.isNotEmpty && path.first.isNotEmpty) {
      return path.first;
    }
    return _require('DB_NAME');
  }

  String get dbUser {
    final userInfo = _databaseUri?.userInfo;
    if (userInfo != null && userInfo.isNotEmpty) {
      return Uri.decodeComponent(userInfo.split(':').first);
    }
    return _require('DB_USER');
  }

  String get dbPassword {
    final userInfo = _databaseUri?.userInfo;
    if (userInfo != null && userInfo.contains(':')) {
      return Uri.decodeComponent(userInfo.split(':').sublist(1).join(':'));
    }
    return _require('DB_PASSWORD');
  }

  /// Modo SSL da conexão com o Postgres. Neon exige SSL; localmente (Docker)
  /// deixamos desligado. Aceita `require` (ou `verify-full`) e `disable`.
  /// Também é inferido de `?sslmode=` na `DATABASE_URL`.
  bool get dbUseSsl {
    final explicit = _values['DB_SSL_MODE'];
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.toLowerCase() != 'disable';
    }
    final uriSslMode = _databaseUri?.queryParameters['sslmode'];
    if (uriSslMode != null && uriSslMode.isNotEmpty) {
      return uriSslMode.toLowerCase() != 'disable';
    }
    // Sem configuração explícita: SSL ligado sempre que houver DATABASE_URL
    // (cenário de nuvem), desligado no fluxo local com DB_* separados.
    return _databaseUri != null;
  }

  String get jwtSecret => _require('JWT_SECRET');
  int get jwtExpirationHours =>
      int.parse(_optional('JWT_EXPIRATION_HOURS', '8'));

  String get logLevel => _optional('LOG_LEVEL', 'INFO');
}
