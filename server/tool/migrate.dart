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
  final env = Env.load();

  final db = await Connection.open(
    Endpoint(
      host: env.dbHost,
      port: env.dbPort,
      database: env.dbName,
      username: env.dbUser,
      password: env.dbPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  await db.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version    text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    )
  ''');

  await _applySqlFiles(db, Directory('migrations'), trackAsMigration: true);

  if (applySeed) {
    final seedDir = Directory('migrations/seed');
    if (seedDir.existsSync()) {
      await _applySqlFiles(db, seedDir, trackAsMigration: false);
    } else {
      stdout.writeln('Nenhum diretório migrations/seed encontrado — pulando seed.');
    }
  }

  await db.close();
  stdout.writeln('Migrações concluídas.');
}

Future<void> _applySqlFiles(
  Connection db,
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
    final sql = await file.readAsString();
    await db.execute(sql);

    if (trackAsMigration) {
      await db.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@version)'),
        parameters: {'version': version},
      );
    }
  }
}
