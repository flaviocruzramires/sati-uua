import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/domain/paginated_result.dart';
import 'package:chamados/features/setores/setor_repository.dart';
import 'package:chamados/features/usuarios/usuario_repository.dart';
import 'package:chamados/features/usuarios/view_model/usuarios_view_model.dart';

class MockUsuarioRepo extends Mock implements UsuarioRepositoryBase {}

class MockSetorRepo extends Mock implements SetorRepositoryBase {}

const kUsuario = UsuarioDto(
  id: 1,
  nome: 'Ana',
  email: 'ana@uems.br',
  login: 'ana',
  setorId: 1,
  setorNome: 'TI',
  papel: PapelUsuario.admin,
  ativo: true,
);

final emptyResult = PaginatedResult<UsuarioDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

final emptySetores = PaginatedResult<SetorDto>(
  data: const [],
  total: 0,
  page: 1,
  pageSize: 20,
);

void main() {
  late MockUsuarioRepo repo;
  late MockSetorRepo setorRepo;

  setUpAll(() {
    registerFallbackValue(PapelUsuario.solicitante);
  });

  setUp(() {
    repo = MockUsuarioRepo();
    setorRepo = MockSetorRepo();
    when(
      () => repo.list(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        papel: any(named: 'papel'),
      ),
    ).thenAnswer((_) async => emptyResult);
    when(
      () => setorRepo.list(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        busca: any(named: 'busca'),
      ),
    ).thenAnswer((_) async => emptySetores);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      usuarioRepositoryProvider.overrideWithValue(repo),
      setorRepositoryProvider.overrideWithValue(setorRepo),
    ],
  );

  test('load popula listState', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(usuariosViewModelProvider.notifier).load();
    expect(
      c.read(usuariosViewModelProvider).listState,
      isA<AsyncData<PaginatedResult<UsuarioDto>>>(),
    );
  });

  test('create retorna true', () async {
    when(
      () => repo.create(
        nome: any(named: 'nome'),
        email: any(named: 'email'),
        login: any(named: 'login'),
        senha: any(named: 'senha'),
        setorId: any(named: 'setorId'),
        papel: any(named: 'papel'),
      ),
    ).thenAnswer((_) async => kUsuario);
    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(usuariosViewModelProvider.notifier)
        .create(
          nome: 'Ana',
          email: 'ana@uems.br',
          login: 'ana',
          senha: 'secret123',
          setorId: 1,
          papel: PapelUsuario.admin,
        );
    expect(ok, isTrue);
  });

  test('create retorna false em conflito e salva saveError', () async {
    when(
      () => repo.create(
        nome: any(named: 'nome'),
        email: any(named: 'email'),
        login: any(named: 'login'),
        senha: any(named: 'senha'),
        setorId: any(named: 'setorId'),
        papel: any(named: 'papel'),
      ),
    ).thenThrow(Exception('409'));
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(usuariosViewModelProvider.notifier);
    await vm.load();
    final ok = await vm.create(
      nome: 'Ana',
      email: 'ana@uems.br',
      login: 'ana',
      senha: 'secret123',
      setorId: 1,
      papel: PapelUsuario.admin,
    );
    expect(ok, isFalse);
    expect(c.read(usuariosViewModelProvider).saveError, isNotNull);
  });

  test('update retorna true', () async {
    when(
      () => repo.update(
        id: any(named: 'id'),
        nome: any(named: 'nome'),
        email: any(named: 'email'),
        setorId: any(named: 'setorId'),
        papel: any(named: 'papel'),
        ativo: any(named: 'ativo'),
        senha: any(named: 'senha'),
      ),
    ).thenAnswer((_) async => kUsuario);
    final c = makeContainer();
    addTearDown(c.dispose);
    final ok = await c
        .read(usuariosViewModelProvider.notifier)
        .update(
          id: 1,
          nome: 'Ana',
          email: 'ana@uems.br',
          setorId: 1,
          papel: PapelUsuario.admin,
          ativo: true,
        );
    expect(ok, isTrue);
  });

  test('selectUser atualiza selectedId', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(usuariosViewModelProvider.notifier);
    vm.selectUser(5);
    expect(c.read(usuariosViewModelProvider).selectedId, 5);
    vm.selectUser(null);
    expect(c.read(usuariosViewModelProvider).selectedId, isNull);
  });

  test('setFiltroPapel aplica filtro e reinicia página', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final vm = c.read(usuariosViewModelProvider.notifier);
    await vm.load();
    vm.setFiltroPapel(PapelUsuario.admin);
    await vm.load();
    expect(c.read(usuariosViewModelProvider).filtroPapel, PapelUsuario.admin);
    expect(c.read(usuariosViewModelProvider).page, 1);
  });
}
