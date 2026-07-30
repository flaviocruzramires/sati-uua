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

  String get appEnv => _optional('APP_ENV', 'development');
  String get httpHost => _optional('HTTP_HOST', '0.0.0.0');
  int get httpPort => int.parse(_optional('HTTP_PORT', '8080'));

  String get dbHost => _optional('DB_HOST', 'localhost');
  int get dbPort => int.parse(_optional('DB_PORT', '5432'));
  String get dbName => _require('DB_NAME');
  String get dbUser => _require('DB_USER');
  String get dbPassword => _require('DB_PASSWORD');

  String get jwtSecret => _require('JWT_SECRET');
  int get jwtExpirationHours => int.parse(_optional('JWT_EXPIRATION_HOURS', '8'));

  String get logLevel => _optional('LOG_LEVEL', 'INFO');
}
