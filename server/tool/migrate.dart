// Runner de migrações simples — aplica os arquivos de `migrations/*.sql` em
// ordem alfabética, registrando o que já rodou em `schema_migrations`, para
// nunca reaplicar a mesma migração duas vezes (ver
// claude-config/skills/postgres-schema-chamados/SKILL.md).
//
// Uso:
//   dart run tool/migrate.dart            # só as migrações de schema
//   dart run tool/migrate.dart --seed     # migrações + seed de desenvolvimento
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'package:sati_uua_server/src/config/env.dart';

Future<void> main(List<String> arguments) async {
  final applySeed = arguments.contains('--seed');

  final packageDir = File(Platform.script.toFilePath()).parent.parent.path;
  final env = Env.load(path: '$packageDir/.env');

  final db = await Connection.open(
    Endpoint(
      host: env.dbHost,
      port: env.dbPort,
      database: env.dbName,
      username: env.dbUser,
      password: env.dbPassword,
    ),
    settings: ConnectionSettings(
      sslMode: env.dbUseSsl ? SslMode.require : SslMode.disable,
    ),
  );

  await db.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version    text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    )
  ''');

  final migrationsDir = Directory('$packageDir/migrations');
  await _applySqlFiles(db, env, migrationsDir, trackAsMigration: true);

  if (applySeed) {
    final seedDir = Directory('$packageDir/migrations/seed');
    if (seedDir.existsSync()) {
      await _applySqlFiles(db, env, seedDir, trackAsMigration: false);
    } else {
      stdout.writeln('Nenhum diretório migrations/seed encontrado — pulando seed.');
    }
  }

  await db.close();
  stdout.writeln('Migrações concluídas.');
}

Future<void> _applySqlFiles(
  Connection db,
  Env env,
  Directory directory, {
  required bool trackAsMigration,
}) async {
  if (!directory.existsSync()) return;

  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // Localiza psql no PATH ou em locais comuns do Windows.
  final psql = _findPsql();

  for (final file in files) {
    final version = file.uri.pathSegments.last;

    if (trackAsMigration) {
      final alreadyApplied = await db.execute(
        Sql.named('SELECT version FROM schema_migrations WHERE version = @version'),
        parameters: {'version': version},
      );
      if (alreadyApplied.isNotEmpty) {
        stdout.writeln('já aplicada: $version');
        continue;
      }
    }

    stdout.writeln('aplicando: ${file.path}');

    // Usa psql para executar o arquivo — suporta múltiplos statements,
    // extensões e sintaxe especial do PostgreSQL sem precisar fazer parse manual.
    final result = await Process.run(
      psql,
      [
        '-h', env.dbHost,
        '-p', env.dbPort.toString(),
        '-U', env.dbUser,
        '-d', env.dbName,
        '-f', file.absolute.path,
        '--no-password',
      ],
      environment: {
        ...Platform.environment,
        'PGPASSWORD': env.dbPassword,
        // Neon/Render exigem SSL; local (Docker) desliga.
        'PGSSLMODE': env.dbUseSsl ? 'require' : 'disable',
      },
    );

    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      throw Exception('Falha ao aplicar ${file.path} (exit ${result.exitCode})');
    }
    if ((result.stdout as String).trim().isNotEmpty) {
      stdout.writeln(result.stdout);
    }

    if (trackAsMigration) {
      await db.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@version)'),
        parameters: {'version': version},
      );
    }
  }
}

String _findPsql() {
  // Tenta psql no PATH primeiro.
  final whichResult = Process.runSync('where', ['psql']);
  if (whichResult.exitCode == 0) {
    return (whichResult.stdout as String).trim().split('\n').first.trim();
  }
  // Locais comuns no Windows.
  for (final version in ['17', '16', '15', '14']) {
    final path = 'C:\\Program Files\\PostgreSQL\\$version\\bin\\psql.exe';
    if (File(path).existsSync()) return path;
  }
  throw StateError(
    'psql não encontrado. Adicione o diretório bin do PostgreSQL ao PATH.',
  );
}
