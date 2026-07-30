import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/auth_storage.dart';
import '../auth_service.dart';

// Estado da tela de login
class LoginState {
  const LoginState({this.loading = false, this.errorMessage});
  final bool loading;
  final String? errorMessage;

  LoginState copyWith({bool? loading, String? errorMessage, bool clearError = false}) {
    return LoginState(
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  AuthService get _service => AuthService(
        ref.read(apiClientProvider),
        ref.read(authStorageProvider),
      );

  Future<bool> login(String login, String senha) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _service.login(login.trim(), senha);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Login ou senha inválidos',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService(
      ref.read(apiClientProvider),
      ref.read(authStorageProvider),
    ).logout();
  }
}

final loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);
