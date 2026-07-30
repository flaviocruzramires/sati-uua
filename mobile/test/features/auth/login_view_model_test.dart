import 'package:chamados/features/auth/view_model/login_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Stub de AuthService que não bate na rede
class _MockAuthService {
  bool shouldFail;
  _MockAuthService({this.shouldFail = false});

  Future<void> login(String login, String senha) async {
    if (shouldFail) throw Exception('401');
  }
}

// ViewModel testável que aceita um service injetado
class _TestLoginViewModel extends LoginViewModel {
  _TestLoginViewModel(this._mockService);
  final _MockAuthService _mockService;

  @override
  Future<bool> login(String login, String senha) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _mockService.login(login, senha);
      state = state.copyWith(loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Login ou senha inválidos',
      );
      return false;
    }
  }
}

void main() {
  group('LoginViewModel', () {
    test('login bem-sucedido: loading vai para true e volta false', () async {
      final mock = _MockAuthService();
      final container = ProviderContainer(
        overrides: [
          loginViewModelProvider.overrideWith(() => _TestLoginViewModel(mock)),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(loginViewModelProvider.notifier)
              as _TestLoginViewModel;

      expect(container.read(loginViewModelProvider).loading, isFalse);
      final future = notifier.login('admin', 'senha123');
      // Enquanto awaita, loading deveria estar true
      expect(container.read(loginViewModelProvider).loading, isTrue);
      final ok = await future;
      expect(ok, isTrue);
      expect(container.read(loginViewModelProvider).loading, isFalse);
      expect(container.read(loginViewModelProvider).errorMessage, isNull);
    });

    test('login com falha seta errorMessage', () async {
      final mock = _MockAuthService(shouldFail: true);
      final container = ProviderContainer(
        overrides: [
          loginViewModelProvider.overrideWith(() => _TestLoginViewModel(mock)),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(loginViewModelProvider.notifier)
              as _TestLoginViewModel;

      final ok = await notifier.login('admin', 'errada');
      expect(ok, isFalse);
      expect(
        container.read(loginViewModelProvider).errorMessage,
        'Login ou senha inválidos',
      );
      expect(container.read(loginViewModelProvider).loading, isFalse);
    });

    test('clearError ao iniciar novo login', () async {
      final mock = _MockAuthService(shouldFail: true);
      final container = ProviderContainer(
        overrides: [
          loginViewModelProvider.overrideWith(() => _TestLoginViewModel(mock)),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(loginViewModelProvider.notifier)
              as _TestLoginViewModel;

      // Primeiro login falha
      await notifier.login('admin', 'errada');
      expect(container.read(loginViewModelProvider).errorMessage, isNotNull);

      // Segundo login: error deve ser limpo no início
      mock.shouldFail = false;
      final fut = notifier.login('admin', 'certa');
      expect(container.read(loginViewModelProvider).errorMessage, isNull);
      await fut;
    });
  });
}
