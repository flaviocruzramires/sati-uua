import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/current_user.dart';
import '../../../core/auth/current_user_provider.dart';
import '../../../core/network/auth_storage.dart';
import '../auth_service.dart';

class LoginState {
  const LoginState({this.loading = false, this.errorMessage});
  final bool loading;
  final String? errorMessage;

  LoginState copyWith({
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<bool> login(String login, String senha) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _service.login(login.trim(), senha);
      // Lê o token que foi salvo e atualiza o usuário de forma síncrona
      final token = await ref.read(authStorageProvider).readToken();
      ref.read(currentUserProvider.notifier).setUser(CurrentUser.fromToken(token));
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      // Só um 401 real significa credenciais inválidas. Timeout, erro de rede,
      // ou o "cold start" do Render (que responde devagar / com página de
      // espera) NÃO são senha errada — mostramos uma mensagem adequada.
      String msg;
      if (e is DioException && e.response?.statusCode == 401) {
        msg = 'Login ou senha inválidos';
      } else if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout)) {
        msg = 'O servidor demorou a responder (pode estar iniciando). '
            'Aguarde alguns segundos e tente novamente.';
      } else {
        msg = 'Não foi possível conectar ao servidor. '
            'Verifique sua conexão e tente novamente.';
      }
      state = state.copyWith(loading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    ref.read(currentUserProvider.notifier).setUser(null);
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);
