import 'package:postgres/postgres.dart';

import '../config/env.dart';
import '../repositories/chamado_historico_repository.dart';
import '../repositories/chamado_repository.dart';
import '../repositories/equipamento_repository.dart';
import '../repositories/servico_repository.dart';
import '../repositories/setor_repository.dart';
import '../repositories/tipo_equipamento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../services/auth_service.dart';

class AppContainer {
  AppContainer._(this._db, this._env) {
    usuarioRepository = UsuarioRepository(_db);
    setorRepository = SetorRepository(_db);
    servicoRepository = ServicoRepository(_db);
    tipoEquipamentoRepository = TipoEquipamentoRepository(_db);
    equipamentoRepository = EquipamentoRepository(_db);
    chamadoRepository = ChamadoRepository(_db);
    chamadoHistoricoRepository = ChamadoHistoricoRepository(_db);
    authService = AuthService(usuarioRepository, _env);
  }

  final Connection _db;
  final Env _env;

  late final UsuarioRepository usuarioRepository;
  late final SetorRepository setorRepository;
  late final ServicoRepository servicoRepository;
  late final TipoEquipamentoRepository tipoEquipamentoRepository;
  late final EquipamentoRepository equipamentoRepository;
  late final ChamadoRepository chamadoRepository;
  late final ChamadoHistoricoRepository chamadoHistoricoRepository;
  late final AuthService authService;

  Connection get db => _db;

  static Future<AppContainer> create(Env env) async {
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
    return AppContainer._(db, env);
  }

  Future<void> close() => _db.close();
}
