import 'package:postgres/postgres.dart';

import '../config/env.dart';
import '../repositories/anexo_repository.dart';
import '../repositories/chamado_historico_repository.dart';
import '../repositories/chamado_repository.dart';
import '../repositories/configuracao_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/equipamento_repository.dart';
import '../repositories/notificacao_repository.dart';
import '../repositories/permissao_repository.dart';
import '../repositories/relatorio_repository.dart';
import '../repositories/rotina_repository.dart';
import '../repositories/servico_repository.dart';
import '../repositories/setor_repository.dart';
import '../repositories/tipo_equipamento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../services/auth_service.dart';
import '../services/notificacao_service.dart';

class AppContainer {
  AppContainer._(this._db, this._env) {
    usuarioRepository = UsuarioRepository(_db);
    anexoRepository = AnexoRepository(_db);
    setorRepository = SetorRepository(_db);
    servicoRepository = ServicoRepository(_db);
    tipoEquipamentoRepository = TipoEquipamentoRepository(_db);
    equipamentoRepository = EquipamentoRepository(_db);
    chamadoRepository = ChamadoRepository(_db);
    chamadoHistoricoRepository = ChamadoHistoricoRepository(_db);
    notificacaoRepository = NotificacaoRepository(_db);
    notificacaoService = NotificacaoService(notificacaoRepository, _db);
    dashboardRepository = DashboardRepository(_db);
    relatorioRepository = RelatorioRepository(_db);
    configuracaoRepository = ConfiguracaoRepository(_db);
    rotinaRepository = RotinaRepository(_db);
    permissaoRepository = PermissaoRepository(_db);
    authService = AuthService(usuarioRepository, _env);
  }

  final Connection _db;
  final Env _env;

  late final UsuarioRepository usuarioRepository;
  late final AnexoRepository anexoRepository;
  late final SetorRepository setorRepository;
  late final ServicoRepository servicoRepository;
  late final TipoEquipamentoRepository tipoEquipamentoRepository;
  late final EquipamentoRepository equipamentoRepository;
  late final ChamadoRepository chamadoRepository;
  late final ChamadoHistoricoRepository chamadoHistoricoRepository;
  late final NotificacaoRepository notificacaoRepository;
  late final NotificacaoService notificacaoService;
  late final DashboardRepository dashboardRepository;
  late final RelatorioRepository relatorioRepository;
  late final ConfiguracaoRepository configuracaoRepository;
  late final RotinaRepository rotinaRepository;
  late final PermissaoRepository permissaoRepository;
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
      settings: ConnectionSettings(
        sslMode: env.dbUseSsl ? SslMode.require : SslMode.disable,
      ),
    );
    return AppContainer._(db, env);
  }

  Future<void> close() => _db.close();
}
